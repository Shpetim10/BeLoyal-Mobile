import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/core/utils/currency_utils.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';

class CustomerTransactionDetailSheet extends StatelessWidget {
  const CustomerTransactionDetailSheet({super.key, required this.tx});
  final CustomerTransaction tx;

  static void show(BuildContext context, CustomerTransaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerTransactionDetailSheet(tx: tx),
    );
  }

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
    'EARN' => 'Earned',
    'REDEEM' => 'Redeemed',
    'REFUND' => 'Refunded',
    'EXPIRED' => 'Expired',
    'ADJUSTMENT' => 'Adjustment',
    'COUPON_PURCHASE' => 'Coupon Purchase',
    _ => tx.type,
  };

  @override
  Widget build(BuildContext context) {
    final isPositive = tx.points > 0;
    final dateFmt = DateFormat('EEEE, MMM d yyyy • h:mm a');
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.glassBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    tx.logoEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.businessName,
                      style: AppTypography.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFmt.format(tx.date),
                      style: AppTypography.dmSans(
                        fontSize: 11,
                        color: AppColors.textMutedDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Points hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${isPositive ? '+' : ''}${tx.points}',
                      style: AppTypography.dmMono(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: _color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'pts',
                      style: AppTypography.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_icon, size: 13, color: _color),
                      const SizedBox(width: 5),
                      Text(
                        _typeLabel,
                        style: AppTypography.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Detail card
          _DetailCard(
            children: [
              _DetailRow(label: 'Description', value: tx.description),
              if (tx.moneyAmount != null && tx.moneyAmount! > 0)
                _DetailRow(
                  label: 'Amount',
                  value:
                      '${currencySymbol(tx.currency)} ${tx.moneyAmount!.toStringAsFixed(0)}',
                  mono: true,
                ),
              if (tx.billAmount > 0)
                _DetailRow(
                  label: 'Bill Amount',
                  value:
                      '${currencySymbol(tx.currency)} ${tx.billAmount.toStringAsFixed(0)}',
                  mono: true,
                ),
              if (tx.netAmount > 0)
                _DetailRow(
                  label: 'Net Amount',
                  value: formatCurrency(tx.netAmount, tx.currency),
                  mono: true,
                ),
              if (tx.discountAmount != null && tx.discountAmount! > 0)
                _DetailRow(
                  label: 'Discount',
                  value: '- ${formatCurrency(tx.discountAmount!, tx.currency)}',
                  mono: true,
                  valueColor: AppColors.success,
                ),
              if (tx.ruleAmountPer != null && tx.rulePointsPer != null)
                _DetailRow(
                  label: 'Earning Rule',
                  value:
                      '${tx.rulePointsPer} pts / ${formatCurrency(tx.ruleAmountPer!, tx.currency)}',
                  mono: true,
                ),
              if (tx.scanMethod?.isNotEmpty == true)
                _DetailRow(label: 'Scan Method', value: tx.scanMethod!),
              if (tx.note?.isNotEmpty == true)
                _DetailRow(label: 'Note', value: tx.note!),
              if (tx.reason?.isNotEmpty == true)
                _DetailRow(label: 'Reason', value: tx.reason!),
              if (tx.invoiceReference?.isNotEmpty == true)
                _DetailRow(
                  label: 'Invoice Ref.',
                  value: tx.invoiceReference!,
                  mono: true,
                ),
              if (tx.referenceId?.isNotEmpty == true &&
                  tx.invoiceReference?.isEmpty != false)
                _DetailRow(
                  label: 'Reference',
                  value: tx.referenceId!,
                  mono: true,
                ),
              _DetailRow(
                label: 'Transaction ID',
                value: '#${tx.id}',
                mono: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(
          const Divider(height: 1, thickness: 1, color: AppColors.glassBorder),
        );
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(children: rows),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool mono;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.dmSans(
              fontSize: 12,
              color: AppColors.textMutedDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: mono
                  ? AppTypography.dmMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? AppColors.textOnDark,
                    )
                  : AppTypography.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? AppColors.textOnDark,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
