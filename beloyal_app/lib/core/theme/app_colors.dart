import 'package:flutter/material.dart';

/// BesaHub "Reward Gold" palette — premium, loyalty, trust.
abstract final class AppColors {
  static const primary = Color(0xFF2563EB); // Royal Blue
  static const primaryLight = Color(0xFF60A5FA);
  static const primaryDark = Color(0xFF1D4ED8);

  static const secondary = Color(0xFF22C55E); // Green (success/progress)
  static const secondaryLight = Color(0xFF4ADE80);

  static const accent = Color(0xFFF59E0B); // Gold / Amber (rewards)
  static const accentLight = Color(0xFFFBBF24);
  static const bgDark = Color(0xFF0B1220); // Deep Navy
  static const bgLight = Color(0xFFF8FAFC);
  static const surfaceDark = Color(0xFF111827);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const textOnDark = Color(0xFFE5E7EB);
  static const textOnLight = Color(0xFF0F172A);
  static const textMuted = Color(0xFF94A3B8);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFCA5A5);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);
  static const glassWhite = Color(0x1AFFFFFF); // 10 %
  static const glassBorder = Color(0x33FFFFFF); // 20 %
  static const glassDarkBg = Color(0x33111827); // 20 %
  static const primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [accent, Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const bgDarkGradient = LinearGradient(
    colors: [bgDark, Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
