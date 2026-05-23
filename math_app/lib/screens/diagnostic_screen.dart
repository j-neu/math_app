import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:math_app/widgets/answer_widgets.dart';
import 'package:math_app/widgets/circle_display_widget.dart';
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
import '../widgets/diagnostic/dice_widget.dart';
import '../widgets/common/hundred_field_widget.dart';
import '../widgets/common/dienes_block_widget.dart';
import '../widgets/common/rechenschiffchen_widget.dart';
import '../widgets/common/pattern_dots_widget.dart';

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

  /// Card-oriented break-off group key. Prefers the explicit `skipGroup`
  /// CSV column (e.g. "verdoppeln", "halbieren") so a failure on Card 18
  /// (Verdoppeln bis 20) only suppresses Card 19 (Verdoppeln bis 100),
  /// not every other ZR100 question in the same coarse skill family.
  ///
  /// Falls back to the first-skill-prefix (e.g. "basic" from
  /// `basic_strategy_8`) for legacy rows without a skipGroup, preserving
  /// the original Phase-0 behaviour for the existing 59 questions.
  String? _categoryKey(DiagnosticQuestion question) {
    final group = question.ifWrongSkip?.trim();
    if (group != null && group.isNotEmpty) return group;
    if (question.ifWrongPracticeSkills.isEmpty) return null;
    return question.ifWrongPracticeSkills.first.split('_').first;
  }

  /// Determine if a question is in ZR 100 range (vs ZR 20)
  bool _isZR100Question(DiagnosticQuestion question) {
    // Explicit CSV override wins — used by Q60+ where the magnitude heuristic
    // misclassifies (e.g. "Doppelte von 19" is diagnostically ZR100).
    final zr = question.zahlenraum;
    if (zr != null && zr.isNotEmpty) {
      return zr.toUpperCase() == 'ZR100' || zr.toUpperCase() == 'ZR1000';
    }

    // Don't check image filenames - they contain large numbers like "img2113.jpg"
    // Only check actual question text for Text/Cards questions
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

    // Q24: any two dice values (1–6) that sum to 7
    if (questionNumber == 24) {
       // Expecting "val1, val2" from MultipleAnswerWidget
       final parts = userAnswer.split(',').map((s) => int.tryParse(s.trim()) ?? -1).toList();
       // Check if we have exactly 2 valid numbers > 0 that sum to 7
       // (Dice usually show 1-6, so maybe strictly >0 and <=6? But question says "numbers on dice")
       // Assuming standard dice: 1-6.
       if (parts.length == 2 && 
           parts[0] >= 1 && parts[0] <= 6 && 
           parts[1] >= 1 && parts[1] <= 6 && 
           (parts[0] + parts[1] == 7)) {
         return true;
       }
       return false;
    }

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
                    : 'Dein Fortschritt wurde gespeichert. Du kannst später ab Aufgabe ${_currentQuestionIndex + 1} weitermachen.\n\nMöchtest du wirklich beenden?',
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
                  // Q24: generated dice illustration (6 + 1 = 7 example)
                  if (question.listNumber == 24) ...[
                    _buildQ21Display(),
                    const SizedBox(height: 8),
                  ],
                  // Q48: generated dice comparison (red = child, blue = teacher)
                  if (question.listNumber == 48) ...[
                    _buildQ48Display(),
                    const SizedBox(height: 8),
                  ],
                  // Display image if available
                  if (question.imagePath != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
                      child: _buildImageWidget(question),
                    )
                  else if (question.sourceType == QuestionType.image)
                    // Fallback to circle display for simple image questions
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: CircleDisplayWidget(count: int.tryParse(question.correctAnswer) ?? 0),
                    ),
                  const SizedBox(height: 20),
                  // Display questionText in very large font for Image type questions
                  if (question.sourceType == QuestionType.image &&
                      !question.questionText.toLowerCase().endsWith('.jpg') &&
                      !question.questionText.toLowerCase().endsWith('.png') &&
                      !question.questionText.toLowerCase().endsWith('.jpeg'))
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
    if (question.listNumber == 24) {
      return Q21AnswerWidget(
        key: const ValueKey('q24_dice'),
        controller: _textController,
        onSubmit: onSubmit,
      );
    }
    switch (question.answerFormat) {
      case AnswerFormat.single:
        return SingleAnswerWidget(
          key: ValueKey('single_${question.listNumber}'),
          controller: _textController,
          onSubmit: onSubmit,
        );
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

        return MultipleAnswerWidget(
          key: ValueKey('multiple_${question.listNumber}'),
          controller: _textController,
          fieldCount: fieldCount,
          prefixText: prefixText,
          onSubmit: onSubmit,
        );
      case AnswerFormat.sort:
        // Parse the correct answer to get the items to sort
        final items = question.correctAnswer
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        return SortAnswerWidget(
          key: ValueKey('sort_${question.listNumber}'),
          controller: _textController,
          items: items,
        );
    }
  }

  // Q21: two white dice showing 6 and 1 as an example illustration.
  Widget _buildQ21Display() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              children: [
                const Text('Würfel 1',
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 6),
                DiceWidget(value: 6, size: 90),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8, left: 12, right: 12),
              child: Text('+',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            ),
            Column(
              children: [
                const Text('Würfel 2',
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 6),
                DiceWidget(value: 1, size: 90),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8, left: 12),
              child: Text('= 7',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Beispiel',
          style: TextStyle(fontSize: 12, color: Colors.black38),
        ),
      ],
    );
  }

  // Q48: red die (child = 5) and blue die (teacher = 3).
  Widget _buildQ48Display() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                const Text('Dein Würfel',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DiceWidget(
                  value: 5,
                  size: 90,
                  faceColor: Colors.red.shade100,
                  borderColor: Colors.red.shade400,
                ),
              ],
            ),
            const SizedBox(width: 32),
            Column(
              children: [
                const Text('Mein Würfel',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DiceWidget(
                  value: 3,
                  size: 90,
                  faceColor: Colors.blue.shade100,
                  borderColor: Colors.blue.shade400,
                ),
              ],
            ),
          ],
        ),
      ],
    );
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

  Widget _buildImageWidget(DiagnosticQuestion question) {
    if (question.imagePath == null) {
      return const SizedBox.shrink();
    }

    final name = question.imagePath!.split('/').last;
    final override = _widgetForImage(name);
    if (override != null) return override;

    // PDF placeholder
    if (question.imagePath!.toLowerCase().endsWith('.pdf')) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            const Icon(Icons.picture_as_pdf, size: 48),
            const SizedBox(height: 8),
            Text(
              'View image for Question ${question.listNumber}',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Remaining image assets
    const double inlineHeight = 320;
    return GestureDetector(
      onTap: () => _showZoomedImage(question.imagePath!),
      child: Image.asset(
        question.imagePath!,
        height: inlineHeight,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildScatteredDienesDisplay(
    List<(DienesType type, double left, double top, double angleDeg)> pieces, {
    double canvasW = 340,
    double canvasH = 300,
  }) {
    return SizedBox(
      width: canvasW,
      height: canvasH,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: pieces.map((p) {
          return Positioned(
            left: p.$2,
            top: p.$3,
            child: Transform.rotate(
              angle: p.$4 * (3.14159265 / 180),
              child: DienesBlockWidget(type: p.$1, cellSize: 10),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget? _widgetForImage(String name) {
    switch (name) {
      // Hundred field (Q39–Q42)
      case 'img1809.jpg':
        return const HundredFieldWidget(visibleCount: 100);
      case 'img1810.jpg':
        return const HundredFieldWidget(visibleCount: 12);
      case 'img1811.jpg':
        return const HundredFieldWidget(visibleCount: 85);
      case 'img1812.jpg':
        return const HundredFieldWidget(visibleCount: 99);

      // Rechenschiffchen (Q32–Q35)
      case 'img1888.jpg':
        return const RechenschiffchenWidget(
            topCount: 9, bottomCount: 0, topColor: Colors.red, bottomColor: Colors.red);
      case 'img1890.jpg':
        return const RechenschiffchenWidget(
            topCount: 9, bottomCount: 5, topColor: Colors.red, bottomColor: Colors.red);
      case 'img1889.jpg':
        return const RechenschiffchenWidget(
            topCount: 9, bottomCount: 10, topColor: Colors.red, bottomColor: Colors.red);
      case 'img1891.jpg':
        return const RechenschiffchenWidget(
            topCount: 8, bottomCount: 8, topColor: Colors.red, bottomColor: Colors.red);

      // Dienes blocks (Q36–Q37) — scattered, mixed, slightly rotated
      case 'img1858.jpg': // 5 rods + 7 units = 57
        return _buildScatteredDienesDisplay([
          (DienesType.rod,  5,   10,  -8),
          (DienesType.rod,  0,   108,  12),
          (DienesType.rod,  142, 22,  -5),
          (DienesType.rod,  130, 132,  18),
          (DienesType.rod,  52,  210, -12),
          (DienesType.unit, 110, 8,   20),
          (DienesType.unit, 248, 12, -15),
          (DienesType.unit, 278, 68,  30),
          (DienesType.unit, 252, 148, -20),
          (DienesType.unit, 288, 202,  25),
          (DienesType.unit, 158, 245, -30),
          (DienesType.unit, 225, 258,  15),
        ]);
      case 'img1859.jpg': // 2 rods + 15 units = 35
        return _buildScatteredDienesDisplay([
          (DienesType.rod,  5,   12,   -6),
          (DienesType.rod,  10,  148,   10),
          (DienesType.unit, 112, 2,    20),
          (DienesType.unit, 145, 12,  -15),
          (DienesType.unit, 185, 6,    30),
          (DienesType.unit, 218, 2,   -25),
          (DienesType.unit, 258, 12,   15),
          (DienesType.unit, 300, 5,   -20),
          (DienesType.unit, 122, 82,   25),
          (DienesType.unit, 168, 72,  -15),
          (DienesType.unit, 212, 88,   20),
          (DienesType.unit, 258, 76,  -30),
          (DienesType.unit, 305, 82,   15),
          (DienesType.unit, 118, 178, -20),
          (DienesType.unit, 165, 170,  25),
          (DienesType.unit, 210, 182, -10),
          (DienesType.unit, 262, 175,  20),
        ]);

      // Dienes blocks (Q60–Q61) — Card 10 completion
      case 'img1860.jpg': // 26 units only, unstructured (no rods)
        return _buildScatteredDienesDisplay(
          [
            (DienesType.unit, 15,  12,   15),
            (DienesType.unit, 65,  25,  -22),
            (DienesType.unit, 130, 8,    30),
            (DienesType.unit, 190, 18,  -15),
            (DienesType.unit, 250, 5,    25),
            (DienesType.unit, 290, 35,   -8),
            (DienesType.unit, 10,  78,  -25),
            (DienesType.unit, 55,  90,   18),
            (DienesType.unit, 105, 72,  -12),
            (DienesType.unit, 160, 85,   22),
            (DienesType.unit, 215, 75,  -18),
            (DienesType.unit, 275, 95,   12),
            (DienesType.unit, 25,  138,  20),
            (DienesType.unit, 80,  152, -28),
            (DienesType.unit, 135, 142,  10),
            (DienesType.unit, 195, 158, -20),
            (DienesType.unit, 245, 145,  28),
            (DienesType.unit, 290, 162, -10),
            (DienesType.unit, 15,  208,  15),
            (DienesType.unit, 70,  215, -25),
            (DienesType.unit, 125, 222,  18),
            (DienesType.unit, 180, 212, -12),
            (DienesType.unit, 235, 228,  22),
            (DienesType.unit, 285, 218, -18),
            (DienesType.unit, 100, 275,  25),
            (DienesType.unit, 195, 282, -15),
          ],
          canvasW: 320,
          canvasH: 320,
        );
      case 'img1861.jpg': // 8 rods + 20 units = 100 (fortgesetzte Bündelung)
        return _buildScatteredDienesDisplay(
          [
            (DienesType.rod,  5,   8,   -10),
            (DienesType.rod,  155, 15,   12),
            (DienesType.rod,  10,  110,  8),
            (DienesType.rod,  158, 105, -15),
            (DienesType.rod,  0,   210,  15),
            (DienesType.rod,  148, 215, -8),
            (DienesType.rod,  12,  310, -12),
            (DienesType.rod,  155, 308,  18),
            (DienesType.unit, 270, 5,    20),
            (DienesType.unit, 305, 35,  -15),
            (DienesType.unit, 335, 12,   25),
            (DienesType.unit, 290, 75,  -22),
            (DienesType.unit, 322, 105,  18),
            (DienesType.unit, 275, 145, -10),
            (DienesType.unit, 315, 165,  28),
            (DienesType.unit, 348, 195, -18),
            (DienesType.unit, 285, 220,  15),
            (DienesType.unit, 320, 250, -25),
            (DienesType.unit, 358, 270,  12),
            (DienesType.unit, 295, 295,  -8),
            (DienesType.unit, 332, 325,  22),
            (DienesType.unit, 275, 355, -15),
            (DienesType.unit, 318, 365,  18),
            (DienesType.unit, 110, 60,  -28),
            (DienesType.unit, 95,  165,  25),
            (DienesType.unit, 125, 265, -12),
            (DienesType.unit, 75,  360,  15),
            (DienesType.unit, 140, 372, -20),
          ],
          canvasW: 380,
          canvasH: 380,
        );

      // Subitizing patterns — Plättchen (Q28–Q31)
      case 'img1936.jpg': // 7 dots: 3 top, 3 middle, 1 centre bottom
        return const PatternDotsWidget(
          count: 7,
          positions: [
            Offset(0.25, 0.20), Offset(0.50, 0.20), Offset(0.75, 0.20),
            Offset(0.25, 0.50), Offset(0.50, 0.50), Offset(0.75, 0.50),
            Offset(0.50, 0.80),
          ],
        );
      case 'img1937.jpg': // 8 dots: 3×3 grid minus centre
        return const PatternDotsWidget(
          count: 8,
          positions: [
            Offset(0.25, 0.20), Offset(0.50, 0.20), Offset(0.75, 0.20),
            Offset(0.25, 0.50),                      Offset(0.75, 0.50),
            Offset(0.25, 0.80), Offset(0.50, 0.80), Offset(0.75, 0.80),
          ],
        );
      case 'img1938.jpg': // 6 dots: 3 top, 2 middle, 1 bottom-centre
        return const PatternDotsWidget(
          count: 6,
          positions: [
            Offset(0.25, 0.20), Offset(0.50, 0.20), Offset(0.75, 0.20),
            Offset(0.35, 0.50), Offset(0.65, 0.50),
            Offset(0.50, 0.80),
          ],
        );
      case 'img1939.jpg': // 10 dots: 3×3 grid + 1 right of middle row
        return const PatternDotsWidget(
          count: 10,
          positions: [
            Offset(0.15, 0.20), Offset(0.40, 0.20), Offset(0.65, 0.20),
            Offset(0.15, 0.50), Offset(0.40, 0.50), Offset(0.65, 0.50),
            Offset(0.15, 0.80), Offset(0.40, 0.80), Offset(0.65, 0.80),
            Offset(0.88, 0.50),
          ],
        );

      // Scattered dots (Q1–Q2)
      case 'img2113.jpg': // 8 green scattered dots
        return const PatternDotsWidget(
          count: 8,
          dotColor: Colors.green,
          positions: [
            Offset(0.15, 0.20), Offset(0.45, 0.12), Offset(0.75, 0.25),
            Offset(0.25, 0.55), Offset(0.62, 0.45), Offset(0.85, 0.68),
            Offset(0.35, 0.82), Offset(0.60, 0.85),
          ],
        );
      case 'img2114.jpg': // 17 green scattered dots
        return const PatternDotsWidget(
          count: 17,
          dotColor: Colors.green,
          positions: [
            Offset(0.10, 0.12), Offset(0.30, 0.08), Offset(0.55, 0.15),
            Offset(0.78, 0.20), Offset(0.92, 0.10),
            Offset(0.18, 0.35), Offset(0.45, 0.32), Offset(0.68, 0.38),
            Offset(0.88, 0.45),
            Offset(0.08, 0.58), Offset(0.32, 0.55), Offset(0.58, 0.52),
            Offset(0.80, 0.62),
            Offset(0.20, 0.78), Offset(0.48, 0.82), Offset(0.70, 0.75),
            Offset(0.90, 0.85),
          ],
        );

      default:
        return null;
    }
  }

  void _showZoomedImage(String imagePath) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      builder: (ctx) {
        return GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {}, // absorb taps on the image itself
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Image.asset(
                      imagePath,
                      height: 480,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 24,
                right: 24,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(ctx).pop(),
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}