// dart:ui (not flutter/material.dart) so this stays importable from
// domain/data code without pulling in the widgets/Material dependency tree —
// shops.preferred_language and customers.preferred_language (SRS §8.2.1/8.2.3)
// reuse this same enum rather than duplicating a second "language" type.
import 'dart:ui' show Locale, TextDirection;

/// The three locales BoloBill supports (SRS §3.6/§10.7), as a closed set —
/// not a generic locale picker, since each one drives specific ASR/TTS model
/// selection and receipt rendering, not just UI strings.
enum AppLocale {
  english(Locale('en'), TextDirection.ltr, 'en'),
  urdu(Locale('ur'), TextDirection.rtl, 'ur'),

  /// Roman Urdu: Urdu language, Latin script — represented with the
  /// standard BCP-47 script subtag (`ur-Latn`) rather than a made-up locale
  /// code, so it interoperates correctly with `intl`/ARB tooling.
  ///
  /// Flutter's default bidi detection keys off language code alone, which
  /// would incorrectly mark this RTL (since 'ur' is normally RTL) — so
  /// direction is looked up from this enum explicitly wherever text
  /// direction is needed, rather than relying on framework defaults.
  romanUrdu(Locale.fromSubtags(languageCode: 'ur', scriptCode: 'Latn'), TextDirection.ltr, 'roman_ur');

  const AppLocale(this.locale, this.textDirection, this.dbCode);

  final Locale locale;
  final TextDirection textDirection;

  /// The literal ENUM value used by shops.preferred_language /
  /// customers.preferred_language per SRS §8.2.1 ('en' / 'ur' / 'roman_ur') —
  /// kept distinct from [locale]'s BCP-47 form so the stored schema matches
  /// the SRS exactly while the in-app locale stays technically correct.
  final String dbCode;

  static const supported = AppLocale.values;

  /// Matches a Flutter [Locale] (as resolved by the framework) back to our
  /// closed enum, falling back to English if unrecognized.
  static AppLocale fromLocale(Locale locale) {
    for (final appLocale in supported) {
      if (appLocale.locale.languageCode == locale.languageCode &&
          appLocale.locale.scriptCode == locale.scriptCode) {
        return appLocale;
      }
    }
    return AppLocale.english;
  }

  static AppLocale fromDbCode(String code) {
    return supported.firstWhere(
      (l) => l.dbCode == code,
      orElse: () => throw ArgumentError.value(code, 'code', 'Unknown language code'),
    );
  }
}
