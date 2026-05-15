import 'package:flutter/material.dart';
import 'package:besahub_app/core/theme/app_colors.dart';

/// Frosted-glass stat card used on dashboard home tabs.
/// Displays an [icon], a large [value], a [label], and an optional [subtitle].
/// Optionally shows a [trend] label (e.g. "+12%") and [trendUp] color tint.
/// Optionally applies an [accentGradient] top border.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.subtitle,
    this.trend,
    this.trendUp,
    this.accentGradient,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final String? subtitle;
  final String? trend;
  final bool? trendUp;
  final Gradient? accentGradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final isCompact = h < 110;
        final iconSize = isCompact ? 18.0 : 22.0;
        final badgeSize = isCompact ? 32.0 : 40.0;
        final gap = isCompact ? 6.0 : 10.0;
        final valueFontSize = isCompact ? 18.0 : 22.0;
        final labelFontSize = isCompact ? 11.0 : 12.0;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Subtle top-accent bar
                if (accentGradient != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: accentGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: badgeSize,
                          height: badgeSize,
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: iconColor, size: iconSize),
                        ),
                        const Spacer(),
                        if (trend != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (trendUp == true
                                      ? AppColors.success
                                      : AppColors.error)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  trendUp == true
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  size: 10,
                                  color: trendUp == true
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  trend!,
                                  style: TextStyle(
                                    color: trendUp == true
                                        ? AppColors.success
                                        : AppColors.error,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: gap),
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
              ],
            ),
          ),
        );
      },
    );
  }
}
