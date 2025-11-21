import 'dart:math';
import 'package:flutter/material.dart';

/// Level 5 (Finale): Mixed Review - True mixed practice from all levels
///
/// **Purpose:** ADHD-friendly Easy→Hard→Easy flow for rewarding completion
///
/// **Mixed Interaction Types:**
/// - **Type 1: Drag & Drop** (from Level 1) - Drag objects to "counted" area
/// - **Type 2: Tap/Click** (from Level 2) - Tap objects to mark as counted
/// - **Type 3: Just Count** (from Level 3) - No interaction, count by looking
///
/// **Difficulty:** Easier than Level 4 (the hardest card-prescribed level)
/// - Object count: 8-12 (medium range, not maximum 20)
/// - Layout: Structured only (grid layout for easier counting)
/// - No flash/hide mechanic (objects stay visible)
/// - Cycles through all 3 interaction types for variety
///
/// **Completion Criteria:**
/// - 10 problems minimum (mix of all 3 types)
/// - Zero errors required
/// - Time limit: <20s per problem
///
/// This level provides a "victory lap" - the child has proven mastery
/// through the 4 card-prescribed levels, now they get to demonstrate
/// consistent performance using mixed methods to end on success.
class CountObjectsLevel5Widget extends StatefulWidget {
  final VoidCallback onStartProblemTimer;
  final Function(bool correct, String? userAnswer) onProblemComplete;
  final VoidCallback? onLevelComplete; // NEW: callback when level is complete

  const CountObjectsLevel5Widget({
    super.key,
    required this.onStartProblemTimer,
    required this.onProblemComplete,
    this.onLevelComplete,
  });

  @override
  State<CountObjectsLevel5Widget> createState() =>
      _CountObjectsLevel5WidgetState();
}

enum InteractionType {
  drag, // Level 1: Drag to counted area
  tap, // Level 2: Tap to mark
  count, // Level 3: Just count
}

enum ObjectType {
  star,
  heart,
  circle,
  square,
  triangle,
  diamond,
}

class ObjectState {
  final Offset position;
  final ObjectType type;
  final Color color;
  bool isCounted;

  ObjectState({
    required this.position,
    required this.type,
    required this.color,
    this.isCounted = false,
  });
}

