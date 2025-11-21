import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Level 4: Advanced Challenge - Extended Sequences
///
/// **Pedagogical Purpose:**
/// - Apply predecessor/successor knowledge to extended sequences
/// - Fill in TWO consecutive numbers (forward or backward)
/// - Build deeper pattern recognition
///
/// **How It Works:**
/// - Two problem types:
///   1. Forward: "17, ___, ___" (child fills 18, 19)
///   2. Backward: "___, ___, 20" (child fills 18, 19)
/// - Two input fields for consecutive numbers
/// - Adaptive difficulty: 5-15 (easy) → 1-19 (hard)
/// - Number line appears on errors (no-fail safety net)
///
/// **Translation:**
/// - Extends Level 3's single-number recall to two-number sequences
/// - Tests deeper understanding of counting forward/backward
///
/// **"Wie kommt die Handlung in den Kopf?"**
/// - Level 3: Single predecessor/successor recall
/// - Level 4: Extended sequence completion (two numbers)
/// - Prepares for Level 5: Finale mixed review
class WhatComesNextLevel4Widget extends StatefulWidget {
  final Function(int correctCount) onProgressUpdate;
  final VoidCallback onStartProblemTimer;
  final Function(bool correct, String? userAnswer) onProblemComplete;

  const WhatComesNextLevel4Widget({
    super.key,
    required this.onProgressUpdate,
    required this.onStartProblemTimer,
    required this.onProblemComplete,
  });

  @override
  State<WhatComesNextLevel4Widget> createState() =>
      _WhatComesNextLevel4WidgetState();
}

class _WhatComesNextLevel4WidgetState extends State<WhatComesNextLevel4Widget> {
  int _correctCount = 0;
  int _consecutiveCorrect = 0;

  // Problem state
  String _problemType = 'forward'; // 'forward' or 'backward'
  int _givenNumber = 10;
  final TextEditingController _first = TextEditingController();
  final TextEditingController _second = TextEditingController();
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
    _first.dispose();
    _second.dispose();
    _firstFocus.dispose();
    _secondFocus.dispose();
    super.dispose();
  }

  void _generateNewProblem() {
    // Adaptive difficulty based on streak
    int minNumber, maxNumber;
    if (_consecutiveCorrect < 3) {
      minNumber = 5;
      maxNumber = 15; // Easy: middle range
    } else if (_consecutiveCorrect < 6) {
      minNumber = 3;
      maxNumber = 17; // Medium: wider range
    } else {
      minNumber = 1;
      maxNumber = 19; // Hard: full range (but leave room for +2)
    }

    // Choose problem type
    _problemType = _random.nextBool() ? 'forward' : 'backward';

    // Generate number based on type
    if (_problemType == 'forward') {
      // Forward: X, ___, ___ (need X+1 and X+2, so max is maxNumber)
      _givenNumber = _random.nextInt(maxNumber - minNumber - 1) + minNumber;
    } else {
      // Backward: ___, ___, X (need X-1 and X-2, so min is minNumber+2)
      _givenNumber =
          _random.nextInt(maxNumber - (minNumber + 2) + 1) + (minNumber + 2);
    }

    _first.clear();
    _second.clear();

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
    final firstText = _first.text.trim();
    final secondText = _second.text.trim();

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

    // Determine expected answers based on problem type
    int expectedFirst, expectedSecond;
    String explanation;

    if (_problemType == 'forward') {
      // Forward: X, ___, ___
      expectedFirst = _givenNumber + 1;
      expectedSecond = _givenNumber + 2;
      explanation =
          'The sequence is: $_givenNumber, $expectedFirst, $expectedSecond';
    } else {
      // Backward: ___, ___, X
      expectedFirst = _givenNumber - 2;
      expectedSecond = _givenNumber - 1;
      explanation =
          'The sequence is: $expectedFirst, $expectedSecond, $_givenNumber';
    }

    // Check correctness
    final bothCorrect =
        firstAnswer == expectedFirst && secondAnswer == expectedSecond;
    final userAnswerString = 'First: $firstAnswer, Second: $secondAnswer';

    // Record the problem result
    widget.onProblemComplete(bothCorrect, userAnswerString);

    if (bothCorrect) {
      // Both correct!
      setState(() {
        _correctCount++;
        _consecutiveCorrect++;
        _feedbackMessage = '✓ Perfect! $explanation';
        _feedbackColor = Colors.green;
      });

      widget.onProgressUpdate(_correctCount);

      // Move to next problem after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _generateNewProblem();
        }
      });
    } else {
      // Wrong - show number line as support
      _consecutiveCorrect = 0;
      setState(() {
        _feedbackMessage = 'Not quite. $explanation. Let me show the number line to help!';
        _feedbackColor = Colors.red;
        _showNumberLine = true;
      });

      // Auto-hide number line after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showNumberLine = false;
          });
        }
      });

      _firstFocus.requestFocus();
    }
  }

  void _toggleNumberLine() {
    setState(() {
      _showNumberLine = !_showNumberLine;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.extension, color: Colors.deepPurple, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Level 4: Extended Sequences',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              Text(
                                'Fill in TWO consecutive numbers! Correct: $_correctCount',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Peek button
                    ElevatedButton.icon(
                      onPressed: _toggleNumberLine,
                      icon: Icon(_showNumberLine ? Icons.visibility_off : Icons.visibility),
                      label: Text(_showNumberLine ? 'Hide Number Line' : 'Show Number Line'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade100,
                        foregroundColor: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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
                        const Text(
                          'Fill in the missing numbers:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Sequence display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _problemType == 'forward'
                              ? [
                                  _buildNumberBox(_givenNumber.toString(), true),
                                  const SizedBox(width: 12),
                                  _buildInputBox(_first, _firstFocus, _secondFocus),
                                  const SizedBox(width: 12),
                                  _buildInputBox(_second, _secondFocus, null),
                                ]
                              : [
                                  _buildInputBox(_first, _firstFocus, _secondFocus),
                                  const SizedBox(width: 12),
                                  _buildInputBox(_second, _secondFocus, null),
                                  const SizedBox(width: 12),
                                  _buildNumberBox(_givenNumber.toString(), true),
                                ],
                        ),

                        const SizedBox(height: 32),

                        // Check button
                        ElevatedButton(
                          onPressed: _checkAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
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

  Widget _buildNumberBox(String text, bool isGiven) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isGiven ? Colors.deepPurple.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGiven ? Colors.deepPurple : Colors.grey.shade400,
          width: isGiven ? 3 : 2,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isGiven ? Colors.deepPurple : Colors.black,
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
        border: Border.all(color: Colors.deepPurple, width: 3),
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
          color: Colors.deepPurple,
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

  Widget _buildNumberLine() {
    // Show range around problem numbers
    int start = _problemType == 'forward'
        ? (_givenNumber - 3).clamp(0, 20)
        : (_givenNumber - 5).clamp(0, 20);
    int end = _problemType == 'forward'
        ? (_givenNumber + 5).clamp(0, 20)
        : (_givenNumber + 3).clamp(0, 20);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(end - start + 1, (index) {
        final number = start + index;
        final isGiven = number == _givenNumber;

        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isGiven ? Colors.deepPurple : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isGiven ? Colors.deepPurple : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isGiven ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      }),
    );
  }
}
