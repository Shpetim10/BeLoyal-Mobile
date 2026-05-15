import 'package:flutter/material.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';
import 'customer_coupon_qr_sheet.dart';

// ─── Shared visual helpers ────────────────────────────────────────────────────

IconData couponTypeIcon(String type) => switch (type) {
  CustomerCouponType.freeProduct => Icons.card_giftcard_rounded,
  CustomerCouponType.percentageDiscount => Icons.percent_rounded,
  CustomerCouponType.fixedAmountDiscount => Icons.discount_rounded,
  _ => Icons.confirmation_number_rounded,
};

String couponTypeLabel(String type) => switch (type) {
  CustomerCouponType.freeProduct => 'Free Product',
  CustomerCouponType.percentageDiscount => 'Percentage Discount',
  CustomerCouponType.fixedAmountDiscount => 'Fixed Discount',
  _ => type,
};

Color couponStatusColor(String status) => switch (status) {
  CustomerCouponStatus.active => AppColors.success,
  CustomerCouponStatus.expiring => AppColors.error,
  CustomerCouponStatus.used => AppColors.textMutedDark,
  CustomerCouponStatus.expired => AppColors.textMutedDark,
  CustomerCouponStatus.cancelled => AppColors.textMutedDark,
  _ => AppColors.textMutedDark,
};

String couponStatusLabel(String status) => switch (status) {
  CustomerCouponStatus.active => 'Active',
  CustomerCouponStatus.expiring => 'Expiring Soon',
  CustomerCouponStatus.used => 'Used',
  CustomerCouponStatus.expired => 'Expired',
  CustomerCouponStatus.cancelled => 'Cancelled',
  _ => status,
};

IconData couponStatusIcon(String status) => switch (status) {
  CustomerCouponStatus.active => Icons.check_circle_outline_rounded,
  CustomerCouponStatus.expiring => Icons.local_fire_department_rounded,
  CustomerCouponStatus.used => Icons.check_circle_rounded,
  CustomerCouponStatus.expired => Icons.history_toggle_off_rounded,
  CustomerCouponStatus.cancelled => Icons.block_rounded,
  _ => Icons.info_outline_rounded,
};

// ─── Action resolution ────────────────────────────────────────────────────────

/// The next action a customer can take on a coupon from a list/detail surface.
enum CouponActionKind {
  /// Owned, active/expiring, not yet used, QR available — render a "Show QR" chip.
  showQr,

  /// Owned but QR is missing — render a disabled explanatory chip instead of a
  /// broken QR action.
  qrMissing,

  /// Unowned + can redeem — render a "Claim" chip.
  claim,

  /// Owned + per-customer limit allows more redemptions — render a "Buy More"
  /// chip alongside the QR.
  buyMore,

  /// Cannot redeem (insufficient points, limit reached, sold out, etc.) —
  /// render a small reason chip.
  cannotRedeem,

  /// Coupon already used; no further redemption available. No chip.
  used,

  /// Coupon expired and no buy-more allowance. No chip.
  expired,

  /// Default — render nothing.
  none,
}

class CouponActionDecision {
  const CouponActionDecision({
    required this.primary,
    this.secondary,
    this.reason,
  });

  /// Primary action chip to render.
  final CouponActionKind primary;

  /// Optional secondary action (typically "Buy More" alongside "Show QR").
  final CouponActionKind? secondary;

  /// Reason text for `cannotRedeem` / `qrMissing` chips.
  final String? reason;
}

