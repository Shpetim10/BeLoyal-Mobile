import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/besa_loader.dart';
import '../controllers/customer_transactions_controller.dart';
import '../widgets/customer_transaction_card.dart';
import '../widgets/transaction_empty_state.dart';
import 'package:collection/collection.dart';
import '../../data/models/point_transaction_customer_list_dto.dart';

class CustomerPointTransactionsPage extends ConsumerStatefulWidget {
  const CustomerPointTransactionsPage({super.key});

  @override
  ConsumerState<CustomerPointTransactionsPage> createState() => _CustomerPointTransactionsPageState();
}

class _CustomerPointTransactionsPageState extends ConsumerState<CustomerPointTransactionsPage> {
  @override
  Widget build(BuildContext context) {
    final transactionsState = ref.watch(customerTransactionsControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Premium Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
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
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Transactions',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Your activity history',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(customerTransactionsControllerProvider.notifier).refresh(),
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceDark,
                child: transactionsState.when(
                  loading: () => const Center(child: BesaLoader()),
                  error: (err, stack) => TransactionEmptyState.error(
                    error: err.toString(),
                    onRetry: () => ref.read(customerTransactionsControllerProvider.notifier).refresh(),
                  ),
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return TransactionEmptyState.noTransactions(
                        onRefresh: () => ref.read(customerTransactionsControllerProvider.notifier).refresh(),
                      );
                    }

                    // Group by date
                    final groupedTransactions = groupBy<PointTransactionCustomerAllListViewDto, DateTime>(
                      transactions,
                      (tx) => DateTime(tx.createdAt.year, tx.createdAt.month, tx.createdAt.day),
                    );

                    final keys = groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a));

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: keys.length,
                      itemBuilder: (context, index) {
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
                            ...transactionsForDate.map((tx) => CustomerTransactionCard(
                              transaction: tx,
                            )),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
