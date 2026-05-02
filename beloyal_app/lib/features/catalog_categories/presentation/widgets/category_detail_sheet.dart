import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/catalog_category.dart';
import '../../../../features/auth/presentation/controllers/session_controller.dart';
import '../../../../features/auth/domain/models/auth_user.dart';
import 'category_form_sheet.dart';
import '../controllers/catalog_category_controller.dart';

/// Full-detail bottom sheet for a [CatalogCategory].
///
/// Roles:
///   - businessAdmin: sees all metadata + action buttons (Edit live,
///     Activate/Deactivate/Delete shown as "Coming Soon").
///   - staff: read-only — no actions section.
class CategoryDetailSheet extends ConsumerWidget {
  const CategoryDetailSheet({
    super.key,
    required this.category,
    required this.businessId,
    required this.isTrashView,
    required this.onRefresh,
  });

  final CatalogCategory category;
  final int businessId;
  final bool isTrashView;
  final VoidCallback onRefresh;

  static Future<void> show(
    BuildContext context, {
    required CatalogCategory category,
    required int businessId,
    required bool isTrashView,
    required VoidCallback onRefresh,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryDetailSheet(
        category: category,
        businessId: businessId,
        isTrashView: isTrashView,
        onRefresh: onRefresh,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.read(sessionControllerProvider);
    final isAdmin = session?.activeRole == UserRole.businessAdmin;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final sheetBg = isDark ? AppColors.surfaceDark : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 40,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // ── Scrollable body ───────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ─────────────────────────────────────────────
                      _SheetHeader(category: category),
                      const SizedBox(height: 28),

                      // ── Metadata rows ──────────────────────────────────────
                      _MetaSection(
                        children: [
                          _MetaRow(
                            icon: Icons.circle_rounded,
                            iconColor: category.status.color,
                            label: 'Status',
                            child: _StatusChip(status: category.status),
                          ),
                          _MetaRow(
                            icon: Icons.format_list_numbered_rounded,
                            label: 'Order',
                            value: '#${category.orderIndex + 1}',
                          ),
                          if (category.createdAt != null)
                            _MetaRow(
                              icon: Icons.calendar_today_rounded,
                              label: 'Created',
                              value: DateFormat(
                                'MMM d, yyyy  HH:mm',
                              ).format(category.createdAt!),
                            ),
                        ],
                      ),

                      if (category.description != null &&
                          category.description!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionLabel('Description'),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : AppColors.bgLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.glassBorder
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            category.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                              color: isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textOnLight,
                            ),
                          ),
                        ),
                      ],

                      // ── Actions (Admin only) ───────────────────────────────
                      if (isAdmin) ...[
                        const SizedBox(height: 32),
                        _AdminActionsSection(
                          category: category,
                          businessId: businessId,
                          isTrashView: isTrashView,
                          onRefresh: onRefresh,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.category});
  final CatalogCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarColor = _avatarColor(category.orderIndex);
    final initial = category.name.trim().isNotEmpty
        ? category.name.trim()[0].toUpperCase()
        : '?';

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [avatarColor, avatarColor.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: avatarColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Catalog Category',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Meta Section ──────────────────────────────────────────────────────────────

class _MetaSection extends StatelessWidget {
  const _MetaSection({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.bgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.glassBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                color: isDark ? AppColors.glassBorder : const Color(0xFFE2E8F0),
              ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    this.iconColor,
    this.value,
    this.child,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor ?? AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (child != null)
            child!
          else if (value != null)
            Text(
              value!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Status Chip (inline) ──────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final CategoryStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: status.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 5),
          Text(
            status.displayName,
            style: TextStyle(
              color: status.color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.textMuted,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ── Admin Actions ─────────────────────────────────────────────────────────────

class _AdminActionsSection extends ConsumerWidget {
  const _AdminActionsSection({
    required this.category,
    required this.businessId,
    required this.isTrashView,
    required this.onRefresh,
  });

  final CatalogCategory category;
  final int businessId;
  final bool isTrashView;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isTrashView) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Actions'),
          const SizedBox(height: 14),
          _ActionButton(
            icon: Icons.restore_rounded,
            label: 'Restore Category',
            color: AppColors.secondary,
            onTap: () async {
              final controller = ref.read(
                catalogCategoryControllerProvider.notifier,
              );
              final success = await controller.restoreCategory(
                businessId: businessId,
                categoryId: category.id,
              );
              if (success) {
                if (context.mounted) Navigator.of(context).pop();
                onRefresh();
              }
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Actions'),
        const SizedBox(height: 14),

        // ── Edit ──────────────────────────────────────────────────────────
        _ActionButton(
          icon: Icons.edit_rounded,
          label: 'Edit Category',
          color: AppColors.primary,
          onTap: () {
            Navigator.of(context).pop();
            CategoryFormSheet.show(
              context,
              businessId: businessId,
              existingCategory: category,
              onSuccess: onRefresh,
            );
          },
        ),
        const SizedBox(height: 10),

        // ── Activate / Deactivate  ──────────────────────────────────────────
        _ActionButton(
          icon: category.isActive
              ? Icons.pause_circle_outline_rounded
              : Icons.play_circle_outline_rounded,
          label: category.isActive ? 'Deactivate' : 'Activate',
          color: category.isActive ? AppColors.warning : AppColors.secondary,
          onTap: () async {
            final controller = ref.read(
              catalogCategoryControllerProvider.notifier,
            );
            if (category.isActive) {
              await controller.deactivateCategory(
                businessId: businessId,
                categoryId: category.id,
              );
            } else {
              await controller.activateCategory(
                businessId: businessId,
                categoryId: category.id,
              );
            }
            if (context.mounted) Navigator.of(context).pop();
            onRefresh();
          },
        ),
        const SizedBox(height: 10),

        // ── Delete ──────────────────────────────────────────
        _ActionButton(
          icon: Icons.delete_outline_rounded,
          label: 'Delete Category',
          color: AppColors.error,
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Category?'),
                content: const Text(
                  'Are you sure you want to delete this category? This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      'DELETE',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              final controller = ref.read(
                catalogCategoryControllerProvider.notifier,
              );
              final success = await controller.deleteCategory(
                businessId: businessId,
                categoryId: category.id,
              );
              if (success) {
                if (context.mounted) Navigator.of(context).pop();
                onRefresh();
              }
            }
          },
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: color.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────

Color _avatarColor(int index) {
  const palette = [
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFFDC2626),
    Color(0xFF0891B2),
    Color(0xFF65A30D),
  ];
  return palette[index % palette.length];
}
