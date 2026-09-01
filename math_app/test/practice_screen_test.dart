import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:math_app/models/skill_spec.dart';
import 'package:math_app/practice/practice_controller.dart';
import 'package:math_app/screens/practice_screen.dart';
import 'package:math_app/services/learning_path_service.dart';
import 'package:math_app/services/skill_spec_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _praise = ['Super!', 'Toll!', 'Genau so!'];

/// Backend for the MockClient: records every request, lets start/end fail on
/// demand and returns a configurable mastery verdict.
class _Backend {
  bool failStart = false;
  bool failEnd = false;
  bool mastered = true;
  List<String> unlocked = ['A1.1b'];
  int startCalls = 0;
  int endCalls = 0;
  final List<Map<String, dynamic>> syncedBatches = [];

  late final http.Client client = MockClient((request) async {
    final path = request.url.path;
    if (path.endsWith('/practice-session/start')) {
      startCalls++;
      if (failStart) {
        return http.Response(
          jsonEncode({'error': 'Der Server ist gerade nicht erreichbar.'}),
          500,
        );
      }
      return http.Response(
        jsonEncode({'practice_session_id': 'ps-$startCalls', 'seed': 7}),
        200,
      );
    }
    if (path.endsWith('/practice-session/sync')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      syncedBatches.add(body);
      return http.Response(jsonEncode({}), 200);
    }
    if (path.endsWith('/practice-session/end')) {
      endCalls++;
      if (failEnd) {
        return http.Response(jsonEncode({'error': 'Speichern fehlgeschlagen.'}), 500);
      }
      return http.Response(
        jsonEncode({
          'skill_mastered': mastered,
          'slow_flag': false,
          'unlocked_skill_ids': unlocked,
        }),
        200,
      );
    }
    return http.Response('not found', 404);
  });

  /// Every attempt the server received, in submission order.
  List<Map<String, dynamic>> get receivedAttempts => [
        for (final batch in syncedBatches)
          for (final attempt in batch['attempts'] as List)
            attempt as Map<String, dynamic>,
      ];
}

Map<String, dynamic> _level(
  int level,
  String representation,
  String template,
  Map<String, dynamic> params,
  int slowBandMs,
) =>
    {
      'level': level,
      'representation': representation,
      'template': template,
      'custom_widget': null,
      'params': params,
      'problem_count': 8,
      'prompt_de': 'Test-Prompt.',
      'slow_band_ms': slowBandMs,
    };

/// A three-level spec whose `levelNumber`th level uses [template]. Level 3 is
/// symbolisch equation_solve, so the representation chip reads "Rechne".
SkillSpec _spec(
  int levelNumber,
  String template,
  Map<String, dynamic> params,
) {
  final levels = [
    _level(1, 'enaktiv', 'place_counters', {
      'count_range': [1, 5],
      'frame': 'zehnerfeld',
      'action': 'fill',
    }, 9000),
    _level(2, 'symbolisch', 'equation_solve', {
      'op': '+',
      'unknown': 'result',
      'zr': 20,
      'a_range': [2, 9],
      'b_range': [2, 9],
      'mode': 'standard',
    }, 7000),
    _level(3, 'symbolisch', 'equation_solve', {
      'op': '+',
      'unknown': 'result',
      'zr': 10,
      'a_range': [1, 5],
      'b_range': [1, 5],
      'mode': 'standard',
    }, 6000),
  ];
  levels[levelNumber - 1] =
      _level(levelNumber, 'symbolisch', template, params, 6000);

  return SkillSpec.fromJson({
    'spec_version': 1,
    'skill_id': 'G1',
    'construct_id': 'G1',
    'domain': 'A',
    'title_de': 'Controller-Test',
    'level_titles_de': ['Stufe 1', 'Stufe 2', 'Stufe 3'],
    'levels': levels,
    'mastery': {'correct_of': 8},
    'error_taxonomy': [
      {
        'code': 'miscount',
        'label_de': 'verzählt',
        'hint_de': 'Zähle noch einmal langsam.',
      },
      {
        'code': 'other',
        'label_de': 'noch einmal probieren',
        'hint_de': 'Schau noch einmal genau hin.',
      },
    ],
    'provenance': {
      'sources': ['Testquelle 2026'],
      'author': 'Test',
      'reviewed_by': 'open',
    },
  });
}

