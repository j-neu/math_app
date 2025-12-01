import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

/// Level 2: Fill Vertical Sequences
///
/// **Pedagogical Purpose:**
/// Recognize and internalize the vertical +10 pattern in the 100-field.
/// Child sees a starting number and must fill in the 4 numbers below it.
///
/// **Activity:**
/// - 10 problems total
/// - Each problem: Show starting number (e.g., 41), hide 4 below (51, 61, 71, 81)
/// - Field is zoomed and non-panable (all numbers visible on screen)
/// - Child fills in the missing numbers
///
/// **DIFFICULTY CURVE (10 problems): Easy → Hard → Easy**
/// P1-2: Trivial (starting 11, 12 → small numbers, mid-column)
/// P3-4: Easy (starting 23, 34 → mid-range, safe positions)
/// P5-6: Medium (starting 45, 26 → larger numbers, varied columns)
/// P7-8: Hard (starting 17, 38 → edge cases, mental challenge)
/// P9: Medium (starting 25 → consolidation)
/// P10: Easy (starting 14 → confidence boost)
///
/// **Design Pattern:** Static zoomed view with text input fields
class Count100FieldLevel2Widget extends StatefulWidget {
  final VoidCallback onComplete;
  final Function(int levelNumber, int problemNumber) startProblemTimer;
  final Function(int levelNumber, int problemNumber, bool isCorrect, double timeTaken)
      recordProblemResult;

  const Count100FieldLevel2Widget({
    super.key,
    required this.onComplete,
    required this.startProblemTimer,
    required this.recordProblemResult,
  });

  @override
  State<Count100FieldLevel2Widget> createState() => _Count100FieldLevel2WidgetState();
}

class _Count100FieldLevel2WidgetState extends State<Count100FieldLevel2Widget> {
  final Random _random = Random();

  // Problem sequence following difficulty curve
  final List<int> _startingNumbers = [
    11, 12, // P1-2: Trivial
    23, 34, // P3-4: Easy
    45, 26, // P5-6: Medium
    17, 38, // P7-8: Hard
    25, // P9: Medium
    14, // P10: Easy
  ];

  int _currentProblemIndex = 0;
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  bool _showFeedback = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _initializeProblem();
  }

  void _initializeProblem() {
    // Clear old controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();

    // Create controllers for 4 missing numbers
    for (int i = 0; i < 4; i++) {
      _controllers[i] = TextEditingController();
      _focusNodes[i] = FocusNode();
    }

    _showFeedback = false;
    _isCorrect = false;

    // Start timer
    widget.startProblemTimer(2, _currentProblemIndex + 1);
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  int get _startingNumber => _startingNumbers[_currentProblemIndex];

  List<int> get _correctAnswers {
    return [
      _startingNumber + 10,
      _startingNumber + 20,
      _startingNumber + 30,
      _startingNumber + 40,
    ];
  }

  void _handleSubmit() {
    // Check answers
    bool allCorrect = true;
    for (int i = 0; i < 4; i++) {
      final text = _controllers[i]?.text ?? '';
      final value = int.tryParse(text);
      if (value != _correctAnswers[i]) {
        allCorrect = false;
        break;
      }
    }

    setState(() {
      _isCorrect = allCorrect;
      _showFeedback = true;
    });

    // Record result
    widget.recordProblemResult(2, _currentProblemIndex + 1, allCorrect, 0.0);

    if (allCorrect) {
      // Move to next problem after delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;

        if (_currentProblemIndex < _startingNumbers.length - 1) {
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
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_downward, color: Colors.green.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fill the numbers going DOWN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pattern: Add 10 each time',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
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
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 100-field view (zoomed section)
          Expanded(
            child: Center(
              child: _buildZoomedField(),
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
                    _isCorrect ? 'Perfect! Moving down adds 10!' : 'Try again - think about +10',
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

  Widget _buildZoomedField() {
    // Calculate which row/col the starting number is in
    final startRow = (_startingNumber - 1) ~/ 10;
    final startCol = (_startingNumber - 1) % 10;

    // We need to show 5 rows (starting number + 4 below) and 3 columns (context)
    // Center the starting column
    final displayStartCol = max(0, startCol - 1);
    final displayEndCol = min(10, displayStartCol + 3);

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
          // Show the 5 rows
          for (int row = startRow; row < min(10, startRow + 5); row++)
            _buildDisplayRow(row, displayStartCol, displayEndCol, startRow, startCol),
        ],
      ),
    );
  }

  Widget _buildDisplayRow(
      int row, int displayStartCol, int displayEndCol, int startRow, int startCol) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int col = displayStartCol; col < displayEndCol; col++)
          _buildDisplayCell(row, col, startRow, startCol),
      ],
    );
  }

  Widget _buildDisplayCell(int row, int col, int startRow, int startCol) {
    final number = row * 10 + col + 1;
    final isStartingNumber = (row == startRow && col == startCol);
    final isTargetColumn = (col == startCol);
    final isBelowStart = (isTargetColumn && row > startRow && row <= startRow + 4);

    // Starting number - show it highlighted
    if (isStartingNumber) {
      return Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          border: Border.all(color: Colors.blue.shade700, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          number.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
      );
    }

    // Below start - editable field
    if (isBelowStart) {
      final fieldIndex = row - startRow - 1;
      return Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.all(4),
        child: TextField(
          controller: _controllers[fieldIndex],
          focusNode: _focusNodes[fieldIndex],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 3,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: const EdgeInsets.all(8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.green.shade300, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.green.shade600, width: 3),
            ),
            fillColor: Colors.green.shade50,
            filled: true,
          ),
          onSubmitted: (_) {
            // Move to next field or submit
            if (fieldIndex < 3) {
              _focusNodes[fieldIndex + 1]?.requestFocus();
            } else {
              _handleSubmit();
            }
          },
        ),
      );
    }

    // Context numbers - show normally
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString(),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
