import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/point_transaction_staff_list_dto.dart';
import 'transaction_detail_sheet.dart';

class StaffTransactionCard extends StatelessWidget {
  const StaffTransactionCard({
    super.key,
    required this.transaction,
  });

  final PointTransactionStaffListViewDto transaction;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final currencyFormat = NumberFormat.currency(symbol: 'L ', decimalDigits: 2);
    
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
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => TransactionDetailSheet(
              transactionId: transaction.id,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Indicator
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeFormat.format(transaction.createdAt),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              
              // Main Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.customerFullName,
                      style: const TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
                    '${transaction.points > 0 ? '+' : ''}${transaction.points}',
                    style: TextStyle(
                      color: transaction.points > 0 ? AppColors.accentLight : AppColors.errorLight,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        currencyFormat.format(transaction.billAmount),
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
            ],
          ),
        ),
      ),
    ),
  );
  }
}
