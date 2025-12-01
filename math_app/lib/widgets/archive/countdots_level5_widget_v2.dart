import 'dart:math';
import 'package:flutter/material.dart';

/// Level 5 (Finale): Mixed Review - True mixed practice from all levels
///
/// **Purpose:** ADHD-friendly Easy→Hard→Easy flow for rewarding completion
///
/// **Mixed Interaction Types:**
/// - **Type 1: Drag & Drop** (from Level 1) - Drag dots to "counted" area
/// - **Type 2: Tap/Click** (from Level 2) - Tap dots to mark as counted
/// - **Type 3: Just Count** (from Level 3) - No interaction, count by looking
///
/// **Difficulty:** Easier than Level 4 (the hardest card-prescribed level)
/// - Dot count: 8-12 (medium range, not maximum 20)
/// - Layout: Structured only (grid layout for easier counting)
/// - No flash/hide mechanic (dots stay visible)
/// - Cycles through all 3 interaction types for variety
///
/// **Completion Criteria:**
/// - 10 problems minimum (mix of all 3 types)
/// - Zero errors required
/// - Time limit: <20s per problem
///
/// This level provides a "victory lap" - the child has proven mastery
/// through the 4 card-prescribed levels, now they get to demonstrate
/// consistent performance using mixed methods to end on success.
class CountDotsLevel5Widget extends StatefulWidget {
  final VoidCallback onStartProblemTimer;
  final Function(bool correct, String? userAnswer) onProblemComplete;
  final VoidCallback? onLevelComplete; // NEW: callback when level is complete

  const CountDotsLevel5Widget({
    super.key,
    required this.onStartProblemTimer,
    required this.onProblemComplete,
    this.onLevelComplete,
  });

  @override
  State<CountDotsLevel5Widget> createState() => _CountDotsLevel5WidgetState();
}

enum InteractionType {
  drag,   // Level 1: Drag to counted area
  tap,    // Level 2: Tap to mark
  count,  // Level 3: Just count
}

class DotState {
  final Offset position;
  bool isCounted;

  DotState({required this.position, this.isCounted = false});
}

