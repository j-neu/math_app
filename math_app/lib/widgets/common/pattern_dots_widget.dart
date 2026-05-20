import 'package:flutter/material.dart';

/// Draws [count] filled circles at normalised [positions] (0..1 in both axes)
/// inside a square canvas of [size] logical pixels.
///
/// Used for subitizing and scattered-dot questions in the diagnostic screen.
class PatternDotsWidget extends StatelessWidget {
  final List<Offset> positions;
  final int count;
  final double size;
  final Color dotColor;

  const PatternDotsWidget({
    super.key,
    required this.positions,
    required this.count,
    this.size = 280,
    this.dotColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PatternDotsPainter(
        positions: positions,
        count: count,
        dotColor: dotColor,
      ),
    );
  }
}

class _PatternDotsPainter extends CustomPainter {
  final List<Offset> positions;
  final int count;
  final Color dotColor;

  const _PatternDotsPainter({
    required this.positions,
    required this.count,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    final radius = size.width * 0.07;
    final drawCount = count.clamp(0, positions.length);
    for (int i = 0; i < drawCount; i++) {
      final p = positions[i];
      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PatternDotsPainter old) =>
      old.count != count ||
      old.dotColor != dotColor ||
      old.positions != positions;
}
