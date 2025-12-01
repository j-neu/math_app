import 'package:flutter/material.dart';
import 'dart:math';

/// Level 3: Ohne äußere Handlung (No External Action)
///
/// **From Card 1:** "Der nächste Schritt ist das laute Abzählen ohne weitere äußere Handlung."
///
/// **Purpose:** Child no longer touches/moves objects - just counts by looking.
/// This is the transition from physical to mental - the objects are visible but
/// the child must count "in their head" without tactile feedback.
///
/// **App Translation:**
/// - Dots displayed on screen (visible)
/// - Child CANNOT interact with dots (no tapping, no dragging)
/// - Child must count silently by looking
/// - Child enters the total count
/// - Builds internal counting without external action support
class CountDotsLevel3Widget extends StatefulWidget {
  final Function(int correct, int total) onProgressUpdate;

  const CountDotsLevel3Widget({
    super.key,
    required this.onProgressUpdate,
  });

  @override
  State<CountDotsLevel3Widget> createState() => _CountDotsLevel3WidgetState();
}

class _CountDotsLevel3WidgetState extends State<CountDotsLevel3Widget>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocus = FocusNode();

  int _targetCount = 5;
  int _correctCount = 0;
  int _totalAttempts = 0;
  bool _showFeedback = false;
  bool _isCorrect = false;
  String _feedbackMessage = '';
  List<Offset> _dotPositions = [];

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
      // STANDARD DIFFICULTY CURVE (per DIFFICULTY_CURVE.md):
      // P0-1: Trivial (3-5 dots)
      // P2-3: Easy (6-8 dots)
      // P4-5: Medium (10-12 dots)
      // P6-7: Hard (15-20 dots)
      // P8: Medium (10-12 dots)
      // P9: Easy (6-8 dots)
      _targetCount = _getDotCountForProblem(_totalAttempts);

      _generateDotPositions();
      _answerController.clear();
      _showFeedback = false;
      _isCorrect = false;
      _feedbackMessage = '';
    });

    // Auto-focus input
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _answerFocus.requestFocus();
      }
    });
  }

  int _getDotCountForProblem(int problemIndex) {
    // Standard difficulty curve for Level 3
    switch (problemIndex) {
      case 0:
      case 1:
        // Trivial: 3-5 dots
        return 3 + _random.nextInt(3);
      case 2:
      case 3:
        // Easy: 6-8 dots
        return 6 + _random.nextInt(3);
      case 4:
      case 5:
        // Medium: 10-12 dots
        return 10 + _random.nextInt(3);
      case 6:
      case 7:
        // Hard: 15-20 dots
        return 15 + _random.nextInt(6);
      case 8:
        // Medium: 10-12 dots
        return 10 + _random.nextInt(3);
      case 9:
        // Easy: 6-8 dots
        return 6 + _random.nextInt(3);
      default:
        // Fallback
        return 8;
    }
  }

  void _generateDotPositions() {
    // Level 3: ALWAYS uses structured arrangement (easier to count)
    _dotPositions = _generateStructuredPositions();
  }

  List<Offset> _generateStructuredPositions() {
    final positions = <Offset>[];
    // Grid layout with maximum 5 dots per row (to avoid crowding)
    const maxDotsPerRow = 5;
    final cols = _targetCount <= maxDotsPerRow ? _targetCount : maxDotsPerRow;
    final rows = (_targetCount / maxDotsPerRow).ceil();

    for (int i = 0; i < _targetCount; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      positions.add(Offset(
        (col + 0.5) / cols,
        (row + 0.5) / rows,
      ));
    }
    return positions;
  }


  void _checkAnswer() {
    if (_answerController.text.isEmpty) return;

    final answer = int.tryParse(_answerController.text);
    if (answer == null) return;

    setState(() {
      _totalAttempts++;
      _isCorrect = (answer == _targetCount);

      if (_isCorrect) {
        _correctCount++;
        _feedbackMessage = 'Perfect! You counted $_targetCount dots just by looking!';
        widget.onProgressUpdate(_correctCount, _totalAttempts);

        // Move to next problem
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _generateNewProblem();
          }
        });
      } else {
        widget.onProgressUpdate(_correctCount, _totalAttempts);
        final difference = (answer - _targetCount).abs();
        if (difference == 1) {
          _feedbackMessage = 'Very close! Off by just 1. Try counting again carefully.';
        } else if (difference <= 3) {
          _feedbackMessage = 'Not quite. Count each dot slowly with your eyes.';
        } else {
          _feedbackMessage = 'Try again. Look at each dot and count in your head.';
        }
      }

      _showFeedback = true;
      _feedbackController.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            children: [
              // Dots area (non-interactive)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Count these dots:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Dots display
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: _dotPositions.asMap().entries.map((entry) {
                                final position = entry.value;
                                return Positioned(
                                  left: position.dx * constraints.maxWidth - 20,
                                  top: position.dy * constraints.maxHeight - 20,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.purple,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 3,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Answer input
              Card(
                color: Colors.purple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'How many dots are there?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _answerController,
                              focusNode: _answerFocus,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Count in your head...',
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
    );
  }
}
