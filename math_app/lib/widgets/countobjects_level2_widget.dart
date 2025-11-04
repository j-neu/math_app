import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Level 2: Supported Practice for Count Objects exercise
///
/// **Purpose:** Build fluency connecting visual objects → number symbol
///
/// **How it works:**
/// - Objects displayed in structured arrangement (not random)
/// - Various object types across problems (apples, books, toys, animals)
/// - Child SEES the objects and must WRITE the number
/// - Immediate validation feedback
/// - New problem after each correct answer
///
/// **Pedagogical goal:** Practice connecting visual quantity to written number with diverse objects
/// **Unlocks Level 3:** After 10 correct answers
class CountObjectsLevel2Widget extends StatefulWidget {
  final int correctAnswersRequired;
  final Function(int correctCount) onProgressUpdate;

  const CountObjectsLevel2Widget({
    super.key,
    this.correctAnswersRequired = 10,
    required this.onProgressUpdate,
  });

  @override
  State<CountObjectsLevel2Widget> createState() =>
      _CountObjectsLevel2WidgetState();
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

class _CountObjectsLevel2WidgetState extends State<CountObjectsLevel2Widget> {
  late int _currentNumber;
  late ObjectType _currentObjectType;
  late List<Offset> _objectPositions;
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  int _correctCount = 0;
  int _totalAttempts = 0;
  String? _feedbackMessage;
  bool? _lastAnswerCorrect;

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
    final random = math.Random();
    // Generate numbers from 3 to 15 (avoiding too easy or too hard)
    _currentNumber = 3 + random.nextInt(13);

    // Pick a random object type for this problem
    _currentObjectType =
        ObjectType.values[random.nextInt(ObjectType.values.length)];

    _generateStructuredObjectPositions();
    _answerController.clear();
    _feedbackMessage = null;
    _lastAnswerCorrect = null;
  }

  void _generateStructuredObjectPositions() {
    _objectPositions = [];
    final random = math.Random();

    // Choose a structured arrangement pattern
    int pattern = random.nextInt(3);

    switch (pattern) {
      case 0: // Grid pattern
        _generateGridPattern();
        break;
      case 1: // Rows pattern
        _generateRowsPattern();
        break;
      case 2: // Grouped pattern (5-frames)
        _generateGroupedPattern();
        break;
    }
  }

  void _generateGridPattern() {
    int cols = (_currentNumber <= 6) ? 3 : 4;
    int rows = (_currentNumber / cols).ceil();
    double spacing = 60.0;
    double offsetX = 80.0;
    double offsetY = 60.0;

    for (int i = 0; i < _currentNumber; i++) {
      int row = i ~/ cols;
      int col = i % cols;
      _objectPositions.add(Offset(
        offsetX + col * spacing,
        offsetY + row * spacing,
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

  void _generateGroupedPattern() {
    // Groups of 5 (like fingers or 5-frames)
    int fullGroups = _currentNumber ~/ 5;
    int remainder = _currentNumber % 5;
    double groupSpacing = 130.0;
    double objectSpacing = 35.0;
    double offsetX = 50.0;
    double offsetY = 80.0;

    int objectIndex = 0;
    for (int group = 0; group < fullGroups; group++) {
      for (int i = 0; i < 5; i++) {
        _objectPositions.add(Offset(
          offsetX + group * groupSpacing + (i % 3) * objectSpacing,
          offsetY + (i ~/ 3) * objectSpacing,
        ));
        objectIndex++;
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

  void _checkAnswer() {
    String input = _answerController.text.trim();
    if (input.isEmpty) return;

    int? userAnswer = int.tryParse(input);
    _totalAttempts++;

    if (userAnswer == _currentNumber) {
      // Correct!
      setState(() {
        _correctCount++;
        _lastAnswerCorrect = true;
        _feedbackMessage =
            'Excellent! There are $_currentNumber ${_getObjectName(plural: true)}! 🎉';
      });

      widget.onProgressUpdate(_correctCount);

      // Auto-advance to next problem after brief delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _generateNewProblem();
          });
        }
      });
    } else {
      // Incorrect
      setState(() {
        _lastAnswerCorrect = false;
        if (userAnswer != null) {
          if (userAnswer < _currentNumber) {
            _feedbackMessage =
                'Not quite. Try counting again - there are more than $userAnswer.';
          } else {
            _feedbackMessage =
                'Not quite. Try counting again - there are fewer than $userAnswer.';
          }
        } else {
          _feedbackMessage = 'Please enter a number.';
        }
      });
    }
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
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.create, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Count the ${_getObjectName(plural: true)} and write the number!\nHow many do you see?',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
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
                'Progress: $_correctCount/${widget.correctAnswersRequired}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // Objects
                  for (int i = 0; i < _objectPositions.length; i++)
                    Positioned(
                      left: _objectPositions[i].dx,
                      top: _objectPositions[i].dy,
                      child: Text(
                        _getObjectEmoji(),
                        style: const TextStyle(fontSize: 32),
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
                    'I count',
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
                          borderSide: BorderSide(
                              color: Colors.grey.shade400, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.blue, width: 2),
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
              ElevatedButton(
                onPressed: _checkAnswer,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Check Answer',
                  style: TextStyle(fontSize: 18),
                ),
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

        const SizedBox(height: 16),
      ],
    );
  }
}
