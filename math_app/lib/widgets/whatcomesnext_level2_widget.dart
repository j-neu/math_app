import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Level 2: Supported Practice - Write Predecessor and Successor
///
/// **Pedagogical Purpose:**
/// - Connect visual number position to writing predecessor/successor
/// - Build fluency in identifying numbers before and after
/// - Practice both directions (before AND after)
///
/// **How It Works:**
/// - Number line visible with target number highlighted
/// - Child writes: "What comes BEFORE?" and "What comes AFTER?"
/// - Two input fields (predecessor and successor)
/// - Immediate validation with constructive feedback
/// - After 10 correct, Level 3 unlocks
///
/// **Translation from Physical Activity:**
/// - Physical: Point to number card, name cards before/after
/// - Digital: See number on line, write before/after
///
/// **"Wie kommt die Handlung in den Kopf?"**
/// - Level 1: SAW the before/after relationship
/// - Level 2: Now WRITE what comes before and after
/// - Prepares for Level 3: RECALL from memory
class WhatComesNextLevel2Widget extends StatefulWidget {
  final int correctAnswersRequired;
  final Function(int correctCount) onProgressUpdate;

  const WhatComesNextLevel2Widget({
    super.key,
    required this.correctAnswersRequired,
    required this.onProgressUpdate,
  });

  @override
  State<WhatComesNextLevel2Widget> createState() =>
      _WhatComesNextLevel2WidgetState();
}

class _WhatComesNextLevel2WidgetState extends State<WhatComesNextLevel2Widget> {
  int _correctCount = 0;
  int _currentNumber = 10;
  final TextEditingController _beforeController = TextEditingController();
  final TextEditingController _afterController = TextEditingController();
  final FocusNode _beforeFocus = FocusNode();
  final FocusNode _afterFocus = FocusNode();
  final math.Random _random = math.Random();

  String? _feedbackMessage;
  Color? _feedbackColor;

  @override
  void initState() {
    super.initState();
    _generateNewProblem();
  }

  @override
  void dispose() {
    _beforeController.dispose();
    _afterController.dispose();
    _beforeFocus.dispose();
    _afterFocus.dispose();
    super.dispose();
  }

