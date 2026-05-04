import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StaffEmptyState extends StatelessWidget {
  const StaffEmptyState.empty({super.key, required this.onInvite})
    : _type = _EmptyStateType.empty,
      _query = null;

  const StaffEmptyState.noResults({
    super.key,
    required String query,
    required this.onInvite,
  }) : _type = _EmptyStateType.noResults,
       _query = query;

  const StaffEmptyState.error({super.key, required this.onInvite})
    : _type = _EmptyStateType.error,
      _query = null;

  final _EmptyStateType _type;
  final String? _query;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(_icon, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              _title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _subtitle,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_type == _EmptyStateType.noResults)
              OutlinedButton.icon(
                onPressed: onInvite, // Reused as Clear Filters action
                icon: const Icon(
                  Icons.filter_alt_off_rounded,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Clear Filters',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: onInvite, // Reused as Retry action
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (_type) {
    _EmptyStateType.empty => Icons.people_outline_rounded,
    _EmptyStateType.noResults => Icons.search_off_rounded,
    _EmptyStateType.error => Icons.error_outline_rounded,
  };

  String get _title => switch (_type) {
    _EmptyStateType.empty => 'No staff yet',
    _EmptyStateType.noResults => 'No matches found',
    _EmptyStateType.error => 'Something went wrong',
  };

  String get _subtitle => switch (_type) {
    _EmptyStateType.empty =>
      'Invite your team to start managing orders and loyalty directly from the BesaHub app.',
    _EmptyStateType.noResults =>
      'We couldn\'t find any staff matching "$_query". Try adjusting your filters or search term.',
    _EmptyStateType.error =>
      'We encountered an error while loading your staff list. Please check your connection and try again.',
  };
}

enum _EmptyStateType { empty, noResults, error }
