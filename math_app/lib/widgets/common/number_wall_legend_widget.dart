import 'package:flutter/material.dart';

/// Worked example shown ahead of a real [NumberWallWidget] item: a fixed
/// 1-2-4 number wall with arrows showing which two boxes combine into the
/// box above them. "(siehe Bild)" alone doesn't explain the rule to a child
/// who has never seen a Zahlenmauer before, so this spells it out with a
/// concrete before-and-after picture instead of leaving it to the wording.
class NumberWallLegendWidget extends StatelessWidget {
  final double cellSize;

  const NumberWallLegendWidget({super.key, this.cellSize = 56});

  @override
  Widget build(BuildContext context) {
    final slot = cellSize * 1.2;
    final rowGap = cellSize * 0.3;
    final rowHeight = cellSize + rowGap;
    final totalWidth = 2 * slot + cellSize;
    final totalHeight = 2 * rowHeight + cellSize;

    Offset baseTopCenter(int i) => Offset(i * slot + cellSize / 2, 2 * rowHeight);
    Offset midBottom(int j, {required bool left}) {
      final x = (j + 0.5) * slot + (left ? cellSize * 0.25 : cellSize * 0.75);
      return Offset(x, rowHeight + cellSize);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Beispiel: Jeder Stein zeigt die Summe der zwei Steine darunter.',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: totalWidth,
          height: totalHeight,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(totalWidth, totalHeight),
                painter: _ArrowsPainter(arrows: [
                  (baseTopCenter(0), midBottom(0, left: true)),
                  (baseTopCenter(1), midBottom(0, left: false)),
                  (baseTopCenter(1), midBottom(1, left: true)),
                  (baseTopCenter(2), midBottom(1, left: false)),
                ]),
              ),
              _cell(1 * slot, 0, cellSize, ''),
              _cell(0.5 * slot, rowHeight, cellSize, '1+2'),
              _cell(1.5 * slot, rowHeight, cellSize, '2+4'),
              _cell(0, 2 * rowHeight, cellSize, '1'),
              _cell(1 * slot, 2 * rowHeight, cellSize, '2'),
              _cell(2 * slot, 2 * rowHeight, cellSize, '4'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(double left, double top, double size, String label) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: label.isEmpty ? Colors.white : Colors.indigo.shade50,
          border: Border.all(color: Colors.indigo, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: size * 0.28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
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
    canvas.drawPath(path, paint..style = PaintingStyle.stroke);
  }

  double _cos(double a) => Offset.fromDirection(a).dx;
  double _sin(double a) => Offset.fromDirection(a).dy;

  @override
  bool shouldRepaint(covariant _ArrowsPainter oldDelegate) => false;
}
