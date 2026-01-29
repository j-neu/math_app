import 'package:flutter/material.dart';

class TenStripWidget extends StatelessWidget {
  final Color color;
  final double width;
  final double height;
  final bool isMarked; // For subtraction (crossed out)

  const TenStripWidget({
    Key? key,
    this.color = Colors.blue,
    this.width = 20,
    this.height = 120,
    this.isMarked = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: List.generate(10, (index) => Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black12, width: 1)),
                ),
              ),
            )),
          ),
        ),
        if (isMarked)
          Positioned.fill(
            child: CustomPaint(
              painter: _CrossPainter(),
            ),
          ),
      ],
    );
  }
}

class _CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
