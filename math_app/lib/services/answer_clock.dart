/// Measures how long a child takes to answer one diagnostic question.
/// Starts on whichever happens first: the question audio finishing, or the
/// child starting to type. There is no budget and nothing fires — the time
/// is recorded for the teacher only (spec 2026-10-22 §1).
class AnswerClock {
  final DateTime Function() _now;
  DateTime? _startedAt;
  DateTime? _stoppedAt;

  AnswerClock({DateTime Function()? now}) : _now = now ?? DateTime.now;

  bool get started => _startedAt != null;

  void startIfIdle() {
    _startedAt ??= _now();
  }

  void stop() {
    if (_startedAt != null) _stoppedAt ??= _now();
  }

  Duration get elapsed {
    final start = _startedAt;
    if (start == null) return Duration.zero;
    return (_stoppedAt ?? _now()).difference(start);
  }
}
