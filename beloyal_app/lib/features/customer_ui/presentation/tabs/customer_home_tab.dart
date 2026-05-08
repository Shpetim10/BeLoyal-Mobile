import 'package:flutter/material.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/mock/customer_mock_data.dart';
import 'package:besahub_app/features/customer_ui/presentation/pages/customer_business_detail_page.dart';
import 'package:besahub_app/features/customer_ui/presentation/pages/customer_view_all_businesses_page.dart';
import 'package:besahub_app/features/customer_ui/presentation/pages/customer_view_all_offers_page.dart';
import 'package:besahub_app/features/customer_ui/presentation/pages/customer_view_all_coupons_page.dart';
import 'package:besahub_app/features/customer_ui/presentation/pages/customer_view_all_transactions_page.dart';

void _push(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

class CustomerHomeTab extends StatefulWidget {
  const CustomerHomeTab({super.key});

  @override
  State<CustomerHomeTab> createState() => _CustomerHomeTabState();
}

class _CustomerHomeTabState extends State<CustomerHomeTab> {
  int _selectedCategoryId = 0;

  @override
  Widget build(BuildContext context) {
    final customer = CustomerMockData.customer;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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
            onViewAll: () => _push(context, const CustomerViewAllBusinessesPage(
              title: 'All Categories',
              subtitle: 'Discover businesses',
              showAllBusinesses: true,
            )),
          ),
          const SizedBox(height: 12),
          _CategoryCarousel(
            selectedId: _selectedCategoryId,
            onSelect: (id) => setState(() => _selectedCategoryId = id),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Your Businesses',
            subtitle: 'Where you have points',
            onViewAll: () => _push(context, const CustomerViewAllBusinessesPage()),
          ),
          const SizedBox(height: 12),
          _BusinessCarousel(
            businesses: _selectedCategoryId == 0
                ? CustomerMockData.businessesWithPoints
                : CustomerMockData.businessesWithPoints
                    .where((b) => b.categoryId == _selectedCategoryId)
                    .toList(),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: '🔥 Hot Offers',
            subtitle: 'Limited-time deals',
            onViewAll: () => _push(context, const CustomerViewAllOffersPage()),
          ),
          const SizedBox(height: 12),
          _OffersCarousel(),
          const SizedBox(height: 24),
          _AlmostThereSection(),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Top Businesses',
            subtitle: 'Highest rated near you',
            onViewAll: () => _push(context, const CustomerViewAllBusinessesPage(
              title: 'Top Businesses',
              subtitle: 'Highest rated',
              showAllBusinesses: true,
            )),
          ),
          const SizedBox(height: 12),
          _HotBusinessesCarousel(),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Recent Activity',
            subtitle: 'Your latest transactions',
            onViewAll: () => _push(context, const CustomerViewAllTransactionsPage()),
          ),
          const SizedBox(height: 12),
          _RecentActivityList(),
          const SizedBox(height: 24),
          _ExpiringSection(),
          const SizedBox(height: 16),
        ],
      ),
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
            colors: [Color(0xFF1A0535), Color(0xFF2D1060), AppColors.primary, AppColors.secondary],
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
                                style: AppTypography.overline(color: Colors.white.withValues(alpha: 0.7)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${customer.currentPoints}',
                                style: AppTypography.dmMono(fontSize: 42, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                              Text(
                                'pts available',
                                style: AppTypography.dmSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        ),
                        // Member since badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded, color: AppColors.gold, size: 13),
                              const SizedBox(width: 5),
                              Text(
                                'Since ${customer.memberSince}',
                                style: AppTypography.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9)),
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
                          onTap: () => _push(context, const CustomerViewAllTransactionsPage(initialFilter: 'EARN', title: 'Earned Points')),
                        ),
                        const SizedBox(width: 8),
                        _StatPill(
                          label: 'Spent',
                          value: '${customer.spentPoints}',
                          icon: Icons.redeem_rounded,
                          color: AppColors.accentLight,
                          onTap: () => _push(context, const CustomerViewAllTransactionsPage(initialFilter: 'REDEEM', title: 'Spent Points')),
                        ),
                        const SizedBox(width: 8),
                        _StatPill(
                          label: 'Businesses',
                          value: '${customer.businessesVisited}',
                          icon: Icons.storefront_rounded,
                          color: AppColors.secondaryLight,
                          onTap: () => _push(context, const CustomerViewAllBusinessesPage()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _MiniStatTile(
                          label: 'Coupons',
                          value: '${customer.activeCoupons}',
                          onTap: () => _push(context, const CustomerViewAllCouponsPage()),
                        ),
                        const SizedBox(width: 16),
                        _MiniStatTile(
                          label: 'Rewards',
                          value: '${customer.activeRewards}',
                          onTap: () => _push(context, const CustomerViewAllBusinessesPage(
                            title: 'My Rewards',
                            subtitle: 'Businesses with rewards',
                          )),
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
  const _StatPill({required this.label, required this.value, required this.icon, required this.color, this.onTap});
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
              Text(value, style: AppTypography.dmMono(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(label, style: AppTypography.dmSans(fontSize: 9, color: Colors.white.withValues(alpha: 0.6))),
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
          Text(value, style: AppTypography.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.dmSans(fontSize: 10, color: Colors.white.withValues(alpha: 0.6))),
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
      _Shortcut(icon: Icons.qr_code_scanner_rounded, label: 'Scan Card', color: AppColors.primary, onTap: () {}),
      _Shortcut(icon: Icons.card_giftcard_rounded, label: 'Rewards', color: AppColors.secondary,
          onTap: () => _push(context, const CustomerViewAllBusinessesPage(title: 'My Rewards', subtitle: 'Available rewards'))),
      _Shortcut(icon: Icons.receipt_long_rounded, label: 'Transactions', color: AppColors.accent,
          onTap: () => _push(context, const CustomerViewAllTransactionsPage())),
      _Shortcut(icon: Icons.storefront_rounded, label: 'Businesses', color: AppColors.gold,
          onTap: () => _push(context, const CustomerViewAllBusinessesPage(showAllBusinesses: true))),
      _Shortcut(icon: Icons.confirmation_number_rounded, label: 'Coupons', color: AppColors.error,
          onTap: () => _push(context, const CustomerViewAllCouponsPage())),
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
  const _Shortcut({required this.icon, required this.label, required this.color, required this.onTap});
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
            style: AppTypography.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMutedDark),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle, required this.onViewAll});
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
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.dmSans(fontSize: 12, color: AppColors.textMutedDark)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View All', style: AppTypography.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primary),
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
  const _CategoryCarousel({required this.selectedId, required this.onSelect});
  final int selectedId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final categories = [
      MockCategory(id: 0, name: 'All', icon: Icons.apps_rounded, color: AppColors.primary, businessCount: 0),
      ...CustomerMockData.categories,
    ];

    return SizedBox(
      height: 90,
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
              width: 76,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          cat.color.withValues(alpha: 0.25),
                          cat.color.withValues(alpha: 0.10),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                color: isSelected ? null : AppColors.cardDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? cat.color.withValues(alpha: 0.55) : AppColors.glassBorder,
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? cat.color.withValues(alpha: 0.2) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          cat.icon,
                          color: isSelected ? cat.color : AppColors.textMutedDark,
                          size: 22,
                        ),
                      ),
                      if (cat.hasBonus)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.secondary,
                            border: Border.all(color: AppColors.cardDark, width: 1.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    cat.name,
                    style: AppTypography.dmSans(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? cat.color : AppColors.textMutedDark,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
  const _BusinessCarousel({required this.businesses});
  final List<MockBusiness> businesses;

  @override
  Widget build(BuildContext context) {
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
          child: Text('No businesses in this category yet.', style: AppTypography.dmSans(fontSize: 13, color: AppColors.textMutedDark)),
        ),
      );
    }

    return SizedBox(
      height: 192,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemCount: businesses.length,
        itemBuilder: (_, i) => _BusinessCard(business: businesses[i]),
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({required this.business});
  final MockBusiness business;

  @override
  Widget build(BuildContext context) {
    final progress = (business.points / business.nextRewardPoints).clamp(0.0, 1.0);
    final remaining = business.nextRewardPoints - business.points;

    return GestureDetector(
      onTap: () => _push(context, CustomerBusinessDetailPage(business: business)),
      child: Container(
        width: 165,
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
            // Cover gradient header
            Container(
              height: 74,
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
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Center(
                            child: Text(business.logoEmoji, style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                        const Spacer(),
                        if (business.hasOffer)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              business.offerLabel!,
                              style: AppTypography.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.gold),
                            ),
                          ),
                        // Open dot
                        const SizedBox(width: 6),
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: business.isOpen ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Card body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: AppTypography.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textOnDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(business.category, style: AppTypography.dmSans(fontSize: 10, color: AppColors.textMutedDark)),
                        const Spacer(),
                        const Icon(Icons.star_rounded, color: AppColors.gold, size: 11),
                        const SizedBox(width: 2),
                        Text('${business.rating}', style: AppTypography.dmSans(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${business.points} pts',
                      style: AppTypography.dmMono(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textOnDark),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.glassBorder,
                        color: business.gradientColors.last,
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$remaining pts to reward',
                      style: AppTypography.dmSans(fontSize: 9, color: AppColors.textMutedDark),
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

// ─── Offers Carousel ─────────────────────────────────────────────────────────

class _OffersCarousel extends StatelessWidget {
  const _OffersCarousel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemCount: CustomerMockData.hotOffers.length,
        itemBuilder: (_, i) => _OfferCard(offer: CustomerMockData.hotOffers[i]),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});
  final MockOffer offer;

  @override
  Widget build(BuildContext context) {
    final daysLeft = offer.validUntil.difference(DateTime.now()).inDays;
    final hoursLeft = offer.validUntil.difference(DateTime.now()).inHours;
    final urgencyLabel = daysLeft <= 0 ? '${hoursLeft}h left' : daysLeft == 1 ? 'Ends tomorrow' : '$daysLeft days left';
    final isUrgent = daysLeft <= 1;

    return GestureDetector(
      onTap: () => _push(context, const CustomerViewAllOffersPage()),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: offer.gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: offer.gradientColors.last.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10, bottom: -10,
              child: Container(
                width: 70, height: 70,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (offer.isHot)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department_rounded, size: 10, color: Colors.white),
                              const SizedBox(width: 3),
                              Text('HOT', style: AppTypography.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isUrgent ? AppColors.error : Colors.white).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          urgencyLabel,
                          style: AppTypography.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: isUrgent ? AppColors.error : Colors.white.withValues(alpha: 0.8)),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(offer.multiplier, style: AppTypography.dmMono(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text(offer.title, style: AppTypography.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(offer.businessName, style: AppTypography.dmSans(fontSize: 10, color: Colors.white.withValues(alpha: 0.7))),
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
  const _AlmostThereSection();

  @override
  Widget build(BuildContext context) {
    final almostThere = CustomerMockData.businesses
        .where((b) => b.nextRewardPoints - b.points <= 200 && b.nextRewardPoints - b.points > 0)
        .toList();
    if (almostThere.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: '⚡ Almost There',
            subtitle: 'Close to your next reward',
            onViewAll: () => _push(context, const CustomerViewAllBusinessesPage()),
          ),
          const SizedBox(height: 12),
          ...almostThere.map((b) => _AlmostThereCard(business: b)),
        ],
      ),
    );
  }
}

class _AlmostThereCard extends StatelessWidget {
  const _AlmostThereCard({required this.business});
  final MockBusiness business;

  @override
  Widget build(BuildContext context) {
    final remaining = business.nextRewardPoints - business.points;
    final progress = (business.points / business.nextRewardPoints).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => _push(context, CustomerBusinessDetailPage(business: business)),
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
                gradient: LinearGradient(colors: business.gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(business.logoEmoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(business.name, style: AppTypography.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textOnDark)),
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
                  Text('$remaining pts until reward', style: AppTypography.dmSans(fontSize: 10, color: AppColors.textMutedDark)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Text('Visit', style: AppTypography.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hot Businesses Carousel ──────────────────────────────────────────────────

class _HotBusinessesCarousel extends StatelessWidget {
  const _HotBusinessesCarousel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: CustomerMockData.hotBusinesses.length,
        itemBuilder: (_, i) => _HotBusinessChip(business: CustomerMockData.hotBusinesses[i]),
      ),
    );
  }
}

class _HotBusinessChip extends StatelessWidget {
  const _HotBusinessChip({required this.business});
  final MockBusiness business;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _push(context, CustomerBusinessDetailPage(business: business)),
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
                    gradient: LinearGradient(colors: business.gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text(business.logoEmoji, style: const TextStyle(fontSize: 14))),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: business.isOpen ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(business.name, style: AppTypography.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textOnDark), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.gold, size: 11),
                const SizedBox(width: 3),
                Text('${business.rating}', style: AppTypography.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.gold)),
                const SizedBox(width: 4),
                Text(business.distance, style: AppTypography.dmSans(fontSize: 10, color: AppColors.textMutedDark)),
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
  const _RecentActivityList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: CustomerMockData.recentActivity.map((tx) => _RecentTxRow(tx: tx)).toList(),
      ),
    );
  }
}

class _RecentTxRow extends StatelessWidget {
  const _RecentTxRow({required this.tx});
  final MockTransaction tx;

  @override
  Widget build(BuildContext context) {
    final isPositive = tx.points > 0;
    final typeColor = isPositive ? AppColors.success : AppColors.error;
    final typeIcon = isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
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
            child: Center(child: Text(tx.logoEmoji, style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.businessName, style: AppTypography.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textOnDark)),
                Text(tx.description, style: AppTypography.dmSans(fontSize: 11, color: AppColors.textMutedDark), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                style: AppTypography.dmMono(fontSize: 14, fontWeight: FontWeight.w700, color: typeColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Expiring Section ─────────────────────────────────────────────────────────

class _ExpiringSection extends StatelessWidget {
  const _ExpiringSection();

  @override
  Widget build(BuildContext context) {
    final expiring = CustomerMockData.coupons.where((c) => c.status == 'expiring').toList();
    if (expiring.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: '⏰ Expiring Soon',
            subtitle: "Don't miss these deals",
            onViewAll: () => _push(context, const CustomerViewAllCouponsPage(initialFilter: 'expiring')),
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
  final MockCoupon coupon;

  @override
  Widget build(BuildContext context) {
    final hours = coupon.expiresAt.difference(DateTime.now()).inHours;
    final label = hours < 24 ? '${hours}h left' : '${coupon.expiresAt.difference(DateTime.now()).inDays}d left';

    return GestureDetector(
      onTap: () => _push(context, const CustomerViewAllCouponsPage(initialFilter: 'expiring')),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: coupon.gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(coupon.title, style: AppTypography.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textOnDark)),
                  Text(coupon.businessName, style: AppTypography.dmSans(fontSize: 11, color: AppColors.textMutedDark)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(coupon.discountDisplay, style: AppTypography.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.error)),
                Text(label, style: AppTypography.dmSans(fontSize: 10, color: AppColors.error)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
