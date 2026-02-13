import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';

/// Animated status banner for error/warning/info messages at the top of forms.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.type = StatusBannerType.error,
    this.onDismiss,
  });

  final String message;
  final StatusBannerType type;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final (bgColor, iconData, iconColor) = switch (type) {
      StatusBannerType.error => (
        AppColors.error.withValues(alpha: 0.12),
        Icons.error_outline_rounded,
        AppColors.error,
      ),
      StatusBannerType.warning => (
        AppColors.warning.withValues(alpha: 0.12),
        Icons.warning_amber_rounded,
        AppColors.warning,
      ),
      StatusBannerType.info => (
        AppColors.info.withValues(alpha: 0.12),
        Icons.info_outline_rounded,
        AppColors.info,
      ),
      StatusBannerType.success => (
        AppColors.secondary.withValues(alpha: 0.12),
        Icons.check_circle_outline_rounded,
        AppColors.secondary,
      ),
    };

    return Animate(
      effects: const [
        FadeEffect(duration: Duration(milliseconds: 300)),
        SlideEffect(
          begin: Offset(0, -0.2),
          end: Offset.zero,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ),
      ],
      child: Semantics(
        liveRegion: true,
        label: '${type.name}: $message',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: iconColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(iconData, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(Icons.close_rounded, size: 18, color: iconColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum StatusBannerType { error, warning, info, success }
