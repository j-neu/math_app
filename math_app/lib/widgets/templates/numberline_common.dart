library;

import 'package:flutter/material.dart';

/// Shared painting/tapping helpers for the interactive number-line template
/// widgets (`numberline_step`, `numberline_locate`).
///
/// The [ZahlenstrahlPainter] in `manipulatives/zahlenstrahl.dart` is
/// hard-coded to a 0–100 scale; these widgets support arbitrary ranges so they
/// scale a `[lo, hi]` interval into the widget width instead.

const double numberLineLeftPad = 16.0;

/// Maps a tap x-offset (relative to the line strip) to the nearest integer
/// inside `[lo, hi]`, using the same left padding the painter uses.
int snappedValueForX(double dx, double width, int lo, int hi) {
  final usable = (width - 2 * numberLineLeftPad).clamp(0.0, double.infinity);
  if (usable <= 0 || hi <= lo) return lo;
  final value = lo + (dx - numberLineLeftPad) / usable * (hi - lo);
  return (value.round()).clamp(lo, hi);
}

/// Paints a horizontal number line for an arbitrary `[lo, hi]` interval with
/// optional major/minor ticks, labels, highlighted values (filled circles) and
/// a mark triangle (blue by default).
class ScaledNumberLinePainter extends CustomPainter {
  final int lo;
  final int hi;
  final double? markAt;
  final Set<int> highlighted;
  final Set<int> majorTicks;
  final Set<int> minorTicks;
  final Map<int, String> labels;
  final Color markColor;

  const ScaledNumberLinePainter({
    required this.lo,
    required this.hi,
    this.markAt,
    this.highlighted = const {},
    this.majorTicks = const {},
    this.minorTicks = const {},
    this.labels = const {},
    this.markColor = Colors.blue,
  });

  double _xFor(num v, double width) {
    final usable = (width - 2 * numberLineLeftPad).clamp(0.0, double.infinity);
    if (usable <= 0 || hi <= lo) return width / 2;
    return numberLineLeftPad + usable * (v - lo) / (hi - lo);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height * 0.62;
    final left = _xFor(lo, size.width);
    final right = _xFor(hi, size.width);

    canvas.drawLine(
      Offset(left, baseline),
      Offset(right, baseline),
      Paint()
        ..color = Colors.black
        ..strokeWidth = 2,
    );

    for (final v in minorTicks) {
      canvas.drawLine(
        Offset(_xFor(v, size.width), baseline - 4),
        Offset(_xFor(v, size.width), baseline + 4),
        Paint()
          ..color = Colors.black54
          ..strokeWidth = 1,
      );
    }
    for (final v in majorTicks) {
      canvas.drawLine(
        Offset(_xFor(v, size.width), baseline - 8),
        Offset(_xFor(v, size.width), baseline + 8),
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
      tp.paint(
        canvas,
        Offset(_xFor(entry.key, size.width) - tp.width / 2, baseline + 14),
      );
    }

    for (final v in highlighted) {
      final x = _xFor(v, size.width);
      canvas.drawCircle(
        Offset(x, baseline - 16),
        7,
        Paint()..color = Colors.indigo,
      );
    }

    if (markAt != null) {
      final x = _xFor(markAt!, size.width);
      final head = Path()
        ..moveTo(x, baseline + 4)
        ..lineTo(x - 9, baseline + 20)
        ..lineTo(x + 9, baseline + 20)
        ..close();
      canvas.drawPath(
        head,
        Paint()
          ..color = markColor
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(ScaledNumberLinePainter oldDelegate) =>
      oldDelegate.lo != lo ||
      oldDelegate.hi != hi ||
      oldDelegate.markAt != markAt ||
      !setEquals(oldDelegate.highlighted, highlighted) ||
      oldDelegate.majorTicks != majorTicks ||
      oldDelegate.minorTicks != minorTicks;

  static bool setEquals(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }
}

/// Builds a sensible tick set for a `[lo, hi]` line: minor ticks at every
/// integer (span <= 40) or every 5, major ticks at every 5 (span <= 40) or
/// every 10.
({Set<int> major, Set<int> minor}) numberLineTicks(int lo, int hi) {
  final span = hi - lo;
  if (span <= 40) {
    return (
      major: {for (var v = lo; v <= hi; v += 5) v},
      minor: {for (var v = lo; v <= hi; v++) v},
    );
  }
  return (
    major: {for (var v = lo; v <= hi; v += 10) v},
    minor: {for (var v = lo; v <= hi; v += 5) v},
  );
}

/// Labels for the endpoints and the midpoint of a `[lo, hi]` line.
Map<int, String> numberLineLabels(int lo, int hi) {
  final mid = (lo + hi) ~/ 2;
  return {lo: '$lo', hi: '$hi', if (mid != lo && mid != hi) mid: '$mid'};
}

/// True when [value] is strictly inside `(lo, hi)` — number-line targets are
/// never endpoints.
bool isInteriorValue(int value, int lo, int hi) => value > lo && value < hi;
