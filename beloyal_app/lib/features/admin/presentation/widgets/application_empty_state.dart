import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ApplicationEmptyState extends StatelessWidget {
  const ApplicationEmptyState({
    super.key,
    required this.message,
    required this.subMessage,
    required this.icon,
    this.onAction,
    this.actionLabel,
  });

  factory ApplicationEmptyState.noPending({VoidCallback? onRefresh}) {
    return ApplicationEmptyState(
      message: 'No pending applications',
      subMessage:
          'When businesses apply, they\'ll appear here for your review.',
      icon: Icons.check_circle_outline_rounded,
      onAction: onRefresh,
      actionLabel: 'Refresh',
    );
  }

  factory ApplicationEmptyState.noResults({VoidCallback? onClearFilters}) {
    return ApplicationEmptyState(
      message: 'No results found',
      subMessage: 'Try adjusting your search or filters.',
      icon: Icons.search_off_rounded,
      onAction: onClearFilters,
      actionLabel: 'Clear Filters',
    );
  }

  factory ApplicationEmptyState.error({
    required String error,
    VoidCallback? onRetry,
  }) {
    return ApplicationEmptyState(
      message: 'Something went wrong',
      subMessage: error,
      icon: Icons.error_outline_rounded,
      onAction: onRetry,
      actionLabel: 'Retry',
    );
  }

  final String message;
  final String subMessage;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
