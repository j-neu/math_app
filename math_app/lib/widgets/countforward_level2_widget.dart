import 'package:flutter/material.dart';
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
  static const int maxNumber = 20;
  static const int requiredProblems = 10;
  static const List<int> decadeNumbers = [10, 20];

  int _problemsCompleted = 0;
  int _startNumber = 0;
  int _targetNumber = 0;
  int _currentPosition = 0;
  int _stepCount = 0;
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
    setState(() {
      // Randomly choose forward or backward
      _isForward = _random.nextBool();

      // Generate sequence length (start with 5-7 steps, increase to 8-10 after 5 completed)
      final sequenceLength = _problemsCompleted < 5
          ? 5 + _random.nextInt(3)  // 5-7 steps
          : 8 + _random.nextInt(3);  // 8-10 steps

      if (_isForward) {
        // Forward counting
        _startNumber = minNumber + _random.nextInt(maxNumber - minNumber - sequenceLength + 1);
        _targetNumber = _startNumber + sequenceLength;
      } else {
        // Backward counting
        _targetNumber = minNumber + _random.nextInt(maxNumber - minNumber - sequenceLength + 1);
        _startNumber = _targetNumber + sequenceLength;
      }

      _currentPosition = _startNumber;
      _stepCount = 0;

      _feedbackMessage = _isForward
          ? 'Count FORWARD from $_startNumber to $_targetNumber. Tap "Next" for each step.'
          : 'Count BACKWARD from $_startNumber to $_targetNumber. Tap "Next" for each step.';
      _showSuccess = false;
      _isComplete = false;
    });
  }

  void _advanceMarker() {
    if (_isComplete) return;

    setState(() {
      _stepCount++;

      if (_isForward) {
        _currentPosition++;
        if (_currentPosition > _targetNumber) {
          _completeSequence();
        } else {
          _feedbackMessage = 'Keep going... Tap when you reach $_targetNumber';
        }
      } else {
        _currentPosition--;
        if (_currentPosition < _targetNumber) {
          _completeSequence();
        } else {
          _feedbackMessage = 'Keep going... Tap when you reach $_targetNumber';
        }
      }
    });
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
          // Header
          Text(
            'Level 2: Walking Marker',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          // Progress indicator
          Text(
            'Problems completed: $_problemsCompleted / $requiredProblems',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // Instructions / Feedback
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _showSuccess
                  ? Colors.green[100]
                  : theme.colorScheme.secondaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showSuccess ? Colors.green : theme.colorScheme.secondary,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                if (_showSuccess)
                  Icon(Icons.check_circle, color: Colors.green[700], size: 32)
                else
                  Icon(Icons.info_outline, color: theme.colorScheme.secondary, size: 32),
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
              'Step: $_stepCount / ${(_targetNumber - _startNumber).abs()}',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
          ],

          // Scrolling Number Band with masked current number
          ScrollingNumberBand(
            minNumber: minNumber,
            maxNumber: maxNumber,
            currentPosition: _currentPosition,
            visibleCount: 5,
            highlightedNumbers: decadeNumbers,
            maskedNumber: _currentPosition, // Current number is covered by marker
            onNumberTapped: null, // No tapping in Level 2
            allowManualScroll: false, // No manual scrolling
          ),

          const SizedBox(height: 32),

          // Helper text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility_off, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The marker covers the current number (shown as ?). '
                    'You must THINK what number you\'re on before moving forward!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.purple[900],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Action buttons
          if (!_isComplete) ...[
            ElevatedButton.icon(
              onPressed: _advanceMarker,
              icon: Icon(_isForward ? Icons.arrow_forward : Icons.arrow_back),
              label: Text(_isForward ? 'Next (Forward)' : 'Next (Backward)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isForward ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],

          if (_isComplete && _problemsCompleted < requiredProblems)
            ElevatedButton(
              onPressed: _generateNewProblem,
              child: const Text('Next Problem'),
            ),

          if (_problemsCompleted >= requiredProblems)
            ElevatedButton.icon(
              onPressed: () => widget.onLevelComplete?.call(),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Advance to Level 3'),
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
