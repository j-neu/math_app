import 'package:flutter/material.dart';

enum TriangleSide { topLeft, topRight, leftRight }

/// Rechendreieck (calculation triangle): three corner numbers are given;
/// each side shows the sum of the two corners it connects. [blankSide] is
/// rendered as "?" for the child to compute (Kombinierte Strategien,
/// Arbeitskarte 10).
///
/// A first, static version — connecting lines only, no animation. Jakob
/// asked for an eventual animated "+"/arrow build-up like the number wall;
/// that's deferred as a separate, larger pass.
class CalculationTriangleWidget extends StatelessWidget {
  final int cornerTop;
  final int cornerLeft;
  final int cornerRight;
  final TriangleSide blankSide;
  final double size;

  const CalculationTriangleWidget({
    super.key,
    required this.cornerTop,
    required this.cornerLeft,
    required this.cornerRight,
    this.blankSide = TriangleSide.leftRight,
    this.size = 220,
  });

  static const Offset _top = Offset(0.5, 0.08);
  static const Offset _left = Offset(0.1, 0.9);
  static const Offset _right = Offset(0.9, 0.9);

  Offset _mid(Offset a, Offset b) => Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

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

    return SizedBox(
      width: size + 2 * margin,
      height: size + 2 * margin,
      child: Stack(
        children: [
          Positioned(
            left: margin,
            top: margin,
            child: CustomPaint(
              size: Size(size, size),
              painter:
                  _TriangleLinesPainter(top: _top, left: _left, right: _right),
            ),
          ),
          _corner(_top, cornerTop),
          _corner(_left, cornerLeft),
          _corner(_right, cornerRight),
          _side(topLeftMid,
              blankSide == TriangleSide.topLeft ? null : cornerTop + cornerLeft),
          _side(topRightMid,
              blankSide == TriangleSide.topRight ? null : cornerTop + cornerRight),
          _side(bottomMid,
              blankSide == TriangleSide.leftRight ? null : cornerLeft + cornerRight),
        ],
      ),
    );
  }

  Widget _corner(Offset frac, int value) {
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
        child: Text('$value',
            style: TextStyle(fontSize: d * 0.4, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _side(Offset frac, int? value) {
    final d = size * 0.2;
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
          value?.toString() ?? '?',
          style: TextStyle(fontSize: d * 0.4, fontWeight: FontWeight.bold),
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
