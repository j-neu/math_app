import 'package:flutter/material.dart';
import 'dart:math';

/// Level 2: Supported Practice for Decompose 10
///
/// Translation of transition phase between iMINT Activities A and B:
/// Physical: Can still see structured materials, but must verbalize/write decomposition
/// Digital: See counters with random decomposition, child writes equation
///
/// Features:
/// - 10 counters displayed with random split (e.g., 7 blue, 3 red)
/// - Instruction: "How many blue? How many red? Write the equation!"
/// - Input fields: 10 = ___ + ___
/// - Immediate feedback on correctness
/// - After correct answer, new random decomposition appears
/// - Progress: "8/10 correct to unlock Level 3"
class Decompose10Level2Widget extends StatefulWidget {
  final Function(bool correct) onAnswerSubmitted;
  final int correctAnswersNeeded;
  final int currentCorrectCount;

  const Decompose10Level2Widget({
    super.key,
    required this.onAnswerSubmitted,
    this.correctAnswersNeeded = 10,
    this.currentCorrectCount = 0,
  });

  @override
  State<Decompose10Level2Widget> createState() => _Decompose10Level2WidgetState();
}

class _Decompose10Level2WidgetState extends State<Decompose10Level2Widget> {
  final TextEditingController _firstPartController = TextEditingController();
  final TextEditingController _secondPartController = TextEditingController();
  final Random _random = Random();

  int _blueCount = 0;
  int _redCount = 0;
  String? _feedbackMessage;
  Color? _feedbackColor;

  @override
  void initState() {
    super.initState();
    _generateNewDecomposition();
  }

  @override
  void dispose() {
    _firstPartController.dispose();
    _secondPartController.dispose();
    super.dispose();
  }

  void _generateNewDecomposition() {
    setState(() {
      _blueCount = _random.nextInt(11); // 0 to 10
      _redCount = 10 - _blueCount;
      _firstPartController.clear();
      _secondPartController.clear();
      _feedbackMessage = null;
      _feedbackColor = null;
    });
  }

  void _checkAnswer() {
    final firstPart = int.tryParse(_firstPartController.text) ?? -1;
    final secondPart = int.tryParse(_secondPartController.text) ?? -1;

    final isCorrect = (firstPart + secondPart == 10) &&
        ((firstPart == _blueCount && secondPart == _redCount) ||
            (firstPart == _redCount && secondPart == _blueCount));

    setState(() {
      if (isCorrect) {
        _feedbackMessage = 'Excellent! 10 = $firstPart + $secondPart ✓';
        _feedbackColor = Colors.green;
      } else if (firstPart + secondPart != 10) {
        _feedbackMessage = '$firstPart + $secondPart = ${firstPart + secondPart}, not 10. Look at the counters!';
        _feedbackColor = Colors.orange;
      } else {
        _feedbackMessage = 'Count the blue and red counters again.';
        _feedbackColor = Colors.orange;
      }
    });

    widget.onAnswerSubmitted(isCorrect);

    // If correct, generate new problem after short delay
    if (isCorrect) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _generateNewDecomposition();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.currentCorrectCount / widget.correctAnswersNeeded;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade300, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit, color: Colors.purple.shade700, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Level 2: Write the Equation',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Look at the counters. How many blue? How many red? Write the equation!',
                    style: TextStyle(fontSize: 16, color: Colors.purple.shade900),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Progress indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress to Level 3:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '${widget.currentCorrectCount}/${widget.correctAnswersNeeded}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 0.8 ? Colors.green : Colors.purple,
                    ),
                  ),
                  if (progress >= 0.8)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Almost there! Level 3 will unlock soon!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Visual: Counters (two rows of 5)
            Center(
              child: Column(
                children: [
                  // Top row (counters 0-4)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) => _buildCounter(i)),
                  ),
                  const SizedBox(height: 8),
                  // Bottom row (counters 5-9)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) => _buildCounter(i + 5)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Equation input
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400, width: 2),
              ),
              child: Column(
                children: [
                  // Color hint labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 55), // Align with "10 = "
                      Container(
                        width: 70,
                        alignment: Alignment.center,
                        child: const Text(
                          'blue',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 32), // Align with " + "
                      Container(
                        width: 70,
                        alignment: Alignment.center,
                        child: const Text(
                          'red',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('10 = ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: _firstPartController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                          decoration: InputDecoration(
                            hintText: '?',
                            hintStyle: const TextStyle(color: Colors.blue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue, width: 3),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const Text(' + ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: _secondPartController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red),
                          decoration: InputDecoration(
                            hintText: '?',
                            hintStyle: const TextStyle(color: Colors.red),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.red, width: 3),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onSubmitted: (_) => _checkAnswer(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Submit button
            ElevatedButton(
              onPressed: _checkAnswer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Check Answer', style: TextStyle(fontSize: 18)),
            ),

            const SizedBox(height: 16),

            // Feedback message
            if (_feedbackMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _feedbackColor?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _feedbackColor ?? Colors.grey, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(
                      _feedbackColor == Colors.green
                          ? Icons.check_circle
                          : Icons.info_outline,
                      color: _feedbackColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _feedbackMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _feedbackColor == Colors.green
                              ? Colors.green.shade900
                              : Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Skip button (for testing or if child gets frustrated)
            TextButton(
              onPressed: _generateNewDecomposition,
              child: const Text('Skip to Next Problem'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter(int index) {
    final isBlue = index < _blueCount;

    return Container(
      width: 48,
      height: 48,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isBlue ? Colors.blue : Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.circle,
          color: Colors.white.withOpacity(0.8),
          size: 24,
        ),
      ),
    );
  }
}
