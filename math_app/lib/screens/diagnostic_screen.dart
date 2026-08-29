import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:math_app/widgets/answer_widgets.dart';
import 'package:math_app/widgets/common/finger_display_widget.dart';
import '../models/diagnostic_question.dart';
import '../models/diagnostic_result.dart';
import '../models/diagnostic_session.dart';
import '../models/user_profile.dart';
import '../services/diagnostic_service.dart';
import '../services/diagnostic_report_generator.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../screens/diagnostic_complete_screen.dart';
import '../screens/diagnostic_report_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

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

  // Timeout and timing tracking (varies by question type)
  static const int timeoutSecondsSingle = 20; // Single-field questions
  static const int timeoutSecondsMultiple = 60; // Multiple/Sort questions
  DateTime? _questionStartTime;
  Timer? _timeoutTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _audioTempFilePath;

  // Break-off logic tracking
  final Map<String, bool> _categoryFailedZR20 = {}; // Track which categories failed in ZR 20
  final Map<String, bool> _categoryPassedZR20 = {}; // Track which categories passed in ZR 20

  @override
  void initState() {
    super.initState();
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
  /// then advances the index to the first unanswered question.
  void _hydrateFromServer(
    List<DiagnosticQuestion> questions,
    List<ServerResult> serverResults,
  ) {
    final resultsByListNumber = {
      for (final r in serverResults) r.questionNumber: r,
    };

    // Walk questions in display order; stop at the first one without a server result.
    int firstUnansweredIndex = questions.length;
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final r = resultsByListNumber[q.listNumber];
      if (r == null) {
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
      if (!r.wasCorrect) {
        _skillTagsToPractice.addAll(q.ifWrongPracticeSkills);
        _checkBreakOffLogic(q, false);
      } else {
        _checkBreakOffLogic(q, true);
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

    final timeoutDuration = question.answerFormat == AnswerFormat.single
        ? timeoutSecondsSingle
        : timeoutSecondsMultiple;

    // Timer that fires after appropriate timeout
    _timeoutTimer = Timer(Duration(seconds: timeoutDuration), () {
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

    // Check break-off logic
    _checkBreakOffLogic(question, false);

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
    _categoryFailedZR20.clear();
    _categoryPassedZR20.clear();

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
        final textCorrect = _checkAnswer(userAnswer, question.correctAnswer, question.answerFormat, question.listNumber);
        // We don't have response time from saved state, so assume 0.0 or not "too long"
        // This is a limitation: if they failed due to time previously, we might re-evaluate as pass here.
        // But persistent "wasCorrect" isn't saved in UserProfile, only answers.
        // Assuming textCorrect is the main factor for reconstruction.
        final wasCorrect = textCorrect; 

        if (!wasCorrect) {
          _skillTagsToPractice.addAll(question.ifWrongPracticeSkills);
          _checkBreakOffLogic(question, false);
        } else {
          _checkBreakOffLogic(question, true);
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
        if (_shouldSkipQuestion(question)) {
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

  /// Check if question should be skipped due to break-off logic
  /// Skip ZR 100 questions only if the category failed in ZR 20 AND didn't pass
  bool _shouldSkipQuestion(DiagnosticQuestion question) {
    // If user has disabled break-off logic, never skip questions
    if (!widget.userProfile.useBreakOffLogic) {
      return false;
    }

    // Prefer card-oriented skipGroup; fall back to first-skill-prefix for legacy rows
    final category = _categoryKey(question);
    if (category == null) return false;

    // Determine if this is a ZR 100 question (questions with numbers typically > 20)
    final isZR100 = _isZR100Question(question);

    // Only skip ZR 100 questions if:
    // 1. This is a ZR 100 question, AND
    // 2. The category failed in ZR 20, AND
    // 3. The category did NOT pass in ZR 20 (pass takes precedence)
    if (isZR100 &&
        _categoryFailedZR20[category] == true &&
        _categoryPassedZR20[category] != true) {
      return true;
    }

    return false;
  }

  /// Break-off group key. Prefers the explicit `skipGroup` CSV column
  /// (e.g. "verdoppeln", "halbieren") so a failure on one ZR20 item only
  /// suppresses the ZR100 items in the same group, not every other ZR100
  /// question in the same coarse skill family.
  ///
  /// Falls back to the first-skill-prefix (e.g. "basic" from
  /// `basic_strategy_8`) for rows without a skipGroup, preserving the
  /// original Phase-0 behaviour.
  String? _categoryKey(DiagnosticQuestion question) {
    final group = question.ifWrongSkip?.trim();
    if (group != null && group.isNotEmpty) return group;
    if (question.ifWrongPracticeSkills.isEmpty) return null;
    return question.ifWrongPracticeSkills.first.split('_').first;
  }

  /// Determine if a question is in ZR 100 range (vs ZR 20)
  bool _isZR100Question(DiagnosticQuestion question) {
    // Explicit CSV override wins — used where the magnitude heuristic
    // misclassifies (e.g. "Doppelte von 19" is diagnostically ZR100).
    final zr = question.zahlenraum;
    if (zr != null && zr.isNotEmpty) {
      return zr.toUpperCase() == 'ZR100' || zr.toUpperCase() == 'ZR1000';
    }

    // Image questions carry an item ID in questionText (not a filename);
    // fall back to the correct answer to judge the number range.
    if (question.sourceType == QuestionType.image) {
      // For image questions, check the correct answer instead
      final answer = int.tryParse(question.correctAnswer) ?? 0;
      return answer > 20;
    }

    // For text/cards questions, check if question text contains numbers > 20
    final text = question.questionText.toLowerCase();
    final numbers = RegExp(r'\d+').allMatches(text);
    for (final match in numbers) {
      final num = int.tryParse(match.group(0) ?? '0') ?? 0;
      if (num > 20) return true;
    }
    return false;
  }

  /// Track break-off logic: mark category as passed or failed in ZR 20
  /// This determines whether ZR 100 questions in the same category should be skipped
  void _checkBreakOffLogic(DiagnosticQuestion question, bool wasCorrect) {
    // Determine if this is a ZR 20 question (not ZR 100)
    final isZR20 = !_isZR100Question(question);

    if (isZR20) {
      // Card-oriented skipGroup if set, else first-skill-prefix
      final category = _categoryKey(question);
      if (category == null) return;

      if (wasCorrect) {
        // Mark this category as passed in ZR 20
        // This prevents skipping ZR 100 questions in this category
        _categoryPassedZR20[category] = true;
      } else {
        // Mark this category as failed in ZR 20
        // This will cause ZR 100 questions in this category to be skipped
        _categoryFailedZR20[category] = true;
      }
    }
  }

  Future<void> _nextQuestion(List<DiagnosticQuestion> questions) async {
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
    final textCorrect = _checkAnswer(userAnswer, currentQuestion.correctAnswer, currentQuestion.answerFormat, currentQuestion.listNumber);

    // Determine time threshold based on question type
    final timeThreshold = currentQuestion.answerFormat == AnswerFormat.single
        ? timeoutSecondsSingle
        : timeoutSecondsMultiple;

    // Answer is considered FAILED if:
    // 1. Text answer is wrong, OR
    // 2. Response time exceeds threshold (indicates counting/inefficient strategy)
    final tookTooLong = responseTime > timeThreshold;
    final wasCorrect = textCorrect && !tookTooLong;

    final answerStatus = userAnswer.isEmpty ? 'leer' : 'attempted';

    final result = DiagnosticResult(
      questionId: currentQuestion.listNumber.toString(),
      wasCorrect: wasCorrect,
      responseTimeSeconds: responseTime,
      status: answerStatus,
      userAnswer: userAnswer,
    );

    _diagnosticResults.add(result);

    // Post to Supabase (web/API mode)
    if (_sessionId != null) {
      try {
        await ApiService().postResult(
          sessionId: _sessionId!,
          questionNumber: currentQuestion.listNumber,
          wasCorrect: wasCorrect,
          responseTimeSeconds: responseTime,
          status: answerStatus,
          userAnswer: userAnswer.isEmpty ? null : userAnswer,
        );
      } catch (e) {
        debugPrint('ApiService.postResult failed: $e');
      }
    }

    // If incorrect OR took too long, add skill tags
    if (!wasCorrect) {
      print('=== Question ${currentQuestion.listNumber} FAILED ===');
      print('  - Text correct: $textCorrect');
      print('  - Response time: ${responseTime}s (threshold: ${timeThreshold}s)');
      print('  - Took too long: $tookTooLong');
      print('  - Adding skill tags: ${currentQuestion.ifWrongPracticeSkills}');
      _skillTagsToPractice.addAll(currentQuestion.ifWrongPracticeSkills);
      _checkBreakOffLogic(currentQuestion, false);
    } else {
      print('=== Question ${currentQuestion.listNumber} PASSED ===');
      print('  - Response time: ${responseTime}s (threshold: ${timeThreshold}s)');
      _checkBreakOffLogic(currentQuestion, true);
    }

    if (_currentQuestionIndex < questions.length - 1) {
      // Find next non-skipped question
      int nextIndex = _currentQuestionIndex + 1;
      while (nextIndex < questions.length && _shouldSkipQuestion(questions[nextIndex])) {
        // Mark as skipped
        final skippedResult = DiagnosticResult(
          questionId: questions[nextIndex].listNumber.toString(),
          wasCorrect: false,
          responseTimeSeconds: 0.0,
          status: 'skipped',
        );
        _diagnosticResults.add(skippedResult);

        // Post skipped question to API
        if (_sessionId != null) {
          try {
            await ApiService().postResult(
              sessionId: _sessionId!,
              questionNumber: questions[nextIndex].listNumber,
              wasCorrect: false,
              responseTimeSeconds: 0,
              status: 'skipped',
            );
          } catch (e) {
            debugPrint('ApiService.postResult (skipped) failed: $e');
          }
        }

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

      // Save progress locally (native only)
      if (_sessionId == null) {
        await _saveDiagnosticProgress();
      }

      // If we've reached the end, process results
      if (_currentQuestionIndex >= questions.length) {
        _processResults(questions);
      }
    } else {
      // Test is finished, process results
      _processResults(questions);
    }
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

  bool _checkAnswer(String userAnswer, String correctAnswer, AnswerFormat format, int questionNumber) {
    if (userAnswer.isEmpty) return false;

    switch (format) {
      case AnswerFormat.single:
        return userAnswer.toLowerCase() == correctAnswer.toLowerCase();

      case AnswerFormat.multiple:
      case AnswerFormat.sort:
        // Normalize both answers by removing extra spaces
        final userItems = userAnswer.split(',').map((s) => s.trim().toLowerCase()).toList();
        final correctItems = correctAnswer.split(',').map((s) => s.trim().toLowerCase()).toList();

        if (userItems.length != correctItems.length) return false;

        for (int i = 0; i < userItems.length; i++) {
          if (userItems[i] != correctItems[i]) return false;
        }
        return true;
    }
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
            return Center(child: Text('Fehler: ${snapshot.error}'));
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
                  // For non-image questions, display questionText in very large font
                  if (question.sourceType == QuestionType.text)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        question.questionText,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      question.german,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (question.audioAsset != null) ...[
                    _buildAudioReplayButton(question.audioAsset!),
                    const SizedBox(height: 12),
                  ],
                  // Dynamically build the answer widget based on format
                  _buildAnswerWidget(question, questions),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => _nextQuestion(questions),
                    child: const Text('Weiter'),
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

    final Widget answerInput;
    switch (question.answerFormat) {
      case AnswerFormat.single:
        answerInput = SingleAnswerWidget(
          key: ValueKey('single_${question.listNumber}'),
          controller: _textController,
          onSubmit: onSubmit,
        );
        break;
      case AnswerFormat.multiple:
        // Calculate the number of fields based on the correct answer
        final fieldCount = question.correctAnswer
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .length;

        // Try to find a starting number for counting questions
        String? prefixText;
        
        // Check if it's a counting question (contains "Count" in English or "Zähle" in German)
        final isCounting = question.english.toLowerCase().contains('count') || 
                           question.german.toLowerCase().contains('zähle');
                            
        // Check if the main display text is a number (which is usually the starting number for these questions)
        final isNumber = int.tryParse(question.questionText.trim()) != null;
        
        if (isCounting && isNumber) {
          prefixText = '${question.questionText.trim()}, ';
        }

        answerInput = MultipleAnswerWidget(
          key: ValueKey('multiple_${question.listNumber}'),
          controller: _textController,
          fieldCount: fieldCount,
          prefixText: prefixText,
          onSubmit: onSubmit,
        );
        break;
      case AnswerFormat.sort:
        // Parse the correct answer to get the items to sort
        final items = question.correctAnswer
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        answerInput = SortAnswerWidget(
          key: ValueKey('sort_${question.listNumber}'),
          controller: _textController,
          items: items,
        );
        break;
    }

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
    // A2.1-01 — Rekenrek flash: 4 beads on the top rod, 800 ms.
    case 'A2.1-01':
      return const _RekenrekFlashWidget(topLeft: 4, bottomLeft: 0);
    // A2.2-01 — Zehnerfeld 5×2: top row full + first cell of second row (5+1).
    case 'A2.2-01':
      return const _ZehnerfeldWidget(filled: {0, 1, 2, 3, 4, 5});
    // A2.2-02 — Fingerbild 8 = 5+3.
    case 'A2.2-02':
      return const _FingerBildWidget(leftCount: 5, rightCount: 3);
    // A2.3-01 — two Zehnerfelder: 6 (5+1) vs 8 (5+3).
    case 'A2.3-01':
      return const _VergleichZehnerfelderWidget();
    // B1.2-01 — 34 Stäbchen: 3 bundles + 4 singles, gap between groups.
    case 'B1.2-01':
      return const _StaebchenWidget(bundles: 3, singles: 4);
    // B1.2-02 — 41 Stäbchen: 3 bundles + 11 singles (rebundling needed).
    case 'B1.2-02':
      return const _StaebchenWidget(bundles: 3, singles: 11);
    // B1.3-01 — 13 = 1 bundle + 3 singles; tapping the bundle opens it.
    case 'B1.3-01':
      return const _StaebchenOeffnenWidget();
    // B2.1-01 — Stellenwerttafel (Z|E) with 47 above, empty entry cells.
    case 'B2.1-01':
      return const _StellenwerttafelWidget(numberAbove: '47');
    // B2.1-02 — Stellenwerttafel with Z=6, E=0 (null as placeholder).
    case 'B2.1-02':
      return const _StellenwerttafelWidget(tensValue: 6, onesValue: 0);
    // B2.2-01 — Zahlenstrahl 0–100, anchors 0/50/100, arrow at 80.
    case 'B2.2-01':
      return const _ZahlenstrahlArrowWidget(value: 80);
    // DDA-04 — Zehnerfeld 5+2.
    case 'DDA-04':
      return const _ZehnerfeldWidget(filled: {0, 1, 2, 3, 4, 5, 6});
    // DDA-05 — Rekenrek 5 top + 4 bottom.
    case 'DDA-05':
      return const _RekenrekWidget(topLeft: 5, bottomLeft: 4);
    // DDA-06 — two Rekenreks, 8 vs 5 comparison.
    case 'DDA-06':
      return const _VergleichRekenrekWidget();
    // DDB-01 — 56 Stäbchen: 5 bundles + 6 singles.
    case 'DDB-01':
      return const _StaebchenWidget(bundles: 5, singles: 6);
    // DDB-02 — 25 as 2 bundles + 5 singles; the item file keeps the initial
    // arrangement visible and the exchange to 1 Z + 15 E is the task.
    case 'DDB-02':
      return const _StaebchenWidget(bundles: 2, singles: 5);
    // DDB-04 — Stellenwerttafel reading 5 Z + 8 E → 58.
    case 'DDB-04':
      return const _StellenwerttafelWidget(tensValue: 5, onesValue: 8);
    // DDB-05 — Zahlenstrahl 0–100; tapping places the marker at 75 and writes
    // the value to [controller]. Without a controller (tests) the marker is
    // pre-rendered statically.
    case 'DDB-05':
      return controller != null
          ? _ZahlenstrahlMarkWidget(controller: controller)
          : const _ZahlenstrahlMarkWidget(initialMark: 75);
    default:
      return const SizedBox.shrink();
  }
}

/// Zehnerfeld (5×2 raster of ten cells) with the given cells filled.
///
/// [filled] holds cell indices 0..9 in row-major order (row 0 = cells 0–4,
/// row 1 = cells 5–9), matching the coordinate specs of the item files
/// (A2.2-01, A2.3-01, DDA-04).
class _ZehnerfeldWidget extends StatelessWidget {
  final Set<int> filled;

  const _ZehnerfeldWidget({required this.filled});

  @override
  Widget build(BuildContext context) {
    const cellSize = 36.0;

    Widget cell(int index) {
      final isFilled = filled.contains(index);
      return Container(
        width: cellSize,
        height: cellSize,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isFilled ? Colors.indigo : Colors.transparent,
          border: Border.all(
            color: isFilled ? Colors.indigo : Colors.blueGrey,
            width: 2,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (var c = 0; c < 5; c++) cell(c)],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (var c = 5; c < 10; c++) cell(c)],
          ),
        ],
      ),
    );
  }
}

/// Rechenrahmen (Rekenrek) with two rods of ten beads each (5 red + 5 white
/// per rod). [topLeft]/[bottomLeft] are the numbers of beads pushed to the
/// left on the upper/lower rod; the remaining beads sit at the right end.
class _RekenrekWidget extends StatelessWidget {
  final int topLeft;
  final int bottomLeft;

  const _RekenrekWidget({required this.topLeft, required this.bottomLeft});

  Widget _bead({required bool red}) {
    return Container(
      width: 16,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: red ? Colors.red.shade700 : Colors.white,
        border: Border.all(color: Colors.black26),
      ),
    );
  }

  Widget _rod(int leftCount) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.brown.shade200,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.brown.shade400),
      ),
      child: Row(
        children: [
          for (var i = 0; i < leftCount; i++) _bead(red: true),
          const SizedBox(width: 20),
          for (var i = leftCount; i < 10; i++) _bead(red: i < 5),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _rod(topLeft),
        const SizedBox(height: 6),
        _rod(bottomLeft),
      ],
    );
  }
}

/// Rekenrek flash presentation for A2.1-01: the frame is shown for exactly
/// 800 ms and then fades out so the child answers from memory.
class _RekenrekFlashWidget extends StatefulWidget {
  final int topLeft;
  final int bottomLeft;

  const _RekenrekFlashWidget({
    required this.topLeft,
    required this.bottomLeft,
  });

  @override
  State<_RekenrekFlashWidget> createState() => _RekenrekFlashWidgetState();
}

class _RekenrekFlashWidgetState extends State<_RekenrekFlashWidget> {
  Timer? _timer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: _RekenrekWidget(
        topLeft: widget.topLeft,
        bottomLeft: widget.bottomLeft,
      ),
    );
  }
}

