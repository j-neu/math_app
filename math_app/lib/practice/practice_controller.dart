/// Session orchestration for one practice run (P2 plan §6).
///
/// Owns the full lifecycle of a session: `start()` calls
/// `LearningPathService.startPractice` and generates the deterministic
/// problem list from the server seed; `submit()` evaluates each answer via
/// the [TemplateEvaluator] and records the attempt (offline-safe through the
/// attempt queue); `finish()` closes the session and exposes the mastery
/// verdict. The UI drives the timing between problems — the controller has
/// no internal timers, only a per-problem [Stopwatch] so the response time
/// lands in the attempt record.
library;

import 'package:flutter/foundation.dart';

import '../models/problem.dart';
import '../models/skill_spec.dart';
import '../services/attempt_queue.dart';
import '../services/learning_path_service.dart';
import 'problem_generators.dart';
import 'template_evaluator.dart';

/// Lifecycle states of a practice session.
enum PracticeState {
  /// `start()` is in flight (or not yet called).
  starting,

  /// A problem is on screen and awaiting an answer.
  ready,

  /// An answer was submitted and is being recorded.
  submitting,

  /// The last submitted answer was correct.
  correct,

  /// The last submitted answer was wrong (hint available via [hintDe]).
  incorrect,

  /// Every problem has been shown; [finish] has the mastery verdict.
  finished,

  /// A network/start/end failure — [errorMessage] holds a child-friendly
  /// German message and the session can be retried.
  failed,
}

/// The mastery verdict from the server after [finish].
typedef MasteryResult = ({bool mastered, bool slowFlag, List<String> unlocked});

/// Orchestrates one practice session (P2 plan §6, task 6).
///
/// Testable with an injected [LearningPathService] backed by a
/// `http.testing.MockClient`. The [PracticeController] is timer-less: the
/// screen waits out the feedback delay and then calls [advance].
class PracticeController extends ChangeNotifier {
  final String token;
  final SkillSpec spec;
  final int level;
  final LearningPathService service;
  final TemplateEvaluator _evaluator;

  PracticeState _state = PracticeState.starting;
  List<Problem> _problems = const [];
  int _problemIndex = 0;
  AnswerEvaluation? _lastEvaluation;
  MasteryResult? _masteryResult;
  String? _errorMessage;
  String? _sessionId;

  final Stopwatch _stopwatch = Stopwatch();

  PracticeController({
    required this.token,
    required this.spec,
    required this.level,
    LearningPathService? service,
    TemplateEvaluator? evaluator,
  }) : service = service ?? LearningPathService(),
       _evaluator = evaluator ?? TemplateEvaluator();

  PracticeState get state => _state;

  Problem? get currentProblem =>
      _problems.isEmpty || _problemIndex >= _problems.length
          ? null
          : _problems[_problemIndex];

  int get problemIndex => _problemIndex;

  int get problemCount => _problems.length;

  AnswerEvaluation? get lastEvaluation => _lastEvaluation;

  MasteryResult? get masteryResult => _masteryResult;

  String? get errorMessage => _errorMessage;

  /// The encouraging hint for the last wrong answer, drawn from the spec's
  /// error taxonomy. Null when the last answer was correct.
  String? get hintDe {
    final code = _lastEvaluation?.errorCode;
    if (code == null) return null;
    for (final rule in spec.errorTaxonomy) {
      if (rule.code == code) return rule.hintDe;
    }
    return null;
  }

  /// Starts the session: asks the server for a session id + seed, generates
  /// the deterministic problem list and shows the first problem. Safe to
  /// call again after a [PracticeState.failed] start.
  Future<void> start() async {
    _state = PracticeState.starting;
    _errorMessage = null;
    notifyListeners();
    try {
      final session = await service.startPractice(
        token,
        skillId: spec.skillId,
        level: level,
      );
      _sessionId = session.practiceSessionId;
      _problems = generateProblems(
        spec: spec,
        level: level,
        seed: session.seed,
      );
      _problemIndex = 0;
      _lastEvaluation = null;
      _stopwatch
        ..reset()
        ..start();
      _state = PracticeState.ready;
    } on LearningPathException catch (e) {
      _errorMessage = e.message;
      _state = PracticeState.failed;
    } catch (_) {
      _errorMessage =
          'Die Übung konnte nicht geladen werden. Bitte noch einmal versuchen.';
      _state = PracticeState.failed;
    }
    notifyListeners();
  }

  /// Evaluates [value] against the current problem, records the attempt and
  /// flips the state to [PracticeState.correct] / [PracticeState.incorrect].
  ///
  /// The attempt is recorded through the service's offline-safe queue; a
  /// network failure during recording is silent by design — the attempt is
  /// already persisted locally and a later flush delivers it, so the session
  /// never crashes mid-answer.
  Future<void> submit(String value) async {
    final problem = currentProblem;
    if (problem == null || _sessionId == null) return;

    _stopwatch.stop();
    final responseMs = _stopwatch.elapsedMilliseconds;
    _state = PracticeState.submitting;
    notifyListeners();

    final evaluation = _evaluator.evaluate(problem, value, spec: spec);
    _lastEvaluation = evaluation;

    final attempt = PracticeAttempt(
      problemIndex: _problemIndex,
      problem: problem.toJson(),
      answer: evaluation.canonicalAnswer,
      wasCorrect: evaluation.isCorrect,
      responseMs: responseMs,
      errorCode: evaluation.isCorrect ? null : evaluation.errorCode,
    );

    try {
      await service.recordAttempt(token, _sessionId!, attempt);
    } catch (_) {
      // The attempt sits in the queue already; a dropped connection must
      // never end the session.
    }

    _state = evaluation.isCorrect
        ? PracticeState.correct
        : PracticeState.incorrect;
    notifyListeners();
  }

  /// Moves to the next problem, or to [PracticeState.finished] after the
  /// last one. The screen calls this after the feedback delay.
  void advance() {
    if (_problems.isEmpty) return;
    if (_problemIndex + 1 < _problems.length) {
      _problemIndex++;
      _lastEvaluation = null;
      _stopwatch
        ..reset()
        ..start();
      _state = PracticeState.ready;
    } else {
      _state = PracticeState.finished;
    }
    notifyListeners();
  }

  /// Closes the session: flushes anything still queued and tells the server
  /// to compute mastery, exposing the result in [masteryResult]. A failure
  /// surfaces as [PracticeState.failed] with a child-friendly German
  /// [errorMessage]; the session stays pending for recovery and [finish] can
  /// be called again.
  Future<void> finish() async {
    if (_masteryResult != null) return;
    try {
      _masteryResult = await service.endPractice(
        token,
        _sessionId ?? '',
        slowBandMs: spec.levelSpec(level).slowBandMs,
      );
      _state = PracticeState.finished;
    } on LearningPathException catch (e) {
      _errorMessage = e.message;
      _state = PracticeState.failed;
    } catch (_) {
      _errorMessage =
          'Deine Antworten sind noch nicht angekommen. Wir versuchen es '
          'gleich noch einmal.';
      _state = PracticeState.failed;
    }
    notifyListeners();
  }
}
