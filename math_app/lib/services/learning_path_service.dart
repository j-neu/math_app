import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
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
  static const _sessionNotFinishedMessage =
      'Deine Antworten sind noch nicht angekommen. Wir versuchen es gleich noch einmal.';

  // Practice sessions whose final flush and/or /end call did not succeed
  // yet, stored durably so a later app run can find and retry them — see
  // recoverPendingSessions(). Each entry is a JSON object
  // {"practice_session_id": …, "slow_band_ms": …} so recovery can re-end the
  // session with the level band it originally used. One shared key/lock is
  // fine: this list is small (a handful of stranded sessions at most) and
  // writes to it are rare compared to attempt_queue traffic.
  static const _pendingEndSessionsKey = 'learning_path_pending_end_sessions';

  /// Slow band used when a pending session has no stored band (legacy entries
  /// persisted before the band was recorded, or malformed ones).
  static const int defaultSlowBandMs = 7000;
  static final Lock _pendingSessionsLock = Lock();

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

  /// Ends a practice session: flushes anything still queued, then tells the
  /// server the session is over so it can compute mastery/unlock from the
  /// full set of attempts.
  ///
  /// If the final flush does not fully succeed, this does NOT call `/end`.
  /// Closing the session on incomplete data would let the server compute
  /// mastery from a partial attempt set, and the unsent attempt would sit
  /// in local storage forever — nothing else ever revisits an old
  /// [practiceSessionId]. Instead the session id is recorded durably (so a
  /// later run can retry it — see [recoverPendingSessions]) and this
  /// throws a [LearningPathException] so the caller knows the session is
  /// still open.
  ///
  /// The same applies if the flush succeeds but the `/end` call itself
  /// then fails (network error or bad status): the session is recorded
  /// pending so recovery retries the `/end` call later.
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

    final stillQueued = await _queue.pending(practiceSessionId);
    if (stillQueued.isNotEmpty) {
      // The flush above didn't fully succeed. Never call /end on
      // incomplete data — keep the session open and remember it for
      // recovery instead.
      await _markSessionPending(practiceSessionId, slowBandMs);
      throw const LearningPathException(_sessionNotFinishedMessage);
    }

    try {
      final result = await _callEnd(token, practiceSessionId, slowBandMs);
      await _clearPendingSession(practiceSessionId);
      return result;
    } catch (_) {
      // The flush succeeded but /end itself failed (network error or bad
      // status) — the server was never told to close the session. Keep it
      // pending so recoverPendingSessions retries the /end call later.
      await _markSessionPending(practiceSessionId, slowBandMs);
      rethrow;
    }
  }

  Future<({bool mastered, bool slowFlag, List<String> unlocked})> _callEnd(
    String token,
    String practiceSessionId,
    int slowBandMs,
  ) async {
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
          result.body['error'] as String? ?? _sessionNotFinishedMessage);
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

  Future<void> _markSessionPending(
    String practiceSessionId,
    int slowBandMs,
  ) async {
    await _pendingSessionsLock.synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_pendingEndSessionsKey) ?? <String>[];
      final entry = jsonEncode({
        'practice_session_id': practiceSessionId,
        'slow_band_ms': slowBandMs,
      });
      if (!list.any((e) => _sessionIdOf(e) == practiceSessionId)) {
        await prefs.setStringList(_pendingEndSessionsKey, [...list, entry]);
      }
    });
  }

  Future<void> _clearPendingSession(String practiceSessionId) async {
    await _pendingSessionsLock.synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_pendingEndSessionsKey) ?? <String>[];
      await prefs.setStringList(
        _pendingEndSessionsKey,
        list.where((e) => _sessionIdOf(e) != practiceSessionId).toList(),
      );
    });
  }

  /// The session id of one pending entry, tolerant of the legacy plain-id
  /// form ("ps-…") that predates the JSON shape.
  static String _sessionIdOf(String entry) {
    try {
      final decoded = jsonDecode(entry);
      if (decoded is Map<String, dynamic> &&
          decoded['practice_session_id'] is String) {
        return decoded['practice_session_id'] as String;
      }
    } catch (_) {
      // fall through to the legacy form
    }
    return entry;
  }

  /// The slow band of one pending entry: the stored band when present,
  /// [defaultSlowBandMs] for legacy/malformed entries (the band was not
  /// persisted back then).
  static int _slowBandOf(String entry) {
    try {
      final decoded = jsonDecode(entry);
      if (decoded is Map<String, dynamic> &&
          decoded['slow_band_ms'] is int) {
        return decoded['slow_band_ms'] as int;
      }
    } catch (_) {
      // fall through
    }
    return defaultSlowBandMs;
  }

  /// Practice sessions that were flushed but never confirmed closed with
  /// the server. Exposed for diagnostics/tests and for a "wird noch
  /// gespeichert" indicator, should P2 want one.
  Future<List<({String practiceSessionId, int slowBandMs})>>
  pendingEndSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(_pendingEndSessionsKey) ?? <String>[];
    return [
      for (final entry in entries)
        (practiceSessionId: _sessionIdOf(entry), slowBandMs: _slowBandOf(entry)),
    ];
  }

  /// Retries every practice session left pending by a previous run — most
  /// likely because the connection dropped between the child's last
  /// answer and the server being told the session was over (see
  /// [endPractice]). For each one this re-attempts the flush (a harmless
  /// no-op if everything already synced, since `/sync` is an idempotent
  /// upsert on (practice_session_id, problem_index)) and then calls
  /// `/end` — with the session's own stored level band, so the recovered
  /// session keeps the same "slow" threshold it was ended under. A session
  /// is removed from the pending list only once `/end` actually succeeds,
  /// so this is safe to call as often as needed — repeated calls neither
  /// duplicate nor lose anything, and a session that still can't complete
  /// (offline, server down, ...) simply stays pending for the next call.
  ///
  /// P2 MUST call this — at app start, and ideally again on reconnect.
  /// Nothing else ever revisits an old practiceSessionId, so a session
  /// left pending here stays stranded until something calls this.
  Future<void> recoverPendingSessions(String token) async {
    final sessions = await pendingEndSessions();
    for (final session in sessions) {
      try {
        await endPractice(
          token,
          session.practiceSessionId,
          slowBandMs: session.slowBandMs,
        );
      } catch (_) {
        // Still not recoverable this run; stays in the pending list so the
        // next call retries it.
      }
    }
  }
}
