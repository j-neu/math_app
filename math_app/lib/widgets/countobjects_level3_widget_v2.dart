import 'package:flutter/material.dart';
import 'dart:math';

/// Level 3: Ohne äußere Handlung (No External Action)
///
/// **From Card 1:** "Der nächste Schritt ist das laute Abzählen ohne weitere äußere Handlung."
///
/// **Purpose:** Child no longer touches/moves objects - just counts by looking.
/// This is the transition from physical to mental - the objects are visible but
/// the child must count "in their head" without tactile feedback.
///
/// **App Translation:**
/// - Objects displayed on screen (visible)
/// - Child CANNOT interact with objects (no tapping, no dragging)
/// - Child must count silently by looking
/// - Child enters the total count
/// - Builds internal counting without external action support
class CountObjectsLevel3Widget extends StatefulWidget {
  final Function(int correct, int total) onProgressUpdate;

  const CountObjectsLevel3Widget({
    super.key,
    required this.onProgressUpdate,
  });

  @override
  State<CountObjectsLevel3Widget> createState() =>
      _CountObjectsLevel3WidgetState();
}

enum ObjectType {
  star,
  heart,
  circle,
  square,
  triangle,
  diamond,
}

class _CountObjectsLevel3WidgetState extends State<CountObjectsLevel3Widget>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocus = FocusNode();

  int _targetCount = 5;
  int _correctCount = 0;
  int _totalAttempts = 0;
  bool _showFeedback = false;
  bool _isCorrect = false;
  String _feedbackMessage = '';
  bool _useStructuredArrangement = true;
  List<Offset> _objectPositions = [];
  ObjectType _currentObjectType = ObjectType.star;
  Color _currentColor = Colors.amber;

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
      _currentColor = _getColorForObjectType(_currentObjectType);

      _generateObjectPositions();
      _answerController.clear();
      _showFeedback = false;
      _isCorrect = false;
      _feedbackMessage = '';
    });

    // Auto-focus input
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _answerFocus.requestFocus();
      }
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

  void _generateObjectPositions() {
    _objectPositions = [];
    if (_useStructuredArrangement) {
      _objectPositions = _generateStructuredPositions();
    } else {
      _objectPositions = _generateScatteredPositions();
    }
  }

  List<Offset> _generateStructuredPositions() {
    final positions = <Offset>[];
    // Simple grid layout
    final cols = (_targetCount / 2).ceil();
    final rows = 2;

    for (int i = 0; i < _targetCount; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      positions.add(Offset(
        (col + 0.5) / cols,
        (row + 0.5) / rows,
      ));
    }
    return positions;
  }

  List<Offset> _generateScatteredPositions() {
    final positions = <Offset>[];

    // CRITICAL: Ensure minimum distance to prevent overlaps
    const minDistance = 0.08;
    const maxAttempts = 200;

    for (int i = 0; i < _targetCount; i++) {
      bool validPosition = false;
      Offset newPos = Offset.zero;

      int attempts = 0;
      while (!validPosition && attempts < maxAttempts) {
        newPos = Offset(
          0.1 + _random.nextDouble() * 0.8,
          0.1 + _random.nextDouble() * 0.8,
        );

        // Check if too close to existing objects
        validPosition = true;
        for (final existing in positions) {
          final distance = (newPos - existing).distance;
          if (distance < minDistance) {
            validPosition = false;
            break;
          }
        }
        attempts++;
      }

      // Fallback: if we couldn't find a valid random position, use structured
      if (attempts >= maxAttempts && !validPosition) {
        return _generateStructuredPositions();
      }

      positions.add(newPos);
    }
    return positions;
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
            'Perfect! You counted $_targetCount ${_getObjectTypeName()} just by looking!';
        widget.onProgressUpdate(_correctCount, _totalAttempts);

        // Move to next problem
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _generateNewProblem();
          }
        });
      } else {
        widget.onProgressUpdate(_correctCount, _totalAttempts);
        final difference = (answer - _targetCount).abs();
        if (difference == 1) {
          _feedbackMessage =
              'Very close! Off by just 1. Try counting again carefully.';
        } else if (difference <= 3) {
          _feedbackMessage =
              'Not quite. Count each ${_currentObjectType.name} slowly with your eyes.';
        } else {
          _feedbackMessage =
              'Try again. Look at each ${_currentObjectType.name} and count in your head.';
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
              // Toggle button for structured/random layout (minimal UI)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _useStructuredArrangement = !_useStructuredArrangement;
                      _generateObjectPositions();
                    });
                  },
                  icon: Icon(
                    _useStructuredArrangement
                        ? Icons.grid_on
                        : Icons.scatter_plot,
                    size: 18,
                  ),
                  label: Text(
                    _useStructuredArrangement
                        ? 'Switch to Random'
                        : 'Switch to Structured',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _useStructuredArrangement
                        ? Colors.orange
                        : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                  ),
                ),
              ),

              // Objects area (non-interactive)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Count these ${_getObjectTypeName()}:',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Objects display
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: _objectPositions
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final position = entry.value;
                                return Positioned(
                                  left:
                                      position.dx * constraints.maxWidth - 20,
                                  top:
                                      position.dy * constraints.maxHeight - 20,
                                  child: _buildObject(
                                      _currentObjectType, _currentColor, 40),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Answer input
              Card(
                color: Colors.purple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'How many ${_getObjectTypeName()} are there?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _answerController,
                              focusNode: _answerFocus,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Count in your head...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              onSubmitted: (_) => _checkAnswer(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _checkAnswer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              padding: const EdgeInsets.all(20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Icon(Icons.check,
                                size: 32, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Feedback message
              if (_showFeedback)
                ScaleTransition(
                  scale: _feedbackAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: _isCorrect
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isCorrect ? Colors.green : Colors.orange,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isCorrect
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: _isCorrect ? Colors.green : Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _feedbackMessage,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _isCorrect
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObject(ObjectType type, Color color, double size) {
    final shadow = BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 3,
      offset: const Offset(0, 2),
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
