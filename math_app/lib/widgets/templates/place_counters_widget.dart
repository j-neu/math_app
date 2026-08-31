import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Enaktiv template widget for `place_counters` (P2 plan §5 rule 2).
///
/// Renders a grid of tappable cells (a 5×2 ten-frame or a 10×2 Rekenrek).
///
/// * action `fill`: tapping a cell fills it (tap again to unfill);
///   [onValueChanged] reports the filled count, `""` while none are filled.
/// * action `take_away`: `display.total` cells start filled; tapping removes
///   (tap an empty cell to put it back); the remaining count is reported once
///   the child has made at least one change (`""` before, `"0"` when all are
///   removed).
/// * mode `nonstandard` (B2.3): a Stellenwerttafel with Z/E columns whose
///   Einer column may hold more than 9. Tapping a column adds a counter,
///   tapping its counters removes one; `"Z E"` (e.g. `"1 13"`) is reported
///   while anything is placed and the evaluator checks `10*Z + E == count`.
class PlaceCountersWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const PlaceCountersWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<PlaceCountersWidget> createState() => _PlaceCountersWidgetState();
}

class _PlaceCountersWidgetState extends State<PlaceCountersWidget> {
  late final Set<int> _filledCells;
  late bool _changed;
  late int _z;
  late int _e;
  bool _tooManyRemoved = false;

  String get _action => (widget.problem.display['action'] as String?) ?? 'fill';
  String get _mode => (widget.problem.display['mode'] as String?) ?? 'standard';
  String get _frame =>
      (widget.problem.display['frame'] as String?) ?? 'zehnerfeld';
  int get _total => (widget.problem.display['total'] as int?) ?? 0;

  /// How many cells the child must remove in `take_away` tasks — the operand
  /// of the rendered equation, not the expected answer.
  int get _removeCount => (widget.problem.display['count'] as int?) ?? 0;
  String get _op => (widget.problem.display['op'] as String?) ?? '-';

  bool get _isNonstandard => _mode == 'nonstandard';

  int get _columns => _frame == 'rekenrek' ? 10 : 5;
  int get _capacity => _isNonstandard
      ? 99
      : (_frame == 'rekenrek' ? 20 : (_frame == 'stellenwerttafel' ? 99 : 10));

  @override
  void initState() {
    super.initState();
    _filledCells = _action == 'take_away'
        ? {for (var i = 0; i < _total; i++) i}
        : <int>{};
    _changed = false;
    _z = 0;
    _e = 0;
    _tooManyRemoved = false;
  }

  void _reset() {
    _filledCells
      ..clear()
      ..addAll(
        _action == 'take_away'
            ? {for (var i = 0; i < _total; i++) i}
            : const <int>{},
      );
    _changed = false;
    _z = 0;
    _e = 0;
    _tooManyRemoved = false;
  }

  @override
  void didUpdateWidget(covariant PlaceCountersWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _reset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  void _report() {
    if (_isNonstandard) {
      if (_z + _e == 0) {
        widget.onValueChanged('');
        return;
      }
      widget.onValueChanged('$_z $_e');
      return;
    }
    if (_action == 'take_away') {
      if (!_changed) {
        widget.onValueChanged('');
        return;
      }
      widget.onValueChanged('${_filledCells.length}');
      return;
    }
    if (_filledCells.isEmpty) {
      widget.onValueChanged('');
      return;
    }
    widget.onValueChanged('${_filledCells.length}');
  }

  void _toggleCell(int index) {
    if (_filledCells.contains(index)) {
      _filledCells.remove(index);
    } else {
      _filledCells.add(index);
    }
    _changed = true;
    // The child may remove at most `count` cells: removing more leaves fewer
    // than the intended remainder, so flag it with a friendly inline hint.
    if (_action == 'take_away') {
      final removed = _total - _filledCells.length;
      _tooManyRemoved = _removeCount > 0 && removed > _removeCount;
    } else {
      _tooManyRemoved = false;
    }
    setState(() {});
    _report();
  }

  void _addToColumn(bool tens) {
    if (tens) {
      if (_z >= 9) return;
      _z++;
    } else {
      if (_e >= 20) return;
      _e++;
    }
    setState(() {});
    _report();
  }

  void _removeFromColumn(bool tens) {
    if (tens) {
      if (_z == 0) return;
      _z--;
    } else {
      if (_e == 0) return;
      _e--;
    }
    setState(() {});
    _report();
  }

  @override
  Widget build(BuildContext context) {
    if (_isNonstandard) {
      return _buildStellenwerttafel();
    }
    final takeAway = _action == 'take_away';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (takeAway) ...[
          Text(
            '$_total ${_op == '-' ? '\u2212' : _op} $_removeCount = ?',
            key: const ValueKey('pc-equation'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var c = 0; c < _columns; c++) _cell(c),
          ],
        ),
        if (_capacity > _columns) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var c = _columns; c < _capacity; c++) _cell(c),
            ],
          ),
        ],
        if (takeAway && _tooManyRemoved) ...[
          const SizedBox(height: 6),
          Text(
            'Nimm nur $_removeCount Plättchen weg.',
            key: const ValueKey('pc-takeaway-hint'),
            style: const TextStyle(fontSize: 15, color: Color(0xFFE65100)),
          ),
        ],
      ],
    );
  }

  Widget _cell(int index) {
    final isFilled = _filledCells.contains(index);
    final label = _action == 'take_away'
        ? (isFilled
            ? 'Plättchen ${index + 1} wegnehmen'
            : 'Plättchen ${index + 1} zurücklegen')
        : (isFilled
            ? 'Plättchen ${index + 1} weglegen'
            : 'Plättchen ${index + 1} hinlegen');
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('pc-cell-$index'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggleCell(index),
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? Colors.indigo : Colors.transparent,
            border: Border.all(
              color: isFilled ? Colors.indigo : Colors.blueGrey,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStellenwerttafel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_columnBox(true), const SizedBox(width: 8), _columnBox(false)],
        ),
      ],
    );
  }

  Widget _columnBox(bool isTens) {
    final value = isTens ? _z : _e;
    return Container(
      width: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isTens ? 'Z' : 'E',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            key: ValueKey(isTens ? 'swt-z-counters' : 'swt-e-counters'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _removeFromColumn(isTens),
            child: Semantics(
              button: true,
              label: isTens ? 'Zehner zählt $value' : 'Einer zählt $value',
              excludeSemantics: true,
              child: SizedBox(
                height: 44,
                width: double.infinity,
                child: Center(
                  child: Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: isTens ? 'Zehner hinzufügen' : 'Einer hinzufügen',
            excludeSemantics: true,
            child: GestureDetector(
              key: ValueKey(isTens ? 'swt-z-add' : 'swt-e-add'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _addToColumn(isTens),
              child: Container(
                height: 44,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, size: 28, color: Colors.indigo),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
