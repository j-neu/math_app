import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/screens/child_path_screen.dart';
import 'package:math_app/screens/practice_screen.dart';
import 'package:math_app/services/learning_path_service.dart';
import 'package:math_app/services/skill_spec_store.dart';
import 'package:math_app/services/student_auth_service.dart';

const _specsDir = '../docs/clean-room/skills/specs';

/// Test-only loader, same pattern as test/skill_spec_store_test.dart: builds
/// the store from the real spec JSONs read off the clean-room source tree.
SkillSpecStore _realStore() {
  final dir = Directory(_specsDir);
  expect(dir.existsSync(), isTrue, reason: 'real spec tree must exist');
  final jsons = <String, String>{};
  for (final file in dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))) {
    jsons[file.path.split(Platform.pathSeparator).last] =
        file.readAsStringSync();
  }
  return SkillSpecStore.fromJsonMap(jsons);
}

/// A path with three mixed items: mastered (A1.1a), available (A1.1b),
/// locked (A2.1). All three skill ids exist in the real spec bundle.
String _pathJson({bool empty = false}) => jsonEncode({
      'path_id': empty ? null : 'p1',
      'unlock_width': 3,
      'items': empty
          ? []
          : [
              {
                'skill_id': 'A1.1a',
                'position': 1,
                'state': 'mastered',
                'title_de': 'Vorwärtszählen bis 20',
                'description_de': 'Zahlenreihe vorwärts',
                'color': 'blue',
                'progress': [
                  {
                    'level': 1,
                    'attempts': 8,
                    'correct': 8,
                    'mastered_at': '2026-08-01T10:00:00Z',
                  },
                  {
                    'level': 2,
                    'attempts': 8,
                    'correct': 8,
                    'mastered_at': '2026-08-01T10:05:00Z',
                  },
                  {
                    'level': 3,
                    'attempts': 8,
                    'correct': 8,
                    'mastered_at': '2026-08-01T10:10:00Z',
                  },
                ],
              },
              {
                'skill_id': 'A1.1b',
                'position': 2,
                'state': 'available',
                'title_de': 'Zählen bis 100',
                'description_de': 'Zahlenreihe bis 100',
                'color': 'green',
                'progress': [],
              },
              {
                'skill_id': 'A2.1',
                'position': 3,
                'state': 'locked',
                'title_de': 'Mengen blitzschnell erkennen',
                'description_de': 'Blitzsehen üben',
                'color': 'orange',
                'progress': [],
              },
            ],
    });

GoRouter _router(Widget screen) => GoRouter(
      initialLocation: '/lernpfad',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home-stub')),
        ),
        GoRoute(path: '/lernpfad', builder: (_, __) => screen),
      ],
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('no stored token shows a friendly prompt and a button to "/"',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: _router(const ChildPathScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bitte melde dich an.'), findsOneWidget);

    await tester.tap(find.text('Zur Anmeldung'));
    await tester.pumpAndSettle();
    expect(find.text('home-stub'), findsOneWidget);
  });

  testWidgets(
      'loading then rendered path with mixed states; available tile opens '
      'practice, locked tile does not navigate, returning refetches',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var fetchCalls = 0;
    final client = MockClient((req) async {
      expect(req.url.path.endsWith('/learning-path'), isTrue);
      fetchCalls++;
      // A real delay so the loading spinner can be observed before the
      // fetch resolves.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return http.Response(_pathJson(), 200);
    });

    await tester.pumpWidget(MaterialApp.router(
      routerConfig: _router(
        ChildPathScreen(
          token: 'tok',
          displayName: 'Mia',
          service: LearningPathService(client: client),
          store: _realStore(),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget,
        reason: 'the screen shows a spinner while the path loads');

    await tester.pumpAndSettle();

    expect(find.text('Hallo, Mia!'), findsOneWidget);
    expect(find.text('Vorwärtszählen bis 20'), findsOneWidget);
    expect(find.text('Zählen bis 100'), findsOneWidget);
    expect(find.text('Mengen blitzschnell erkennen'), findsOneWidget);
    // Each state carries icon + text, never colour alone.
    expect(find.text('Geschafft'), findsOneWidget);
    expect(find.text('Verfügbar'), findsOneWidget);
    expect(find.text('Noch gesperrt'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
    // Overview strip and the three level pips per tile.
    expect(find.byKey(const ValueKey('overview')), findsOneWidget);
    expect(find.byKey(const ValueKey('pip-A1.1a-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pip-A1.1a-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('pip-A1.1b-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pip-A2.1-3')), findsOneWidget);

    // Locked tile must not navigate.
    await tester.tap(find.byKey(const ValueKey('path-item-A2.1')));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(PracticeScreen), findsNothing);

    // Available tile opens practice.
    await tester.tap(find.byKey(const ValueKey('path-item-A1.1b')));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeScreen), findsOneWidget);

    // Leave practice via the close dialog: the path screen must refetch.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Übung beenden?'), findsOneWidget);
    await tester.tap(find.text('Beenden'));
    await tester.pumpAndSettle();

    expect(find.byType(PracticeScreen), findsNothing);
    expect(find.text('Hallo, Mia!'), findsOneWidget);
    expect(fetchCalls, 2,
        reason: 'returning from practice refetches the path');
  });

  testWidgets('fetch failure shows a German error and retry reloads the path',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var calls = 0;
    final client = MockClient((req) async {
      calls++;
      if (calls == 1) throw const SocketException('offline');
      return http.Response(_pathJson(), 200);
    });

    await tester.pumpWidget(MaterialApp.router(
      routerConfig: _router(
        ChildPathScreen(
          token: 'tok',
          displayName: 'Mia',
          service: LearningPathService(client: client),
          store: _realStore(),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
      find.text('Verbindung zum Server nicht möglich. '
          'Bitte Internetverbindung prüfen.'),
      findsOneWidget,
    );
    expect(find.text('Nochmal versuchen'), findsOneWidget);

    await tester.tap(find.text('Nochmal versuchen'));
    await tester.pumpAndSettle();

    expect(find.text('Hallo, Mia!'), findsOneWidget);
    expect(find.text('Verfügbar'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('no active path shows the friendly empty state and refresh works',
      (tester) async {
    var calls = 0;
    final client = MockClient((req) async {
      calls++;
      return http.Response(_pathJson(empty: true), 200);
    });

    await tester.pumpWidget(MaterialApp.router(
      routerConfig: _router(
        ChildPathScreen(
          token: 'tok',
          service: LearningPathService(client: client),
          store: _realStore(),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Deine Lehrkraft bereitet deinen Lernpfad gerade vor'),
      findsOneWidget,
    );
    expect(find.text('Aktualisieren'), findsOneWidget);

    await tester.tap(find.text('Aktualisieren'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('logout clears the stored credentials and goes home',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'student_token': 'tok',
      'student_name': 'Mia',
    });
    final client = MockClient((req) async => http.Response(_pathJson(), 200));

    await tester.pumpWidget(MaterialApp.router(
      routerConfig: _router(
        ChildPathScreen(
          service: LearningPathService(client: client),
          store: _realStore(),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Hallo, Mia!'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('logout')));
    await tester.pumpAndSettle();

    final auth = StudentAuthService();
    expect(await auth.storedToken(), isNull);
    expect(await auth.storedName(), isNull);
    expect(find.text('home-stub'), findsOneWidget);
  });
}
