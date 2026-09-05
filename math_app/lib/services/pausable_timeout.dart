import 'dart:async';
import 'package:flutter/foundation.dart' show VoidCallback;

/// A wall-clock response timer that can be paused and resumed without
/// losing the time already spent — used so opening the diagnostic's Hilfe
/// panel doesn't count against the response-time budget (usability rework
/// §4.9). [now] is injectable so tests can drive a fake clock in lockstep
/// with a virtualized [Timer]; production code omits it and gets
/// [DateTime.now].
class PausableTimeout {
  final Duration budget;
  final VoidCallback onTimeout;
  final DateTime Function() _now;

  DateTime? _startedAt;
  Duration _pausedTotal = Duration.zero;
  DateTime? _pausedAt;
  Timer? _timer;

  PausableTimeout({
    required this.budget,
    required this.onTimeout,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Starts (or restarts) the budget from zero.
  void start() {
    _startedAt = _now();
    _pausedTotal = Duration.zero;
    _pausedAt = null;
    _armTimer(budget);
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
    final remaining = budget - elapsed;
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
