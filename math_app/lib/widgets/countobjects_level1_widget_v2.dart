import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

/// Level 1 V2: Drag Objects to Count (No Count Feedback)
///
/// **From Card 1:** "Zuerst wird das gezählte Objekt zur Seite geschoben.
/// Dabei wird die Zählzahl genannt."
///
/// **CRITICAL DIFFERENCE:** Child is NEVER shown the count automatically.
/// They must count independently as they drag, then enter the total themselves.
///
/// **Purpose:** Learn one-to-one correspondence with various object types,
/// while building independent counting skills without automatic feedback.
///
/// **App Translation:**
/// - Various objects (stars, hearts, shapes) displayed in source area
/// - Child drags each object to "counted" area
/// - NO running count shown (unlike C1.1)
/// - After all objects moved, child enters the total count
/// - Reinforces: counting works same for all objects, mental tracking required
class CountObjectsLevel1WidgetV2 extends StatefulWidget {
  final Function(int problemsSolved) onProgressUpdate;

  const CountObjectsLevel1WidgetV2({
    super.key,
    required this.onProgressUpdate,
  });

  @override
  State<CountObjectsLevel1WidgetV2> createState() =>
      _CountObjectsLevel1WidgetV2State();
}

enum ObjectType {
  star,
  heart,
  circle,
  square,
  triangle,
  diamond,
}

class _CountObjectsLevel1WidgetV2State
    extends State<CountObjectsLevel1WidgetV2>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocus = FocusNode();

  List<ObjectInfo> _sourceObjects = [];
  List<ObjectInfo> _countedObjects = [];
  int _targetCount = 5;
  int _problemsSolved = 0;
  bool _showFeedback = false;
  bool _isCorrect = false;
  String _feedbackMessage = '';
  bool _allObjectsMovedToCountedArea = false;
  ObjectType _currentObjectType = ObjectType.star;

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
      // Adaptive difficulty: start at 5, gradually increase
      if (_problemsSolved < 3) {
        _targetCount = 5 + _random.nextInt(3); // 5-7
      } else if (_problemsSolved < 6) {
        _targetCount = 7 + _random.nextInt(4); // 7-10
      } else {
        _targetCount = 10 + _random.nextInt(6); // 10-15
      }

      // Pick random object type for this problem
      _currentObjectType =
          ObjectType.values[_random.nextInt(ObjectType.values.length)];

      _sourceObjects = List.generate(
        _targetCount,
        (i) => ObjectInfo(
          id: i,
          type: _currentObjectType,
          color: _getColorForObjectType(_currentObjectType),
        ),
      );
      _countedObjects = [];
      _answerController.clear();
      _showFeedback = false;
      _isCorrect = false;
      _feedbackMessage = '';
      _allObjectsMovedToCountedArea = false;
    });
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

  void _onObjectMoved(ObjectInfo object) {
    setState(() {
      _sourceObjects.remove(object);
      _countedObjects.add(object);

      // Check if all objects have been moved
      if (_sourceObjects.isEmpty) {
        _allObjectsMovedToCountedArea = true;
        // Auto-focus input after small delay
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
      _isCorrect = (answer == _targetCount);

      if (_isCorrect) {
        _feedbackMessage =
            'Perfect! You counted $_targetCount ${_getObjectTypeName()} correctly!';
        _problemsSolved++;
        widget.onProgressUpdate(_problemsSolved);

        // Move to next problem after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _generateNewProblem();
          }
        });
      } else {
        if (answer == _countedObjects.length) {
          _feedbackMessage =
              'You counted the ${_getObjectTypeName()} you moved: ${_countedObjects.length}. Count ALL the ${_getObjectTypeName()}!';
        } else {
          _feedbackMessage =
              'Not quite. Count again carefully - drag each ${_currentObjectType.name} and count as you go.';
        }
      }

      _showFeedback = true;
      _feedbackController.forward(from: 0);
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

              // Counting areas
              Expanded(
                child: Row(
                  children: [
                    // Source area (uncounted objects)
                    Expanded(
                      child: _buildSourceArea(),
                    ),
                    const SizedBox(width: 16),
                    // Arrow
                    const Icon(
                      Icons.arrow_forward,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    // Counted area
                    Expanded(
                      child: _buildCountedArea(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Answer input (only shown after all objects moved)
              if (_allObjectsMovedToCountedArea)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'How many ${_getObjectTypeName()} did you count?',
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
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) => _checkAnswer(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _getObjectTypeName(),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _checkAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
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
                      ],
                    ),
                  ),
                ),

              // Feedback
              if (_showFeedback)
                ScaleTransition(
                  scale: _feedbackAnimation,
                  child: Card(
                    color:
                        _isCorrect ? Colors.green.shade100 : Colors.orange.shade100,
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

  Widget _buildSourceArea() {
    return DragTarget<ObjectInfo>(
      onWillAccept: (data) => false, // Can't drag back to source
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade400, width: 2),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2, size: 20, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'To Count',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _sourceObjects.isEmpty
                    ? Center(
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green.shade300,
                        ),
                      )
                    : Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: _sourceObjects.map((obj) {
                          return Draggable<ObjectInfo>(
                            data: obj,
                            feedback: _buildObject(obj.type, obj.color, true),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _buildObject(obj.type, obj.color, false),
                            ),
                            child: _buildObject(obj.type, obj.color, false),
                            onDragCompleted: () {
                              // Handled by DragTarget
                            },
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountedArea() {
    return DragTarget<ObjectInfo>(
      onWillAccept: (data) => data != null && _sourceObjects.contains(data),
      onAccept: (data) {
        _onObjectMoved(data);
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovering = candidateData.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: isHovering ? Colors.green.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovering ? Colors.green : Colors.green.shade300,
              width: isHovering ? 3 : 2,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.done_all, size: 20, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Counted',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _countedObjects.isEmpty
                    ? Center(
                        child: Text(
                          'Drag here →',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: _countedObjects
                            .map((obj) => _buildObject(obj.type, obj.color, false))
                            .toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildObject(ObjectType type, Color color, bool isDragging) {
    final size = isDragging ? 48.0 : 40.0;
    final effectiveColor = color;
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
            painter: StarPainter(color: effectiveColor, shadow: shadow),
          ),
        );
      case ObjectType.heart:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: HeartPainter(color: effectiveColor, shadow: shadow),
          ),
        );
      case ObjectType.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: effectiveColor,
            boxShadow: [shadow],
          ),
        );
      case ObjectType.square:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [shadow],
          ),
        );
      case ObjectType.triangle:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: TrianglePainter(color: effectiveColor, shadow: shadow),
          ),
        );
      case ObjectType.diamond:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: DiamondPainter(color: effectiveColor, shadow: shadow),
          ),
        );
    }
  }
}

class ObjectInfo {
  final int id;
  final ObjectType type;
  final Color color;

  ObjectInfo({
    required this.id,
    required this.type,
    required this.color,
  });
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