/// Fingerbild of two hands (palms facing out), reusing [FingerDisplayWidget].
class _FingerBildWidget extends StatelessWidget {
  final int leftCount;
  final int rightCount;

  const _FingerBildWidget({required this.leftCount, required this.rightCount});

  @override
  Widget build(BuildContext context) {
    return FingerDisplayWidget(
      leftCount: leftCount,
      rightCount: rightCount,
      height: 180,
    );
  }
}

/// Two Zehnerfelder side by side (A2.3-01): left 6 (5+1), right 8 (5+3).
class _VergleichZehnerfelderWidget extends StatelessWidget {
  const _VergleichZehnerfelderWidget();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _labeled(
            'links',
            const _ZehnerfeldWidget(filled: {0, 1, 2, 3, 4, 5}),
          ),
          const SizedBox(width: 28),
          _labeled(
            'rechts',
            const _ZehnerfeldWidget(filled: {0, 1, 2, 3, 4, 5, 6, 7}),
          ),
        ],
      ),
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Two Rekenreks side by side (DDA-06): left 8 (5 top + 3 bottom), right 5.
class _VergleichRekenrekWidget extends StatelessWidget {
  const _VergleichRekenrekWidget();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labeled(
            'links',
            const _RekenrekWidget(topLeft: 5, bottomLeft: 3),
          ),
          const SizedBox(width: 40),
          _labeled(
            'rechts',
            const _RekenrekWidget(topLeft: 5, bottomLeft: 0),
          ),
        ],
      ),
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// A single ten-stick bundle ("Zehnerbündel") with two rubber bands.
class _StaebchenBundelWidget extends StatelessWidget {
  const _StaebchenBundelWidget();

