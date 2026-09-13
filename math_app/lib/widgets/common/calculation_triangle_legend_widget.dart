import 'package:flutter/material.dart';

/// Worked example shown ahead of a real [CalculationTriangleWidget] item: a
/// fixed 1/2/4 triangle with arrows showing which two corners combine into
/// the side between them. "(siehe Bild)" alone doesn't explain the rule to
/// a child who has never seen a Rechendreieck before, so this spells it out
/// with a concrete before-and-after picture instead of leaving it to the
/// wording.
class CalculationTriangleLegendWidget extends StatelessWidget {
  final double size;

  const CalculationTriangleLegendWidget({super.key, this.size = 220});

  static const _top = Offset(0.5, 0.08);
  static const _left = Offset(0.1, 0.9);
  static const _right = Offset(0.9, 0.9);

  Offset _mid(Offset a, Offset b) =>
      Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

  // The corner circles are centered near the fractional edges (y=0.08,
  // x=0.1/0.9), so half their own diameter pokes past the triangle's [0,1]
  // box; Stack clips overflowing children by default, cutting the corners
  // off at the top and sides. This margin gives them room.
  double get _margin => size * 0.11;

  @override
  Widget build(BuildContext context) {
    final topLeftMid = _mid(_top, _left);
    final topRightMid = _mid(_top, _right);
    final bottomMid = _mid(_left, _right);
    final margin = _margin;

    Offset px(Offset frac) =>
        Offset(margin + frac.dx * size, margin + frac.dy * size);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Beispiel: Jede Seite zeigt die Summe der zwei Ecken, die sie verbindet.',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: size + 2 * margin,
          height: size + 2 * margin,
          child: Stack(
            children: [
              Positioned(
                left: margin,
                top: margin,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _TriangleLinesPainter(
                      top: _top, left: _left, right: _right),
                ),
              ),
              CustomPaint(
                size: Size(size + 2 * margin, size + 2 * margin),
                painter: _ArrowsPainter(arrows: [
                  (px(_top), px(topLeftMid)),
                  (px(_left), px(topLeftMid)),
                  (px(_top), px(topRightMid)),
                  (px(_right), px(topRightMid)),
                  (px(_left), px(bottomMid)),
                  (px(_right), px(bottomMid)),
                ]),
              ),
              _corner(_top, '1'),
              _corner(_left, '2'),
              _corner(_right, '4'),
              _side(topLeftMid, '1+2'),
              _side(topRightMid, '1+4'),
              _side(bottomMid, '2+4'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _corner(Offset frac, String label) {
    final d = size * 0.22;
    return Positioned(
      left: _margin + frac.dx * size - d / 2,
      top: _margin + frac.dy * size - d / 2,
      child: Container(
        width: d,
        height: d,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.orange.shade100,
          border: Border.all(color: Colors.deepOrange, width: 2),
        ),
        child: Text(label,
            style: TextStyle(fontSize: d * 0.4, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _side(Offset frac, String label) {
    final d = size * 0.24;
    return Positioned(
      left: _margin + frac.dx * size - d / 2,
      top: _margin + frac.dy * size - d / 2,
      child: Container(
        width: d,
        height: d,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.indigo, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: d * 0.26, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _TriangleLinesPainter extends CustomPainter {
  final Offset top;
  final Offset left;
  final Offset right;

  const _TriangleLinesPainter({
    required this.top,
    required this.left,
    required this.right,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.indigo.shade200
      ..strokeWidth = 3;
    Offset p(Offset frac) => Offset(frac.dx * size.width, frac.dy * size.height);
    canvas.drawLine(p(top), p(left), paint);
    canvas.drawLine(p(top), p(right), paint);
    canvas.drawLine(p(left), p(right), paint);
  }

  @override
  bool shouldRepaint(covariant _TriangleLinesPainter oldDelegate) => false;
}

class _ArrowsPainter extends CustomPainter {
  final List<(Offset, Offset)> arrows;

  const _ArrowsPainter({required this.arrows});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final (from, to) in arrows) {
      canvas.drawLine(from, to, paint);
      _drawArrowhead(canvas, from, to, paint);
    }
  }

  void _drawArrowhead(Canvas canvas, Offset from, Offset to, Paint paint) {
    const headLength = 9.0;
    const headAngle = 0.5; // radians
    final direction = (to - from);
    final angle = direction.direction;
    final p1 = to -
        Offset(headLength * _cos(angle - headAngle),
            headLength * _sin(angle - headAngle));
    final p2 = to -
        Offset(headLength * _cos(angle + headAngle),
            headLength * _sin(angle + headAngle));
    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(p1.dx, p1.dy)
      ..moveTo(to.dx, to.dy)
      ..lineTo(p2.dx, p2.dy);
    canvas.drawPath(path, paint);
  }

  double _cos(double a) => Offset.fromDirection(a).dx;
  double _sin(double a) => Offset.fromDirection(a).dy;

  @override
  bool shouldRepaint(covariant _ArrowsPainter oldDelegate) => false;
}
