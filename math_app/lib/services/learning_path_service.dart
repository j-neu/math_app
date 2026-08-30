import 'dart:convert';
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

  Future<LearningPath> fetchPath(String token) async {
    final res = await _client.get(
      Uri.parse('$supabaseFunctionsUrl/learning-path'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw LearningPathException('Lernpfad konnte nicht geladen werden (${res.statusCode})');
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
      throw const LearningPathException('Lernpfad konnte nicht gelesen werden.');
    }
  }

  Future<({String practiceSessionId, int seed})> startPractice(
    String token, {
    required String skillId,
    required int level,
  }) async {
    final res = await _client.post(
      Uri.parse('$supabaseFunctionsUrl/practice-session/start'),
      headers: _headers(token),
      body: jsonEncode({'skill_id': skillId, 'level': level}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw LearningPathException(body['error'] as String? ?? 'Übung konnte nicht gestartet werden');
    }
    return (
      practiceSessionId: body['practice_session_id'] as String,
      seed: body['seed'] as int,
    );
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
    // Last chance to deliver anything still queued before we score the session.
    await _queue.flush(practiceSessionId, (batch) async {
      final res = await _client.post(
        Uri.parse('$supabaseFunctionsUrl/practice-session/sync'),
        headers: _headers(token),
        body: jsonEncode({
          'practice_session_id': practiceSessionId,
          'attempts': batch.map((a) => a.toJson()).toList(),
        }),
      );
      return res.statusCode == 200;
    });

    final res = await _client.post(
      Uri.parse('$supabaseFunctionsUrl/practice-session/end'),
      headers: _headers(token),
      body: jsonEncode({
        'practice_session_id': practiceSessionId,
        'slow_band_ms': slowBandMs,
      }),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw LearningPathException(body['error'] as String? ?? 'Übung konnte nicht abgeschlossen werden');
    }
    return (
      mastered: body['skill_mastered'] as bool? ?? false,
      slowFlag: body['slow_flag'] as bool? ?? false,
      unlocked: ((body['unlocked_skill_ids'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }
}