  Widget _band() => Container(
        height: 3,
        color: Colors.brown.shade600,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < 10; i++)
                Expanded(
                  child: Center(
                    child: Container(
                      width: 3,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Positioned(top: 5, left: 4, right: 4, child: _band()),
          Positioned(bottom: 5, left: 4, right: 4, child: _band()),
        ],
      ),
    );
  }
}

/// A single loose stick.
class _StaebchenEinzelWidget extends StatelessWidget {
  const _StaebchenEinzelWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: Colors.deepOrange.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Bundled tens and loose single sticks with a visible gap between the two
/// groups (B1.2-01, B1.2-02, DDB-01, DDB-02).
class _StaebchenWidget extends StatelessWidget {
  final int bundles;
  final int singles;

  const _StaebchenWidget({required this.bundles, required this.singles});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < bundles; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            const _StaebchenBundelWidget(),
          ],
          const SizedBox(width: 26),
          for (var i = 0; i < singles; i++) const _StaebchenEinzelWidget(),
        ],
      ),
    );
  }
}

/// B1.3-01: one bundle + 3 single sticks; tapping the bundle opens it into
/// ten single sticks (interactive Entbündelung per the item file).
class _StaebchenOeffnenWidget extends StatefulWidget {
  const _StaebchenOeffnenWidget();

