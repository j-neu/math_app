import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

/// Level 3: Fill Horizontal Sequences
///
/// **Pedagogical Purpose:**
/// Recognize and internalize the horizontal +1 pattern in the 100-field.
/// Child sees a starting number and must fill in the 4 numbers to its right.
///
/// **Activity:**
/// - 10 problems total
/// - Each problem: Show starting number (e.g., 56), hide 4 to right (57, 58, 59, 60)
/// - Field is zoomed and non-panable (all numbers visible on screen)
/// - Child fills in the missing numbers
///
/// **DIFFICULTY CURVE (10 problems): Easy → Hard → Easy**
/// P1-2: Trivial (starting 11, 21 → small numbers, no decade crossing)
/// P3-4: Easy (starting 32, 43 → mid-range, no decade crossing)
/// P5-6: Medium (starting 26, 47 → decade crossing at end: 26→27→28→29→30)
/// P7-8: Hard (starting 16, 36 → decade crossing with mental load)
/// P9: Medium (starting 24 → decade crossing, consolidation)
/// P10: Easy (starting 12 → no crossing, confidence boost)
///
/// **Design Pattern:** Static zoomed view with text input fields
class Count100FieldLevel3Widget extends StatefulWidget {
  final VoidCallback onComplete;
  final Function(int levelNumber, int problemNumber) startProblemTimer;
  final Function(int levelNumber, int problemNumber, bool isCorrect, double timeTaken)
      recordProblemResult;

  const Count100FieldLevel3Widget({
    super.key,
    required this.onComplete,
    required this.startProblemTimer,
    required this.recordProblemResult,
  });

  @override
  State<Count100FieldLevel3Widget> createState() => _Count100FieldLevel3WidgetState();
}

class _Count100FieldLevel3WidgetState extends State<Count100FieldLevel3Widget> {
  final Random _random = Random();

  // Problem sequence following difficulty curve
  final List<int> _startingNumbers = [
    11, 21, // P1-2: Trivial (no decade crossing)
    32, 43, // P3-4: Easy (no decade crossing)
    26, 47, // P5-6: Medium (crosses decade: 26→30, 47→50)
    16, 36, // P7-8: Hard (crosses decade with mental challenge)
    24, // P9: Medium (crosses decade, consolidation)
    12, // P10: Easy (no crossing, confidence boost)
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
    widget.startProblemTimer(3, _currentProblemIndex + 1);
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
      _startingNumber + 1,
      _startingNumber + 2,
      _startingNumber + 3,
      _startingNumber + 4,
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
    widget.recordProblemResult(3, _currentProblemIndex + 1, allCorrect, 0.0);

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
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_forward, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fill the numbers going RIGHT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pattern: Add 1 each time',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade700,
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
                    color: Colors.orange.shade800,
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
                    _isCorrect ? 'Perfect! Moving right adds 1!' : 'Try again - think about +1',
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

    // We need to show 5 columns (starting number + 4 to right) and 3 rows (context)
    // But we may need to show multiple rows if the sequence wraps to next row
    final endNumber = _startingNumber + 4;
    final endRow = (endNumber - 1) ~/ 10;

    // Center the starting row
    final displayStartRow = max(0, startRow - 1);
    final displayEndRow = min(10, max(endRow, startRow) + 2);

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
          // Show the rows
          for (int row = displayStartRow; row < displayEndRow; row++)
            _buildDisplayRow(row, startRow, startCol),
        ],
      ),
    );
  }

  Widget _buildDisplayRow(int row, int startRow, int startCol) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int col = 0; col < 10; col++)
          _buildDisplayCell(row, col, startRow, startCol),
      ],
    );
  }

  Widget _buildDisplayCell(int row, int col, int startRow, int startCol) {
    final number = row * 10 + col + 1;
    final isStartingNumber = (number == _startingNumber);
    final isInSequence = (number > _startingNumber && number <= _startingNumber + 4);

    // Starting number - show it highlighted
    if (isStartingNumber) {
      return Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          border: Border.all(color: Colors.blue.shade700, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          number.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
      );
    }

    // In sequence - editable field
    if (isInSequence) {
      final fieldIndex = number - _startingNumber - 1;
      return Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.all(2),
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: const EdgeInsets.all(4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.orange.shade300, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.orange.shade600, width: 3),
            ),
            fillColor: Colors.orange.shade50,
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

    // Context numbers - show normally (but dimmed)
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString(),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
