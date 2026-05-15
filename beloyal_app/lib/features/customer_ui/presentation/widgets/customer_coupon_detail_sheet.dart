import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/core/utils/currency_utils.dart';
import 'package:besahub_app/features/customer_ui/data/providers/customer_providers.dart';
import 'package:besahub_app/features/customer_ui/data/repositories/customer_repository.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_data_source.dart'
    show buildOwnedCouponFromRedemption;
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_coupon_helpers.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_coupon_qr_sheet.dart';

class CustomerCouponDetailSheet {
  const CustomerCouponDetailSheet._();

  static void show(BuildContext context, CustomerCoupon coupon) {
    // Only fetch fresh detail data for active/expiring coupons.
    // Used/expired coupons already carry complete data from the home API and
    // fetching by promotion ID for those states risks returning a different
    // business's coupon if the backend resolves customer-coupon IDs differently.
    final needsDetailFetch =
        coupon.status == 'active' || coupon.status == 'expiring';
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
          fetchDetailed: needsDetailFetch,
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
    this.fetchDetailed = false,
  });

  final CustomerCoupon coupon;
  final ScrollController scrollController;
  final BuildContext rootContext;
  final bool fetchDetailed;

  @override
  ConsumerState<_CouponSheetBody> createState() => _CouponSheetBodyState();
}

class _CouponSheetBodyState extends ConsumerState<_CouponSheetBody> {
  late final Future<CustomerCoupon?> _detailedCouponFuture;

  @override
  void initState() {
    super.initState();
    if (widget.fetchDetailed) {
      _detailedCouponFuture = Future.microtask(() async {
        try {
          final detailed = await ref.read(
            customerCouponDetailProvider(widget.coupon.couponId).future,
          );
          return detailed;
        } catch (_) {
          return widget.coupon;
        }
      });
    } else {
      _detailedCouponFuture = Future.value(widget.coupon);
    }
  }

  ScrollController get scrollController => widget.scrollController;

  Color _statusColor(CustomerCoupon coupon) => couponStatusColor(coupon.status);
  String _statusLabel(CustomerCoupon coupon) =>
      couponStatusLabel(coupon.status);
  IconData _typeIcon(CustomerCoupon coupon) => couponTypeIcon(coupon.type);
  String _typeLabel(CustomerCoupon coupon) => couponTypeLabel(coupon.type);

