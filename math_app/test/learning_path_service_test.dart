import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math_app/services/attempt_queue.dart';
import 'package:math_app/services/learning_path_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('fetchPath parses a well-formed payload', () async {
    final client = MockClient((req) async => http.Response(
          jsonEncode({
            'path_id': 'p1',
            'unlock_width': 3,
            'items': [
              {
                'skill_id': 'add-10',
                'position': 1,
                'state': 'available',
                'title_de': 'Addieren bis 10',
                'description_de': 'Zahlen bis 10 addieren',
                'color': 'blue',
                'progress': [],
              },
            ],
          }),
          200,
        ));

    final path = await LearningPathService(client: client).fetchPath('tok');

    expect(path.pathId, 'p1');
    expect(path.items, hasLength(1));
    expect(path.items.first.skillId, 'add-10');
  });

  test('fetchPath surfaces a not-yet-activated path as an empty path, not an error', () async {
    final client = MockClient((req) async => http.Response(
        jsonEncode({'path_id': null, 'items': []}), 200));

    final path = await LearningPathService(client: client).fetchPath('tok');

    expect(path.pathId, isNull);
    expect(path.items, isEmpty);
    expect(path.hasActivePath, isFalse);
  });

  test('fetchPath raises a clean, typed exception on a non-200 response', () async {
    final client = MockClient((req) async =>
        http.Response(jsonEncode({'error': 'nicht gefunden'}), 500));

    expect(
      () => LearningPathService(client: client).fetchPath('tok'),
      throwsA(isA<LearningPathException>()),
    );
  });

  test('fetchPath failure message never leaks the raw HTTP status code to the child',
      () async {
    // A raw status code (500, 502, ...) must never reach a 6-year-old.
    final client = MockClient((req) async =>
        http.Response(jsonEncode({'error': 'nicht gefunden'}), 500));

    late Object caught;
    try {
      await LearningPathService(client: client).fetchPath('tok');
      fail('expected fetchPath to throw');
    } catch (e) {
      caught = e;
    }

    expect(caught, isA<LearningPathException>());
    final message = (caught as LearningPathException).message;
    expect(message, isNot(contains('500')));
    expect(RegExp(r'\d').hasMatch(message), isFalse,
        reason: 'child-facing message "$message" must contain no digits/codes');
  });

  test('fetchPath raises a clean, typed exception on malformed data instead of a raw TypeError', () async {
    // skill_id is a number here, not a String — LearningPath.fromJson /
    // PathItem.fromJson would otherwise throw a raw TypeError deep inside
    // the model parsing. The service must catch that and surface a
    // German-messaged, typed exception instead, with no half-built path
    // reaching the caller.
    final client = MockClient((req) async => http.Response(
          jsonEncode({
            'path_id': 'p1',
            'unlock_width': 3,
            'items': [
              {
                'skill_id': 12345,
                'position': 1,
                'state': 'available',
                'title_de': 'Kaputt',
                'description_de': 'Kaputt',
                'color': 'blue',
                'progress': [],
              },
            ],
          }),
          200,
        ));

    late Object caught;
    try {
      await LearningPathService(client: client).fetchPath('tok');
      fail('expected fetchPath to throw');
    } catch (e) {
      caught = e;
    }

    expect(caught, isA<LearningPathException>());
    expect(caught, isNot(isA<TypeError>()));
  });

  test('fetchPath surfaces a typed German error on a socket failure', () async {
    final client = MockClient((req) async => throw const SocketException('no route'));

    late Object caught;
    try {
      await LearningPathService(client: client).fetchPath('tok');
      fail('expected fetchPath to throw');
    } catch (e) {
      caught = e;
    }

    expect(caught, isA<LearningPathException>());
  });

  test('startPractice surfaces a typed German error on a socket failure', () async {
    final client = MockClient((req) async => throw const SocketException('no route'));

    late Object caught;
    try {
      await LearningPathService(client: client)
          .startPractice('tok', skillId: 'add-10', level: 1);
      fail('expected startPractice to throw');
    } catch (e) {
      caught = e;
    }

    expect(caught, isA<LearningPathException>());
  });

  test('startPractice surfaces a typed German error on a non-JSON 502 body', () async {
    final client = MockClient((req) async =>
        http.Response('<html><body>Bad Gateway</body></html>', 502));

    late Object caught;
    try {
      await LearningPathService(client: client)
          .startPractice('tok', skillId: 'add-10', level: 1);
      fail('expected startPractice to throw');
    } catch (e) {
      caught = e;
    }

    expect(caught, isA<LearningPathException>());
    expect(caught, isNot(isA<FormatException>()));
  });

  test('endPractice surfaces a typed German error on a socket failure from the end call', () async {
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/practice-session/sync')) {
        return http.Response(jsonEncode({}), 200);
      }
      throw const SocketException('no route');
    });

    late Object caught;
    try {
      await LearningPathService(client: client)
          .endPractice('tok', 'ps1', slowBandMs: 5000);
      fail('expected endPractice to throw');
    } catch (e) {
      caught = e;
    }

    expect(caught, isA<LearningPathException>());
  });

  test('endPractice surfaces a typed German error on a non-JSON 502 body from the end call', () async {
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/practice-session/sync')) {
        return http.Response(jsonEncode({}), 200);
      }
      return http.Response('<html><body>Bad Gateway</body></html>', 502);
    });

    late Object caught;
    try {
      await LearningPathService(client: client)
          .endPractice('tok', 'ps1', slowBandMs: 5000);
      fail('expected endPractice to throw');
    } catch (e) {
      caught = e;
    }

    expect(caught, isA<LearningPathException>());
    expect(caught, isNot(isA<FormatException>()));
  });

  test(
      'a failing endPractice flush keeps the session open instead of closing it on incomplete data',
      () async {
    // This is the exact scenario AttemptQueue exists to protect against, at
    // the one moment it matters most: session end. A dropped connection
    // during the final flush must not clear the queue, and the session
    // must never be closed on incomplete data — so /end must never be
    // called when the flush didn't fully succeed.
    final queue = AttemptQueue();
    const sessionId = 'ps-drop';
    await queue.add(
      sessionId,
      const PracticeAttempt(
        problemIndex: 0,
        problem: {'a': 2, 'b': 3},
        answer: '5',
        wasCorrect: true,
        responseMs: 1200,
        errorCode: null,
      ),
    );

    var endCalled = false;
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/practice-session/sync')) {
        throw const SocketException('dropped mid-flush');
      }
      endCalled = true;
      return http.Response(
        jsonEncode({
          'skill_mastered': false,
          'slow_flag': false,
          'unlocked_skill_ids': [],
        }),
        200,
      );
    });

    final service = LearningPathService(client: client, queue: queue);

    await expectLater(
      () => service.endPractice('tok', sessionId, slowBandMs: 5000),
      throwsA(isA<LearningPathException>()),
    );

    expect(endCalled, isFalse, reason: '/end must not be called when the flush failed');
    final stillPending = await queue.pending(sessionId);
    expect(stillPending, hasLength(1));
    expect(stillPending.first.problemIndex, 0);
    final pendingSessions = await service.pendingEndSessions();
    expect(
      pendingSessions.map((s) => s.practiceSessionId),
      contains(sessionId),
    );
    expect(
      pendingSessions.firstWhere((s) => s.practiceSessionId == sessionId).slowBandMs,
      5000,
      reason: 'the level band is persisted with the pending session so '
          'recovery re-ends it with the right slow threshold',
    );

    // Calling it again (e.g. the child retries) must not double-record the
    // session as pending.
    await expectLater(
      () => service.endPractice('tok', sessionId, slowBandMs: 5000),
      throwsA(isA<LearningPathException>()),
    );
    final pendingSessions2 = await service.pendingEndSessions();
    expect(
      pendingSessions2.where((s) => s.practiceSessionId == sessionId),
      hasLength(1),
    );
  });

  test(
      'recoverPendingSessions flushes and closes a stranded session, then clears it from the pending list',
      () async {
    // Simulates the next app run after the scenario above: a session was
    // left pending (flush failed last time), and nothing else ever
    // revisits an old practiceSessionId — recovery is the only thing that
    // can still get this child's last answer to the server.
    SharedPreferences.setMockInitialValues({
      'learning_path_pending_end_sessions': ['ps-stranded'],
    });
    final queue = AttemptQueue();
    await queue.add(
      'ps-stranded',
      const PracticeAttempt(
        problemIndex: 0,
        problem: {'a': 1, 'b': 1},
        answer: '2',
        wasCorrect: true,
        responseMs: 900,
        errorCode: null,
      ),
    );

    var endCalls = 0;
    int? sentBand;
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/practice-session/sync')) {
        return http.Response(jsonEncode({}), 200);
      }
      endCalls++;
      sentBand =
          (jsonDecode(req.body) as Map<String, dynamic>)['slow_band_ms'] as int?;
      return http.Response(
        jsonEncode({
          'skill_mastered': true,
          'slow_flag': false,
          'unlocked_skill_ids': <String>[],
        }),
        200,
      );
    });

    final service = LearningPathService(client: client, queue: queue);
    await service.recoverPendingSessions('tok');

    expect(endCalls, 1);
    // The legacy plain-id entry carries no band, so the 7000 ms fallback
    // is used.
    expect(sentBand, LearningPathService.defaultSlowBandMs);
    expect(await queue.pending('ps-stranded'), isEmpty);
    expect(await service.pendingEndSessions(), isEmpty);

    // Idempotent: nothing left pending, so calling it again does nothing.
    await service.recoverPendingSessions('tok');
    expect(endCalls, 1);
  });

  test('recoverPendingSessions uses the band stored on each pending session',
      () async {
    SharedPreferences.setMockInitialValues({
      'learning_path_pending_end_sessions': [
        jsonEncode({
          'practice_session_id': 'ps-band',
          'slow_band_ms': 9000,
        }),
      ],
    });
    final queue = AttemptQueue();
    await queue.add(
      'ps-band',
      const PracticeAttempt(
        problemIndex: 0,
        problem: {'a': 1, 'b': 1},
        answer: '2',
        wasCorrect: true,
        responseMs: 900,
        errorCode: null,
      ),
    );

    var endCalls = 0;
    int? sentBand;
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/practice-session/sync')) {
        return http.Response(jsonEncode({}), 200);
      }
      endCalls++;
      sentBand =
          (jsonDecode(req.body) as Map<String, dynamic>)['slow_band_ms'] as int?;
      return http.Response(
        jsonEncode({
          'skill_mastered': true,
          'slow_flag': false,
          'unlocked_skill_ids': <String>[],
        }),
        200,
      );
    });

    final service = LearningPathService(client: client, queue: queue);
    await service.recoverPendingSessions('tok');

    expect(endCalls, 1);
    expect(sentBand, 9000,
        reason: 'the session is re-ended with its own stored level band');
    expect(await service.pendingEndSessions(), isEmpty);
  });
}
