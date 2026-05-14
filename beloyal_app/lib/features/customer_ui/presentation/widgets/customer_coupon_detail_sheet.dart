import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/data/providers/customer_providers.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_coupon_qr_sheet.dart';

class CustomerCouponDetailSheet {
  const CustomerCouponDetailSheet._();

  static void show(BuildContext context, CustomerCoupon coupon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (sheetCtx, scrollController) => _CouponSheetBody(
          coupon: coupon,
          scrollController: scrollController,
          rootContext: context,
        ),
      ),
    );
  }
}

class _CouponSheetBody extends ConsumerStatefulWidget {
  const _CouponSheetBody({
    required this.coupon,
    required this.scrollController,
    required this.rootContext,
  });

  final CustomerCoupon coupon;
  final ScrollController scrollController;
  final BuildContext rootContext;

  @override
  ConsumerState<_CouponSheetBody> createState() => _CouponSheetBodyState();
}

class _CouponSheetBodyState extends ConsumerState<_CouponSheetBody> {
  CustomerCoupon get coupon => widget.coupon;
  ScrollController get scrollController => widget.scrollController;

  Color get _statusColor => switch (coupon.status) {
    'active' => AppColors.success,
    'expiring' => AppColors.error,
    'used' => AppColors.textMutedDark,
    _ => AppColors.textMutedDark,
  };

  String get _statusLabel => switch (coupon.status) {
    'active' => 'Active',
    'expiring' => 'Expiring Soon',
    'used' => 'Used',
    'expired' => 'Expired',
    _ => coupon.status,
  };

  IconData get _typeIcon => switch (coupon.type) {
    'FREE_PRODUCT' => Icons.card_giftcard_rounded,
    'PERCENTAGE_DISCOUNT' => Icons.percent_rounded,
    'FIXED_AMOUNT_DISCOUNT' => Icons.discount_rounded,
    _ => Icons.confirmation_number_rounded,
  };

  String get _typeLabel => switch (coupon.type) {
    'FREE_PRODUCT' => 'Free Product',
    'PERCENTAGE_DISCOUNT' => 'Percentage Discount',
    'FIXED_AMOUNT_DISCOUNT' => 'Fixed Discount',
    _ => coupon.type,
  };

