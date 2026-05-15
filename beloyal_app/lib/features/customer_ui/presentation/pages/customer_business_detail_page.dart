import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/data/providers/customer_providers.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_data_source.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_async_state.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_coupon_detail_sheet.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_menu_item_detail_sheet.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_transaction_detail_sheet.dart';

class CustomerBusinessDetailPage extends ConsumerStatefulWidget {
  const CustomerBusinessDetailPage({super.key, required this.business});
  final CustomerBusiness business;

  @override
  ConsumerState<CustomerBusinessDetailPage> createState() =>
      _CustomerBusinessDetailPageState();
}

class _CustomerBusinessDetailPageState
    extends ConsumerState<CustomerBusinessDetailPage> {
  int _selectedTab = 0;

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded, label: 'Overview'),
    _TabItem(icon: Icons.restaurant_menu_rounded, label: 'Menu'),
    _TabItem(
      icon: Icons.confirmation_number_rounded,
      label: 'Coupons & Offers',
    ),
    _TabItem(icon: Icons.receipt_long_rounded, label: 'Transactions'),
    _TabItem(icon: Icons.location_on_rounded, label: 'Location'),
    _TabItem(icon: Icons.info_outline_rounded, label: 'Info'),
  ];

  CustomerBusiness get _b => widget.business;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final customerData = ref.watch(customerDataProvider);
    final detail = ref.watch(customerBusinessDetailProvider(_b.id));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0812),
      body: customerData.when(
        loading: () => const CustomerLoadingState(),
        error: (_, __) => CustomerErrorState(
          onRetry: () => ref.read(customerDataProvider.notifier).refresh(),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(customerDataProvider.notifier).refresh();
            ref.invalidate(customerBusinessDetailProvider(_b.id));
          },
          color: AppColors.primary,
          backgroundColor: const Color(0xFF1A0535),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _buildSliverAppBar(topPad),
              SliverToBoxAdapter(child: _buildBusinessInfo()),
              SliverToBoxAdapter(child: _buildPointsCard(detail)),
              SliverToBoxAdapter(child: _buildTabBar()),
              SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  child: KeyedSubtree(
                    key: ValueKey(_selectedTab),
                    child: _buildTabContent(data, detail),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(double topPad) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: const Color(0xFF0A0812),
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
      actions: const [],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [..._b.gradientColors, const Color(0xFF0A0812)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: 20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _b.gradientColors.last.withValues(alpha: 0.15),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _b.gradientColors.last.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _b.logoUrl != null && _b.logoUrl!.isNotEmpty
                      ? Image.network(
                          _b.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              _b.logoEmoji,
                              style: const TextStyle(fontSize: 36),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _b.logoEmoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _b.name,
                  style: AppTypography.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textOnDark,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.gold,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _b.rating.toStringAsFixed(2),
                    style: AppTypography.dmMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  _b.category,
                  style: AppTypography.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _b.description,
            style: AppTypography.dmSans(
              fontSize: 13,
              color: AppColors.textMutedDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(AsyncValue<CustomerBusinessDetail> detail) {
    final detailVal = detail.asData?.value;
    final points = detailVal?.currentPoints ?? _b.points;
    final nextReward = detailVal?.nextRewardPoints ?? _b.nextRewardPoints;
    // Prefer backend-computed pointsToNextReward when available
    final remaining =
        detailVal?.pointsToNextReward ??
        (nextReward - points).clamp(0, nextReward);
    final progress = nextReward > 0
        ? ((nextReward - remaining) / nextReward).clamp(0.0, 1.0)
        : 0.0;
    final memberCode = detailVal?.memberCode ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _b.gradientColors.first.withValues(alpha: 0.8),
            _b.gradientColors.last.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _b.gradientColors.last.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: _b.gradientColors.last.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Points',
                      style: AppTypography.dmSans(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$points pts',
                      style: AppTypography.dmMono(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        color: Colors.white,
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nextReward == 0
                          ? 'No rewards available'
                          : remaining > 0
                          ? '$remaining pts to reward'
                          : 'Ready to redeem!',
                      style: AppTypography.dmSans(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (memberCode.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.badge_outlined,
                  size: 13,
                  color: Colors.white60,
                ),
                const SizedBox(width: 6),
                Text(
                  'Member Code',
                  style: AppTypography.dmSans(
                    fontSize: 10,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    memberCode,
                    style: AppTypography.dmMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: memberCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Member code copied',
                          style: AppTypography.dmSans(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: AppColors.cardDark,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _tabs.length,
        itemBuilder: (_, i) {
          final tab = _tabs[i];
          final isSelected = _selectedTab == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          _b.gradientColors.first.withValues(alpha: 0.8),
                          _b.gradientColors.last,
                        ],
                      )
                    : null,
                color: isSelected ? null : AppColors.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? _b.gradientColors.last.withValues(alpha: 0.5)
                      : AppColors.glassBorder,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _b.gradientColors.last.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab.icon,
                    size: 14,
                    color: isSelected ? Colors.white : AppColors.textMutedDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tab.label,
                    style: AppTypography.dmSans(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textMutedDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent(
    CustomerDataSource data,
    AsyncValue<CustomerBusinessDetail> detail,
  ) {
    final detailData = detail.asData?.value;
    return switch (_selectedTab) {
      0 => _OverviewTab(
        business: _b,
        data: data,
        onCouponsTap: () => setState(() => _selectedTab = 2),
        onDirectionsTap: () => setState(() => _selectedTab = 4),
      ),
      1 => _MenuTab(business: _b, detail: detail),
      2 => _CouponsTab(
        coupons: detailData?.coupons ?? data.couponsForBusiness(_b.id),
      ),
      3 => _TransactionsTab(
        txs: detailData?.transactions ?? data.transactionsForBusiness(_b.id),
      ),
      4 => _LocationTab(business: _b, location: detailData?.location),
      5 => _InfoTab(business: _b, detail: detailData),
      _ => const SizedBox.shrink(),
    };
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.business,
    required this.data,
    required this.onCouponsTap,
    required this.onDirectionsTap,
  });
  final CustomerBusiness business;
  final CustomerDataSource data;
  final VoidCallback onCouponsTap;
  final VoidCallback onDirectionsTap;

  @override
  Widget build(BuildContext context) {
    final coupons = data
        .couponsForBusiness(business.id)
        .where((c) => c.status == 'active' || c.status == 'expiring')
        .take(3)
        .toList();
    // Only show hot offers that are genuinely backed by isHot backend field
    final offers = data
        .offersForBusiness(business.id)
        .where((c) => c.isHot)
        .toList();
    final rewards = data.rewardsForBusiness(business.id).take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (coupons.isNotEmpty) ...[
            const SizedBox(height: 22),
            _SubSectionHeader(title: 'Active Coupons', count: coupons.length),
            const SizedBox(height: 10),
            ...coupons.map((c) => _OverviewCouponRow(coupon: c)),
          ],
          if (offers.isNotEmpty) ...[
            const SizedBox(height: 22),
            _SubSectionHeader(title: 'Hot Offers', count: offers.length),
            const SizedBox(height: 10),
            ...offers.map((o) => _OverviewOfferRow(offer: o)),
          ],
          if (rewards.isNotEmpty) ...[
            const SizedBox(height: 22),
            _SubSectionHeader(
              title: 'Available Rewards',
              count: rewards.length,
            ),
            const SizedBox(height: 10),
            ...rewards.map((r) => _OverviewRewardRow(reward: r)),
          ],
          if (coupons.isEmpty && offers.isEmpty && rewards.isEmpty) ...[
            const SizedBox(height: 32),
            const _EmptyState(
              icon: Icons.store_outlined,
              message: 'Nothing active right now.\nCheck back soon for offers!',
            ),
          ],
        ],
      ),
    );
  }
}

class _SubSectionHeader extends StatelessWidget {
  const _SubSectionHeader({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textOnDark,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: AppTypography.dmMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewCouponRow extends StatelessWidget {
  const _OverviewCouponRow({required this.coupon});
  final CustomerCoupon coupon;

  @override
  Widget build(BuildContext context) {
    final color = coupon.status == 'expiring'
        ? AppColors.error
        : AppColors.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: coupon.status == 'expiring'
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: coupon.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                coupon.discountDisplay.length <= 4
                    ? coupon.discountDisplay
                    : coupon.type == 'FREE_PRODUCT'
                    ? '🎁'
                    : '%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnDark,
                  ),
                ),
                Text(
                  '${coupon.pointCost} pts',
                  style: AppTypography.dmSans(
                    fontSize: 11,
                    color: AppColors.textMutedDark,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              coupon.status == 'expiring' ? 'Expiring' : 'Active',
              style: AppTypography.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewOfferRow extends StatelessWidget {
  const _OverviewOfferRow({required this.offer});
  final CustomerCoupon offer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: offer.gradientColors
              .map((c) => c.withValues(alpha: 0.15))
              .toList(),
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: offer.gradientColors.last.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: offer.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                offer.multiplierLabel ?? offer.discountDisplay,
                style: AppTypography.dmMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: AppTypography.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnDark,
                  ),
                ),
                Text(
                  offer.description,
                  style: AppTypography.dmSans(
                    fontSize: 11,
                    color: AppColors.textMutedDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (offer.isHot)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 10,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'HOT',
                    style: AppTypography.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
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

class _OverviewRewardRow extends StatelessWidget {
  const _OverviewRewardRow({required this.reward});
  final CustomerReward reward;

  @override
  Widget build(BuildContext context) {
    final canRedeem = reward.currentPoints >= reward.pointCost;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: canRedeem
              ? AppColors.gold.withValues(alpha: 0.3)
              : AppColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: reward.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: AppTypography.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnDark,
                  ),
                ),
                Text(
                  '${reward.pointCost} pts required',
                  style: AppTypography.dmSans(
                    fontSize: 11,
                    color: AppColors.textMutedDark,
                  ),
                ),
              ],
            ),
          ),
          if (canRedeem)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Redeem',
                style: AppTypography.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          else
            Text(
              '${reward.pointCost - reward.currentPoints} pts away',
              style: AppTypography.dmSans(
                fontSize: 11,
                color: AppColors.textMutedDark,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Menu Tab ─────────────────────────────────────────────────────────────────

class _MenuTab extends StatefulWidget {
  const _MenuTab({required this.business, required this.detail});
  final CustomerBusiness business;
  final AsyncValue<CustomerBusinessDetail> detail;

  @override
  State<_MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<_MenuTab> {
  int? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    return widget.detail.when(
      loading: () => _buildMenuSkeleton(),
      error: (_, __) => Padding(
        padding: const EdgeInsets.only(top: 40),
        child: _EmptyState(
          icon: Icons.restaurant_menu_outlined,
          message: 'Could not load menu.\nPull to refresh.',
        ),
      ),
      data: (detail) {
        if (detail.menuItems.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: _EmptyState(
              icon: Icons.restaurant_menu_outlined,
              message: 'No menu available yet.',
            ),
          );
        }
        final items = detail.itemsForCategory(_selectedCategoryId);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (detail.menuCategories.length > 1) ...[
              const SizedBox(height: 20),
              _buildCategoryTabs(detail.menuCategories),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedCategoryId != null) ...[
                    Text(
                      detail.menuCategories
                          .firstWhere(
                            (c) => c.id == _selectedCategoryId,
                            orElse: () => detail.menuCategories.first,
                          )
                          .name,
                      style: AppTypography.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ...items.map(
                    (item) => _FancyMenuItemCard(
                      item: item,
                      accentColors: widget.business.gradientColors,
                      onTap: () => CustomerMenuItemDetailSheet.show(
                        context,
                        item,
                        widget.business.gradientColors,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryTabs(List<CustomerMenuCategory> categories) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _MenuCategoryChip(
            label: 'All',
            isSelected: _selectedCategoryId == null,
            accentColors: widget.business.gradientColors,
            onTap: () => setState(() => _selectedCategoryId = null),
          ),
          ...categories.map(
            (c) => _MenuCategoryChip(
              label: c.name,
              isSelected: _selectedCategoryId == c.id,
              accentColors: widget.business.gradientColors,
              onTap: () => setState(
                () => _selectedCategoryId = _selectedCategoryId == c.id
                    ? null
                    : c.id,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category chips skeleton
          Row(
            children: List.generate(
              3,
              (i) => Container(
                width: 80,
                height: 36,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            3,
            (_) => Container(
              height: 110,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCategoryChip extends StatelessWidget {
  const _MenuCategoryChip({
    required this.label,
    required this.isSelected,
    required this.accentColors,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final List<Color> accentColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    accentColors.first.withValues(alpha: 0.8),
                    accentColors.last,
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.cardDark,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? accentColors.last.withValues(alpha: 0.5)
                : AppColors.glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColors.last.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.dmSans(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textMutedDark,
          ),
        ),
      ),
    );
  }
}

class _FancyMenuItemCard extends StatelessWidget {
  const _FancyMenuItemCard({
    required this.item,
    required this.accentColors,
    this.onTap,
  });
  final CustomerMenuItem item;
  final List<Color> accentColors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasVariants = item.variants.isNotEmpty;
    final isSingleVariant = item.variants.length == 1;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: item.isAvailable ? 1.0 : 0.45,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.isPopular
                  ? AppColors.gold.withValues(alpha: 0.25)
                  : AppColors.glassBorder,
            ),
            boxShadow: item.isPopular
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image or emoji hero
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildMenuItemEmoji(),
                          )
                        : _buildMenuItemEmoji(),
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name row with popular badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: AppTypography.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textOnDark,
                              ),
                            ),
                          ),
                          if (item.isPopular) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFB8860B), AppColors.gold],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 9,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Popular',
                                    style: AppTypography.dmSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: AppTypography.dmSans(
                            fontSize: 12,
                            color: AppColors.textMutedDark,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 10),
                      if (!hasVariants) ...[
                        _buildBasePriceRow(),
                      ] else if (isSingleVariant) ...[
                        _buildSingleVariantRow(),
                      ] else ...[
                        _buildMultiVariantRow(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasePriceRow() {
    final earnLabel = _earnLabelFromItem();
    final displayLabel =
        earnLabel ?? (item.pointsLabel.isNotEmpty ? item.pointsLabel : null);
    final symbol = item.baseCurrency.isEmpty ? 'L' : item.baseCurrency;
    final hasBasePrice = item.basePrice != null;
    return Row(
      children: [
        if (hasBasePrice)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.elevDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Text(
              '${item.basePrice!.toStringAsFixed(0)} $symbol${item.unit.isNotEmpty ? ' / ${item.unit}' : ''}',
              style: AppTypography.dmMono(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textOnDark,
              ),
            ),
          ),
        if (hasBasePrice && displayLabel != null) const Spacer(),
        if (displayLabel != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              displayLabel,
              style: AppTypography.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSingleVariantRow() {
    final variant = item.variants.first;
    final earnLabel = _earnLabelFromItem() ?? _earnLabel(variant);
    final displayLabel =
        earnLabel ?? (item.pointsLabel.isNotEmpty ? item.pointsLabel : null);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.elevDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Text(
            '${variant.formattedPrice}${item.unit.isNotEmpty ? ' / ${item.unit}' : ''}',
            style: AppTypography.dmMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnDark,
            ),
          ),
        ),
        const Spacer(),
        if (displayLabel != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              displayLabel,
              style: AppTypography.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMultiVariantRow() {
    final itemEarnedPoints = item.earnedPoints;
    final anyEarnedPoints =
        itemEarnedPoints != null && itemEarnedPoints > 0 ||
        item.variants.any((v) => v.earnedPoints != null && v.earnedPoints! > 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: item.variants.map((v) {
            final isDefault = v.isDefault;
            final earn = _earnLabel(v);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: isDefault
                    ? LinearGradient(
                        colors: [
                          accentColors.first.withValues(alpha: 0.4),
                          accentColors.last.withValues(alpha: 0.3),
                        ],
                      )
                    : null,
                color: isDefault ? null : AppColors.elevDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDefault
                      ? accentColors.last.withValues(alpha: 0.4)
                      : AppColors.glassBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${v.name}  ${v.formattedPrice}',
                    style: AppTypography.dmSans(
                      fontSize: 11,
                      fontWeight: isDefault ? FontWeight.w600 : FontWeight.w400,
                      color: isDefault ? Colors.white : AppColors.textMutedDark,
                    ),
                  ),
                  if (earn != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      earn,
                      style: AppTypography.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
        if (!anyEarnedPoints && item.pointsLabel.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              item.pointsLabel,
              style: AppTypography.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ] else if (anyEarnedPoints &&
            itemEarnedPoints != null &&
            itemEarnedPoints > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              '+$itemEarnedPoints pts',
              style: AppTypography.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String? _earnLabel(CustomerMenuVariant v) {
    if (v.earnedPoints != null && v.earnedPoints! > 0) {
      return '+${v.earnedPoints} pts';
    }
    return null;
  }

  String? _earnLabelFromItem() {
    if (item.earnedPoints != null && item.earnedPoints! > 0) {
      return '+${item.earnedPoints} pts';
    }
    return null;
  }

  Widget _buildMenuItemEmoji() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColors.first.withValues(alpha: 0.6),
            accentColors.last.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(item.emoji, style: const TextStyle(fontSize: 30)),
      ),
    );
  }
}

// ─── Coupons Tab ──────────────────────────────────────────────────────────────

class _CouponsTab extends StatefulWidget {
  const _CouponsTab({required this.coupons});
  final List<CustomerCoupon> coupons;

  @override
  State<_CouponsTab> createState() => _CouponsTabState();
}

class _CouponsTabState extends State<_CouponsTab> {
  bool _showMyCoupons = true;

  @override
  Widget build(BuildContext context) {
    final myCoupons = widget.coupons.where((c) => c.isOwned).toList();
    final allCoupons = widget.coupons;

    final displayedCoupons = _showMyCoupons ? myCoupons : allCoupons;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _CouponsTabButton(
                    label: 'My Coupons',
                    count: myCoupons.length,
                    isSelected: _showMyCoupons,
                    onTap: () => setState(() => _showMyCoupons = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CouponsTabButton(
                    label: 'All Coupons',
                    count: allCoupons.length,
                    isSelected: !_showMyCoupons,
                    onTap: () => setState(() => _showMyCoupons = false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (displayedCoupons.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: _EmptyState(
                icon: Icons.confirmation_number_outlined,
                message: _showMyCoupons
                    ? 'No coupons found in your wallet.'
                    : 'No coupons for this business yet.',
              ),
            )
          else
            ...displayedCoupons.map(
              (c) => _DetailCouponCard(
                coupon: c,
                onTap: () => CustomerCouponDetailSheet.show(context, c),
              ),
            ),
        ],
      ),
    );
  }
}

class _CouponsTabButton extends StatelessWidget {
  const _CouponsTabButton({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

class _DetailCouponCard extends StatelessWidget {
  const _DetailCouponCard({required this.coupon, this.onTap});
  final CustomerCoupon coupon;
  final VoidCallback? onTap;

  Color get _statusColor => switch (coupon.status) {
    'active' => AppColors.success,
    'expiring' => AppColors.error,
    'used' => AppColors.textMutedDark,
    'expired' => AppColors.textMutedDark,
    _ => AppColors.textMutedDark,
  };

  String get _statusLabel => switch (coupon.status) {
    'active' => 'Active',
    'expiring' => 'Expiring',
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

  @override
  Widget build(BuildContext context) {
    final isActive = coupon.status == 'active' || coupon.status == 'expiring';
    final expiresAt = DateFormat('MMM d').format(coupon.expiresAt);
    final expiresIn = coupon.expiresIn ?? 'Expires soon';

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: coupon.isUsed || coupon.status == 'expired' ? 0.55 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: coupon.status == 'expiring'
                  ? AppColors.error.withValues(alpha: 0.35)
                  : AppColors.glassBorder,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 76,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: coupon.isUsed || coupon.status == 'expired'
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
                            fontSize: coupon.discountDisplay.length > 6
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
                    ),
                  ),
                  CustomPaint(
                    size: const Size(1, 110),
                    painter: _DashedPainter(),
                  ),
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
                              if (coupon.isFeatured) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
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
                                  color: _statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
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
                          ),
                          const SizedBox(height: 4),
                          if (coupon.description.isNotEmpty)
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
                              if (isActive)
                                Container(
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
                            ],
                          ),
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
                                if (coupon.usageLimit != null) ...[
                                  const SizedBox(width: 10),
                                  Text(
                                    '${coupon.usageCount}/${coupon.usageLimit} used',
                                    style: AppTypography.dmSans(
                                      fontSize: 11,
                                      color: AppColors.textMutedDark,
                                    ),
                                  ),
                                ] else if (coupon.totalRedemptionLimit !=
                                    null) ...[
                                  const SizedBox(width: 10),
                                  Text(
                                    '${coupon.totalRedemptions}/${coupon.totalRedemptionLimit} redeemed',
                                    style: AppTypography.dmSans(
                                      fontSize: 11,
                                      color: AppColors.textMutedDark,
                                    ),
                                  ),
                                ],
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
                      color: AppColors.textMutedDark.withValues(alpha: 0.6),
                      height: 1.4,
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

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.glassBorder
      ..strokeWidth = 1;
    const dashH = 5.0, dashSpace = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashH), paint);
      y += dashH + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Transactions Tab ─────────────────────────────────────────────────────────

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab({required this.txs});
  final List<CustomerTransaction> txs;

  @override
  Widget build(BuildContext context) {
    if (txs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: _EmptyState(
          icon: Icons.receipt_long_outlined,
          message: 'No transactions at this business yet.',
        ),
      );
    }

    final dateFmt = DateFormat('MMM d – h:mm a');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: txs.map((tx) {
          final isPositive = tx.points > 0;
          final color = switch (tx.type) {
            'EARN' => AppColors.success,
            'REFUND' => AppColors.info,
            'ADJUSTMENT' => AppColors.warning,
            'EXPIRED' => AppColors.textMutedDark,
            _ => AppColors.error,
          };
          final icon = switch (tx.type) {
            'EARN' => Icons.arrow_upward_rounded,
            'REFUND' => Icons.undo_rounded,
            'ADJUSTMENT' => Icons.tune_rounded,
            'EXPIRED' => Icons.hourglass_empty_rounded,
            _ => Icons.arrow_downward_rounded,
          };

          return GestureDetector(
            onTap: () => CustomerTransactionDetailSheet.show(context, tx),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder),
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
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.description,
                          style: AppTypography.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              dateFmt.format(tx.date),
                              style: AppTypography.dmSans(
                                fontSize: 11,
                                color: AppColors.textMutedDark,
                              ),
                            ),
                            if (tx.billAmount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.elevDark,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${(tx.currency ?? 'L')} ${tx.billAmount.toStringAsFixed(0)}',
                                  style: AppTypography.dmMono(
                                    fontSize: 10,
                                    color: AppColors.textMutedDark,
                                  ),
                                ),
                              ),
                            ] else if (tx.netAmount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.elevDark,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${(tx.currency ?? 'L')} ${tx.netAmount.toStringAsFixed(0)}',
                                  style: AppTypography.dmMono(
                                    fontSize: 10,
                                    color: AppColors.textMutedDark,
                                  ),
                                ),
                              ),
                            ],
                            if (tx.discountAmount != null &&
                                tx.discountAmount! > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '-${(tx.currency ?? 'L')} ${tx.discountAmount!.toStringAsFixed(0)}',
                                  style: AppTypography.dmMono(
                                    fontSize: 10,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                            if (tx.invoiceReference?.isNotEmpty == true) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tx.invoiceReference!,
                                  style: AppTypography.dmMono(
                                    fontSize: 10,
                                    color: AppColors.textMutedDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isPositive ? '+' : ''}${tx.points}',
                        style: AppTypography.dmMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      Text(
                        'pts',
                        style: AppTypography.dmSans(
                          fontSize: 10,
                          color: AppColors.textMutedDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Location Tab ─────────────────────────────────────────────────────────────

class _LocationTab extends StatelessWidget {
  const _LocationTab({required this.business, this.location});
  final CustomerBusiness business;
  final CustomerBusinessLocation? location;

  @override
  Widget build(BuildContext context) {
    final loc = location;

    // Determine the address string to show.
    final mapLabel = loc?.mapLabel.isNotEmpty == true
        ? loc!.mapLabel
        : business.address;
    final addressLine1 = loc?.addressLine1.isNotEmpty == true
        ? loc!.addressLine1
        : business.address;
    final city = loc?.city ?? '';
    final country = loc?.country ?? '';
    final postalCode = loc?.postalCode ?? '';

    final addressParts = [
      if (addressLine1.isNotEmpty) addressLine1,
      if (loc?.addressLine2.isNotEmpty == true) loc!.addressLine2,
      if (city.isNotEmpty) city,
      if (postalCode.isNotEmpty) postalCode,
      if (country.isNotEmpty) country,
    ];
    final fullAddress = addressParts.isNotEmpty
        ? addressParts.join(', ')
        : mapLabel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Decorative map hero ─────────────────────────────────────────
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  business.gradientColors.first.withValues(alpha: 0.5),
                  business.gradientColors.last.withValues(alpha: 0.35),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: business.gradientColors.last.withValues(alpha: 0.3),
              ),
            ),
            child: Stack(
              children: [
                // Decorative grid pattern
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CustomPaint(
                    size: const Size(double.infinity, 200),
                    painter: _MapGridPainter(),
                  ),
                ),
                // Content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: business.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: business.gradientColors.last.withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        business.name,
                        style: AppTypography.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      if (mapLabel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            mapLabel,
                            style: AppTypography.dmSans(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.75),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Address card ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Address',
                            style: AppTypography.dmSans(
                              fontSize: 11,
                              color: AppColors.textMutedDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (addressLine1.isNotEmpty)
                            Text(
                              addressLine1,
                              style: AppTypography.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textOnDark,
                              ),
                            ),
                          if (city.isNotEmpty || country.isNotEmpty)
                            Text(
                              [
                                if (city.isNotEmpty) city,
                                if (loc?.postalCode.isNotEmpty == true)
                                  loc!.postalCode,
                                if (country.isNotEmpty) country,
                              ].join(', '),
                              style: AppTypography.dmSans(
                                fontSize: 12,
                                color: AppColors.textMutedDark,
                              ),
                            ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (fullAddress.isNotEmpty) {
                          Clipboard.setData(ClipboardData(text: fullAddress));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Address copied',
                                style: AppTypography.dmSans(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: AppColors.cardDark,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.copy_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Copy',
                              style: AppTypography.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Get Directions ──────────────────────────────────────────────
          if (fullAddress.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                // Copy address and guide user to paste in their maps app
                Clipboard.setData(ClipboardData(text: fullAddress));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Address copied — paste in Maps to get directions',
                      style: AppTypography.dmSans(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: AppColors.cardDark,
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      business.gradientColors.first.withValues(alpha: 0.7),
                      business.gradientColors.last,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: business.gradientColors.last.withValues(
                        alpha: 0.3,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.directions_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Get Directions',
                      style: AppTypography.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Info Tab ─────────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.business, this.detail});
  final CustomerBusiness business;
  final CustomerBusinessDetail? detail;

  @override
  Widget build(BuildContext context) {
    final effectiveAbout = detail?.about.isNotEmpty == true
        ? detail!.about
        : business.description;
    final effectivePolicy = detail?.loyaltyPolicy ?? '';
    final effectivePhone = detail?.phone.isNotEmpty == true
        ? detail!.phone
        : business.phone;
    final effectiveEmail = detail?.email.isNotEmpty == true
        ? detail!.email
        : business.email;
    final effectiveCategory = detail?.categoryLabel.isNotEmpty == true
        ? detail!.categoryLabel
        : business.category;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            icon: Icons.info_outline_rounded,
            label: 'About',
            value: effectiveAbout,
          ),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: effectivePhone,
          ),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: effectiveEmail,
          ),
          _InfoRow(
            icon: Icons.category_outlined,
            label: 'Category',
            value: effectiveCategory,
          ),
          _InfoRow(
            icon: Icons.language_rounded,
            label: 'Website',
            value: detail?.websiteUrl ?? '',
          ),
          if (effectivePolicy.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.stars_rounded,
                          color: AppColors.gold,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Loyalty Policy',
                        style: AppTypography.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textOnDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    effectivePolicy,
                    style: AppTypography.dmSans(
                      fontSize: 12,
                      color: AppColors.textOnDark.withValues(alpha: 0.85),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          if (detail != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loyalty Summary',
                    style: AppTypography.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lifetime earned: ${detail!.lifetimeEarned} pts',
                    style: AppTypography.dmSans(
                      fontSize: 12,
                      color: AppColors.textMutedDark,
                    ),
                  ),
                  Text(
                    'Lifetime redeemed: ${detail!.lifetimeRedeemed} pts',
                    style: AppTypography.dmSans(
                      fontSize: 12,
                      color: AppColors.textMutedDark,
                    ),
                  ),
                  Text(
                    'Lifetime expired: ${detail!.lifetimeExpired} pts',
                    style: AppTypography.dmSans(
                      fontSize: 12,
                      color: AppColors.textMutedDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.dmSans(
                    fontSize: 11,
                    color: AppColors.textMutedDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.dmSans(
                    fontSize: 13,
                    color: AppColors.textOnDark,
                    height: 1.4,
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

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 56,
            color: AppColors.textMutedDark.withValues(alpha: 0.3),
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
