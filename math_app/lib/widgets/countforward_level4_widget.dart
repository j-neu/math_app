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
  static const int maxNumber = 20; // Same range as other levels
  static const int minProblems = 10; // Minimum for completion
  static const List<int> decadeNumbers = [10, 20];

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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.celebration, color: Colors.green[700], size: 28),
              const SizedBox(width: 8),
              Text(
                'Level 4: Finale',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress indicator
          Text(
            'Problems completed: $_problemsCompleted / $minProblems',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // Instructions / Feedback
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _showSuccess
                  ? Colors.green[100]
                  : Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showSuccess ? Colors.green : Colors.green[300]!,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                if (_showSuccess)
                  Icon(Icons.check_circle, color: Colors.green[700], size: 32)
                else
                  Icon(Icons.info_outline, color: Colors.green[700], size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _feedbackMessage,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Direction indicator
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
                  _isForward ? 'Counting FORWARD' : 'Counting BACKWARD',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isForward ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Current: $_currentPosition  →  Target: $_targetNumber',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
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

          const SizedBox(height: 32),

          // Helper text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.green[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is the finale! Practice counting forward and backward to 50. '
                    'The number band is visible to help you succeed!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.green[900],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Manual advance button (if problem complete)
          if (_isComplete && _problemsCompleted < minProblems)
            ElevatedButton(
              onPressed: _generateNewProblem,
              child: const Text('Next Problem'),
            ),

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
