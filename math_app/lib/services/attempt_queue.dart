import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
class AttemptQueue {
  static const _prefix = 'attempt_queue_';

  String _key(String practiceSessionId) => '$_prefix$practiceSessionId';

  Future<void> add(String practiceSessionId, PracticeAttempt attempt) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await pending(practiceSessionId);
    if (current.any((a) => a.problemIndex == attempt.problemIndex)) return;
    current.add(attempt);
    await prefs.setString(
      _key(practiceSessionId),
      jsonEncode(current.map((a) => a.toJson()).toList()),
    );
  }

  Future<List<PracticeAttempt>> pending(String practiceSessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(practiceSessionId));
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => PracticeAttempt.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Sends everything pending via [send]. Returns the number of attempts
  /// accepted; keeps the queue intact when [send] reports failure.
  Future<int> flush(
    String practiceSessionId,
    Future<bool> Function(List<PracticeAttempt>) send,
  ) async {
    final batch = await pending(practiceSessionId);
    if (batch.isEmpty) return 0;
    final ok = await send(batch);
    if (!ok) return 0;
    await clear(practiceSessionId);
    return batch.length;
  }

  Future<void> clear(String practiceSessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(practiceSessionId));
  }
}
