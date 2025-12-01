import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'common/scrolling_number_band.dart';

/// Level 2: Walking Marker with Covered Numbers (Partial Support)
///
/// **Source:** iMINT Card 3, Activity C (pages 77-78)
/// **Physical action from card:** Move counter that covers numbers while counting
/// **App translation:** Animated marker hops along, covering numbers as it moves
///
/// **Features:**
/// - Scrollable band with animated marker/character
/// - Active number is COVERED/HIDDEN by marker (shown as ?)
/// - Surrounding numbers visible for context
/// - Child taps to advance marker (must think number before seeing next)
/// - Both FORWARD and BACKWARD counting
/// - Crosses decade boundaries (19→20, 29→30)
///
/// **Pedagogical Purpose:**
/// - Partial visual support (numbers covered but context visible)
/// - Child must "think" the number under the marker
/// - Builds mental representation while retaining spatial context
/// - Prepares for Level 3 where band is completely hidden
///
/// **Scaffolding Level 2 of 3:**
/// This is "Die einzelne Zahl schon 'gedacht', da das wandernde Plättchen die Zahl jeweils verdeckt"
/// (The individual number is already "thought" as the wandering counter covers each number)
class CountForwardLevel2Widget extends StatefulWidget {
  final Function(bool)? onProblemComplete;
  final Function()? onLevelComplete;

  const CountForwardLevel2Widget({
    Key? key,
    this.onProblemComplete,
    this.onLevelComplete,
  }) : super(key: key);

  @override
  State<CountForwardLevel2Widget> createState() =>
      _CountForwardLevel2WidgetState();
}

class _CountForwardLevel2WidgetState extends State<CountForwardLevel2Widget> {
  static const int minNumber = 1;
  static const int maxNumber = 100;
  static const int requiredProblems = 12;
  static const List<int> decadeNumbers = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

  int _problemsCompleted = 0;
  int _startNumber = 0;
  int _targetNumber = 0;
  int _currentPosition = 0;
  int _stepCount = 0;
  bool _isForward = true;
  bool _isComplete = false;
  String _feedbackMessage = '';
  bool _showSuccess = false;
  bool _waitingForInput = false;

  final Random _random = Random();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _generateNewProblem();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _generateNewProblem() {
    setState(() {
      // Randomly choose forward or backward
      _isForward = _random.nextBool();

      // Fixed 1-20 range with varying sequence lengths
      int sequenceLength;

      if (_problemsCompleted < 6) {
        // First 6 problems: 5-7 steps
        sequenceLength = 5 + _random.nextInt(3);
      } else {
        // Final problems: 8-10 steps
        sequenceLength = 8 + _random.nextInt(3);
      }

      if (_isForward) {
        // Forward counting
        _startNumber = minNumber + _random.nextInt(max(1, maxNumber - sequenceLength));
        _targetNumber = _startNumber + sequenceLength;
      } else {
        // Backward counting
        _targetNumber = minNumber + _random.nextInt(max(1, maxNumber - sequenceLength));
        _startNumber = _targetNumber + sequenceLength;
      }

      _currentPosition = _startNumber;
      _stepCount = 0;
      _waitingForInput = false;
      _answerController.clear();

      _feedbackMessage = _isForward
          ? 'Count FORWARD. What number is covered by the marker?'
          : 'Count BACKWARD. What number is covered by the marker?';
      _showSuccess = false;
      _isComplete = false;
    });
  }

  void _checkAnswer() {
    if (_isComplete) return;

    final answer = int.tryParse(_answerController.text.trim());

    if (answer == null) {
      setState(() {
        _feedbackMessage = 'Please enter a number!';
        _showSuccess = false;
      });
      return;
    }

    if (answer == _currentPosition) {
      // Correct answer
      setState(() {
        _stepCount++;
        _answerController.clear();
        _waitingForInput = false;

        if (_isForward) {
          _currentPosition++;
          if (_currentPosition > _targetNumber) {
            _completeSequence();
          } else {
            _feedbackMessage = 'Correct! What number is covered now?';
          }
        } else {
          _currentPosition--;
          if (_currentPosition < _targetNumber) {
            _completeSequence();
          } else {
            _feedbackMessage = 'Correct! What number is covered now?';
          }
        }
      });
    } else {
      // Incorrect answer
      setState(() {
        _feedbackMessage = 'Not quite. The covered number is $_currentPosition. Try again!';
        _showSuccess = false;
        _answerController.clear();
      });
    }
  }

  void _completeSequence() {
    _isComplete = true;
    _problemsCompleted++;
    _feedbackMessage = _isForward
        ? 'Perfect! You counted forward from $_startNumber to $_targetNumber!'
        : 'Excellent! You counted backward from $_startNumber to $_targetNumber!';
    _showSuccess = true;

    widget.onProblemComplete?.call(true);

    if (_problemsCompleted >= requiredProblems) {
      // Level complete
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          widget.onLevelComplete?.call();
        }
      });
    } else {
      // Generate next problem
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _generateNewProblem();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Scrolling Number Band with masked current number
          ScrollingNumberBand(
            minNumber: minNumber,
            maxNumber: maxNumber,
            currentPosition: _currentPosition,
            visibleCount: 5,
            highlightedNumbers: decadeNumbers,
            maskedNumber: _currentPosition, // Current number is covered by marker
            onNumberTapped: null, // No tapping in Level 2
            allowManualScroll: true,
          ),

          const Spacer(),

          // Answer input
          if (!_isComplete) ...[
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _answerController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLength: 3,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(width: 3),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 3,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onSubmitted: (_) => _checkAnswer(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _checkAnswer,
                      icon: const Icon(Icons.check),
                      label: const Text('Check'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isForward ? Colors.green : Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (_problemsCompleted >= requiredProblems)
            ElevatedButton.icon(
              onPressed: () => widget.onLevelComplete?.call(),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue to Level 3'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
        ],
      ),
    );
  }
}
