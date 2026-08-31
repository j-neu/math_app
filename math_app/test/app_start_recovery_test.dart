import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/main.dart';
import 'package:math_app/services/app_start_recovery.dart';
import 'package:math_app/services/attempt_queue.dart';
import 'package:math_app/services/learning_path_service.dart';
import 'package:math_app/services/student_auth_service.dart';

/// A MockClient backend that answers `/sync` successfully and counts `/end`
/// calls (optionally failing them).
class _EndBackend {
  int endCalls = 0;
  bool failEnd = false;

  late final http.Client client = MockClient((request) async {
    if (request.url.path.endsWith('/practice-session/sync')) {
      return http.Response(jsonEncode({}), 200);
    }
    if (request.url.path.endsWith('/practice-session/end')) {
      endCalls++;
      if (failEnd) throw const SocketException('offline');
      return http.Response(
        jsonEncode({
          'skill_mastered': true,
          'slow_flag': false,
          'unlocked_skill_ids': <String>[],
        }),
        200,
      );
    }
    return http.Response('not found', 404);
  });
}

const _pendingKey = 'learning_path_pending_end_sessions';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('maybeRecoverPendingSessions', () {
    test('no stored token is a no-op: /end is never called', () async {
      final backend = _EndBackend();
      final service = LearningPathService(client: backend.client);

      await maybeRecoverPendingSessions(
        StudentAuthService(client: backend.client),
        service,
      );

      expect(backend.endCalls, 0);
    });

    test(
        'a stored token with a pending session flushes and closes it exactly '
        'once, then clears the pending list', () async {
      SharedPreferences.setMockInitialValues({
        'student_token': 'tok',
        _pendingKey: ['ps-stranded'],
      });
      final queue = AttemptQueue();
      await queue.add(
        'ps-stranded',
        const PracticeAttempt(
          problemIndex: 0,
          problem: {'a': 2, 'b': 3},
          answer: '5',
          wasCorrect: true,
          responseMs: 900,
          errorCode: null,
        ),
      );
      final backend = _EndBackend();
      final service = LearningPathService(client: backend.client, queue: queue);

      await maybeRecoverPendingSessions(
        StudentAuthService(client: backend.client),
        service,
      );

      expect(backend.endCalls, 1, reason: 'the /end call is made exactly once');
      expect(await service.pendingEndSessions(), isEmpty,
          reason: 'the recovered session leaves the pending list');
      expect(await queue.pending('ps-stranded'), isEmpty,
          reason: 'the queued attempt is flushed to the server');
    });

    test('a failure is silent: /end stays pending and nothing throws',
        () async {
      SharedPreferences.setMockInitialValues({
        'student_token': 'tok',
        _pendingKey: ['ps-offline'],
      });
      final backend = _EndBackend()..failEnd = true;
      final service = LearningPathService(client: backend.client);

      await maybeRecoverPendingSessions(
        StudentAuthService(client: backend.client),
        service,
      );

      expect(backend.endCalls, 1);
      expect(
        (await service.pendingEndSessions()).map((s) => s.practiceSessionId),
        ['ps-offline'],
        reason: 'an unrecoverable session stays pending for the next run',
      );
    });

    test('uses the band stored with the pending session for the /end call',
        () async {
      SharedPreferences.setMockInitialValues({
        'student_token': 'tok',
        _pendingKey: [
          jsonEncode({
            'practice_session_id': 'ps-band',
            'slow_band_ms': 9000,
          }),
        ],
      });
      int? sentSlowBandMs;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/practice-session/sync')) {
          return http.Response(jsonEncode({}), 200);
        }
        if (request.url.path.endsWith('/practice-session/end')) {
          sentSlowBandMs =
              (jsonDecode(request.body) as Map<String, dynamic>)['slow_band_ms']
                  as int?;
          return http.Response(
            jsonEncode({
              'skill_mastered': true,
              'slow_flag': false,
              'unlocked_skill_ids': <String>[],
            }),
            200,
          );
        }
        return http.Response('not found', 404);
      });

      await maybeRecoverPendingSessions(
        StudentAuthService(client: client),
        LearningPathService(client: client),
      );

      expect(sentSlowBandMs, 9000,
          reason: 'the stored level band, not a hard-coded constant, is used');
    });

    test('a legacy pending entry without a band falls back to 7000 ms',
        () async {
      SharedPreferences.setMockInitialValues({
        'student_token': 'tok',
        _pendingKey: ['ps-legacy'],
      });
      int? sentSlowBandMs;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/practice-session/sync')) {
          return http.Response(jsonEncode({}), 200);
        }
        if (request.url.path.endsWith('/practice-session/end')) {
          sentSlowBandMs =
              (jsonDecode(request.body) as Map<String, dynamic>)['slow_band_ms']
                  as int?;
          return http.Response(
            jsonEncode({
              'skill_mastered': true,
              'slow_flag': false,
              'unlocked_skill_ids': <String>[],
            }),
            200,
          );
        }
        return http.Response('not found', 404);
      });

      await maybeRecoverPendingSessions(
        StudentAuthService(client: client),
        LearningPathService(client: client),
      );

      expect(sentSlowBandMs, LearningPathService.defaultSlowBandMs);
    });
  });

  testWidgets(
      'app shell fires recovery after the first frame when a token is stored',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'student_token': 'tok',
      'student_name': 'Mia',
      _pendingKey: ['ps-shell'],
    });
    final backend = _EndBackend();
    final service = LearningPathService(client: backend.client);

    await tester.pumpWidget(MyApp(
      authService: StudentAuthService(client: backend.client),
      learningPathService: service,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Wer lernt heute?'), findsOneWidget,
        reason: 'the app shell still boots to the profile selection screen');
    expect(backend.endCalls, 1,
        reason: 'the shell recovers the pending session once');
    expect(await service.pendingEndSessions(), isEmpty);
  });
}
