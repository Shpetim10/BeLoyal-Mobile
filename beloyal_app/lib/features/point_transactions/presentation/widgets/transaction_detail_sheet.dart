import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/besa_loader.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../data/models/point_transaction_view_dto.dart';
import '../../data/point_transactions_repository.dart';

final transactionDetailProvider = FutureProvider.autoDispose.family<PointTransactionViewDto, ({int businessId, int txId})>((ref, args) async {
  return ref.read(pointTransactionsRepositoryProvider).fetchTransactionDetail(args.businessId, args.txId);
});

class TransactionDetailSheet extends ConsumerWidget {
  const TransactionDetailSheet({super.key, required this.transactionId});

  final int transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final businessId = session?.activeBusinessId ?? 0;
    final currencyCode = ref.watch(activeBusinessCurrencyProvider);
    final detailAsync = ref.watch(transactionDetailProvider((businessId: businessId, txId: transactionId)));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Expanded(
            child: detailAsync.when(
              loading: () => const Center(child: BesaLoader(size: 40)),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(transactionDetailProvider((businessId: businessId, txId: transactionId))),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (detail) => _buildContent(context, detail, currencyCode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, PointTransactionViewDto detail, String? currencyCode) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    Color typeColor;
    String typeLabel;
    
    switch (detail.type.toUpperCase()) {
      case 'EARN_BILL':
        typeColor = AppColors.secondary;
        typeLabel = 'EARN';
        break;
      case 'REDEEM_DISCOUNT':
        typeColor = AppColors.error;
        typeLabel = 'REDEEM';
        break;
      case 'REDEEM_OFFER':
        typeColor = AppColors.error;
        typeLabel = 'OFFER';
        break;
      case 'EXPIRE':
        typeColor = AppColors.error;
        typeLabel = 'EXPIRED';
        break;
      case 'ADJUSTMENT_PLUS':
        typeColor = AppColors.secondary;
        typeLabel = 'ADJ +';
        break;
      case 'ADJUSTMENT_MINUS':
        typeColor = AppColors.error;
        typeLabel = 'ADJ -';
        break;
      case 'REVERSAL':
        typeColor = AppColors.warning;
        typeLabel = 'REVERSAL';
        break;
      default:
        typeColor = AppColors.textMuted;
        typeLabel = detail.type;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.customerFullName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textOnDark,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${detail.pointsDelta > 0 ? '+' : ''}${detail.pointsDelta}',
                    style: TextStyle(
                      color: detail.pointsDelta > 0 ? AppColors.accentLight : AppColors.errorLight,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Pts',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Divider(color: AppColors.glassBorder),
          const SizedBox(height: 16),
          
          // Customer Details Box
          _buildSectionTitle('Customer Information'),
          _buildDetailRow('Email', detail.customerEmail ?? 'N/A'),
          _buildDetailRow('Phone', detail.customerPhone ?? 'N/A'),
          _buildDetailRow('Available Points', detail.availablePoints.toString()),
          _buildDetailRow('Lifetime Earned', detail.lifetimeEarnedPoints.toString()),
          
          const SizedBox(height: 24),
          const Divider(color: AppColors.glassBorder),
          const SizedBox(height: 16),
          
          // Transaction Details
          _buildSectionTitle('Transaction Details'),
          _buildDetailRow('Date', dateFormat.format(detail.createdAt)),
          _buildDetailRow('Processed By', detail.businessMemberFullName),
          if (detail.reason != null) _buildDetailRow('Reason', detail.reason!),
          if (detail.description != null) _buildDetailRow('Description', detail.description!),

          const SizedBox(height: 24),
          const Divider(color: AppColors.glassBorder),
          const SizedBox(height: 16),

          // Bill Details
          _buildSectionTitle('Bill Details'),
          _buildDetailRow('Invoice Ref', detail.invoiceReference ?? 'None'),
          if (detail.note != null) _buildDetailRow('Note', detail.note!),
          _buildDetailRow('Net Amount', formatCurrency(detail.netAmount, currencyCode)),
          if (detail.discountAmount != null && detail.discountAmount! > 0)
            _buildDetailRow('Discount', '-${formatCurrency(detail.discountAmount!, currencyCode)}', valueColor: AppColors.errorLight),
          _buildDetailRow(
            'Total Bill',
            formatCurrency(detail.billAmount, currencyCode),
            isBold: true, 
            valueColor: AppColors.primaryLight
          ),

          // Rule Details if Earn Setup
          if (detail.type.toUpperCase() == 'EARN' && detail.ruleAmountPer != null && detail.rulePointsPer != null) ...[
            const SizedBox(height: 24),
            const Divider(color: AppColors.glassBorder),
            const SizedBox(height: 16),
            _buildSectionTitle('Applied Rule Snapshot'),
            _buildDetailRow('Rule', '${detail.rulePointsPer} pts / ${formatCurrency(detail.ruleAmountPer ?? 0, currencyCode)}'),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? AppColors.textOnDark,
                fontSize: 15,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
