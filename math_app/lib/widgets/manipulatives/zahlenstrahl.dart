import 'package:flutter/material.dart';

/// Zahlenstrahl painter shared by the static arrow item (B2.2-01) and the
/// interactive marker item (DDB-05).
class ZahlenstrahlPainter extends CustomPainter {
  final double? arrowAt;
  final double? markAt;
  final Set<int> majorTicks;
  final Set<int> minorTicks;
  final Map<int, String> labels;

  const ZahlenstrahlPainter({
    this.arrowAt,
    this.markAt,
    this.majorTicks = const {},
    this.minorTicks = const {},
    this.labels = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 16.0;
    final right = size.width - 16.0;
    final baseline = size.height * 0.6;

    double xFor(num v) => left + (right - left) * (v / 100.0);

    canvas.drawLine(
      Offset(left, baseline),
      Offset(right, baseline),
      Paint()
        ..color = Colors.black
        ..strokeWidth = 2,
    );

    for (final v in minorTicks) {
      canvas.drawLine(
        Offset(xFor(v), baseline - 4),
        Offset(xFor(v), baseline + 4),
        Paint()
          ..color = Colors.black54
          ..strokeWidth = 1,
      );
    }
    for (final v in majorTicks) {
      canvas.drawLine(
        Offset(xFor(v), baseline - 8),
        Offset(xFor(v), baseline + 8),
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2,
      );
    }

    for (final entry in labels.entries) {
      final tp = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(xFor(entry.key) - tp.width / 2, baseline + 12));
    }

    if (arrowAt != null) {
      final x = xFor(arrowAt!);
      canvas.drawLine(
        Offset(x, baseline - 4),
        Offset(x, baseline - 30),
        Paint()
          ..color = Colors.red
          ..strokeWidth = 2.5,
      );
      final head = Path()
        ..moveTo(x, baseline - 38)
        ..lineTo(x - 8, baseline - 26)
        ..lineTo(x + 8, baseline - 26)
        ..close();
      canvas.drawPath(
        head,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill,
      );
    }

    if (markAt != null) {
      final x = xFor(markAt!);
      final head = Path()
        ..moveTo(x, baseline + 4)
        ..lineTo(x - 9, baseline + 20)
        ..lineTo(x + 9, baseline + 20)
        ..close();
      canvas.drawPath(
        head,
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(ZahlenstrahlPainter oldDelegate) =>
      oldDelegate.arrowAt != arrowAt || oldDelegate.markAt != markAt;
}

/// Static number line 0–100 with labelled anchors at 0/50/100, unlabelled
/// tens marks and a red arrow at [value] (B2.2-01).
class ZahlenstrahlArrowWidget extends StatelessWidget {
  final int value;

  const ZahlenstrahlArrowWidget({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      height: 110,
      child: CustomPaint(
        painter: ZahlenstrahlPainter(
          arrowAt: value.toDouble(),
          majorTicks: {for (var v = 0; v <= 100; v += 10) v},
          labels: const {0: '0', 50: '50', 100: '100'},
        ),
      ),
    );
  }
}

/// Interactive number line 0–100 (DDB-05): tapping places a marker snapped to
/// the nearest 5 and writes the value into [controller] (the answer). Without
/// a controller the marker is rendered statically at [initialMark].
class ZahlenstrahlMarkWidget extends StatefulWidget {
  final TextEditingController? controller;
  final double? initialMark;

  const ZahlenstrahlMarkWidget({this.controller, this.initialMark});

  @override
  State<ZahlenstrahlMarkWidget> createState() => _ZahlenstrahlMarkWidgetState();
}

class _ZahlenstrahlMarkWidgetState extends State<ZahlenstrahlMarkWidget> {
  double? _mark;

  @override
  void initState() {
    super.initState();
    _mark = widget.initialMark;
  }

  double _valueAt(double dx, double width) {
    final raw = (dx / width) * 100;
    final snapped = (raw / 5).round() * 5;
    return snapped.clamp(0, 100).toDouble();
  }

  void _handleTap(TapUpDetails details, double width) {
    final value = _valueAt(details.localPosition.dx, width);
    setState(() => _mark = value);
    widget.controller?.text = value.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) => _handleTap(details, constraints.maxWidth),
          child: SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(
              painter: ZahlenstrahlPainter(
                markAt: _mark,
                majorTicks: const {0, 25, 50, 75, 100},
                minorTicks: {for (var v = 0; v <= 100; v += 5) v},
                labels: const {0: '0', 100: '100'},
              ),
            ),
          ),
        );
      },
    );
  }
}
