import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../auth/presentation/widgets/primary_gradient_button.dart';
import '../controllers/earning_rule_controller.dart';
import '../controllers/loyalty_settings_controller.dart';
import '../widgets/earning_rule_builder_card.dart';
import '../widgets/earning_rule_preview_card.dart';
import '../widgets/preset_chips_row.dart';
import '../../data/models/loyalty_settings_dto.dart';

/// Unified two-step onboarding wizard.
/// Step 1: Earning Rule setup (pointsPer / amountPer)
/// Step 2: Loyalty Settings setup (redemption policies)
///
/// Redirected to from the router when either setting is not yet configured.
/// Step is auto-selected based on session flags.
class BusinessSetupWizardPage extends ConsumerStatefulWidget {
  const BusinessSetupWizardPage({
    super.key,
    required this.businessId,
    this.initialStep,
  });

  final int businessId;

  /// Override which step to start on. If null, determined from session flags.
  final int? initialStep;

  @override
  ConsumerState<BusinessSetupWizardPage> createState() =>
      _BusinessSetupWizardPageState();
}

class _BusinessSetupWizardPageState
    extends ConsumerState<BusinessSetupWizardPage> {
  int _currentStep = 0;
  final _step1FormKey = GlobalKey<FormState>();
  late final TextEditingController _pointsCtrl;
  late final TextEditingController _amountCtrl;
  bool _step1Initialized = false;
  final _step2FormKey = GlobalKey<FormState>();
  late final TextEditingController _minRedeemCtrl;
  late final TextEditingController _maxRedeemCtrl;
  late final TextEditingController _ppudCtrl; // points per unit discount
  late final TextEditingController _maxPtCtrl; // max points per transaction
  late final TextEditingController _monthsCtrl;

  @override
  void initState() {
    super.initState();
    _pointsCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
    _minRedeemCtrl = TextEditingController();
    _maxRedeemCtrl = TextEditingController();
    _ppudCtrl = TextEditingController();
    _maxPtCtrl = TextEditingController();
    _monthsCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initStep1();
      _initStep2();
      _determineStartingStep();
    });
  }

  @override
  void dispose() {
    _pointsCtrl.dispose();
    _amountCtrl.dispose();
    _minRedeemCtrl.dispose();
    _maxRedeemCtrl.dispose();
    _ppudCtrl.dispose();
    _maxPtCtrl.dispose();
    _monthsCtrl.dispose();
    super.dispose();
  }

  void _initStep1() {
    if (_step1Initialized) return;
    final s = ref.read(earningRuleControllerProvider);
    _pointsCtrl.text = s.pointsPer.toString();
    _amountCtrl.text = s.amountPer.toString();
    _pointsCtrl.addListener(_updateStep1State);
    _amountCtrl.addListener(_updateStep1State);
    _step1Initialized = true;
  }

  void _initStep2() {
    final s = ref.read(loyaltySettingsControllerProvider);
    _minRedeemCtrl.text = s.minPointsToRedeem.toString();
    _maxRedeemCtrl.text = s.maxPointsToRedeem.toString();
    _ppudCtrl.text = s.pointsPerUnitDiscount.toString();
    _maxPtCtrl.text = s.maxPointsPerTransaction.toString();
    _monthsCtrl.text = s.monthsToExpire.toString();
    _minRedeemCtrl.addListener(_updateStep2State);
    _maxRedeemCtrl.addListener(_updateStep2State);
    _ppudCtrl.addListener(_updateStep2State);
    _maxPtCtrl.addListener(_updateStep2State);
    _monthsCtrl.addListener(_updateStep2State);
  }

  void _determineStartingStep() {
    if (widget.initialStep != null) {
      setState(() => _currentStep = widget.initialStep!);
      return;
    }
    final session = ref.read(sessionControllerProvider);
    if (session == null) return;
    final profile = session.user.businessProfiles.firstWhere(
      (p) => p.businessId == widget.businessId,
      orElse: () => session.user.businessProfiles.first,
    );
    if (profile.earningSettingsConfigured &&
        !profile.loyaltySettingsConfigured) {
      setState(() => _currentStep = 1);
    }
  }

  void _updateStep1State() {
    final points = int.tryParse(_pointsCtrl.text);
    final amount = int.tryParse(_amountCtrl.text);
    ref
        .read(earningRuleControllerProvider.notifier)
        .updateFields(pointsPer: points, amountPer: amount);
  }

  void _updateStep2State() {
    ref
        .read(loyaltySettingsControllerProvider.notifier)
        .updateFields(
          minPointsToRedeem: int.tryParse(_minRedeemCtrl.text),
          maxPointsToRedeem: int.tryParse(_maxRedeemCtrl.text),
          pointsPerUnitDiscount: int.tryParse(_ppudCtrl.text),
          maxPointsPerTransaction: int.tryParse(_maxPtCtrl.text),
          monthsToExpire: int.tryParse(_monthsCtrl.text),
        );
  }

  void _applyStep1Preset(int points, int amount) {
    _pointsCtrl.text = points.toString();
    _amountCtrl.text = amount.toString();
    ref
        .read(earningRuleControllerProvider.notifier)
        .applyPreset(pointsPer: points, amountPer: amount);
  }

  void _applyStep2Preset() {
    _minRedeemCtrl.text = '100';
    _maxRedeemCtrl.text = '5000';
    _ppudCtrl.text = '1';
    _maxPtCtrl.text = '5000';
    _monthsCtrl.text = '12';
    ref.read(loyaltySettingsControllerProvider.notifier).applyDefaultPreset();
  }

  Future<void> _handleStep1Next() async {
    if (!_step1FormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await ref
        .read(earningRuleControllerProvider.notifier)
        .save(widget.businessId);

    if (success && mounted) {
      final earningState = ref.read(earningRuleControllerProvider);
      ref
          .read(sessionControllerProvider.notifier)
          .updateEarningSettingsFlags(
            businessId: widget.businessId,
            configured: true,
            enabled: earningState.pointsPer > 0,
          );
      setState(() => _currentStep = 1);
    }
  }

  Future<void> _handleStep2Save() async {
    if (!_step2FormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final lsState = ref.read(loyaltySettingsControllerProvider);
    if (lsState.expiryType == ExpiryType.expireAfterXMonths &&
        lsState.monthsToExpire < 1) {
      return;
    }

    final success = await ref
        .read(loyaltySettingsControllerProvider.notifier)
        .save(widget.businessId);

    if (success && mounted) {
      ref
          .read(sessionControllerProvider.notifier)
          .updateLoyaltySettingsFlags(
            businessId: widget.businessId,
            configured: true,
            enabled: true,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Setup complete!')),
            ],
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      context.go('/business/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentStep == 0 ? 'Set up earning rule' : 'Loyalty settings',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _currentStep = 0),
                tooltip: 'Back to earning rule',
              )
            : null,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDark, Color(0xFF1A0F15)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildStepIndicator(),
              Expanded(
                child: IndexedStack(
                  index: _currentStep,
                  children: [_buildStep1(), _buildStep2()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          _StepDot(index: 1, current: _currentStep, label: 'Earning rule'),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _currentStep >= 1
                        ? AppColors.primary
                        : AppColors.glassBorder,
                    _currentStep >= 1
                        ? AppColors.primary
                        : AppColors.glassBorder,
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          _StepDot(index: 2, current: _currentStep, label: 'Loyalty settings'),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    final step1State = ref.watch(earningRuleControllerProvider);

    return Form(
      key: _step1FormKey,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose how guests earn points from their bill.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                PresetChipsRow(onSelect: _applyStep1Preset),
                const SizedBox(height: 24),
                EarningRuleBuilderCard(
                  pointsController: _pointsCtrl,
                  amountController: _amountCtrl,
                ),
                const SizedBox(height: 24),
                EarningRulePreviewCard(
                  pointsPer: step1State.pointsPer,
                  amountPer: step1State.amountPer,
                ),
                if (step1State.errorMessage != null) ...[
                  const SizedBox(height: 24),
                  _buildError(step1State.errorMessage!),
                ],
                if (step1State.pointsPer == 0) ...[
                  const SizedBox(height: 24),
                  _buildWarning(
                    "Earning is disabled. Guests won't earn points until you increase points per.",
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStickyBar(
              child: PrimaryGradientButton(
                label: 'Next: Loyalty Settings',
                icon: Icons.arrow_forward_rounded,
                isLoading: step1State.isSaving,
                onPressed: step1State.isValid && !step1State.isSaving
                    ? _handleStep1Next
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final s = ref.watch(loyaltySettingsControllerProvider);

    return Form(
      key: _step2FormKey,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set the rules for redeeming points and preventing abuse.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),

                // MVP Preset Chip
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Quick preset',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ActionChip(
                  label: const Text('Default'),
                  avatar: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  onPressed: _applyStep2Preset,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                  side: const BorderSide(color: AppColors.accent, width: 0.5),
                  labelStyle: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionHeader('Redemption Rules', Icons.redeem_rounded),
                _buildGlassCard(
                  children: [
                    _buildIntField(
                      controller: _minRedeemCtrl,
                      label: 'Min points to redeem',
                      hint: 'e.g. 100',
                      prefixIcon: Icons.arrow_downward_rounded,
                      helper:
                          'Guests need at least this many points to redeem.',
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1) {
                          return 'Must be at least 1';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildIntField(
                      controller: _maxRedeemCtrl,
                      label: 'Max points to redeem',
                      hint: 'e.g. 5000',
                      prefixIcon: Icons.arrow_upward_rounded,
                      helper:
                          'Maximum points allowed per redemption transaction.',
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1) {
                          return 'Must be at least 1';
                        }
                        final min = int.tryParse(_minRedeemCtrl.text) ?? 0;
                        if (n < min) {
                          return 'Must be ≥ min ($min)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionHeader(
                  'Conversion (points → discount)',
                  Icons.swap_horiz_rounded,
                ),
                _buildGlassCard(
                  children: [
                    _buildIntField(
                      controller: _ppudCtrl,
                      label: 'Points per 1 ALL discount',
                      hint: 'e.g. 1',
                      prefixIcon: Icons.monetization_on_rounded,
                      helper:
                          'Example: If set to 2, then 2 points = 1 ALL discount.',
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1) {
                          return 'Must be at least 1';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Live preview
                    if (s.pointsPerUnitDiscount > 0) ...[
                      _buildDiscountPreviewRow(100, s),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: AppColors.glassBorder),
                      ),
                      _buildDiscountPreviewRow(250, s),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: AppColors.glassBorder),
                      ),
                      _buildDiscountPreviewRow(1000, s),
                      const SizedBox(height: 12),
                      _buildInfoBox(
                        'Discount is always rounded down to whole ALL.',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionHeader('Transaction Caps', Icons.block_rounded),
                _buildGlassCard(
                  children: [
                    _buildIntField(
                      controller: _maxPtCtrl,
                      label: 'Max points per transaction',
                      hint: 'e.g. 5000 (0 = no cap)',
                      prefixIcon: Icons.price_check_rounded,
                      helper:
                          'Cap points applied per transaction. Set to 0 for no cap.',
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 0) {
                          return 'Must be 0 or greater';
                        }
                        return null;
                      },
                    ),
                    if (s.maxPointsPerTransaction == 0) ...[
                      const SizedBox(height: 8),
                      _buildWarning('No transaction cap set.'),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionHeader('Expiry Policy', Icons.schedule_rounded),
                _buildGlassCard(
                  children: [
                    _buildRadioTile(
                      value: ExpiryType.noExpiry,
                      groupValue: s.expiryType,
                      label: 'No expiry',
                      subtitle: 'Points never expire',
                      onChanged: (v) {
                        ref
                            .read(loyaltySettingsControllerProvider.notifier)
                            .updateFields(expiryType: v, monthsToExpire: 0);
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Divider(color: AppColors.glassBorder),
                    ),
                    _buildRadioTile(
                      value: ExpiryType.expireAfterXMonths,
                      groupValue: s.expiryType,
                      label: 'Expire after X months',
                      subtitle: 'Points expire after the set number of months.',
                      onChanged: (v) {
                        ref
                            .read(loyaltySettingsControllerProvider.notifier)
                            .updateFields(
                              expiryType: v,
                              monthsToExpire:
                                  int.tryParse(_monthsCtrl.text) ?? 12,
                            );
                      },
                    ),
                    if (s.expiryType == ExpiryType.expireAfterXMonths) ...[
                      const SizedBox(height: 16),
                      _buildMonthsPresetChips(),
                      const SizedBox(height: 12),
                      _buildIntField(
                        controller: _monthsCtrl,
                        label: 'Months until expiry',
                        hint: 'e.g. 12',
                        prefixIcon: Icons.calendar_month_rounded,
                        helper:
                            'Points earned will expire after this many months.',
                        validator: (v) {
                          if (s.expiryType != ExpiryType.expireAfterXMonths) {
                            return null;
                          }
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1) {
                            return 'Must be at least 1 month';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),

                if (s.errorMessage != null) ...[
                  const SizedBox(height: 24),
                  _buildError(s.errorMessage!),
                ],
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStickyBar(
              child: PrimaryGradientButton(
                label: 'Save & Continue',
                icon: Icons.check_rounded,
                isLoading: s.isSaving,
                onPressed: s.isValid && !s.isSaving ? _handleStep2Save : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildIntField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? hint,
    String? helper,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        prefixIcon: Icon(prefixIcon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildRadioTile<T>({
    required T value,
    required T groupValue,
    required String label,
    required String subtitle,
    required ValueChanged<T?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Radio<T>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthsPresetChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final months in [3, 6, 12, 24])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text('$months mo'),
                onPressed: () {
                  _monthsCtrl.text = months.toString();
                  ref
                      .read(loyaltySettingsControllerProvider.notifier)
                      .updateFields(monthsToExpire: months);
                },
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                side: const BorderSide(color: AppColors.primary, width: 0.5),
                labelStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiscountPreviewRow(int points, LoyaltySettingsState s) {
    final discount = s.discountFor(points);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Redeem $points pts',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
        ),
        Row(
          children: [
            const Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              '$discount ALL discount',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarning(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBar({required Widget child}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).scaffoldBackgroundColor.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: child,
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.current,
    required this.label,
  });

  final int index; // 1-based
  final int current; // 0-based
  final String label;

  @override
  Widget build(BuildContext context) {
    final stepIndex = index - 1;
    final isActive = current == stepIndex;
    final isDone = current > stepIndex;

    final color = isDone
        ? AppColors.secondary
        : (isActive ? AppColors.primary : AppColors.glassBorder);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: isActive || isDone ? 1.0 : 0.15),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text(
                    '$index',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? color : AppColors.textMuted,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
