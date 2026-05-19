import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/data/providers/customer_providers.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';
import 'package:besahub_app/features/customer_ui/presentation/pages/customer_business_detail_page.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_async_state.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_coupon_card.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_coupon_detail_sheet.dart';

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
      _RewardTab.used =>
        coupons
            .where((c) => c.isUsed || c.status == CustomerCouponStatus.used)
            .toList(),
    };
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
        final expiringCount = couponSource
            .where((c) => c.status == 'expiring')
            .length;

        // Count bug fix: reflect filtered count per owner tab
        final myFilteredCount = _filteredCoupons(data.myCoupons).length;
        final allFilteredCount = _filteredCoupons(data.allCoupons).length;

        return Column(
          children: [
            if (data.walletLoadFailed &&
                _couponOwnerTab == _CouponOwnerTab.myCoupons)
              _buildWalletErrorBanner(),
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
                    // 1. Rewards carousel (always at top)
                    _buildRewardsSection(data.rewards, data.businesses),
                    // 2. Expiring banner
                    _buildExpiringBanner(expiringCount),
                    // 3. Filter area
                    _buildSearchBar(),
                    _buildOwnerTabSwitcher(myFilteredCount, allFilteredCount),
                    _buildFilterTabs(),
                    // 4. Coupons section
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

  Widget _buildWalletErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: AppColors.warning,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Could not load your wallet. Pull down to retry.',
              style: AppTypography.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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

  Widget _buildRewardsSection(
    List<CustomerReward> rewards,
    List<CustomerBusiness> businesses,
  ) {
    if (rewards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'Next Rewards',
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
            itemBuilder: (_, i) {
              final reward = rewards[i];
              final matchIndex =
                  businesses.indexWhere((b) => b.id == reward.businessId);
              final business =
                  matchIndex >= 0 ? businesses[matchIndex] : null;
              return _RewardCard(
                reward: reward,
                onTap: business == null
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomerBusinessDetailPage(business: business),
                          ),
                        ),
              );
            },
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
              child: CustomerCouponCard(
                coupon: c,
                showBusinessName: true,
                onTap: () => CustomerCouponDetailSheet.show(context, c),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Reward Card ──────────────────────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.reward, this.onTap});
  final CustomerReward reward;
  final VoidCallback? onTap;

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
      onTap: onTap,
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
                  color: isSelected ? Colors.white : AppColors.textMutedDark,
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
