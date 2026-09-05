import 'dart:async';
import 'dart:io' show File;
import 'dart:math' show max;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:math_app/widgets/manipulatives/fingerbild.dart';
import 'package:math_app/widgets/manipulatives/rekenrek.dart';
import 'package:math_app/widgets/manipulatives/dienes_place_value.dart';
import 'package:math_app/widgets/manipulatives/stellenwerttafel.dart';
import 'package:math_app/widgets/manipulatives/zahlenstrahl.dart';
import 'package:math_app/widgets/manipulatives/zehnerfeld.dart';
import 'package:math_app/widgets/diagnostic_answer_widgets.dart';
import '../models/diagnostic_question.dart';
import '../models/diagnostic_result.dart';
import '../models/diagnostic_session.dart';
import '../models/user_profile.dart';
import '../services/diagnostic_service.dart';
import '../services/diagnostic_shortening.dart';
import '../services/answer_grading.dart';
import '../services/diagnostic_report_generator.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../screens/diagnostic_complete_screen.dart';
import '../screens/diagnostic_report_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

/// One persisted diagnostic result row (web/API mode).
typedef _AnswerRow = ({
  int questionNumber,
  bool wasCorrect,
  double responseTimeSeconds,
  String status,
  String? userAnswer,
});

class DiagnosticScreen extends StatefulWidget {
  final UserProfile userProfile;
  final bool retryMode;
  // When set, answers are posted to the Supabase API instead of (or in addition to)
  // SharedPreferences. Used by the web student client.
  final String? sessionId;
  // When non-null, the diagnostic is being resumed; these results were
  // previously submitted to the server and should be used to hydrate state
  // and skip to the first unanswered question.
  final List<ServerResult>? priorResults;
  // When non-null and retryMode is true, only questions with these list numbers
  // are shown. Returned by the server when a retry ticket is redeemed.
  final List<int>? retryQuestionNumbers;

  const DiagnosticScreen({
    super.key,
    required this.userProfile,
    this.retryMode = false,
    this.sessionId,
    this.priorResults,
    this.retryQuestionNumbers,
  });

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  // Convenience getter — non-null means web/API mode.
  String? get _sessionId => widget.sessionId;

  late Future<List<DiagnosticQuestion>> _questionsFuture;
  int _currentQuestionIndex = 0;
  final Map<int, String> _answers = {}; // To store user's answers
  final List<String> _skillTagsToPractice = []; // To store tags for incorrect answers
  final List<DiagnosticResult> _diagnosticResults = []; // Store full diagnostic session data
  final TextEditingController _textController = TextEditingController();

  // Web-mode save gate: when a result cannot be persisted after bounded
  // retries the child is blocked with a German retry instead of silently
  // advancing past an unsaved answer (see _advanceAfterPersist/_blockSave).
  bool _saveBlocked = false;
  bool _retryingSave = false;
  Future<void> Function()? _retrySave;
  // True while an answer is being persisted/advanced. Guards _nextQuestion
  // against re-entry (a double tap or Enter during a multi-second network
  // stall must not run the submit logic twice on the same question) and
  // drives the disabled-Weiter progress state.
  bool _savingAnswer = false;

  // Timeout and timing tracking (varies by question type)
  DateTime? _questionStartTime;
  Timer? _timeoutTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _audioTempFilePath;

  // Break-off (shortened diagnostic) gate: construct-keyed, difficulty-graded.
  // See ConstructGates in services/diagnostic_shortening.dart for the rule.
  late final ConstructGates _gates;

  @override
  void initState() {
    super.initState();
    _gates = ConstructGates(abbreviated: widget.userProfile.useBreakOffLogic);
    _questionsFuture = _loadQuestions();

    // Only load saved progress if NOT in retry mode
    if (!widget.retryMode) {
      _questionsFuture.then((questions) {
        if (widget.priorResults != null && widget.priorResults!.isNotEmpty) {
          _hydrateFromServer(questions, widget.priorResults!);
        } else {
          _loadDiagnosticProgress(questions);
        }
      });
    }
  }

