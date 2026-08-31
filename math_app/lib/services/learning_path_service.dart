import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/learning_path.dart';
import 'attempt_queue.dart';
import 'supabase_config.dart';

/// Raised when the learning-path service cannot do its job — a failed
/// request, a bad status code, or a payload that does not parse into a
/// [LearningPath]. Always carries a German message safe to show a child
/// or teacher.
class LearningPathException implements Exception {
  final String message;
  const LearningPathException(this.message);
  @override
  String toString() => message;
}

class LearningPathService {
  static const _connectionErrorMessage =
      'Verbindung zum Server nicht möglich. Bitte Internetverbindung prüfen.';
  static const _unreadableResponseMessage =
      'Antwort vom Server konnte nicht gelesen werden.';
  static const _pathLoadFailedMessage = 'Lernpfad konnte nicht geladen werden.';

  final http.Client _client;
  final AttemptQueue _queue;

  LearningPathService({http.Client? client, AttemptQueue? queue})
      : _client = client ?? http.Client(),
        _queue = queue ?? AttemptQueue();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $supabaseAnonKey',
        'apikey': supabaseAnonKey,
        'x-student-token': token,
      };

  /// Runs [request] and always comes back with a status code and a decoded
  /// body, never a raw exception: a network failure (dropped wifi, DNS,
  /// timeout, ...) becomes a typed, German-messaged [LearningPathException],
  /// and a non-JSON body (an HTML captive-portal or proxy error page — both
  /// common on school wifi) decodes to an empty map instead of throwing a
  /// raw [FormatException]. This also fixes the ordering bug where decoding
  /// used to run before the status check, so a non-JSON error response
  /// crashed before its HTTP failure was ever reported.
  Future<({Map<String, dynamic> body, int statusCode})> _send(
    Future<http.Response> Function() request,
  ) async {
    late http.Response res;
    try {
      res = await request();
    } catch (_) {
      throw const LearningPathException(_connectionErrorMessage);
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      body = const {};
    }

    return (body: body, statusCode: res.statusCode);
  }

  Future<LearningPath> fetchPath(String token) async {
    late http.Response res;
    try {
      res = await _client.get(
        Uri.parse('$supabaseFunctionsUrl/learning-path'),
        headers: _headers(token),
      );
    } catch (_) {
      throw const LearningPathException(_connectionErrorMessage);
    }

    if (res.statusCode != 200) {
      // The raw HTTP status code must never reach the child. It's only
      // useful for diagnostics, so it goes to the log, not the message.
      developer.log(
        'LearningPathService.fetchPath failed with status ${res.statusCode}',
        name: 'LearningPathService',
      );
      throw const LearningPathException(_pathLoadFailedMessage);
    }

    // LearningPath.fromJson/PathItem.fromJson throw a raw TypeError on a
    // malformed field (e.g. skill_id not a String), and a single bad item
    // would otherwise abort with an untyped exception. Wrap it so the
    // caller always gets a clean, German-messaged, typed failure instead —
    // and so a parse failure never leaves a half-built path in flight.
    try {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      return LearningPath.fromJson(decoded);
    } on LearningPathException {
      rethrow;
    } catch (_) {
      throw const LearningPathException(_unreadableResponseMessage);
    }
  }

  Future<({String practiceSessionId, int seed})> startPractice(
    String token, {
    required String skillId,
    required int level,
  }) async {
    final result = await _send(() => _client.post(
          Uri.parse('$supabaseFunctionsUrl/practice-session/start'),
          headers: _headers(token),
          body: jsonEncode({'skill_id': skillId, 'level': level}),
        ));

    if (result.statusCode != 200) {
      throw LearningPathException(
          result.body['error'] as String? ?? 'Übung konnte nicht gestartet werden');
    }

    try {
      return (
        practiceSessionId: result.body['practice_session_id'] as String,
        seed: result.body['seed'] as int,
      );
    } catch (_) {
      throw const LearningPathException(_unreadableResponseMessage);
    }
  }

  /// Records an attempt locally, then tries to flush. A failed flush is
  /// silent: the queue keeps the work and the next call retries.
  Future<void> recordAttempt(
    String token,
    String practiceSessionId,
    PracticeAttempt attempt,
  ) async {
    await _queue.add(practiceSessionId, attempt);
    await _queue.flush(practiceSessionId, (batch) async {
      try {
        final res = await _client.post(
          Uri.parse('$supabaseFunctionsUrl/practice-session/sync'),
          headers: _headers(token),
          body: jsonEncode({
            'practice_session_id': practiceSessionId,
            'attempts': batch.map((a) => a.toJson()).toList(),
          }),
        );
        return res.statusCode == 200;
      } catch (_) {
        return false;
      }
    });
  }

  Future<({bool mastered, bool slowFlag, List<String> unlocked})> endPractice(
    String token,
    String practiceSessionId, {
    required int slowBandMs,
  }) async {
    // Last chance to deliver anything still queued before we score the
    // session. Structurally identical to recordAttempt's flush callback:
    // a network failure here must return false (keeping the queue intact)
    // rather than throw — this is the exact moment the queue exists to
    // protect, so losing the child's answers here would be the worst time
    // to do it.
    await _queue.flush(practiceSessionId, (batch) async {
      try {
        final res = await _client.post(
          Uri.parse('$supabaseFunctionsUrl/practice-session/sync'),
          headers: _headers(token),
          body: jsonEncode({
            'practice_session_id': practiceSessionId,
            'attempts': batch.map((a) => a.toJson()).toList(),
          }),
        );
        return res.statusCode == 200;
      } catch (_) {
        return false;
      }
    });

    final result = await _send(() => _client.post(
          Uri.parse('$supabaseFunctionsUrl/practice-session/end'),
          headers: _headers(token),
          body: jsonEncode({
            'practice_session_id': practiceSessionId,
            'slow_band_ms': slowBandMs,
          }),
        ));

    if (result.statusCode != 200) {
      throw LearningPathException(
          result.body['error'] as String? ?? 'Übung konnte nicht abgeschlossen werden');
    }

    try {
      return (
        mastered: result.body['skill_mastered'] as bool? ?? false,
        slowFlag: result.body['slow_flag'] as bool? ?? false,
        unlocked: ((result.body['unlocked_skill_ids'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
      );
    } catch (_) {
      throw const LearningPathException(_unreadableResponseMessage);
    }
  }
}
