import 'package:flutter/material.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_coupon_helpers.dart';

/// Uniform coupon list card used across all coupon surfaces:
/// - Business detail "Coupons & Offers" tab
/// - Rewards tab coupon list
/// - View-all coupons page
///
/// All action chip taps (Claim, Buy More, Show QR) are routed to [onTap].
/// Callers must open [CustomerCouponDetailSheet] from [onTap]. The card never
/// runs any validate/confirm/redeem logic directly.
class CustomerCouponCard extends StatelessWidget {
  const CustomerCouponCard({
    super.key,
    required this.coupon,
    required this.onTap,
    this.showBusinessName = false,
  });

  final CustomerCoupon coupon;

  /// Invoked by both the card body tap and every action chip tap.
  /// Should open [CustomerCouponDetailSheet].
  final VoidCallback onTap;

  /// When true, shows [coupon.businessName] as a sub-label below the title.
  /// Use on cross-business surfaces (rewards tab, all-coupons page).
  final bool showBusinessName;

  Color get _statusColor => couponStatusColor(coupon.status);
  String get _statusLabel => couponStatusLabel(coupon.status);
  IconData get _typeIcon => couponTypeIcon(coupon.type);

  @override
  Widget build(BuildContext context) {
    final isActive = coupon.status == 'active' || coupon.status == 'expiring';
    final expiryLabel = couponExpiryDateLabel(coupon);
    final isPerLimitReached = coupon.isPerCustomerLimitReached;
    final isOverallLimitReached = coupon.isOverallLimitReached;
    final isLimitReached = coupon.isLimitReached;

    final borderColor = isLimitReached
        ? (isPerLimitReached ? AppColors.warning : AppColors.error)
            .withValues(alpha: 0.35)
        : coupon.status == 'expiring'
        ? AppColors.error.withValues(alpha: 0.3)
        : AppColors.glassBorder;

    final cardOpacity = coupon.canBuyMore
        ? 1.0
        : (coupon.isUsed || coupon.status == 'expired')
        ? 0.55
        : (isLimitReached ? 0.7 : 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: cardOpacity,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // ── Left gradient strip ─────────────────────────────
                      Container(
                        width: 76,
                        height: 110,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: (!coupon.canBuyMore &&
                                    (coupon.isUsed ||
                                        coupon.status == 'expired' ||
                                        isLimitReached))
                                ? [
                                    const Color(0xFF374151),
                                    const Color(0xFF6B7280),
                                  ]
                                : coupon.gradientColors,
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isLimitReached)
                              Icon(
                                isPerLimitReached
                                    ? Icons.person_off_rounded
                                    : Icons.inventory_2_rounded,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 22,
                              )
                            else ...[
                              Text(
                                coupon.discountDisplay,
                                style: AppTypography.outfit(
                                  fontSize:
                                      coupon.discountDisplay.length > 6
                                          ? 12
                                          : 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Icon(
                                _typeIcon,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ),
                      CustomPaint(
                        size: const Size(1, 110),
                        painter: _CouponDashedPainter(),
                      ),
                      // ── Right content ──────────────────────────────────
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title + badges row
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      coupon.title,
                                      style: AppTypography.dmSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textOnDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isLimitReached) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (isPerLimitReached
                                                ? AppColors.warning
                                                : AppColors.error)
                                            .withValues(alpha: 0.14),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isPerLimitReached
                                            ? 'My Limit'
                                            : 'Sold Out',
                                        style: AppTypography.dmSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: isPerLimitReached
                                              ? AppColors.warning
                                              : AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    if (coupon.isFeatured) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.gold
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Featured',
                                          style: AppTypography.dmSans(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.gold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _statusLabel,
                                        style: AppTypography.dmSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: _statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Sub-label: business name, limit reason, or description
                              if (showBusinessName)
                                Text(
                                  coupon.businessName,
                                  style: AppTypography.dmSans(
                                    fontSize: 11,
                                    color: AppColors.textMutedDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              else if (isLimitReached)
                                Text(
                                  coupon.limitReachedReason,
                                  style: AppTypography.dmSans(
                                    fontSize: 11,
                                    color: (isPerLimitReached
                                            ? AppColors.warning
                                            : AppColors.error)
                                        .withValues(alpha: 0.8),
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              else if (coupon.description.isNotEmpty)
                                Text(
                                  coupon.description,
                                  style: AppTypography.dmSans(
                                    fontSize: 11,
                                    color: AppColors.textMutedDark,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 8),
                              // Expiry + action chips row
                              Row(
                                children: [
                                  Icon(
                                    couponCardExpiryIcon(coupon),
                                    size: 11,
                                    color: coupon.status == 'expiring'
                                        ? AppColors.error
                                        : AppColors.textMutedDark,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      expiryLabel,
                                      style: AppTypography.dmSans(
                                        fontSize: 11,
                                        fontWeight:
                                            coupon.status == 'expiring'
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                        color: coupon.status == 'expiring'
                                            ? AppColors.error
                                            : AppColors.textMutedDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // All chip taps open the detail sheet via onTap.
                                  Flexible(
                                    child: CouponActionChipRow(
                                      coupon: coupon,
                                      onClaim: onTap,
                                    ),
                                  ),
                                ],
                              ),
                              // Points + redemption count row
                              if (coupon.pointCost > 0) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.stars_rounded,
                                      size: 12,
                                      color: AppColors.gold,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${coupon.pointCost} pts',
                                      style: AppTypography.dmSans(
                                        fontSize: 11,
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    _RedemptionCountLabel(coupon: coupon),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (coupon.termsAndConditions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      child: Text(
                        '* ${coupon.termsAndConditions}',
                        style: AppTypography.dmSans(
                          fontSize: 10,
                          color:
                              AppColors.textMutedDark.withValues(alpha: 0.6),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            // SOLD OUT corner stamp
            if (isOverallLimitReached && isActive)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                  child: Text(
                    'SOLD OUT',
                    style: AppTypography.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            // LIMIT HIT corner stamp
            if (isPerLimitReached && !isOverallLimitReached && isActive)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                  child: Text(
                    'LIMIT HIT',
                    style: AppTypography.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Redemption count label ───────────────────────────────────────────────────

class _RedemptionCountLabel extends StatelessWidget {
  const _RedemptionCountLabel({required this.coupon});
  final CustomerCoupon coupon;

  @override
  Widget build(BuildContext context) {
    if (coupon.isPerCustomerLimitReached) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${coupon.customerRedemptionCount}/${coupon.usageLimit} ✓',
          style: AppTypography.dmSans(
            fontSize: 10,
            color: AppColors.warning,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    if (coupon.isOverallLimitReached) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${coupon.totalRedemptions}/${coupon.totalRedemptionLimit} sold',
          style: AppTypography.dmSans(
            fontSize: 10,
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    if (coupon.usageLimit != null) {
      return Text(
        '${coupon.customerRedemptionCount}/${coupon.usageLimit} bought',
        style: AppTypography.dmSans(
          fontSize: 10,
          color: coupon.customerRedemptionCount > 0
              ? AppColors.primary
              : AppColors.textMutedDark,
        ),
      );
    }
    if (coupon.totalRedemptionLimit != null) {
      return Text(
        '${coupon.totalRedemptions}/${coupon.totalRedemptionLimit} sold',
        style: AppTypography.dmSans(
          fontSize: 10,
          color: AppColors.textMutedDark,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// ─── Shared dashed divider painter ───────────────────────────────────────────

class _CouponDashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.glassBorder
      ..strokeWidth = 1;
    const dashHeight = 5.0;
    const dashSpace = 4.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
