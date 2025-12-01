import 'package:flutter/material.dart';
import 'dart:math';

/// Level 1: Zur Seite geschoben (Push Aside)
///
/// **From Card 1:** "Zuerst wird das gezählte Objekt zur Seite geschoben.
/// Dabei wird die Zählzahl genannt."
///
/// **Purpose:** Child learns one-to-one correspondence by physically moving
/// each object as they count it. This is the most concrete level.
///
/// **App Translation:**
/// - Dots displayed in source area
/// - Child drags each dot to "counted" area
/// - App shows running count as dots are moved
/// - After all dots moved, child enters the total
/// - Reinforces: each object counted exactly once, final number = total
class CountDotsLevel1Widget extends StatefulWidget {
  final Function(int problemsSolved) onProgressUpdate;

  const CountDotsLevel1Widget({
    super.key,
    required this.onProgressUpdate,
  });

  @override
  State<CountDotsLevel1Widget> createState() => _CountDotsLevel1WidgetState();
}

class _CountDotsLevel1WidgetState extends State<CountDotsLevel1Widget>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocus = FocusNode();

  List<int> _sourceDotsIds = [];
  List<int> _countedDotsIds = [];
  int _targetCount = 5;
  int _problemsSolved = 0;
  bool _showFeedback = false;
  bool _isCorrect = false;
  String _feedbackMessage = '';
  bool _allDotsMovedToCountedArea = false;

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
      // DIFFICULTY CURVE (Standard per DIFFICULTY_CURVE.md):
      // P0-1: Trivial (3-5 dots)
      // P2-3: Easy (6-8 dots)
      // P4-5: Medium (10-12 dots)
      // P6-7: Hard (15-20 dots)
      // P8: Medium (10-12 dots)
      // P9: Easy (6-8 dots)
      _targetCount = _getDotCountForProblem(_problemsSolved);

      _sourceDotsIds = List.generate(_targetCount, (i) => i);
      _countedDotsIds = [];
      _answerController.clear();
      _showFeedback = false;
      _isCorrect = false;
      _feedbackMessage = '';
      _allDotsMovedToCountedArea = false;
    });
  }

  int _getDotCountForProblem(int problemIndex) {
    // STANDARD DIFFICULTY CURVE (per DIFFICULTY_CURVE.md):
    // P0-1: Trivial (3-5 dots)
    // P2-3: Easy (6-8 dots)
    // P4-5: Medium (10-12 dots)
    // P6-7: Hard (15-20 dots)
    // P8: Medium (10-12 dots)
    // P9: Easy (6-8 dots)
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
        // Fallback (shouldn't happen in normal 10-problem flow)
        return 8;
    }
  }

  void _onDotMoved(int dotId) {
    setState(() {
      _sourceDotsIds.remove(dotId);
      _countedDotsIds.add(dotId);

      // Check if all dots have been moved
      if (_sourceDotsIds.isEmpty) {
        _allDotsMovedToCountedArea = true;
        // Auto-focus input after small delay
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
      _isCorrect = (answer == _targetCount);

      if (_isCorrect) {
        _feedbackMessage = 'Perfect! You counted $_targetCount dots correctly!';
        _problemsSolved++;
        widget.onProgressUpdate(_problemsSolved);

        // Move to next problem after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _generateNewProblem();
          }
        });
      } else {
        if (answer == _countedDotsIds.length) {
          _feedbackMessage = 'You counted the dots you moved: ${_countedDotsIds.length}. But count ALL the dots you moved!';
        } else {
          _feedbackMessage = 'Not quite. Count again carefully - move each dot and count as you go.';
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
              const SizedBox(height: 16),

              // Counting areas
              Expanded(
                child: Row(
                  children: [
                    // Source area (uncounted dots)
                    Expanded(
                      child: _buildSourceArea(),
                    ),
                    const SizedBox(width: 16),
                    // Arrow
                    const Icon(
                      Icons.arrow_forward,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    // Counted area
                    Expanded(
                      child: _buildCountedArea(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Answer input (only shown after all dots moved)
              if (_allDotsMovedToCountedArea)
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
                                backgroundColor: Colors.blue,
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

  Widget _buildSourceArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'Dots to Count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _sourceDotsIds.isEmpty
                ? Center(
                    child: Text(
                      'All dots moved!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                : _buildDotGrid(
                    _sourceDotsIds.map((id) {
                      return Draggable<int>(
                        data: id,
                        feedback: _buildDot(Colors.blue.shade300, 40),
                        childWhenDragging: _buildDot(Colors.grey.shade300, 40),
                        onDragCompleted: () => _onDotMoved(id),
                        child: _buildDot(Colors.blue, 40),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountedArea() {
    return DragTarget<int>(
      onWillAccept: (data) => true,
      onAccept: (data) {
        // Already handled in onDragCompleted
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? Colors.green.shade100
                : Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: candidateData.isNotEmpty ? Colors.green : Colors.green.shade300,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              const Text(
                'Counted Dots',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Count: ${_countedDotsIds.length}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _countedDotsIds.isEmpty
                    ? Center(
                        child: Text(
                          'Drag dots here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : _buildDotGrid(
                        _countedDotsIds.map((id) {
                          return _buildDot(Colors.green, 40);
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
              padding: const EdgeInsets.all(6.0),
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
