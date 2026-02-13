import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/auth_user.dart';

/// Premium chip for displaying and selecting a user role.
class RoleChip extends StatelessWidget {
  const RoleChip({
    super.key,
    required this.role,
    this.selected = false,
    this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback? onTap;

  IconData get _icon => switch (role) {
    UserRole.customer => Icons.shopping_bag_outlined,
    UserRole.restaurantAdmin => Icons.storefront_outlined,
    UserRole.staff => Icons.badge_outlined,
    UserRole.platformAdmin => Icons.admin_panel_settings_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: '${role.displayName} role',
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.15)
                : (isDark
                      ? AppColors.surfaceDark.withValues(alpha: 0.5)
                      : AppColors.bgLight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (isDark ? AppColors.glassBorder : const Color(0xFFE2E8F0)),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : (isDark
                            ? AppColors.glassWhite
                            : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _icon,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  role.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.primary : null,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