class _CountObjectsLevel5WidgetState extends State<CountObjectsLevel5Widget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Random _random = Random();

  int _currentObjectCount = 8;
  InteractionType _currentInteractionType = InteractionType.drag;
  List<ObjectState> _objects = [];
  int _objectsCountedInArea = 0;
  ObjectType _currentObjectType = ObjectType.star;
  Color _currentColor = Colors.amber;

  int _correctAnswers = 0;
  int _totalAttempts = 0;
  String _feedback = '';
  Color _feedbackColor = Colors.grey;
  bool _showFeedback = false;
  bool _isComplete = false; // NEW: track if level is complete

  // Completion tracking
  static const int _requiredProblems = 10;
  static const int _timeLimit = 20; // seconds
  final List<Map<String, dynamic>> _recentResults = []; // Track recent attempts

  @override
  void initState() {
    super.initState();
    _generateNewProblem();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Color _getColorForObjectType(ObjectType type) {
    switch (type) {
      case ObjectType.star:
        return Colors.amber;
      case ObjectType.heart:
        return Colors.red;
      case ObjectType.circle:
        return Colors.blue;
      case ObjectType.square:
        return Colors.green;
      case ObjectType.triangle:
        return Colors.purple;
      case ObjectType.diamond:
        return Colors.pink;
    }
  }

  String _getObjectTypeName() {
    switch (_currentObjectType) {
      case ObjectType.star:
        return 'stars';
      case ObjectType.heart:
        return 'hearts';
      case ObjectType.circle:
        return 'circles';
      case ObjectType.square:
        return 'squares';
      case ObjectType.triangle:
        return 'triangles';
      case ObjectType.diamond:
        return 'diamonds';
    }
  }

  void _generateNewProblem() {
    setState(() {
      // Random count between 8-12 (easier range)
      _currentObjectCount = 8 + _random.nextInt(5); // 8, 9, 10, 11, or 12

      // Cycle through interaction types
      _currentInteractionType = InteractionType.values[_totalAttempts % 3];

      // Pick random object type for this problem
      _currentObjectType =
          ObjectType.values[_random.nextInt(ObjectType.values.length)];
      _currentColor = _getColorForObjectType(_currentObjectType);

      // Generate objects in structured grid
      _objects = _generateStructuredObjects();
      _objectsCountedInArea = 0;

      _controller.clear();
      _showFeedback = false;
    });

    // Start timing this problem
    widget.onStartProblemTimer();

    // Auto-focus for count-only type
    if (_currentInteractionType == InteractionType.count) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  List<ObjectState> _generateStructuredObjects() {
    final List<ObjectState> objects = [];
    final objectsPerRow = _currentObjectCount <= 8 ? 4 : 5;
    final rows = (_currentObjectCount / objectsPerRow).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < objectsPerRow; col++) {
        final index = row * objectsPerRow + col;
        if (index >= _currentObjectCount) break;

        objects.add(ObjectState(
          position: Offset(
            col * 70.0 + 35.0,
            row * 70.0 + 35.0,
          ),
          type: _currentObjectType,
          color: _currentColor,
        ));
      }
    }

    return objects;
  }

  void _onObjectTapped(int index) {
    if (_currentInteractionType != InteractionType.tap) return;

    setState(() {
      _objects[index].isCounted = !_objects[index].isCounted;
    });
  }

  void _onObjectDragEnd(int index, DragTargetDetails details) {
    if (_currentInteractionType != InteractionType.drag) return;

    setState(() {
      if (!_objects[index].isCounted) {
        _objects[index].isCounted = true;
        _objectsCountedInArea++;
      }
    });
  }

  void _checkAnswer() {
    int userAnswer;
    String? userAnswerString;

    if (_currentInteractionType == InteractionType.count) {
      // For count-only, get answer from text field
      final userInput = _controller.text.trim();
      if (userInput.isEmpty) return;

      final parsedAnswer = int.tryParse(userInput);
      if (parsedAnswer == null) {
        setState(() {
          _feedback = 'Please enter a number!';
          _feedbackColor = Colors.orange;
          _showFeedback = true;
        });
        return;
      }
      userAnswer = parsedAnswer;
      userAnswerString = userInput;
    } else {
      // For drag/tap, count marked objects
      userAnswer = _objects.where((obj) => obj.isCounted).length;
      userAnswerString = userAnswer.toString();
    }

    final isCorrect = userAnswer == _currentObjectCount;

    setState(() {
      _totalAttempts++;
      if (isCorrect) {
        _correctAnswers++;
        _feedback = 'Correct!';
        _feedbackColor = Colors.green;
      } else {
        _feedback =
            'Oops! The answer was $_currentObjectCount ${_getObjectTypeName()}. Let\'s try another!';
        _feedbackColor = Colors.red;
      }
      _showFeedback = true;
    });

    // Track this result (we'll check time from timer stop)
    // Note: Time will be calculated by the mixin when we call onProblemComplete
    _recentResults.add({
      'correct': isCorrect,
      'timestamp': DateTime.now(),
    });

    // Record result with mixin (this triggers time tracking and completion detection)
    widget.onProblemComplete(isCorrect, userAnswerString);

    // Check if level is now complete
    _checkLevelCompletion();

    // Auto-advance after brief delay (only if not complete)
    if (!_isComplete) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_isComplete) {
          _generateNewProblem();
        }
      });
    }
  }

  void _checkLevelCompletion() {
    // Need at least 10 attempts
    if (_totalAttempts < _requiredProblems) {
      return;
    }

    // Check last 10 attempts - all must be correct
    // (We're using a simplified check here - the mixin does the full validation including time)
    final lastTen = _recentResults.length >= _requiredProblems
        ? _recentResults.sublist(_recentResults.length - _requiredProblems)
        : _recentResults;

    final allCorrect = lastTen.every((result) => result['correct'] == true);

    if (allCorrect && lastTen.length >= _requiredProblems) {
      setState(() {
        _isComplete = true;
        _feedback =
            'Level Complete! You\'ve mastered counting objects!\n\nGo back to see your progress!';
        _feedbackColor = Colors.green;
        _showFeedback = true;
      });

      // Notify parent that level is complete
      widget.onLevelComplete?.call();
    }
  }

  String _getInstructionText() {
    switch (_currentInteractionType) {
      case InteractionType.drag:
        return 'Drag each ${_currentObjectType.name} to the "Counted" area below';
      case InteractionType.tap:
        return 'Tap each ${_currentObjectType.name} as you count it';
      case InteractionType.count:
        return 'Count the ${_getObjectTypeName()} and enter the total';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events,
                        color: Colors.amber.shade700, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level 5: Finale - Mixed Review',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getInstructionText(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress display
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Correct: $_correctAnswers',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Total: $_totalAttempts',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_totalAttempts > 0)
                        Text(
                          'Accuracy: ${(_correctAnswers / _totalAttempts * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _correctAnswers == _totalAttempts
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Main interaction area
          Expanded(
            child: _buildInteractionArea(),
          ),

          const SizedBox(height: 24),

          // Feedback
          if (_showFeedback)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _feedbackColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _feedbackColor, width: 2),
              ),
              child: Text(
                _feedback,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _feedbackColor == Colors.grey
                      ? Colors.grey.shade800
                      : (_feedbackColor == Colors.green
                          ? Colors.green.shade800
                          : Colors.red.shade800),
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 16),

          // Submit/Check button
          _buildSubmitButton(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInteractionArea() {
    switch (_currentInteractionType) {
      case InteractionType.drag:
        return _buildDragInteraction();
      case InteractionType.tap:
        return _buildTapInteraction();
      case InteractionType.count:
        return _buildCountInteraction();
    }
  }

  Widget _buildDragInteraction() {
    return Column(
      children: [
        // Objects area
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity, // Force full width
            constraints: const BoxConstraints(
              minHeight: 200, // Prevent vertical collapse
              minWidth: 300, // Prevent horizontal collapse
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.blue.shade50,
            ),
            child: Stack(
              children: _objects.asMap().entries.map((entry) {
                final index = entry.key;
                final obj = entry.value;

                if (obj.isCounted) return const SizedBox.shrink();

                return Positioned(
                  left: obj.position.dx,
                  top: obj.position.dy,
                  child: Draggable<int>(
                    data: index,
                    feedback: _buildObject(obj.type, obj.color, 40, true),
                    childWhenDragging: const SizedBox.shrink(),
                    child: _buildObject(obj.type, obj.color, 40, false),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Counted area (drag target)
        Expanded(
          flex: 1,
          child: DragTarget<int>(
            onAcceptWithDetails: (details) =>
                _onObjectDragEnd(details.data, details),
            builder: (context, candidateData, rejectedData) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: candidateData.isNotEmpty
                        ? Colors.green.shade600
                        : Colors.green.shade300,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: candidateData.isNotEmpty
                      ? Colors.green.shade100
                      : Colors.green.shade50,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        size: 48,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Counted: $_objectsCountedInArea',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Text(
                        'Drop ${_getObjectTypeName()} here',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTapInteraction() {
    return Center(
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: _objects.asMap().entries.map((entry) {
          final index = entry.key;
          final obj = entry.value;

          return GestureDetector(
            onTap: () => _onObjectTapped(index),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: _buildObject(obj.type, obj.color, 50, false),
                ),
                if (obj.isCounted)
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: 30,
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCountInteraction() {
    return Column(
      children: [
        // Objects display area (structured grid layout)
        Expanded(
          child: Center(
            child: _buildStructuredObjectsGrid(),
          ),
        ),

        const SizedBox(height: 24),

        // Input area
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Count:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onSubmitted: (_) => _checkAnswer(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStructuredObjectsGrid() {
    final objectsPerRow = _currentObjectCount <= 8 ? 4 : 5;
    final rows = (_currentObjectCount / objectsPerRow).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows, (rowIndex) {
        final startIdx = rowIndex * objectsPerRow;
        final endIdx = min(startIdx + objectsPerRow, _currentObjectCount);
        final objectsInRow = endIdx - startIdx;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(objectsInRow, (colIndex) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildObject(
                    _currentObjectType, _currentColor, 40, false),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildObject(
      ObjectType type, Color color, double size, bool isDragging) {
    final shadow = BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: isDragging ? 8 : 4,
      offset: Offset(0, isDragging ? 4 : 2),
    );

    switch (type) {
      case ObjectType.star:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: StarPainter(color: color, shadow: shadow),
          ),
        );
      case ObjectType.heart:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: HeartPainter(color: color, shadow: shadow),
          ),
        );
      case ObjectType.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [shadow],
          ),
        );
      case ObjectType.square:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [shadow],
          ),
        );
      case ObjectType.triangle:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: TrianglePainter(color: color, shadow: shadow),
          ),
        );
      case ObjectType.diamond:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: DiamondPainter(color: color, shadow: shadow),
          ),
        );
    }
  }

  Widget _buildSubmitButton() {
    // If complete, show "Go Back" button
    if (_isComplete) {
      return ElevatedButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back, size: 28),
        label: const Text(
          'Go Back to Path',
          style: TextStyle(fontSize: 20),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      );
    }

    String buttonText;
    IconData buttonIcon;

    switch (_currentInteractionType) {
      case InteractionType.drag:
        buttonText = 'Done Dragging';
        buttonIcon = Icons.check_circle;
        break;
      case InteractionType.tap:
        buttonText = 'Done Tapping';
        buttonIcon = Icons.check_circle;
        break;
      case InteractionType.count:
        buttonText = 'Submit';
        buttonIcon = Icons.check;
        break;
    }

    return ElevatedButton.icon(
      onPressed: _checkAnswer,
      icon: Icon(buttonIcon, size: 28),
      label: Text(
        buttonText,
        style: const TextStyle(fontSize: 20),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// Custom painters for different shapes

class StarPainter extends CustomPainter {
  final Color color;
  final BoxShadow shadow;

  StarPainter({required this.color, required this.shadow});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double outerRadius = size.width / 2;
    final double innerRadius = outerRadius * 0.4;

    for (int i = 0; i < 5; i++) {
      double outerAngle = (i * 2 * pi / 5) - pi / 2;
      double innerAngle = outerAngle + pi / 5;

      double outerX = centerX + outerRadius * cos(outerAngle);
      double outerY = centerY + outerRadius * sin(outerAngle);
      double innerX = centerX + innerRadius * cos(innerAngle);
      double innerY = centerY + innerRadius * sin(innerAngle);

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HeartPainter extends CustomPainter {
  final Color color;
  final BoxShadow shadow;

  HeartPainter({required this.color, required this.shadow});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(width / 2, height * 0.35);

    path.cubicTo(
      width / 2,
      height * 0.25,
      width * 0.35,
      height * 0.1,
      width * 0.25,
      height * 0.25,
    );
    path.cubicTo(
      width * 0.1,
      height * 0.4,
      width * 0.1,
      height * 0.55,
      width / 2,
      height * 0.9,
    );
    path.cubicTo(
      width * 0.9,
      height * 0.55,
      width * 0.9,
      height * 0.4,
      width * 0.75,
      height * 0.25,
    );
    path.cubicTo(
      width * 0.65,
      height * 0.1,
      width / 2,
      height * 0.25,
      width / 2,
      height * 0.35,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TrianglePainter extends CustomPainter {
  final Color color;
  final BoxShadow shadow;

  TrianglePainter({required this.color, required this.shadow});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DiamondPainter extends CustomPainter {
  final Color color;
  final BoxShadow shadow;

  DiamondPainter({required this.color, required this.shadow});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height / 2);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
