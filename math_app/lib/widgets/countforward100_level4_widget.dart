import 'package:flutter/material.dart';
import 'dart:math';
import 'common/scrolling_number_band.dart';

/// Level 4: Finale - Victory Lap (ADHD: Easy→Hard→Easy flow)
///
/// **Purpose:** Easier mixed review after mastering Level 3's mental counting
/// **Range:** 1-20 (same as other levels)
/// **Visual Support:** Number band VISIBLE (restored visual support)
/// **Directions:** Both forward and backward (mixed review)
/// **Sequence Length:** 5-8 steps (shorter than L3's 10-15)
///
/// **Completion Criteria:**
/// - Minimum 10 problems
/// - Zero errors in last 10 problems (tracked by ExerciseProgressMixin)
/// - 30 seconds per problem time limit
/// - Status: notStarted → inProgress → finished → completed
///
/// **Pedagogical Purpose:**
/// - Confidence-building completion level
/// - Consolidate counting skills in mid-range
/// - Success-oriented finale (must be completable!)
/// - Prepares for future skip-counting exercises
///
/// **Scaffolding Level 4 of 4 (Finale):**
/// This provides closure and celebration after the challenging mental work of Level 3.
class CountForwardLevel4Widget extends StatefulWidget {
  final Function(bool)? onProblemComplete;
  final Function()? onLevelComplete;
  final Function()? startProblemTimer;
  final Function(bool)? recordProblemResult;

  const CountForwardLevel4Widget({
    Key? key,
    this.onProblemComplete,
    this.onLevelComplete,
    this.startProblemTimer,
    this.recordProblemResult,
  }) : super(key: key);

  @override
  State<CountForwardLevel4Widget> createState() =>
      _CountForwardLevel4WidgetState();
}

class _CountForwardLevel4WidgetState extends State<CountForwardLevel4Widget> {
  static const int minNumber = 1;
  static const int maxNumber = 100; // Same range as other levels
  static const int minProblems = 10; // Minimum for completion
  static const List<int> decadeNumbers = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

  int _problemsCompleted = 0;
  int _startNumber = 0;
  int _targetNumber = 0;
  int _currentPosition = 0;
  bool _isForward = true;
  bool _isComplete = false;
  String _feedbackMessage = '';
  bool _showSuccess = false;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateNewProblem();
  }

  void _generateNewProblem() {
    // Start problem timer (if callback provided)
    widget.startProblemTimer?.call();

    setState(() {
      // Randomly choose forward or backward
      _isForward = _random.nextBool();

      // Sequence length: 5-8 steps (easier than L3's 10-15)
      final sequenceLength = 5 + _random.nextInt(4);

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

      _feedbackMessage = _isForward
          ? 'Tap the numbers in order from $_startNumber to $_targetNumber (forward)'
          : 'Tap the numbers in order from $_startNumber to $_targetNumber (backward)';
      _showSuccess = false;
      _isComplete = false;
    });
  }

  void _onNumberTapped(int number) {
    if (_isComplete) return;

    // Check if this is the correct next number
    bool isCorrectNumber = false;

    if (_isForward) {
      isCorrectNumber = (number == _currentPosition);
    } else {
      isCorrectNumber = (number == _currentPosition);
    }

    if (isCorrectNumber) {
      // Correct tap
      setState(() {
        if (_isForward) {
          _currentPosition++;
          if (_currentPosition > _targetNumber) {
            _completeProblem(true);
          } else {
            _feedbackMessage = 'Good! Now tap $_currentPosition';
          }
        } else {
          _currentPosition--;
          if (_currentPosition < _targetNumber) {
            _completeProblem(true);
          } else {
            _feedbackMessage = 'Good! Now tap $_currentPosition';
          }
        }
      });
    } else {
      // Incorrect tap - record error
      widget.recordProblemResult?.call(false);

      setState(() {
        if (_isForward) {
          if (number > _currentPosition) {
            _feedbackMessage = 'Not so fast! Tap $_currentPosition first';
          } else {
            _feedbackMessage = 'You already counted $number. Tap $_currentPosition next';
          }
        } else {
          if (number < _currentPosition) {
            _feedbackMessage = 'Not so fast! Tap $_currentPosition first';
          } else {
            _feedbackMessage = 'You already counted $number. Tap $_currentPosition next';
          }
        }
      });
    }
  }

  void _completeProblem(bool correct) {
    _isComplete = true;
    _problemsCompleted++;

    final direction = _isForward ? 'forward' : 'backward';
    _feedbackMessage = 'Perfect! You counted $direction from $_startNumber to $_targetNumber!';
    _showSuccess = true;

    // Record result (if callback provided)
    widget.recordProblemResult?.call(correct);
    widget.onProblemComplete?.call(correct);

    if (_problemsCompleted >= minProblems) {
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Scrolling Number Band (VISIBLE for easier practice)
          ScrollingNumberBand(
            minNumber: minNumber,
            maxNumber: maxNumber,
            currentPosition: _currentPosition,
            visibleCount: 5,
            highlightedNumbers: decadeNumbers,
            onNumberTapped: _onNumberTapped,
            allowManualScroll: true,
          ),

          const Spacer(),

          if (_problemsCompleted >= minProblems)
            ElevatedButton.icon(
              onPressed: () => widget.onLevelComplete?.call(),
              icon: const Icon(Icons.celebration),
              label: const Text('Exercise Complete!'),
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
