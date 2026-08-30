import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

/// One answered practice problem, held locally until the server confirms it.
class PracticeAttempt {
  final int problemIndex;
  final Map<String, dynamic> problem;
  final String? answer;
  final bool wasCorrect;
  final int? responseMs;
  final String? errorCode;

  const PracticeAttempt({
    required this.problemIndex,
    required this.problem,
    required this.answer,
    required this.wasCorrect,
    required this.responseMs,
    required this.errorCode,
  });

  Map<String, dynamic> toJson() => {
        'problem_index': problemIndex,
        'problem': problem,
        'answer': answer,
        'was_correct': wasCorrect,
        'response_ms': responseMs,
        'error_code': errorCode,
      };

  factory PracticeAttempt.fromJson(Map<String, dynamic> j) => PracticeAttempt(
        problemIndex: j['problem_index'] as int,
        problem: (j['problem'] as Map).cast<String, dynamic>(),
        answer: j['answer'] as String?,
        wasCorrect: j['was_correct'] as bool? ?? false,
        responseMs: j['response_ms'] as int?,
        errorCode: j['error_code'] as String?,
      );
}

/// Buffers attempts on the device so a dropped connection never costs a
/// child their work. Flushes are idempotent server-side on problem_index,
/// so a retry after an ambiguous failure is safe.
///
/// Mutating operations ([add], [flush], [clear]) are serialised per queue
/// key with [Lock]s from `package:synchronized`, so two concurrent calls for
/// the same practice session can never clobber each other's read-modify-write
/// cycle. Locks are keyed per session (not one global lock) so two different
/// children's sessions never block each other.
class AttemptQueue {
  static const _prefix = 'attempt_queue_';

  // One lock per storage key, shared across all AttemptQueue instances (the
  // underlying SharedPreferences store is itself a singleton), so unrelated
  // sessions never contend for the same lock.
  static final Map<String, Lock> _locks = {};

  String _key(String practiceSessionId) => '$_prefix$practiceSessionId';

  Lock _lockFor(String key) => _locks.putIfAbsent(key, () => Lock());

  /// Reads and decodes the attempts stored under [key]. A corrupted or
  /// unparsable entry is treated as an empty queue rather than thrown —
  /// losing one bad batch is far better than bricking the queue forever,
  /// since every other queue operation funnels through this read.
  List<PracticeAttempt> _readAttempts(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => PracticeAttempt.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (e, st) {
      developer.log(
        'AttemptQueue: corrupt data under "$key", treating as empty.',
        name: 'AttemptQueue',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<void> add(String practiceSessionId, PracticeAttempt attempt) async {
    final key = _key(practiceSessionId);
    await _lockFor(key).synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      final current = _readAttempts(prefs, key);
      if (current.any((a) => a.problemIndex == attempt.problemIndex)) return;
      current.add(attempt);
      await prefs.setString(
        key,
        jsonEncode(current.map((a) => a.toJson()).toList()),
      );
    });
  }

  Future<List<PracticeAttempt>> pending(String practiceSessionId) async {
    final prefs = await SharedPreferences.getInstance();
    return _readAttempts(prefs, _key(practiceSessionId));
  }

  /// Sends everything pending via [send]. Returns the number of attempts
  /// accepted; keeps the queue intact when [send] reports failure.
  Future<int> flush(
    String practiceSessionId,
    Future<bool> Function(List<PracticeAttempt>) send,
  ) async {
    final key = _key(practiceSessionId);
    return _lockFor(key).synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      final batch = _readAttempts(prefs, key);
      if (batch.isEmpty) return 0;
      final ok = await send(batch);
      if (!ok) return 0;
      await prefs.remove(key);
      return batch.length;
    });
  }

  Future<void> clear(String practiceSessionId) async {
    final key = _key(practiceSessionId);
    await _lockFor(key).synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    });
  }
}
