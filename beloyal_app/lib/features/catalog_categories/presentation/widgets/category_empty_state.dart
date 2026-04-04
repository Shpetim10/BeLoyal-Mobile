import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';

/// Premium empty state for when there are no categories to display.
class CategoryEmptyState extends StatelessWidget {
  const CategoryEmptyState({
    super.key,
    required this.isAdmin,
    required this.onCreateTap,
    this.isFiltered = false,
  });

  /// True = businessAdmin (can create). False = staff (read-only).
  final bool isAdmin;
  final VoidCallback onCreateTap;

  /// True when the empty state is due to a search/filter (not truly empty).
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final heading = isFiltered
        ? 'No results found'
        : 'No categories yet';
    final sub = isFiltered
        ? 'Try adjusting your search or filter.'
        : isAdmin
            ? 'Create your first category to start organising your catalog.'
            : 'No categories have been created yet.\nContact your admin to get started.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ────────────────────────────────────────────────────────
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.category_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.7, 0.7),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            // ── Heading ──────────────────────────────────────────────────────
            Text(
              heading,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            )
                .animate(delay: 100.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.2, curve: Curves.easeOut),

            const SizedBox(height: 10),

            // ── Subtitle ─────────────────────────────────────────────────────
            Text(
              sub,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                height: 1.55,
              ),
            )
                .animate(delay: 180.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.2, curve: Curves.easeOut),

            if (isAdmin && !isFiltered) ...[
              const SizedBox(height: 32),

              // ── CTA ──────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: onCreateTap,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Create Category'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              )
                  .animate(delay: 280.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.3, curve: Curves.easeOut),
            ],
          ],
        ),
      ),
    );
  }
}
