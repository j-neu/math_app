import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'numberline_common.dart';

/// Ikonisch template widget for `numberline_locate` (P2 plan §5 rule 9).
///
/// Renders a Zahlenstrahl over `display.range`; the child taps where
/// `display.value` sits and the tap snaps to the nearest tick (integer).
/// [onValueChanged] reports the snapped value, `""` until the first tap. The
/// target is never an endpoint (`display.value` is strictly interior); a tap
/// at the very edge still snaps to the clamped endpoint.
class NumberlineLocateWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const NumberlineLocateWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<NumberlineLocateWidget> createState() => _NumberlineLocateWidgetState();
}

class _NumberlineLocateWidgetState extends State<NumberlineLocateWidget> {
  int? _mark;

  int get _lo => (widget.problem.display['range'] as List).first;
  int get _hi => (widget.problem.display['range'] as List).last;

  @override
  void didUpdateWidget(covariant NumberlineLocateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _mark = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  void _handleTap(double dx, double width) {
    final value = snappedValueForX(dx, width, _lo, _hi);
    setState(() => _mark = value);
    widget.onValueChanged('$value');
  }

  @override
  Widget build(BuildContext context) {
    final ticks = numberLineTicks(_lo, _hi);
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          key: const ValueKey('numberline-locate-line'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) =>
              _handleTap(details.localPosition.dx, constraints.maxWidth),
          child: SizedBox(
            height: 72,
            width: double.infinity,
            child: CustomPaint(
              painter: ScaledNumberLinePainter(
                lo: _lo,
                hi: _hi,
                markAt: _mark?.toDouble(),
                majorTicks: ticks.major,
                minorTicks: ticks.minor,
                labels: numberLineLabels(_lo, _hi),
              ),
            ),
          ),
        );
      },
    );
  }
}
