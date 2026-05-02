import 'package:flutter/material.dart';
import './app_colors.dart';
import './app_typography.dart';

/// Fully custom Material 3 theme for BesaHub.
/// Palette: Crystal Violet primary · Magenta Bloom secondary · Aura Teal accent
/// Typography: Outfit (display) + DM Sans (body) + DM Mono (data)
abstract final class AppTheme {
  // ── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final textTheme = AppTypography.textTheme(Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryDeep,
        onPrimaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF3D1040),
        onSecondaryContainer: AppColors.secondaryLight,
        tertiary: AppColors.accent,
        onTertiary: AppColors.bgDark,
        tertiaryContainer: Color(0xFF003344),
        onTertiaryContainer: AppColors.accentLight,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textOnDark,
        surfaceContainerHighest: AppColors.highDark,
        surfaceContainerHigh: AppColors.elevDark,
        surfaceContainer: AppColors.cardDark,
        onSurfaceVariant: AppColors.textSubDark,
        outline: AppColors.glassBorder,
        outlineVariant: AppColors.glassWhite,
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: Color(0xFF4A1010),
        onErrorContainer: AppColors.errorLight,
        shadow: Colors.black,
        scrim: Color(0xB809080F),
      ),
      textTheme: textTheme,
      inputDecorationTheme: _inputTheme(Brightness.dark),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      checkboxTheme: _checkboxTheme(),
      chipTheme: _chipTheme(Brightness.dark),
      cardTheme: _cardTheme(Brightness.dark),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Color(0xDD0F0D1A), // navBg dark
        indicatorColor: AppColors.glassAccent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.textMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 0.2,
            );
          }
          return AppTypography.dmSans(
            fontSize: 11,
            color: AppColors.textMuted,
            letterSpacing: 0.2,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.elevDark,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textOnDark),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: AppTypography.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textOnDark,
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnDark),
      ),
    );
  }

  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get light {
    final textTheme = AppTypography.textTheme(Brightness.light);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFEDE0FA),
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFFFD6EE),
        onSecondaryContainer: AppColors.secondaryDark,
        tertiary: AppColors.accentDark,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFCCF4FF),
        onTertiaryContainer: Color(0xFF004455),
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textOnLight,
        surfaceContainerHighest: AppColors.highLight,
        surfaceContainerHigh: AppColors.elevLight,
        surfaceContainer: AppColors.cardLight,
        onSurfaceVariant: AppColors.textSubLight,
        outline: Color(0x28501090),
        outlineVariant: Color(0x14501090),
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: Color(0xFFFFE4E4),
        onErrorContainer: Color(0xFF7A0000),
        shadow: Color(0xFF501090),
        scrim: Color(0x85140D2B),
      ),
      textTheme: textTheme,
      inputDecorationTheme: _inputTheme(Brightness.light),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      checkboxTheme: _checkboxTheme(),
      chipTheme: _chipTheme(Brightness.light),
      cardTheme: _cardTheme(Brightness.light),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Color(0xEEFFFFFF),
        indicatorColor: Color(0x19501090),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return IconThemeData(color: AppColors.textMutedLight);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 0.2,
            );
          }
          return AppTypography.dmSans(
            fontSize: 11,
            color: AppColors.textMutedLight,
            letterSpacing: 0.2,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
        elevation: 2,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x14501090),
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textOnLight),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: AppTypography.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textOnLight,
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnLight),
      ),
    );
  }

  // ── Shared component themes ────────────────────────────────────────────────

  static InputDecorationTheme _inputTheme(Brightness b) {
    final isDark = b == Brightness.dark;
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? AppColors.cardDark.withValues(alpha: 0.7)
          : AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppColors.glassBorder : const Color(0xFFE2DAEF),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppColors.glassBorder : const Color(0xFFDDD5EF),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: TextStyle(
        color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
        fontFamily: 'DMSans',
      ),
      hintStyle: TextStyle(
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        fontFamily: 'DMSans',
      ),
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme() =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme() =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTypography.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  static TextButtonThemeData _textButtonTheme() => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: AppTypography.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static CheckboxThemeData _checkboxTheme() => CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.primary;
      return Colors.transparent;
    }),
    checkColor: const WidgetStatePropertyAll(Colors.white),
    side: const BorderSide(color: AppColors.textMuted, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
  );

  static ChipThemeData _chipTheme(Brightness b) {
    final isDark = b == Brightness.dark;
    return ChipThemeData(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      selectedColor: AppColors.glassAccent,
      disabledColor: isDark
          ? AppColors.glassWhite
          : AppColors.cardLight.withValues(alpha: 0.5),
      labelStyle: AppTypography.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.glassBorder : const Color(0xFFDDD5EF),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  static CardThemeData _cardTheme(Brightness b) {
    final isDark = b == Brightness.dark;
    return CardThemeData(
      color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? AppColors.glassBorder : const Color(0x14501090),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
    );
  }
}