  @override
  State<_StaebchenOeffnenWidget> createState() => _StaebchenOeffnenWidgetState();
}

class _StaebchenOeffnenWidgetState extends State<_StaebchenOeffnenWidget> {
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    if (_opened) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 13; i++) const _StaebchenEinzelWidget(),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '13 einzelne Stäbchen',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => setState(() => _opened = true),
              child: const _StaebchenBundelWidget(),
            ),
            const SizedBox(width: 26),
            for (var i = 0; i < 3; i++) const _StaebchenEinzelWidget(),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Tippe auf das Bündel, um es zu öffnen.',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }
}

/// Stellenwerttafel with Z/E columns (B2.1-01, B2.1-02, DDB-04). When
/// [numberAbove] is set it is shown above the table; null column values
/// render as empty entry cells.
class _StellenwerttafelWidget extends StatelessWidget {
  final int? tensValue;
  final int? onesValue;
  final String? numberAbove;

  const _StellenwerttafelWidget({
    this.tensValue,
    this.onesValue,
    this.numberAbove,
  });

  @override
  Widget build(BuildContext context) {
    Widget columnCell(String text) {
      return Container(
        width: 64,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (numberAbove != null) ...[
            Text(
              numberAbove!,
              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              columnCell('Z'),
              const SizedBox(width: 4),
              columnCell('E'),
            ],
          ),
          Row(
            children: [
              columnCell(tensValue?.toString() ?? ''),
              const SizedBox(width: 4),
              columnCell(onesValue?.toString() ?? ''),
            ],
          ),
        ],
      ),
    );
  }
}

