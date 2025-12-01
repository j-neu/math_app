import 'package:flutter/material.dart';
import 'dart:math';
import 'common/scrolling_number_band.dart';

/// Level 1: Interactive Number Band (Full Visual Support)
///
/// **Source:** iMINT Card 3, Activity B (pages 77-78)
/// **Physical action from card:** Point to numbers while counting forward
/// **App translation:** Tap numbers in sequence → they highlight/animate
///
/// **Features:**
/// - Horizontal scrollable band (1-50), ~5 numbers visible at once
/// - Child taps next number in sequence, immediate visual/audio feedback
/// - Band auto-scrolls to keep current number centered
/// - Task: "Count forward from X to Y" (5-12 step sequences)
/// - Decade numbers (10, 20, 30, 40, 50) have special visual styling
///
/// **Pedagogical Purpose:**
/// - Full visual support (SEE numbers, POINT/tap, COUNT forward)
/// - Build understanding of number sequence through interactive exploration
/// - Pattern recognition: ones-digit repeats, decade transitions
///
/// **Scaffolding Level 1 of 4:**
/// This is "Zunächst wird weitergezählt mit vollständiger visueller Unterstützung"
/// (First counting forward with complete visual support)
class CountForwardLevel1Widget extends StatefulWidget {
  final Function(bool)? onProblemComplete;
  final Function()? onLevelComplete;

  const CountForwardLevel1Widget({
    Key? key,
    this.onProblemComplete,
    this.onLevelComplete,
  }) : super(key: key);

  @override
  State<CountForwardLevel1Widget> createState() =>
      _CountForwardLevel1WidgetState();
}

class _CountForwardLevel1WidgetState extends State<CountForwardLevel1Widget> {
  static const int minNumber = 1;
  static const int maxNumber = 50;
  static const int requiredProblems = 5;
  static const List<int> decadeNumbers = [10, 20, 30, 40, 50];

  int _problemsCompleted = 0;
  int _startNumber = 0;
  int _targetNumber = 0;
  int _currentPosition = 0;
  bool _isComplete = false;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateNewProblem();
  }

  void _generateNewProblem() {
    setState(() {
      // Fixed 1-50 range with varying sequence lengths
      int sequenceLength;

      if (_problemsCompleted < 2) {
        // First 2 problems: 5-7 steps
        sequenceLength = 5 + _random.nextInt(3);
      } else if (_problemsCompleted < 4) {
        // Next 2 problems: 7-9 steps
        sequenceLength = 7 + _random.nextInt(3);
      } else {
        // Final problems: 10-12 steps
        sequenceLength = 10 + _random.nextInt(3);
      }

      // Ensure we don't go beyond maxNumber
      _startNumber = minNumber + _random.nextInt(max(1, maxNumber - sequenceLength));
      _targetNumber = _startNumber + sequenceLength;
      _currentPosition = _startNumber;

      _isComplete = false;
    });
  }

  void _onNumberTapped(int number) {
    if (_isComplete) return;

    // Check if this is the correct next number
    if (number == _currentPosition) {
      // Correct tap
      setState(() {
        _currentPosition++;

        if (_currentPosition > _targetNumber) {
          // Problem complete!
          _isComplete = true;
          _problemsCompleted++;

          widget.onProblemComplete?.call(true);

          if (_problemsCompleted >= requiredProblems) {
            // Level complete
            Future.delayed(const Duration(seconds: 1), () {
              widget.onLevelComplete?.call();
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

          // Current task display
          if (!_isComplete) ...[
            Text(
              'Tap from $_startNumber to $_targetNumber',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Success message
          if (_isComplete) ...[
            Icon(Icons.check_circle, color: Colors.green[700], size: 64),
            const SizedBox(height: 16),
            Text(
              'Perfect! You counted to $_targetNumber!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],

          // Scrolling Number Band
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
