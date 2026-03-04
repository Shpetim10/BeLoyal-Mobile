import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../auth/presentation/widgets/primary_gradient_button.dart';
import '../controllers/earning_rule_controller.dart';
import '../widgets/earning_rule_builder_card.dart';
import '../widgets/earning_rule_preview_card.dart';
import '../widgets/preset_chips_row.dart';

class EarningRuleManagementPage extends ConsumerStatefulWidget {
  const EarningRuleManagementPage({super.key, required this.businessId});

  final int businessId;

  @override
  ConsumerState<EarningRuleManagementPage> createState() =>
      _EarningRuleManagementPageState();
}

class _EarningRuleManagementPageState
    extends ConsumerState<EarningRuleManagementPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _pointsCtrl;
  late final TextEditingController _amountCtrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _pointsCtrl = TextEditingController();
    _amountCtrl = TextEditingController();

    _pointsCtrl.addListener(_updateState);
    _amountCtrl.addListener(_updateState);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFromSession();
    });
  }

  void _initFromSession() {
    if (_initialized) return;

    final session = ref.read(sessionControllerProvider);
    if (session == null) return;

    final currentState = ref.read(earningRuleControllerProvider);

    _pointsCtrl.text = currentState.pointsPer.toString();
    _amountCtrl.text = currentState.amountPer.toString();

    _initialized = true;
  }

  @override
  void dispose() {
    _pointsCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _updateState() {
    if (!_initialized) return;
    final points = int.tryParse(_pointsCtrl.text);
    final amount = int.tryParse(_amountCtrl.text);
    ref
        .read(earningRuleControllerProvider.notifier)
        .updateFields(pointsPer: points, amountPer: amount);
  }

  void _applyPreset(int points, int amount) {
    _pointsCtrl.text = points.toString();
    _amountCtrl.text = amount.toString();
    ref
        .read(earningRuleControllerProvider.notifier)
        .applyPreset(pointsPer: points, amountPer: amount);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await ref
        .read(earningRuleControllerProvider.notifier)
        .save(widget.businessId);

    if (success && mounted) {
      final state = ref.read(earningRuleControllerProvider);

      // Update session tracking
      ref
          .read(sessionControllerProvider.notifier)
          .updateEarningSettingsFlags(
            businessId: widget.businessId,
            configured: true,
            enabled: state.pointsPer > 0,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Earning rule updated')),
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

      context.pop(); // Go back to profile
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(earningRuleControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earning rule'),
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
          child: Stack(
            children: [
              Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PresetChipsRow(onSelect: _applyPreset),
                      const SizedBox(height: 24),

                      EarningRuleBuilderCard(
                        pointsController: _pointsCtrl,
                        amountController: _amountCtrl,
                      ),
                      const SizedBox(height: 24),

                      EarningRulePreviewCard(
                        pointsPer: state.pointsPer,
                        amountPer: state.amountPer,
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Applies to future transactions only.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                            ),
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
                                  state.errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (state.pointsPer == 0) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  "Earning is disabled. Guests won't earn points until you increase points per.",
                                  style: TextStyle(color: Colors.amber),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Sticky Action Bar
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
                        isLoading: state.isSaving,
                        onPressed:
                            state.isDirty && state.isValid && !state.isSaving
                            ? _handleSave
                            : null,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: state.isSaving
                            ? null
                            : () => _applyPreset(1, 100),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        child: const Text(
                          'Reset to default (1 per 100)',
                        ), // Safe client side as requested
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
}
