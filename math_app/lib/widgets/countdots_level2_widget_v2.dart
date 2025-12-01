import 'package:flutter/material.dart';
import 'dart:math';

/// Level 2: Angetippt (Tap/Touch)
///
/// **From Card 1:** "Später wird es beim lauten Zählen nur angetippt."
///
/// **Purpose:** Child reduces physical action - no longer moving objects aside,
/// just tapping them. This is less concrete but still provides tactile confirmation.
///
/// **App Translation:**
/// - Dots displayed on screen
/// - Child taps each dot (it marks as "counted" with color change)
/// - Running count shows how many tapped
/// - After all dots tapped, child enters the total
/// - Progress from moving (Level 1) to just touching (Level 2)
class CountDotsLevel2Widget extends StatefulWidget {
  final Function(int correct, int total) onProgressUpdate;

  const CountDotsLevel2Widget({
    super.key,
    required this.onProgressUpdate,
  });

  @override
  State<CountDotsLevel2Widget> createState() => _CountDotsLevel2WidgetState();
}

class _CountDotsLevel2WidgetState extends State<CountDotsLevel2Widget>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocus = FocusNode();

  int _targetCount = 5;
  Set<int> _tappedDots = {};
  int _correctCount = 0;
  int _totalAttempts = 0;
  bool _showFeedback = false;
  bool _isCorrect = false;
  String _feedbackMessage = '';
  bool _allDotsTapped = false;

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

      _tappedDots.clear();
      _answerController.clear();
      _showFeedback = false;
      _isCorrect = false;
      _feedbackMessage = '';
      _allDotsTapped = false;
    });
  }

  int _getDotCountForProblem(int problemIndex) {
    // Standard difficulty curve for Level 2
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

  void _onDotTapped(int dotId) {
    if (_allDotsTapped) return; // Don't allow tapping after all done

    setState(() {
      _tappedDots.add(dotId);

      // Check if all dots tapped
      if (_tappedDots.length == _targetCount) {
        _allDotsTapped = true;
        // Auto-focus input
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _answerFocus.requestFocus();
          }
        });
      }
    });
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
        _feedbackMessage = 'Perfect! You counted $_targetCount dots correctly!';
        widget.onProgressUpdate(_correctCount, _totalAttempts);

        // Move to next problem
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _generateNewProblem();
          }
        });
      } else {
        widget.onProgressUpdate(_correctCount, _totalAttempts);
        if (answer == _tappedDots.length) {
          _feedbackMessage = 'You counted the tapped dots: ${_tappedDots.length}. But count ALL the dots!';
        } else {
          _feedbackMessage = 'Not quite. Try tapping each dot again and count carefully.';
        }
      }

      _showFeedback = true;
      _feedbackController.forward(from: 0);
    });
  }

  void _resetTaps() {
    setState(() {
      _tappedDots.clear();
      _allDotsTapped = false;
      _answerController.clear();
      _showFeedback = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            children: [
              const SizedBox(height: 16),

              // Counter display
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Tapped: ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_tappedDots.length}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      if (_allDotsTapped) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.check_circle, color: Colors.green, size: 32),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Dots area
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: Center(
                    child: _buildDotGrid(
                      List.generate(_targetCount, (index) {
                        final isTapped = _tappedDots.contains(index);
                        return GestureDetector(
                          onTap: () => _onDotTapped(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: isTapped ? Colors.green : Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isTapped ? Colors.green.shade700 : Colors.blue.shade700,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isTapped
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 24,
                                  )
                                : null,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Reset button (if not all tapped yet)
              if (!_allDotsTapped && _tappedDots.isNotEmpty)
                TextButton.icon(
                  onPressed: _resetTaps,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Start over'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                ),

              // Answer input (only shown after all dots tapped)
              if (_allDotsTapped)
                Card(
                  color: Colors.green.shade50,
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
    );
  }

  /// Builds a grid of dots with maximum 5 dots per row
  Widget _buildDotGrid(List<Widget> dots) {
    const maxDotsPerRow = 5;
    final rows = <Widget>[];

    for (int i = 0; i < dots.length; i += maxDotsPerRow) {
      final rowDots = dots.sublist(
        i,
        (i + maxDotsPerRow > dots.length) ? dots.length : i + maxDotsPerRow,
      );

      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: rowDots.map((dot) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: dot,
            );
          }).toList(),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rows,
    );
  }
}
