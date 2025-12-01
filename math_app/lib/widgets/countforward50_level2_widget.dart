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
/// - Child enters number they think is covered
/// - Both FORWARD and BACKWARD counting
/// - Crosses decade boundaries (19→20, 29→30)
///
/// **Pedagogical Purpose:**
/// - Partial visual support (numbers covered but context visible)
/// - Child must "think" the number under the marker
/// - Builds mental representation while retaining spatial context
/// - Prepares for Level 3 where band is completely hidden
///
/// **Scaffolding Level 2 of 4:**
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
  static const int maxNumber = 50;
  static const int requiredProblems = 12;
  static const List<int> decadeNumbers = [10, 20, 30, 40, 50];

  int _problemsCompleted = 0;
  int _startNumber = 0;
  int _targetNumber = 0;
  int _currentPosition = 0;
  int _stepCount = 0;
  bool _isForward = true;
  bool _isComplete = false;
  String _feedbackMessage = '';

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

      // Fixed 1-50 range with varying sequence lengths
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
      _answerController.clear();

      _feedbackMessage = '';
      _isComplete = false;
    });
  }

  void _checkAnswer() {
    if (_isComplete) return;

    final answer = int.tryParse(_answerController.text.trim());

    if (answer == null) {
      setState(() {
        _feedbackMessage = 'Please enter a number!';
      });
      return;
    }

    if (answer == _currentPosition) {
      // Correct answer
      setState(() {
        _stepCount++;
        _answerController.clear();
        _feedbackMessage = '';

        if (_isForward) {
          _currentPosition++;
          if (_currentPosition > _targetNumber) {
            _completeSequence();
          }
        } else {
          _currentPosition--;
          if (_currentPosition < _targetNumber) {
            _completeSequence();
          }
        }
      });
    } else {
      // Incorrect answer - show correct number
      setState(() {
        _feedbackMessage = 'The covered number was $_currentPosition. Try again!';
        _answerController.clear();
      });
    }
  }

  void _completeSequence() {
    _isComplete = true;
    _problemsCompleted++;

    widget.onProblemComplete?.call(true);

    if (_problemsCompleted >= requiredProblems) {
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
              'Step $_stepCount / ${(_targetNumber - _startNumber).abs()}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
          ],

          // Success message
          if (_isComplete) ...[
            Icon(Icons.check_circle, color: Colors.green[700], size: 64),
            const SizedBox(height: 16),
            Text(
              _isForward
                  ? 'Perfect! You counted forward!'
                  : 'Excellent! You counted backward!',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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
            allowManualScroll: true,
          ),

          const SizedBox(height: 32),

          // Feedback message
          if (_feedbackMessage.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Text(
                _feedbackMessage,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.orange[900],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],

          const Spacer(),

          // Answer input
          if (!_isComplete) ...[
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'What number is covered?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                        maxLength: 2,
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
        ],
      ),
    );
  }
}
