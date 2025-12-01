import 'package:flutter/material.dart';
import 'dart:math';

/// Level 4: Mit den Augen verfolgen (Follow with Eyes)
///
/// **From Card 1:** "Das Verfolgen der Zählhandlung mit den Augen und die
/// Nennung des Ergebnisses stellt schließlich die schwierigste Aufgabe dar."
///
/// **Purpose:** The MOST DIFFICULT level. Child must count by tracking with
/// eyes only. The dots remain visible but the child must demonstrate mastery
/// of counting by efficiently scanning and tracking. This tests whether counting
/// has become an internalized, visual-spatial process.
///
/// **App Translation:**
/// - Dots displayed in various arrangements (structured and scattered)
/// - Child counts by eye-tracking only (no interaction possible)
/// - Emphasis on quick recognition for smaller quantities (subitizing)
/// - For larger quantities, efficient eye-scanning patterns
/// - Child enters total after visual counting
class CountDotsLevel4Widget extends StatefulWidget {
  final Function(int correct, int total) onProgressUpdate;

  const CountDotsLevel4Widget({
    super.key,
    required this.onProgressUpdate,
  });

  @override
  State<CountDotsLevel4Widget> createState() => _CountDotsLevel4WidgetState();
}

class _CountDotsLevel4WidgetState extends State<CountDotsLevel4Widget>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocus = FocusNode();

  int _targetCount = 5;
  int _correctCount = 0;
  int _totalAttempts = 0;
  int _consecutiveCorrect = 0;
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

      // Level 4: ALWAYS uses random arrangement (tests eye-tracking)
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
    // Standard difficulty curve for Level 4
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
    // Level 4: ALWAYS uses scattered/random positions (tests eye-tracking)
    _dotPositions = _generateScatteredPositions();
  }

  List<Offset> _generateScatteredPositions() {
    final positions = <Offset>[];

    // CRITICAL: Ensure minimum distance to prevent overlaps
    // Dots are typically 20-30px diameter, widget is ~350px
    // So 0.08 = ~28px minimum distance between centers (safe for 20px dots)
    const minDistance = 0.08;
    const maxAttempts = 200; // Increased from 50 to ensure we find valid positions

    for (int i = 0; i < _targetCount; i++) {
      bool validPosition = false;
      Offset newPos = Offset.zero;

      int attempts = 0;
      while (!validPosition && attempts < maxAttempts) {
        newPos = Offset(
          0.1 + _random.nextDouble() * 0.8,
          0.1 + _random.nextDouble() * 0.8,
        );

        // Check if too close to existing dots
        validPosition = true;
        for (final existing in positions) {
          final distance = (newPos - existing).distance;
          if (distance < minDistance) {
            validPosition = false;
            break;
          }
        }
        attempts++;
      }

      // Fallback: if we couldn't find a valid random position after many attempts,
      // use the best position we found
      if (attempts >= maxAttempts && !validPosition) {
        // Use the last attempted position as fallback
        // This should rarely happen with maxAttempts = 200
      }

      positions.add(newPos);
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
        _consecutiveCorrect++;
        _feedbackMessage = 'Excellent! You counted $_targetCount dots just by looking!';
        widget.onProgressUpdate(_correctCount, _totalAttempts);

        // Move to next problem
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _generateNewProblem();
          }
        });
      } else {
        _consecutiveCorrect = 0;
        widget.onProgressUpdate(_correctCount, _totalAttempts);
        final difference = (answer - _targetCount).abs();
        if (difference == 1) {
          _feedbackMessage = 'So close! Off by just 1. Follow each dot with your eyes carefully.';
        } else {
          _feedbackMessage = 'Not quite. Try tracking each dot slowly with your eyes - don\'t miss any!';
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
              // Dots area (eye-tracking challenge)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade300, width: 2),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: _dotPositions.map((offset) {
                          return Positioned(
                            left: offset.dx * constraints.maxWidth - 20,
                            top: offset.dy * constraints.maxHeight - 20,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.teal,
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
              ),

              const SizedBox(height: 24),

              // Answer input
              Card(
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'How many dots did you count?',
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
                                hintText: 'Track with eyes...',
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
                              backgroundColor: Colors.teal,
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
