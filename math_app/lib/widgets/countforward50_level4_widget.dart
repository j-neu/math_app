import 'package:flutter/material.dart';
import 'dart:math';
import 'common/scrolling_number_band.dart';

/// Level 4: Finale - Victory Lap (ADHD: Easy→Hard→Easy flow)
///
/// **Purpose:** Easier mixed review after mastering Level 3's mental counting
/// **Range:** 1-50 (same as other levels)
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
  static const int maxNumber = 50;
  static const int minProblems = 10;
  static const List<int> decadeNumbers = [10, 20, 30, 40, 50];

  int _problemsCompleted = 0;
  int _startNumber = 0;
  int _targetNumber = 0;
  int _currentPosition = 0;
  bool _isForward = true;
  bool _isComplete = false;

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
          }
        } else {
          _currentPosition--;
          if (_currentPosition < _targetNumber) {
            _completeProblem(true);
          }
        }
      });
    } else {
      // Incorrect tap - record error
      widget.recordProblemResult?.call(false);
    }
  }

  void _completeProblem(bool correct) {
    _isComplete = true;
    _problemsCompleted++;

    // Record result (if callback provided)
    widget.recordProblemResult?.call(correct);
    widget.onProblemComplete?.call(correct);

    if (_problemsCompleted >= minProblems) {
      // Level complete
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          widget.onLevelComplete?.call();
        }
      });
    } else {
      // Generate next problem
      Future.delayed(const Duration(seconds: 1), () {
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

          // Direction indicator and task
          if (!_isComplete) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isForward ? Icons.arrow_forward : Icons.arrow_back,
                  size: 32,
                  color: _isForward ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Text(
                  _isForward ? 'Forward' : 'Backward',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isForward ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tap from $_startNumber to $_targetNumber',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
          ],

          // Success message
          if (_isComplete) ...[
            Icon(Icons.check_circle, color: Colors.green[700], size: 64),
            const SizedBox(height: 16),
            Text(
              'Perfect! You counted ${_isForward ? 'forward' : 'backward'}!',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],

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
        ],
      ),
    );
  }
}
