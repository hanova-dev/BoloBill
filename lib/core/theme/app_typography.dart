import 'package:flutter/material.dart';

/// Font family names as registered in pubspec.yaml.
abstract final class AppFontFamily {
  static const latin = 'Poppins';
  static const numeral = 'SpaceGrotesk';
  static const urdu = 'NotoNastaliqUrdu';

  /// Any text style that might contain Urdu-script glyphs (which is most of
  /// the app, once localized) declares this fallback so Skia's per-glyph
  /// font substitution renders Urdu characters in Noto Nastaliq Urdu
  /// automatically, without the caller having to branch on locale.
  static const fallback = [urdu];
}

/// Text roles that don't map cleanly onto Material's [TextTheme] slots —
/// mirrors the mockup's custom classes (.eyebrow, .amt, .li-amt, etc).
/// Carried as a [ThemeExtension] like [AppColorTokens] so both are looked up
/// the same way: `Theme.of(context).extension<AppTypographyTokens>()!`.
///
/// These styles intentionally omit color — callers compose it from
/// [AppColorTokens] (e.g. `.copyWith(color: tokens.text)`), keeping typography
/// and color as independent, orthogonal concerns.
@immutable
class AppTypographyTokens extends ThemeExtension<AppTypographyTokens> {
  const AppTypographyTokens({
    required this.eyebrow,
    required this.caption,
    required this.body,
    required this.bodyEmphasis,
    required this.buttonLabel,
    required this.screenTitle,
    required this.screenSubtitle,
    required this.amountHero,
    required this.amountLine,
    required this.amountSmall,
  });

  /// Small uppercase tracked label, e.g. "CHOOSE YOUR LANGUAGE".
  final TextStyle eyebrow;

  /// Secondary/meta text, e.g. line-item unit breakdown, timestamps.
  final TextStyle caption;

  /// Primary readable content — item names, list rows. NFR §4.1.3 minimum: 16sp.
  final TextStyle body;
  final TextStyle bodyEmphasis;

  final TextStyle buttonLabel;

  final TextStyle screenTitle;
  final TextStyle screenSubtitle;

  /// The Jama Karain bill total and other hero numerals. NFR §4.1.3: 28sp+.
  /// Uses tabular (monospaced) figures so digits can't be misread at a
  /// glance (e.g. 6 vs 8) — the exact concern called out in SRS §4.1.3.
  final TextStyle amountHero;

  /// Per-line-item amounts (bill list, receipt, ledger rows).
  final TextStyle amountLine;

  /// Small inline amounts (chips, avatars' balance labels).
  final TextStyle amountSmall;

  static const _tabular = [FontFeature.tabularFigures()];

  static const standard = AppTypographyTokens(
    eyebrow: TextStyle(
      fontFamily: AppFontFamily.latin,
      fontFamilyFallback: AppFontFamily.fallback,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
    ),
    caption: TextStyle(
      fontFamily: AppFontFamily.latin,
      fontFamilyFallback: AppFontFamily.fallback,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    body: TextStyle(
      fontFamily: AppFontFamily.latin,
      fontFamilyFallback: AppFontFamily.fallback,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    bodyEmphasis: TextStyle(
      fontFamily: AppFontFamily.latin,
      fontFamilyFallback: AppFontFamily.fallback,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    buttonLabel: TextStyle(
      fontFamily: AppFontFamily.latin,
      fontFamilyFallback: AppFontFamily.fallback,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    screenTitle: TextStyle(
      fontFamily: AppFontFamily.numeral,
      fontFamilyFallback: AppFontFamily.fallback,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
    screenSubtitle: TextStyle(
      fontFamily: AppFontFamily.latin,
      fontFamilyFallback: AppFontFamily.fallback,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    amountHero: TextStyle(
      fontFamily: AppFontFamily.numeral,
      fontFamilyFallback: AppFontFamily.fallback,
      fontSize: 40,
      fontWeight: FontWeight.w700,
      height: 1.1,
      fontFeatures: _tabular,
    ),
    amountLine: TextStyle(
      fontFamily: AppFontFamily.numeral,
      fontFamilyFallback: AppFontFamily.fallback,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      fontFeatures: _tabular,
    ),
    amountSmall: TextStyle(
      fontFamily: AppFontFamily.numeral,
      fontFamilyFallback: AppFontFamily.fallback,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      fontFeatures: _tabular,
    ),
  );

  @override
  AppTypographyTokens copyWith({
    TextStyle? eyebrow,
    TextStyle? caption,
    TextStyle? body,
    TextStyle? bodyEmphasis,
    TextStyle? buttonLabel,
    TextStyle? screenTitle,
    TextStyle? screenSubtitle,
    TextStyle? amountHero,
    TextStyle? amountLine,
    TextStyle? amountSmall,
  }) {
    return AppTypographyTokens(
      eyebrow: eyebrow ?? this.eyebrow,
      caption: caption ?? this.caption,
      body: body ?? this.body,
      bodyEmphasis: bodyEmphasis ?? this.bodyEmphasis,
      buttonLabel: buttonLabel ?? this.buttonLabel,
      screenTitle: screenTitle ?? this.screenTitle,
      screenSubtitle: screenSubtitle ?? this.screenSubtitle,
      amountHero: amountHero ?? this.amountHero,
      amountLine: amountLine ?? this.amountLine,
      amountSmall: amountSmall ?? this.amountSmall,
    );
  }

  @override
  AppTypographyTokens lerp(ThemeExtension<AppTypographyTokens>? other, double t) {
    if (other is! AppTypographyTokens) return this;
    // Text styles don't benefit from interpolation here (family/weight/features
    // don't tween meaningfully) — snap at the midpoint like a discrete theme.
    return t < 0.5 ? this : other;
  }
}

/// Builds the Material [TextTheme] slots BoloBill actually uses, derived
/// from [AppTypographyTokens] plus a text color, so `Theme.of(context).textTheme`
/// stays usable for any Flutter/Material widget that expects it.
TextTheme buildAppTextTheme({required Color textColor, required Color textSoftColor}) {
  final t = AppTypographyTokens.standard;
  return TextTheme(
    titleLarge: t.screenTitle.copyWith(color: textColor),
    titleMedium: t.bodyEmphasis.copyWith(color: textColor),
    bodyLarge: t.body.copyWith(color: textColor),
    bodyMedium: t.body.copyWith(color: textColor, fontSize: 14),
    bodySmall: t.caption.copyWith(color: textSoftColor),
    labelLarge: t.buttonLabel.copyWith(color: textColor),
  );
}
