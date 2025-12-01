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
  bool _isComplete = false;
  String _feedbackMessage = '';
  bool _showSuccess = false;

  List<int> _sequence = [];
  List<int> _visibleNumbers = [];
  List<int> _hiddenIndices = [];
  List<TextEditingController> _controllers = [];
  List<FocusNode> _focusNodes = [];

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateNewProblem();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _generateNewProblem() {
    // Clean up old controllers/focus nodes
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }

    setState(() {
      // Randomly choose forward or backward
      _isForward = _random.nextBool();

      // Fixed 1-20 range with varying sequence lengths
      int sequenceLength;

      if (_problemsCompleted < 3) {
        // First 3 problems: 5-7 steps
        sequenceLength = 5 + _random.nextInt(3);
      } else if (_problemsCompleted < 6) {
        // Next 3 problems: 7-9 steps
        sequenceLength = 7 + _random.nextInt(3);
      } else {
        // Final problems: 10-12 steps
        sequenceLength = 10 + _random.nextInt(3);
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

      // Generate sequence
      _sequence = [];
      if (_isForward) {
        for (int i = _startNumber; i <= _targetNumber; i++) {
          _sequence.add(i);
        }
      } else {
        for (int i = _startNumber; i >= _targetNumber; i--) {
          _sequence.add(i);
        }
      }

      // Show first 2 and last 2, hide middle
      _hiddenIndices = [];
      for (int i = 2; i < _sequence.length - 2; i++) {
        _hiddenIndices.add(i);
      }

      // Create controllers and focus nodes for hidden numbers
      _controllers = List.generate(
        _hiddenIndices.length,
        (index) => TextEditingController(),
      );
      _focusNodes = List.generate(
        _hiddenIndices.length,
        (index) => FocusNode(),
      );

      _isComplete = false;
      _feedbackMessage = _isForward
          ? 'Fill in the missing numbers counting FORWARD'
          : 'Fill in the missing numbers counting BACKWARD';
      _showSuccess = false;
    });
  }

  void _checkAnswer() {
    // Check if all fields have values
    bool allFilled = true;
    for (var controller in _controllers) {
      if (controller.text.trim().isEmpty) {
        allFilled = false;
        break;
      }
    }

    if (!allFilled) {
      setState(() {
        _feedbackMessage = 'Please fill in all the blanks!';
        _showSuccess = false;
      });
      return;
    }

    // Validate each answer
    bool allCorrect = true;
    for (int i = 0; i < _hiddenIndices.length; i++) {
      final answer = int.tryParse(_controllers[i].text.trim());
      final expected = _sequence[_hiddenIndices[i]];

      if (answer != expected) {
        allCorrect = false;
        break;
      }
    }

    if (allCorrect) {
      // Correct!
      setState(() {
        _isComplete = true;
        _problemsCompleted++;
        _consecutiveCorrect++;
        _feedbackMessage = _isForward
            ? 'Perfect! You counted forward correctly!'
            : 'Excellent! You counted backward correctly!';
        _showSuccess = true;
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
      // Incorrect - show correct answers
      _consecutiveCorrect = 0; // Reset streak
      setState(() {
        _feedbackMessage = 'Not quite. Check your answers and try again!';
        _showSuccess = false;
      });

      // Clear wrong answers after showing feedback
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            for (var controller in _controllers) {
              controller.clear();
            }
            _feedbackMessage = _isForward
                ? 'Try again! Count forward from ${_sequence[0]}'
                : 'Try again! Count backward from ${_sequence[0]}';
          });
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
          const SizedBox(height: 16),

          // Direction indicator
          if (!_isComplete)
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _isForward ? Colors.green : Colors.orange,
                      ),
                    ),
                    Text(
                      'From $_startNumber to $_targetNumber',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),

          if (_showSuccess)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _feedbackMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Sequence display with input fields
          if (!_isComplete && _sequence.isNotEmpty) ...[
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_sequence.length, (index) {
                    // Check if this index is hidden
                    final hiddenIndex = _hiddenIndices.indexOf(index);
                    final isHidden = hiddenIndex != -1;

                    if (isHidden) {
                      // Show text field
                      return SizedBox(
                        width: 60,
                        height: 60,
                        child: TextField(
                          controller: _controllers[hiddenIndex],
                          focusNode: _focusNodes[hiddenIndex],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
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
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onSubmitted: (_) {
                            // Auto-advance to next field
                            if (hiddenIndex < _focusNodes.length - 1) {
                              _focusNodes[hiddenIndex + 1].requestFocus();
                            } else {
                              // Last field - check answer
                              _checkAnswer();
                            }
                          },
                        ),
                      );
                    } else {
                      // Show number
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${_sequence[index]}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    }
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          const Spacer(),

          // Action button
          if (!_isComplete) ...[
            ElevatedButton.icon(
              onPressed: _checkAnswer,
              icon: const Icon(Icons.check),
              label: const Text('Check Answers'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