  bool get _isFreeProduct => coupon.type == 'FREE_PRODUCT';

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isActive = coupon.status == 'active' || coupon.status == 'expiring';
    final hoursLeft = coupon.expiresAt.difference(DateTime.now()).inHours;
    final daysLeft = coupon.expiresAt.difference(DateTime.now()).inDays;
    final isExpired = coupon.expiresAt.isBefore(DateTime.now());
    final timeLabel = isExpired
        ? 'Expired ${-daysLeft}d ago'
        : hoursLeft < 24
        ? 'Expires in ${hoursLeft}h'
        : 'Expires in ${daysLeft}d';
    final expiryFmt = DateFormat('MMM d, yyyy');
    final dateFmt = DateFormat('MMM d, yyyy');
    final gradientColors = coupon.isUsed || coupon.status == 'expired'
        ? [const Color(0xFF374151), const Color(0xFF6B7280)]
        : coupon.gradientColors;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPad),
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // ── Hero card ──────────────────────────────────────────────────
          Opacity(
            opacity: coupon.isUsed || coupon.status == 'expired' ? 0.75 : 1.0,
            child: _buildHeroCard(gradientColors, isActive),
          ),
          const SizedBox(height: 20),
          // ── Status & badges ───────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _statusLabel,
                      style: AppTypography.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor,
                      ),
                    ),
                  ),
                  if (coupon.isFeatured) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Featured',
                        style: AppTypography.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            coupon.businessName,
            style: AppTypography.dmSans(
              fontSize: 13,
              color: AppColors.textMutedDark,
            ),
          ),
          if (coupon.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              coupon.description,
              style: AppTypography.dmSans(
                fontSize: 14,
                color: AppColors.textOnDark,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // ── Free product details ───────────────────────────────────────
          if (_isFreeProduct && _hasFreeProductInfo) ...[
            _SectionLabel(label: 'Free Item'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (coupon.freeProductName?.isNotEmpty == true)
                    _FreeProductRow(
                      icon: Icons.restaurant_menu_rounded,
                      label: coupon.freeProductName!,
                    ),
                  if (coupon.freeProductVariant?.isNotEmpty == true)
                    _FreeProductRow(
                      icon: Icons.tune_rounded,
                      label: coupon.freeProductVariant!,
                    ),
                  if (coupon.freeProductCategory?.isNotEmpty == true)
                    _FreeProductRow(
                      icon: Icons.category_rounded,
                      label: coupon.freeProductCategory!,
                    ),
                  if (coupon.freeProductQuantity != null &&
                      coupon.freeProductQuantity! > 0)
                    _FreeProductRow(
                      icon: Icons.numbers_rounded,
                      label: 'Qty: ${coupon.freeProductQuantity}',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // ── Details grid ───────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Expires',
                  value: isExpired
                      ? timeLabel
                      : '${expiryFmt.format(coupon.expiresAt)}  ($timeLabel)',
                  valueColor: coupon.status == 'expiring'
                      ? AppColors.error
                      : null,
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.glassBorder,
                ),
                _InfoRow(
                  icon: Icons.category_rounded,
                  label: 'Type',
                  value: _typeLabel,
                ),
                if (coupon.pointCost > 0) ...[
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.glassBorder,
                  ),
                  _InfoRow(
                    icon: Icons.stars_rounded,
                    label: 'Point Cost',
                    value: '${coupon.pointCost} pts',
                    valueColor: AppColors.gold,
                  ),
                ],
                if (coupon.minimumOrderAmount != null &&
                    coupon.minimumOrderAmount! > 0) ...[
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.glassBorder,
                  ),
                  _InfoRow(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Min. Order',
                    value: 'L ${coupon.minimumOrderAmount!.toStringAsFixed(0)}',
                  ),
                ],
                if (coupon.maximumDiscountAmount != null &&
                    coupon.maximumDiscountAmount! > 0) ...[
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.glassBorder,
                  ),
                  _InfoRow(
                    icon: Icons.discount_rounded,
                    label: 'Max Discount',
                    value:
                        'L ${coupon.maximumDiscountAmount!.toStringAsFixed(0)}',
                    valueColor: AppColors.success,
                  ),
                ],
                if (coupon.usageLimit != null) ...[
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.glassBorder,
                  ),
                  _InfoRow(
                    icon: Icons.repeat_rounded,
                    label: 'Usage',
                    value: '${coupon.usageCount} / ${coupon.usageLimit} used',
                  ),
                ],
                if (coupon.totalRedemptionLimit != null) ...[
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.glassBorder,
                  ),
                  _InfoRow(
                    icon: Icons.people_rounded,
                    label: 'Total Redemptions',
                    value:
                        '${coupon.totalRedemptions} / ${coupon.totalRedemptionLimit}',
                  ),
                ],
              ],
            ),
          ),
          // ── Lifecycle details for owned coupons ────────────────────────
          if (_hasLifecycleInfo) ...[
            const SizedBox(height: 16),
            _SectionLabel(label: 'Usage Details'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                children: [
                  if (coupon.redeemedAt != null)
                    _InfoRow(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Redeemed',
                      value: dateFmt.format(coupon.redeemedAt!),
                    ),
                  if (coupon.usedAt != null) ...[
                    if (coupon.redeemedAt != null)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.glassBorder,
                      ),
                    _InfoRow(
                      icon: Icons.done_all_rounded,
                      label: 'Used',
                      value: dateFmt.format(coupon.usedAt!),
                    ),
                  ],
                  if (coupon.orderId?.isNotEmpty == true) ...[
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.glassBorder,
                    ),
                    _InfoRow(
                      icon: Icons.receipt_outlined,
                      label: 'Order ID',
                      value: coupon.orderId!,
                    ),
                  ],
                ],
              ),
            ),
          ],
          // ── Terms & Conditions ─────────────────────────────────────────
          if (coupon.termsAndConditions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Terms & Conditions',
              style: AppTypography.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMutedDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              coupon.termsAndConditions,
              style: AppTypography.dmSans(
                fontSize: 12,
                color: AppColors.textMutedDark,
                height: 1.5,
              ),
            ),
          ],
          if (isActive) ...[
            const SizedBox(height: 24),
            _CouponActionButton(
              coupon: coupon,
              rootContext: widget.rootContext,
            ),
          ],
        ],
      ),
    );
  }

  bool get _hasFreeProductInfo =>
      coupon.freeProductName?.isNotEmpty == true ||
      coupon.freeProductVariant?.isNotEmpty == true ||
      coupon.freeProductCategory?.isNotEmpty == true ||
      (coupon.freeProductQuantity != null && coupon.freeProductQuantity! > 0);

  bool get _hasLifecycleInfo =>
      coupon.redeemedAt != null ||
      coupon.usedAt != null ||
      coupon.orderId?.isNotEmpty == true;

  Widget _buildHeroCard(List<Color> gradientColors, bool isActive) {
    // Show image if available, otherwise the discount display card
    if (coupon.imageUrl?.isNotEmpty == true) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 160,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                coupon.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildGradientHero(gradientColors, isActive),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      coupon.discountDisplay,
                      style: AppTypography.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (coupon.title.toLowerCase() !=
                        coupon.discountDisplay.toLowerCase())
                      Text(
                        coupon.title,
                        style: AppTypography.dmSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return _buildGradientHero(gradientColors, isActive);
  }

  Widget _buildGradientHero(List<Color> gradientColors, bool isActive) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: gradientColors.first.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.discountDisplay,
                      style: AppTypography.outfit(
                        fontSize: coupon.discountDisplay.length > 6 ? 28 : 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (coupon.title.toLowerCase() !=
                        coupon.discountDisplay.toLowerCase())
                      Text(
                        coupon.title,
                        style: AppTypography.dmSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                const Spacer(),
                Icon(
                  _typeIcon,
                  size: 44,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _CouponActionButton extends ConsumerStatefulWidget {
  const _CouponActionButton({required this.coupon, required this.rootContext});

  final CustomerCoupon coupon;
  final BuildContext rootContext;

  @override
  ConsumerState<_CouponActionButton> createState() =>
      _CouponActionButtonState();
}

class _CouponActionButtonState extends ConsumerState<_CouponActionButton> {
  @override
  Widget build(BuildContext context) {
    ref.listen<CouponRedemptionState>(customerCouponRedemptionProvider, (
      _,
      next,
    ) {
      if (!mounted) return;
      if (next is CouponRedemptionSuccess) {
        ScaffoldMessenger.of(widget.rootContext).showSnackBar(
          SnackBar(
            content: Text(
              'Coupon added to your wallet!',
              style: AppTypography.dmSans(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(customerCouponRedemptionProvider.notifier).reset();
        Navigator.of(context).pop();
      }
    });

    final redemptionState = ref.watch(customerCouponRedemptionProvider);
    final coupon = widget.coupon;
    final isLoading = redemptionState is CouponRedemptionLoading;

    if (coupon.isOwned) {
      // Owned coupon — show QR or indicate QR unavailable
      return GestureDetector(
        onTap: isLoading
            ? null
            : () => CustomerCouponQrSheet.show(widget.rootContext, coupon),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Show QR Code',
                style: AppTypography.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Unowned coupon — show Claim button
    return Column(
      children: [
        if (redemptionState is CouponRedemptionError) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 14,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    redemptionState.message,
                    style: AppTypography.dmSans(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        GestureDetector(
          onTap: isLoading
              ? null
              : () => ref
                    .read(customerCouponRedemptionProvider.notifier)
                    .redeemCoupon(
                      couponId: coupon.id,
                      couponTitle: coupon.title,
                    ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: isLoading
                  ? null
                  : const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
              color: isLoading ? AppColors.cardDark : null,
              borderRadius: BorderRadius.circular(16),
              border: isLoading
                  ? Border.all(color: AppColors.glassBorder)
                  : null,
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Claim Coupon  •  ${coupon.pointCost} pts',
                          style: AppTypography.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textMutedDark,
      ),
    );
  }
}

class _FreeProductRow extends StatelessWidget {
  const _FreeProductRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.dmSans(
                fontSize: 13,
                color: AppColors.textOnDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMutedDark),
          const SizedBox(width: 10),
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
              textAlign: TextAlign.right,
              style: AppTypography.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textOnDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
