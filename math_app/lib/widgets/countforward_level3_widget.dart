import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'common/scrolling_number_band.dart';

/// Level 3: Mental Counting - Hidden Band (No Visual Support)
///
/// **Source:** iMINT Card 3, Activity D (pages 77-78)
/// **Physical action from card:** Count with eyes closed, no visual reference
/// **App translation:** Flash starting number, then hide entire band
///
/// **Features:**
/// - Starting number shown briefly (2 seconds) then band disappears
/// - Child counts mentally from starting number to target
/// - After counting, child enters final number or entire sequence
/// - "Peek" button reveals band if child is lost (with reflection prompt)
/// - Both forward AND backward counting
/// - Adaptive difficulty (longer sequences, decade crossings)
///
/// **Pedagogical Purpose:**
/// - No visual support during counting (complete mental representation)
/// - Child must have internalized the number sequence
/// - "Die Zahlenfolge muss verinnerlicht sein"
/// - Safety net available (peek) matches card's philosophy
///
/// **Scaffolding Level 3 of 3:**
/// This is "mit geschlossenen Augen" (with closed eyes) - complete internalization
/// The final step where counting has truly "come into the head"
class CountForwardLevel3Widget extends StatefulWidget {
  final Function(bool)? onProblemComplete;
  final Function()? onLevelComplete;

  const CountForwardLevel3Widget({
    Key? key,
    this.onProblemComplete,
    this.onLevelComplete,
  }) : super(key: key);

  @override
  State<CountForwardLevel3Widget> createState() =>
      _CountForwardLevel3WidgetState();
}

class _CountForwardLevel3WidgetState extends State<CountForwardLevel3Widget> {
  static const int minNumber = 1;
  static const int maxNumber = 20;
  static const List<int> decadeNumbers = [10, 20];

  int _problemsCompleted = 0;
  int _consecutiveCorrect = 0;
  int _startNumber = 0;
  int _targetNumber = 0;
  bool _isForward = true;
  bool _bandVisible = true;
  bool _waitingForAnswer = false;
  bool _isComplete = false;
  String _feedbackMessage = '';
  bool _showSuccess = false;
  bool _peekUsed = false;

