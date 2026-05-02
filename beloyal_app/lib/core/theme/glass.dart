import 'dart:ui';
import 'package:flutter/material.dart';
import './app_colors.dart';

/// BesaHub premium glassmorphism card.
/// Backdrop blur + amethyst/magenta border gradient + layered micro-shadow.
///
/// Usage:
///   GlassCard(child: MyWidget())
///   GlassCard.accent(child: MyWidget())   // amethyst tint
///   GlassCard.coin(child: MyWidget())     // gold tint (BesaCoin context)
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.blur = 20,
    this.padding,
    this.tintColor,
    this.borderColor,
    this.glowColor,
  });

  /// Standard neutral glass card
  const GlassCard.neutral({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 16,
    this.padding,
  }) : tintColor = null,
       borderColor = null,
       glowColor = null;

  /// Amethyst-tinted card — use for featured/highlighted content
  const GlassCard.accent({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 20,
    this.padding,
  }) : tintColor = AppColors.glassAccent,
       borderColor = const Color(0x339B5DE5),
       glowColor = const Color(0x1A9B5DE5);

  /// Magenta-tinted card — use for offers, promotions
  const GlassCard.bloom({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 20,
    this.padding,
  }) : tintColor = _glassMagentaSoft,
       borderColor = const Color(0x33F15BB5),
       glowColor = const Color(0x1AF15BB5);

  /// Gold-tinted card — use for BesaCoin / rewards context
  const GlassCard.coin({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 20,
    this.padding,
  }) : tintColor = _glassCoinSoft,
       borderColor = const Color(0x33E8C96A),
       glowColor = const Color(0x1AE8C96A);

  /// Teal-tinted card — use for tier/level-up moments
  const GlassCard.aura({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 20,
    this.padding,
  }) : tintColor = _glassTealSoft,
       borderColor = const Color(0x3300D4FF),
       glowColor = const Color(0x1400D4FF);

  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final Color? tintColor;
  final Color? borderColor;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resolvedBorderColor =
        borderColor ??
        (isDark ? AppColors.glassBorder : const Color(0x14501090));

    final resolvedTint =
        tintColor ??
        (isDark ? AppColors.glassWhite : Colors.white.withValues(alpha: 0.82));

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            // Base shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            // Brand glow (dark only, or when tinted)
            if (isDark || glowColor != null)
              BoxShadow(
                color:
                    glowColor ??
                    AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.04),
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
                color: resolvedTint,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: resolvedBorderColor, width: 1.5),
              ),
              padding:
                  padding ??
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Soft glass colors not part of AppColors ────────────────────────────────
const Color _glassMagentaSoft = Color(0x1AF15BB5);
const Color _glassCoinSoft = Color(0x1AE8C96A);
const Color _glassTealSoft = Color(0x1400D4FF);
