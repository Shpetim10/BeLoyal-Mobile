import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/catalog_category.dart';

/// Premium category list item card.
///
/// Visual layout:
///   [Avatar] [Name + Desc + Badge + Order] [DragHandle]
///
/// The drag handle is visible now for future reorder UX.
/// Tapping the card opens the category details bottom sheet.
class CategoryCard extends StatefulWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.animationIndex = 0,
    this.isReorderable = false,
  });

  final CatalogCategory category;
  final VoidCallback onTap;
  final int animationIndex;
  final bool isReorderable;

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cat = widget.category;

    final cardColor = isDark
        ? AppColors.surfaceDark.withValues(alpha: 0.9)
        : Colors.white;

    final borderColor = isDark
        ? AppColors.glassBorder
        : const Color(0xFFE2E8F0);

    final avatarColor = _categoryColor(cat.orderIndex);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isReorderable) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              if (cat.isActive)
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.06),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // ── Avatar ─────────────────────────────────────────────────
                _CategoryAvatar(name: cat.name, color: avatarColor),
                const SizedBox(width: 14),

                // ── Content ────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name + order index
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cat.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _OrderBadge(index: cat.orderIndex),
                        ],
                      ),

                      if (cat.description != null &&
                          cat.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          cat.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),
                      _StatusBadge(status: cat.status),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // ── Right side: Drag Handle + Chevron ─────────────────────
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isReorderable)
                      ReorderableDragStartListener(
                        index: widget.animationIndex,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            size: 26,
                            color: AppColors.primary.withValues(alpha: 0.8),
                          ),
                        ),
                      )
                    else ...[
                      Icon(
                        Icons.drag_handle_rounded,
                        size: 22,
                        color: AppColors.textMuted.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.textMuted.withValues(alpha: 0.6),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: (widget.animationIndex * 55).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.18, end: 0, curve: Curves.easeOut);
  }
}

// ── Avatar ───────────────────────────────────────────────────────────────────

class _CategoryAvatar extends StatelessWidget {
  const _CategoryAvatar({required this.name, required this.color});
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

// ── Order Badge ───────────────────────────────────────────────────────────────

class _OrderBadge extends StatelessWidget {
  const _OrderBadge({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '#${index+1}',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final CategoryStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: status.color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 11, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: status.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Color palette for avatars ─────────────────────────────────────────────────

Color _categoryColor(int index) {
  const palette = [
    Color(0xFF2563EB), // Blue
    Color(0xFF7C3AED), // Violet
    Color(0xFFDB2777), // Pink
    Color(0xFF059669), // Emerald
    Color(0xFFD97706), // Amber
    Color(0xFFDC2626), // Red
    Color(0xFF0891B2), // Cyan
    Color(0xFF65A30D), // Lime
  ];
  return palette[index % palette.length];
}
