import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/main.dart';

void main() {
  testWidgets('app boots to the profile selection screen',
      (WidgetTester tester) async {
    // The app's root route (go_router '/') is UserSelectionScreen — not the
    // default Flutter counter — so the smoke test asserts that first screen
    // renders with empty local storage.
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Wer lernt heute?'), findsOneWidget);
    expect(find.text('Noch keine Profile'), findsOneWidget);
  });
}