class _CountDotsLevel5WidgetState extends State<CountDotsLevel5Widget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Random _random = Random();

  int _currentDotCount = 8;
  InteractionType _currentInteractionType = InteractionType.drag;
  List<DotState> _dots = [];
  int _dotsCountedInArea = 0;

  int _correctAnswers = 0;
  int _totalAttempts = 0;
  String _feedback = '';
  Color _feedbackColor = Colors.grey;
  bool _showFeedback = false;
  bool _isComplete = false; // NEW: track if level is complete

  // Completion tracking
  static const int _requiredProblems = 10;
  static const int _timeLimit = 20; // seconds
  final List<Map<String, dynamic>> _recentResults = []; // Track recent attempts

  @override
  void initState() {
    super.initState();
    _generateNewProblem();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _generateNewProblem() {
    setState(() {
      // Random count between 8-12 (easier range)
      _currentDotCount = 8 + _random.nextInt(5); // 8, 9, 10, 11, or 12

      // Cycle through interaction types
      _currentInteractionType = InteractionType.values[_totalAttempts % 3];

      // Generate dots in structured grid
      _dots = _generateStructuredDots();
      _dotsCountedInArea = 0;

      _controller.clear();
      _showFeedback = false;
    });

    // Start timing this problem
    widget.onStartProblemTimer();

    // Auto-focus for count-only type
    if (_currentInteractionType == InteractionType.count) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  List<DotState> _generateStructuredDots() {
    final List<DotState> dots = [];
    final dotsPerRow = _currentDotCount <= 8 ? 4 : 5;
    final rows = (_currentDotCount / dotsPerRow).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < dotsPerRow; col++) {
        final index = row * dotsPerRow + col;
        if (index >= _currentDotCount) break;

        dots.add(DotState(
          position: Offset(
            col * 70.0 + 35.0,
            row * 70.0 + 35.0,
          ),
        ));
      }
    }

    return dots;
  }

  void _onDotTapped(int index) {
    if (_currentInteractionType != InteractionType.tap) return;

    setState(() {
      _dots[index].isCounted = !_dots[index].isCounted;
    });
  }

  void _onDotDragEnd(int index, DragTargetDetails details) {
    if (_currentInteractionType != InteractionType.drag) return;

    setState(() {
      if (!_dots[index].isCounted) {
        _dots[index].isCounted = true;
        _dotsCountedInArea++;
      }
    });
  }

  void _checkAnswer() {
    int userAnswer;
    String? userAnswerString;

    if (_currentInteractionType == InteractionType.count) {
      // For count-only, get answer from text field
      final userInput = _controller.text.trim();
      if (userInput.isEmpty) return;

      final parsedAnswer = int.tryParse(userInput);
      if (parsedAnswer == null) {
        setState(() {
          _feedback = 'Please enter a number!';
          _feedbackColor = Colors.orange;
          _showFeedback = true;
        });
        return;
      }
      userAnswer = parsedAnswer;
      userAnswerString = userInput;
    } else {
      // For drag/tap, count marked dots
      userAnswer = _dots.where((dot) => dot.isCounted).length;
      userAnswerString = userAnswer.toString();
    }

    final isCorrect = userAnswer == _currentDotCount;

    setState(() {
      _totalAttempts++;
      if (isCorrect) {
        _correctAnswers++;
        _feedback = 'Correct! 🎉';
        _feedbackColor = Colors.green;
      } else {
        _feedback = 'Oops! The answer was $_currentDotCount. Let\'s try another!';
        _feedbackColor = Colors.red;
      }
      _showFeedback = true;
    });

    // Track this result (we'll check time from timer stop)
    // Note: Time will be calculated by the mixin when we call onProblemComplete
    _recentResults.add({
      'correct': isCorrect,
      'timestamp': DateTime.now(),
    });

    // Record result with mixin (this triggers time tracking and completion detection)
    widget.onProblemComplete(isCorrect, userAnswerString);

    // Check if level is now complete
    _checkLevelCompletion();

    // Auto-advance after brief delay (only if not complete)
    if (!_isComplete) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_isComplete) {
          _generateNewProblem();
        }
      });
    }
  }

  void _checkLevelCompletion() {
    // Need at least 10 attempts
    if (_totalAttempts < _requiredProblems) {
      return;
    }

    // Check last 10 attempts - all must be correct
    // (We're using a simplified check here - the mixin does the full validation including time)
    final lastTen = _recentResults.length >= _requiredProblems
        ? _recentResults.sublist(_recentResults.length - _requiredProblems)
        : _recentResults;

    final allCorrect = lastTen.every((result) => result['correct'] == true);

    if (allCorrect && lastTen.length >= _requiredProblems) {
      setState(() {
        _isComplete = true;
        _feedback = '🎊 Level Complete! You\'ve mastered counting! 🎊\n\nGo back to see your progress!';
        _feedbackColor = Colors.green;
        _showFeedback = true;
      });

      // Notify parent that level is complete
      widget.onLevelComplete?.call();
    }
  }

  String _getInstructionText() {
    switch (_currentInteractionType) {
      case InteractionType.drag:
        return 'Drag each dot to the "Counted" area below';
      case InteractionType.tap:
        return 'Tap each dot as you count it';
      case InteractionType.count:
        return 'Count the dots and enter the total';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Header
          const SizedBox(height: 16),

          // Main interaction area
          Expanded(
            child: _buildInteractionArea(),
          ),

          const SizedBox(height: 24),

          // Feedback
          if (_showFeedback)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _feedbackColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _feedbackColor, width: 2),
              ),
              child: Text(
                _feedback,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _feedbackColor == Colors.grey
                      ? Colors.grey.shade800
                      : (_feedbackColor == Colors.green
                          ? Colors.green.shade800
                          : Colors.red.shade800),
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 16),

          // Submit/Check button
          _buildSubmitButton(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInteractionArea() {
    switch (_currentInteractionType) {
      case InteractionType.drag:
        return _buildDragInteraction();
      case InteractionType.tap:
        return _buildTapInteraction();
      case InteractionType.count:
        return _buildCountInteraction();
    }
  }

  Widget _buildDragInteraction() {
    return Column(
      children: [
        // Dots area
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity, // Force full width
            constraints: const BoxConstraints(
              minHeight: 200, // Prevent vertical collapse
              minWidth: 300,  // Prevent horizontal collapse
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.blue.shade50,
            ),
            child: Stack(
              children: _dots.asMap().entries.map((entry) {
                final index = entry.key;
                final dot = entry.value;

                if (dot.isCounted) return const SizedBox.shrink();

                return Positioned(
                  left: dot.position.dx,
                  top: dot.position.dy,
                  child: Draggable<int>(
                    data: index,
                    feedback: _buildDot(Colors.blue.shade400, 40),
                    childWhenDragging: const SizedBox.shrink(),
                    child: _buildDot(Colors.blue.shade600, 40),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Counted area (drag target)
        Expanded(
          flex: 1,
          child: DragTarget<int>(
            onAcceptWithDetails: (details) => _onDotDragEnd(details.data, details),
            builder: (context, candidateData, rejectedData) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: candidateData.isNotEmpty
                        ? Colors.green.shade600
                        : Colors.green.shade300,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: candidateData.isNotEmpty
                      ? Colors.green.shade100
                      : Colors.green.shade50,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        size: 48,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Counted: $_dotsCountedInArea',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Text(
                        'Drop dots here',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTapInteraction() {
    return Center(
      child: _buildDotGrid(
        _dots.asMap().entries.map((entry) {
          final index = entry.key;
          final dot = entry.value;

          return GestureDetector(
            onTap: () => _onDotTapped(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: dot.isCounted
                    ? Colors.green.shade400
                    : Colors.blue.shade600,
                shape: BoxShape.circle,
                border: Border.all(
                  color: dot.isCounted
                      ? Colors.green.shade700
                      : Colors.blue.shade800,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: dot.isCounted
                  ? const Icon(Icons.check, color: Colors.white, size: 30)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCountInteraction() {
    return Column(
      children: [
        // Dots display area (structured grid layout)
        Expanded(
          child: Center(
            child: _buildStructuredDotsGrid(),
          ),
        ),

        const SizedBox(height: 24),

        // Input area
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Count:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onSubmitted: (_) => _checkAnswer(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStructuredDotsGrid() {
    // Maximum 5 dots per row (to avoid crowding with large numbers up to 20)
    const dotsPerRow = 5;
    final rows = (_currentDotCount / dotsPerRow).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows, (rowIndex) {
        final startIdx = rowIndex * dotsPerRow;
        final endIdx = min(startIdx + dotsPerRow, _currentDotCount);
        final dotsInRow = endIdx - startIdx;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(dotsInRow, (colIndex) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildDot(Colors.blue.shade600, 40),
              );
            }),
          ),
        );
      }),
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
            offset: const Offset(2, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    // If complete, show "Go Back" button
    if (_isComplete) {
      return ElevatedButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back, size: 28),
        label: const Text(
          'Go Back to Path',
          style: TextStyle(fontSize: 20),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      );
    }

    String buttonText;
    IconData buttonIcon;

    switch (_currentInteractionType) {
      case InteractionType.drag:
        buttonText = 'Done Dragging';
        buttonIcon = Icons.check_circle;
        break;
      case InteractionType.tap:
        buttonText = 'Done Tapping';
        buttonIcon = Icons.check_circle;
        break;
      case InteractionType.count:
        buttonText = 'Submit';
        buttonIcon = Icons.check;
        break;
    }

    return ElevatedButton.icon(
      onPressed: _checkAnswer,
      icon: Icon(buttonIcon, size: 28),
      label: Text(
        buttonText,
        style: const TextStyle(fontSize: 20),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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
              padding: const EdgeInsets.all(10.0),
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
