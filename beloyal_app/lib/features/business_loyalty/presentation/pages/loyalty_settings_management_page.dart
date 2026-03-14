import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../auth/presentation/widgets/primary_gradient_button.dart';
import '../controllers/loyalty_settings_controller.dart';
import '../../data/models/loyalty_settings_dto.dart';

/// Non-blocking page for editing loyalty settings after initial setup.
/// Accessible from the Business Profile tab → Loyalty Settings card.
/// Route: /business/:businessId/loyalty/settings
class LoyaltySettingsManagementPage extends ConsumerStatefulWidget {
  const LoyaltySettingsManagementPage({super.key, required this.businessId});

  final int businessId;

  @override
  ConsumerState<LoyaltySettingsManagementPage> createState() =>
      _LoyaltySettingsManagementPageState();
}

class _LoyaltySettingsManagementPageState
    extends ConsumerState<LoyaltySettingsManagementPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _minRedeemCtrl;
  late final TextEditingController _maxRedeemCtrl;
  late final TextEditingController _ppudCtrl;
  late final TextEditingController _maxPtCtrl;
  late final TextEditingController _monthsCtrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _minRedeemCtrl = TextEditingController();
    _maxRedeemCtrl = TextEditingController();
    _ppudCtrl = TextEditingController();
    _maxPtCtrl = TextEditingController();
    _monthsCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  @override
  void dispose() {
    _minRedeemCtrl.dispose();
    _maxRedeemCtrl.dispose();
    _ppudCtrl.dispose();
    _maxPtCtrl.dispose();
    _monthsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    await ref
        .read(loyaltySettingsControllerProvider.notifier)
        .load(widget.businessId);

    if (!mounted) return;
    final s = ref.read(loyaltySettingsControllerProvider);
    _populateControllers(s);
    _initialized = true;
  }

  void _populateControllers(LoyaltySettingsState s) {
    _minRedeemCtrl.text = s.minPointsToRedeem.toString();
    _maxRedeemCtrl.text = s.maxPointsToRedeem.toString();
    _ppudCtrl.text = s.pointsPerUnitDiscount.toString();
    _maxPtCtrl.text = s.maxPointsPerTransaction.toString();
    _monthsCtrl.text = s.monthsToExpire.toString();

    for (final ctrl in [
      _minRedeemCtrl,
      _maxRedeemCtrl,
      _ppudCtrl,
      _maxPtCtrl,
      _monthsCtrl,
    ]) {
      ctrl.addListener(_syncState);
    }
  }

  void _syncState() {
    if (!_initialized) return;
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

  void _applyDefault() {
    _minRedeemCtrl.text = '100';
    _maxRedeemCtrl.text = '5000';
    _ppudCtrl.text = '1';
    _maxPtCtrl.text = '5000';
    _monthsCtrl.text = '12';
    ref.read(loyaltySettingsControllerProvider.notifier).applyDefaultPreset();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

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
              Expanded(child: Text('Loyalty settings updated')),
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

      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(loyaltySettingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          child: s.isLoading
              ? _buildSkeleton()
              : Stack(
                  children: [
                    Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 160),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (s.errorMessage != null) ...[
                              _buildError(s.errorMessage!),
                              const SizedBox(height: 16),
                            ],
                            _buildInfoNote(
                              'Changes apply to future redemptions and earnings rule checks.',
                            ),
                            const SizedBox(height: 20),
                            _buildSectionHeader(
                              'Redemption Rules',
                              Icons.redeem_rounded,
                            ),
                            _buildGlassCard(
                              children: [
                                _buildIntField(
                                  controller: _minRedeemCtrl,
                                  label: 'Min points to redeem',
                                  prefixIcon: Icons.arrow_downward_rounded,
                                  helper:
                                      'Guests need at least this many points.',
                                  validator: (v) {
                                    final n = int.tryParse(v ?? '');
                                    if (n == null || n < 1)
                                      return 'Must be ≥ 1';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildIntField(
                                  controller: _maxRedeemCtrl,
                                  label: 'Max points to redeem',
                                  prefixIcon: Icons.arrow_upward_rounded,
                                  helper:
                                      'Max points per redemption transaction.',
                                  validator: (v) {
                                    final n = int.tryParse(v ?? '');
                                    if (n == null || n < 1)
                                      return 'Must be ≥ 1';
                                    final min =
                                        int.tryParse(_minRedeemCtrl.text) ?? 0;
                                    if (n < min) return 'Must be ≥ min ($min)';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildSectionHeader(
                              'Conversion',
                              Icons.swap_horiz_rounded,
                            ),
                            _buildGlassCard(
                              children: [
                                _buildIntField(
                                  controller: _ppudCtrl,
                                  label: 'Points per 1 ALL discount',
                                  prefixIcon: Icons.monetization_on_rounded,
                                  helper: 'e.g. 2 → 2 pts = 1 ALL discount',
                                  validator: (v) {
                                    final n = int.tryParse(v ?? '');
                                    if (n == null || n < 1)
                                      return 'Must be ≥ 1';
                                    return null;
                                  },
                                ),
                                if (s.pointsPerUnitDiscount > 0) ...[
                                  const SizedBox(height: 16),
                                  _buildDiscountPreviewRow(100, s),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Divider(
                                      color: AppColors.glassBorder,
                                    ),
                                  ),
                                  _buildDiscountPreviewRow(250, s),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Divider(
                                      color: AppColors.glassBorder,
                                    ),
                                  ),
                                  _buildDiscountPreviewRow(1000, s),
                                ],
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildSectionHeader(
                              'Transaction Caps',
                              Icons.block_rounded,
                            ),
                            _buildGlassCard(
                              children: [
                                _buildIntField(
                                  controller: _maxPtCtrl,
                                  label: 'Max points per transaction',
                                  prefixIcon: Icons.price_check_rounded,
                                  helper: 'Cap per transaction (0 = no cap).',
                                  validator: (v) {
                                    final n = int.tryParse(v ?? '');
                                    if (n == null || n < 0)
                                      return 'Must be ≥ 0';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildSectionHeader(
                              'Expiry Policy',
                              Icons.schedule_rounded,
                            ),
                            _buildGlassCard(
                              children: [
                                _buildRadioTile(
                                  value: ExpiryType.noExpiry,
                                  groupValue: s.expiryType,
                                  label: 'No expiry',
                                  subtitle: 'Points never expire',
                                  onChanged: (v) => ref
                                      .read(
                                        loyaltySettingsControllerProvider
                                            .notifier,
                                      )
                                      .updateFields(
                                        expiryType: v,
                                        monthsToExpire: 0,
                                      ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Divider(color: AppColors.glassBorder),
                                ),
                                _buildRadioTile(
                                  value: ExpiryType.expireAfterXMonths,
                                  groupValue: s.expiryType,
                                  label: 'Expire after X months',
                                  subtitle: 'Points expire after a period',
                                  onChanged: (v) => ref
                                      .read(
                                        loyaltySettingsControllerProvider
                                            .notifier,
                                      )
                                      .updateFields(
                                        expiryType: v,
                                        monthsToExpire:
                                            int.tryParse(_monthsCtrl.text) ??
                                            12,
                                      ),
                                ),
                                if (s.expiryType ==
                                    ExpiryType.expireAfterXMonths) ...[
                                  const SizedBox(height: 16),
                                  _buildMonthsPresetChips(),
                                  const SizedBox(height: 12),
                                  _buildIntField(
                                    controller: _monthsCtrl,
                                    label: 'Months until expiry',
                                    prefixIcon: Icons.calendar_month_rounded,
                                    helper:
                                        'Points expire after this many months.',
                                    validator: (v) {
                                      if (s.expiryType !=
                                          ExpiryType.expireAfterXMonths) {
                                        return null;
                                      }
                                      final n = int.tryParse(v ?? '');
                                      if (n == null || n < 1) {
                                        return 'Must be at least 1';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
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
                          border: const Border(
                            top: BorderSide(color: AppColors.glassBorder),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PrimaryGradientButton(
                              label: 'Save changes',
                              icon: Icons.save_rounded,
                              isLoading: s.isSaving,
                              onPressed: s.isDirty && s.isValid && !s.isSaving
                                  ? _handleSave
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: s.isSaving ? null : _applyDefault,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                              ),
                              icon: const Icon(Icons.restore_rounded),
                              label: const Text('Reset to default'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
    String? helper,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
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
              '$discount ALL',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoNote(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.info,
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

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(
        children: List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 16,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Container(
                  height: i == 3 ? 100 : 72,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
