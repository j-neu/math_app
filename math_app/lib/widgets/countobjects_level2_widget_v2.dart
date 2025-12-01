import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

/// Level 2 V2: Tap Objects to Count (No Count Feedback)
///
/// **From Card 1:** "Später wird es beim lauten Zählen nur angetippt."
///
/// **CRITICAL DIFFERENCE:** Child is NEVER shown the count automatically.
/// They must count independently as they tap, then enter the total themselves.
///
/// **Purpose:** Reduce physical action from dragging to tapping, while
/// building independent counting skills without automatic feedback.
///
/// **App Translation:**
/// - Various objects (apples, books, emoji) displayed on screen
/// - Child taps each object (it marks as "counted" with visual change)
/// - NO running count shown (unlike C1.1)
/// - After all objects tapped, child enters the total count
/// - Progress from moving (L1) to just touching (L2), maintaining abstraction
class CountObjectsLevel2WidgetV2 extends StatefulWidget {
  final Function(int correct, int total) onProgressUpdate;

  const CountObjectsLevel2WidgetV2({
    super.key,
    required this.onProgressUpdate,
  });

  @override
  State<CountObjectsLevel2WidgetV2> createState() =>
      _CountObjectsLevel2WidgetV2State();
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

class _CountObjectsLevel2WidgetV2State extends State<CountObjectsLevel2WidgetV2>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocus = FocusNode();

  int _targetCount = 5;
  Set<int> _tappedObjects = {};
  int _correctCount = 0;
  int _totalAttempts = 0;
  bool _showFeedback = false;
  bool _isCorrect = false;
  String _feedbackMessage = '';
  bool _allObjectsTapped = false;
  ObjectType _currentObjectType = ObjectType.apple;
  List<Offset> _objectPositions = [];

  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    );
    _generateNewProblem();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocus.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _generateNewProblem() {
    setState(() {
      // Adaptive difficulty
      if (_correctCount < 3) {
        _targetCount = 5 + _random.nextInt(3); // 5-7
      } else if (_correctCount < 7) {
        _targetCount = 7 + _random.nextInt(4); // 7-10
      } else if (_correctCount < 12) {
        _targetCount = 10 + _random.nextInt(6); // 10-15
      } else {
        _targetCount = 15 + _random.nextInt(6); // 15-20
      }

      // Pick random object type for this problem
      _currentObjectType =
          ObjectType.values[_random.nextInt(ObjectType.values.length)];

      _generateStructuredObjectPositions();
      _tappedObjects.clear();
      _answerController.clear();
      _showFeedback = false;
      _isCorrect = false;
      _feedbackMessage = '';
      _allObjectsTapped = false;
    });
  }

  void _generateStructuredObjectPositions() {
    _objectPositions = [];
    final random = Random();

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
    int cols = (_targetCount <= 6) ? 3 : 4;
    int rows = (_targetCount / cols).ceil();
    double spacing = 60.0;
    double offsetX = 80.0;
    double offsetY = 60.0;

    for (int i = 0; i < _targetCount; i++) {
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
    int rows = (_targetCount / objectsPerRow).ceil();
    double spacing = 50.0;
    double offsetX = 70.0;
    double offsetY = 60.0;

    for (int i = 0; i < _targetCount; i++) {
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
    int fullGroups = _targetCount ~/ 5;
    int remainder = _targetCount % 5;
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

  void _onObjectTapped(int objectId) {
    if (_allObjectsTapped) return; // Don't allow tapping after all done

    setState(() {
      _tappedObjects.add(objectId);

      // Check if all objects tapped
      if (_tappedObjects.length == _targetCount) {
        _allObjectsTapped = true;
        // Auto-focus input
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _answerFocus.requestFocus();
          }
        });
      }
    });
  }

  void _checkAnswer() {
    if (_answerController.text.isEmpty) return;

    final answer = int.tryParse(_answerController.text);
    if (answer == null) return;

    setState(() {
      _totalAttempts++;
      _isCorrect = (answer == _targetCount);

      if (_isCorrect) {
        _correctCount++;
        _feedbackMessage =
            'Perfect! You counted $_targetCount ${_getObjectName(plural: true)} correctly!';
        widget.onProgressUpdate(_correctCount, _totalAttempts);

        // Move to next problem
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _generateNewProblem();
          }
        });
      } else {
        widget.onProgressUpdate(_correctCount, _totalAttempts);
        if (answer == _tappedObjects.length) {
          _feedbackMessage =
              'You counted the tapped ${_getObjectName(plural: true)}: ${_tappedObjects.length}. But count ALL the ${_getObjectName(plural: true)}!';
        } else {
          _feedbackMessage =
              'Not quite. Try tapping each ${_getObjectName()} again and count carefully.';
        }
      }

      _showFeedback = true;
      _feedbackController.forward(from: 0);
    });
  }

  void _resetTaps() {
    setState(() {
      _tappedObjects.clear();
      _allObjectsTapped = false;
      _answerController.clear();
      _showFeedback = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [

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
                            child: GestureDetector(
                              onTap: () => _onObjectTapped(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                transform: Matrix4.identity()
                                  ..scale(_tappedObjects.contains(i) ? 1.1 : 1.0),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: _tappedObjects.contains(i) ? 0.5 : 1.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: _tappedObjects.contains(i)
                                          ? Border.all(
                                              color: Colors.green,
                                              width: 3,
                                            )
                                          : null,
                                    ),
                                    child: Text(
                                      _getObjectEmoji(),
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Reset button (if some tapped but not all)
              if (_tappedObjects.isNotEmpty && !_allObjectsTapped)
                TextButton.icon(
                  onPressed: _resetTaps,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Taps'),
                ),

              // Answer input (only shown after all objects tapped)
              if (_allObjectsTapped)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'How many ${_getObjectName(plural: true)} did you count?',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'I counted',
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _answerController,
                                focusNode: _answerFocus,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  hintText: '?',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade400,
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.orange,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) => _checkAnswer(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _getObjectName(plural: true),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _checkAnswer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Check Answer',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton.icon(
                              onPressed: _resetTaps,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset Taps'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Feedback
              if (_showFeedback)
                ScaleTransition(
                  scale: _feedbackAnimation,
                  child: Card(
                    color: _isCorrect
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            _isCorrect ? Icons.check_circle : Icons.info,
                            color: _isCorrect ? Colors.green : Colors.orange,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _feedbackMessage,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
