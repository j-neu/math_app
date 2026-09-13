import 'package:flutter/material.dart';

/// Zahlenmauer (number wall): each stone equals the sum of the two stones
/// directly below it. [base] is the bottom row (visible); every row above it
/// renders as an open "?" stone, narrowing to the single top stone most
/// number-wall items ask for (Kombinierte Strategien, Arbeitskarte 9).
///
/// This is a first, static version — Jakob asked for an eventual animated
/// build-up with "+" arrows showing where each sum goes; that's a larger,
/// separate pass, deferred for now.
class NumberWallWidget extends StatelessWidget {
  final List<int> base;
  final double cellSize;

  const NumberWallWidget({super.key, required this.base, this.cellSize = 56});

  List<List<int?>> get _rowsTopFirst {
    final rows = <List<int?>>[
      [for (final v in base) v],
    ];
    var count = base.length;
    while (count > 1) {
      count--;
      rows.add(List<int?>.filled(count, null));
    }
    return rows.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rowsTopFirst;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [for (final v in row) _cell(v)],
          ),
          if (row != rows.last) SizedBox(height: cellSize * 0.3),
        ],
        const SizedBox(height: 10),
        const Text(
          'Jeder Stein zeigt die Summe der zwei Steine darunter.',
          style: TextStyle(fontSize: 13, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _cell(int? value) {
    return Container(
      width: cellSize,
      height: cellSize,
      margin: EdgeInsets.symmetric(horizontal: cellSize * 0.1),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: value != null ? Colors.indigo.shade50 : Colors.white,
        border: Border.all(color: Colors.indigo, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value?.toString() ?? '?',
        style: TextStyle(fontSize: cellSize * 0.4, fontWeight: FontWeight.bold),
      ),
    );
  }
}
