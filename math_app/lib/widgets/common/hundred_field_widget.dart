import 'package:flutter/material.dart';

/// 10×10 dot field (Hundertfeld).
///
/// Shows [visibleCount] red dots left-to-right, top-to-bottom.
/// Dotted dividers split the field vertically at column 5 and
/// horizontally between rows 5 and 6.
class HundredFieldWidget extends StatelessWidget {
  final int visibleCount;
  final Color dotColor;
  final double size;

  const HundredFieldWidget({
    super.key,
    this.visibleCount = 100,
    this.dotColor = const Color(0xFFE53935),
    this.size = 280,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HundredFieldPainter(
        visibleCount: visibleCount.clamp(0, 100),
        dotColor: dotColor,
      ),
    );
  }
}

class _HundredFieldPainter extends CustomPainter {
  final int visibleCount;
  final Color dotColor;

  const _HundredFieldPainter({
    required this.visibleCount,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(rrect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.006,
    );

    final cellW = w / 10;
    final cellH = h / 10;
    final dotRadius = cellW * 0.38;
    final dotPaint = Paint()..color = dotColor;

    for (int i = 0; i < visibleCount; i++) {
      final col = i % 10;
      final row = i ~/ 10;
      canvas.drawCircle(
        Offset((col + 0.5) * cellW, (row + 0.5) * cellH),
        dotRadius,
        dotPaint,
      );
    }

    // Vertical dotted divider between columns 5 and 6
    _drawDashed(
      canvas,
      Offset(5 * cellW, 0),
      Offset(5 * cellW, h),
      color: Colors.black54,
      strokeWidth: w * 0.004,
      dashLen: w * 0.02,
      gapLen: w * 0.02,
    );

    // Horizontal dotted divider between rows 5 and 6
    _drawDashed(
      canvas,
      Offset(0, 5 * cellH),
      Offset(w, 5 * cellH),
      color: Colors.black54,
      strokeWidth: h * 0.004,
      dashLen: h * 0.02,
      gapLen: h * 0.02,
    );
  }

  void _drawDashed(
    Canvas canvas,
    Offset start,
    Offset end, {
    required Color color,
    required double strokeWidth,
    required double dashLen,
    required double gapLen,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final total = (end - start).distance;
    final dir = (end - start) / total;
    double d = 0;
    bool drawing = true;

    while (d < total) {
      final seg = drawing ? dashLen : gapLen;
      final next = (d + seg).clamp(0.0, total);
      if (drawing) {
        canvas.drawLine(start + dir * d, start + dir * next, paint);
      }
      d = next;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(_HundredFieldPainter old) =>
      old.visibleCount != visibleCount || old.dotColor != dotColor;
}
