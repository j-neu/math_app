import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Level 3: Independent Mastery - Memory Challenge with Sequences
///
/// **Pedagogical Purpose:**
/// - Internalize predecessor/successor relationships
/// - Work from mental imagery and memory
/// - Apply to sequence completion (fill in gaps)
///
/// **How It Works:**
/// - Number line HIDDEN by default
/// - Three problem types:
///   1. Given number, write before AND after (e.g., "What comes before and after 12?")
///   2. Fill the gap: _, 7, _ (predecessor and successor)
///   3. Sequence: Find missing number: 5, _, 7 (successor)
/// - Number line appears ONLY on errors (no-fail safety net)
/// - Adaptive difficulty increases range
///
/// **"Wie kommt die Handlung in den Kopf?"**
/// - Level 1: SAW the before/after visually
/// - Level 2: WROTE with visual support
/// - Level 3: RECALL from memory (visual hidden, mental work)
class WhatComesNextLevel3Widget extends StatefulWidget {
  final Function(int correctCount) onProgressUpdate;
  final VoidCallback onStartProblemTimer;
  final Function(bool correct, String? userAnswer) onProblemComplete;

  const WhatComesNextLevel3Widget({
    super.key,
    required this.onProgressUpdate,
    required this.onStartProblemTimer,
    required this.onProblemComplete,
  });

  @override
  State<WhatComesNextLevel3Widget> createState() =>
      _WhatComesNextLevel3WidgetState();
}

class _WhatComesNextLevel3WidgetState extends State<WhatComesNextLevel3Widget> {
  int _correctCount = 0;
  int _consecutiveCorrect = 0;

  // Problem state
  String _problemType = 'both'; // 'both', 'before_after_gap', 'sequence_gap'
  int _targetNumber = 10;
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  final math.Random _random = math.Random();

  String? _feedbackMessage;
  Color? _feedbackColor;
  bool _showNumberLine = false;
  bool _peekUsed = false;

