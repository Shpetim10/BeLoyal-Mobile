import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/data/models/customer_home_dto.dart'
    show ValidateRedemptionDto;
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
  /// Owned, active/expiring, not yet used, QR available — render a "Use Coupon" chip.
  showQr,

  /// Owned but QR is missing — render a disabled explanatory chip instead of a
  /// broken QR action.
  qrMissing,

  /// Owned, active/expiring, but canUse = false — render a disabled reason chip.
  cannotUse,

  /// Unowned + can redeem — render a "Redeem" chip.
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

/// Resolves the action(s) to display for a coupon.
///
/// Two separate CTA paths:
/// - Owned (`isOwned=true`): gate by `canUse` — customer presents QR at checkout.
/// - Unowned (`isOwned=false`): gate by `canRedeem` — customer spends points to claim.
CouponActionDecision resolveCouponAction(CustomerCoupon coupon) {
  final isActive =
      coupon.status == CustomerCouponStatus.active ||
      coupon.status == CustomerCouponStatus.expiring;
  final hasQr = coupon.qrCode?.isNotEmpty == true;
  final canShowQr = coupon.canShowQr;
  // qrMissing: owned+active+has no QR yet but canUse isn't blocked
  final qrMissing =
      coupon.isOwned &&
      !coupon.isUsed &&
      isActive &&
      !hasQr &&
      coupon.canUse != false;

  // ── Owned coupons: gate by canUse for checkout presentation ────────────────
  if (coupon.isOwned) {
    if (isActive) {
      // canUse=false: owned instance blocked from checkout use
      if (coupon.canUse == false) {
        return CouponActionDecision(
          primary: CouponActionKind.cannotUse,
          secondary: coupon.canBuyMore ? CouponActionKind.buyMore : null,
          reason: coupon.cannotUseReason,
        );
      }
      if (canShowQr) {
        return CouponActionDecision(
          primary: CouponActionKind.showQr,
          secondary: coupon.canBuyMore ? CouponActionKind.buyMore : null,
        );
      }
      if (qrMissing) {
        return CouponActionDecision(
          primary: CouponActionKind.qrMissing,
          secondary: coupon.canBuyMore ? CouponActionKind.buyMore : null,
          reason: 'QR not available yet',
        );
      }
    }
    if (coupon.isUsed || coupon.status == CustomerCouponStatus.used) {
      return coupon.canBuyMore
          ? const CouponActionDecision(primary: CouponActionKind.buyMore)
          : const CouponActionDecision(primary: CouponActionKind.used);
    }
    if (coupon.status == CustomerCouponStatus.expired) {
      return coupon.canBuyMore
          ? const CouponActionDecision(primary: CouponActionKind.buyMore)
          : const CouponActionDecision(primary: CouponActionKind.expired);
    }
    if (coupon.status == CustomerCouponStatus.cancelled) {
      return const CouponActionDecision(primary: CouponActionKind.none);
    }
    return coupon.canBuyMore
        ? const CouponActionDecision(primary: CouponActionKind.buyMore)
        : const CouponActionDecision(primary: CouponActionKind.none);
  }

  // ── Unowned coupons: gate by canRedeem for point-spend purchase ─────────────
  if (!isActive) return const CouponActionDecision(primary: CouponActionKind.none);

  // Backend canRedeem=false is authoritative: customer cannot purchase right now
  if (coupon.canRedeem == false) {
    return CouponActionDecision(
      primary: CouponActionKind.cannotRedeem,
      reason: coupon.cannotRedeemReason ?? coupon.limitReachedReason,
    );
  }
  // Client-side limit check as safety net
  if (coupon.isLimitReached) {
    return CouponActionDecision(
      primary: CouponActionKind.cannotRedeem,
      reason: coupon.limitReachedReason,
    );
  }
  return const CouponActionDecision(primary: CouponActionKind.claim);
}

String couponActionLabel(CouponActionKind kind) => switch (kind) {
  CouponActionKind.showQr => 'Use Coupon',
  CouponActionKind.qrMissing => 'QR pending',
  CouponActionKind.cannotUse => 'Unavailable',
  CouponActionKind.claim => 'Redeem',
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
        case CouponActionKind.cannotUse:
          chips.add(_disabledChip(d.reason ?? 'Unavailable'));
          break;
        case CouponActionKind.claim:
          chips.add(_claimChip(label: 'Redeem', primary: true));
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            chips[i],
          ],
        ],
      ),
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
              'Use Coupon',
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 110),
      child: Container(
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
      ),
    );
  }
}

// ─── Expiry label ─────────────────────────────────────────────────────────────

/// Returns the card-style expiry label, adjusted for status:
/// - Active/expiring with date: "MMM d • relative" (e.g. "May 5 • Expires in 2d")
/// - Active/expiring without date: coupon.expiryLabel fallback
/// - Used/expired with date: just "MMM d" — relative suffix is past and redundant
/// - Used/expired without date: "—" (backend omits date for consumed instances)
String couponExpiryDateLabel(CustomerCoupon coupon) {
  final isUsedOrExpired = coupon.isUsed ||
      coupon.status == CustomerCouponStatus.used ||
      coupon.status == CustomerCouponStatus.expired;
  final expiresAt = coupon.expiresAt;

  if (isUsedOrExpired) {
    return expiresAt != null ? DateFormat('MMM d').format(expiresAt) : '—';
  }

  if (expiresAt == null) return coupon.expiryLabel;
  final datePart = DateFormat('MMM d').format(expiresAt);
  final relativePart = coupon.expiresIn ?? coupon.expiryLabel;
  return '$datePart • $relativePart';
}

