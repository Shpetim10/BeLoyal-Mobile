import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/data/providers/customer_providers.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_async_state.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_transaction_detail_sheet.dart';

enum _TxFilter {
  all,
  earn,
  redeem,
  couponPurchase,
  expired,
  refunded,
  adjustment,
}

class CustomerOrdersTab extends ConsumerStatefulWidget {
  const CustomerOrdersTab({super.key});

  @override
  ConsumerState<CustomerOrdersTab> createState() => _CustomerOrdersTabState();
}

class _CustomerOrdersTabState extends ConsumerState<CustomerOrdersTab> {
  _TxFilter _filter = _TxFilter.all;

  List<CustomerTransaction> _filtered(List<CustomerTransaction> transactions) {
    final all = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
    if (_filter == _TxFilter.all) return all;
    final typeStr = switch (_filter) {
      _TxFilter.earn => 'EARN',
      _TxFilter.redeem => 'REDEEM',
      _TxFilter.couponPurchase => 'COUPON_PURCHASE',
      _TxFilter.expired => 'EXPIRED',
      _TxFilter.refunded => 'REFUND',
      _TxFilter.adjustment => 'ADJUSTMENT',
      _TxFilter.all => '',
    };
    return all.where((t) => t.type == typeStr).toList();
  }

  Map<String, List<CustomerTransaction>> _grouped(
    List<CustomerTransaction> txs,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final groups = <String, List<CustomerTransaction>>{};
    for (final tx in txs) {
      final d = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String label;
      if (d == today) {
        label = 'Today';
      } else if (d == yesterday) {
        label = 'Yesterday';
      } else if (now.difference(d).inDays < 7) {
        label = DateFormat('EEEE').format(tx.date);
      } else {
        label = DateFormat('MMMM d, y').format(tx.date);
      }
      groups.putIfAbsent(label, () => []).add(tx);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final customerData = ref.watch(customerDataProvider);

    return customerData.when(
      loading: () => const CustomerLoadingState(),
      error: (_, __) => CustomerErrorState(
        onRetry: () => ref.read(customerDataProvider.notifier).refresh(),
      ),
      data: (data) {
        final txs = _filtered(data.transactions);
        final grouped = _grouped(txs);
        final totalEarned = txs
            .where((t) => t.type == 'EARN')
            .fold(0, (s, t) => s + t.points);
        final totalSpent = txs
            .where((t) => t.type == 'REDEEM')
            .fold(0, (s, t) => s + t.points.abs());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  _SummaryPill(
                    label: 'Earned',
                    value: '+$totalEarned pts',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 10),
                  _SummaryPill(
                    label: 'Spent',
                    value: '-$totalSpent pts',
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 10),
                  _SummaryPill(
                    label: 'Total',
                    value: '${txs.length}',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: _TxFilter.values.map((f) {
                  final isSelected = _filter == f;
                  final label = switch (f) {
                    _TxFilter.all => 'All',
                    _TxFilter.earn => 'Earned',
                    _TxFilter.redeem => 'Spent',
                    _TxFilter.couponPurchase => 'Coupons Bought',
                    _TxFilter.expired => 'Expired',
                    _TxFilter.refunded => 'Refunded',
                    _TxFilter.adjustment => 'Adjustments',
                  };
                  final color = switch (f) {
                    _TxFilter.earn => AppColors.success,
                    _TxFilter.refunded => AppColors.info,
                    _TxFilter.expired => AppColors.textMutedDark,
                    _TxFilter.adjustment => AppColors.warning,
                    _TxFilter.couponPurchase => AppColors.secondary,
                    _TxFilter.redeem => AppColors.error,
                    _TxFilter.all => AppColors.primary,
                  };
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : AppColors.cardDark,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? color.withValues(alpha: 0.5)
                              : AppColors.glassBorder,
                        ),
                      ),
                      child: Text(
                        label,
                        style: AppTypography.dmSans(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? color : AppColors.textMutedDark,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: txs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_outlined,
                            size: 52,
                            color: AppColors.textMutedDark.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions',
                            style: AppTypography.dmSans(
                              fontSize: 14,
                              color: AppColors.textMutedDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try a different filter',
                            style: AppTypography.dmSans(
                              fontSize: 12,
                              color: AppColors.textMutedDark.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                      physics: const BouncingScrollPhysics(),
                      children: grouped.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    entry.key,
                                    style: AppTypography.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMutedDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...entry.value.map(
                              (tx) => _TxCard(
                                tx: tx,
                                onTap: () {
                                  // Prefer richer transaction data from
                                  // business detail cache if already loaded;
                                  // the home endpoint returns sparse fields.
                                  final detailState = ref.read(
                                    customerBusinessDetailProvider(tx.businessId),
                                  );
                                  final richTx = detailState.asData?.value
                                      .transactions
                                      .where((t) => t.id == tx.id)
                                      .firstOrNull;
                                  CustomerTransactionDetailSheet.show(
                                    context,
                                    richTx ?? tx,
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Summary Pill ──────────────────────────────────────────────────────────────

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.dmMono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.dmSans(
                fontSize: 10,
                color: AppColors.textMutedDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Transaction Card ─────────────────────────────────────────────────────────

class _TxCard extends StatelessWidget {
  const _TxCard({required this.tx, this.onTap});
  final CustomerTransaction tx;
  final VoidCallback? onTap;

  Color get _typeColor => switch (tx.type) {
    'EARN' => AppColors.success,
    'REFUND' => AppColors.info,
    'ADJUSTMENT' => AppColors.warning,
    'EXPIRED' => AppColors.textMutedDark,
    'COUPON_PURCHASE' => AppColors.secondary,
    _ => AppColors.error,
  };

  IconData get _typeIcon => switch (tx.type) {
    'EARN' => Icons.arrow_upward_rounded,
    'REFUND' => Icons.undo_rounded,
    'ADJUSTMENT' => Icons.tune_rounded,
    'EXPIRED' => Icons.hourglass_empty_rounded,
    'COUPON_PURCHASE' => Icons.confirmation_number_rounded,
    _ => Icons.arrow_downward_rounded,
  };

  String get _typeLabel => switch (tx.type) {
    'EARN' => 'EARN',
    'REDEEM' => 'REDEEM',
    'EXPIRED' => 'EXPIRED',
    'REFUND' => 'REFUND',
    'ADJUSTMENT' => 'ADJUST',
    'COUPON_PURCHASE' => 'COUPON',
    _ => tx.type,
  };

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('h:mm a');
    final isPositive = tx.points > 0;

    return GestureDetector(
      onTap: onTap,
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(tx.logoEmoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
                Text(
                  tx.description,
                  style: AppTypography.dmSans(
                    fontSize: 11,
                    color: AppColors.textMutedDark,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _typeColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_typeIcon, size: 9, color: _typeColor),
                          const SizedBox(width: 3),
                          Text(
                            _typeLabel,
                            style: AppTypography.dmSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _typeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeFmt.format(tx.date),
                      style: AppTypography.dmSans(
                        fontSize: 10,
                        color: AppColors.textMutedDark,
                      ),
                    ),
                    if (tx.billAmount > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '· L ${tx.billAmount.toStringAsFixed(0)}',
                        style: AppTypography.dmMono(
                          fontSize: 10,
                          color: AppColors.textMutedDark,
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
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _typeColor,
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
  }
}
