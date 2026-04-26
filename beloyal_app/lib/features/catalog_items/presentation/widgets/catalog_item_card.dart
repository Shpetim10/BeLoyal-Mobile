import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/catalog_item_short_response.dart';
import '../../data/models/catalog_item_status.dart';

class CatalogItemCard extends StatefulWidget {
  const CatalogItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.animationIndex = 0,
    this.isReorderable = false,
  });

  final CatalogItemShortResponse item;
  final VoidCallback onTap;
  final int animationIndex;
  final bool isReorderable;

  @override
  State<CatalogItemCard> createState() => _CatalogItemCardState();
}

class _CatalogItemCardState extends State<CatalogItemCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = widget.item;

    final cardColor = isDark
        ? AppColors.surfaceDark.withValues(alpha: 0.9)
        : Colors.white;

    final borderColor = isDark
        ? AppColors.glassBorder
        : const Color(0xFFE2E8F0);

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
              if (item.status == CatalogItemStatus.active)
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
                _buildImagePlaceholder(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _OrderBadge(index: item.orderIndex),
                        ],
                      ),
                      if (item.categoryName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.categoryName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StatusBadge(status: item.status),

                          const Spacer(),
                          Text(
                            '${_getCurrencySymbol(item.currencyCode)} ${item.price.toStringAsFixed(2)}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
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

  String _getCurrencySymbol(String? currency) {
    switch (currency?.toUpperCase()) {
      case 'EURO':
      case 'EUR':
        return '€';
      case 'DOLLAR':
      case 'USD':
        return '\$';
      case 'LEK':
      case 'ALL':
        return 'L';
      default:
        return '€'; // default
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        image: widget.item.imageUrl != null
            ? DecorationImage(
                image: NetworkImage(widget.item.imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: widget.item.imageUrl == null
          ? const Icon(Icons.image_outlined, color: AppColors.primary)
          : null,
    );
  }
}

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
        '#${index + 1}',
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final CatalogItemStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;

    switch (status) {
      case CatalogItemStatus.active:
        color = AppColors.secondary;
        bgColor = AppColors.secondary.withValues(alpha: 0.1);
        break;
      case CatalogItemStatus.inactive:
        color = AppColors.warning;
        bgColor = AppColors.warning.withValues(alpha: 0.1);
        break;
      case CatalogItemStatus.deleted:
        color = AppColors.error;
        bgColor = AppColors.error.withValues(alpha: 0.1);
        break;
    }

    final isActuallyDeleted = status == CatalogItemStatus.deleted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
