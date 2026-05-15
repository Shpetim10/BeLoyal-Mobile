import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/data/providers/customer_providers.dart';
import 'package:besahub_app/features/customer_ui/data/repositories/customer_repository.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_async_state.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_coupon_detail_sheet.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_coupon_qr_sheet.dart';

enum _RewardTab { all, available, coupons, used }

enum _CouponOwnerTab { myCoupons, allCoupons }

class CustomerRewardsTab extends ConsumerStatefulWidget {
  const CustomerRewardsTab({super.key});

  @override
  ConsumerState<CustomerRewardsTab> createState() => _CustomerRewardsTabState();
}

class _CustomerRewardsTabState extends ConsumerState<CustomerRewardsTab> {
  _RewardTab _selectedTab = _RewardTab.all;
  _CouponOwnerTab _couponOwnerTab = _CouponOwnerTab.myCoupons;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CustomerCoupon> _filteredCoupons(List<CustomerCoupon> source) {
    var coupons = source;
    if (_searchQuery.isNotEmpty) {
      coupons = coupons
          .where(
            (c) =>
                c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                c.businessName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }
    return switch (_selectedTab) {
      _RewardTab.all => coupons,
      _RewardTab.available =>
        coupons
            .where((c) => c.status == 'active' || c.status == 'expiring')
            .toList(),
      _RewardTab.coupons =>
        coupons
            .where((c) => c.status == 'expiring' || c.status == 'expired')
            .toList(),
      _RewardTab.used => coupons.where((c) => c.isUsed).toList(),
    };
  }

  List<CustomerReward> _filteredRewards(List<CustomerReward> rewards) {
    if (_selectedTab != _RewardTab.all &&
        _selectedTab != _RewardTab.available) {
      return [];
    }
    return rewards;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CouponRedemptionState>(customerCouponRedemptionProvider, (
      _,
      next,
    ) {
      if (next is CouponRedemptionSuccess) {
        final remaining = next.result.remainingBalance;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Coupon purchased! $remaining pts remaining',
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
      } else if (next is CouponRedemptionError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.message,
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
        ref.read(customerCouponRedemptionProvider.notifier).reset();
      }
    });

    final customerData = ref.watch(customerDataProvider);

    return customerData.when(
      loading: () => const CustomerLoadingState(),
      error: (_, __) => CustomerErrorState(
        onRetry: () => ref.read(customerDataProvider.notifier).refresh(),
      ),
      data: (data) {
        final couponSource = _couponOwnerTab == _CouponOwnerTab.myCoupons
            ? data.myCoupons
            : data.allCoupons;
        final filteredCoupons = _filteredCoupons(couponSource);
        final filteredRewards = _filteredRewards(data.rewards);
        final expiringCount = couponSource
            .where((c) => c.status == 'expiring')
            .length;

        return Column(
          children: [
            _buildSearchBar(),
            _buildOwnerTabSwitcher(data.myCoupons.length, data.allCoupons.length),
            _buildFilterTabs(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(customerDataProvider.notifier).refresh(),
                color: AppColors.primary,
                backgroundColor: const Color(0xFF1A0535),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 120),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  children: [
                    if (_selectedTab == _RewardTab.available ||
                        _selectedTab == _RewardTab.all) ...[
                      _buildExpiringBanner(expiringCount),
                      _buildRewardsSection(filteredRewards),
                    ],
                    _buildCouponsSection(filteredCoupons),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: AppTypography.dmSans(fontSize: 14, color: AppColors.textOnDark),
        decoration: InputDecoration(
          hintText: 'Search rewards & coupons...',
          hintStyle: AppTypography.dmSans(
            fontSize: 14,
            color: AppColors.textMutedDark,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textMutedDark,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(
                    Icons.clear_rounded,
                    color: AppColors.textMutedDark,
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: AppColors.cardDark,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.glassBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.glassBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerTabSwitcher(int myCount, int allCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: _OwnerTabButton(
                label: 'My Coupons',
                count: myCount,
                isSelected: _couponOwnerTab == _CouponOwnerTab.myCoupons,
                onTap: () =>
                    setState(() => _couponOwnerTab = _CouponOwnerTab.myCoupons),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OwnerTabButton(
                label: 'All Coupons',
                count: allCount,
                isSelected: _couponOwnerTab == _CouponOwnerTab.allCoupons,
                onTap: () => setState(
                  () => _couponOwnerTab = _CouponOwnerTab.allCoupons,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      (_RewardTab.all, 'All'),
      (_RewardTab.available, 'Available'),
      (_RewardTab.coupons, 'Near Expiry'),
      (_RewardTab.used, 'Used'),
    ];

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: tabs.map((entry) {
          final isSelected = _selectedTab == entry.$1;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = entry.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.glassBorder,
                ),
              ),
              child: Text(
                entry.$2,
                style: AppTypography.dmSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textMutedDark,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpiringBanner(int expiring) {
    if (expiring == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$expiring coupon${expiring > 1 ? 's' : ''} expiring soon! Use them before they\'re gone.',
              style: AppTypography.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.error,
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsSection(List<CustomerReward> rewards) {
    if (rewards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'Rewards',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemCount: rewards.length,
            itemBuilder: (_, i) => _RewardCard(reward: rewards[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildCouponsSection(List<CustomerCoupon> coupons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'Coupons',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (coupons.isEmpty)
          _EmptyCoupons(tab: _selectedTab)
        else
          ...coupons.map(
            (c) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _CouponCard(
                coupon: c,
                onDetailTap: () => CustomerCouponDetailSheet.show(context, c),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Reward Card ──────────────────────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.reward});
  final CustomerReward reward;

  @override
  Widget build(BuildContext context) {
    final hasReward = reward.pointCost > 0;
    final progress = hasReward
        ? (reward.currentPoints / reward.pointCost).clamp(0.0, 1.0)
        : 0.0;
    final canRedeem = hasReward && reward.currentPoints >= reward.pointCost;
    final remaining = hasReward
        ? (reward.pointCost - reward.currentPoints).clamp(0, reward.pointCost)
        : 0;

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 175,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: reward.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: reward.gradientColors.last.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              top: -15,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.card_giftcard_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const Spacer(),
                      if (canRedeem)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'Redeem!',
                            style: AppTypography.dmSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    reward.title,
                    style: AppTypography.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reward.businessName,
                    style: AppTypography.dmSans(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      color: canRedeem ? AppColors.gold : Colors.white,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    !hasReward
                        ? 'No rewards available'
                        : canRedeem
                        ? 'Ready to redeem!'
                        : '$remaining pts to reward',
                    style: AppTypography.dmSans(
                      fontSize: 9,
                      color: canRedeem
                          ? AppColors.gold
                          : Colors.white.withValues(alpha: 0.65),
                      fontWeight: canRedeem ? FontWeight.w700 : FontWeight.w400,
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
}

// ─── Coupon Card ──────────────────────────────────────────────────────────────

class _CouponCard extends ConsumerStatefulWidget {
  const _CouponCard({required this.coupon, this.onDetailTap});
  final CustomerCoupon coupon;
  final VoidCallback? onDetailTap;

  @override
  ConsumerState<_CouponCard> createState() => _CouponCardState();
}

class _CouponCardState extends ConsumerState<_CouponCard> {
  bool _isValidating = false;
  bool _isWaitingForResult = false;

  CustomerCoupon get coupon => widget.coupon;

  Color get _statusColor => switch (coupon.status) {
    'active' => AppColors.success,
    'expiring' => AppColors.error,
    'used' => AppColors.textMutedDark,
    'expired' => AppColors.textMutedDark,
    _ => AppColors.textMutedDark,
  };

  String get _statusLabel => switch (coupon.status) {
    'active' => 'ACTIVE',
    'expiring' => 'EXPIRING',
    'used' => 'USED',
    'expired' => 'EXPIRED',
    _ => coupon.status.toUpperCase(),
  };

  IconData get _statusIcon => switch (coupon.status) {
    'active' => Icons.check_circle_outline_rounded,
    'expiring' => Icons.timer_rounded,
    'used' => Icons.done_all_rounded,
    'expired' => Icons.cancel_outlined,
    _ => Icons.info_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    ref.listen<CouponRedemptionState>(customerCouponRedemptionProvider, (
      _,
      next,
    ) {
      if (!_isWaitingForResult) return;
      if (next is CouponRedemptionSuccess) {
        if (mounted) setState(() => _isWaitingForResult = false);
        CustomerCouponQrSheet.show(
          context,
          _buildQrCoupon(coupon, next.result),
        );
      } else if (next is CouponRedemptionIdle || next is CouponRedemptionError) {
        if (mounted) setState(() => _isWaitingForResult = false);
      }
    });

    final isActive = coupon.status == 'active' || coupon.status == 'expiring';
    final expiresAt = DateFormat('MMM d').format(coupon.expiresAt);
    final expiresIn = coupon.expiresIn ?? 'Expires soon';
    final redemptionState = ref.watch(customerCouponRedemptionProvider);
    final isClaimLoading =
        (redemptionState is CouponRedemptionLoading) || _isValidating;

    return GestureDetector(
      onTap: widget.onDetailTap,
      child: Opacity(
        opacity: coupon.canBuyMore
            ? 1.0
            : coupon.isUsed || coupon.status == 'expired'
            ? 0.55
            : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: coupon.status == 'expiring'
                  ? AppColors.error.withValues(alpha: 0.35)
                  : AppColors.glassBorder,
            ),
          ),
          child: Row(
            children: [
              // Left gradient strip
              Container(
                width: 72,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: !coupon.canBuyMore &&
                            (coupon.isUsed || coupon.status == 'expired')
                        ? [const Color(0xFF374151), const Color(0xFF6B7280)]
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
                    Text(
                      coupon.discountDisplay,
                      style: AppTypography.outfit(
                        fontSize: coupon.discountDisplay.length > 6 ? 13 : 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      coupon.type == 'FREE_PRODUCT'
                          ? Icons.card_giftcard_rounded
                          : coupon.type == 'PERCENTAGE_DISCOUNT'
                          ? Icons.percent_rounded
                          : Icons.discount_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 16,
                    ),
                  ],
                ),
              ),
              // Dashed divider
              CustomPaint(
                size: const Size(1, 100),
                painter: _DashedLinePainter(),
              ),
              // Right content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _statusIcon,
                                  size: 10,
                                  color: _statusColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _statusLabel,
                                  style: AppTypography.dmSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: _statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coupon.businessName,
                        style: AppTypography.dmSans(
                          fontSize: 11,
                          color: AppColors.textMutedDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (coupon.status == 'expiring')
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 11,
                              color: AppColors.error,
                            )
                          else
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: AppColors.textMutedDark,
                            ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$expiresAt • $expiresIn',
                              style: AppTypography.dmSans(
                                fontSize: 11,
                                fontWeight: coupon.status == 'expiring'
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
                          // "Use Now" — show QR for an owned, not-yet-used instance
                          if (isActive && coupon.isOwned && !coupon.isUsed) ...[
                            GestureDetector(
                              onTap: () =>
                                  CustomerCouponQrSheet.show(context, coupon),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primaryDark,
                                      AppColors.primary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Use Now',
                                  style: AppTypography.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            if (coupon.canBuyMore) const SizedBox(width: 6),
                          ],
                          // "Buy More" — shown whenever per-customer limit allows it
                          if (coupon.canBuyMore)
                            GestureDetector(
                              onTap: isClaimLoading
                                  ? null
                                  : () => _confirmAndClaim(context),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isClaimLoading
                                      ? null
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFF1D4ED8),
                                            Color(0xFF2563EB),
                                          ],
                                        ),
                                  color: isClaimLoading
                                      ? AppColors.cardDark
                                      : null,
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
                                          valueColor: AlwaysStoppedAnimation(
                                            AppColors.primary,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        coupon.isOwned ? 'Buy More' : 'Claim',
                                        style: AppTypography.dmSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            )
                          // "Claim" — unowned coupon, not yet purchased
                          else if (isActive && !coupon.isOwned)
                            GestureDetector(
                              onTap: isClaimLoading
                                  ? null
                                  : () => _confirmAndClaim(context),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isClaimLoading
                                      ? null
                                      : const LinearGradient(
                                          colors: [
                                            AppColors.primaryDark,
                                            AppColors.primary,
                                          ],
                                        ),
                                  color: isClaimLoading
                                      ? AppColors.cardDark
                                      : null,
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
                                          valueColor: AlwaysStoppedAnimation(
                                            AppColors.primary,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Claim',
                                        style: AppTypography.dmSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                        ],
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

  Future<void> _confirmAndClaim(BuildContext context) async {
    if (_isValidating) return;
    setState(() => _isValidating = true);

    final messenger = ScaffoldMessenger.of(context);

    ValidateRedemptionDto? validation;
    String? networkError;
    try {
      validation = await ref
          .read(customerRepositoryProvider)
          .validateRedemption(coupon.id);
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

    final confirmed = await _RewardsClaimDialog.show(
      context, // ignore: use_build_context_synchronously
      coupon,
      validation: validation,
      networkError: networkError,
    );
    if (confirmed == true && mounted) {
      setState(() => _isWaitingForResult = true);
      ref
          .read(customerCouponRedemptionProvider.notifier)
          .redeemCoupon(couponId: coupon.id, couponTitle: coupon.title);
    }
  }

  CustomerCoupon _buildQrCoupon(
    CustomerCoupon original,
    CustomerCouponRedemptionDto result,
  ) {
    final expiresAt = result.expiresAt != null
        ? DateTime.tryParse(result.expiresAt!) ?? original.expiresAt
        : original.expiresAt;
    final now = DateTime.now();
    String? expiresIn;
    if (expiresAt.isAfter(now)) {
      final hours = expiresAt.difference(now).inHours;
      expiresIn = hours < 24
          ? 'Expires in ${hours}h'
          : 'Expires in ${expiresAt.difference(now).inDays}d';
    }
    return CustomerCoupon(
      id: result.couponId,
      businessId: original.businessId,
      businessName: original.businessName,
      title: result.snapshotTitle,
      discountValue: original.discountValue,
      discountDisplay: original.discountDisplay,
      status: 'active',
      expiresAt: expiresAt,
      pointCost: result.pointsSpent,
      gradientColors: original.gradientColors,
      type: result.snapshotCouponType,
      isUsed: false,
      description: result.snapshotDescription,
      expiresIn: expiresIn,
      termsAndConditions: original.termsAndConditions,
      usageLimit: original.usageLimit,
      usageCount: original.usageCount,
      customerRedemptionCount: original.customerRedemptionCount + 1,
      isOwned: true,
      imageUrl: result.snapshotImageUrl ?? original.imageUrl,
      currency: result.currency ?? original.currency,
      customerCouponId: result.customerCouponId,
      isFeatured: original.isFeatured,
      totalRedemptions: original.totalRedemptions,
      totalRedemptionLimit: original.totalRedemptionLimit,
      minimumOrderAmount: original.minimumOrderAmount,
      maximumDiscountAmount: original.maximumDiscountAmount,
      freeProductName: original.freeProductName,
      freeProductVariant: original.freeProductVariant,
      freeProductCategory: original.freeProductCategory,
      freeProductQuantity: original.freeProductQuantity,
      redeemedAt: result.redeemedAt != null
          ? DateTime.tryParse(result.redeemedAt!)
          : null,
      qrCode: result.qrCode,
    );
  }
}

// ─── Rewards Claim Confirmation Dialog ───────────────────────────────────────

class _RewardsClaimDialog {
  const _RewardsClaimDialog._();

  static Future<bool?> show(
    BuildContext context,
    CustomerCoupon coupon, {
    ValidateRedemptionDto? validation,
    String? networkError,
  }) {
    final balanceBefore = validation?.customerBalance;
    final cost = validation?.pointsRequired ?? coupon.pointCost;
    final balanceAfter =
        balanceBefore != null ? balanceBefore - cost : null;

    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 40,
        ),
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
                height: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.confirmation_number_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Confirm Purchase',
                      style: AppTypography.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      coupon.title,
                      style: AppTypography.dmSans(
                        fontSize: 13,
                        color: AppColors.textMutedDark,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 18),
                    // Cost row
                    _DialogRow(
                      icon: Icons.toll_rounded,
                      label: 'Cost',
                      value: '$cost pts',
                      valueColor: AppColors.primary,
                      valueBold: true,
                    ),
                    if (balanceBefore != null) ...[
                      const SizedBox(height: 8),
                      _DialogRow(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Balance',
                        value:
                            '$balanceBefore pts → ${balanceAfter! < 0 ? 0 : balanceAfter} pts',
                        valueColor: AppColors.textMutedDark,
                      ),
                    ],
                    if (coupon.usageLimit != null) ...[
                      const SizedBox(height: 8),
                      _DialogRow(
                        icon: Icons.repeat_rounded,
                        label: 'Your usage',
                        value:
                            '${coupon.customerRedemptionCount}/${coupon.usageLimit}',
                        valueColor: AppColors.textMutedDark,
                      ),
                    ],
                    if (coupon.termsAndConditions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Terms: ${coupon.termsAndConditions}',
                        style: AppTypography.dmSans(
                          fontSize: 11,
                          color: AppColors.textMutedDark,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (coupon.isOwned) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'You already own this coupon. Buying again adds another.',
                              style: AppTypography.dmSans(
                                fontSize: 11,
                                color: AppColors.primary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (networkError != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              size: 13,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                networkError,
                                style: AppTypography.dmSans(
                                  fontSize: 11,
                                  color: AppColors.warning,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(false),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.glassBorder,
                                ),
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
                              height: 46,
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
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 10,
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
      ),
    );
  }
}

class _DialogRow extends StatelessWidget {
  const _DialogRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMutedDark),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.dmSans(
            fontSize: 13,
            color: AppColors.textMutedDark,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.dmSans(
            fontSize: 13,
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? AppColors.textOnDark,
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.glassBorder
      ..strokeWidth = 1;
    const dashHeight = 5.0;
    const dashSpace = 4.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OwnerTabButton extends StatelessWidget {
  const _OwnerTabButton({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color:
                      isSelected ? Colors.white : AppColors.textMutedDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.18)
                    : AppColors.glassBorder,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: AppTypography.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textMutedDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCoupons extends StatelessWidget {
  const _EmptyCoupons({required this.tab});
  final _RewardTab tab;

  @override
  Widget build(BuildContext context) {
    final message = switch (tab) {
      _RewardTab.used => 'No used coupons yet.\nStart redeeming your rewards!',
      _RewardTab.coupons => 'No coupons near expiry.\nYou\'re all caught up!',
      _ => 'No coupons found.\nExplore businesses to earn rewards!',
    };

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            tab == _RewardTab.used
                ? Icons.done_all_rounded
                : Icons.confirmation_number_outlined,
            size: 52,
            color: AppColors.textMutedDark.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.dmSans(
              fontSize: 14,
              color: AppColors.textMutedDark,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