  final TextEditingController _answerController = TextEditingController();
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateNewProblem();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _generateNewProblem() {
    setState(() {
      // Randomly choose forward or backward
      _isForward = _random.nextBool();

      // Adaptive difficulty based on consecutive correct
      final sequenceLength = _consecutiveCorrect < 3
          ? 5 + _random.nextInt(3)   // 5-7 steps
          : _consecutiveCorrect < 6
              ? 8 + _random.nextInt(3)   // 8-10 steps
              : 10 + _random.nextInt(3);  // 10-12 steps

      if (_isForward) {
        // Forward counting
        _startNumber = minNumber + _random.nextInt(maxNumber - minNumber - sequenceLength + 1);
        _targetNumber = _startNumber + sequenceLength;
      } else {
        // Backward counting
        _targetNumber = minNumber + _random.nextInt(maxNumber - minNumber - sequenceLength + 1);
        _startNumber = _targetNumber + sequenceLength;
      }

      _bandVisible = true;
      _waitingForAnswer = false;
      _isComplete = false;
      _peekUsed = false;
      _answerController.clear();

      final direction = _isForward ? 'FORWARD' : 'BACKWARD';
      _feedbackMessage = 'Watch the starting position... Then count $direction in your head!';
      _showSuccess = false;
    });

    // Flash the band for 2 seconds, then hide it
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _bandVisible = false;
          _waitingForAnswer = true;
          _feedbackMessage = _isForward
              ? 'Count FORWARD from $_startNumber to $_targetNumber. What number do you land on?'
              : 'Count BACKWARD from $_startNumber to $_targetNumber. What number do you land on?';
        });
      }
    });
  }

  void _checkAnswer() {
    final answer = int.tryParse(_answerController.text.trim());

    if (answer == null) {
      setState(() {
        _feedbackMessage = 'Please enter a number!';
        _showSuccess = false;
      });
      return;
    }

    if (answer == _targetNumber) {
      // Correct!
      setState(() {
        _isComplete = true;
        _problemsCompleted++;
        _consecutiveCorrect++;
        _feedbackMessage = _isForward
            ? 'Perfect! Counting forward from $_startNumber leads to $_targetNumber!'
            : 'Excellent! Counting backward from $_startNumber leads to $_targetNumber!';
        _showSuccess = true;
        _bandVisible = true; // Show band to confirm
      });

      widget.onProblemComplete?.call(true);

      // Move to next problem or complete level
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          if (_problemsCompleted >= 8) {
            widget.onLevelComplete?.call();
          } else {
            _generateNewProblem();
          }
        }
      });
    } else {
      // Incorrect - show band and give feedback
      _consecutiveCorrect = 0; // Reset streak
      setState(() {
        _feedbackMessage = _isForward
            ? 'Not quite. Counting forward from $_startNumber to $_targetNumber lands on $_targetNumber, not $answer. Let\'s see the band!'
            : 'Not quite. Counting backward from $_startNumber to $_targetNumber lands on $_targetNumber, not $answer. Let\'s see the band!';
        _bandVisible = true; // Show as safety net
        _showSuccess = false;
      });

      // Allow retry
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _answerController.clear();
            _feedbackMessage = 'Try again! Look at the band if you need help.';
          });
        }
      });
    }
  }

  void _peekAtBand() {
    setState(() {
      _bandVisible = true;
      _peekUsed = true;
      _feedbackMessage = 'Band visible. Count along the numbers, then hide it and try again!';
    });

    // Show reflection prompt (from card: "Natürlich kann immer auch nachgeschaut werden")
    _showReflectionDialog();
  }

  void _showReflectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.amber),
            SizedBox(width: 12),
            Text('Reflection'),
          ],
        ),
        content: const Text(
          'The card says: "Natürlich kann immer auch nachgeschaut werden, '
          'wenn Kind A den Faden verloren hat."\n\n'
          '(Of course, you can always look again if you\'ve lost the thread.)\n\n'
          'Use the band to count, then try hiding it and counting in your head!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _hideBand() {
    setState(() {
      _bandVisible = false;
      _feedbackMessage = 'Band hidden. Count in your head!';
    });
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
            'Level 3: Mental Counting',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Problems: $_problemsCompleted / 8',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(width: 24),
              Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
              const SizedBox(width: 4),
              Text(
                'Streak: $_consecutiveCorrect',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Instructions / Feedback
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _showSuccess
                  ? Colors.green[100]
                  : theme.colorScheme.tertiaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showSuccess ? Colors.green : theme.colorScheme.tertiary,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                if (_showSuccess)
                  Icon(Icons.check_circle, color: Colors.green[700], size: 32)
                else
                  Icon(Icons.psychology, color: theme.colorScheme.tertiary, size: 32),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isForward ? 'Count FORWARD' : 'Count BACKWARD',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _isForward ? Colors.green : Colors.orange,
                      ),
                    ),
                    Text(
                      'From $_startNumber to $_targetNumber',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Scrolling Number Band (visible at start, then hidden)
          ScrollingNumberBand(
            minNumber: minNumber,
            maxNumber: maxNumber,
            currentPosition: _startNumber,
            visibleCount: 5,
            highlightedNumbers: decadeNumbers,
            isVisible: _bandVisible,
            onNumberTapped: null,
            allowManualScroll: false,
          ),

          const SizedBox(height: 24),

          // Answer input (only when band is hidden)
          if (_waitingForAnswer && !_isComplete) ...[
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'What number do you land on?',
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Helper text
          if (!_bandVisible && !_isComplete) ...[
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
                      'The band is hidden. Count in your head from $_startNumber!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.purple[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          const Spacer(),

          // Action buttons
          if (_waitingForAnswer && !_isComplete) ...[
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                if (!_bandVisible)
                  OutlinedButton.icon(
                    onPressed: _peekAtBand,
                    icon: const Icon(Icons.visibility),
                    label: const Text('Peek at Band'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                if (_bandVisible && _peekUsed)
                  OutlinedButton.icon(
                    onPressed: _hideBand,
                    icon: const Icon(Icons.visibility_off),
                    label: const Text('Hide Band'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _checkAnswer,
                  icon: const Icon(Icons.check),
                  label: const Text('Check Answer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (_isComplete && _problemsCompleted < 8)
            ElevatedButton(
              onPressed: _generateNewProblem,
              child: const Text('Next Problem'),
            ),

          if (_problemsCompleted >= 8)
            ElevatedButton.icon(
              onPressed: () => widget.onLevelComplete?.call(),
              icon: const Icon(Icons.celebration),
              label: const Text('Level Complete!'),
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