  /// Populates state from server-side results when a session is resumed,
  /// then advances the index to the first question still to be answered.
  void _hydrateFromServer(
    List<DiagnosticQuestion> questions,
    List<ServerResult> serverResults,
  ) {
    final resultsByListNumber = {
      for (final r in serverResults) r.questionNumber: r,
    };

    // Walk questions in display order. Answered rows are replayed (local
    // result, skill tags, break-off gate state). A question with no server
    // row is either a gate-skipped question whose 'skipped' marker never
    // stored (never presented — skip it), or the next question to ask.
    int firstUnansweredIndex = questions.length;
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final r = resultsByListNumber[q.listNumber];
      if (r == null) {
        if (_gates.shouldSkip(q)) continue;
        firstUnansweredIndex = i;
        break;
      }
      _answers[i] = r.userAnswer ?? '';
      _diagnosticResults.add(DiagnosticResult(
        questionId: q.listNumber.toString(),
        wasCorrect: r.wasCorrect,
        responseTimeSeconds: r.responseTimeSeconds ?? 0,
        status: r.status,
        userAnswer: r.userAnswer,
      ));
      _gates.noteAnswered(q, r.wasCorrect);
      if (!r.wasCorrect) {
        _skillTagsToPractice.addAll(q.ifWrongPracticeSkills);
      }
    }

    setState(() {
      _currentQuestionIndex = firstUnansweredIndex;
    });

