import 'package:bolobill/core/localization/generated/app_localizations.dart';
import 'package:bolobill/core/theme/app_theme.dart';
import 'package:bolobill/domain/entities/enums.dart';
import 'package:bolobill/features/onboarding/application/onboarding_controller.dart';
import 'package:bolobill/features/onboarding/presentation/business_type_screen.dart';
import 'package:bolobill/features/onboarding/presentation/shop_name_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// theme: AppTheme.light is required here — the real app always sets this via
// app.dart, and every shared widget (IconTile, BoloChip, ...) unconditionally
// reads `Theme.of(context).extension<AppColorTokens>()!`. Omitting it makes
// that null-check throw, not a representative test of app behavior.
Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  testWidgets('all 6 business-type tiles render, Continue disabled until one is selected',
      (tester) async {
    await tester.pumpWidget(_wrap(const BusinessTypeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Grocery'), findsOneWidget);
    expect(find.text('Tea Stall'), findsOneWidget);
    expect(find.text('Vegetable Cart'), findsOneWidget);
    expect(find.text('Tailor'), findsOneWidget);
    expect(find.text('Bakery'), findsOneWidget);
    expect(find.text('General Store'), findsOneWidget);

    final continueButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(continueButton.onPressed, isNull);
  });

  testWidgets('selecting a tile enables Continue and navigates to A4 with the choice recorded',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const BusinessTypeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tea Stall'));
    await tester.pump();

    final continueButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(continueButton.onPressed, isNotNull);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.byType(ShopNameScreen), findsOneWidget);
    expect(container.read(onboardingControllerProvider).businessType, BusinessType.teaStall);
  });
}
