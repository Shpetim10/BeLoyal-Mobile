import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../controllers/earn_points_controller.dart';
import '../widgets/slide_to_confirm_widget.dart';

/// Step 3: Transaction confirmation with slide-to-confirm.
class ConfirmationScreen extends ConsumerStatefulWidget {
  const ConfirmationScreen({super.key, required this.businessId});

  final int businessId;

  @override
  ConsumerState<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen> {
  final _slideKey = GlobalKey<SlideToConfirmWidgetState>();

  Future<void> _onConfirm() async {
    final ctrl = ref.read(earnPointsControllerProvider.notifier);
    final success =
        await ctrl.submitTransaction(businessId: widget.businessId);

    if (!success && mounted) {
      // Reset the slider so staff can retry.
      _slideKey.currentState?.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(earnPointsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            ref
                .read(earnPointsControllerProvider.notifier)
                .goToStep(WizardStep.billDetails);
          },
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        title: const Text(
          'Confirm Transaction',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Step 3/3',
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Transaction summary card ──
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Total Amount',
                    value: '${draft.billAmount ?? 0} ALL',
                    isHighlighted: true,
                  ),
                  if (draft.invoiceNumber != null &&
                      draft.invoiceNumber!.isNotEmpty)
                    _SummaryRow(
                      label: 'Invoice',
                      value: '#${draft.invoiceNumber}',
                    ),
                  if (draft.note != null && draft.note!.isNotEmpty)
                    _SummaryRow(
                      label: 'Note',
                      value: draft.note!,
                    ),
                  _SummaryRow(
                    label: 'Total Points',
                    value: '+${draft.preview?.totalPoints ?? "--"}',
                    valueColor: AppColors.accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Per-guest breakdown ──
            const Text(
              'Guest Breakdown',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),

            ...List.generate(draft.guestCount, (i) {
              final guest = draft.guests[i];
              final result = draft.preview?.guestPointsResults
                  .where((r) => r.customerId == guest.customerId)
                  .firstOrNull;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.glassWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        guest.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guest.fullName,
                            style: const TextStyle(
                              color: AppColors.textOnDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Balance: ${guest.currentPoints} pts',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Points + new balance
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${result?.pointsEarned ?? "--"} pts',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (result != null)
                          Text(
                            'New: ${result.projectedBalance} pts',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            // ── Error banner ──
            if (draft.submissionError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${draft.submissionError}\nSwipe again to retry.',
                        style: const TextStyle(
                          color: AppColors.errorLight,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgDark,
          border: Border(
            top: BorderSide(
              color: AppColors.glassBorder.withValues(alpha: 0.15),
            ),
          ),
        ),
        child: SlideToConfirmWidget(
          key: _slideKey,
          onConfirmed: _onConfirm,
          isLoading: draft.isSubmitting,
          label: 'Slide to award points',
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isHighlighted;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textOnDark,
              fontSize: isHighlighted ? 18 : 14,
              fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
