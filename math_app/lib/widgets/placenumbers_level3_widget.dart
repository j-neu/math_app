import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

/// Level 3: Independent Mastery - Mental positioning without visual support
///
/// **Purpose:** Child works from mental imagery, placing numbers on hidden
/// number line. Visual support appears ONLY on errors (no-fail safety net).
///
/// **Pedagogical Goal (Vorstellung → Symbol):**
/// - Internalize number line structure ("in den Kopf")
/// - Work from mental imagery without visual support
/// - Build automatic number sense
/// - Adaptive difficulty increases with mastery
///
/// **No-Fail Support:** Number line flashes briefly on incorrect answers
class PlaceNumbersLevel3Widget extends StatefulWidget {
  final Function(int correct) onProgressUpdate;

  const PlaceNumbersLevel3Widget({
    super.key,
    required this.onProgressUpdate,
  });

  @override
  State<PlaceNumbersLevel3Widget> createState() =>
      _PlaceNumbersLevel3WidgetState();
}

class _PlaceNumbersLevel3WidgetState extends State<PlaceNumbersLevel3Widget>
    with TickerProviderStateMixin {
  final Random _random = Random();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocus = FocusNode();

  int _currentNumber = 0;
  int _minNumber = 0;
  int _maxNumber = 10;
  int _correctCount = 0;
  int _consecutiveCorrect = 0;
  int _totalAttempts = 0;
  bool _showFeedback = false;
  bool _isCorrect = false;
  String _feedbackMessage = '';
  bool _showNumberLine = false;

  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;
  late AnimationController _numberLineController;
  late Animation<double> _numberLineAnimation;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    );

    _numberLineController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _numberLineAnimation = CurvedAnimation(
      parent: _numberLineController,
      curve: Curves.easeInOut,
    );

    _generateNewProblem();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocus.dispose();
    _feedbackController.dispose();
    _numberLineController.dispose();
    super.dispose();
  }

  void _generateNewProblem() {
    setState(() {
      // Adaptive difficulty based on performance
      if (_consecutiveCorrect >= 5) {
        _maxNumber = min(20, _maxNumber + 1);
      }

      _currentNumber = _minNumber + _random.nextInt(_maxNumber - _minNumber + 1);
      _answerController.clear();
      _showFeedback = false;
      _isCorrect = false;
      _feedbackMessage = '';
      _showNumberLine = false;
    });

    // Auto-focus on input
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _answerFocus.requestFocus();
      }
    });
  }

  void _checkAnswer() {
    if (_answerController.text.isEmpty) return;

    final answer = int.tryParse(_answerController.text);
    if (answer == null) return;

    setState(() {
      _totalAttempts++;
      _isCorrect = (answer == _currentNumber);

      if (_isCorrect) {
        _correctCount++;
        _consecutiveCorrect++;
        _feedbackMessage = _getSuccessMessage();
        widget.onProgressUpdate(_correctCount);
      } else {
        _consecutiveCorrect = 0;
        _feedbackMessage = _getGuidanceMessage(answer);
        _showNumberLine = true;
        _numberLineController.forward(from: 0);

        // Hide number line after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showNumberLine = false;
            });
          }
        });
      }

      _showFeedback = true;
      _feedbackController.forward(from: 0);

      if (_isCorrect) {
        // Move to next problem after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _generateNewProblem();
          }
        });
      }
    });
  }

  String _getSuccessMessage() {
    final messages = [
      'Perfect! You visualized $_currentNumber correctly!',
      'Excellent mental positioning!',
      'Great job! Your mental number line is strong!',
      'Amazing! You found $_currentNumber without looking!',
      'Well done! You\'re mastering number placement!',
    ];
    return messages[_random.nextInt(messages.length)];
  }

  String _getGuidanceMessage(int answer) {
    final difference = answer - _currentNumber;
    if (difference > 0) {
      return 'Not quite. $_currentNumber is actually to the LEFT of $answer. Let\'s see the line to help!';
    } else {
      return 'Not quite. $_currentNumber is actually to the RIGHT of $answer. Let\'s see the line to help!';
    }
  }

  void _showHint() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.amber),
            SizedBox(width: 8),
            Text('Hint'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tips for mental positioning:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildHintItem('Close your eyes and imagine a number line'),
            _buildHintItem('Think: Is this number closer to 0 or to 20?'),
            _buildHintItem('Count up from 0: how many steps to reach $_currentNumber?'),
            _buildHintItem('Remember: numbers increase from left to right'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _showNumberLine = true;
                _numberLineController.forward(from: 0);
              });
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _showNumberLine = false;
                  });
                }
              });
            },
            child: const Text('Show me the line'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildHintItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 20, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Instructions
              Card(
                color: Colors.purple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology, color: Colors.purple),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Level 3: Mental Positioning',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.help_outline, color: Colors.purple),
                            onPressed: _showHint,
                            tooltip: 'Get a hint',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use your mental number line! Imagine where each number belongs and type your answer.',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Progress and difficulty indicator
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Correct: $_correctCount',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Range: 0-$_maxNumber',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.local_fire_department,
                              size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Streak: $_consecutiveCorrect',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (_totalAttempts > 0)
                            Text(
                              'Accuracy: ${((_correctCount / _totalAttempts) * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Challenge card with number
              Expanded(
                child: Center(
                  child: Card(
                    elevation: 8,
                    color: Colors.purple.shade50,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.psychology,
                            size: 48,
                            color: Colors.purple,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Imagine the number line...\nWhere does this number belong?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _currentNumber.toString(),
                                style: const TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Answer input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Type where it belongs on the line:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _answerController,
                              focusNode: _answerFocus,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                hintText: 'Your answer...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              onSubmitted: (_) => _checkAnswer(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _checkAnswer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              padding: const EdgeInsets.all(20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Icon(Icons.check, size: 32, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Number line (shown only on errors)
              if (_showNumberLine)
                FadeTransition(
                  opacity: _numberLineAnimation,
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.visibility, color: Colors.amber),
                            SizedBox(width: 8),
                            Text(
                              'Here\'s the line to help you:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 80,
                          child: _buildNumberLineVisualization(),
                        ),
                      ],
                    ),
                  ),
                ),

              // Feedback message
              if (_showFeedback)
                ScaleTransition(
                  scale: _feedbackAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: _isCorrect ? Colors.green.shade100 : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isCorrect ? Colors.green : Colors.orange,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isCorrect ? Icons.check_circle : Icons.info_outline,
                          color: _isCorrect ? Colors.green : Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _feedbackMessage,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _isCorrect ? Colors.green.shade800 : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberLineVisualization() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: NumberLineLevel3Painter(
            minNumber: _minNumber,
            maxNumber: _maxNumber,
            highlightNumber: _currentNumber,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_maxNumber - _minNumber + 1, (index) {
              final number = _minNumber + index;
              final isHighlight = number == _currentNumber;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isHighlight ? Colors.green.shade200 : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isHighlight ? Colors.green : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          number.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                            color: isHighlight ? Colors.green.shade800 : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// Custom painter for Level 3 number line (shown on errors)
class NumberLineLevel3Painter extends CustomPainter {
  final int minNumber;
  final int maxNumber;
  final int highlightNumber;

  NumberLineLevel3Painter({
    required this.minNumber,
    required this.maxNumber,
    required this.highlightNumber,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final tickPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 2;

    final highlightPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4;

    // Draw main horizontal line
    final y = size.height * 0.5;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      paint,
    );

    // Draw tick marks
    final numberOfPositions = maxNumber - minNumber + 1;
    for (int i = 0; i < numberOfPositions; i++) {
      final x = (size.width / numberOfPositions) * i + (size.width / numberOfPositions / 2);
      final isHighlight = (minNumber + i) == highlightNumber;

      canvas.drawLine(
        Offset(x, y - 12),
        Offset(x, y + 12),
        isHighlight ? highlightPaint : tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(NumberLineLevel3Painter oldDelegate) {
    return highlightNumber != oldDelegate.highlightNumber ||
        maxNumber != oldDelegate.maxNumber;
  }
}
