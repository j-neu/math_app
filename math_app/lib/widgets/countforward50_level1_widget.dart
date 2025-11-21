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
/// **Scaffolding Level 1 of 3:**
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
      // Fixed 1-20 range with varying sequence lengths
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

      _feedbackMessage = 'Tap the numbers in order and say them out loud!';
      _showSuccess = false;
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
          _feedbackMessage = 'Perfect! You counted from $_startNumber to $_targetNumber!';
          _showSuccess = true;

          widget.onProblemComplete?.call(true);

          if (_problemsCompleted >= requiredProblems) {
            // Level complete
            Future.delayed(const Duration(seconds: 2), () {
              widget.onLevelComplete?.call();
            });
          } else {
            // Generate next problem
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _generateNewProblem();
              }
            });
          }
        } else {
          _feedbackMessage = 'Keep going!';
        }
      });
    } else if (number > _currentPosition) {
      // Tapped a number ahead - hint to go in order
      setState(() {
        _feedbackMessage = 'Not so fast! Tap $_currentPosition first';
      });
    } else {
      // Tapped a number behind - already counted
      setState(() {
        _feedbackMessage = 'You already counted $number. Tap $_currentPosition next';
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
            'Level 1: Count Forward',
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
                  : theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showSuccess ? Colors.green : theme.colorScheme.primary,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                if (_showSuccess)
                  Icon(Icons.check_circle, color: Colors.green[700], size: 32)
                else
                  Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 32),
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
          const SizedBox(height: 32),

          // Current task display
          if (!_isComplete) ...[
            Text(
              'Current: $_currentPosition  →  Target: $_targetNumber',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
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

          const SizedBox(height: 32),

          // Helper text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Notice how the numbers 10, 20, 30... are highlighted? '
                    'These are "decade" numbers! The ones-digit pattern repeats after each decade.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Manual advance button (if problem complete)
          if (_isComplete && _problemsCompleted < requiredProblems)
            ElevatedButton(
              onPressed: _generateNewProblem,
              child: const Text('Next Problem'),
            ),

          if (_problemsCompleted >= requiredProblems)
            ElevatedButton.icon(
              onPressed: () => widget.onLevelComplete?.call(),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Advance to Level 2'),
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
