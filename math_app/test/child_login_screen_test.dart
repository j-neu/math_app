import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math_app/screens/child_login_screen.dart';
import 'package:math_app/services/student_auth_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  StudentAuthService serviceReturningRoster() => StudentAuthService(
        client: MockClient((req) async {
          if (req.url.path.endsWith('roster')) {
            return http.Response(
              jsonEncode({
                'class_id': 'c1',
                'require_pin': false,
                'students': [
                  {'id': 's1', 'display_name': 'Mia', 'avatar': 'fuchs'},
                  {'id': 's2', 'display_name': 'Jonas', 'avatar': 'eule'},
                ],
              }),
              200,
            );
          }
          return http.Response(
              jsonEncode({'token': 't', 'student_id': 's1', 'display_name': 'Mia'}), 200);
        }),
      );

  testWidgets('asks for the class code in German', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChildLoginScreen(schoolSlug: 'lindenschule', authService: serviceReturningRoster()),
    ));
    expect(find.text('Klassencode'), findsOneWidget);
    // Note: brief's original assertion `find.textContaining('code')` findsNothing
    // is deliberately dropped per controller ruling R3 — 'Klassencode' itself
    // contains the substring 'code', so that assertion could never pass.
  });

  testWidgets('shows the roster after a valid code', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChildLoginScreen(schoolSlug: 'lindenschule', authService: serviceReturningRoster()),
    ));

    await tester.enterText(find.byType(TextField), '7K2M');
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    expect(find.text('Wer bist du?'), findsOneWidget);
    expect(find.text('Mia'), findsOneWidget);
    expect(find.text('Jonas'), findsOneWidget);
  });

  testWidgets('a wrong code shows a friendly German message', (tester) async {
    final failing = StudentAuthService(
      client: MockClient((req) async =>
          http.Response(jsonEncode({'error': 'Code nicht gefunden'}), 404)),
    );

    await tester.pumpWidget(MaterialApp(
      home: ChildLoginScreen(schoolSlug: 'lindenschule', authService: failing),
    ));

    await tester.enterText(find.byType(TextField), 'ZZZZ');
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    expect(find.text('Code nicht gefunden'), findsOneWidget);
  });

  testWidgets('name buttons are at least 44 logical pixels tall', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChildLoginScreen(schoolSlug: 'lindenschule', authService: serviceReturningRoster()),
    ));
    await tester.enterText(find.byType(TextField), '7K2M');
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    final size = tester.getSize(find.ancestor(
      of: find.text('Mia'),
      matching: find.byType(InkWell),
    ).first);
    expect(size.height, greaterThanOrEqualTo(44.0));
  });

  testWidgets('a successful login shows a warm German confirmation, not a dead end',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChildLoginScreen(schoolSlug: 'lindenschule', authService: serviceReturningRoster()),
    ));

    await tester.enterText(find.byType(TextField), '7K2M');
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mia'));
    await tester.pumpAndSettle();

    expect(find.text('Hallo Mia!'), findsOneWidget);
    // No dead end: pumpAndSettle must terminate (no dangling spinner/timer)
    // and the widget tree must still be present.
    expect(find.byType(ChildLoginScreen), findsOneWidget);
  });

  testWidgets('roster step has a way back to the code step', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChildLoginScreen(schoolSlug: 'lindenschule', authService: serviceReturningRoster()),
    ));

    await tester.enterText(find.byType(TextField), '7K2M');
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    expect(find.text('Wer bist du?'), findsOneWidget);
    expect(find.text('Zurück'), findsOneWidget);

    await tester.tap(find.text('Zurück'));
    await tester.pumpAndSettle();

    expect(find.text('Klassencode'), findsOneWidget);
  });
}
