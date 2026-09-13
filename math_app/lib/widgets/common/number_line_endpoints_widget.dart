import 'package:flutter/material.dart';

/// A Rechenstrich with only its two endpoints labeled, plus a downward arrow
/// pointing at the midpoint of the line -- for "which number lies exactly
/// between them?" items, where the picture marks *where* to look without
/// giving away the value itself.
class NumberLineEndpointsWidget extends StatelessWidget {
  final int leftValue;
  final int rightValue;
  final double width;
  final double height;

  const NumberLineEndpointsWidget({
    super.key,
    required this.leftValue,
    required this.rightValue,
    this.width = 320,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter:
          _EndpointsPainter(leftValue: leftValue, rightValue: rightValue),
    );
  }
}

class _EndpointsPainter extends CustomPainter {
  final int leftValue;
  final int rightValue;

  const _EndpointsPainter({
    required this.leftValue,
    required this.rightValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final lineY = size.height * 0.6;
    final marginX = size.width * 0.1;
    final left = Offset(marginX, lineY);
    final right = Offset(size.width - marginX, lineY);
    final midX = (left.dx + right.dx) / 2;

    final linePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2;
    canvas.drawLine(left, right, linePaint);

    final dotPaint = Paint()..color = Colors.indigo;
    canvas.drawCircle(left, 5, dotPaint);
    canvas.drawCircle(right, 5, dotPaint);

    const labelStyle = TextStyle(
        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87);
    _drawText(canvas, '$leftValue', left + const Offset(0, 12), labelStyle);
    _drawText(canvas, '$rightValue', right + const Offset(0, 12), labelStyle);

    final arrowTop = Offset(midX, lineY - 40);
    final arrowTip = Offset(midX, lineY - 6);
    final arrowPaint = Paint()
      ..color = Colors.deepOrange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(arrowTop, arrowTip, arrowPaint);
    _drawArrowhead(canvas, arrowTop, arrowTip, arrowPaint);
  }

  void _drawText(Canvas canvas, String text, Offset anchor, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(anchor.dx - tp.width / 2, anchor.dy));
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
  bool shouldRepaint(covariant _EndpointsPainter oldDelegate) =>
      oldDelegate.leftValue != leftValue ||
      oldDelegate.rightValue != rightValue;
}
