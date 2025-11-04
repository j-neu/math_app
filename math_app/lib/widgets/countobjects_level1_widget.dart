import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Level 1: Guided Exploration for Count Objects exercise
///
/// **Purpose:** Understand one-to-one correspondence with various object types
///
/// **How it works:**
/// - Various objects (stars, hearts, circles, squares) displayed randomly
/// - Child taps each object to "count" it
/// - Tapped objects highlight/brighten and counter auto-displays
/// - Child explores freely, seeing count increase as they tap
///
/// **Pedagogical goal:** Build understanding that counting works with any objects
/// **iMINT skill:** counting_1 (Count objects one by one)
class CountObjectsLevel1Widget extends StatefulWidget {
  final int numberOfObjects;
  final VoidCallback onReadyForNextLevel;

  const CountObjectsLevel1Widget({
    super.key,
    required this.numberOfObjects,
    required this.onReadyForNextLevel,
  });

  @override
  State<CountObjectsLevel1Widget> createState() =>
      _CountObjectsLevel1WidgetState();
}

enum ObjectType {
  star,
  heart,
  circle,
  square,
  triangle,
  diamond,
}

class _CountObjectsLevel1WidgetState extends State<CountObjectsLevel1Widget> {
  late List<ObjectInfo> _objects;
  final Set<int> _tappedObjects = {};
  int _countedSoFar = 0;
  int _problemsSolved = 0;

  @override
  void initState() {
    super.initState();
    _generateRandomObjects();
  }

  @override
  void didUpdateWidget(CountObjectsLevel1Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.numberOfObjects != widget.numberOfObjects) {
      _resetProblem();
    }
  }

  void _generateRandomObjects() {
    final random = math.Random();

    // Pick a random object type for this problem
    final objectType = ObjectType.values[random.nextInt(ObjectType.values.length)];

    _objects = List.generate(widget.numberOfObjects, (index) {
      // Generate random positions in a 300x300 area with padding
      return ObjectInfo(
        type: objectType,
        position: Offset(
          50 + random.nextDouble() * 250,
          50 + random.nextDouble() * 250,
        ),
        color: _getColorForObjectType(objectType),
      );
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

  void _resetProblem() {
    setState(() {
      _tappedObjects.clear();
      _countedSoFar = 0;
      _generateRandomObjects();
    });
  }

  void _onObjectTapped(int index) {
    if (_tappedObjects.contains(index)) return; // Already tapped

    setState(() {
      _tappedObjects.add(index);
      _countedSoFar = _tappedObjects.length;

      // Check if all objects are counted
      if (_countedSoFar == widget.numberOfObjects) {
        _problemsSolved++;
      }
    });
  }

  bool get _allObjectsCounted => _countedSoFar == widget.numberOfObjects;
  bool get _readyToProgress => _problemsSolved >= 3;

  String _getObjectTypeName() {
    if (_objects.isEmpty) return 'objects';

    switch (_objects[0].type) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.touch_app, color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tap each ${_getObjectTypeName().substring(0, _getObjectTypeName().length - 1)} to count!\nWatch the number grow as you tap.',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),

        // Counter display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _allObjectsCounted ? Colors.green.shade100 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _allObjectsCounted ? Colors.green : Colors.grey,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Counted: ',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '$_countedSoFar ${_getObjectTypeName()}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _allObjectsCounted
                      ? Colors.green.shade700
                      : Colors.blue.shade700,
                ),
              ),
              if (_allObjectsCounted) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

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
                  for (int i = 0; i < _objects.length; i++)
                    Positioned(
                      left: _objects[i].position.dx,
                      top: _objects[i].position.dy,
                      child: GestureDetector(
                        onTap: () => _onObjectTapped(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          width: _tappedObjects.contains(i) ? 36 : 32,
                          height: _tappedObjects.contains(i) ? 36 : 32,
                          child: _buildObject(
                            _objects[i].type,
                            _objects[i].color,
                            _tappedObjects.contains(i),
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

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Reset button
            ElevatedButton.icon(
              onPressed: _resetProblem,
              icon: const Icon(Icons.refresh),
              label: const Text('New Problem'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),

            if (_readyToProgress) ...[
              const SizedBox(width: 16),
              // Ready for next level button
              ElevatedButton.icon(
                onPressed: widget.onReadyForNextLevel,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Ready for Next Level!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 8),

        // Progress hint
        if (!_readyToProgress)
          Text(
            'Counted $_problemsSolved/3 problems. Keep exploring!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildObject(ObjectType type, Color color, bool isTapped) {
    final effectiveColor = isTapped ? color : color.withOpacity(0.6);
    final shadow = BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: isTapped ? 6 : 4,
      offset: Offset(0, isTapped ? 3 : 2),
    );

    switch (type) {
      case ObjectType.star:
        return CustomPaint(
          painter: StarPainter(color: effectiveColor, shadow: shadow),
        );
      case ObjectType.heart:
        return CustomPaint(
          painter: HeartPainter(color: effectiveColor, shadow: shadow),
        );
      case ObjectType.circle:
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: effectiveColor,
            boxShadow: [shadow],
          ),
        );
      case ObjectType.square:
        return Container(
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [shadow],
          ),
        );
      case ObjectType.triangle:
        return CustomPaint(
          painter: TrianglePainter(color: effectiveColor, shadow: shadow),
        );
      case ObjectType.diamond:
        return CustomPaint(
          painter: DiamondPainter(color: effectiveColor, shadow: shadow),
        );
    }
  }
}

class ObjectInfo {
  final ObjectType type;
  final Offset position;
  final Color color;

  ObjectInfo({
    required this.type,
    required this.position,
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
      double outerAngle = (i * 2 * math.pi / 5) - math.pi / 2;
      double innerAngle = outerAngle + math.pi / 5;

      double outerX = centerX + outerRadius * math.cos(outerAngle);
      double outerY = centerY + outerRadius * math.sin(outerAngle);
      double innerX = centerX + innerRadius * math.cos(innerAngle);
      double innerY = centerY + innerRadius * math.sin(innerAngle);

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
      width / 2, height * 0.25,
      width * 0.35, height * 0.1,
      width * 0.25, height * 0.25,
    );
    path.cubicTo(
      width * 0.1, height * 0.4,
      width * 0.1, height * 0.55,
      width / 2, height * 0.9,
    );
    path.cubicTo(
      width * 0.9, height * 0.55,
      width * 0.9, height * 0.4,
      width * 0.75, height * 0.25,
    );
    path.cubicTo(
      width * 0.65, height * 0.1,
      width / 2, height * 0.25,
      width / 2, height * 0.35,
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
