import 'dart:async';
import 'package:flutter/material.dart';
import 'package:math_app/widgets/answer_widgets.dart';
import 'package:math_app/widgets/circle_display_widget.dart';
import '../models/diagnostic_question.dart';
import '../models/diagnostic_result.dart';
import '../models/user_profile.dart';
import '../services/diagnostic_service.dart';
import '../services/user_service.dart';
import '../screens/learning_path_screen.dart';

class DiagnosticScreen extends StatefulWidget {
  final UserProfile userProfile;

  const DiagnosticScreen({super.key, required this.userProfile});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
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

  // Break-off logic tracking
  final Map<String, bool> _categoryFailedZR20 = {}; // Track which categories failed in ZR 20
  final Map<String, bool> _categoryPassedZR20 = {}; // Track which categories passed in ZR 20

  @override
  void initState() {
    super.initState();
    _questionsFuture = DiagnosticService().loadQuestions();
    _loadDiagnosticProgress();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  /// Start timer for the current question (runs silently in background)
  void _startQuestionTimer(List<DiagnosticQuestion> questions) {
    _questionStartTime = DateTime.now();
    _timeoutTimer?.cancel();

    // Determine timeout based on question type
    final question = questions[_currentQuestionIndex];
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
          title: const Text('Need more time?'),
          content: const Text('Should we skip this question and move to the next one?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Give them more time - restart the timer
                _startQuestionTimer(questions);
              },
              child: const Text('Keep Working'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Skip this question
                _skipCurrentQuestion(questions);
              },
              child: const Text('Skip Question'),
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

  Future<void> _loadDiagnosticProgress() async {
    // Load saved diagnostic progress if it exists
    if (widget.userProfile.diagnosticProgress != null) {
      setState(() {
        _currentQuestionIndex = widget.userProfile.diagnosticProgress!;
        if (widget.userProfile.diagnosticAnswers != null) {
          _answers.addAll(widget.userProfile.diagnosticAnswers!);
        }
      });
    }
  }

  /// Check if question should be skipped due to break-off logic
  /// Skip ZR 100 questions only if the category failed in ZR 20 AND didn't pass
  bool _shouldSkipQuestion(DiagnosticQuestion question) {
    // If user has disabled break-off logic, never skip questions
    if (!widget.userProfile.useBreakOffLogic) {
      return false;
    }

    // Determine category from skill tags (first skill tag's category)
    if (question.ifWrongPracticeSkills.isEmpty) return false;

    final firstSkill = question.ifWrongPracticeSkills.first;
    final category = firstSkill.split('_').first; // e.g., "counting" from "counting_4"

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

  /// Determine if a question is in ZR 100 range (vs ZR 20)
  bool _isZR100Question(DiagnosticQuestion question) {
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

    if (isZR20 && question.ifWrongPracticeSkills.isNotEmpty) {
      // Extract category from first skill tag
      final firstSkill = question.ifWrongPracticeSkills.first;
      final category = firstSkill.split('_').first;

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
    final textCorrect = _checkAnswer(userAnswer, currentQuestion.correctAnswer, currentQuestion.answerFormat);

    // Determine time threshold based on question type
    final timeThreshold = currentQuestion.answerFormat == AnswerFormat.single
        ? timeoutSecondsSingle
        : timeoutSecondsMultiple;

    // Answer is considered FAILED if:
    // 1. Text answer is wrong, OR
    // 2. Response time exceeds threshold (indicates counting/inefficient strategy)
    final tookTooLong = responseTime > timeThreshold;
    final wasCorrect = textCorrect && !tookTooLong;

    final result = DiagnosticResult(
      questionId: currentQuestion.listNumber.toString(),
      wasCorrect: wasCorrect,
      responseTimeSeconds: responseTime,
      status: 'attempted',
      userAnswer: userAnswer,
    );

    _diagnosticResults.add(result);

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

      // Save progress after each question
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
    // De-duplicate skill tags
    final uniqueTags = _skillTagsToPractice.toSet().toList();

    print('=== DIAGNOSTIC TEST COMPLETE ===');
    print('  - Total skill tags to practice: ${_skillTagsToPractice.length}');
    print('  - Unique skill tags: ${uniqueTags.length}');
    print('  - Skill tags: $uniqueTags');

    // Update the user profile with the skill tags, diagnostic results, and clear diagnostic progress
    final updatedProfile = widget.userProfile.copyWith(
      skillTags: uniqueTags,
      diagnosticResults: _diagnosticResults,
      clearDiagnosticProgress: true, // Clear progress since test is complete
    );

    // Save the updated profile to persistent storage
    final userService = UserService();
    await userService.saveUser(updatedProfile);

    // Update state to show completion screen
    setState(() {
       _currentQuestionIndex++;
    });

    // Navigate to learning path after a short delay to show completion message
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LearningPathScreen(userProfile: updatedProfile),
          ),
        );
      }
    });
  }

  bool _checkAnswer(String userAnswer, String correctAnswer, AnswerFormat format) {
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
              title: const Text('Exit Diagnostic?'),
              content: Text(
                _currentQuestionIndex == 0
                    ? 'Are you sure you want to exit the diagnostic test?'
                    : 'Your progress has been saved. You can continue later from question ${_currentQuestionIndex + 1}.\n\nAre you sure you want to exit?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Stay'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Exit'),
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
          title: const Text('Diagnostic Test'),
        ),
      body: FutureBuilder<List<DiagnosticQuestion>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No questions found.'));
          }

          final questions = snapshot.data!;
          if (_currentQuestionIndex >= questions.length) {
            // Test is complete
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Test Complete!'),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate back or to results screen
                      Navigator.of(context).pop();
                    },
                    child: const Text('Go Back'),
                  ),
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
                    'Question ${_currentQuestionIndex + 1}/${questions.length}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
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
                  // Displaying the English question text for now.
                  // Localization will be handled later.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      question.english,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Dynamically build the answer widget based on format
                  _buildAnswerWidget(question),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => _nextQuestion(questions),
                    child: const Text('Next'),
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

  Widget _buildAnswerWidget(DiagnosticQuestion question) {
    switch (question.answerFormat) {
      case AnswerFormat.single:
        return SingleAnswerWidget(
          key: ValueKey('single_${question.listNumber}'),
          controller: _textController,
        );
      case AnswerFormat.multiple:
        // Calculate the number of fields based on the correct answer
        final fieldCount = question.correctAnswer
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .length;
        return MultipleAnswerWidget(
          key: ValueKey('multiple_${question.listNumber}'),
          controller: _textController,
          fieldCount: fieldCount,
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

  Widget _buildImageWidget(DiagnosticQuestion question) {
    if (question.imagePath == null) {
      return const SizedBox.shrink();
    }

    // Check if it's a PDF or image file
    if (question.imagePath!.toLowerCase().endsWith('.pdf')) {
      // For PDFs, we'll need to use a PDF viewer package or display a message
      // For now, show a placeholder with the PDF name
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
              question.imagePath!.split('/').last,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    } else {
      // For image files
      return Image.asset(
        question.imagePath!,
        height: 200,
        fit: BoxFit.contain,
      );
    }
  }
}