import 'package:flutter/material.dart';

/// BesaHub brand palette — Premium Crystal Violet / Magenta / Void.
/// Matches the BesaHub design system: deep space backgrounds,
/// electric amethyst primary, magenta bloom secondary, aura teal accent.
abstract final class AppColors {
  // ── Primary: Crystal Violet ──────────────────────────────────────────────
  static const primary = Color(0xFF9B5DE5); // Electric amethyst
  static const primaryLight = Color(0xFFC29AF0); // Lavender tint
  static const primaryDark = Color(0xFF6B3FA0); // Deep violet
  static const primaryDeep = Color(0xFF3D2580); // Void violet

  // ── Secondary: Magenta Bloom ─────────────────────────────────────────────
  static const secondary = Color(0xFFF15BB5); // Bloom magenta
  static const secondaryLight = Color(0xFFF79DD1); // Soft pink
  static const secondaryDark = Color(0xFFBF3A8A); // Deep magenta

  // ── Accent: Aura Teal ────────────────────────────────────────────────────
  static const accent = Color(0xFF00D4FF); // Crystal teal
  static const accentLight = Color(0xFF7DE8FF); // Ice teal
  static const accentDark = Color(0xFF0099BB); // Deep teal (light mode)

  // ── BesaCoin Gold ────────────────────────────────────────────────────────
  static const gold = Color(0xFFE8C96A); // BesaCoin gold (dark mode)
  static const goldLight = Color(0xFFF5E199); // Highlight gold
  static const goldDark = Color(0xFF9A720F); // BesaCoin gold (light mode)

  // ── Backgrounds — Dark ───────────────────────────────────────────────────
  static const bgDark = Color(0xFF09080F); // Void black
  static const surfaceDark = Color(0xFF0F0D1A); // Deep surface
  static const cardDark = Color(0xFF181426); // Card background
  static const elevDark = Color(0xFF221E35); // Elevated card
  static const highDark = Color(0xFF2A2340); // Highest surface

  // ── Backgrounds — Light ──────────────────────────────────────────────────
  static const bgLight = Color(0xFFF4F1FB); // Warm lavender white
  static const surfaceLight = Color(0xFFFFFFFF); // Pure white
  static const cardLight = Color(0xFFEDE8F8); // Card tint
  static const elevLight = Color(0xFFE2DAEF); // Elevated card
  static const highLight = Color(0xFFD4C9EA); // Highest surface

  // ── Text — Dark mode ─────────────────────────────────────────────────────
  static const textOnDark = Color(0xFFFAF8FF); // Frost white
  static const textSubDark = Color(0x8DFAF8FF); // 55% frost
  static const textMutedDark = Color(0x52FAF8FF); // 32% frost
  static const textMuted = Color(0x52FAF8FF); // alias

  // ── Text — Light mode ────────────────────────────────────────────────────
  static const textOnLight = Color(0xFF140D2B); // Deep ink
  static const textSubLight = Color(0x8D140D2B); // 55% ink
  static const textMutedLight = Color(0x54140D2B); // 33% ink

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFCA5A5);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);
  static const success = Color(0xFF22C55E);

  // ── Glass / Blur surfaces ────────────────────────────────────────────────
  static const glassWhite = Color(0x0FFAF8FF); // ~6% frost — dark cards
  static const glassBorder = Color(0x14FAF8FF); // ~8% frost border
  static const glassBorderStrong = Color(0x24FAF8FF); // ~14% frost
  static const glassAccent = Color(0x1F9B5DE5); // ~12% amethyst
  static const glassDarkBg = Color(0x33221E35); // elevated glass bg

  // ── Gradients ────────────────────────────────────────────────────────────
  static const primaryGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const crystalGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const auroraGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const coinGradient = LinearGradient(
    colors: [goldLight, gold, Color(0xFFA07820)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardGradient = LinearGradient(
    colors: [Color(0xFF1A0935), Color(0xFF2D1060), primary, secondary],
    stops: [0.0, 0.3, 0.7, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const bgDarkGradient = LinearGradient(
    colors: [bgDark, Color(0xFF0F0D1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const bgLightGradient = LinearGradient(
    colors: [bgLight, Color(0xFFE8E1F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static get magentaSoft => null;

  // ── Coupon Status Colors ─────────────────────────────────────────────────
  static const couponStatusDraft = Color(0xFF6B7280);    // neutral gray
  static const couponStatusActive = Color(0xFF22C55E);   // success green
  static const couponStatusPaused = Color(0xFFF59E0B);   // warning amber
  static const couponStatusExpired = Color(0xFFEF4444);  // danger red
  static const couponStatusArchived = Color(0xFF64748B); // slate/muted

  // ── Coupon Type Colors ───────────────────────────────────────────────────
  static const couponTypeFreeProduct = Color(0xFF3B82F6);    // brand blue
  static const couponTypePercentage = Color(0xFF8B5CF6);     // violet/indigo
  static const couponTypeFixedAmount = Color(0xFF14B8A6);    // teal

  // ── Coupon Visibility Colors ─────────────────────────────────────────────
  static const couponVisibilityPublic = Color(0xFF22C55E);   // green
  static const couponVisibilityHidden = Color(0xFF6B7280);   // gray
}
