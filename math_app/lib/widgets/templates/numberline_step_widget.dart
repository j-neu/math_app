import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'numberline_common.dart';

/// Enaktiv template widget for `numberline_step` (P2 plan §5 rule 5).
///
/// Renders a Zahlenstrahl over `display.range`. The child taps the successive
/// numbers `start+step … target` (or `start−step … target` for
/// `direction: "down"`); only the next required tick registers and the tapped
/// ticks light up in order. [onValueChanged] reports the tapped run joined
/// `","` (e.g. `"11,12,13"`) on every change — a partial run while still
/// counting, the full run once the target is reached — and `""` while no tick
/// has been tapped yet.
class NumberlineStepWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const NumberlineStepWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<NumberlineStepWidget> createState() => _NumberlineStepWidgetState();
}

class _NumberlineStepWidgetState extends State<NumberlineStepWidget> {
  final List<int> _tapped = [];
  late List<int> _required;

  int get _lo => (widget.problem.display['range'] as List).first;
  int get _hi => (widget.problem.display['range'] as List).last;

  List<int> _computeRequired() {
    final d = widget.problem.display;
    final start = d['start'] as int;
    final target = d['target'] as int;
    final step = (d['step'] as int?) ?? 1;
    final direction = (d['direction'] as String?) ?? 'up';
    final dir = direction == 'up' ? 1 : -1;
    final out = <int>[];
    for (var v = start + dir * step;
        direction == 'up' ? v <= target : v >= target;
        v += dir * step) {
      out.add(v);
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    _required = _computeRequired();
  }

  @override
  void didUpdateWidget(covariant NumberlineStepWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _tapped.clear();
      _required = _computeRequired();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  void _report() {
    if (_tapped.isEmpty) {
      widget.onValueChanged('');
      return;
    }
    widget.onValueChanged(_tapped.join(','));
  }

  void _handleTap(double dx, double width) {
    if (_tapped.length >= _required.length) return;
    final value = snappedValueForX(dx, width, _lo, _hi);
    if (value != _required[_tapped.length]) return;
    setState(() => _tapped.add(value));
    _report();
  }

  @override
  Widget build(BuildContext context) {
    final ticks = numberLineTicks(_lo, _hi);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Semantics(
              button: true,
              label: 'Zahlenstrahl',
              excludeSemantics: true,
              child: GestureDetector(
                key: const ValueKey('numberline-step-line'),
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
                      highlighted: _tapped.toSet(),
                      majorTicks: ticks.major,
                      minorTicks: ticks.minor,
                      labels: numberLineLabels(_lo, _hi),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (_tapped.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _tapped.join(' → '),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }
}
