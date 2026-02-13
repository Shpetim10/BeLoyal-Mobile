import 'package:flutter/material.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/utils/responsive.dart';

/// Shared premium background shell for all auth screens.
/// Provides responsive centering, gradient background, and subtle pattern.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.bgDark,
                    const Color(0xFF0F1A2E),
                    const Color(0xFF162544),
                  ]
                : [
                    AppColors.bgLight,
                    const Color(0xFFEEF2FF),
                    const Color(0xFFE0E7FF),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative orbs ──
            Positioned(
              top: -80,
              right: -60,
              child: _Orb(
                size: 260,
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.08 : 0.06,
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: _Orb(
                size: 320,
                color: AppColors.accent.withValues(alpha: isDark ? 0.06 : 0.04),
              ),
            ),

            // ── Content ──
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.authMaxWidth(context),
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