    if (_currentQuestionIndex >= questions.length) {
      _processResults(questions);
    }
  }

  Future<List<DiagnosticQuestion>> _loadQuestions() async {
    final allQuestions = await DiagnosticService().loadQuestions();

    if (!widget.retryMode) {
      return allQuestions;
    }

    // Server-driven retry: use question numbers returned by the API.
    if (widget.retryQuestionNumbers != null && widget.retryQuestionNumbers!.isNotEmpty) {
      final numberSet = widget.retryQuestionNumbers!.toSet();
      return allQuestions.where((q) => numberSet.contains(q.listNumber)).toList();
    }

    // Fallback: filter from local diagnostic history (desktop/offline mode).
    if (widget.userProfile.diagnosticHistory.isEmpty) {
      return allQuestions;
    }

    final lastSession = widget.userProfile.diagnosticHistory.last;
    final incorrectIds = lastSession.results
        .where((r) => !r.wasCorrect)
        .map((r) => r.questionId)
        .toSet();

    if (incorrectIds.isEmpty) {
      return allQuestions;
    }

    return allQuestions
        .where((q) => incorrectIds.contains(q.listNumber.toString()))
        .toList();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _textController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Response-time budget for [question]: floor 15 s, else 5 s per answer
  /// box (diagnostic usability rework §4.6) — a multi-box item gets
  /// proportionally more time than a one-number calculation.
  int _timeoutSecondsFor(DiagnosticQuestion question) =>
      max(15, 5 * AnswerGrading.boxCount(question));

  /// Start timer for the current question (runs silently in background)
  void _startQuestionTimer(List<DiagnosticQuestion> questions) {
    if (_currentQuestionIndex >= questions.length) return;
    
    _questionStartTime = DateTime.now();
    _timeoutTimer?.cancel();

    // Determine timeout based on question type
    final question = questions[_currentQuestionIndex];

    if (question.audioAsset != null) {
      _playAudio(question.audioAsset!);
    }

    // Timer that fires after the response-time budget
    _timeoutTimer = Timer(Duration(seconds: _timeoutSecondsFor(question)), () {
      _handleTimeout(questions);
    });
  }

  /// Handle timeout - show popup asking if child wants to skip
  void _handleTimeout(List<DiagnosticQuestion> questions) {
    // Stop the timer so it doesn't keep firing
    _timeoutTimer?.cancel();

    // Show dialog asking if they want to skip
    showDialog(
      context: context,
      barrierDismissible: false, // Must choose an option
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Noch mehr Zeit?'),
          content: const Text('Soll diese Aufgabe übersprungen werden?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Give them more time - restart the timer
                _startQuestionTimer(questions);
              },
              child: const Text('Weiter versuchen'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Skip this question
                _skipCurrentQuestion(questions);
              },
              child: const Text('Überspringen'),
            ),
          ],
        );
      },
    );
  }

  /// Skip the current question due to timeout
  void _skipCurrentQuestion(List<DiagnosticQuestion> questions) {
    // The timeout dialog and the answer field can race: if the child already
    // submitted an answer and the persist is in flight, the guard in
    // _nextQuestion would swallow this skip — but the local 'timeout' row,
    // skill tags and false break-off failure below would already have been
    // applied. Do nothing instead: the submitted answer decides the outcome.
    if (_savingAnswer) return;

    final question = questions[_currentQuestionIndex];
    final responseTime = DateTime.now().difference(_questionStartTime!).inSeconds.toDouble();

    // Record as timeout/skipped
    final result = DiagnosticResult(
      questionId: question.listNumber.toString(),
      wasCorrect: false,
      responseTimeSeconds: responseTime,
      status: 'timeout',
      userAnswer: _textController.text.trim(),
    );

    _diagnosticResults.add(result);
    _skillTagsToPractice.addAll(question.ifWrongPracticeSkills);

    // Update the break-off gate
    _gates.noteAnswered(question, false);

    // Move to next question
    _nextQuestion(questions);
  }

  void _loadDiagnosticProgress(List<DiagnosticQuestion> questions) {
    // Load saved diagnostic progress if it exists
    if (widget.userProfile.diagnosticProgress != null) {
      final savedIndex = widget.userProfile.diagnosticProgress!;
      final savedAnswers = widget.userProfile.diagnosticAnswers;

      if (savedAnswers != null) {
        _answers.addAll(savedAnswers);
        // Reconstruct the in-memory state (results, tags, logic) from the saved answers
        _reconstructStateFromAnswers(questions, savedAnswers, savedIndex);
      }

      setState(() {
        _currentQuestionIndex = savedIndex;
      });

      // If we loaded a state where we are already finished, trigger processing
      if (_currentQuestionIndex >= questions.length) {
        _processResults(questions);
      }
    }
  }

  /// Reconstructs _diagnosticResults, _skillTagsToPractice, and break-off logic
  /// by re-evaluating the saved answers up to the current index.
  void _reconstructStateFromAnswers(
    List<DiagnosticQuestion> questions,
    Map<int, String> savedAnswers,
    int savedIndex,
  ) {
    print('=== Reconstructing Diagnostic State ===');
    _diagnosticResults.clear();
    _skillTagsToPractice.clear();
    _gates.clear();

    // Iterate through all questions up to the saved index
    // Note: We iterate by list index, but we need to handle skipped questions too if logic implies it.
    // However, savedAnswers only contains answers for questions actually attempted (or saved).
    // A simpler approach: Re-simulate the test flow up to savedIndex.

    // Using a loop to simulate the flow
    for (int i = 0; i < savedIndex && i < questions.length; i++) {
      final question = questions[i];
      final userAnswer = savedAnswers[i];

      // If we don't have an answer for 'i', it might have been skipped or we are out of sync.
      // But _nextQuestion logic saves answer (empty string if skipped?). 
      // Actually _skipCurrentQuestion saves 'userAnswer' as controller text, usually empty.
      // But _nextQuestion loop for skipped questions (break-off) adds 'skipped' results.
      
      // For reconstruction, we primarily care about:
      // 1. Identifying failed skills (to build learning path)
      // 2. Break-off logic state (to know if we should skip future questions)

      if (userAnswer != null) {
        final textCorrect = _checkAnswer(question, userAnswer);
        // We don't have response time from saved state, so assume 0.0 or not "too long"
        // This is a limitation: if they failed due to time previously, we might re-evaluate as pass here.
        // But persistent "wasCorrect" isn't saved in UserProfile, only answers.
        // Assuming textCorrect is the main factor for reconstruction.
        final wasCorrect = textCorrect; 

        _gates.noteAnswered(question, wasCorrect);
        if (!wasCorrect) {
          _skillTagsToPractice.addAll(question.ifWrongPracticeSkills);
        }

        // Re-add to results list (simplified)
        _diagnosticResults.add(DiagnosticResult(
          questionId: question.listNumber.toString(),
          wasCorrect: wasCorrect,
          responseTimeSeconds: 0, // Lost data
          status: 'restored',
          userAnswer: userAnswer,
        ));
      } else {
        // No answer found for this index. 
        // It might be a question skipped by break-off logic?
        // If so, we should record it as skipped.
        if (_gates.shouldSkip(question)) {
           _diagnosticResults.add(DiagnosticResult(
            questionId: question.listNumber.toString(),
            wasCorrect: false,
            responseTimeSeconds: 0,
            status: 'skipped',
          ));
        }
      }
    }
    print('=== Reconstruction Complete: ${_skillTagsToPractice.length} tags found ===');
  }

  Future<void> _nextQuestion(List<DiagnosticQuestion> questions) async {
    if (_savingAnswer) return;
    setState(() => _savingAnswer = true);
    try {
      await _nextQuestionInner(questions);
    } finally {
      if (mounted) setState(() => _savingAnswer = false);
    }
  }

  Future<void> _nextQuestionInner(List<DiagnosticQuestion> questions) async {
    // Stop the timer
    _timeoutTimer?.cancel();

    // Calculate response time
    final responseTime = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inSeconds.toDouble()
        : 0.0;

    // Save the answer from the controller
    final userAnswer = _textController.text.trim();
    _answers[_currentQuestionIndex] = userAnswer;

    // Check if answer is correct and record result
    final currentQuestion = questions[_currentQuestionIndex];
    final textCorrect = _checkAnswer(currentQuestion, userAnswer);

    // Determine time threshold based on the item's answer boxes
    final timeThreshold = _timeoutSecondsFor(currentQuestion);

    // Answer is considered FAILED if:
    // 1. Text answer is wrong, OR
    // 2. Response time exceeds threshold (indicates counting/inefficient strategy)
    final tookTooLong = responseTime > timeThreshold;
    final wasCorrect = textCorrect && !tookTooLong;

    // The server's status vocabulary is attempted|skipped|timeout (DB check
    // constraint diagnostic_results_status_check); 'leer' was never accepted
    // and a child pressing Weiter with no answer would 500 and strand on the
    // retry screen. An empty submit means the child did not know — record it
    // as a skip (server side) / leer (native side, where the old vocabulary
    // still applies).
    final answerStatus = userAnswer.isEmpty
        ? (_sessionId != null ? 'skipped' : 'leer')
        : 'attempted';

    final result = DiagnosticResult(
      questionId: currentQuestion.listNumber.toString(),
      wasCorrect: wasCorrect,
      responseTimeSeconds: responseTime,
      status: answerStatus,
      userAnswer: userAnswer,
    );

    _diagnosticResults.add(result);

    // If incorrect OR took too long, add skill tags and update the gate
    _gates.noteAnswered(currentQuestion, wasCorrect);
    if (!wasCorrect) {
      print('=== Question ${currentQuestion.listNumber} FAILED ===');
      print('  - Text correct: $textCorrect');
      print('  - Response time: ${responseTime}s (threshold: ${timeThreshold}s)');
      print('  - Took too long: $tookTooLong');
      print('  - Adding skill tags: ${currentQuestion.ifWrongPracticeSkills}');
      _skillTagsToPractice.addAll(currentQuestion.ifWrongPracticeSkills);
    } else {
      print('=== Question ${currentQuestion.listNumber} PASSED ===');
      print('  - Response time: ${responseTime}s (threshold: ${timeThreshold}s)');
    }

    // Web/API mode: the answer must be persisted to the server BEFORE the
    // child advances. A silently dropped row would leave the session short
    // an answer and the Förderplan would be generated from gaps — and the
    // server's auto-complete only fires when every row is present, so a
    // missing post would also strand the session as in_progress forever.
    // postResult upserts on (session_id, question_id), so retrying after a
    // lost response is safe. If the row still cannot be stored, block here
    // and show the German retry state instead of moving on.
    if (_sessionId != null) {
      final currentRow = (
        questionNumber: currentQuestion.listNumber,
        wasCorrect: wasCorrect,
        responseTimeSeconds: responseTime,
        status: answerStatus,
        userAnswer: userAnswer.isEmpty ? null : userAnswer,
      );
      final advanced = await _advanceAfterPersist(questions, currentRow);
      if (!advanced) return;
    } else {
      // Native mode — original local-only flow below.
      if (_currentQuestionIndex < questions.length - 1) {
        // Find next non-skipped question
        int nextIndex = _currentQuestionIndex + 1;
        while (nextIndex < questions.length && _gates.shouldSkip(questions[nextIndex])) {
          // Mark as skipped
          final skippedResult = DiagnosticResult(
            questionId: questions[nextIndex].listNumber.toString(),
            wasCorrect: false,
            responseTimeSeconds: 0.0,
            status: 'skipped',
          );
          _diagnosticResults.add(skippedResult);

          nextIndex++;
        }

        setState(() {
          _currentQuestionIndex = nextIndex;
          _textController.clear();
        });

        // Start timer for next question if not at end
        if (_currentQuestionIndex < questions.length) {
          _startQuestionTimer(questions);
        }

        await _saveDiagnosticProgress();

        // If we've reached the end, process results
        if (_currentQuestionIndex >= questions.length) {
          _processResults(questions);
        }
      } else {
        // Test is finished, process results
        _processResults(questions);
      }
    }
  }

  /// Web-mode persistence + advance. The just-given answer row must be stored
  /// before the child moves on (hard gate); break-off 'skipped' markers are
  /// best effort (they exist for resume/auto-complete bookkeeping, and a
  /// missing marker must not strand a child who already answered correctly).
  /// Returns true when the UI advanced, false when the answer row could not
  /// be stored after bounded retries and the child is blocked on the German
  /// retry screen.
  Future<bool> _advanceAfterPersist(
    List<DiagnosticQuestion> questions,
    _AnswerRow currentRow,
  ) async {
    final nextIndex = await _persistRowsAndFindNext(questions, currentRow);
    if (nextIndex == null) return false;
    if (!mounted) return false;

    setState(() {
      _currentQuestionIndex = nextIndex;
      _textController.clear();
    });

    if (_currentQuestionIndex < questions.length) {
      _startQuestionTimer(questions);
    } else {
      _processResults(questions);
    }
    return true;
  }

  /// Persists [currentRow] and best-effort 'skipped' markers for every
  /// following break-off-exempt question, returning the index of the next
  /// presented question (or questions.length at the end), or null when the
  /// answer row itself could not be stored after bounded retries.
  Future<int?> _persistRowsAndFindNext(
    List<DiagnosticQuestion> questions,
    _AnswerRow currentRow,
  ) async {
    if (!await _persistRowWithRetry(currentRow)) {
      _blockSave(questions, currentRow);
      return null;
    }

    var nextIndex = _currentQuestionIndex + 1;
    while (nextIndex < questions.length &&
        _gates.shouldSkip(questions[nextIndex])) {
      final skipped = questions[nextIndex];
      // Best effort and single attempt: a failing 'skipped' marker must not
      // lock the child out or stall the run on a dead network — it only
      // exists for resume/auto-complete bookkeeping, and the session is
      // completed server-side by _processResults regardless.
      await _persistRowWithRetry((
        questionNumber: skipped.listNumber,
        wasCorrect: false,
        responseTimeSeconds: 0,
        status: 'skipped',
        userAnswer: null,
      ), maxAttempts: 1);
      nextIndex++;
    }

    // Mirror the walked 'skipped' rows locally. This runs once per advance
    // (advances are serialized by the _nextQuestion guard, and a blocked
    // answer-row failure returns before this point), so entries cannot be
    // double-appended by a retry.
    for (var i = _currentQuestionIndex + 1; i < nextIndex; i++) {
      _diagnosticResults.add(DiagnosticResult(
        questionId: questions[i].listNumber.toString(),
        wasCorrect: false,
        responseTimeSeconds: 0.0,
        status: 'skipped',
      ));
    }
    return nextIndex;
  }

  /// Posts [row], retrying up to [maxAttempts] times. The results endpoint
  /// upserts on (session_id, question_id), so a retry after a lost response
  /// cannot create a duplicate row.
  Future<bool> _persistRowWithRetry(_AnswerRow row,
      {int maxAttempts = 3}) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (attempt > 1) {
        await Future.delayed(Duration(milliseconds: 600 * (attempt - 1)));
      }
      try {
        await ApiService().postResult(
          sessionId: _sessionId!,
          questionNumber: row.questionNumber,
          wasCorrect: row.wasCorrect,
          responseTimeSeconds: row.responseTimeSeconds,
          status: row.status,
          userAnswer: row.userAnswer,
        );
        return true;
      } catch (e) {
        debugPrint('postResult (Q${row.questionNumber}) '
            'attempt $attempt/$maxAttempts failed: $e');
      }
    }
    return false;
  }

  /// Arms the German retry state: the child stays on the current question,
  /// the answer is kept in memory, and [FilledButton] in the question view
  /// re-runs the persistence and advance.
  void _blockSave(List<DiagnosticQuestion> questions, _AnswerRow currentRow) {
    if (!mounted) return;
    _retrySave = () async {
      if (!mounted || _retryingSave || _savingAnswer) return;
      setState(() => _retryingSave = true);
      try {
        final ok = await _advanceAfterPersist(questions, currentRow);
        if (!mounted) return;
        if (ok) setState(() => _saveBlocked = false);
      } finally {
        if (mounted) setState(() => _retryingSave = false);
      }
    };
    setState(() => _saveBlocked = true);
  }

  Future<void> _saveDiagnosticProgress() async {
    print('=== DiagnosticScreen._saveDiagnosticProgress() ===');
    print('  - Current question: $_currentQuestionIndex');
    print('  - Answers saved: ${_answers.length}');

    // Save current progress to user profile
    final updatedProfile = widget.userProfile.copyWith(
      diagnosticProgress: _currentQuestionIndex,
      diagnosticAnswers: Map<int, String>.from(_answers),
    );

    print('  - Updated profile diagnosticProgress: ${updatedProfile.diagnosticProgress}');

    final userService = UserService();
    await userService.saveUser(updatedProfile);
    print('=== DiagnosticScreen - Progress saved ===');
  }

  Future<void> _processResults(List<DiagnosticQuestion> questions) async {
    // Web / API mode: server already has all results; just show the completion screen.
    if (_sessionId != null) {
      setState(() {
        _currentQuestionIndex++;
      });
      // Force-complete the session on the server regardless of whether all
      // individual skip-result posts succeeded (they may have failed silently).
      try {
        await ApiService().completeSession(_sessionId!);
      } catch (e) {
        debugPrint('completeSession failed: $e');
      }
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DiagnosticCompleteScreen()),
      );
      return;
    }

    // Native mode — existing local-storage flow below.

    // De-duplicate skill tags
    final uniqueTags = _skillTagsToPractice.toSet().toList();

    print('=== DIAGNOSTIC TEST COMPLETE ===');
    print('  - Total skill tags to practice: ${_skillTagsToPractice.length}');
    print('  - Unique skill tags: ${uniqueTags.length}');
    print('  - Skill tags: $uniqueTags');

    // Prepare final results
    List<DiagnosticResult> finalResults = [];
    
    if (widget.retryMode && widget.userProfile.diagnosticHistory.isNotEmpty) {
      // Merge: start with results from last session
      final lastResults = widget.userProfile.diagnosticHistory.last.results;
      // Map of questionId -> result
      final resultMap = {for (var r in lastResults) r.questionId: r};
      
      // Overwrite with new results
      for (var r in _diagnosticResults) {
        resultMap[r.questionId] = r;
      }
      
      finalResults = resultMap.values.toList();
      // Sort by question ID numerically to keep order
      finalResults.sort((a, b) => int.parse(a.questionId).compareTo(int.parse(b.questionId)));
    } else {
      finalResults = _diagnosticResults;
    }

    // Create a new diagnostic session with MERGED results
    final session = DiagnosticSession(
      date: DateTime.now(),
      results: finalResults,
      generatedSkillTags: uniqueTags,
    );

    // Update the user profile with the skill tags, diagnostic results, and clear diagnostic progress
    // Also append the new session to the history
    final updatedProfile = widget.userProfile.copyWith(
      skillTags: uniqueTags,
      diagnosticResults: finalResults,
      diagnosticHistory: [...widget.userProfile.diagnosticHistory, session],
      clearDiagnosticProgress: true, // Clear progress since test is complete
    );

    // Save the updated profile to persistent storage
    final userService = UserService();
    await userService.saveUser(updatedProfile);

    // Update state to show completion screen while the report generates.
    setState(() {
      _currentQuestionIndex++;
    });

    // Build the Förderplan concurrently with the 2-second completion pause so
    // navigation is ready as soon as the minimum display time has elapsed.
    final foerderplanFuture =
        DiagnosticReportGenerator().generate(updatedProfile, session);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final foerderplan = await foerderplanFuture;
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DiagnosticReportScreen(
          userProfile: updatedProfile,
          session: session,
          foerderplan: foerderplan,
        ),
      ),
    );
  }

  bool _checkAnswer(DiagnosticQuestion question, String userAnswer) {
    if (userAnswer.trim().isEmpty) return false;
    return AnswerGrading.grade(userAnswer: userAnswer, question: question);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back button behavior
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Show confirmation dialog before exiting
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Diagnose beenden?'),
              content: Text(
                _currentQuestionIndex == 0
                    ? 'Möchtest du die Diagnose wirklich beenden?'
                    : 'Dein Fortschritt wurde gespeichert. Du kannst später dort weitermachen, wo du aufgehört hast.\n\nMöchtest du wirklich beenden?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Bleiben'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Beenden'),
                ),
              ],
            );
          },
        );

        if (shouldExit == true && context.mounted) {
          // NOTE (integration-critic F5): the session is left in_progress so
          // the child can resume later — the server is never told the session
          // was abandoned (no API call here, and the diagnostic-sessions
          // function's only terminal action is "complete"). Marking sessions
          // abandoned would need a product decision; see the note in
          // diagnostic-sessions/index.ts.
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Diagnose'),
        ),
      body: FutureBuilder<List<DiagnosticQuestion>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFFEC4748), size: 64),
                  const SizedBox(height: 24),
                  const Text(
                    'Die Aufgaben konnten nicht geladen werden.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bitte wende dich an deine Lehrkraft.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _questionsFuture = _loadQuestions();
                      });
                    },
                    child: const Text('Nochmal versuchen'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Keine Aufgaben gefunden.'));
          }

          final questions = snapshot.data!;
          if (_currentQuestionIndex >= questions.length) {
            // Test is complete - show processing state
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Ergebnisse werden ausgewertet …',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('Bitte warten.'),
                ],
              ),
            );
          }

          // Web-mode save gate: the last answer could not be stored. The
          // child stays on this question with a retry button — never
          // silently advancing past an unsaved answer.
          if (_saveBlocked) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off,
                        color: Color(0xFFEC4748), size: 64),
                    const SizedBox(height: 24),
                    const Text(
                      'Deine Antwort konnte noch nicht gespeichert werden.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Das kann passieren, wenn die Internetverbindung '
                      'gerade nicht klappt.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _retryingSave ? null : _retrySave,
                      child: _retryingSave
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Nochmal versuchen'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Wenn es nicht klappt, wende dich bitte an deine '
                      'Lehrkraft.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final question = questions[_currentQuestionIndex];

          // Start timer if not already started
          if (_questionStartTime == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startQuestionTimer(questions);
            });
          }

          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Aufgabe ${_currentQuestionIndex + 1}/${questions.length}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  QuestionPrompt(question: question),
                  const SizedBox(height: 20),
                  if (question.audioAsset != null) ...[
                    _buildAudioReplayButton(question.audioAsset!),
                    const SizedBox(height: 12),
                  ],
                  // Dynamically build the answer widget based on format
                  _buildAnswerWidget(question, questions),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _savingAnswer
                        ? null
                        : () => _nextQuestion(questions),
                    child: _savingAnswer
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Weiter'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildAnswerWidget(
      DiagnosticQuestion question, List<DiagnosticQuestion> questions) {
    void onSubmit() => _nextQuestion(questions);

    final answerInput = DiagnosticAnswerInput(
      key: ValueKey('answer_${question.listNumber}'),
      question: question,
      controller: _textController,
      onSubmit: onSubmit,
    );

    // Visual items render the arrangement from their clean-room spec above
    // the answer input (see buildVisualDisplay).
    if (question.sourceType == QuestionType.image) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildVisualDisplay(question),
          const SizedBox(height: 16),
          answerInput,
        ],
      );
    }

    return answerInput;
  }

  /// Renders the arrangement specified by the clean-room item file for the
  /// current visual item, delegating to the public [buildVisualDisplay] with
  /// access to the shared text controller (used by the interactive number
  /// line of DDB-05).
  Widget _buildVisualDisplay(DiagnosticQuestion question) {
    return buildVisualDisplay(question, controller: _textController);
  }

  Widget _buildAudioReplayButton(String audioUrl) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.replay),
      label: const Text('Nochmal anhören'),
      onPressed: () => _playAudio(audioUrl),
    );
  }

  Future<void> _playAudio(String audioUrl) async {
    await _audioPlayer.stop();
    Source source;
    if (kIsWeb) {
      // On web, load from the public Supabase Storage URL.
      source = UrlSource(audioUrl);
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      // audioplayers_windows doesn't resolve AssetSource paths reliably;
      // extract to a temp file once and reuse.
      if (_audioTempFilePath == null) {
        final data = await rootBundle.load('Research/zahlen_diktat.mp3');
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/zahlen_diktat.mp3');
        await file.writeAsBytes(data.buffer.asUint8List());
        _audioTempFilePath = file.path;
      }
      source = DeviceFileSource(_audioTempFilePath!);
    } else {
      source = AssetSource('Research/zahlen_diktat.mp3');
    }
    await _audioPlayer.play(source);
  }
}

