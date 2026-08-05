import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bolobill/app/app.dart';

void main() {
  testWidgets('App boots to the placeholder screen with the app name shown', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BoloBillApp()));
    await tester.pumpAndSettle();

    expect(find.text('BoloBill'), findsOneWidget);
  });
}
