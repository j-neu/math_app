import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Level 5: Finale - Easier Mixed Review
///
/// **Pedagogical Purpose:**
/// - Confidence-building victory lap (ADHD-friendly Easy→Hard→Easy flow)
/// - Mixed review of before/after in easier range (5-15)
/// - Demonstrate mastery for completion
///
/// **How It Works:**
/// - Problem types: Alternating "both" (before/after) and "gap" (_, X, _)
/// - Narrower range: 6-14 (easier than Level 3's 1-19)
/// - Completion criteria: 10 problems, 0 errors, <20s per problem
/// - Number line available but not intrusive
///
/// **Translation:**
/// - Simpler version of Level 3 for final demonstration
/// - Success-oriented (child should feel accomplished)
///
/// **Completion Tracking:**
/// - ExerciseProgressMixin tracks accuracy and time
/// - Status: "finished" → "completed" when criteria met
/// - Celebration dialog on completion
class WhatComesNextLevel5Widget extends StatefulWidget {
  final VoidCallback onStartProblemTimer;
  final Function(bool correct, String? userAnswer) onProblemComplete;

  const WhatComesNextLevel5Widget({
    super.key,
    required this.onStartProblemTimer,
    required this.onProblemComplete,
  });

  @override
  State<WhatComesNextLevel5Widget> createState() =>
      _WhatComesNextLevel5WidgetState();
}

class _WhatComesNextLevel5WidgetState extends State<WhatComesNextLevel5Widget> {
  int _problemsCompleted = 0;
  int _correctCount = 0;

  // Problem state
  String _problemType = 'both'; // 'both' or 'gap'
  int _targetNumber = 10;
  final TextEditingController _firstController = TextEditingController();
  final TextEditingController _secondController = TextEditingController();
  final FocusNode _firstFocus = FocusNode();
  final FocusNode _secondFocus = FocusNode();
  final math.Random _random = math.Random();

  String? _feedbackMessage;
  Color? _feedbackColor;
  bool _showNumberLine = false;

  @override
  void initState() {
    super.initState();
    _generateNewProblem();
  }

  @override
  void dispose() {
    _firstController.dispose();
    _secondController.dispose();
    _firstFocus.dispose();
    _secondFocus.dispose();
    super.dispose();
  }

