import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'numberline_common.dart';

/// Enaktiv template widget for `numberline_step` (P2 plan §5 rule 5).
///
/// Renders a Zahlenstrahl over `display.range`. The child counts stepwise
/// from the start number to the target — tapping the successive numbers
/// `start+step … target` (or `start−step … target` for `direction: "down"`).
///
/// Interaction model (§3a 2026-09-06, child-development gate on A1.2b Stufe 1):
/// precise tick-hitting was impossible for a child finger — consecutive
/// whole-number ticks sit ~8 px apart at 390 px width while a finger needs
/// ≈44 px, and off-tick taps were silently ignored. Instead:
///
///  * the current number is always visible: a large read-out above the line
///    plus a marker under the line, starting at the problem's start number;
///  * ONE tap anywhere in the counting direction (left of the marker for a
///    backward run, right of it for a forward run) advances the marker
///    exactly one required number — no precision needed, the marker can never
///    skip or overshoot;
///  * a tap in the wrong direction shows an immediate, non-punitive cue
///    ("Tippe weiter links." / "Tippe weiter rechts.") and does not advance;
///  * a tap on the current number itself is a no-op (that is where the child
///    stands), never an error.
///
/// [onValueChanged] reports the tapped run joined `","` (e.g. `"11,12,13"`)
/// on every valid step — a partial run while still counting, the full run
/// once the target is reached — and `""` before the first step. The run is
/// always correct by construction, so a submitted partial run must not be
/// possible: the caller gates submission on the full run (practice_screen).
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
  bool _wrongDirection = false;

  int get _lo => (widget.problem.display['range'] as List).first;
  int get _hi => (widget.problem.display['range'] as List).last;

  String get _direction => (widget.problem.display['direction'] as String?) ?? 'up';

  int get _start => widget.problem.display['start'] as int;

  /// The number the child currently stands on: the start number before the
  /// first step, then the last tapped number.
  int get _current => _tapped.isEmpty ? _start : _tapped.last;

  List<int> _computeRequired() {
    final d = widget.problem.display;
    final start = d['start'] as int;
    final target = d['target'] as int;
    final step = (d['step'] as int?) ?? 1;
    final dir = _direction == 'up' ? 1 : -1;
    final out = <int>[];
    for (var v = start + dir * step;
        _direction == 'up' ? v <= target : v >= target;
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
      _wrongDirection = false;
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
    final snapped = snappedValueForX(dx, width, _lo, _hi);
    final dir = _direction == 'up' ? 1 : -1;
    final current = _current;
    // Counting direction: forward runs advance to the right, backward runs to
    // the left. Tapping the number the child stands on is a no-op, not an
    // error; only a tap on the wrong side gets the direction cue.
    if (dir > 0 ? snapped <= current : snapped >= current) {
      if (snapped != current) {
        setState(() => _wrongDirection = true);
      }
      return;
    }
    final next = _required[_tapped.length];
    setState(() {
      _tapped.add(next);
      _wrongDirection = false;
    });
    _report();
  }

  @override
  Widget build(BuildContext context) {
    final ticks = numberLineTicks(_lo, _hi);
    final dir = _direction;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Large read-out of the number the child is at / just counted.
        Text(
          '$_current',
          key: const ValueKey('numberline-current'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 44,
            height: 1.1,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
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
                      markAt: _current.toDouble(),
                      markColor: Colors.indigo,
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
        // Fixed-height cue line so showing the hint never shifts the layout.
        SizedBox(
          height: 28,
          child: Center(
            child: _wrongDirection
                ? Text(
                    dir == 'up' ? 'Tippe weiter rechts.' : 'Tippe weiter links.',
                    key: const ValueKey('numberline-direction-hint'),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
