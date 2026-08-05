import 'package:flutter/material.dart';

/// Brand + semantic color roles for BoloBill, extracted from the screens
/// mockups (bolobill-screens-*.html). Material's [ColorScheme] doesn't have
/// slots for roles like "tint" or "textSoft", so these are carried as a
/// [ThemeExtension] alongside the standard [ColorScheme] and looked up via
/// `Theme.of(context).extension<AppColorTokens>()!`.
///
/// Dark theme is a distinct, hand-tuned token set — not a computed inversion
/// of light. In particular the dark "accent" role is the brightened ember
/// (#E08A52), never the light-mode Arsenic (#4D2308) directly.
@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.primary,
    required this.accent,
    required this.accentGradientEnd,
    required this.secondary,
    required this.tint,
    required this.surface,
    required this.surfaceAlt,
    required this.scaffoldBackground,
    required this.text,
    required this.textSoft,
    required this.alert,
    required this.alertSoft,
    required this.success,
    required this.successSoft,
    required this.cardBorder,
    required this.divider,
    required this.appBarBackground,
    required this.appBarForeground,
  });

  /// Liver Chestnut #55443A — app bar, headers, primary CTAs, confirmed states.
  final Color primary;

  /// The "deep accent" role: Arsenic (#4D2308) in light theme, brightened
  /// ember (#E08A52) in dark theme. Mic button, Jama Karain total, keypad
  /// digits, active chips/toggles.
  final Color accent;

  /// Gradient end color for the mic FAB's radial gradient.
  final Color accentGradientEnd;

  /// Morning Blue #8A9992 — secondary highlights, captions, muted elements.
  final Color secondary;

  /// Almond Light #CFD0CD — chip backgrounds, dashed "add" borders.
  final Color tint;

  /// Card/input/screen surface color.
  final Color surface;

  /// Secondary surface (e.g. inline info rows on top of [surface]).
  final Color surfaceAlt;

  /// Root scaffold background, sits behind [surface] cards.
  final Color scaffoldBackground;

  final Color text;
  final Color textSoft;

  /// Signal Red (functional) #B23A2E — overdue khata, destructive actions.
  /// Deliberately identical in both themes (SRS §11.2): red/green cues must
  /// stay universally recognizable, not diluted for brand consistency.
  final Color alert;
  final Color alertSoft;

  /// Muted Green (functional) #5C7A5A — payment received, sync complete.
  final Color success;
  final Color successSoft;

  final Color cardBorder;
  final Color divider;

  final Color appBarBackground;
  final Color appBarForeground;

  static const light = AppColorTokens(
    primary: Color(0xFF55443A),
    accent: Color(0xFF4D2308),
    accentGradientEnd: Color(0xFF6A4A2E),
    secondary: Color(0xFF8A9992),
    tint: Color(0xFFCFD0CD),
    surface: Color(0xFFFBF9F6),
    surfaceAlt: Color(0xFFF1EEE9),
    scaffoldBackground: Color(0xFFEFEBE4),
    text: Color(0xFF3A2A22),
    textSoft: Color(0xFF7C6F66),
    alert: Color(0xFFB23A2E),
    alertSoft: Color(0xFFF3D9D5),
    success: Color(0xFF5C7A5A),
    successSoft: Color(0xFFDCE5DA),
    cardBorder: Color(0xFFE9E4DB),
    divider: Color(0xFFEEE9E1),
    appBarBackground: Color(0xFF55443A),
    appBarForeground: Color(0xFFFFFFFF),
  );

  static const dark = AppColorTokens(
    primary: Color(0xFF55443A),
    accent: Color(0xFFE08A52),
    accentGradientEnd: Color(0xFFB85A2E),
    secondary: Color(0xFF8A9992),
    tint: Color(0xFF3E332B),
    surface: Color(0xFF2A211C),
    surfaceAlt: Color(0xFF3E332B),
    scaffoldBackground: Color(0xFF201810),
    text: Color(0xFFF1ECE5),
    textSoft: Color(0xFFB8ADA3),
    alert: Color(0xFFB23A2E),
    alertSoft: Color(0xFF4A2C27),
    success: Color(0xFF5C7A5A),
    successSoft: Color(0xFF2B3A2E),
    cardBorder: Color(0xFF3E332B),
    divider: Color(0xFF3E332B),
    appBarBackground: Color(0xFF3A2C22),
    appBarForeground: Color(0xFFF1ECE5),
  );

  @override
  AppColorTokens copyWith({
    Color? primary,
    Color? accent,
    Color? accentGradientEnd,
    Color? secondary,
    Color? tint,
    Color? surface,
    Color? surfaceAlt,
    Color? scaffoldBackground,
    Color? text,
    Color? textSoft,
    Color? alert,
    Color? alertSoft,
    Color? success,
    Color? successSoft,
    Color? cardBorder,
    Color? divider,
    Color? appBarBackground,
    Color? appBarForeground,
  }) {
    return AppColorTokens(
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      accentGradientEnd: accentGradientEnd ?? this.accentGradientEnd,
      secondary: secondary ?? this.secondary,
      tint: tint ?? this.tint,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      text: text ?? this.text,
      textSoft: textSoft ?? this.textSoft,
      alert: alert ?? this.alert,
      alertSoft: alertSoft ?? this.alertSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      cardBorder: cardBorder ?? this.cardBorder,
      divider: divider ?? this.divider,
      appBarBackground: appBarBackground ?? this.appBarBackground,
      appBarForeground: appBarForeground ?? this.appBarForeground,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    return AppColorTokens(
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentGradientEnd: Color.lerp(accentGradientEnd, other.accentGradientEnd, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tint: Color.lerp(tint, other.tint, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      scaffoldBackground: Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSoft: Color.lerp(textSoft, other.textSoft, t)!,
      alert: Color.lerp(alert, other.alert, t)!,
      alertSoft: Color.lerp(alertSoft, other.alertSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      appBarBackground: Color.lerp(appBarBackground, other.appBarBackground, t)!,
      appBarForeground: Color.lerp(appBarForeground, other.appBarForeground, t)!,
    );
  }
}
