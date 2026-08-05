import 'package:flutter/material.dart';

import 'app_color_tokens.dart';
import 'app_radii.dart';
import 'app_typography.dart';

/// The app's two first-class themes. Dark is a deliberately distinct token
/// set (see [AppColorTokens.dark]), not a computed inversion of light.
abstract final class AppTheme {
  static ThemeData light = _build(AppColorTokens.light, Brightness.light);
  static ThemeData dark = _build(AppColorTokens.dark, Brightness.dark);

  static ThemeData _build(AppColorTokens tokens, Brightness brightness) {
    final textTheme = buildAppTextTheme(
      textColor: tokens.text,
      textSoftColor: tokens.textSoft,
    );

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.primary,
      onPrimary: tokens.appBarForeground,
      secondary: tokens.secondary,
      onSecondary: tokens.text,
      error: tokens.alert,
      onError: Colors.white,
      surface: tokens.surface,
      onSurface: tokens.text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.scaffoldBackground,
      fontFamily: AppFontFamily.latin,
      fontFamilyFallback: AppFontFamily.fallback,
      textTheme: textTheme,
      extensions: [tokens, AppTypographyTokens.standard],
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.appBarBackground,
        foregroundColor: tokens.appBarForeground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypographyTokens.standard.bodyEmphasis.copyWith(
          color: tokens.appBarForeground,
          fontSize: 17,
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: tokens.cardBorder, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(color: tokens.divider, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: brightness == Brightness.dark ? tokens.scaffoldBackground : Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          textStyle: AppTypographyTokens.standard.buttonLabel,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.text,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: tokens.secondary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          textStyle: AppTypographyTokens.standard.buttonLabel,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: tokens.cardBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: tokens.cardBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: tokens.accent, width: 2),
        ),
      ),
      iconTheme: IconThemeData(color: tokens.accent),
    );
  }
}
