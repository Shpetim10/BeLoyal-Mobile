import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/data/providers/customer_providers.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_async_state.dart';
import 'customer_business_detail_page.dart';

class CustomerViewAllBusinessesPage extends ConsumerStatefulWidget {
  const CustomerViewAllBusinessesPage({super.key});

  @override
  ConsumerState<CustomerViewAllBusinessesPage> createState() =>
      _CustomerViewAllBusinessesPageState();
}

class _CustomerViewAllBusinessesPageState
    extends ConsumerState<CustomerViewAllBusinessesPage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _selectedCategoryId = -1;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<CustomerBusiness> _applyFilters(List<CustomerBusiness> source) {
    return source.where((b) {
      if (_searchQuery.isNotEmpty &&
          !b.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !b.category.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedCategoryId != -1 && b.categoryId != _selectedCategoryId) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final customerData = ref.watch(customerDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0812),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0812),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: customerData.maybeWhen(
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Businesses',
                style: AppTypography.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textOnDark,
                ),
              ),
              Text(
                '${data.businesses.length} businesses in total',
                style: AppTypography.dmSans(
                  fontSize: 12,
                  color: AppColors.textMutedDark,
                ),
              ),
            ],
          ),
          orElse: () => Text(
            'Businesses',
            style: AppTypography.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnDark,
            ),
          ),
        ),
      ),
      body: customerData.when(
        loading: () => const CustomerLoadingState(),
        error: (_, __) => CustomerErrorState(
          onRetry: () => ref.read(customerDataProvider.notifier).refresh(),
        ),
        data: (data) {
          final yourBusinesses = _applyFilters(data.businessesWithPoints);
          final discoverBusinesses = _applyFilters(
            data.businesses.where((b) => b.points == 0).toList(),
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: AppTypography.dmSans(
                    fontSize: 14,
                    color: AppColors.textOnDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search businesses...',
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
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _CategoryChip(
                      id: -1,
                      label: 'All',
                      isSelected: _selectedCategoryId == -1,
                      onTap: () => setState(() => _selectedCategoryId = -1),
                    ),
                    ...data.categories.map(
                      (c) => _CategoryChip(
                        id: c.id,
                        label: c.name,
                        isSelected: _selectedCategoryId == c.id,
                        color: c.color,
                        onTap: () => setState(
                          () => _selectedCategoryId =
                              _selectedCategoryId == c.id ? -1 : c.id,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (_) => setState(() {}),
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelPadding: EdgeInsets.zero,
                    labelStyle: AppTypography.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: AppTypography.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textMutedDark,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.favorite_rounded, size: 14),
                            const SizedBox(width: 6),
                            Text('Your Businesses (${yourBusinesses.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.explore_rounded, size: 14),
                            const SizedBox(width: 6),
                            Text('Discover (${discoverBusinesses.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _BusinessList(
                      businesses: yourBusinesses,
                      isDiscover: false,
                      emptyMessage:
                          'No businesses with your points\nmatch the current filter.',
                    ),
                    _BusinessList(
                      businesses: discoverBusinesses,
                      isDiscover: true,
                      emptyMessage:
                          'No new businesses match\nthe current filter.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Business List (tab content) ──────────────────────────────────────────────

class _BusinessList extends StatelessWidget {
  const _BusinessList({
    required this.businesses,
    required this.isDiscover,
    required this.emptyMessage,
  });
  final List<CustomerBusiness> businesses;
  final bool isDiscover;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (businesses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 56,
              color: AppColors.textMutedDark.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      physics: const BouncingScrollPhysics(),
      itemCount: businesses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) =>
          _BusinessListCard(business: businesses[i], isDiscover: isDiscover),
    );
  }
}

// ─── Category Chip ────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.id,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });
  final int id;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? c.withValues(alpha: 0.15) : AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? c.withValues(alpha: 0.5)
                : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.dmSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? c : AppColors.textMutedDark,
          ),
        ),
      ),
    );
  }
}

// ─── Business List Card ───────────────────────────────────────────────────────

class _BusinessListCard extends StatelessWidget {
  const _BusinessListCard({required this.business, this.isDiscover = false});
  final CustomerBusiness business;
  final bool isDiscover;

  @override
  Widget build(BuildContext context) {
    final progress = (business.points / business.nextRewardPoints).clamp(
      0.0,
      1.0,
    );
    final remaining = business.nextRewardPoints - business.points;
    final offerLabel = business.offerLabel?.trim();
    final showOfferBadge =
        business.hasOffer && offerLabel != null && offerLabel.isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CustomerBusinessDetailPage(business: business),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            // Cover gradient bar
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDiscover
                      ? [
                          business.gradientColors.first.withValues(alpha: 0.45),
                          business.gradientColors.last.withValues(alpha: 0.45),
                        ]
                      : business.gradientColors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDiscover
                            ? [
                                business.gradientColors.first.withValues(
                                  alpha: 0.55,
                                ),
                                business.gradientColors.last.withValues(
                                  alpha: 0.55,
                                ),
                              ]
                            : business.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: business.gradientColors.last.withValues(
                            alpha: isDiscover ? 0.12 : 0.28,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: business.hasLogo
                        ? Center(
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  business.logoEmoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                business.name,
                                style: AppTypography.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textOnDark,
                                ),
                              ),
                            ),
                            if (showOfferBadge)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  offerLabel,
                                  style: AppTypography.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              business.category,
                              style: AppTypography.dmSans(
                                fontSize: 11,
                                color: AppColors.textMutedDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.textMutedDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.gold,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              business.rating.toStringAsFixed(2),
                              style: AppTypography.dmSans(
                                fontSize: 11,
                                color: AppColors.gold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.textMutedDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              business.distance,
                              style: AppTypography.dmSans(
                                fontSize: 11,
                                color: AppColors.textMutedDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (isDiscover) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.bolt_rounded,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Start earning points',
                                      style: AppTypography.dmSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Up to ${business.nextRewardPoints} pts reward',
                                style: AppTypography.dmSans(
                                  fontSize: 10,
                                  color: AppColors.textMutedDark,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Text(
                                '${business.points} pts',
                                style: AppTypography.dmMono(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textOnDark,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$remaining pts to reward',
                                style: AppTypography.dmSans(
                                  fontSize: 10,
                                  color: AppColors.textMutedDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.glassBorder,
                              color: business.gradientColors.last,
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textMutedDark,
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
