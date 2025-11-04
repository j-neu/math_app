import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Level 3: Independent Mastery for Count Objects exercise
///
/// **Purpose:** Internalize counting ability - work from mental imagery with various objects
///
/// **How it works:**
/// - Objects are FLASHED briefly (2 seconds), then HIDDEN
/// - Child must count from memory/mental imagery
/// - On incorrect answer: Objects shown again briefly (no-fail safety net)
/// - Progressive difficulty: starts at 5, increases to 20
/// - Various object types for visual diversity
///
/// **Pedagogical goal:** "Wie kommt die Handlung in den Kopf?"
/// - Child must imagine the objects (Vorstellung)
/// - Builds subitizing and estimation skills with diverse visual stimuli
/// **iMINT principle:** Visual support appears ONLY when needed
class CountObjectsLevel3Widget extends StatefulWidget {
  final Function(int correctCount) onProgressUpdate;

  const CountObjectsLevel3Widget({
    super.key,
    required this.onProgressUpdate,
  });

  @override
  State<CountObjectsLevel3Widget> createState() =>
      _CountObjectsLevel3WidgetState();
}

enum ObjectType {
  apple,
  book,
  ball,
  flower,
  car,
  butterfly,
  leaf,
  fish,
}

class _CountObjectsLevel3WidgetState extends State<CountObjectsLevel3Widget> {
  late int _currentNumber;
  late ObjectType _currentObjectType;
  late List<Offset> _objectPositions;
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  int _correctCount = 0;
  int _totalAttempts = 0;
  String? _feedbackMessage;
  bool? _lastAnswerCorrect;

  bool _objectsVisible = true; // Start visible for initial flash
  bool _flashingInitialObjects = true;
  bool _showingErrorFeedback = false;

  int _currentDifficulty = 5; // Start with 5 objects
  int _consecutiveCorrect = 0;

  final List<String> _hints = [
    'Try to remember the pattern you saw.',
    'Close your eyes and picture the objects in your mind.',
    'Were they in groups? How many groups?',
    'Don\'t worry! The objects will show again if you need help.',
  ];
  int _currentHintIndex = 0;

