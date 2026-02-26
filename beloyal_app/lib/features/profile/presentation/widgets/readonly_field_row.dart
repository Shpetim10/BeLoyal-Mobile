import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// A read-only row displaying a label and value with optional lock icon.
/// Used for fields that cannot be edited by the current user (e.g. VAT ID,
/// business status).
class ReadonlyFieldRow extends StatelessWidget {
  const ReadonlyFieldRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.helperText = 'Managed by platform admin',
    this.showHelper = true,
    this.trailing,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String helperText;
  final bool showHelper;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.glassWhite.withValues(alpha: 0.05)
            : AppColors.bgLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.lock_rounded,
            size: 18,
            color: AppColors.textMuted.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (showHelper) ...[
                  const SizedBox(height: 3),
                  Text(
                    helperText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