  void _generateNewProblem() {
    // Easier range: 6-14 (always has before and after)
    _targetNumber = _random.nextInt(9) + 6; // 6-14

    // Alternate problem types for variety
    _problemType = _problemsCompleted % 2 == 0 ? 'both' : 'gap';

    _firstController.clear();
    _secondController.clear();

    setState(() {
      _feedbackMessage = null;
      _showNumberLine = false;
    });

    // Start problem timer
    widget.onStartProblemTimer();

    // Focus first field
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _firstFocus.requestFocus();
      }
    });
  }

  void _checkAnswer() {
    final firstText = _firstController.text.trim();
    final secondText = _secondController.text.trim();

    // Check if both fields filled
    if (firstText.isEmpty || secondText.isEmpty) {
      setState(() {
        _feedbackMessage = 'Please fill in both numbers!';
        _feedbackColor = Colors.orange;
      });
      return;
    }

    // Parse numbers
    final firstAnswer = int.tryParse(firstText);
    final secondAnswer = int.tryParse(secondText);

    if (firstAnswer == null || secondAnswer == null) {
      setState(() {
        _feedbackMessage = 'Please enter valid numbers!';
        _feedbackColor = Colors.orange;
      });
      return;
    }

    // Expected answers
    final expectedBefore = _targetNumber - 1;
    final expectedAfter = _targetNumber + 1;

    // Check correctness
    final bothCorrect =
        firstAnswer == expectedBefore && secondAnswer == expectedAfter;
    final userAnswerString = 'Before: $firstAnswer, After: $secondAnswer';

    // Record the problem result
    widget.onProblemComplete(bothCorrect, userAnswerString);

    if (bothCorrect) {
      // Correct!
      _problemsCompleted++;
      _correctCount++;

      setState(() {
        _feedbackMessage = '✓ Perfect! $expectedBefore, $_targetNumber, $expectedAfter';
        _feedbackColor = Colors.green;
      });

      // Check if completed (handled by mixin, but show celebration if done)
      if (_problemsCompleted >= 10) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _showCompletionCelebration();
          }
        });
      } else {
        // Move to next problem after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _generateNewProblem();
          }
        });
      }
    } else {
      // Wrong - show number line as support
      setState(() {
        _feedbackMessage =
            'Not quite. $expectedBefore comes before, $expectedAfter comes after $_targetNumber. Try again!';
        _feedbackColor = Colors.red;
        _showNumberLine = true;
      });

      // Auto-hide number line after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _showNumberLine) {
          setState(() {
            _showNumberLine = false;
          });
        }
      });

      _firstFocus.requestFocus();
    }
  }

  void _showCompletionCelebration() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber, size: 40),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Congratulations!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You completed the Finale level!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    '✓ $_problemsCompleted problems solved',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '✓ $_correctCount correct answers',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You\'ve mastered predecessor and successor!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to learning path
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleNumberLine() {
    setState(() {
      _showNumberLine = !_showNumberLine;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress
    final accuracy = _problemsCompleted > 0
        ? ((_correctCount / _problemsCompleted) * 100).toStringAsFixed(0)
        : '0';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [

              // Number line (conditionally shown)
              if (_showNumberLine) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _buildNumberLine(),
                ),
                const SizedBox(height: 20),
              ],

              // Problem display
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _problemType == 'both'
                              ? 'What comes BEFORE and AFTER this number?'
                              : 'Fill in the blanks:',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Problem display
                        if (_problemType == 'both') ...[
                          // Target number
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green, width: 3),
                            ),
                            child: Center(
                              child: Text(
                                '$_targetNumber',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Input fields
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'BEFORE',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInputBox(_firstController, _firstFocus, _secondFocus),
                                ],
                              ),
                              const SizedBox(width: 48),
                              Column(
                                children: [
                                  const Text(
                                    'AFTER',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInputBox(_secondController, _secondFocus, null),
                                ],
                              ),
                            ],
                          ),
                        ] else ...[
                          // Gap problem: _, X, _
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildInputBox(_firstController, _firstFocus, _secondFocus),
                              const SizedBox(width: 12),
                              _buildNumberBox('$_targetNumber', true),
                              const SizedBox(width: 12),
                              _buildInputBox(_secondController, _secondFocus, null),
                            ],
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Check button
                        ElevatedButton(
                          onPressed: _checkAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            'Check Answer',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),

                        // Feedback message
                        if (_feedbackMessage != null) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _feedbackColor?.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _feedbackColor ?? Colors.grey, width: 2),
                            ),
                            child: Text(
                              _feedbackMessage!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _feedbackColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBox(
    TextEditingController controller,
    FocusNode currentFocus,
    FocusNode? nextFocus,
  ) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 3),
      ),
      child: TextField(
        controller: controller,
        focusNode: currentFocus,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onSubmitted: (_) {
          if (nextFocus != null) {
            nextFocus.requestFocus();
          } else {
            _checkAnswer();
          }
        },
      ),
    );
  }

  Widget _buildNumberBox(String text, bool isGiven) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isGiven ? Colors.green.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGiven ? Colors.green : Colors.grey.shade400,
          width: isGiven ? 3 : 2,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isGiven ? Colors.green : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildNumberLine() {
    // Show range 3-17 (covers our 6-14 target range plus context)
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(15, (index) {
        final number = index + 3;
        final isTarget = number == _targetNumber;

        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isTarget ? Colors.green : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isTarget ? Colors.green : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isTarget ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      }),
    );
  }
}