/// Resolves the action(s) to display for a coupon. Trusts backend `canRedeem`
/// /`cannotRedeemReason` from `/customer/businesses/{id}/available-coupons`
/// when present.
CouponActionDecision resolveCouponAction(CustomerCoupon coupon) {
  final isActive =
      coupon.status == CustomerCouponStatus.active ||
      coupon.status == CustomerCouponStatus.expiring;
  final hasQr = coupon.qrCode?.isNotEmpty == true;
  final canShowQr = coupon.isOwned && !coupon.isUsed && isActive && hasQr;
  final qrMissing = coupon.isOwned && !coupon.isUsed && isActive && !hasQr;

  // Backend explicit gate.
  if (coupon.canRedeem == false) {
    if (canShowQr) {
      return CouponActionDecision(
        primary: CouponActionKind.showQr,
        secondary: CouponActionKind.cannotRedeem,
        reason: coupon.cannotRedeemReason ?? coupon.limitReachedReason,
      );
    }
    if (qrMissing) {
      return const CouponActionDecision(
        primary: CouponActionKind.qrMissing,
        reason: 'QR not available yet',
      );
    }
    if (coupon.status == CustomerCouponStatus.used || coupon.isUsed) {
      return const CouponActionDecision(primary: CouponActionKind.used);
    }
    if (coupon.status == CustomerCouponStatus.expired) {
      return const CouponActionDecision(primary: CouponActionKind.expired);
    }
    return CouponActionDecision(
      primary: CouponActionKind.cannotRedeem,
      reason: coupon.cannotRedeemReason ?? coupon.limitReachedReason,
    );
  }

  if (coupon.status == CustomerCouponStatus.used || coupon.isUsed) {
    if (coupon.canBuyMore) {
      return const CouponActionDecision(primary: CouponActionKind.buyMore);
    }
    return const CouponActionDecision(primary: CouponActionKind.used);
  }

  if (coupon.status == CustomerCouponStatus.expired) {
    if (coupon.canBuyMore) {
      return const CouponActionDecision(primary: CouponActionKind.buyMore);
    }
    return const CouponActionDecision(primary: CouponActionKind.expired);
  }

  if (coupon.status == CustomerCouponStatus.cancelled) {
    return const CouponActionDecision(primary: CouponActionKind.none);
  }

  if (canShowQr && coupon.canBuyMore) {
    return const CouponActionDecision(
      primary: CouponActionKind.showQr,
      secondary: CouponActionKind.buyMore,
    );
  }
  if (canShowQr) {
    return const CouponActionDecision(primary: CouponActionKind.showQr);
  }
  if (qrMissing && coupon.canBuyMore) {
    return const CouponActionDecision(
      primary: CouponActionKind.qrMissing,
      secondary: CouponActionKind.buyMore,
      reason: 'QR not available yet',
    );
  }
  if (qrMissing) {
    return const CouponActionDecision(
      primary: CouponActionKind.qrMissing,
      reason: 'QR not available yet',
    );
  }
  if (!coupon.isOwned && isActive) {
    if (coupon.isLimitReached) {
      return CouponActionDecision(
        primary: CouponActionKind.cannotRedeem,
        reason: coupon.limitReachedReason,
      );
    }
    return const CouponActionDecision(primary: CouponActionKind.claim);
  }
  return const CouponActionDecision(primary: CouponActionKind.none);
}

String couponActionLabel(CouponActionKind kind) => switch (kind) {
  CouponActionKind.showQr => 'Show QR',
  CouponActionKind.qrMissing => 'QR pending',
  CouponActionKind.claim => 'Claim',
  CouponActionKind.buyMore => 'Buy More',
  CouponActionKind.cannotRedeem => 'Unavailable',
  CouponActionKind.used => 'Used',
  CouponActionKind.expired => 'Expired',
  CouponActionKind.none => '',
};

// ─── Shared action chip row ──────────────────────────────────────────────────

/// Renders the standard row of compact coupon action chips (Show QR / Claim /
/// Buy More / Unavailable) used in list/card surfaces.
///
/// The parent owns the validate→confirm→redeem flow and passes `onClaim` —
/// fired for both Claim and Buy More. The QR chip opens [CustomerCouponQrSheet]
/// directly using the coupon's `qrCode`.
class CouponActionChipRow extends StatelessWidget {
  const CouponActionChipRow({
    super.key,
    required this.coupon,
    required this.onClaim,
    this.isClaimLoading = false,
    this.decision,
    this.spacing = 6,
  });

  final CustomerCoupon coupon;
  final VoidCallback onClaim;
  final bool isClaimLoading;
  // Optional pre-resolved decision (e.g. for surfaces that customize gating).
  final CouponActionDecision? decision;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final d = decision ?? resolveCouponAction(coupon);
    final chips = <Widget>[];

    void addChip(CouponActionKind kind) {
      switch (kind) {
        case CouponActionKind.showQr:
          chips.add(_qrChip(context));
          break;
        case CouponActionKind.qrMissing:
          chips.add(_disabledChip(d.reason ?? 'QR pending'));
          break;
        case CouponActionKind.claim:
          chips.add(_claimChip(label: 'Claim', primary: true));
          break;
        case CouponActionKind.buyMore:
          chips.add(_claimChip(label: 'Buy More', primary: false));
          break;
        case CouponActionKind.cannotRedeem:
          chips.add(_disabledChip(d.reason ?? coupon.limitReachedReason));
          break;
        case CouponActionKind.used:
        case CouponActionKind.expired:
        case CouponActionKind.none:
          break;
      }
    }

    addChip(d.primary);
    if (d.secondary != null) addChip(d.secondary!);

    if (chips.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          chips[i],
        ],
      ],
    );
  }

  Widget _qrChip(BuildContext context) {
    return GestureDetector(
      onTap: () => CustomerCouponQrSheet.show(context, coupon),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_rounded, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text(
              'Show QR',
              style: AppTypography.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _claimChip({required String label, required bool primary}) {
    final colors = primary
        ? const [AppColors.primaryDark, AppColors.primary]
        : const [Color(0xFF1D4ED8), Color(0xFF2563EB)];
    return GestureDetector(
      onTap: isClaimLoading ? null : onClaim,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: isClaimLoading ? null : LinearGradient(colors: colors),
          color: isClaimLoading ? AppColors.cardDark : null,
          borderRadius: BorderRadius.circular(10),
          border: isClaimLoading
              ? Border.all(color: AppColors.glassBorder)
              : null,
        ),
        child: isClaimLoading
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              )
            : Text(
                label,
                style: AppTypography.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _disabledChip(String reason) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        reason,
        style: AppTypography.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textMutedDark,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
