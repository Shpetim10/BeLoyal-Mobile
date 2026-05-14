import 'package:flutter/material.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_transaction_detail_sheet.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../data/models/point_transaction_customer_list_dto.dart';

class CustomerTransactionCard extends StatelessWidget {
  const CustomerTransactionCard({
    super.key,
    required this.transaction,
  });

  final PointTransactionCustomerAllListViewDto transaction;

  @override
  Widget build(BuildContext context) {
    final isEarn = transaction.points > 0 || transaction.type.toUpperCase() == 'EARN_BILL';
    final customerTransaction = CustomerTransaction(
      id: transaction.id,
      businessId: 0,
      businessName: transaction.businessName,
      type: _mapCustomerType(transaction.type),
      points: transaction.points,
      date: transaction.createdAt,
      description: _descriptionForCustomerTransaction(transaction),
      netAmount: transaction.netAmount,
      billAmount: transaction.billAmount,
      logoEmoji: '🏪',
      referenceId: transaction.billTransactionReferenceId,
      discountAmount: transaction.discountAmount,
    );
    
    // Determine Type Colors
    Color typeColor;
    String typeLabel;
    IconData typeIcon;
    
    switch (transaction.type.toUpperCase()) {
      case 'EARN_BILL':
        typeColor = AppColors.secondary;
        typeLabel = 'EARN';
        typeIcon = Icons.arrow_upward_rounded;
        break;
      case 'REDEEM_DISCOUNT':
        typeColor = AppColors.error;
        typeLabel = 'REDEEM';
        typeIcon = Icons.arrow_downward_rounded;
        break;
      case 'REDEEM_OFFER':
        typeColor = AppColors.error;
        typeLabel = 'OFFER';
        typeIcon = Icons.local_offer_rounded;
        break;
      case 'EXPIRE':
        typeColor = AppColors.error;
        typeLabel = 'EXPIRED';
        typeIcon = Icons.history_rounded;
        break;
      case 'ADJUSTMENT_PLUS':
        typeColor = AppColors.secondary;
        typeLabel = 'ADJ +';
        typeIcon = Icons.add_circle_outline_rounded;
        break;
      case 'ADJUSTMENT_MINUS':
        typeColor = AppColors.error;
        typeLabel = 'ADJ -';
        typeIcon = Icons.remove_circle_outline_rounded;
        break;
      case 'REVERSAL':
        typeColor = AppColors.warning;
        typeLabel = 'REVERSAL';
        typeIcon = Icons.undo_rounded;
        break;
      default:
        typeColor = AppColors.textMuted;
        typeLabel = transaction.type;
        typeIcon = Icons.receipt_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
        onTap: () => CustomerTransactionDetailSheet.show(
          context,
          customerTransaction,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Business Logo or Fallback
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bgDark,
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: ClipOval(
                  child: transaction.businessLogoPath != null && transaction.businessLogoPath!.isNotEmpty
                      ? Image.network(
                          transaction.businessLogoPath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.storefront_rounded, color: AppColors.textMuted, size: 24),
                        )
                      : const Icon(Icons.storefront_rounded, color: AppColors.textMuted, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              
              // Main Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.businessName,
                      style: const TextStyle(
                         color: AppColors.textOnDark,
                         fontSize: 15,
                         fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.businessLocation,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Type Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(typeIcon, size: 12, color: typeColor),
                              const SizedBox(width: 4),
                              Text(
                                typeLabel,
                                style: TextStyle(
                                  color: typeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Right Column (Points & Amounts)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isEarn ? '+' : ''}${transaction.points}',
                    style: TextStyle(
                      color: isEarn ? AppColors.accentLight : AppColors.errorLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatCurrency(transaction.netAmount, null),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

String _mapCustomerType(String type) {
  switch (type.toUpperCase()) {
    case 'EARN_BILL':
      return 'EARN';
    case 'REDEEM_DISCOUNT':
    case 'REDEEM_OFFER':
      return 'REDEEM';
    case 'EXPIRE':
      return 'EXPIRED';
    case 'ADJUSTMENT_PLUS':
    case 'ADJUSTMENT_MINUS':
      return 'ADJUSTMENT';
    case 'REVERSAL':
      return 'REFUND';
    default:
      return type.toUpperCase();
  }
}

String _descriptionForCustomerTransaction(
  PointTransactionCustomerAllListViewDto transaction,
) {
  final location = transaction.businessLocation.trim();
  switch (transaction.type.toUpperCase()) {
    case 'EARN_BILL':
      return location.isEmpty
          ? 'Points earned from purchase'
          : 'Points earned from purchase at $location';
    case 'REDEEM_DISCOUNT':
      return 'Points redeemed for discount';
    case 'REDEEM_OFFER':
      return 'Points redeemed for offer';
    case 'EXPIRE':
      return 'Points expired';
    case 'ADJUSTMENT_PLUS':
      return 'Points adjustment added';
    case 'ADJUSTMENT_MINUS':
      return 'Points adjustment removed';
    case 'REVERSAL':
      return 'Transaction reversed';
    default:
      return transaction.type;
  }
}