  void _generateNewProblem() {
    // Generate number between 1 and 19 (so both before and after exist)
    _currentNumber = _random.nextInt(19) + 1; // 1-19

    _beforeController.clear();
    _afterController.clear();

    setState(() {
      _feedbackMessage = null;
    });

    // Focus on first field
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _beforeFocus.requestFocus();
      }
    });
  }

  void _checkAnswer() {
    final beforeText = _beforeController.text.trim();
    final afterText = _afterController.text.trim();

    // Check if both fields filled
    if (beforeText.isEmpty || afterText.isEmpty) {
      setState(() {
        _feedbackMessage = 'Please fill in both numbers!';
        _feedbackColor = Colors.orange;
      });
      return;
    }

    // Parse numbers
    final beforeAnswer = int.tryParse(beforeText);
    final afterAnswer = int.tryParse(afterText);

    if (beforeAnswer == null || afterAnswer == null) {
      setState(() {
        _feedbackMessage = 'Please enter valid numbers!';
        _feedbackColor = Colors.orange;
      });
      return;
    }

    // Expected answers
    final expectedBefore = _currentNumber - 1;
    final expectedAfter = _currentNumber + 1;

    // Check correctness
    final beforeCorrect = beforeAnswer == expectedBefore;
    final afterCorrect = afterAnswer == expectedAfter;

    if (beforeCorrect && afterCorrect) {
      // Both correct!
      setState(() {
        _correctCount++;
        _feedbackMessage = '✓ Perfect! $expectedBefore comes before $_currentNumber, and $expectedAfter comes after!';
        _feedbackColor = Colors.green;
      });

      widget.onProgressUpdate(_correctCount);

      // Move to next problem after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _generateNewProblem();
        }
      });
    } else if (!beforeCorrect && afterCorrect) {
      // Only "before" is wrong
      setState(() {
        _feedbackMessage = 'Almost! $expectedBefore comes BEFORE $_currentNumber. The "after" is correct!';
        _feedbackColor = Colors.orange;
      });
      _beforeFocus.requestFocus();
    } else if (beforeCorrect && !afterCorrect) {
      // Only "after" is wrong
      setState(() {
        _feedbackMessage = 'Almost! $expectedAfter comes AFTER $_currentNumber. The "before" is correct!';
        _feedbackColor = Colors.orange;
      });
      _afterFocus.requestFocus();
    } else {
      // Both wrong
      setState(() {
        _feedbackMessage = 'Not quite. $expectedBefore comes before, and $expectedAfter comes after $_currentNumber. Try again!';
        _feedbackColor = Colors.red;
      });
      _beforeFocus.requestFocus();
    }
  }

  void _showHint() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.amber),
            SizedBox(width: 12),
            Text('Hint'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You need to find what comes before AND after $_currentNumber.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Strategy:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('• BEFORE means subtract 1 (go backwards)'),
            const Text('• AFTER means add 1 (go forwards)'),
            const SizedBox(height: 16),
            const Text('Look at the number line to see the pattern!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Instructions
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.create, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Write what comes before AND after!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Look at the number on the line. Write the number before it and the number after it.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Progress indicator
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress: $_correctCount/${widget.correctAnswersRequired}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${((_correctCount / widget.correctAnswersRequired) * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _correctCount / widget.correctAnswersRequired,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Number line visualization
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Number Line',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildNumberLineSegment(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Problem card
          Card(
            elevation: 4,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    'What comes before and after this number?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // The target number (large display)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      '$_currentNumber',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Input fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Before field
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'BEFORE',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildNumberInput(
                              _beforeController,
                              _beforeFocus,
                              Colors.orange,
                              () => _afterFocus.requestFocus(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Arrow indicator
                      Column(
                        children: [
                          const SizedBox(height: 22),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.grey.shade400,
                            size: 32,
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),

                      // After field
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'AFTER',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildNumberInput(
                              _afterController,
                              _afterFocus,
                              Colors.green,
                              _checkAnswer,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Feedback message
          if (_feedbackMessage != null) ...[
            Card(
              color: _feedbackColor?.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _feedbackColor == Colors.green
                          ? Icons.check_circle
                          : Icons.info_outline,
                      color: _feedbackColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _feedbackMessage!,
                        style: TextStyle(
                          fontSize: 15,
                          color: _feedbackColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _showHint,
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('Hint'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _checkAnswer,
                icon: const Icon(Icons.check),
                label: const Text('Check'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput(
    TextEditingController controller,
    FocusNode focusNode,
    Color borderColor,
    VoidCallback onSubmit,
  ) {
    return SizedBox(
      width: 80,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        maxLength: 2,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onSubmitted: (_) => onSubmit(),
      ),
    );
  }

  Widget _buildNumberLineSegment() {
    // Show segment of number line around current number (±3)
    final int start = math.max(0, _currentNumber - 3);
    final int end = math.min(20, _currentNumber + 3);

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            end - start + 1,
            (index) {
              final number = start + index;
              final isCurrent = number == _currentNumber;
              final isBefore = number == _currentNumber - 1;
              final isAfter = number == _currentNumber + 1;

              return Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? Colors.blue
                      : isBefore
                          ? Colors.orange.shade100
                          : isAfter
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrent
                        ? Colors.blue.shade700
                        : isBefore
                            ? Colors.orange
                            : isAfter
                                ? Colors.green
                                : Colors.grey.shade400,
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontSize: isCurrent ? 20 : 16,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 4),
            const Text('Before', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 12),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.blue,
                border: Border.all(color: Colors.blue.shade700),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 4),
            const Text('Current', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 12),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 4),
            const Text('After', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
