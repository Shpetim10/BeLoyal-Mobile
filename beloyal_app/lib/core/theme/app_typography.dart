import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './app_colors.dart';

/// BesaHub typography system.
/// Display / Headlines: Outfit (geometric, premium feel)
/// Body / UI labels:    DM Sans (clean, readable)
/// Data / Codes:        DM Mono (coin balances, codes, numbers)
abstract final class AppTypography {
  // ── Font family helpers ───────────────────────────────────────────────────

  /// Outfit — brand display font. Use for headlines, hero text, tier names.
  static TextStyle outfit({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 0,
    double? height,
    Color? color,
    FontStyle fontStyle = FontStyle.normal,
  }) => GoogleFonts.outfit(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
    color: color,
    fontStyle: fontStyle,
  );

  /// DM Sans — UI body font. Use for labels, body copy, nav items.
  static TextStyle dmSans({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double letterSpacing = 0,
    double? height,
    Color? color,
  }) => GoogleFonts.dmSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
    color: color,
  );

  /// DM Mono — data font. Use for coin balances, codes, IDs, timestamps.
  static TextStyle dmMono({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double letterSpacing = 0,
    Color? color,
  }) => GoogleFonts.dmMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    color: color,
  );

  // ── Full Material TextTheme ───────────────────────────────────────────────

  static TextTheme textTheme(Brightness brightness) {
    final color = brightness == Brightness.dark
        ? AppColors.textOnDark
        : AppColors.textOnLight;

    final subColor = brightness == Brightness.dark
        ? AppColors.textSubDark
        : AppColors.textSubLight;

    return TextTheme(
      // Display — Outfit, hero moments
      displayLarge: GoogleFonts.outfit(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        color: color,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: color,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: color,
      ),

      // Headlines — Outfit, section headers
      headlineLarge: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: color,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: color,
      ),

      // Titles — DM Sans, card/list titles
      titleLarge: GoogleFonts.dmSans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      ),

      // Body — DM Sans, readable paragraphs
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: color,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: color,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: subColor,
      ),

      // Labels — DM Sans, chips, badges, nav
      labelLarge: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: color,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: color,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: subColor,
      ),
    );
  }

  // ── Convenience styles (use directly in widgets) ──────────────────────────

  /// Coin balance display (large monospace number)
  static TextStyle coinBalance({Color color = AppColors.textOnDark}) =>
      GoogleFonts.dmMono(
        fontSize: 38,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.8,
        color: color,
      );

  /// Loyalty code / transaction ID
  static TextStyle loyaltyCode({Color color = AppColors.textOnDark}) =>
      GoogleFonts.dmMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.8,
        color: color,
      );

  /// Overline / eyebrow label (e.g. "TOTAL BESACOINS")
  static TextStyle overline({Color? color}) => GoogleFonts.dmSans(
    fontSize: 9,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.8,
    color: color,
  );

  /// Tier name (e.g. "Rose Crystal")
  static TextStyle tierName({Color? color}) => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: color,
  );

  /// Card holder name (italic serif feel via Outfit italic)
  static TextStyle cardholderName({Color color = AppColors.textOnDark}) =>
      GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        letterSpacing: 0.3,
        color: color,
      );

  /// Business name on grid card
  static TextStyle bizName({Color? color}) => GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: color,
  );

  /// Small metadata (distance, category)
  static TextStyle meta({Color? color}) => GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: color,
  );
}
