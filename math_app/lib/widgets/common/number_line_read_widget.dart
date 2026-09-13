import 'package:flutter/material.dart';

import '../templates/numberline_common.dart';

/// A scaled, non-interactive number line with one unlabeled marked point --
/// for "where does the mark belong? what number is that?" items. Only the
/// endpoints and midpoint are labeled (via [numberLineLabels]); the mark
/// itself carries no number, so the child must read its position off the
/// scale and type the value.
///
/// Distinct from `ZahlenstrahlMarkWidget`/`NumberlineLocateWidget`, which are
/// the opposite interaction: tap to PLACE a marker at a GIVEN number.
class NumberLineReadWidget extends StatelessWidget {
  final int lo;
  final int hi;
  final int markAt;
  final double width;

  const NumberLineReadWidget({
    super.key,
    required this.lo,
    required this.hi,
    required this.markAt,
    this.width = 320,
  });

  @override
  Widget build(BuildContext context) {
    final ticks = numberLineTicks(lo, hi);
    return SizedBox(
      height: 72,
      width: width,
      child: CustomPaint(
        painter: ScaledNumberLinePainter(
          lo: lo,
          hi: hi,
          markAt: markAt.toDouble(),
          majorTicks: ticks.major,
          minorTicks: ticks.minor,
          labels: numberLineLabels(lo, hi),
        ),
      ),
    );
  }
}
