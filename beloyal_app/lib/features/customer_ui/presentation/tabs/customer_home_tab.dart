import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/data/providers/customer_providers.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';
import 'package:besahub_app/features/customer_ui/presentation/pages/customer_business_detail_page.dart';
import 'package:besahub_app/features/customer_ui/presentation/pages/customer_view_all_businesses_page.dart';
import 'package:besahub_app/features/customer_ui/presentation/pages/customer_view_all_coupons_page.dart';
import 'package:besahub_app/features/customer_ui/presentation/pages/customer_view_all_transactions_page.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_async_state.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_transaction_detail_sheet.dart';

void _push(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

String _categoryEmoji(String categoryName) {
  final name = categoryName.toLowerCase();
  if (name.contains('all')) return '✨';
  if (name.contains('restaurant')) return '🍽️';
  if (name.contains('caf')) return '☕';
  if (name.contains('fitness')) return '💪';
  if (name.contains('beauty')) return '💄';
  if (name.contains('retail')) return '👗';
  if (name.contains('grocery')) return '🌿';
  if (name.contains('entertainment')) return '🎬';
  if (name.contains('health')) return '🏥';
  if (name.contains('travel')) return '✈️';
  if (name.contains('service')) return '🧰';
  return '🏷️';
}

class CustomerHomeTab extends ConsumerStatefulWidget {
  const CustomerHomeTab({super.key});

  @override
  ConsumerState<CustomerHomeTab> createState() => _CustomerHomeTabState();
}

class _CustomerHomeTabState extends ConsumerState<CustomerHomeTab> {
  int _selectedCategoryId = -1;

  @override
  Widget build(BuildContext context) {
    final customerData = ref.watch(customerDataProvider);

    return customerData.when(
      loading: () => const CustomerLoadingState(),
      error: (_, __) => CustomerErrorState(
        onRetry: () => ref.read(customerDataProvider.notifier).refresh(),
      ),
      data: (data) {
        final customer = data.summary;

        return RefreshIndicator(
          onRefresh: () => ref.read(customerDataProvider.notifier).refresh(),
          color: AppColors.primary,
          backgroundColor: const Color(0xFF1A0535),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _StatsHeroCard(customer: customer),
                const SizedBox(height: 20),
                _QuickShortcuts(),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Categories',
                  subtitle: 'Browse by type',
                  onViewAll: () =>
                      _push(context, const CustomerViewAllBusinessesPage()),
                ),
                const SizedBox(height: 12),
                _CategoryCarousel(
                  selectedId: _selectedCategoryId,
                  categories: data.categories,
                  onSelect: (id) => setState(() => _selectedCategoryId = id),
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Your Businesses',
                  subtitle: 'Where you have points',
                  onViewAll: () =>
                      _push(context, const CustomerViewAllBusinessesPage()),
                ),
                const SizedBox(height: 12),
                _BusinessCarousel(
                  businesses: _selectedCategoryId == -1
                      ? data.businessesWithPoints
                      : data.businessesWithPoints
                            .where((b) => b.categoryId == _selectedCategoryId)
                            .toList(),
                  categories: data.categories,
                  onViewAll: () =>
                      _push(context, const CustomerViewAllBusinessesPage()),
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Discover Businesses',
                  subtitle: 'New places to explore',
                  onViewAll: () =>
                      _push(context, const CustomerViewAllBusinessesPage()),
                ),
                const SizedBox(height: 12),
                _DiscoverCarousel(
                  businesses:
                      (_selectedCategoryId == -1
                              ? data.businesses.where((b) => b.points == 0)
                              : data.businesses.where(
                                  (b) =>
                                      b.points == 0 &&
                                      b.categoryId == _selectedCategoryId,
                                ))
                          .toList(),
                  onViewAll: () =>
                      _push(context, const CustomerViewAllBusinessesPage()),
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: '🎫 Coupons & Offers',
                  subtitle: 'Business-wide deals across all brands',
                  onViewAll: () => _push(
                    context,
                    const CustomerViewAllCouponsPage(
                      initialTab: CustomerCouponsTab.allCoupons,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _OffersCarousel(
                  coupons: data.allCoupons
                      .where(
                        (coupon) =>
                            coupon.status == 'active' ||
                            coupon.status == 'expiring',
                      )
                      .toList(),
                  onViewAll: () => _push(
                    context,
                    const CustomerViewAllCouponsPage(
                      initialTab: CustomerCouponsTab.allCoupons,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _AlmostThereSection(
                  businesses: data.businesses,
                  onViewAll: () =>
                      _push(context, const CustomerViewAllBusinessesPage()),
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Top Businesses',
                  subtitle: 'Highest rated near you',
                  onViewAll: () =>
                      _push(context, const CustomerViewAllBusinessesPage()),
                ),
                const SizedBox(height: 12),
                _HotBusinessesCarousel(
                  businesses: data.hotBusinesses,
                  onViewAll: () =>
                      _push(context, const CustomerViewAllBusinessesPage()),
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Recent Activity',
                  subtitle: 'Your latest transactions',
                  onViewAll: () =>
                      _push(context, const CustomerViewAllTransactionsPage()),
                ),
                const SizedBox(height: 12),
                _RecentActivityList(
                  transactions: data.transactions,
                  onViewAll: () =>
                      _push(context, const CustomerViewAllTransactionsPage()),
                ),
                const SizedBox(height: 24),
                _ExpiringSection(coupons: data.coupons),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Stats Hero Card ──────────────────────────────────────────────────────────

class _StatsHeroCard extends StatelessWidget {
  const _StatsHeroCard({required this.customer});
  final dynamic customer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1A0535),
              Color(0xFF2D1060),
              AppColors.primary,
              AppColors.secondary,
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL BESACOINS',
                                style: AppTypography.overline(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${customer.currentPoints}',
                                style: AppTypography.dmMono(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'pts available',
                                style: AppTypography.dmSans(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Member since badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                color: AppColors.gold,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Since ${customer.memberSince}',
                                style: AppTypography.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _StatPill(
                          label: 'Lifetime',
                          value: '${customer.lifetimePoints}',
                          icon: Icons.stars_rounded,
                          color: AppColors.gold,
                          onTap: () => _push(
                            context,
                            const CustomerViewAllTransactionsPage(
                              initialFilter: 'EARN',
                              title: 'Earned Points',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatPill(
                          label: 'Spent',
                          value: '${customer.spentPoints}',
                          icon: Icons.redeem_rounded,
                          color: AppColors.accentLight,
                          onTap: () => _push(
                            context,
                            const CustomerViewAllTransactionsPage(
                              initialFilter: 'REDEEM',
                              title: 'Spent Points',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatPill(
                          label: 'Businesses',
                          value: '${customer.businessesVisited}',
                          icon: Icons.storefront_rounded,
                          color: AppColors.secondaryLight,
                          onTap: () => _push(
                            context,
                            const CustomerViewAllBusinessesPage(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _MiniStatTile(
                          label: 'Coupons',
                          value: '${customer.activeCoupons}',
                          onTap: () => _push(
                            context,
                            const CustomerViewAllCouponsPage(
                              initialTab: CustomerCouponsTab.myCoupons,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _MiniStatTile(
                          label: 'Rewards',
                          value: '${customer.activeRewards}',
                          onTap: () => _push(
                            context,
                            const CustomerViewAllBusinessesPage(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _MiniStatTile(
                          label: 'Member Code',
                          value: customer.memberCode as String,
                          onTap: null,
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

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTypography.dmMono(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: AppTypography.dmSans(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatTile extends StatelessWidget {
  const _MiniStatTile({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTypography.dmMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.dmSans(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Shortcuts ──────────────────────────────────────────────────────────

class _QuickShortcuts extends StatelessWidget {
  const _QuickShortcuts();

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      _Shortcut(
        icon: Icons.receipt_long_rounded,
        label: 'Transactions',
        color: AppColors.accent,
        onTap: () => _push(context, const CustomerViewAllTransactionsPage()),
      ),
      _Shortcut(
        icon: Icons.storefront_rounded,
        label: 'Businesses',
        color: AppColors.gold,
        onTap: () => _push(context, const CustomerViewAllBusinessesPage()),
      ),
      _Shortcut(
        icon: Icons.confirmation_number_rounded,
        label: 'Coupons',
        color: AppColors.error,
        onTap: () => _push(
          context,
          const CustomerViewAllCouponsPage(
            initialTab: CustomerCouponsTab.myCoupons,
          ),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: shortcuts.map((s) => _ShortcutButton(shortcut: s)).toList(),
      ),
    );
  }
}

class _Shortcut {
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _ShortcutButton extends StatelessWidget {
  const _ShortcutButton({required this.shortcut});
  final _Shortcut shortcut;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: shortcut.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: shortcut.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: shortcut.color.withValues(alpha: 0.25)),
            ),
            child: Icon(shortcut.icon, color: shortcut.color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            shortcut.label,
            style: AppTypography.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMutedDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.onViewAll,
  });
  final String title;
  final String subtitle;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.dmSans(
                    fontSize: 12,
                    color: AppColors.textMutedDark,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  style: AppTypography.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Carousel (premium redesign) ────────────────────────────────────

class _CategoryCarousel extends StatelessWidget {
  const _CategoryCarousel({
    required this.selectedId,
    required this.categories,
    required this.onSelect,
  });
  final int selectedId;
  final List<CustomerCategory> categories;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final categories = [
      CustomerCategory(
        id: -1,
        name: 'All',
        icon: Icons.apps_rounded,
        color: AppColors.primary,
        businessCount: 0,
      ),
      ...this.categories,
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          cat.color.withValues(alpha: 0.22),
                          cat.color.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : AppColors.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? cat.color.withValues(alpha: 0.55)
                      : AppColors.glassBorder,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: cat.color.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Text(
                    _categoryEmoji(cat.name),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat.name,
                    style: AppTypography.dmSans(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected ? cat.color : AppColors.textMutedDark,
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
}

// ─── Business Carousel ────────────────────────────────────────────────────────

class _BusinessCarousel extends StatelessWidget {
  const _BusinessCarousel({
    required this.businesses,
    required this.categories,
    required this.onViewAll,
  });
  final List<CustomerBusiness> businesses;
  final List<CustomerCategory> categories;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    const limit = 10;
    final visibleBusinesses = businesses.take(limit).toList();
    final hasMore = businesses.length > limit;

    if (businesses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Text(
            'No businesses in this category yet.',
            style: AppTypography.dmSans(
              fontSize: 13,
              color: AppColors.textMutedDark,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 192,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemCount: visibleBusinesses.length,
            itemBuilder: (_, i) => _BusinessCard(
              business: visibleBusinesses[i],
              categories: categories,
            ),
          ),
        ),
        if (hasMore)
          _ViewAllHint(
            message:
                'Showing ${visibleBusinesses.length} of ${businesses.length} businesses. Tap View All.',
            onTap: onViewAll,
          ),
      ],
    );
  }
}

class _ViewAllHint extends StatelessWidget {
  const _ViewAllHint({required this.message, required this.onTap});
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({required this.business, required this.categories});
  final CustomerBusiness business;
  final List<CustomerCategory> categories;

  @override
  Widget build(BuildContext context) {
    final hasReward = business.nextRewardPoints > 0;
    final progress = hasReward
        ? (business.points / business.nextRewardPoints).clamp(0.0, 1.0)
        : 0.0;
    final remaining = hasReward
        ? (business.nextRewardPoints - business.points).clamp(
            0,
            business.nextRewardPoints,
          )
        : 0;
    final category = categories.firstWhere(
      (c) => c.id == business.categoryId || c.name == business.category,
      orElse: () => categories.isNotEmpty
          ? categories.first
          : CustomerCategory(
              id: 0,
              name: business.category,
              icon: Icons.store_rounded,
              color: AppColors.primary,
              businessCount: 0,
            ),
    );

    return GestureDetector(
      onTap: () =>
          _push(context, CustomerBusinessDetailPage(business: business)),
      child: Container(
        width: 185,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: business.gradientColors.last.withValues(alpha: 0.15),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover gradient header with centered logo
            Container(
              height: 82,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: business.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circle
                  Positioned(
                    right: -10,
                    top: -10,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  // Top-left category icon
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _categoryEmoji(business.category),
                          textAlign: TextAlign.center,
                          strutStyle: const StrutStyle(
                            forceStrutHeight: true,
                            height: 1,
                          ),
                          style: const TextStyle(fontSize: 13, height: 1),
                        ),
                      ),
                    ),
                  ),
                  // Centered business logo chip — shown only when business has a logo
                  if (business.hasLogo)
                    Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: category.color.withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: business.gradientColors.last.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            business.logoEmoji,
                            textAlign: TextAlign.center,
                            strutStyle: const StrutStyle(
                              forceStrutHeight: true,
                              height: 1,
                            ),
                            style: const TextStyle(fontSize: 24, height: 1),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Card body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: AppTypography.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            business.category,
                            style: AppTypography.dmSans(
                              fontSize: 10,
                              color: AppColors.textMutedDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.gold,
                          size: 11,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          business.rating.toStringAsFixed(2),
                          style: AppTypography.dmSans(
                            fontSize: 10,
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${business.points} pts',
                      style: AppTypography.dmMono(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.glassBorder,
                        color: business.gradientColors.last,
                        minHeight: 3.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      !hasReward
                          ? 'No rewards available'
                          : remaining <= 0
                          ? 'Ready to redeem!'
                          : '$remaining pts to reward',
                      style: AppTypography.dmSans(
                        fontSize: 9,
                        color: AppColors.textMutedDark,
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
}

// ─── Discover Carousel ───────────────────────────────────────────────────────

class _DiscoverCarousel extends StatelessWidget {
  const _DiscoverCarousel({required this.businesses, required this.onViewAll});
  final List<CustomerBusiness> businesses;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    if (businesses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 90,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Text(
            'No new businesses in this category.',
            style: AppTypography.dmSans(
              fontSize: 13,
              color: AppColors.textMutedDark,
            ),
          ),
        ),
      );
    }

    const limit = 10;
    final visibleBusinesses = businesses.take(limit).toList();
    final hasMore = businesses.length > limit;

    return Column(
      children: [
        SizedBox(
          height: 154,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemCount: visibleBusinesses.length,
            itemBuilder: (_, i) =>
                _DiscoverCard(business: visibleBusinesses[i]),
          ),
        ),
        if (hasMore)
          _ViewAllHint(
            message:
                'Showing ${visibleBusinesses.length} of ${businesses.length} businesses. Tap View All.',
            onTap: onViewAll,
          ),
      ],
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({required this.business});
  final CustomerBusiness business;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          _push(context, CustomerBusinessDetailPage(business: business)),
      child: Container(
        width: 168,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Muted gradient header
            Container(
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    business.gradientColors.first.withValues(alpha: 0.45),
                    business.gradientColors.last.withValues(alpha: 0.45),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Center(
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      business.logoEmoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    style: AppTypography.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 10,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        business.rating.toStringAsFixed(2),
                        style: AppTypography.dmSans(
                          fontSize: 10,
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '· ${business.distance}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.dmSans(
                            fontSize: 10,
                            color: AppColors.textMutedDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 10,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Start earning',
                          style: AppTypography.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
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

// ─── Offers Carousel ─────────────────────────────────────────────────────────

class _OffersCarousel extends StatelessWidget {
  const _OffersCarousel({required this.coupons, required this.onViewAll});
  final List<CustomerCoupon> coupons;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    const limit = 10;
    final visibleCoupons = coupons.take(limit).toList();
    final hasMore = coupons.length > limit;

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemCount: visibleCoupons.length,
            itemBuilder: (_, i) => _OfferCard(coupon: visibleCoupons[i]),
          ),
        ),
        if (hasMore)
          _ViewAllHint(
            message:
                'Showing ${visibleCoupons.length} of ${coupons.length} coupons. Tap View All.',
            onTap: onViewAll,
          ),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.coupon});
  final CustomerCoupon coupon;

  @override
  Widget build(BuildContext context) {
    final urgencyLabel = coupon.expiresIn ?? 'Expires soon';
    final isUrgent = coupon.status == 'expiring';
    final displayValue = coupon.multiplierLabel ?? coupon.discountDisplay;

    return GestureDetector(
      onTap: () => _push(
        context,
        const CustomerViewAllCouponsPage(
          initialTab: CustomerCouponsTab.allCoupons,
        ),
      ),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: coupon.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: coupon.gradientColors.last.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
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
                      if (coupon.isHot)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 10,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'HOT',
                                style: AppTypography.dmSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (isUrgent ? AppColors.error : Colors.white)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          urgencyLabel,
                          style: AppTypography.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isUrgent
                                ? AppColors.error
                                : Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    displayValue,
                    style: AppTypography.dmMono(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    coupon.title,
                    style: AppTypography.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    coupon.businessName,
                    style: AppTypography.dmSans(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.7),
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

// ─── Almost There Section ─────────────────────────────────────────────────────

class _AlmostThereSection extends StatelessWidget {
  const _AlmostThereSection({
    required this.businesses,
    required this.onViewAll,
  });
  final List<CustomerBusiness> businesses;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    const limit = 5;
    final almostThere = businesses
        .where(
          (b) =>
              b.nextRewardPoints - b.points <= 200 &&
              b.nextRewardPoints - b.points > 0,
        )
        .toList();
    if (almostThere.isEmpty) return const SizedBox.shrink();
    final visibleAlmostThere = almostThere.take(limit).toList();
    final hasMore = almostThere.length > limit;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: '⚡ Almost There',
            subtitle: 'Close to your next reward',
            onViewAll: () =>
                _push(context, const CustomerViewAllBusinessesPage()),
          ),
          const SizedBox(height: 12),
          ...visibleAlmostThere.map((b) => _AlmostThereCard(business: b)),
          if (hasMore)
            _ViewAllHint(
              message:
                  'Showing ${visibleAlmostThere.length} of ${almostThere.length} almost-there businesses. Tap View All.',
              onTap: onViewAll,
            ),
        ],
      ),
    );
  }
}

class _AlmostThereCard extends StatelessWidget {
  const _AlmostThereCard({required this.business});
  final CustomerBusiness business;

  @override
  Widget build(BuildContext context) {
    final hasReward = business.nextRewardPoints > 0;
    final remaining = hasReward
        ? (business.nextRewardPoints - business.points).clamp(
            0,
            business.nextRewardPoints,
          )
        : 0;
    final progress = hasReward
        ? (business.points / business.nextRewardPoints).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () =>
          _push(context, CustomerBusinessDetailPage(business: business)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: business.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  business.logoEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    style: AppTypography.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.glassBorder,
                      color: business.gradientColors.last,
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    !hasReward
                        ? 'No rewards available'
                        : remaining <= 0
                        ? 'Ready to redeem!'
                        : '$remaining pts to reward',
                    style: AppTypography.dmSans(
                      fontSize: 10,
                      color: AppColors.textMutedDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                'Visit',
                style: AppTypography.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hot Businesses Carousel ──────────────────────────────────────────────────

class _HotBusinessesCarousel extends StatelessWidget {
  const _HotBusinessesCarousel({
    required this.businesses,
    required this.onViewAll,
  });
  final List<CustomerBusiness> businesses;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    const limit = 10;
    final visibleBusinesses = businesses.take(limit).toList();
    final hasMore = businesses.length > limit;

    return Column(
      children: [
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: visibleBusinesses.length,
            itemBuilder: (_, i) =>
                _HotBusinessChip(business: visibleBusinesses[i]),
          ),
        ),
        if (hasMore)
          _ViewAllHint(
            message:
                'Showing ${visibleBusinesses.length} of ${businesses.length} businesses. Tap View All.',
            onTap: onViewAll,
          ),
      ],
    );
  }
}

class _HotBusinessChip extends StatelessWidget {
  const _HotBusinessChip({required this.business});
  final CustomerBusiness business;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          _push(context, CustomerBusinessDetailPage(business: business)),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
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
                    gradient: LinearGradient(
                      colors: business.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      business.logoEmoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: business.isOpen
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              business.name,
              style: AppTypography.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.gold, size: 11),
                const SizedBox(width: 3),
                Text(
                  business.rating.toStringAsFixed(2),
                  style: AppTypography.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  business.distance,
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
  }
}

// ─── Recent Activity List ─────────────────────────────────────────────────────

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({
    required this.transactions,
    required this.onViewAll,
  });
  final List<CustomerTransaction> transactions;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    const limit = 10;
    final visibleTransactions = transactions.take(limit).toList();
    final hasMore = transactions.length > limit;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ...visibleTransactions.map((tx) => _RecentTxRow(tx: tx)),
          if (hasMore)
            _ViewAllHint(
              message:
                  'Showing ${visibleTransactions.length} of ${transactions.length} transactions. Tap View All.',
              onTap: onViewAll,
            ),
        ],
      ),
    );
  }
}

class _RecentTxRow extends StatelessWidget {
  const _RecentTxRow({required this.tx});
  final CustomerTransaction tx;

  @override
  Widget build(BuildContext context) {
    final isPositive = tx.points > 0;
    final typeColor = isPositive ? AppColors.success : AppColors.error;
    final typeIcon = isPositive
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return GestureDetector(
      onTap: () => CustomerTransactionDetailSheet.show(context, tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(tx.logoEmoji, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.businessName,
                    style: AppTypography.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnDark,
                    ),
                  ),
                  Text(
                    tx.description,
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(typeIcon, color: typeColor, size: 12),
                const SizedBox(width: 3),
                Text(
                  '${isPositive ? '+' : ''}${tx.points}',
                  style: AppTypography.dmMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
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

// ─── Expiring Section ─────────────────────────────────────────────────────────

class _ExpiringSection extends StatelessWidget {
  const _ExpiringSection({required this.coupons});
  final List<CustomerCoupon> coupons;

  @override
  Widget build(BuildContext context) {
    final expiring = coupons.where((c) => c.status == 'expiring').toList();
    if (expiring.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: '⏰ Expiring Soon',
            subtitle: "Don't miss these deals",
            onViewAll: () => _push(
              context,
              const CustomerViewAllCouponsPage(initialFilter: 'expiring'),
            ),
          ),
          const SizedBox(height: 12),
          ...expiring.map((c) => _ExpiringCouponRow(coupon: c)),
        ],
      ),
    );
  }
}

class _ExpiringCouponRow extends StatelessWidget {
  const _ExpiringCouponRow({required this.coupon});
  final CustomerCoupon coupon;

  @override
  Widget build(BuildContext context) {
    final expiresAt = DateFormat('MMM d').format(coupon.expiresAt);
    final expiresIn = coupon.expiresIn ?? 'Expires soon';

    return GestureDetector(
      onTap: () => _push(
        context,
        const CustomerViewAllCouponsPage(initialFilter: 'expiring'),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.error.withValues(alpha: 0.08),
              AppColors.error.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
            width: 1.5,
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
                boxShadow: [
                  BoxShadow(
                    color: coupon.gradientColors.last.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
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
                    coupon.title,
                    style: AppTypography.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    coupon.businessName,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  coupon.discountDisplay,
                  style: AppTypography.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                Text(
                  '$expiresAt • $expiresIn',
                  style: AppTypography.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
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
