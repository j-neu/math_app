import 'dart:async';
import 'package:flutter/foundation.dart' show VoidCallback;

/// A wall-clock response timer that can be paused and resumed without
/// losing the time already spent — used so opening the diagnostic's Hilfe
/// panel doesn't count against the response-time budget (usability rework
/// §4.9). [now] is injectable so tests can drive a fake clock in lockstep
/// with a virtualized [Timer]; production code omits it and gets
/// [DateTime.now].
class PausableTimeout {
  Duration _budget;
  final VoidCallback onTimeout;
  final DateTime Function() _now;

  DateTime? _startedAt;
  Duration _pausedTotal = Duration.zero;
  DateTime? _pausedAt;
  Timer? _timer;

  PausableTimeout({
    required Duration budget,
    required this.onTimeout,
    DateTime Function()? now,
  })  : _budget = budget,
        _now = now ?? DateTime.now;

  Duration get budget => _budget;

  /// Starts (or restarts) the budget from zero.
  void start() {
    _startedAt = _now();
    _pausedTotal = Duration.zero;
    _pausedAt = null;
    _armTimer(_budget);
  }

  /// Stops the countdown; [elapsed] freezes until [resume].
  void pause() {
    if (_pausedAt != null) return;
    _timer?.cancel();
    _pausedAt = _now();
  }

  /// Resumes counting down the remainder of [budget].
  void resume() {
    if (_pausedAt == null) return;
    _pausedTotal += _now().difference(_pausedAt!);
    _pausedAt = null;
    final remaining = _budget - elapsed;
    _armTimer(remaining.isNegative ? Duration.zero : remaining);
  }

  /// Grants [extra] additional time on top of the current budget without
  /// resetting [_startedAt]/[_pausedTotal] — unlike [start], [elapsed] keeps
  /// counting from the original start. Used when a timeout popup's "try
  /// again" choice should give more time without wiping out the time
  /// already spent (that time is still real response-time data).
  void extend(Duration extra) {
    _budget += extra;
    final remaining = _budget - elapsed;
    _armTimer(remaining.isNegative ? Duration.zero : remaining);
  }

  /// Stops the timer permanently (the question was answered/skipped).
  void cancel() {
    _timer?.cancel();
  }

  void _armTimer(Duration duration) {
    _timer?.cancel();
    _timer = Timer(duration, onTimeout);
  }

  /// Unpaused wall-clock time elapsed since [start].
  Duration get elapsed {
    if (_startedAt == null) return Duration.zero;
    final raw = _now().difference(_startedAt!);
    final pausedSoFar = _pausedAt != null
        ? _pausedTotal + _now().difference(_pausedAt!)
        : _pausedTotal;
    final net = raw - pausedSoFar;
    return net.isNegative ? Duration.zero : net;
  }
}
