import 'package:flutter/material.dart';

/// Rechenstrich (empty/unmarked number line) for mental-jump items (PIKAS
/// Kartei 45): an arrow labeled with each jump size connects consecutive
/// points along a plain line with no scale or tick marks. Only [start] is
/// labeled; every landing point after a jump stays blank so the child works
/// out where it lands, rather than the picture giving the answer away.
///
/// [startOnRight] lays the points out right-to-left instead of left-to-right
/// -- for a subtraction chain like "36, -10, -4" the child reads the jumps
/// moving right to left, matching how they'd count back (Jakob's 2026-09-13
/// feedback: "the 36 needs to be on the right side... you jump left").
///
/// Distinct from the marked Zahlenstrahl (see `zahlenstrahl.dart`), which
/// shows a fixed 0..100 scale for reading off a position.
class RechenstrichWidget extends StatelessWidget {
  final int start;
  final List<int> jumps;
  final bool startOnRight;
  final double width;
  final double height;

  const RechenstrichWidget({
    super.key,
    required this.start,
    required this.jumps,
    this.startOnRight = false,
    this.width = 320,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _RechenstrichPainter(
          start: start, jumps: jumps, startOnRight: startOnRight),
    );
  }
}

class _RechenstrichPainter extends CustomPainter {
  final int start;
  final List<int> jumps;
  final bool startOnRight;

  const _RechenstrichPainter({
    required this.start,
    required this.jumps,
    required this.startOnRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pointCount = jumps.length + 1;
    final lineY = size.height * 0.68;
    final marginX = size.width * 0.1;
    final usableWidth = size.width - 2 * marginX;
    final step = pointCount > 1 ? usableWidth / (pointCount - 1) : 0.0;
    final sign = startOnRight ? -1 : 1;
    final originX = startOnRight ? size.width - marginX : marginX;

    final points = <Offset>[
      for (var i = 0; i < pointCount; i++)
        Offset(originX + sign * step * i, lineY),
    ];

    final linePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2;
    canvas.drawLine(points.first, points.last, linePaint);

    final dotPaint = Paint()..color = Colors.indigo;
    for (final p in points) {
      canvas.drawCircle(p, 5, dotPaint);
    }

    _drawText(canvas, '$start', points.first + const Offset(0, 12),
        const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        anchorAbove: false);

    final arcPaint = Paint()
      ..color = Colors.deepOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const arcHeight = 30.0;

    for (var i = 0; i < jumps.length; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final midX = (p1.dx + p2.dx) / 2;
      final control = Offset(midX, p1.dy - arcHeight);

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(control.dx, control.dy, p2.dx, p2.dy);
      canvas.drawPath(path, arcPaint);
      _drawArrowhead(canvas, control, p2, arcPaint);

      final jump = jumps[i];
      final label = jump >= 0 ? '+$jump' : '$jump';
      _drawText(
        canvas,
        label,
        Offset(midX, p1.dy - arcHeight - 8),
        const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange),
        anchorAbove: true,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset anchor, TextStyle style,
      {required bool anchorAbove}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = Offset(
      anchor.dx - tp.width / 2,
      anchorAbove ? anchor.dy - tp.height : anchor.dy,
    );
    tp.paint(canvas, offset);
  }

  void _drawArrowhead(Canvas canvas, Offset from, Offset to, Paint paint) {
    const headLength = 9.0;
    const headAngle = 0.5;
    final angle = (to - from).direction;
    final p1 = to - Offset.fromDirection(angle - headAngle, headLength);
    final p2 = to - Offset.fromDirection(angle + headAngle, headLength);
    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(p1.dx, p1.dy)
      ..moveTo(to.dx, to.dy)
      ..lineTo(p2.dx, p2.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RechenstrichPainter oldDelegate) =>
      oldDelegate.start != start ||
      oldDelegate.jumps != jumps ||
      oldDelegate.startOnRight != startOnRight;
}
