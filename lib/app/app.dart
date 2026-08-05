import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/generated/app_localizations.dart';
import '../core/localization/locale_provider.dart';
import '../core/navigation/root_navigator_key.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_provider.dart';
import '../features/onboarding/presentation/language_select_screen.dart';

class BoloBillApp extends ConsumerWidget {
  const BoloBillApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'BoloBill',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: activeLocale.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Flutter's default bidi detection keys off language code alone, which
      // would mark Roman Urdu (ur-Latn) RTL since 'ur' is normally RTL. This
      // explicitly overrides ambient directionality from our closed AppLocale
      // enum instead, per the RTL design decision in the implementation plan.
      builder: (context, child) => Directionality(
        textDirection: activeLocale.textDirection,
        child: child!,
      ),
      home: const LanguageSelectScreen(),
    );
  }
}