/// Zahlenstrahl painter shared by the static arrow item (B2.2-01) and the
/// interactive marker item (DDB-05).
class _ZahlenstrahlPainter extends CustomPainter {
  final double? arrowAt;
  final double? markAt;
  final Set<int> majorTicks;
  final Set<int> minorTicks;
  final Map<int, String> labels;

  const _ZahlenstrahlPainter({
    this.arrowAt,
    this.markAt,
    this.majorTicks = const {},
    this.minorTicks = const {},
    this.labels = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 16.0;
    final right = size.width - 16.0;
    final baseline = size.height * 0.6;

    double xFor(num v) => left + (right - left) * (v / 100.0);

    canvas.drawLine(
      Offset(left, baseline),
      Offset(right, baseline),
      Paint()
        ..color = Colors.black
        ..strokeWidth = 2,
    );

    for (final v in minorTicks) {
      canvas.drawLine(
        Offset(xFor(v), baseline - 4),
        Offset(xFor(v), baseline + 4),
        Paint()
          ..color = Colors.black54
          ..strokeWidth = 1,
      );
    }
    for (final v in majorTicks) {
      canvas.drawLine(
        Offset(xFor(v), baseline - 8),
        Offset(xFor(v), baseline + 8),
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2,
      );
    }

    for (final entry in labels.entries) {
      final tp = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(xFor(entry.key) - tp.width / 2, baseline + 12));
    }

    if (arrowAt != null) {
      final x = xFor(arrowAt!);
      canvas.drawLine(
        Offset(x, baseline - 4),
        Offset(x, baseline - 30),
        Paint()
          ..color = Colors.red
          ..strokeWidth = 2.5,
      );
      final head = Path()
        ..moveTo(x, baseline - 38)
        ..lineTo(x - 8, baseline - 26)
        ..lineTo(x + 8, baseline - 26)
        ..close();
      canvas.drawPath(
        head,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill,
      );
    }

    if (markAt != null) {
      final x = xFor(markAt!);
      final head = Path()
        ..moveTo(x, baseline + 4)
        ..lineTo(x - 9, baseline + 20)
        ..lineTo(x + 9, baseline + 20)
        ..close();
      canvas.drawPath(
        head,
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_ZahlenstrahlPainter oldDelegate) =>
      oldDelegate.arrowAt != arrowAt || oldDelegate.markAt != markAt;
}

/// Static number line 0–100 with labelled anchors at 0/50/100, unlabelled
/// tens marks and a red arrow at [value] (B2.2-01).
class _ZahlenstrahlArrowWidget extends StatelessWidget {
  final int value;

  const _ZahlenstrahlArrowWidget({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      height: 110,
      child: CustomPaint(
        painter: _ZahlenstrahlPainter(
          arrowAt: value.toDouble(),
          majorTicks: {for (var v = 0; v <= 100; v += 10) v},
          labels: const {0: '0', 50: '50', 100: '100'},
        ),
      ),
    );
  }
}

/// Interactive number line 0–100 (DDB-05): tapping places a marker snapped to
/// the nearest 5 and writes the value into [controller] (the answer). Without
/// a controller the marker is rendered statically at [initialMark].
class _ZahlenstrahlMarkWidget extends StatefulWidget {
  final TextEditingController? controller;
  final double? initialMark;

  const _ZahlenstrahlMarkWidget({this.controller, this.initialMark});

  @override
  State<_ZahlenstrahlMarkWidget> createState() => _ZahlenstrahlMarkWidgetState();
}

class _ZahlenstrahlMarkWidgetState extends State<_ZahlenstrahlMarkWidget> {
  double? _mark;

  @override
  void initState() {
    super.initState();
    _mark = widget.initialMark;
  }

  double _valueAt(double dx, double width) {
    final raw = (dx / width) * 100;
    final snapped = (raw / 5).round() * 5;
    return snapped.clamp(0, 100).toDouble();
  }

  void _handleTap(TapUpDetails details, double width) {
    final value = _valueAt(details.localPosition.dx, width);
    setState(() => _mark = value);
    widget.controller?.text = value.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) => _handleTap(details, constraints.maxWidth),
          child: SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(
              painter: _ZahlenstrahlPainter(
                markAt: _mark,
                majorTicks: const {0, 25, 50, 75, 100},
                minorTicks: {for (var v = 0; v <= 100; v += 5) v},
                labels: const {0: '0', 100: '100'},
              ),
            ),
          ),
        );
      },
    );
  }
}
