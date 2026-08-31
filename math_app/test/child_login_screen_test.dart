import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
    // The welcome step hands off to the learning path with a primary action.
    expect(find.text("Los geht's"), findsOneWidget);
    // No dead end: pumpAndSettle must terminate (no dangling spinner/timer)
    // and the widget tree must still be present.
    expect(find.byType(ChildLoginScreen), findsOneWidget);
  });

  testWidgets("after login, 'Los geht's' navigates to /lernpfad", (tester) async {
    final router = GoRouter(
      initialLocation: '/lernen/lindenschule',
      routes: [
        GoRoute(
          path: '/lernen/:slug',
          builder: (context, state) => ChildLoginScreen(
            schoolSlug: state.pathParameters['slug']!,
            authService: serviceReturningRoster(),
          ),
        ),
        GoRoute(
          path: '/lernpfad',
          builder: (_, __) => const Scaffold(body: Text('lernpfad-stub')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.enterText(find.byType(TextField), '7K2M');
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mia'));
    await tester.pumpAndSettle();

    expect(find.text('Hallo Mia!'), findsOneWidget);

    await tester.tap(find.text("Los geht's"));
    await tester.pumpAndSettle();

    expect(find.text('lernpfad-stub'), findsOneWidget);
    expect(find.byType(ChildLoginScreen), findsNothing);
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

  /// Reads the fill colour of the four Bildfolge progress dots, in order,
  /// via the `ValueKey('pin-dot-$i')` on each dot's Container.
  List<Color?> pinDotColors(WidgetTester tester) => [
        for (var i = 0; i < kPinLength; i++)
          (tester.widget<Container>(find.byKey(ValueKey('pin-dot-$i'))).decoration
                  as BoxDecoration)
              .color,
      ];

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
    // The claim in the test name: the four progress dots actually reset to
    // empty, not just "the child didn't get logged in".
    expect(pinDotColors(tester), everyElement(Colors.transparent));
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

  // ---- Fix round 2: two-finger mash on two different names ----

  testWidgets(
      'a two-finger tap on two different names logs in only the first child, exactly once',
      (tester) async {
    var loginCalls = 0;
    final racyService = StudentAuthService(
      client: MockClient((req) async {
        if (req.url.path.endsWith('roster')) {
          return http.Response(
            jsonEncode({
              'class_id': 'c1',
              'require_pin': false,
              'students': [
                {'id': 's1', 'display_name': 'Mia', 'avatar': null},
                {'id': 's2', 'display_name': 'Jonas', 'avatar': null},
              ],
            }),
            200,
          );
        }
        loginCalls++;
        final studentId = jsonDecode(req.body)['student_id'] as String;
        final displayName = studentId == 's1' ? 'Mia' : 'Jonas';
        return http.Response(
          jsonEncode({'token': 't', 'student_id': studentId, 'display_name': displayName}),
          200,
        );
      }),
    );

    await reachRoster(tester, racyService);

    // Two pointer-down events in the same frame, exactly like a child
    // mashing the tablet with two fingers: no pump() between the two taps,
    // so both onTap closures run against the widget tree built while
    // `_busy` was still false.
    await tester.tap(find.text('Mia'));
    await tester.tap(find.text('Jonas'));
    await tester.pumpAndSettle();

    expect(loginCalls, 1);
    expect(find.text('Hallo Mia!'), findsOneWidget);
    expect(find.text('Hallo Jonas!'), findsNothing);
  });

  // ---- Fix round 3: remaining concurrency gaps ("Weiter" and Bildfolge) ----

  testWidgets('a two-finger tap on "Weiter" sends only one roster request', (tester) async {
    var rosterCalls = 0;
    final countingService = StudentAuthService(
      client: MockClient((req) async {
        if (req.url.path.endsWith('roster')) {
          rosterCalls++;
          // A real (fake-clock) delay so the first request is still
          // in flight when the second tap lands: without it, the whole
          // async round trip for this endpoint resolves within a single
          // `tester.tap()` (no SharedPreferences hop after the network
          // call, unlike `login`), so a second, later tap would be a
          // legitimate second request rather than the concurrent one this
          // test means to exercise.
          await Future.delayed(const Duration(milliseconds: 50));
          return http.Response(
            jsonEncode({
              'class_id': 'c1',
              'require_pin': false,
              'students': [
                {'id': 's1', 'display_name': 'Mia', 'avatar': null},
              ],
            }),
            200,
          );
        }
        return http.Response(
            jsonEncode({'token': 't', 'student_id': 's1', 'display_name': 'Mia'}), 200);
      }),
    );

    await tester.pumpWidget(MaterialApp(
      home: ChildLoginScreen(schoolSlug: 'lindenschule', authService: countingService),
    ));
    await tester.enterText(find.byType(TextField), '7K2M');

    // Two pointer-down events on "Weiter" in the same frame: no pump()
    // between the two taps, so both onPressed closures run against the
    // widget tree built while `_busy` was still false, exactly like the
    // two-finger name-tile mash above.
    await tester.tap(find.text('Weiter'));
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    expect(rosterCalls, 1);
  });

  testWidgets(
      'a two-finger tap on two different names opens the Bildfolge for the first child tapped',
      (tester) async {
    final racyPinService = StudentAuthService(
      client: MockClient((req) async {
        if (req.url.path.endsWith('roster')) {
          return http.Response(
            jsonEncode({
              'class_id': 'c1',
              'require_pin': true,
              'students': [
                {'id': 's1', 'display_name': 'Mia', 'avatar': null},
                {'id': 's2', 'display_name': 'Jonas', 'avatar': null},
              ],
            }),
            200,
          );
        }
        return http.Response(
            jsonEncode({'token': 't', 'student_id': 's1', 'display_name': 'Mia'}), 200);
      }),
    );

    await reachRoster(tester, racyPinService);

    // Two pointer-down events in the same frame, same reasoning as above:
    // this branch of `_tapName` never touches `_busy` (no network call yet),
    // so only the synchronous `_navigating` latch can reject the second tap.
    await tester.tap(find.text('Mia'));
    await tester.tap(find.text('Jonas'));
    await tester.pumpAndSettle();

    expect(find.text('Deine Bildfolge'), findsOneWidget);
    expect(find.text('Hallo Mia! Tippe deine vier Bilder an.'), findsOneWidget);
    expect(find.text('Hallo Jonas! Tippe deine vier Bilder an.'), findsNothing);
  });

  // ---- Fix round 3: avatar colour collisions on same-initial names ----

  testWidgets('same-initial children get different avatar colours', (tester) async {
    // These ids are chosen so their id hashes land on the same palette index
    // (verified offline against the same hash the widget uses): without
    // collision resolution, each pair below would render an identical
    // colour behind the shared initial, exactly the bug a visual review
    // found with real names like Franziska/Finn and Marlene/Max.
    final sameInitialService = StudentAuthService(
      client: MockClient((req) async => http.Response(
            jsonEncode({
              'class_id': 'c1',
              'require_pin': false,
              'students': [
                {'id': 'f-student-1', 'display_name': 'Franziska', 'avatar': null},
                {'id': 'f-student-25', 'display_name': 'Finn', 'avatar': null},
                {'id': 'm-student-1', 'display_name': 'Marlene', 'avatar': null},
                {'id': 'm-student-16', 'display_name': 'Max', 'avatar': null},
              ],
            }),
            200,
          )),
    );

    await reachRoster(tester, sameInitialService);

    final avatars = tester.widgetList<CircleAvatar>(find.byType(CircleAvatar)).toList();
    expect(avatars.length, 4);

    // Franziska vs. Finn (both 'F').
    expect(avatars[0].backgroundColor, isNot(equals(avatars[1].backgroundColor)));
    // Marlene vs. Max (both 'M').
    expect(avatars[2].backgroundColor, isNot(equals(avatars[3].backgroundColor)));
  });

  // ---- Fix round 4: palette ordering must not put same-hue colours next
  // to each other, since collision resolution always advances to the next
  // adjacent index (see the doc comment on `_avatarPalette`). ----

  test('no two adjacent palette entries belong to the same hue family', () {
    final palette = avatarPaletteForTesting();
    expect(palette.length, 20);

    // Colours this desaturated (grey 800, blue grey 800) read as neutral;
    // HSL hue is not a meaningful signal for them, so they are a documented
    // special case rather than being forced through the hue check.
    const neutralSaturationCutoff = 0.20;

    // The reordering that fixed this (see the doc comment above
    // `_avatarPalette`) separates every same-family neighbour by well over
    // 130 degrees of hue. 90 degrees is a safe threshold well below that
    // achieved minimum but far above any plausible same-family adjacency
    // (e.g. the old brown 700/brown 900 pair sat about 5 degrees apart).
    const minHueSeparation = 90.0;

    double circularHueDistance(double a, double b) {
      final diff = (a - b).abs() % 360.0;
      return diff > 180.0 ? 360.0 - diff : diff;
    }

    for (var i = 0; i < palette.length; i++) {
      final a = HSLColor.fromColor(palette[i]);
      final b = HSLColor.fromColor(palette[(i + 1) % palette.length]);
      if (a.saturation < neutralSaturationCutoff || b.saturation < neutralSaturationCutoff) {
        continue;
      }
      final distance = circularHueDistance(a.hue, b.hue);
      expect(
        distance,
        greaterThanOrEqualTo(minHueSeparation),
        reason: 'Palette entries at index $i and ${(i + 1) % palette.length} '
            '(${palette[i]} and ${palette[(i + 1) % palette.length]}) are only '
            '$distance degrees apart in hue — too close to tell apart at a '
            'glance if a collision hands them to the same-initial pair they '
            'exist to protect.',
      );
    }
  });
}

String? _lastLoginBody;
