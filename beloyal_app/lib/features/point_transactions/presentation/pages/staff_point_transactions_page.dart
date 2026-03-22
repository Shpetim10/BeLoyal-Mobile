import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/point_transactions_controller.dart' show TxTypeFilter;
import '../controllers/staff_point_transactions_controller.dart';
import '../widgets/staff_transaction_card.dart';
import '../widgets/staff_transaction_filter_bar.dart';
import '../widgets/transaction_empty_state.dart';

class StaffPointTransactionsPage extends ConsumerStatefulWidget {
  const StaffPointTransactionsPage({super.key});

  @override
  ConsumerState<StaffPointTransactionsPage> createState() => _StaffPointTransactionsPageState();
}

class _StaffPointTransactionsPageState extends ConsumerState<StaffPointTransactionsPage> {
  @override
  Widget build(BuildContext context) {
    final transactionsState = ref.watch(staffPointTransactionsControllerProvider);
    final groupedTransactions = ref.watch(staffFilteredGroupedTransactionsProvider);
    
    // Check if we have no data at all (before filters) to show the true empty state
    final hasNoDataAtAll = transactionsState.value?.isEmpty ?? false;

    return RefreshIndicator(
      onRefresh: () => ref.read(staffPointTransactionsControllerProvider.notifier).refresh(),
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceDark,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyFilterBarDelegate(
              child: const StaffTransactionFilterBar(),
            ),
          ),
          
          transactionsState.when(
            loading: () => const SliverToBoxAdapter(
              child: SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
            error: (err, stack) => SliverToBoxAdapter(
              child: TransactionEmptyState.error(
                error: err.toString(),
                onRetry: () => ref.read(staffPointTransactionsControllerProvider.notifier).refresh(),
              ),
            ),
            data: (_) {
              if (hasNoDataAtAll) {
                return SliverToBoxAdapter(
                  child: TransactionEmptyState.noTransactions(
                    onRefresh: () => ref.read(staffPointTransactionsControllerProvider.notifier).refresh(),
                  ),
                );
              }

              if (groupedTransactions.isEmpty) {
                return SliverToBoxAdapter(
                  child: TransactionEmptyState.noResults(
                    onClearFilters: () {
                      ref.read(staffTxSearchQueryProvider.notifier).updateQuery('');
                      ref.read(staffTxTypeFilterProvider.notifier).updateFilter(TxTypeFilter.all);
                      ref.read(staffTxDateRangeProvider.notifier).updateDateRange(null);
                    },
                  ),
                );
              }

              // Normal data state: SliverPadding with SliverList
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final keys = groupedTransactions.keys.toList();
                      final dateKey = keys[index];
                      final transactionsForDate = groupedTransactions[dateKey]!;
                      
                      final headerFormat = DateFormat('EEEE, MMMM d, yyyy');

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 12),
                            child: Text(
                              headerFormat.format(dateKey).toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          ...transactionsForDate.map((tx) => StaffTransactionCard(
                            transaction: tx,
                          )),
                        ],
                      );
                    },
                    childCount: groupedTransactions.length,
                  ),
                ),
              );
            },
          ),

          // Bottom padding for nav bar overlap avoidance
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _StickyFilterBarDelegate extends SliverPersistentHeaderDelegate {
  _StickyFilterBarDelegate({required this.child});
  final Widget child;

  @override
  double get minExtent => 155.0;
  @override
  double get maxExtent => 155.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: Material(
        color: AppColors.bgDark,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyFilterBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
