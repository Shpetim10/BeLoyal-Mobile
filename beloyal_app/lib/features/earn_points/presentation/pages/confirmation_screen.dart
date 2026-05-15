import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass.dart';
import '../../../../features/auth/presentation/controllers/session_controller.dart';
import '../controllers/earn_points_controller.dart';
import '../widgets/slide_to_confirm_widget.dart';
import 'discount_coupon_scan_page.dart';

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
    final success = await ctrl.submitTransaction(businessId: widget.businessId);

    if (!success && mounted) {
      _slideKey.currentState?.reset();
    }
  }

  Future<void> _scanCoupon() async {
    final qrCode = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => const DiscountCouponScanPage(),
        fullscreenDialog: true,
      ),
    );

    if (qrCode == null || qrCode.isEmpty || !mounted) return;

    final confirmed = await _showCouponConfirmDialog(qrCode);
    if (confirmed != true || !mounted) return;

    final ctrl = ref.read(earnPointsControllerProvider.notifier);
    await ctrl.applyCoupon(businessId: widget.businessId, qrCode: qrCode);

    if (!mounted) return;

    final draft = ref.read(earnPointsControllerProvider);
    final currency = ref.read(activeBusinessCurrencyProvider) ?? 'ALL';
    _showCouponAppliedDialog(draft, currency);
  }

  Future<bool?> _showCouponConfirmDialog(String qrCode) {
    final displayCode = qrCode.length > 32
        ? '${qrCode.substring(0, 16)}…${qrCode.substring(qrCode.length - 8)}'
        : qrCode;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Apply Discount Coupon?',
                style: AppTypography.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textOnDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Please confirm before applying this coupon to the transaction.',
                textAlign: TextAlign.center,
                style: AppTypography.dmSans(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.glassWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer_rounded,
                      color: AppColors.secondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        displayCode,
                        style: AppTypography.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: const BorderSide(color: AppColors.glassBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCouponAppliedDialog(EarnPointsDraftState draft, String currency) {
    final preview = draft.preview;
    final hasDiscount = preview?.hasCouponDiscount ?? false;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Coupon Applied!',
                style: AppTypography.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textOnDark,
                ),
              ),
              const SizedBox(height: 8),
              if (hasDiscount) ...[
                Text(
                  'Discount of ${preview!.couponDiscountApplied!.toStringAsFixed(0)} $currency applied',
                  textAlign: TextAlign.center,
                  style: AppTypography.dmSans(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                _DialogRow(
                  label: 'Original Amount',
                  value:
                      '${(preview.originalBillAmount ?? 0).toStringAsFixed(0)} $currency',
                  valueColor: AppColors.textMuted,
                ),
                _DialogRow(
                  label: 'Discount',
                  value:
                      '-${preview.couponDiscountApplied!.toStringAsFixed(0)} $currency',
                  valueColor: AppColors.success,
                ),
                _DialogRow(
                  label: 'New Total',
                  value:
                      '${(preview.billAmount ?? 0).toStringAsFixed(0)} $currency',
                  valueColor: AppColors.textOnDark,
                  isBold: true,
                ),
                _DialogRow(
                  label: 'Points Earned',
                  value: '+${preview.totalPoints} pts',
                  valueColor: AppColors.accent,
                  isBold: true,
                ),
              ] else ...[
                Text(
                  'The discount coupon QR has been scanned and will be applied when you confirm the transaction.',
                  textAlign: TextAlign.center,
                  style: AppTypography.dmSans(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            FocusScope.of(context).unfocus();
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
      body: Consumer(
        builder: (context, ref, _) {
          final currency = ref.watch(activeBusinessCurrencyProvider) ?? 'ALL';
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Transaction summary card ──
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (draft.hasCoupon &&
                          (draft.preview?.hasCouponDiscount ?? false)) ...[
                        _SummaryRow(
                          label: 'Original Amount',
                          value:
                              '${(draft.preview!.originalBillAmount ?? draft.billAmount ?? 0).toStringAsFixed(0)} $currency',
                        ),
                        _SummaryRow(
                          label: 'Coupon Discount',
                          value:
                              '-${draft.preview!.couponDiscountApplied!.toStringAsFixed(0)} $currency',
                          valueColor: AppColors.success,
                        ),
                        _SummaryRow(
                          label: 'Final Amount',
                          value:
                              '${(draft.preview!.billAmount ?? 0).toStringAsFixed(0)} $currency',
                          isHighlighted: true,
                        ),
                      ] else
                        _SummaryRow(
                          label: 'Total Amount',
                          value: '${draft.billAmount ?? 0} $currency',
                          isHighlighted: true,
                        ),
                      if (draft.invoiceNumber != null &&
                          draft.invoiceNumber!.isNotEmpty)
                        _SummaryRow(
                          label: 'Invoice',
                          value: '#${draft.invoiceNumber}',
                        ),
                      if (draft.note != null && draft.note!.isNotEmpty)
                        _SummaryRow(label: 'Note', value: draft.note!),
                      _SummaryRow(
                        label: 'Total Points',
                        value: '+${draft.preview?.totalPoints ?? "--"}',
                        valueColor: AppColors.accent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Coupon section ──
                _CouponSection(
                  draft: draft,
                  currency: currency,
                  onScanCoupon: _scanCoupon,
                  onRemoveCoupon: () {
                    ref
                        .read(earnPointsControllerProvider.notifier)
                        .removeCoupon(businessId: widget.businessId);
                  },
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
          );
        },
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
          isLoading: draft.isSubmitting || draft.isCouponPreviewLoading,
          label: draft.hasCoupon
              ? 'Slide to award points + apply coupon'
              : 'Slide to award points',
        ),
      ),
    );
  }
}

// ── Coupon section ─────────────────────────────────────────────────────────

class _CouponSection extends StatelessWidget {
  const _CouponSection({
    required this.draft,
    required this.currency,
    required this.onScanCoupon,
    required this.onRemoveCoupon,
  });

  final EarnPointsDraftState draft;
  final String currency;
  final VoidCallback onScanCoupon;
  final VoidCallback onRemoveCoupon;

  @override
  Widget build(BuildContext context) {
    if (draft.isCouponPreviewLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.secondary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Applying coupon discount…',
              style: AppTypography.dmSans(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (draft.hasCoupon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_offer_rounded,
                color: AppColors.success,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discount Coupon Applied',
                    style: AppTypography.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                  if (draft.preview?.hasCouponDiscount ?? false)
                    Text(
                      '-${draft.preview!.couponDiscountApplied!.toStringAsFixed(0)} $currency off',
                      style: AppTypography.dmSans(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemoveCoupon,
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
              visualDensity: VisualDensity.compact,
              tooltip: 'Remove coupon',
            ),
          ],
        ),
      );
    }

    // No coupon yet — show scan button
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        onScanCoupon();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan Discount Coupon',
                    style: AppTypography.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Optional — apply customer\'s discount coupon',
                    style: AppTypography.dmSans(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary row ─────────────────────────────────────────────────────────────

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

// ── Dialog row helper ───────────────────────────────────────────────────────

class _DialogRow extends StatelessWidget {
  const _DialogRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textOnDark,
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
