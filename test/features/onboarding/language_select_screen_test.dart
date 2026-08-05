import 'package:bolobill/core/localization/app_locale.dart';
import 'package:bolobill/core/localization/generated/app_localizations.dart';
import 'package:bolobill/core/localization/locale_provider.dart';
import 'package:bolobill/core/theme/app_theme.dart';
import 'package:bolobill/features/onboarding/presentation/language_select_screen.dart';
import 'package:bolobill/features/onboarding/presentation/sign_up_method_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping a language chip sets the locale and advances to E1', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Mirrors app.dart's real wiring: MaterialApp's `locale` is driven by
    // localeProvider, not the test environment's default — otherwise this
    // test would be checking Flutter's default locale resolution instead
    // of the app's actual locale-switching behavior.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: ref.watch(localeProvider).locale,
            home: const LanguageSelectScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Default locale is Urdu (SRS §8.2.1 shops.preferred_language default
    // 'ur'), so the chip is initially labeled in Urdu script, not English.
    expect(container.read(localeProvider), AppLocale.urdu);

    await tester.tap(find.text('انگریزی')); // "English" in Urdu
    await tester.pumpAndSettle();

    expect(container.read(localeProvider), AppLocale.english);
    expect(find.byType(SignUpMethodScreen), findsOneWidget);
  });
}
