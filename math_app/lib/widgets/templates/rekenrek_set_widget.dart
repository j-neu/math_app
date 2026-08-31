import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Enaktiv template widget for `rekenrek_set` (P2 plan §5 rule 4).
///
/// Renders a two-row Rekenrek (one row when `display.rows == 1`) whose beads
/// slide: tapping a bead on the left of the row slides it back, tapping an
/// empty slot on the right slides the beads left to include it.
/// [onValueChanged] reports the total number of beads pushed to the left on
/// every change, `""` while no bead has been moved yet.
class RekenrekSetWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const RekenrekSetWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<RekenrekSetWidget> createState() => _RekenrekSetWidgetState();
}

class _RekenrekSetWidgetState extends State<RekenrekSetWidget> {
  int _top = 0;
  int _bottom = 0;

  int get _rows => (widget.problem.display['rows'] as int?) ?? 2;

  int get _total => _top + _bottom;

  @override
  void didUpdateWidget(covariant RekenrekSetWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _top = 0;
      _bottom = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  void _report() {
    if (_total == 0) {
      widget.onValueChanged('');
      return;
    }
    widget.onValueChanged('$_total');
  }

  void _tapBead(bool top, int index) {
    final current = top ? _top : _bottom;
    final next = index < current ? index : index + 1;
    setState(() {
      if (top) {
        _top = next;
      } else {
        _bottom = next;
      }
    });
    _report();
  }

  Widget _rod(bool top) {
    final filled = top ? _top : _bottom;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 10; i++)
          GestureDetector(
            key: ValueKey(top ? 'bead-top-$i' : 'bead-bottom-$i'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _tapBead(top, i),
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.all(2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled
                    ? Colors.red.shade700
                    : Colors.white,
                border: Border.all(
                  color: i < filled ? Colors.red.shade700 : Colors.black26,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _rod(true),
        if (_rows > 1) ...[
          const SizedBox(height: 4),
          _rod(false),
        ],
      ],
    );
  }
}
