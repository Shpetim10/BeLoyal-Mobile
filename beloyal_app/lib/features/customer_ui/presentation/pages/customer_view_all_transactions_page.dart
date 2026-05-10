import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/data/providers/customer_providers.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_async_state.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_transaction_detail_sheet.dart';

class CustomerViewAllTransactionsPage extends ConsumerStatefulWidget {
  const CustomerViewAllTransactionsPage({
    super.key,
    this.initialFilter = 'ALL',
    this.title = 'Transactions',
    this.transactions,
  });

  final String initialFilter;
  final String title;
  final List<CustomerTransaction>? transactions;

  @override
  ConsumerState<CustomerViewAllTransactionsPage> createState() =>
      _CustomerViewAllTransactionsPageState();
}

class _CustomerViewAllTransactionsPageState
    extends ConsumerState<CustomerViewAllTransactionsPage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late TabController _tabCtrl;

  static const _tabs = [
    ('ALL', 'Total'),
    ('EARN', 'Earned'),
    ('REDEEM', 'Spent'),
  ];

  @override
  void initState() {
    super.initState();
    // Map legacy initialFilter to tab index
    int initial = 0;
    if (widget.initialFilter == 'EARN') initial = 1;
    if (widget.initialFilter == 'REDEEM') initial = 2;
    _tabCtrl = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initial,
    );
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CustomerTransaction> _filtered(
    List<CustomerTransaction> transactions,
    String typeFilter,
  ) {
    final source = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
    return source.where((t) {
      if (_searchQuery.isNotEmpty &&
          !t.businessName.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !t.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (typeFilter == 'ALL') return true;
      return t.type == typeFilter;
    }).toList();
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
    if (widget.transactions != null) {
      return _buildScaffold(widget.transactions!);
    }

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
                widget.title,
                style: AppTypography.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textOnDark,
                ),
              ),
              Text(
                '${data.transactions.length} transactions',
                style: AppTypography.dmSans(
                  fontSize: 12,
                  color: AppColors.textMutedDark,
                ),
              ),
            ],
          ),
          orElse: () => Text(
            widget.title,
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
        data: (data) => _buildBody(data.transactions),
      ),
    );
  }

  Scaffold _buildScaffold(List<CustomerTransaction> transactions) {
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: AppTypography.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textOnDark,
              ),
            ),
            Text(
              '${transactions.length} transactions',
              style: AppTypography.dmSans(
                fontSize: 12,
                color: AppColors.textMutedDark,
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(transactions),
    );
  }

  Widget _buildBody(List<CustomerTransaction> transactions) {
    final allTxs = _filtered(transactions, 'ALL');
    final totalEarned = allTxs
        .where((t) => t.type == 'EARN')
        .fold(0, (s, t) => s + t.points);
    final totalSpent = allTxs
        .where((t) => t.type == 'REDEEM')
        .fold(0, (s, t) => s + t.points.abs());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
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
                value: '${allTxs.length}',
                color: AppColors.primary,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: AppTypography.dmSans(
              fontSize: 14,
              color: AppColors.textOnDark,
            ),
            decoration: InputDecoration(
              hintText: 'Search transactions...',
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
        Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textMutedDark,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: AppTypography.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: AppTypography.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Total'),
              Tab(text: 'Earned'),
              Tab(text: 'Spent'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: _tabs.map((tab) {
              final txs = _filtered(transactions, tab.$1);
              final grouped = _grouped(txs);
              final dateFmt = DateFormat('h:mm a');

              if (txs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_outlined,
                        size: 56,
                        color: AppColors.textMutedDark.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions found.',
                        style: AppTypography.dmSans(
                          fontSize: 14,
                          color: AppColors.textMutedDark,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
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
                          timeFmt: dateFmt,
                          onTap: () => CustomerTransactionDetailSheet.show(context, tx),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

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

class _TxCard extends StatelessWidget {
  const _TxCard({required this.tx, required this.timeFmt, this.onTap});
  final CustomerTransaction tx;
  final DateFormat timeFmt;
  final VoidCallback? onTap;

  Color get _color => switch (tx.type) {
    'EARN' => AppColors.success,
    'REFUND' => AppColors.info,
    'ADJUSTMENT' => AppColors.warning,
    'EXPIRED' => AppColors.textMutedDark,
    'COUPON_PURCHASE' => AppColors.secondary,
    _ => AppColors.error,
  };

  IconData get _icon => switch (tx.type) {
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
    'REFUND' => 'REFUND',
    'EXPIRED' => 'EXPIRED',
    'ADJUSTMENT' => 'ADJUST',
    'COUPON_PURCHASE' => 'COUPON',
    _ => tx.type,
  };

  @override
  Widget build(BuildContext context) {
    final isPositive = tx.points > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
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
                    color: _color.withValues(alpha: 0.10),
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
                              color: _color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_icon, size: 9, color: _color),
                                const SizedBox(width: 3),
                                Text(
                                  _typeLabel,
                                  style: AppTypography.dmSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: _color,
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
                        color: _color,
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
        ),
      ),
    );
  }
}