  @override
  void initState() {
    super.initState();
    _generateNewProblem();
    _startInitialFlash();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _generateNewProblem() {
    final random = math.Random();
    // Use current difficulty level ± 1
    _currentNumber = math.max(3, _currentDifficulty + random.nextInt(3) - 1);

    // Pick a random object type for this problem
    _currentObjectType =
        ObjectType.values[random.nextInt(ObjectType.values.length)];

    _generateStructuredObjectPositions();
    _answerController.clear();
    _feedbackMessage = null;
    _lastAnswerCorrect = null;
    _flashingInitialObjects = true;
    _showingErrorFeedback = false;
  }

  void _startInitialFlash() {
    setState(() {
      _objectsVisible = true;
      _flashingInitialObjects = true;
    });

    // Hide objects after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _flashingInitialObjects) {
        setState(() {
          _objectsVisible = false;
          _flashingInitialObjects = false;
        });
      }
    });
  }

  void _generateStructuredObjectPositions() {
    _objectPositions = [];
    final random = math.Random();

    // Always use structured patterns to make mental imagery easier
    if (_currentNumber <= 10) {
      _generateGroupedPattern(); // 5-frame pattern for easier visualization
    } else {
      _generateRowsPattern(); // Row pattern for larger numbers
    }
  }

  void _generateGroupedPattern() {
    // Groups of 5 (like fingers or 5-frames)
    int fullGroups = _currentNumber ~/ 5;
    int remainder = _currentNumber % 5;
    double groupSpacing = 130.0;
    double objectSpacing = 35.0;
    double offsetX = 50.0;
    double offsetY = 80.0;

    for (int group = 0; group < fullGroups; group++) {
      for (int i = 0; i < 5; i++) {
        _objectPositions.add(Offset(
          offsetX + group * groupSpacing + (i % 3) * objectSpacing,
          offsetY + (i ~/ 3) * objectSpacing,
        ));
      }
    }

    // Add remainder objects
    for (int i = 0; i < remainder; i++) {
      _objectPositions.add(Offset(
        offsetX + fullGroups * groupSpacing + (i % 3) * objectSpacing,
        offsetY + (i ~/ 3) * objectSpacing,
      ));
    }
  }

  void _generateRowsPattern() {
    int objectsPerRow = 5;
    int rows = (_currentNumber / objectsPerRow).ceil();
    double spacing = 50.0;
    double offsetX = 70.0;
    double offsetY = 60.0;

    for (int i = 0; i < _currentNumber; i++) {
      int row = i ~/ objectsPerRow;
      int col = i % objectsPerRow;
      _objectPositions.add(Offset(
        offsetX + col * spacing,
        offsetY + row * spacing,
      ));
    }
  }

  void _checkAnswer() {
    if (_flashingInitialObjects) return; // Don't check during initial flash

    String input = _answerController.text.trim();
    if (input.isEmpty) return;

    int? userAnswer = int.tryParse(input);
    _totalAttempts++;

    if (userAnswer == _currentNumber) {
      // Correct!
      setState(() {
        _correctCount++;
        _consecutiveCorrect++;
        _lastAnswerCorrect = true;
        _feedbackMessage =
            'Excellent! You counted $_currentNumber ${_getObjectName(plural: true)} from memory! 🎉';
      });

      widget.onProgressUpdate(_correctCount);

      // Increase difficulty after 3 consecutive correct
      if (_consecutiveCorrect >= 3 && _currentDifficulty < 20) {
        _currentDifficulty = math.min(20, _currentDifficulty + 2);
        _consecutiveCorrect = 0;
      }

      // Auto-advance to next problem after brief delay
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() {
            _generateNewProblem();
            _startInitialFlash();
          });
        }
      });
    } else {
      // Incorrect - show objects briefly as help (no-fail safety net)
      _consecutiveCorrect = 0;
      setState(() {
        _lastAnswerCorrect = false;
        _showingErrorFeedback = true;
        _objectsVisible = true; // Show objects to help

        if (userAnswer != null) {
          if (userAnswer < _currentNumber) {
            _feedbackMessage =
                'Not quite. Look at the ${_getObjectName(plural: true)} - there are more than $userAnswer. Try again!';
          } else {
            _feedbackMessage =
                'Not quite. Look at the ${_getObjectName(plural: true)} - there are fewer than $userAnswer. Try again!';
          }
        } else {
          _feedbackMessage = 'Please enter a number.';
        }
      });

      // Hide objects again after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showingErrorFeedback) {
          setState(() {
            _objectsVisible = false;
            _showingErrorFeedback = false;
            _feedbackMessage = 'Now try from memory!';
          });
        }
      });
    }
  }

  void _showNextHint() {
    setState(() {
      _currentHintIndex = (_currentHintIndex + 1) % _hints.length;
    });
  }

  void _requestPeek() {
    // Allow child to peek at objects if stuck
    setState(() {
      _objectsVisible = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _objectsVisible = false;
        });
      }
    });
  }

  String _getObjectName({bool plural = false}) {
    switch (_currentObjectType) {
      case ObjectType.apple:
        return plural ? 'apples' : 'apple';
      case ObjectType.book:
        return plural ? 'books' : 'book';
      case ObjectType.ball:
        return plural ? 'balls' : 'ball';
      case ObjectType.flower:
        return plural ? 'flowers' : 'flower';
      case ObjectType.car:
        return plural ? 'cars' : 'car';
      case ObjectType.butterfly:
        return plural ? 'butterflies' : 'butterfly';
      case ObjectType.leaf:
        return plural ? 'leaves' : 'leaf';
      case ObjectType.fish:
        return 'fish'; // Same singular/plural
    }
  }

  String _getObjectEmoji() {
    switch (_currentObjectType) {
      case ObjectType.apple:
        return '🍎';
      case ObjectType.book:
        return '📚';
      case ObjectType.ball:
        return '⚽';
      case ObjectType.flower:
        return '🌸';
      case ObjectType.car:
        return '🚗';
      case ObjectType.butterfly:
        return '🦋';
      case ObjectType.leaf:
        return '🍃';
      case ObjectType.fish:
        return '🐟';
    }
  }

  double get _accuracy =>
      _totalAttempts == 0 ? 0.0 : _correctCount / _totalAttempts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.visibility_off, color: Colors.purple, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Count from memory!\nThe objects will flash, then hide. Remember what you saw!',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              if (_flashingInitialObjects) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
                const SizedBox(height: 4),
                const Text(
                  'Watch carefully...',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),

        // Progress tracker
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Correct: $_correctCount',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Difficulty: $_currentDifficulty',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                'Accuracy: ${(_accuracy * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),

        // Objects display area
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _objectsVisible ? Colors.white : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // Hidden message
                  if (!_objectsVisible)
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.psychology, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Imagine the objects...',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Objects (visible only during flash or error feedback)
                  if (_objectsVisible)
                    for (int i = 0; i < _objectPositions.length; i++)
                      Positioned(
                        left: _objectPositions[i].dx,
                        top: _objectPositions[i].dy,
                        child: AnimatedOpacity(
                          opacity: _objectsVisible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _getObjectEmoji(),
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Answer input area
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'I counted',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _answerController,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      enabled: !_flashingInitialObjects,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '?',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade400, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.purple, width: 2),
                        ),
                      ),
                      onSubmitted: (_) => _checkAnswer(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getObjectName(plural: true),
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _flashingInitialObjects ? null : _checkAnswer,
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Check Answer',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed:
                        (_flashingInitialObjects || _objectsVisible) ? null : _requestPeek,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Peek'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Feedback message
        if (_feedbackMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _lastAnswerCorrect == true
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _lastAnswerCorrect == true ? Colors.green : Colors.orange,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _lastAnswerCorrect == true ? Icons.check_circle : Icons.info,
                  color: _lastAnswerCorrect == true ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _feedbackMessage!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

        // Hint button
        if (!_flashingInitialObjects && !_objectsVisible)
          TextButton.icon(
            onPressed: _showNextHint,
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('Need a hint?'),
          ),

        // Hint display
        if (!_flashingInitialObjects && !_objectsVisible)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.yellow.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _hints[_currentHintIndex],
                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }
}
