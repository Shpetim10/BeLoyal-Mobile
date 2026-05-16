import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/data/providers/customer_providers.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_async_state.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_coupon_card.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_coupon_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CustomerCouponsTab { myCoupons, allCoupons }

class CustomerViewAllCouponsPage extends ConsumerStatefulWidget {
  const CustomerViewAllCouponsPage({
    super.key,
    this.initialFilter = 'all',
    this.initialTab = CustomerCouponsTab.myCoupons,
  });

  final String initialFilter;
  final CustomerCouponsTab initialTab;

  @override
  ConsumerState<CustomerViewAllCouponsPage> createState() =>
      _CustomerViewAllCouponsPageState();
}

class _CustomerViewAllCouponsPageState
    extends ConsumerState<CustomerViewAllCouponsPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late String _filter;
  late CustomerCouponsTab _selectedTab;

  static const _filters = [
    ('all', 'All'),
    ('active', 'Active'),
    ('expiring', 'Expiring'),
    ('used', 'Used'),
    ('expired', 'Expired'),
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _selectedTab = widget.initialTab;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CustomerCoupon> _filtered(List<CustomerCoupon> coupons) {
    return coupons.where((c) {
      if (_searchQuery.isNotEmpty &&
          !c.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !c.businessName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_filter == 'all') return true;
      return c.status == _filter;
    }).toList();
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
          data: (data) {
            final source = _selectedTab == CustomerCouponsTab.myCoupons
                ? data.myCoupons
                : data.allCoupons;
            final title = _selectedTab == CustomerCouponsTab.myCoupons
                ? 'My Coupons'
                : 'All Coupons';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnDark,
                  ),
                ),
                Text(
                  '${source.length} coupons available',
                  style: AppTypography.dmSans(
                    fontSize: 12,
                    color: AppColors.textMutedDark,
                  ),
                ),
              ],
            );
          },
          orElse: () => Text(
            'Coupons & Offers',
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
          final myCoupons = data.myCoupons;
          final allCoupons = data.allCoupons;
          final source = _selectedTab == CustomerCouponsTab.myCoupons
              ? myCoupons
              : allCoupons;
          final expiring = source.where((c) => c.status == 'expiring').length;
          final coupons = _filtered(source);

          return Column(
            children: [
              if (expiring > 0)
                GestureDetector(
                  onTap: () => setState(() => _filter = 'expiring'),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timer_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$expiring coupon${expiring > 1 ? 's are' : ' is'} expiring soon. Tap to filter.',
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
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: _CouponsTabSwitcher(
                  selectedTab: _selectedTab,
                  myCount: myCoupons.length,
                  allCount: allCoupons.length,
                  onChanged: (tab) => setState(() => _selectedTab = tab),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: AppTypography.dmSans(
                    fontSize: 14,
                    color: AppColors.textOnDark,
                  ),
                  decoration: InputDecoration(
                    hintText: _selectedTab == CustomerCouponsTab.myCoupons
                        ? 'Search my coupons...'
                        : 'Search all business coupons...',
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
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: _filters.map((f) {
                    final isSelected = _filter == f.$1;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.glassBorder,
                          ),
                        ),
                        child: Text(
                          f.$2,
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
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.read(customerDataProvider.notifier).refresh(),
                  color: AppColors.primary,
                  backgroundColor: const Color(0xFF1A0535),
                  child: coupons.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 80),
                              child: _EmptyCouponsState(
                                selectedTab: _selectedTab,
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: coupons.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) => CustomerCouponCard(
                            coupon: coupons[i],
                            showBusinessName: true,
                            onTap: () => CustomerCouponDetailSheet.show(
                              context,
                              coupons[i],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CouponsTabSwitcher extends StatelessWidget {
  const _CouponsTabSwitcher({
    required this.selectedTab,
    required this.myCount,
    required this.allCount,
    required this.onChanged,
  });

  final CustomerCouponsTab selectedTab;
  final int myCount;
  final int allCount;
  final ValueChanged<CustomerCouponsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              count: myCount,
              isSelected: selectedTab == CustomerCouponsTab.myCoupons,
              onTap: () => onChanged(CustomerCouponsTab.myCoupons),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _CouponsTabButton(
              label: 'All Coupons',
              count: allCount,
              isSelected: selectedTab == CustomerCouponsTab.allCoupons,
              onTap: () => onChanged(CustomerCouponsTab.allCoupons),
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

class _EmptyCouponsState extends StatelessWidget {
  const _EmptyCouponsState({required this.selectedTab});

  final CustomerCouponsTab selectedTab;

  @override
  Widget build(BuildContext context) {
    final message = selectedTab == CustomerCouponsTab.myCoupons
        ? 'No coupons found in your wallet.'
        : 'No business-wide coupons matched this filter.';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 56,
            color: AppColors.textMutedDark.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTypography.dmSans(
              fontSize: 14,
              color: AppColors.textMutedDark,
            ),
          ),
        ],
      ),
    );
  }
}

