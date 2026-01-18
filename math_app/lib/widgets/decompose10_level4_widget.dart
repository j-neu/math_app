import 'package:flutter/material.dart';
import 'dart:math';

/// Level 4: Finale - Mental Decomposition (5-9)
///
/// **Educational Goal:**
/// Apply decomposition strategies to variable numbers (5-9) in a supported way.
/// Acts as "Easier Mixed Review" following the challenging Level 3.
///
/// **Mechanics:**
/// - Random target number (5-9)
/// - Visual support provided (counters shown)
/// - Child writes equation: "7 = 3 + 4"
/// - No-fail feedback
/// - Completion criteria: 10 correct answers
class Decompose10Level4Widget extends StatefulWidget {
  final Function(bool correct) onAnswerSubmitted;
  final int correctAnswersNeeded;
  final int currentCorrectCount;

  const Decompose10Level4Widget({
    super.key,
    required this.onAnswerSubmitted,
    this.correctAnswersNeeded = 10,
    this.currentCorrectCount = 0,
  });

  @override
  State<Decompose10Level4Widget> createState() => _Decompose10Level4WidgetState();
}

class _Decompose10Level4WidgetState extends State<Decompose10Level4Widget> {
  final TextEditingController _firstPartController = TextEditingController();
  final TextEditingController _secondPartController = TextEditingController();
  final Random _random = Random();

  int _total = 10;
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
      // Pick random total between 5 and 9
      _total = 5 + _random.nextInt(5); // 5, 6, 7, 8, 9
      
      _blueCount = _random.nextInt(_total + 1);
      _redCount = _total - _blueCount;
      
      _firstPartController.clear();
      _secondPartController.clear();
      _feedbackMessage = null;
      _feedbackColor = null;
    });
  }

  void _checkAnswer() {
    final firstPart = int.tryParse(_firstPartController.text) ?? -1;
    final secondPart = int.tryParse(_secondPartController.text) ?? -1;

    final isCorrect = (firstPart + secondPart == _total) &&
        ((firstPart == _blueCount && secondPart == _redCount) ||
            (firstPart == _redCount && secondPart == _blueCount));

    setState(() {
      if (isCorrect) {
        _feedbackMessage = 'Excellent! $_total = $firstPart + $secondPart ✓';
        _feedbackColor = Colors.green;
      } else if (firstPart + secondPart != _total) {
        _feedbackMessage = '$firstPart + $secondPart = ${firstPart + secondPart}, not $_total. Look at the counters!';
        _feedbackColor = Colors.orange;
      } else {
        _feedbackMessage = 'Count the blue and red counters again.';
        _feedbackColor = Colors.orange;
      }
    });

    widget.onAnswerSubmitted(isCorrect);

    // If correct, generate new problem after short delay
    if (isCorrect) {
      Future.delayed(const Duration(milliseconds: 1500), () {
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
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade300, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.indigo.shade700, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Finale: Decompose $_total',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Count the blue and red counters. Write the equation!',
                    style: TextStyle(fontSize: 16, color: Colors.indigo.shade900),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Progress indicator (Finale Style)
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
                        'Finale Progress:',
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
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? Colors.amber : Colors.indigo,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Visual: Counters
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  // Blue counters
                  ...List.generate(_blueCount, (i) => _buildCounter(true)),
                  // Red counters
                  ...List.generate(_redCount, (i) => _buildCounter(false)),
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
                      const SizedBox(width: 55), // Align with "$total = "
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
                      Text('$_total = ', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
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
                      const Text(' + ', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
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
                backgroundColor: Colors.indigo,
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

            // Skip button
            TextButton(
              onPressed: _generateNewDecomposition,
              child: const Text('Skip to Next Problem'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter(bool isBlue) {
    return Container(
      width: 48,
      height: 48,
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
