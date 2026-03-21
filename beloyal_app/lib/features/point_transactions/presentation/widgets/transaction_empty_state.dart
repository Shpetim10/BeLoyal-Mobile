import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TransactionEmptyState extends StatelessWidget {
  const TransactionEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  factory TransactionEmptyState.noTransactions({VoidCallback? onRefresh}) {
    return TransactionEmptyState(
      icon: Icons.receipt_long_rounded,
      title: 'No Transactions',
      message: 'There are no points transactions for this business yet.',
      actionLabel: onRefresh != null ? 'Refresh' : null,
      onAction: onRefresh,
    );
  }

  factory TransactionEmptyState.noResults({required VoidCallback onClearFilters}) {
    return TransactionEmptyState(
      icon: Icons.search_off_rounded,
      title: 'No Matches Found',
      message: 'Adjust your filters or search query to see results.',
      actionLabel: 'Clear Filters',
      onAction: onClearFilters,
    );
  }

  factory TransactionEmptyState.error({required String error, required VoidCallback onRetry}) {
    return TransactionEmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Something went wrong',
      message: error,
      actionLabel: 'Try Again',
      onAction: onRetry,
    );
  }

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Icon(icon, size: 48, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnDark,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
