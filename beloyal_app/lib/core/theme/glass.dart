import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Premium glassmorphism card with blur, border gradient, and micro-shadow.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.blur = 20,
    this.padding,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            if (isDark)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 60,
                spreadRadius: -8,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.glassWhite
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: isDark
                      ? AppColors.glassBorder
                      : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              padding:
                  padding ??
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
