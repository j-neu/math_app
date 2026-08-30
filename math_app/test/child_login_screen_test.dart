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

  // ---- Fix round 1: Bildfolge, empty roster, in-flight state, logout ----

  StudentAuthService serviceWithPin({int loginStatus = 200, String? capturePin}) =>
      StudentAuthService(
        client: MockClient((req) async {
          if (req.url.path.endsWith('roster')) {
            return http.Response(
              jsonEncode({
                'class_id': 'c1',
                'require_pin': true,
                'students': [
                  {'id': 's1', 'display_name': 'Mia', 'avatar': null},
                ],
              }),
              200,
            );
          }
          _lastLoginBody = req.body;
          if (loginStatus != 200) {
            return http.Response(
                jsonEncode({'error': 'Bildfolge stimmt nicht'}), loginStatus);
          }
          return http.Response(
              jsonEncode({'token': 't', 'student_id': 's1', 'display_name': 'Mia'}), 200);
        }),
      );

  Future<void> reachRoster(WidgetTester tester, StudentAuthService service) async {
    await tester.pumpWidget(MaterialApp(
      home: ChildLoginScreen(schoolSlug: 'lindenschule', authService: service),
    ));
    await tester.enterText(find.byType(TextField), '7K2M');
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
  }

  testWidgets('a class without Bildfolge logs in directly, showing no picture step',
      (tester) async {
    await reachRoster(tester, serviceReturningRoster());
    await tester.tap(find.text('Mia'));
    await tester.pumpAndSettle();

    expect(find.text('Deine Bildfolge'), findsNothing);
    expect(find.text('Hallo Mia!'), findsOneWidget);
  });

  testWidgets('a class with Bildfolge asks for four pictures before logging in',
      (tester) async {
    await reachRoster(tester, serviceWithPin());
    await tester.tap(find.text('Mia'));
    await tester.pumpAndSettle();

    // The picture step appears instead of an immediate login.
    expect(find.text('Deine Bildfolge'), findsOneWidget);
    expect(find.text('Hallo Mia!'), findsNothing);

    // Four taps complete the Bildfolge and log the child in.
    for (final symbol in kPinSymbols.take(kPinLength)) {
      await tester.tap(find.byIcon(symbol.icon));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Hallo Mia!'), findsOneWidget);
    expect(_lastLoginBody, contains('stern-herz-blume-sonne'));
  });

  testWidgets('a wrong Bildfolge clears the taps and keeps the child on the step',
      (tester) async {
    await reachRoster(tester, serviceWithPin(loginStatus: 401));
    await tester.tap(find.text('Mia'));
    await tester.pumpAndSettle();

    for (final symbol in kPinSymbols.take(kPinLength)) {
      await tester.tap(find.byIcon(symbol.icon));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Deine Bildfolge'), findsOneWidget);
    expect(find.text('Bildfolge stimmt nicht'), findsOneWidget);
    expect(find.text('Hallo Mia!'), findsNothing);
  });

  testWidgets('an empty class explains itself instead of showing a blank grid',
      (tester) async {
    final emptyClass = StudentAuthService(
      client: MockClient((req) async => http.Response(
            jsonEncode({'class_id': 'c1', 'require_pin': false, 'students': []}),
            200,
          )),
    );
    await reachRoster(tester, emptyClass);

    expect(find.textContaining('noch keine Kinder eingetragen'), findsOneWidget);
    expect(find.text('Zurück'), findsOneWidget);
  });

  testWidgets('going back to the code step clears the stored token', (tester) async {
    await reachRoster(tester, serviceReturningRoster());
    await tester.tap(find.text('Mia'));
    await tester.pumpAndSettle();

    final auth = StudentAuthService(client: MockClient((_) async => http.Response('{}', 200)));
    expect(await auth.storedToken(), isNotNull);

    await tester.tap(find.text('Zurück zur Anmeldung'));
    await tester.pumpAndSettle();

    expect(await auth.storedToken(), isNull);
    expect(find.text('Klassencode'), findsOneWidget);
  });

  testWidgets('long hyphenated names do not overflow their tile at phone width',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final longNames = StudentAuthService(
      client: MockClient((req) async => http.Response(
            jsonEncode({
              'class_id': 'c1',
              'require_pin': false,
              'students': [
                {'id': 's1', 'display_name': 'Charlotte-Sophie', 'avatar': null},
                {'id': 's2', 'display_name': 'Maximilian', 'avatar': null},
                {'id': 's3', 'display_name': 'Franziska', 'avatar': null},
                {'id': 's4', 'display_name': 'Alexander', 'avatar': null},
              ],
            }),
            200,
          )),
    );
    await reachRoster(tester, longNames);

    expect(find.text('Charlotte-Sophie'), findsOneWidget);
    // A RenderFlex overflow reports itself through the error reporter; the
    // absence of exceptions here is the assertion.
    expect(tester.takeException(), isNull);
  });
}

String? _lastLoginBody;
