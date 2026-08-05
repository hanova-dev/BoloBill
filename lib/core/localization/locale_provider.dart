import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_locale.dart';

/// The shop's active language. Defaults to Urdu — SRS §8.2.1 defines the
/// `shops.preferred_language` column's default as 'ur', and this mirrors
/// that for the pre-onboarding/placeholder state. Once a shop profile
/// exists, this provider is driven by that persisted value instead.
final localeProvider = StateProvider<AppLocale>((ref) => AppLocale.urdu);
