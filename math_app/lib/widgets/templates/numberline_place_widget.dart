import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'numberline_common.dart';

/// Custom-widget template for the registry key `"numberline_place"`
/// (place_on_numberline_zr20/zr100, BUILD_ORDER.md Batch 1.6): `display.
/// targets` are shown as tappable chips; the child places each one on the
/// shared [ScaledNumberLinePainter] line (already used by `numberline_step`/
/// `numberline_locate`) by selecting a chip, then tapping the line -- the
/// tap snaps to the nearest tick via the same [snappedValueForX] helper
/// those templates already use. Placement auto-advances to the next
/// unplaced chip in generated order, but tapping any unplaced chip
/// re-targets the next tap to it. [onValueChanged] reports the placed
/// positions in generated order, comma-joined, once every chip is placed;
/// `""` while any remain.
class NumberlinePlaceWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const NumberlinePlaceWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<NumberlinePlaceWidget> createState() => _NumberlinePlaceWidgetState();
}

class _NumberlinePlaceWidgetState extends State<NumberlinePlaceWidget> {
  late List<int?> _placed;
  int _activeIndex = 0;

  int get _lo => (widget.problem.display['range'] as List).first as int;
  int get _hi => (widget.problem.display['range'] as List).last as int;

  List<int> get _targets =>
      ((widget.problem.display['targets'] as List?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList();

  @override
  void initState() {
    super.initState();
    _placed = List<int?>.filled(_targets.length, null);
  }

  @override
  void didUpdateWidget(covariant NumberlinePlaceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _placed = List<int?>.filled(_targets.length, null);
      _activeIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  void _selectChip(int index) {
    setState(() => _activeIndex = index);
  }

  void _placeActiveAt(double dx, double width) {
    if (_activeIndex < 0 || _activeIndex >= _placed.length) return;
    if (_placed[_activeIndex] != null) return;
    final value = snappedValueForX(dx, width, _lo, _hi);
    setState(() {
      _placed[_activeIndex] = value;
      final nextUnplaced = _placed.indexWhere((v) => v == null);
      _activeIndex = nextUnplaced;
    });
    if (_placed.contains(null)) {
      widget.onValueChanged('');
    } else {
      widget.onValueChanged(_placed.join(','));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticks = numberLineTicks(_lo, _hi);
    final targets = _targets;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < targets.length; i++)
              if (_placed[i] == null)
                GestureDetector(
                  key: ValueKey('np-chip-${targets[i]}'),
                  onTap: () => _selectChip(i),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == _activeIndex
                          ? Colors.orange
                          : Colors.indigo,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${targets[i]}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            return Semantics(
              button: true,
              label: 'Zahlenstrahl',
              excludeSemantics: true,
              child: GestureDetector(
                key: const ValueKey('numberline-place-line'),
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) =>
                    _placeActiveAt(details.localPosition.dx, constraints.maxWidth),
                child: SizedBox(
                  height: 72,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: ScaledNumberLinePainter(
                      lo: _lo,
                      hi: _hi,
                      highlighted: _placed.whereType<int>().toSet(),
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
      ],
    );
  }
}