/// The child-facing prompt: the German wording, rendered once. Before the
/// diagnostic usability rework, `questionText` duplicated this for every
/// text item; `questionText` keeps its separate role as the item-ID key for
/// visual items (see [buildVisualDisplay]) and is not rendered here.
///
/// Public (top-level) so widget tests can pump it without instantiating the
/// full [DiagnosticScreen], matching [buildVisualDisplay]'s pattern.
class QuestionPrompt extends StatelessWidget {
  final DiagnosticQuestion question;

  const QuestionPrompt({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Text(
        question.german,
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Renders the arrangement specified by the clean-room item file for a visual
/// diagnostic item, keyed by the item ID carried in
/// [DiagnosticQuestion.questionText] (see docs/clean-room/items/ and tasks.md
/// R5.2). One case per visual item ID; each matches the Stimulus type of the
/// corresponding item file.
///
/// Public (top-level) so widget tests can pump every arrangement without
/// instantiating the full [DiagnosticScreen].
Widget buildVisualDisplay(
  DiagnosticQuestion question, {
  TextEditingController? controller,
}) {
  switch (question.questionText.trim()) {
    // A2.1-01 — Rekenrek flash: 4 beads on the top rod, flash presentation
    // gated behind Bereit.
    case 'A2.1-01':
      return const RekenrekFlashWidget(topLeft: 4, bottomLeft: 0);
    // A2.2-01 — Zehnerfeld 5×2: top row full + first cell of second row (5+1).
    case 'A2.2-01':
      return const ZehnerfeldWidget(filled: {0, 1, 2, 3, 4, 5});
    // A2.2-02 — Fingerbild 8 = 5+3.
    case 'A2.2-02':
      return const FingerBildWidget(leftCount: 5, rightCount: 3);
    // A2.3-01 — two Zehnerfelder: 6 (5+1) vs 8 (5+3).
    case 'A2.3-01':
      return const VergleichZehnerfelderWidget();
    // B1.2-01 — 34 as 3 Zehner-Stangen + 4 Einer-Würfel, gap between groups.
    case 'B1.2-01':
      return const DienesPlaceValueWidget(tens: 3, ones: 4);
    // B1.2-02 — 41 as 3 Zehner-Stangen + 11 Einer-Würfel (rebundling needed).
    case 'B1.2-02':
      return const DienesPlaceValueWidget(tens: 3, ones: 11);
    // B1.3-01 — 13 = 1 Zehner-Stange + 3 Einer; tapping the rod opens it.
    case 'B1.3-01':
      return const DienesOeffnenWidget();
    // B2.1-01 — Stellenwerttafel (Z|E) with 47 above, empty entry cells.
    case 'B2.1-01':
      return const StellenwerttafelWidget(numberAbove: '47');
    // B2.1-02 — Stellenwerttafel with Z=6, E=0 (null as placeholder).
    case 'B2.1-02':
      return const StellenwerttafelWidget(tensValue: 6, onesValue: 0);
    // B2.2-01 — Zahlenstrahl 0–100, anchors 0/50/100, arrow at 80.
    case 'B2.2-01':
      return const ZahlenstrahlArrowWidget(value: 80);
    // DDA-04 — Zehnerfeld 5+2.
    case 'DDA-04':
      return const ZehnerfeldWidget(filled: {0, 1, 2, 3, 4, 5, 6});
    // DDA-05 — Rekenrek 5 top + 4 bottom.
    case 'DDA-05':
      return const RekenrekWidget(topLeft: 5, bottomLeft: 4);
    // DDA-06 — two Rekenreks, 8 vs 5 comparison.
    case 'DDA-06':
      return const VergleichRekenrekWidget();
    // DDB-01 — 56 as 5 Zehner-Stangen + 6 Einer-Würfel.
    case 'DDB-01':
      return const DienesPlaceValueWidget(tens: 5, ones: 6);
    // DDB-02 — 25 as 2 Zehner-Stangen + 5 Einer; the item file keeps the
    // initial arrangement visible and the exchange to 1 Z + 15 E is the task.
    case 'DDB-02':
      return const DienesPlaceValueWidget(tens: 2, ones: 5);
    // DDB-04 — Stellenwerttafel reading 5 Z + 8 E → 58.
    case 'DDB-04':
      return const StellenwerttafelWidget(tensValue: 5, onesValue: 8);
    // DDB-05 — Zahlenstrahl 0–100; tapping places the marker at 75 and writes
    // the value to [controller]. Without a controller (tests) the marker is
    // pre-rendered statically.
    case 'DDB-05':
      return controller != null
          ? ZahlenstrahlMarkWidget(controller: controller)
          : const ZahlenstrahlMarkWidget(initialMark: 75);
    default:
      return const SizedBox.shrink();
  }
}