  bool _isFreeProduct(CustomerCoupon coupon) =>
      coupon.type == CustomerCouponType.freeProduct;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CustomerCoupon?>(
      future: _detailedCouponFuture,
      builder: (_, snapshot) {
        final coupon = snapshot.data ?? widget.coupon;
        return _buildContent(context, coupon);
      },
    );
  }

  Widget _buildContent(BuildContext context, CustomerCoupon coupon) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isActive = coupon.status == 'active' || coupon.status == 'expiring';
    final expiryDate = coupon.expiresAt != null
        ? DateFormat('MMM d, yyyy').format(coupon.expiresAt!)
        : 'No expiry provided';
    final expiresIn = coupon.expiresIn ?? coupon.expiryLabel;
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
            child: _buildHeroCard(coupon, gradientColors, isActive),
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
                      color: _statusColor(coupon).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _statusLabel(coupon),
                      style: AppTypography.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(coupon),
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
          if (_isFreeProduct(coupon) && _buildHasFreeProductInfo(coupon)) ...[
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
                if (coupon.status == 'expiring')
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.error.withValues(alpha: 0.08),
                          AppColors.error.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$expiryDate • $expiresIn',
                            style: AppTypography.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Expires',
                    value: '$expiryDate • $expiresIn',
                  ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.glassBorder,
                ),
                _InfoRow(
                  icon: Icons.category_rounded,
                  label: 'Type',
                  value: _typeLabel(coupon),
                ),
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
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.glassBorder,
                ),
                _InfoRow(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Min. Order',
                  value:
                      coupon.minimumOrderAmount != null &&
                          coupon.minimumOrderAmount! > 0
                      ? _formatCouponMoney(
                          coupon.minimumOrderAmount!,
                          coupon.currency,
                        )
                      : 'None',
                ),
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
                    value: _formatCouponMoney(
                      coupon.maximumDiscountAmount!,
                      coupon.currency,
                    ),
                    valueColor: AppColors.success,
                  ),
                ],
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.glassBorder,
                ),
                // ── Per-customer purchase count vs limit ────────────────────
                if (coupon.isPerCustomerLimitReached)
                  _HighlightRow(
                    icon: Icons.person_off_rounded,
                    text:
                        '${coupon.customerRedemptionCount}/${coupon.usageLimit} purchased • Personal limit reached',
                    color: AppColors.warning,
                  )
                else
                  _InfoRow(
                    icon: Icons.person_rounded,
                    label: 'My Purchases',
                    value: coupon.usageLimit != null
                        ? '${coupon.customerRedemptionCount} / ${coupon.usageLimit}'
                        : coupon.customerRedemptionCount > 0
                        ? '${coupon.customerRedemptionCount} times'
                        : 'Not yet purchased',
                    valueColor: coupon.customerRedemptionCount > 0
                        ? AppColors.primary
                        : null,
                  ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.glassBorder,
                ),
                // ── Overall redemption count vs limit ───────────────────────
                if (coupon.isOverallLimitReached)
                  _HighlightRow(
                    icon: Icons.inventory_2_rounded,
                    text:
                        '${coupon.totalRedemptions}/${coupon.totalRedemptionLimit} sold • Sold out',
                    color: AppColors.error,
                  )
                else
                  _InfoRow(
                    icon: Icons.people_rounded,
                    label: 'Total Sold',
                    value: coupon.totalRedemptionLimit != null
                        ? '${coupon.totalRedemptions} / ${coupon.totalRedemptionLimit}'
                        : 'Unlimited availability',
                  ),
                // ── Backend cannot-redeem reason ────────────────────────────
                if (coupon.canRedeem == false &&
                    coupon.cannotRedeemReason?.isNotEmpty == true) ...[
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.glassBorder,
                  ),
                  _HighlightRow(
                    icon: Icons.block_rounded,
                    text: coupon.cannotRedeemReason!,
                    color: AppColors.error,
                  ),
                ],
              ],
            ),
          ),
          // ── Lifecycle details for owned coupons ────────────────────────
          if (_buildHasLifecycleInfo(coupon)) ...[
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
          if (isActive || coupon.isOwned) ...[
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

  bool _buildHasFreeProductInfo(CustomerCoupon coupon) =>
      coupon.freeProductName?.isNotEmpty == true ||
      coupon.freeProductVariant?.isNotEmpty == true ||
      coupon.freeProductCategory?.isNotEmpty == true ||
      (coupon.freeProductQuantity != null && coupon.freeProductQuantity! > 0);

  bool _buildHasLifecycleInfo(CustomerCoupon coupon) =>
      coupon.redeemedAt != null ||
      coupon.usedAt != null ||
      coupon.orderId?.isNotEmpty == true;

  String _formatCouponMoney(double value, String? currency) {
    final symbol = currencySymbol(currency);
    final fixed = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return '$symbol $fixed'.trim();
  }

  Widget _buildHeroCard(
    CustomerCoupon coupon,
    List<Color> gradientColors,
    bool isActive,
  ) {
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
                    _buildGradientHero(coupon, gradientColors, isActive),
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
    return _buildGradientHero(coupon, gradientColors, isActive);
  }

  Widget _buildGradientHero(
    CustomerCoupon coupon,
    List<Color> gradientColors,
    bool isActive,
  ) {
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
                  _typeIcon(coupon),
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
  bool _isValidating = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<CouponRedemptionState>(customerCouponRedemptionProvider, (
      _,
      next,
    ) {
      if (!mounted) return;
      if (next is CouponRedemptionSuccess) {
        final result = next.result;
        ScaffoldMessenger.of(widget.rootContext).showSnackBar(
          SnackBar(
            content: Text(
              'Coupon purchased! ${result.remainingBalance} pts remaining',
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
        // Refresh home data in background
        ref.read(customerDataProvider.notifier).refresh();

        // Build a temporary coupon from the redemption result for QR display
        final qrCoupon = buildOwnedCouponFromRedemption(widget.coupon, result);
        Navigator.of(context).pop();
        if (widget.rootContext.mounted) {
          CustomerCouponQrSheet.show(widget.rootContext, qrCoupon);
        }
      }
    });

    final redemptionState = ref.watch(customerCouponRedemptionProvider);
    final coupon = widget.coupon;
    final isLoading =
        redemptionState is CouponRedemptionLoading || _isValidating;

    // ── Limit-reached state ───────────────────────────────────────────────────
    if (coupon.isLimitReached) {
      return Column(
        children: [
          if (coupon.isOwned) ...[
            _QrButton(
              isLoading: isLoading,
              onTap: () =>
                  CustomerCouponQrSheet.show(widget.rootContext, coupon),
            ),
            const SizedBox(height: 10),
          ],
          _LimitReachedBanner(coupon: coupon),
        ],
      );
    }

    // ── Owned coupon — show QR + optionally buy more ──────────────────────────
    if (coupon.isOwned) {
      return Column(
        children: [
          if (redemptionState is CouponRedemptionError)
            _ErrorBanner(message: redemptionState.message),
          _QrButton(
            isLoading: isLoading,
            onTap: () => CustomerCouponQrSheet.show(widget.rootContext, coupon),
          ),
          if (coupon.canBuyMore) ...[
            const SizedBox(height: 10),
            _ClaimButton(
              coupon: coupon,
              isLoading: isLoading,
              label: 'Buy Another  •  ${coupon.pointCost} pts',
              onTap: () => _confirmAndClaim(context, coupon),
            ),
          ],
        ],
      );
    }

    // ── Unowned coupon — show Claim button ────────────────────────────────────
    return Column(
      children: [
        if (redemptionState is CouponRedemptionError)
          _ErrorBanner(message: redemptionState.message),
        _ClaimButton(
          coupon: coupon,
          isLoading: isLoading,
          label: 'Claim Coupon  •  ${coupon.pointCost} pts',
          onTap: () => _confirmAndClaim(context, coupon),
        ),
      ],
    );
  }

  Future<void> _confirmAndClaim(
    BuildContext context,
    CustomerCoupon coupon,
  ) async {
    if (_isValidating) return;
    setState(() => _isValidating = true);

    // Capture before async gap — rootContext is external so mounted doesn't guard it.
    final messenger = ScaffoldMessenger.of(widget.rootContext);

    ValidateRedemptionDto? validation;
    String? networkError;
    try {
      validation = await ref
          .read(customerRepositoryProvider)
          .validateRedemption(coupon.couponId);
      if (!mounted) return;
      if (validation.canRedeem == false) {
        setState(() => _isValidating = false);
        final reason = validation.reason?.isNotEmpty == true
            ? validation.reason!
            : 'This coupon is no longer available.';
        final isInsufficientPoints =
            reason.toLowerCase().contains('insufficient') ||
            reason.toLowerCase().contains('points') ||
            reason.toLowerCase().contains('balance');
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isInsufficientPoints
                  ? '$reason Earn more points by visiting this business.'
                  : reason,
              style: AppTypography.dmSans(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(customerDataProvider.notifier).refresh();
        return;
      }
    } on DioException {
      networkError =
          'Could not verify eligibility. Please check your connection.';
    } catch (_) {
      networkError =
          'Could not verify eligibility. Please check your connection.';
    }

    if (!mounted) return;
    setState(() => _isValidating = false);

    final confirmed = await _CouponPurchaseConfirmDialog.show(
      context, // ignore: use_build_context_synchronously
      coupon,
      validation: validation,
      networkError: networkError,
    );
    if (confirmed == true && mounted) {
      ref
          .read(customerCouponRedemptionProvider.notifier)
          .redeemCoupon(couponId: coupon.couponId, couponTitle: coupon.title);
    }
  }
}

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

class _QrButton extends StatelessWidget {
  const _QrButton({required this.isLoading, required this.onTap});
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
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
}

class _ClaimButton extends StatelessWidget {
  const _ClaimButton({
    required this.coupon,
    required this.isLoading,
    required this.label,
    required this.onTap,
  });
  final CustomerCoupon coupon;
  final bool isLoading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
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
          border: isLoading ? Border.all(color: AppColors.glassBorder) : null,
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
                      label,
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
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.dmSans(fontSize: 12, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitReachedBanner extends StatelessWidget {
  const _LimitReachedBanner({required this.coupon});
  final CustomerCoupon coupon;

  @override
  Widget build(BuildContext context) {
    final isPersonal = coupon.isPerCustomerLimitReached;
    final icon = isPersonal
        ? Icons.person_off_rounded
        : Icons.inventory_2_rounded;
    final color = isPersonal ? AppColors.warning : AppColors.error;
    final label = isPersonal ? 'Personal Limit Reached' : 'Sold Out';
    final sublabel = coupon.limitReachedReason;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: AppTypography.dmSans(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Purchase Confirmation Dialog ─────────────────────────────────────────────

class _CouponPurchaseConfirmDialog extends StatelessWidget {
  const _CouponPurchaseConfirmDialog({
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
      builder: (_) => _CouponPurchaseConfirmDialog(
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
            // ── Header gradient band ────────────────────────────────────────
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Icon ─────────────────────────────────────────────────
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
                    'You\'re about to buy this coupon.',
                    style: AppTypography.dmSans(
                      fontSize: 13,
                      color: AppColors.textMutedDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // ── Coupon summary card ────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: coupon.gradientColors,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.local_offer_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    coupon.title,
                                    style: AppTypography.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textOnDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    coupon.businessName,
                                    style: AppTypography.dmSans(
                                      fontSize: 12,
                                      color: AppColors.textMutedDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(height: 1, color: AppColors.glassBorder),
                        const SizedBox(height: 14),
                        // ── Cost row ─────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cost',
                              style: AppTypography.dmSans(
                                fontSize: 13,
                                color: AppColors.textMutedDark,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.stars_rounded,
                                  size: 16,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${coupon.pointCost} pts',
                                  style: AppTypography.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // ── Balance before → after (from validate result) ─
                        if (validation != null && validation!.canRedeem) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Balance',
                                style: AppTypography.dmSans(
                                  fontSize: 13,
                                  color: AppColors.textMutedDark,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${validation!.customerBalance} pts',
                                    style: AppTypography.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textOnDark,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: AppColors.textMutedDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${(validation!.customerBalance - coupon.pointCost).clamp(0, validation!.customerBalance)} pts',
                                    style: AppTypography.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                        // ── Per-customer usage ────────────────────────────
                        if (coupon.usageLimit != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Your usage',
                                style: AppTypography.dmSans(
                                  fontSize: 12,
                                  color: AppColors.textMutedDark,
                                ),
                              ),
                              Text(
                                "You've used ${coupon.customerRedemptionCount} of ${coupon.usageLimit} allowed",
                                style: AppTypography.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textOnDark,
                                ),
                              ),
                            ],
                          ),
                        ] else if (coupon.isOwned) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Already purchased',
                                style: AppTypography.dmSans(
                                  fontSize: 12,
                                  color: AppColors.textMutedDark,
                                ),
                              ),
                              Text(
                                '${coupon.customerRedemptionCount} time${coupon.customerRedemptionCount == 1 ? '' : 's'}',
                                style: AppTypography.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textOnDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                        // ── Terms & Conditions ────────────────────────────
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
                  // ── Network validation error ───────────────────────────
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
                  // ── Buttons ───────────────────────────────────────────────
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

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