/// Returns the icon for the expiry row on coupon cards.
/// - Expiring → fire (urgency)
/// - Used → check circle (consumed)
/// - Expired → history clock (lapsed)
/// - Active → calendar (upcoming date)
IconData couponCardExpiryIcon(CustomerCoupon coupon) {
  if (coupon.status == CustomerCouponStatus.expiring) {
    return Icons.local_fire_department_rounded;
  }
  if (coupon.isUsed || coupon.status == CustomerCouponStatus.used) {
    return Icons.check_circle_outline_rounded;
  }
  if (coupon.status == CustomerCouponStatus.expired) {
    return Icons.history_toggle_off_rounded;
  }
  return Icons.calendar_today_rounded;
}

// ─── Purchase Confirmation Dialog ─────────────────────────────────────────────

/// Shared purchase confirmation dialog used across all coupon surfaces.
/// Shows coupon title+business, cost, balance before/after (if [validation]
/// available), per-customer usage, terms, and an optional [networkError] banner.
class CouponPurchaseConfirmDialog extends StatelessWidget {
  const CouponPurchaseConfirmDialog({
    super.key,
    required this.coupon,
    this.validation,
    this.networkError,
  });

  final CustomerCoupon coupon;
  final ValidateRedemptionDto? validation;
  final String? networkError;

  static Future<bool?> show(
    BuildContext context,
    CustomerCoupon coupon, {
    ValidateRedemptionDto? validation,
    String? networkError,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => CouponPurchaseConfirmDialog(
        coupon: coupon,
        validation: validation,
        networkError: networkError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.confirmation_number_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Confirm Purchase',
                    style: AppTypography.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textOnDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${coupon.title} • ${coupon.businessName}',
                    style: AppTypography.dmSans(
                      fontSize: 13,
                      color: AppColors.textMutedDark,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Column(
                      children: [
                        _ConfirmRow(
                          icon: Icons.stars_rounded,
                          iconColor: AppColors.gold,
                          label: 'Cost',
                          value: '${coupon.pointCost} pts',
                          valueColor: AppColors.gold,
                          valueBold: true,
                        ),
                        if (validation != null && validation!.canRedeem) ...[
                          const SizedBox(height: 10),
                          _ConfirmRow(
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'Balance',
                            value:
                                '${validation!.customerBalance} pts → ${(validation!.customerBalance - coupon.pointCost).clamp(0, validation!.customerBalance)} pts',
                            valueColor: AppColors.textMutedDark,
                          ),
                        ],
                        if (coupon.usageLimit != null) ...[
                          const SizedBox(height: 10),
                          _ConfirmRow(
                            icon: Icons.repeat_rounded,
                            label: 'My redemptions',
                            value:
                                '${coupon.customerRedemptionCount} of ${coupon.usageLimit} allowed',
                            valueColor: AppColors.textMutedDark,
                          ),
                        ] else if (coupon.isOwned) ...[
                          const SizedBox(height: 10),
                          _ConfirmRow(
                            icon: Icons.info_outline_rounded,
                            iconColor: AppColors.primary,
                            label: 'Already purchased',
                            value:
                                '${coupon.customerRedemptionCount} time${coupon.customerRedemptionCount == 1 ? '' : 's'}',
                            valueColor: AppColors.primary,
                          ),
                        ],
                        if (coupon.termsAndConditions.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(height: 1, color: AppColors.glassBorder),
                          const SizedBox(height: 10),
                          Text(
                            coupon.termsAndConditions,
                            style: AppTypography.dmSans(
                              fontSize: 11,
                              color: AppColors.textMutedDark,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (networkError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              networkError!,
                              style: AppTypography.dmSans(
                                fontSize: 12,
                                color: AppColors.warning,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(false),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.cardDark,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: AppTypography.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMutedDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: networkError != null
                              ? null
                              : () => Navigator.of(context).pop(true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: networkError != null
                                  ? null
                                  : const LinearGradient(
                                      colors: [
                                        AppColors.primaryDark,
                                        AppColors.primary,
                                      ],
                                    ),
                              color: networkError != null
                                  ? AppColors.cardDark
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                              border: networkError != null
                                  ? Border.all(color: AppColors.glassBorder)
                                  : null,
                              boxShadow: networkError != null
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: Text(
                                'Confirm Buy',
                                style: AppTypography.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: networkError != null
                                      ? AppColors.textMutedDark
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
    this.valueBold = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor ?? AppColors.textMutedDark),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.dmSans(
            fontSize: 13,
            color: AppColors.textMutedDark,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTypography.dmSans(
              fontSize: 13,
              fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? AppColors.textOnDark,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
