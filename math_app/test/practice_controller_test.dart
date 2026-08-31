import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:math_app/models/skill_spec.dart';
import 'package:math_app/practice/practice_controller.dart';
import 'package:math_app/practice/problem_generators.dart';
import 'package:math_app/services/attempt_queue.dart';
import 'package:math_app/services/learning_path_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backend for the MockClient: records every request the controller makes
/// and lets each endpoint fail on demand.
class _Backend {
  final List<Map<String, dynamic>> startBodies = [];
  final List<Map<String, dynamic>> syncedBatches = [];
  final List<Map<String, dynamic>> endBodies = [];
  int startCalls = 0;
  int endCalls = 0;
  bool failStart = false;
  bool failSync = false;
  bool failEnd = false;

  late final http.Client client = MockClient((request) async {
    final path = request.url.path;
    if (path.endsWith('/practice-session/start')) {
      startCalls++;
      if (failStart) {
        return http.Response(
            jsonEncode({'error': 'Der Server ist gerade nicht erreichbar.'}), 500);
      }
      startBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
      return http.Response(
        jsonEncode({'practice_session_id': 'ps-$startCalls', 'seed': 7}),
        200,
      );
    }
    if (path.endsWith('/practice-session/sync')) {
      if (failSync) throw const SocketException('no route');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      syncedBatches.add(body);
      return http.Response(jsonEncode({}), 200);
    }
    if (path.endsWith('/practice-session/end')) {
      endCalls++;
      if (failEnd) {
        return http.Response(jsonEncode({'error': 'Speichern fehlgeschlagen.'}), 500);
      }
      endBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
      return http.Response(
        jsonEncode({
          'skill_mastered': true,
          'slow_flag': false,
          'unlocked_skill_ids': ['A1.1b'],
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

/// A three-level spec whose `levelNumber`th level uses [template].
SkillSpec _spec(
  int levelNumber,
  String template,
  Map<String, dynamic> params, {
  int slowBandMs = 5000,
  List<Map<String, String>>? taxonomy,
}) {
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
  levels[levelNumber - 1] = _level(levelNumber, 'symbolisch', template, params, slowBandMs);

  return SkillSpec.fromJson({
    'spec_version': 1,
    'skill_id': 'G1',
    'construct_id': 'G1',
    'domain': 'A',
    'title_de': 'Controller-Test',
    'level_titles_de': ['Stufe 1', 'Stufe 2', 'Stufe 3'],
    'levels': levels,
    'mastery': {'correct_of': 8},
    'error_taxonomy': taxonomy ??
        [
          {
            'code': 'miscount',
            'label_de': 'verzählt',
            'hint_de': 'Zähle noch einmal langsam.',
          },
          {
            'code': 'sign_error',
            'label_de': 'Plus und Minus verwechselt',
            'hint_de': 'Plus und Minus sind verschiedene Rechenzeichen.',
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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('full session: 8 problems recorded in order and /end carries the '
      'slow band', () async {
    final backend = _Backend();
    final service = LearningPathService(client: backend.client);
    final spec = _spec(2, 'equation_solve', {
      'op': '+',
      'unknown': 'result',
      'zr': 20,
      'a_range': [2, 9],
      'b_range': [2, 9],
      'mode': 'standard',
    });
    final controller = PracticeController(
      token: 'tok',
      spec: spec,
      level: 2,
      service: service,
    );

    await controller.start();
    expect(controller.state, PracticeState.ready);
    expect(controller.problemCount, 8);
    expect(controller.problemIndex, 0);

    // The backend uses seed 7, so the problem list is deterministic here.
    final expectedProblems =
        generateProblems(spec: spec, level: 2, seed: 7);

    for (var i = 0; i < 8; i++) {
      expect(controller.currentProblem?.index, i);
      final expected = controller.currentProblem!.expected.single;
      final correct = i.isEven;
      final submitted = correct ? expected : '${int.parse(expected) + 1}';
      await controller.submit(submitted);
      expect(
        controller.state,
        correct ? PracticeState.correct : PracticeState.incorrect,
        reason: 'problem $i',
      );
      if (correct) {
        expect(controller.lastEvaluation?.isCorrect, isTrue);
        expect(controller.hintDe, isNull);
      } else {
        expect(controller.lastEvaluation?.isCorrect, isFalse);
        expect(controller.lastEvaluation?.errorCode, 'miscount',
            reason: 'off-by-one answers map to miscount');
        expect(controller.hintDe, isNotNull,
            reason: 'a wrong answer exposes the taxonomy hint');
      }
      controller.advance();
    }
    expect(controller.state, PracticeState.finished);

    await controller.finish();
    expect(controller.state, PracticeState.finished);
    expect(controller.masteryResult, isNotNull);
    expect(controller.masteryResult!.mastered, isTrue);
    expect(controller.masteryResult!.slowFlag, isFalse);
    expect(controller.masteryResult!.unlocked, ['A1.1b']);

    final attempts = backend.receivedAttempts;
    expect(attempts, hasLength(8));
    for (var i = 0; i < 8; i++) {
      final attempt = attempts[i];
      expect(attempt['problem_index'], i, reason: 'attempt $i index');
      expect(attempt['was_correct'], i.isEven, reason: 'attempt $i verdict');
      expect(attempt['response_ms'], isA<int>(), reason: 'attempt $i timing');
      expect(attempt['response_ms'] as int, greaterThanOrEqualTo(0));
      expect(attempt['answer'], isA<String>());
      expect(attempt['error_code'], i.isEven ? isNull : 'miscount');
      expect(
        jsonEncode(attempt['problem']),
        jsonEncode(expectedProblems[i].toJson()),
        reason: 'attempt $i carries the exact problem JSON',
      );
    }

    expect(backend.endBodies, hasLength(1));
    expect(backend.endBodies.single['slow_band_ms'], spec.levelSpec(2).slowBandMs);
    expect(backend.startBodies.single['skill_id'], 'G1');
    expect(backend.startBodies.single['level'], 2);
  });

  test('a correct retry is flagged (isRetryCorrect) and not re-recorded',
      () async {
    final backend = _Backend();
    final service = LearningPathService(client: backend.client);
    final spec = _spec(2, 'equation_solve', {
      'op': '+',
      'unknown': 'result',
      'zr': 20,
      'a_range': [2, 9],
      'b_range': [2, 9],
      'mode': 'standard',
    });
    final controller = PracticeController(
      token: 'tok',
      spec: spec,
      level: 2,
      service: service,
    );

    await controller.start();
    final expected = controller.currentProblem!.expected.single;

    // First attempt wrong: not a retry, recorded once.
    await controller.submit('${int.parse(expected) + 1}');
    expect(controller.state, PracticeState.incorrect);
    expect(controller.isRetryCorrect, isFalse);

    // Correct retry: flagged as a retry, still only one record.
    await controller.submit(expected);
    expect(controller.state, PracticeState.correct);
    expect(controller.isRetryCorrect, isTrue,
        reason: 'the screen must say "Jetzt stimmt es!" instead of "Super!"');
    expect(backend.receivedAttempts, hasLength(1));
    expect(backend.receivedAttempts.single['was_correct'], isFalse);

    // Advancing clears the flag for the next problem.
    controller.advance();
    await controller.submit(controller.currentProblem!.expected.single);
    expect(controller.state, PracticeState.correct);
    expect(controller.isRetryCorrect, isFalse,
        reason: 'a fresh problem is not a retry');
  });

  test('a slow answer still evaluates and the record carries response_ms',
      () async {
    final backend = _Backend();
    final service = LearningPathService(client: backend.client);
    final spec = _spec(2, 'equation_solve', {
      'op': '+',
      'unknown': 'result',
      'zr': 20,
      'a_range': [2, 9],
      'b_range': [2, 9],
      'mode': 'standard',
    }, slowBandMs: 10);
    final controller = PracticeController(
      token: 'tok',
      spec: spec,
      level: 2,
      service: service,
    );

    await controller.start();
    // Answer well past the (tiny) slow band.
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final expected = controller.currentProblem!.expected.single;
    await controller.submit(expected);

    expect(controller.state, PracticeState.correct,
        reason: 'a slow answer still evaluates');
    final recorded = backend.receivedAttempts.single;
    final responseMs = recorded['response_ms'] as int;
    expect(responseMs, greaterThan(spec.levelSpec(2).slowBandMs),
        reason: 'the record carries the slow response time');

    await controller.finish();
    expect(backend.endBodies.single['slow_band_ms'], 10,
        reason: 'the controller passes the spec slow band through');
  });

  test('network failure during recordAttempt keeps the session going and the '
      'queue intact', () async {
    final backend = _Backend();
    backend.failSync = true;
    final queue = AttemptQueue();
    final service = LearningPathService(client: backend.client, queue: queue);
    final spec = _spec(2, 'equation_solve', {
      'op': '+',
      'unknown': 'result',
      'zr': 20,
      'a_range': [2, 9],
      'b_range': [2, 9],
      'mode': 'standard',
    });
    final controller = PracticeController(
      token: 'tok',
      spec: spec,
      level: 2,
      service: service,
    );

    await controller.start();
    await controller.submit(controller.currentProblem!.expected.single);
    expect(controller.state, PracticeState.correct,
        reason: 'the session continues despite the drop');
    controller.advance();
    await controller.submit(controller.currentProblem!.expected.single);
    expect(controller.state, PracticeState.correct);

    expect(backend.receivedAttempts, isEmpty,
        reason: 'nothing reached the server while offline');
    final pending = await queue.pending('ps-1');
    expect(pending, hasLength(2), reason: 'both attempts are retained');

    // Back online: the next attempt flushes everything.
    backend.failSync = false;
    controller.advance();
    await controller.submit(controller.currentProblem!.expected.single);
    final attempts = backend.receivedAttempts;
    expect(attempts, hasLength(3),
        reason: 'the queued attempts arrive with the next flush');
    expect(attempts.map((a) => a['problem_index']).toList(), [0, 1, 2]);
    expect(await queue.pending('ps-1'), isEmpty);
  });

  test('start() failure leaves a failed state with a German message and '
      'retrying works', () async {
    final backend = _Backend();
    backend.failStart = true;
    final service = LearningPathService(client: backend.client);
    final spec = _spec(2, 'equation_solve', {
      'op': '+',
      'unknown': 'result',
      'zr': 20,
      'a_range': [2, 9],
      'b_range': [2, 9],
      'mode': 'standard',
    });
    final controller = PracticeController(
      token: 'tok',
      spec: spec,
      level: 2,
      service: service,
    );

    await controller.start();
    expect(controller.state, PracticeState.failed);
    expect(controller.errorMessage, isNotNull);
    expect(controller.errorMessage, isNotEmpty);
    expect(RegExp(r'\d').hasMatch(controller.errorMessage!), isFalse,
        reason: 'child-facing messages carry no status codes');

    backend.failStart = false;
    await controller.start();
    expect(controller.state, PracticeState.ready);
    expect(controller.problemCount, 8);
    expect(controller.currentProblem, isNotNull);
  });

  test('finish() failure surfaces as failed and finish is idempotent', () async {
    final backend = _Backend();
    backend.failEnd = true;
    final service = LearningPathService(client: backend.client);
    final spec = _spec(2, 'equation_solve', {
      'op': '+',
      'unknown': 'result',
      'zr': 20,
      'a_range': [2, 9],
      'b_range': [2, 9],
      'mode': 'standard',
    });
    final controller = PracticeController(
      token: 'tok',
      spec: spec,
      level: 2,
      service: service,
    );

    await controller.start();
    await controller.submit(controller.currentProblem!.expected.single);
    await controller.finish();
    expect(controller.state, PracticeState.failed);
    expect(controller.errorMessage, isNotEmpty);
    expect(controller.masteryResult, isNull);

    // The server is back: calling finish again completes the session.
    backend.failEnd = false;
    await controller.finish();
    expect(controller.state, PracticeState.finished);
    expect(controller.masteryResult?.mastered, isTrue);

    // Idempotent: a third call must not re-contact the server.
    final callsBefore = backend.endCalls;
    await controller.finish();
    expect(backend.endCalls, callsBefore,
        reason: 'finish is safe to call repeatedly');
  });

  test('strategy_choice is evaluated as a value|strategy composite', () async {
    final backend = _Backend();
    final service = LearningPathService(client: backend.client);
    final spec = _spec(2, 'strategy_choice', {
      'op': '+',
      'zr': 20,
      'a_range': [2, 10],
      'b_range': [2, 10],
      'strategies': [
        {'id': 'verdoppeln', 'label_de': 'Verdoppeln'},
        {'id': 'fast_verdoppeln', 'label_de': 'Fast verdoppeln'},
      ],
      'correct_strategy': 'verdoppeln',
    });
    final controller = PracticeController(
      token: 'tok',
      spec: spec,
      level: 2,
      service: service,
    );

    await controller.start();
    expect(controller.currentProblem!.display['correct_strategy'], 'verdoppeln');
    final value = controller.currentProblem!.expected.single;
    await controller.submit('$value|verdoppeln');
    expect(controller.state, PracticeState.correct);

    controller.advance();
    final value2 = controller.currentProblem!.expected.single;
    await controller.submit('$value2|fast_verdoppeln');
    expect(controller.state, PracticeState.incorrect,
        reason: 'the right value with the wrong strategy is wrong');
    expect(controller.lastEvaluation?.errorCode, 'other');
  });

  test('drag_partition make_ten: a split without a full ten is wrong', () async {
    final backend = _Backend();
    final service = LearningPathService(client: backend.client);
    final spec = _spec(2, 'drag_partition', {
      'total_range': [11, 19],
      'parts': 2,
      'split_constraint': 'make_ten',
      'box_labels': ['volle Zehn', 'Rest'],
    });
    final controller = PracticeController(
      token: 'tok',
      spec: spec,
      level: 2,
      service: service,
    );

    await controller.start();
    final total = controller.currentProblem!.display['total'] as int;
    await controller.submit('10+${total - 10}');
    expect(controller.state, PracticeState.correct,
        reason: '10 + (total-10) is the canonical split');

    controller.advance();
    final total2 = controller.currentProblem!.display['total'] as int;
    final wrong = total2 == 11 ? '9+2' : '1+${total2 - 1}';
    await controller.submit(wrong);
    expect(controller.state, PracticeState.incorrect,
        reason: '11 = 9+2 is not a split-to-ten');
  });

  test('two_groups difference (C1.1b L2): expected is the asked quantity',
      () async {
    final backend = _Backend();
    final service = LearningPathService(client: backend.client);
    final spec = SkillSpec.fromJson(
      jsonDecode(File('../docs/clean-room/skills/specs/C1.1b.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final controller = PracticeController(
      token: 'tok',
      spec: spec,
      level: 2,
      service: service,
    );

    await controller.start();
    final problem = controller.currentProblem!;
    expect(problem.display['arrangement'], 'two_groups');
    expect(problem.display['ask'], 'difference');
    final split = (problem.display['split'] as List).cast<int>();
    final diff = (split[0] - split[1]).abs();
    expect(diff, greaterThanOrEqualTo(1));
    expect(problem.expected.single, '$diff',
        reason: 'expected is the difference, not the total');

    await controller.submit(problem.expected.single);
    expect(controller.state, PracticeState.correct);
  });
}
