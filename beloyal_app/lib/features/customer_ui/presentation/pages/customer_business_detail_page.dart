import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/data/providers/customer_providers.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_data_source.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_async_state.dart';

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
    _TabItem(icon: Icons.card_giftcard_rounded, label: 'Rewards'),
    _TabItem(icon: Icons.receipt_long_rounded, label: 'Transactions'),
    _TabItem(icon: Icons.location_on_rounded, label: 'Location'),
    _TabItem(icon: Icons.info_outline_rounded, label: 'Info'),
  ];

  CustomerBusiness get _b => widget.business;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final customerData = ref.watch(customerDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0812),
      body: customerData.when(
        loading: () => const CustomerLoadingState(),
        error: (_, __) => CustomerErrorState(
          onRetry: () => ref.read(customerDataProvider.notifier).refresh(),
        ),
        data: (data) => CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(topPad),
            SliverToBoxAdapter(child: _buildBusinessInfo()),
            SliverToBoxAdapter(child: _buildPointsCard()),
            SliverToBoxAdapter(child: _buildTabBar()),
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                child: KeyedSubtree(
                  key: ValueKey(_selectedTab),
                  child: _buildTabContent(data),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
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
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.share_rounded,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () {},
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
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
            // Business logo center
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
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
                    child: Center(
                      child: Text(
                        _b.logoEmoji,
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Open/closed badge
            Positioned(
              top: topPad + 16,
              right: 72,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: (_b.isOpen ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (_b.isOpen ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _b.isOpen ? AppColors.success : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _b.isOpen ? 'Open Now' : 'Closed',
                      style: AppTypography.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _b.isOpen ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
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
              const SizedBox(width: 10),
              const Icon(
                Icons.near_me_rounded,
                size: 13,
                color: AppColors.textMutedDark,
              ),
              const SizedBox(width: 4),
              Text(
                _b.distance,
                style: AppTypography.dmSans(
                  fontSize: 12,
                  color: AppColors.textMutedDark,
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

  Widget _buildPointsCard() {
    final progress = (_b.points / _b.nextRewardPoints).clamp(0.0, 1.0);
    final remaining = _b.nextRewardPoints - _b.points;

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
      child: Row(
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
                  '${_b.points} pts',
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
                  '$remaining pts until next reward',
                  style: AppTypography.dmSans(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedTab = 4), // Rewards tab
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.card_giftcard_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rewards',
                        style: AppTypography.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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

  Widget _buildTabContent(CustomerDataSource data) {
    return switch (_selectedTab) {
      0 => _OverviewTab(business: _b, data: data),
      1 => _MenuTab(business: _b),
      2 => _CouponsTab(coupons: data.couponsForBusiness(_b.id)),
      3 => _RewardsTab(rewards: data.rewardsForBusiness(_b.id)),
      4 => _TransactionsTab(txs: data.transactionsForBusiness(_b.id)),
      5 => _LocationTab(business: _b),
      6 => _InfoTab(business: _b),
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
  const _OverviewTab({required this.business, required this.data});
  final CustomerBusiness business;
  final CustomerDataSource data;

  @override
  Widget build(BuildContext context) {
    final coupons = data
        .couponsForBusiness(business.id)
        .where((c) => c.status == 'active' || c.status == 'expiring')
        .take(3)
        .toList();
    final offers = data.offersForBusiness(business.id);
    final rewards = data.rewardsForBusiness(business.id).take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick actions
          Row(
            children: [
              _QuickActionBtn(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan & Earn',
                color: AppColors.primary,
                onTap: () {},
              ),
              const SizedBox(width: 10),
              _QuickActionBtn(
                icon: Icons.confirmation_number_rounded,
                label: 'My Coupons',
                color: AppColors.secondary,
                onTap: () {},
              ),
              const SizedBox(width: 10),
              _QuickActionBtn(
                icon: Icons.directions_rounded,
                label: 'Directions',
                color: AppColors.accent,
                onTap: () {},
              ),
            ],
          ),
          if (coupons.isNotEmpty) ...[
            const SizedBox(height: 22),
            _SubSectionHeader(title: 'Active Coupons', count: coupons.length),
            const SizedBox(height: 10),
            ...coupons.map((c) => _OverviewCouponRow(coupon: c)),
          ],
          if (offers.isNotEmpty) ...[
            const SizedBox(height: 22),
            _SubSectionHeader(title: 'Current Offers', count: offers.length),
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
            _EmptyState(
              icon: Icons.store_outlined,
              message: 'Nothing active right now.\nCheck back soon for offers!',
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
  const _MenuTab({required this.business});
  final CustomerBusiness business;

  @override
  State<_MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<_MenuTab> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    const items = <CustomerMenuItem>[];
    final cats = items.map((i) => i.menuCategory).toSet().toList();

    final filtered = _selectedCategory == null
        ? items
        : items.where((i) => i.menuCategory == _selectedCategory).toList();

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: _EmptyState(
          icon: Icons.restaurant_menu_outlined,
          message: 'No menu available yet.',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _MenuCategoryChip(
                  label: 'All',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ...cats.map(
                  (c) => _MenuCategoryChip(
                    label: c,
                    isSelected: _selectedCategory == c,
                    onTap: () => setState(
                      () =>
                          _selectedCategory = _selectedCategory == c ? null : c,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...filtered.map((item) => _MenuItemCard(item: item)),
        ],
      ),
    );
  }
}

class _MenuCategoryChip extends StatelessWidget {
  const _MenuCategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.dmSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textMutedDark,
          ),
        ),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item});
  final CustomerMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isPopular
              ? AppColors.gold.withValues(alpha: 0.2)
              : AppColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.elevDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(item.emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppTypography.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnDark,
                        ),
                      ),
                    ),
                    if (item.isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Popular',
                          style: AppTypography.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: AppTypography.dmSans(
                    fontSize: 11,
                    color: AppColors.textMutedDark,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'L ${item.price.toStringAsFixed(0)}',
                      style: AppTypography.dmMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const Spacer(),
                    if (item.pointsLabel.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.pointsLabel,
                          style: AppTypography.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
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
    );
  }
}

// ─── Coupons Tab ──────────────────────────────────────────────────────────────

class _CouponsTab extends StatelessWidget {
  const _CouponsTab({required this.coupons});
  final List<CustomerCoupon> coupons;

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: _EmptyState(
          icon: Icons.confirmation_number_outlined,
          message: 'No coupons for this business yet.',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: coupons.map((c) => _DetailCouponCard(coupon: c)).toList(),
      ),
    );
  }
}

class _DetailCouponCard extends StatelessWidget {
  const _DetailCouponCard({required this.coupon});
  final CustomerCoupon coupon;

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
    final hoursLeft = coupon.expiresAt.difference(DateTime.now()).inHours;
    final daysLeft = coupon.expiresAt.difference(DateTime.now()).inDays;
    final isExpired = coupon.expiresAt.isBefore(DateTime.now());
    final timeLabel = isExpired
        ? 'Expired ${-daysLeft}d ago'
        : hoursLeft < 24
        ? 'Expires in ${hoursLeft}h'
        : 'Expires in ${daysLeft}d';

    return Opacity(
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
                          fontSize: coupon.discountDisplay.length > 6 ? 12 : 15,
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
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: AppColors.textMutedDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeLabel,
                              style: AppTypography.dmSans(
                                fontSize: 11,
                                color: AppColors.textMutedDark,
                              ),
                            ),
                            const Spacer(),
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

// ─── Rewards Tab ──────────────────────────────────────────────────────────────

class _RewardsTab extends StatelessWidget {
  const _RewardsTab({required this.rewards});
  final List<CustomerReward> rewards;

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: _EmptyState(
          icon: Icons.card_giftcard_outlined,
          message: 'No reward threshold available for this business yet.',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: rewards.map((r) => _DetailRewardCard(reward: r)).toList(),
      ),
    );
  }
}

class _DetailRewardCard extends StatelessWidget {
  const _DetailRewardCard({required this.reward});
  final CustomerReward reward;

  @override
  Widget build(BuildContext context) {
    final progress = (reward.currentPoints / reward.pointCost).clamp(0.0, 1.0);
    final canRedeem = reward.currentPoints >= reward.pointCost;
    final remaining = (reward.pointCost - reward.currentPoints).clamp(
      0,
      reward.pointCost,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: reward.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: reward.gradientColors.last.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    reward.title,
                    style: AppTypography.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (canRedeem)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'Redeem!',
                      style: AppTypography.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              reward.description,
              style: AppTypography.dmSans(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                color: canRedeem ? AppColors.gold : Colors.white,
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  canRedeem
                      ? '${reward.pointCost} pts — Ready to redeem!'
                      : '$remaining pts to go · ${reward.pointCost} pts total',
                  style: AppTypography.dmSans(
                    fontSize: 11,
                    color: canRedeem
                        ? AppColors.gold
                        : Colors.white.withValues(alpha: 0.7),
                    fontWeight: canRedeem ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Transactions Tab ─────────────────────────────────────────────────────────

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab({required this.txs});
  final List<CustomerTransaction> txs;

  @override
  Widget build(BuildContext context) {
    if (txs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
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

          return Container(
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
                      Text(
                        dateFmt.format(tx.date),
                        style: AppTypography.dmSans(
                          fontSize: 11,
                          color: AppColors.textMutedDark,
                        ),
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
          );
        }).toList(),
      ),
    );
  }
}

// ─── Location Tab ─────────────────────────────────────────────────────────────

class _LocationTab extends StatelessWidget {
  const _LocationTab({required this.business});
  final CustomerBusiness business;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map placeholder
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  business.gradientColors.first.withValues(alpha: 0.3),
                  business.gradientColors.last.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 48,
                    color: AppColors.textMutedDark.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Map Preview',
                    style: AppTypography.dmSans(
                      fontSize: 14,
                      color: AppColors.textMutedDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    business.address,
                    style: AppTypography.dmSans(
                      fontSize: 11,
                      color: AppColors.textMutedDark.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Info rows
          _LocationRow(
            icon: Icons.location_on_rounded,
            label: 'Address',
            value: business.address,
          ),
          _LocationRow(
            icon: Icons.access_time_rounded,
            label: 'Hours',
            value: business.openingHours,
          ),
          _LocationRow(
            icon: Icons.near_me_rounded,
            label: 'Distance',
            value: '${business.distance} away',
          ),
          const SizedBox(height: 16),
          // Directions button
          GestureDetector(
            onTap: () {},
            child: Container(
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
                  const Icon(
                    Icons.directions_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Get Directions',
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
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
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
                    fontWeight: FontWeight.w500,
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

// ─── Info Tab ─────────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.business});
  final CustomerBusiness business;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            icon: Icons.info_outline_rounded,
            label: 'About',
            value: business.description,
          ),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: business.phone,
          ),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: business.email,
          ),
          _InfoRow(
            icon: Icons.category_outlined,
            label: 'Category',
            value: business.category,
          ),
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
                  'Loyalty Policy',
                  style: AppTypography.dmSans(
                    fontSize: 11,
                    color: AppColors.textMutedDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Earn points on every purchase. Redeem rewards at any time. Points are valid for 180 days from the date of last activity. Some rewards and coupons may have specific terms and conditions.',
                  style: AppTypography.dmSans(
                    fontSize: 12,
                    color: AppColors.textOnDark,
                    height: 1.5,
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
