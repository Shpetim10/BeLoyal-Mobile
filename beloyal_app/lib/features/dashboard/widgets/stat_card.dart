import 'package:flutter/material.dart';
import 'package:besahub_app/core/theme/app_colors.dart';

/// Frosted-glass stat card used as a placeholder widget on dashboard home tabs.
/// Displays an [icon] (tinted [iconColor]), a large [value], a [label], and
/// an optional [subtitle] line.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapt sizing based on available height
        final h = constraints.maxHeight;
        final isCompact = h < 110;
        final iconSize = isCompact ? 18.0 : 22.0;
        final badgeSize = isCompact ? 32.0 : 40.0;
        final gap = isCompact ? 6.0 : 10.0;
        final valueFontSize = isCompact ? 18.0 : 22.0;
        final labelFontSize = isCompact ? 11.0 : 12.0;

        return Container(
          padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Icon badge
              Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: iconSize),
              ),
              SizedBox(height: gap),

              // Value — scales down if too wide
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),

              // Label
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Optional subtitle
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