/// A store holding the real A1.1b spec, so the summary can resolve the
/// server's `unlocked_skill_ids` to child-facing titles.
SkillSpecStore _unlockStore() => SkillSpecStore.fromJsonMap({
      'A1.1b': File('../docs/clean-room/skills/specs/A1.1b.json').readAsStringSync(),
    });

Future<void> _pumpScreen(
  WidgetTester tester,
  PracticeController controller,
  SkillSpec spec, {
  SkillSpecStore? store,
  int level = 3,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 1700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    MaterialApp(
      home: PracticeScreen(
        token: 'tok',
        spec: spec,
        level: level,
        controller: controller,
        skillStore: store,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

/// Pushes the screen over a stub home so `Navigator.pop` can be observed.
Future<void> _pushScreen(
  WidgetTester tester,
  PracticeController controller,
  SkillSpec spec,
) async {
  await tester.binding.setSurfaceSize(const Size(900, 1700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PracticeScreen(
                    token: 'tok',
                    spec: spec,
                    level: 3,
                    controller: controller,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
  await tester.pump();
}

/// Answers the current equation_solve problem correctly and advances.
Future<void> _answerCorrect(WidgetTester tester, PracticeController controller) async {
  final expected = controller.currentProblem!.expected.single;
  await tester.enterText(find.byType(TextField), expected);
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('full all-correct session: progress, feedback, summary, /end '
      'and submit gated on a reported value', (tester) async {
    final backend = _Backend();
    final service = LearningPathService(client: backend.client);
    final spec = _spec(3, 'equation_solve', {
      'op': '+',
      'unknown': 'result',
      'zr': 10,
      'a_range': [1, 5],
      'b_range': [1, 5],
      'mode': 'standard',
    });
    final controller = PracticeController(
      token: 'tok',
      spec: spec,
      level: 3,
      service: service,
    );
    await _pumpScreen(tester, controller, spec, store: _unlockStore());

    // First problem rendered: title, progress, representation chip, prompt,
    // submit disabled while the widget reports no value.
    expect(find.text('Controller-Test'), findsOneWidget);
    expect(find.text('Aufgabe 1 von 8'), findsOneWidget);
    expect(find.text('Rechne'), findsOneWidget);
    expect(find.text('Test-Prompt.'), findsWidgets,
        reason: 'the prompt appears in the screen card (and inside the '
            'equation widget)');
    expect(find.byKey(const ValueKey('progress-dot-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-dot-7')), findsOneWidget);
    final submit = find.widgetWithText(FilledButton, 'Weiter');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull,
        reason: 'submit stays disabled while no value is reported');

    for (var i = 0; i < 8; i++) {
      await _answerCorrect(tester, controller);
      expect(find.text(_praise[i % 3]), findsOneWidget,
          reason: 'problem $i shows the deterministic praise');
      if (i < 7) {
        await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
        await tester.pump();
        await tester.pump();
        expect(find.text('Aufgabe ${i + 2} von 8'), findsOneWidget,
            reason: 'progress advances after problem $i');
      }
    }

    // Advance the last problem: the screen must call finish() → /end.
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Geschafft!'), findsOneWidget);
    expect(find.text('Vorwärtszählen bis 100'), findsOneWidget,
        reason: 'the unlocked skill title is listed');
    expect(find.text('Zurück zum Lernpfad'), findsOneWidget);
    expect(backend.endCalls, 1);
    expect(backend.receivedAttempts, hasLength(8));
    for (var i = 0; i < 8; i++) {
      expect(backend.receivedAttempts[i]['problem_index'], i);
      expect(backend.receivedAttempts[i]['was_correct'], isTrue);
    }

    await tester.pump(const Duration(seconds: 2)); // flush the auto-advance timer
  });

  testWidgets('wrong answer: hint shown, retry records no second attempt, '
      '"Weiter" advances', (tester) async {
    final backend = _Backend();
    final service = LearningPathService(client: backend.client);
    final spec = _spec(3, 'equation_solve', {
      'op': '+',
      'unknown': 'result',
      'zr': 10,
      'a_range': [1, 5],
      'b_range': [1, 5],
      'mode': 'standard',
    });
    final controller = PracticeController(
      token: 'tok',
      spec: spec,
      level: 3,
      service: service,
    );
    await _pumpScreen(tester, controller, spec);

    // Problem 0: answer off by one → wrong.
    final expected = int.parse(controller.currentProblem!.expected.single);
    final wrong = '${expected + 1}';
    await tester.enterText(find.byType(TextField), wrong);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pump();
    await tester.pump();

    // Taxonomy hint and the child's input stay visible.
    expect(find.text('Zähle noch einmal langsam.'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        wrong, reason: 'the input stays for retry');

    // Retry with the correct answer: correct feedback, but the attempt for
    // this problem_index is NOT re-recorded.
    await tester.enterText(find.byType(TextField), '$expected');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Nochmal'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Jetzt stimmt es!'), findsOneWidget,
        reason: 'a successful retry gets honest feedback, not first-attempt '
            '"Super!"');
    expect(find.text('Super!'), findsNothing,
        reason: '"Super!" is reserved for first-attempt-correct answers');
    expect(backend.receivedAttempts, hasLength(1));
    expect(backend.receivedAttempts.single['problem_index'], 0);
    expect(backend.receivedAttempts.single['was_correct'], isFalse,
        reason: 'the first, wrong attempt is the only record');

    // "Weiter" advances to problem 2.
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Aufgabe 2 von 8'), findsOneWidget);

    // Finish the remaining seven correctly.
    for (var i = 1; i < 8; i++) {
      await _answerCorrect(tester, controller);
      if (i < 7) {
        await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
        await tester.pump();
        await tester.pump();
      }
    }
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    final attempts = backend.receivedAttempts;
    expect(attempts, hasLength(8),
        reason: 'the retry must not add a ninth attempt');
    expect(attempts[0]['problem_index'], 0);
    expect(attempts[0]['was_correct'], isFalse);
    for (var i = 1; i < 8; i++) {
      expect(attempts[i]['problem_index'], i);
      expect(attempts[i]['was_correct'], isTrue);
    }

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('mastered session with further skill levels: the summary is '
      'session-positive and says how many stages remain — never '
      '"Fast geschafft!"', (tester) async {
    final backend = _Backend()..mastered = false;
    final service = LearningPathService(client: backend.client);
    final spec = _spec(1, 'equation_solve', {
      'op': '+',
      'unknown': 'result',
      'zr': 10,
      'a_range': [1, 5],
      'b_range': [1, 5],
      'mode': 'standard',
    });
    final controller = PracticeController(
      token: 'tok',
      spec: spec,
      level: 1,
      service: service,
    );
    await _pumpScreen(tester, controller, spec, store: _unlockStore(), level: 1);

    // All 8 problems correct on the first attempt → the session is mastered.
    for (var i = 0; i < 8; i++) {
      await _answerCorrect(tester, controller);
      if (i < 7) {
        await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
        await tester.pump();
        await tester.pump();
      }
    }
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(backend.endCalls, 1);
    expect(controller.sessionMastered, isTrue,
        reason: '8/8 correct on first attempts masters the session');
    expect(find.text('Geschafft!'), findsOneWidget);
    expect(find.text('Du hast alle 8 Aufgaben richtig.'), findsOneWidget);
    expect(
      find.text('Noch 2 Stufen bis die Kompetenz ganz geschafft ist.'),
      findsOneWidget,
      reason: 'level 1 of 3 is done, so 2 stages remain',
    );
    expect(find.text('Fast geschafft!'), findsNothing,
        reason: 'the session was mastered — only a non-mastered session '
            'deserves "Fast geschafft!"');
    expect(find.text('Zurück zum Lernpfad'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2)); // flush the auto-advance timer
  });

  testWidgets(
      'reduced motion: correct feedback stays visible without the pulse and '
      'the incorrect shake is skipped', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final backend = _Backend();
    final service = LearningPathService(client: backend.client);
    final spec = _spec(3, 'equation_solve', {
      'op': '+',
      'unknown': 'result',
      'zr': 10,
      'a_range': [1, 5],
      'b_range': [1, 5],
      'mode': 'standard',
    });
    final controller = PracticeController(
      token: 'tok',
      spec: spec,
      level: 3,
      service: service,
    );
    await _pumpScreen(tester, controller, spec);

    // A correct answer still shows the check + praise (no animation widget).
    await _answerCorrect(tester, controller);
    expect(find.text('Super!'), findsOneWidget,
        reason: 'the feedback is shown even without animations');
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing,
        reason: 'the scale pulse is skipped under reduced motion');

    // A wrong answer still shows the taxonomy hint (no shake).
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pump();
    await tester.pump();
    final expected = controller.currentProblem!.expected.single;
    await tester.enterText(find.byType(TextField), '${int.parse(expected) + 1}');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Zähle noch einmal langsam.'), findsOneWidget,
        reason: 'the hint is shown without the shake');
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);

    await tester.pump(const Duration(seconds: 2)); // flush the auto-advance timer
  });

  testWidgets('exit dialog: Beenden pops the screen, Weiterüben stays',
      (tester) async {
    final backend = _Backend();
    final service = LearningPathService(client: backend.client);
    final spec = _spec(3, 'equation_solve', {
      'op': '+',
      'unknown': 'result',
      'zr': 10,
      'a_range': [1, 5],
      'b_range': [1, 5],
      'mode': 'standard',
    });
    final controller = PracticeController(
      token: 'tok',
      spec: spec,
      level: 3,
      service: service,
    );
    await _pushScreen(tester, controller, spec);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Übung beenden?'), findsOneWidget);

    // Weiterüben dismisses the dialog and stays on the screen.
    await tester.tap(find.text('Weiterüben'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Übung beenden?'), findsNothing);
    expect(find.byType(PracticeScreen), findsOneWidget);

    // Beenden pops back to the stub home.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Beenden'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(PracticeScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('start failure shows the German error and retry works',
      (tester) async {
    final backend = _Backend()..failStart = true;
    final service = LearningPathService(client: backend.client);
    final spec = _spec(3, 'equation_solve', {
      'op': '+',
      'unknown': 'result',
      'zr': 10,
      'a_range': [1, 5],
      'b_range': [1, 5],
      'mode': 'standard',
    });
    final controller = PracticeController(
      token: 'tok',
      spec: spec,
      level: 3,
      service: service,
    );
    await _pumpScreen(tester, controller, spec);

    expect(find.text('Der Server ist gerade nicht erreichbar.'), findsOneWidget);
    expect(find.text('Nochmal versuchen'), findsOneWidget);

    backend.failStart = false;
    await tester.tap(find.text('Nochmal versuchen'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(controller.state, PracticeState.ready);
    expect(find.text('Aufgabe 1 von 8'), findsOneWidget);
    expect(find.text('Rechne'), findsOneWidget);
  });

  testWidgets('unmount during the 1.2s feedback delay does not throw',
      (tester) async {
    final backend = _Backend();
    final service = LearningPathService(client: backend.client);
    final spec = _spec(3, 'equation_solve', {
      'op': '+',
      'unknown': 'result',
      'zr': 10,
      'a_range': [1, 5],
      'b_range': [1, 5],
      'mode': 'standard',
    });
    final controller = PracticeController(
      token: 'tok',
      spec: spec,
      level: 3,
      service: service,
    );
    await _pumpScreen(tester, controller, spec);

    await _answerCorrect(tester, controller);
    expect(find.text('Super!'), findsOneWidget);

    // Unmount while the auto-advance timer is still pending.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('wrong-answer feedback is encouraging: hint shown, never the '
      'punitive word "Falsch"', (tester) async {
    final backend = _Backend();
    final service = LearningPathService(client: backend.client);
    final spec = _spec(3, 'equation_solve', {
      'op': '+',
      'unknown': 'result',
      'zr': 10,
      'a_range': [1, 5],
      'b_range': [1, 5],
      'mode': 'standard',
    });
    final controller = PracticeController(
      token: 'tok',
      spec: spec,
      level: 3,
      service: service,
    );
    await _pumpScreen(tester, controller, spec);

    final expected = int.parse(controller.currentProblem!.expected.single);
    await tester.enterText(find.byType(TextField), '${expected + 1}');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pump();
    await tester.pump();

    // The taxonomy hint appears, the retry stays possible, and the copy is
    // gentle — no red "Falsch!" anywhere.
    expect(find.text('Zähle noch einmal langsam.'), findsOneWidget);
    expect(find.text('Nochmal'), findsOneWidget,
        reason: 'the child can retry the same problem');
    expect(find.textContaining('Falsch'), findsNothing,
        reason: 'feedback must never be punitive');

    final hint = tester.widget<Text>(find.text('Zähle noch einmal langsam.'));
    expect(hint.style?.color, isNot(Colors.red.shade700),
        reason: 'the hint is not signalled in red');

    await tester.pump(const Duration(seconds: 2));
  });
}
