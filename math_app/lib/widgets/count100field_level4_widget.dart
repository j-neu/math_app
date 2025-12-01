import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

/// Level 4: Fill Missing Number from Context
///
/// **Pedagogical Purpose:**
/// Apply both patterns (+1 horizontal, +10 vertical) to deduce a missing number
/// from its surrounding context. Tests deep understanding of 100-field structure.
///
/// **Activity:**
/// - 10 problems total
/// - Each problem: Hide central number, show surrounding numbers
/// - Child must deduce the missing number from context
/// - Shows 3x3 grid with center missing
///
/// **DIFFICULTY CURVE (10 problems): Easy → Hard → Easy**
/// P1-2: Trivial (numbers 22, 33 → mid-field, all context visible)
/// P3-4: Easy (numbers 44, 25 → mid-field, clear patterns)
/// P5-6: Medium (numbers 56, 37 → requires both patterns)
/// P7-8: Hard (numbers 67, 48 → complex context, mental challenge)
/// P9: Medium (number 35 → consolidation)
/// P10: Easy (number 24 → confidence boost)
///
/// **Design Pattern:** Static view with single text input field
class Count100FieldLevel4Widget extends StatefulWidget {
  final VoidCallback onComplete;
  final Function(int levelNumber, int problemNumber) startProblemTimer;
  final Function(int levelNumber, int problemNumber, bool isCorrect, double timeTaken)
      recordProblemResult;

  const Count100FieldLevel4Widget({
    super.key,
    required this.onComplete,
    required this.startProblemTimer,
    required this.recordProblemResult,
  });

  @override
  State<Count100FieldLevel4Widget> createState() => _Count100FieldLevel4WidgetState();
}

class _Count100FieldLevel4WidgetState extends State<Count100FieldLevel4Widget> {
  final Random _random = Random();

  // Problem sequence following difficulty curve
  // We need numbers that have full context (not on edges)
  final List<int> _missingNumbers = [
    22, 33, // P1-2: Trivial (row 2-3, col 2-3)
    44, 25, // P3-4: Easy
    56, 37, // P5-6: Medium
    67, 48, // P7-8: Hard
    35, // P9: Medium
    24, // P10: Easy
  ];

  int _currentProblemIndex = 0;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showFeedback = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _initializeProblem();
  }

  void _initializeProblem() {
    _controller.clear();
    _showFeedback = false;
    _isCorrect = false;

    // Start timer
    widget.startProblemTimer(4, _currentProblemIndex + 1);

    // Auto-focus the input field
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int get _missingNumber => _missingNumbers[_currentProblemIndex];

  // Get the 3x3 grid around the missing number
  List<int?> get _contextNumbers {
    final row = (_missingNumber - 1) ~/ 10;
    final col = (_missingNumber - 1) % 10;

    List<int?> context = [];

    // 3x3 grid: top row, middle row, bottom row
    for (int r = row - 1; r <= row + 1; r++) {
      for (int c = col - 1; c <= col + 1; c++) {
        if (r == row && c == col) {
          // Center - this is the missing number
          context.add(null);
        } else if (r >= 0 && r < 10 && c >= 0 && c < 10) {
          // Valid position
          context.add(r * 10 + c + 1);
        } else {
          // Out of bounds
          context.add(null);
        }
      }
    }

    return context;
  }

  void _handleSubmit() {
    final text = _controller.text;
    final value = int.tryParse(text);
    final correct = (value == _missingNumber);

    setState(() {
      _isCorrect = correct;
      _showFeedback = true;
    });

    // Record result
    widget.recordProblemResult(4, _currentProblemIndex + 1, correct, 0.0);

    if (correct) {
      // Move to next problem after delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;

        if (_currentProblemIndex < _missingNumbers.length - 1) {
          setState(() {
            _currentProblemIndex++;
            _initializeProblem();
          });
        } else {
          // All problems complete
          widget.onComplete();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.question_mark, color: Colors.purple.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find the missing number',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use the numbers around it to figure it out!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Problem ${_currentProblemIndex + 1}/10',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Hint box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Above: -10  |  Below: +10  |  Left: -1  |  Right: +1',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3x3 grid view
          Expanded(
            child: Center(
              child: _build3x3Grid(),
            ),
          ),

          const SizedBox(height: 24),

          // Submit button
          if (!_showFeedback)
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const Text('Check'),
            ),

          // Feedback
          if (_showFeedback)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isCorrect ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isCorrect ? Colors.green.shade300 : Colors.orange.shade300,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isCorrect ? Icons.check_circle : Icons.refresh,
                    color: _isCorrect ? Colors.green.shade700 : Colors.orange.shade700,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isCorrect
                        ? 'Perfect! You found it!'
                        : 'Try again - look at the patterns',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isCorrect ? Colors.green.shade900 : Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _build3x3Grid() {
    final context = _contextNumbers;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCell(context[0], false),
              _buildCell(context[1], false),
              _buildCell(context[2], false),
            ],
          ),
          // Middle row (with missing center)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCell(context[3], false),
              _buildCell(null, true), // Center - missing number
              _buildCell(context[5], false),
            ],
          ),
          // Bottom row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCell(context[6], false),
              _buildCell(context[7], false),
              _buildCell(context[8], false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCell(int? number, bool isMissing) {
    if (isMissing) {
      // Missing number - show input field
      return Container(
        width: 90,
        height: 90,
        margin: const EdgeInsets.all(4),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 3,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: const EdgeInsets.all(8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.purple.shade300, width: 3),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.purple.shade600, width: 4),
            ),
            fillColor: Colors.purple.shade50,
            filled: true,
            hintText: '?',
            hintStyle: TextStyle(
              fontSize: 32,
              color: Colors.purple.shade300,
            ),
          ),
          onSubmitted: (_) => _handleSubmit(),
        ),
      );
    }

    if (number == null) {
      // Out of bounds - show empty
      return Container(
        width: 90,
        height: 90,
        margin: const EdgeInsets.all(4),
      );
    }

    // Context number - show normally
    return Container(
      width: 90,
      height: 90,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade400, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString(),
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}
