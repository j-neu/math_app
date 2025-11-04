import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

/// Level 2: Supported Practice - Estimate position and validate
///
/// **Purpose:** Child sees the number line with a number, and must estimate
/// where it belongs by entering the position. Visual support remains available.
///
/// **Pedagogical Goal (Vorstellung begins):**
/// - See the number, estimate its position
/// - Connect visual spacing to numerical position
/// - Build fluency with number placement
/// - Immediate validation feedback
///
/// **Progression:** After 10 correct answers, Level 3 unlocks
class PlaceNumbersLevel2Widget extends StatefulWidget {
  final Function(int correct, int total) onProgressUpdate;

  const PlaceNumbersLevel2Widget({
    super.key,
    required this.onProgressUpdate,
  });

  @override
  State<PlaceNumbersLevel2Widget> createState() =>
      _PlaceNumbersLevel2WidgetState();
}

class _PlaceNumbersLevel2WidgetState extends State<PlaceNumbersLevel2Widget>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocus = FocusNode();

  int _currentNumber = 0;
  int _minNumber = 0;
  int _maxNumber = 20;
  int _correctCount = 0;
  int _totalAttempts = 0;
  bool _showFeedback = false;
  bool _isCorrect = false;
  String _feedbackMessage = '';

  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;

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
    _generateNewProblem();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocus.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _generateNewProblem() {
    setState(() {
      // Gradually increase range as child progresses
      if (_correctCount < 5) {
        _maxNumber = 10;
      } else if (_correctCount < 10) {
        _maxNumber = 15;
      } else {
        _maxNumber = 20;
      }

      _currentNumber = _minNumber + _random.nextInt(_maxNumber - _minNumber + 1);
      _answerController.clear();
      _showFeedback = false;
      _isCorrect = false;
      _feedbackMessage = '';
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
        _feedbackMessage = _getSuccessMessage();
      } else {
        final difference = (answer - _currentNumber).abs();
        if (difference == 1) {
          _feedbackMessage = 'Very close! Just one position off.';
        } else if (difference <= 3) {
          _feedbackMessage = 'Close! Try again, think about where $_currentNumber sits.';
        } else {
          _feedbackMessage = 'Not quite. Look at the number line - where does $_currentNumber belong?';
        }
      }

      _showFeedback = true;
      _feedbackController.forward(from: 0);

      widget.onProgressUpdate(_correctCount, _totalAttempts);

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
      'Perfect! $_currentNumber is exactly there!',
      'Excellent positioning!',
      'Great job! You found the right spot!',
      'Correct! You\'re getting good at this!',
      'Well done! $_currentNumber is in the right place!',
    ];
    return messages[_random.nextInt(messages.length)];
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
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.create, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Level 2: Find the Position',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Look at the number line and find where the number belongs. Type the number you see on the line at that position!',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Progress indicator
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Correct: $_correctCount/10',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _correctCount / 10,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Number to place (large and prominent)
              Card(
                elevation: 4,
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        'Where does this number belong?',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _currentNumber.toString(),
                            style: const TextStyle(
                              fontSize: 48,
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

              const SizedBox(height: 24),

              // Number line visualization
              Expanded(
                child: _buildNumberLine(),
              ),

              const SizedBox(height: 24),

              // Answer input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Type the position where it belongs:',
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
                                hintText: 'Enter number...',
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
                              backgroundColor: Colors.orange,
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

  Widget _buildNumberLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: NumberLineLevel2Painter(
            minNumber: _minNumber,
            maxNumber: _maxNumber,
            highlightNumber: _showFeedback && _isCorrect ? _currentNumber : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Position markers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_maxNumber - _minNumber + 1, (index) {
                  final number = _minNumber + index;
                  final isHighlight = _showFeedback && _isCorrect && number == _currentNumber;

                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
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
                                fontSize: 16,
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
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for Level 2 number line
class NumberLineLevel2Painter extends CustomPainter {
  final int minNumber;
  final int maxNumber;
  final int? highlightNumber;

  NumberLineLevel2Painter({
    required this.minNumber,
    required this.maxNumber,
    this.highlightNumber,
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
      final isHighlight = highlightNumber != null && (minNumber + i) == highlightNumber;

      canvas.drawLine(
        Offset(x, y - 15),
        Offset(x, y + 15),
        isHighlight ? highlightPaint : tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(NumberLineLevel2Painter oldDelegate) {
    return highlightNumber != oldDelegate.highlightNumber ||
        maxNumber != oldDelegate.maxNumber;
  }
}
