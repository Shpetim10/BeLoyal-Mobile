import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import '../../../../features/auth/presentation/controllers/session_controller.dart';
import '../controllers/point_transactions_controller.dart';
import '../widgets/transaction_card.dart';
import '../widgets/transaction_empty_state.dart';
import '../widgets/transaction_filter_bar.dart';

class PointTransactionsPage extends ConsumerStatefulWidget {
  const PointTransactionsPage({
    super.key,
    this.showAppBar = false,
  });

  final bool showAppBar;

  @override
  ConsumerState<PointTransactionsPage> createState() => _PointTransactionsPageState();
}

class _PointTransactionsPageState extends ConsumerState<PointTransactionsPage> {
  @override
  Widget build(BuildContext context) {
    final transactionsState = ref.watch(pointTransactionsControllerProvider);
    final groupedTransactions = ref.watch(filteredGroupedTransactionsProvider);
    
    // Check if we have no data at all (before filters) to show the true empty state
    final hasNoDataAtAll = transactionsState.value?.isEmpty ?? false;

    final session = ref.watch(sessionControllerProvider);
    final businessName = session?.activeBusinessName ?? 'Your Business';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = RefreshIndicator(
      onRefresh: () => ref.read(pointTransactionsControllerProvider.notifier).refresh(),
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceDark,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyFilterBarDelegate(
              child: const TransactionFilterBar(),
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
                onRetry: () => ref.read(pointTransactionsControllerProvider.notifier).refresh(),
              ),
            ),
            data: (_) {
              if (hasNoDataAtAll) {
                return SliverToBoxAdapter(
                  child: TransactionEmptyState.noTransactions(
                    onRefresh: () => ref.read(pointTransactionsControllerProvider.notifier).refresh(),
                  ),
                );
              }

              if (groupedTransactions.isEmpty) {
                return SliverToBoxAdapter(
                  child: TransactionEmptyState.noResults(
                    onClearFilters: () {
                      ref.read(txSearchQueryProvider.notifier).updateQuery('');
                      ref.read(txTypeFilterProvider.notifier).updateFilter(TxTypeFilter.all);
                      ref.read(txEmployeeFilterProvider.notifier).updateEmployee(null);
                      ref.read(txDateRangeProvider.notifier).updateDateRange(null);
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
                          ...transactionsForDate.map((tx) => TransactionCard(
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

    if (widget.showAppBar) {
      content = SafeArea(
        child: Column(
          children: [
            _AppBar(businessName: businessName),
            Expanded(child: content),
          ],
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: content,
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.businessName});
  final String businessName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.glassBorder : const Color(0xFFE2E8F0),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Logs',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  businessName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
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

class _StickyFilterBarDelegate extends SliverPersistentHeaderDelegate {
  _StickyFilterBarDelegate({required this.child});
  final Widget child;

  // Fixed height matching the rough size of the TransactionFilterBar to avoid layout assertions
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