  @override
  void initState() {
    super.initState();
    _generateNewProblem();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _generateNewProblem() {
    // Clear old controllers
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();

    // Adaptive difficulty based on streak
    int minNumber, maxNumber;
    if (_consecutiveCorrect < 3) {
      minNumber = 5;
      maxNumber = 15; // Easy: middle range
    } else if (_consecutiveCorrect < 6) {
      minNumber = 2;
      maxNumber = 18; // Medium: wider range
    } else {
      minNumber = 1;
      maxNumber = 19; // Hard: full range
    }

    _targetNumber = _random.nextInt(maxNumber - minNumber + 1) + minNumber;

    // Choose problem type (vary for engagement)
    final types = ['both', 'before_after_gap', 'sequence_gap'];
    _problemType = types[_random.nextInt(types.length)];

    // Create controllers based on problem type
    switch (_problemType) {
      case 'both':
        // Two inputs: before and after
        _controllers.add(TextEditingController());
        _controllers.add(TextEditingController());
        _focusNodes.add(FocusNode());
        _focusNodes.add(FocusNode());
        break;
      case 'before_after_gap':
        // Two inputs: fill _, X, _
        _controllers.add(TextEditingController());
        _controllers.add(TextEditingController());
        _focusNodes.add(FocusNode());
        _focusNodes.add(FocusNode());
        break;
      case 'sequence_gap':
        // One input: fill X, _, Y
        _controllers.add(TextEditingController());
        _focusNodes.add(FocusNode());
        break;
    }

    setState(() {
      _feedbackMessage = null;
      _showNumberLine = false;
      _peekUsed = false;
    });

    // Start problem timer
    widget.onStartProblemTimer();

    // Focus first field
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _checkAnswer() {
    // Parse all inputs
    List<int?> answers = [];
    for (var controller in _controllers) {
      final text = controller.text.trim();
      if (text.isEmpty) {
        answers.add(null);
      } else {
        answers.add(int.tryParse(text));
      }
    }

    // Check if all filled
    if (answers.contains(null)) {
      setState(() {
        _feedbackMessage = 'Please fill in all blanks!';
        _feedbackColor = Colors.orange;
      });
      return;
    }

    // Validate based on problem type
    bool isCorrect = false;
    String correctAnswer = '';
    String explanation = '';

    switch (_problemType) {
      case 'both':
        final expectedBefore = _targetNumber - 1;
        final expectedAfter = _targetNumber + 1;
        isCorrect = answers[0] == expectedBefore && answers[1] == expectedAfter;
        correctAnswer = '$expectedBefore and $expectedAfter';
        explanation = '$expectedBefore comes before $_targetNumber, and $expectedAfter comes after';
        break;

      case 'before_after_gap':
        final expectedBefore = _targetNumber - 1;
        final expectedAfter = _targetNumber + 1;
        isCorrect = answers[0] == expectedBefore && answers[1] == expectedAfter;
        correctAnswer = '$expectedBefore and $expectedAfter';
        explanation = 'The sequence is: $expectedBefore, $_targetNumber, $expectedAfter';
        break;

      case 'sequence_gap':
        final expectedMiddle = _targetNumber + 1;
        isCorrect = answers[0] == expectedMiddle;
        correctAnswer = '$expectedMiddle';
        explanation = '$expectedMiddle comes between $_targetNumber and ${_targetNumber + 2}';
        break;
    }

    // Build user answer string
    String userAnswerString = _problemType == 'sequence_gap'
        ? 'Answer: ${answers[0]}'
        : 'Before: ${answers[0]}, After: ${answers[1]}';

    // Record the problem result
    widget.onProblemComplete(isCorrect, userAnswerString);

    if (isCorrect) {
      setState(() {
        _correctCount++;
        _consecutiveCorrect++;
        _feedbackMessage = '✓ Perfect! The answer is $correctAnswer!';
        _feedbackColor = Colors.green;
      });

      widget.onProgressUpdate(_correctCount);

      // Move to next problem
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
    }
  }

  void _peekAtNumberLine() {
    setState(() {
      _showNumberLine = true;
      _peekUsed = true;
      _feedbackMessage = 'Number line showing to help. Use it to find the answer!';
      _feedbackColor = Colors.blue;
    });
  }

  void _hideNumberLine() {
    setState(() {
      _showNumberLine = false;
      _feedbackMessage = null;
    });
  }

  void _showStrategy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.psychology_outlined, color: Colors.purple),
            SizedBox(width: 12),
            Text('Strategy'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finding predecessor and successor:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 16),
            Text('• BEFORE (predecessor) = subtract 1'),
            Text('• AFTER (successor) = add 1'),
            SizedBox(height: 16),
            Text(
              'Example: Given 10',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('  Before: 10 - 1 = 9'),
            Text('  After: 10 + 1 = 11'),
            SizedBox(height: 16),
            Text(
              'Try saying the numbers in order in your head!',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
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

  String _getDifficultyLabel() {
    if (_consecutiveCorrect < 3) return 'Easy';
    if (_consecutiveCorrect < 6) return 'Medium';
    return 'Hard';
  }

  Color _getDifficultyColor() {
    if (_consecutiveCorrect < 3) return Colors.green;
    if (_consecutiveCorrect < 6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [

          // Number line (hidden by default, shown on peek or error)
          if (_showNumberLine) ...[
            Card(
              elevation: 4,
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Number Line (Support)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_peekUsed)
                          IconButton(
                            icon: const Icon(Icons.visibility_off),
                            onPressed: _hideNumberLine,
                            tooltip: 'Hide number line',
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNumberLineSegment(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Problem card
          Card(
            elevation: 4,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildProblemDisplay(),
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
                          : _feedbackColor == Colors.blue
                              ? Icons.info_outline
                              : Icons.warning_amber,
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
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              if (!_showNumberLine)
                OutlinedButton.icon(
                  onPressed: _peekAtNumberLine,
                  icon: const Icon(Icons.visibility),
                  label: const Text('Peek'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _showStrategy,
                icon: const Icon(Icons.psychology_outlined),
                label: const Text('Strategy'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _checkAnswer,
                icon: const Icon(Icons.check),
                label: const Text('Check'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProblemDisplay() {
    switch (_problemType) {
      case 'both':
        return _buildBothProblem();
      case 'before_after_gap':
        return _buildGapProblem();
      case 'sequence_gap':
        return _buildSequenceGapProblem();
      default:
        return Container();
    }
  }

  Widget _buildBothProblem() {
    return Column(
      children: [
        const Text(
          'What comes BEFORE and AFTER this number?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$_targetNumber',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                  _buildInput(0, Colors.orange),
                ],
              ),
            ),
            const SizedBox(width: 24),
            const Column(
              children: [
                SizedBox(height: 22),
                Icon(Icons.arrow_forward, color: Colors.grey, size: 32),
              ],
            ),
            const SizedBox(width: 24),
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
                  _buildInput(1, Colors.green),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGapProblem() {
    return Column(
      children: [
        const Text(
          'Fill in the blanks:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 70, child: _buildInput(0, Colors.orange)),
            const SizedBox(width: 16),
            const Text(',', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$_targetNumber',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text(',', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            SizedBox(width: 70, child: _buildInput(1, Colors.green)),
          ],
        ),
      ],
    );
  }

  Widget _buildSequenceGapProblem() {
    return Column(
      children: [
        const Text(
          'What number is missing?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$_targetNumber',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text(',', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            SizedBox(width: 70, child: _buildInput(0, Colors.blue)),
            const SizedBox(width: 16),
            const Text(',', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${_targetNumber + 2}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInput(int index, Color borderColor) {
    return SizedBox(
      width: 70,
      height: 70,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        maxLength: 2,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
        onSubmitted: (_) {
          if (index < _controllers.length - 1) {
            _focusNodes[index + 1].requestFocus();
          } else {
            _checkAnswer();
          }
        },
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildNumberLineSegment() {
    final int start = math.max(0, _targetNumber - 3);
    final int end = math.min(20, _targetNumber + 3);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(end - start + 1, (index) {
        final number = start + index;
        final isCurrent = number == _targetNumber;
        final isBefore = number == _targetNumber - 1;
        final isAfter = number == _targetNumber + 1;

        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isCurrent
                ? Colors.purple
                : isBefore
                    ? Colors.orange.shade100
                    : isAfter
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent
                  ? Colors.purple.shade700
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
      }),
    );
  }
}
