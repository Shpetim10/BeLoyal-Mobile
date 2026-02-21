import 'package:flutter/material.dart';
import 'package:besahub_app/core/theme/app_colors.dart';

/// A single icon + label item for the side slots of [DashboardNavBar].
class DashboardNavItem {
  const DashboardNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Role-aware custom bottom navigation bar.
///
/// Layout: [left0] [left1] [★ center (elevated)] [right0] [right1]
///
/// The center button floats above the bar via [Transform.translate].
/// [selectedIndex] uses positions 0-4 where 2 is always the center action.
class DashboardNavBar extends StatelessWidget {
  const DashboardNavBar({
    super.key,
    required this.leftItems,
    required this.rightItems,
    required this.centerIcon,
    required this.centerLabel,
    required this.centerGradient,
    required this.selectedIndex,
    required this.onTap,
  }) : assert(leftItems.length == 2, 'Exactly 2 left items required'),
       assert(rightItems.length == 2, 'Exactly 2 right items required');

  final List<DashboardNavItem> leftItems;
  final List<DashboardNavItem> rightItems;
  final IconData centerIcon;
  final String centerLabel;
  final Gradient centerGradient;

  /// 0 = leftItems[0], 1 = leftItems[1],
  /// 2 = center, 3 = rightItems[0], 4 = rightItems[1]
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // ── Left items ──
            _NavSideItem(
              item: leftItems[0],
              isSelected: selectedIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavSideItem(
              item: leftItems[1],
              isSelected: selectedIndex == 1,
              onTap: () => onTap(1),
            ),

            // ── Center raised action button ──
            _CenterActionButton(
              icon: centerIcon,
              label: centerLabel,
              gradient: centerGradient,
              isSelected: selectedIndex == 2,
              onTap: () => onTap(2),
            ),

            // ── Right items ──
            _NavSideItem(
              item: rightItems[0],
              isSelected: selectedIndex == 3,
              onTap: () => onTap(3),
            ),
            _NavSideItem(
              item: rightItems[1],
              isSelected: selectedIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Flat icon + label nav item for the 4 side slots.
class _NavSideItem extends StatelessWidget {
  const _NavSideItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final DashboardNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Elevated center action button that floats above the navbar bar.
class _CenterActionButton extends StatelessWidget {
  const _CenterActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Gradient gradient;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: isSelected ? 0.65 : 0.40,
                    ),
                    blurRadius: isSelected ? 24 : 16,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: isSelected
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      )
                    : null,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
