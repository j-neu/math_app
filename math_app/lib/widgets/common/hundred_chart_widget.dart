import 'package:flutter/material.dart';

/// The labeled 10x10 Hundertertafel (1..100, row-major).
///
/// Two modes:
/// - Single-blank (pass [blankValue]): every cell is labeled except
///   [blankValue], shown as "?" — the structural-navigation task
///   (iMINT-derived gap, Stellenwerte Arbeitskarte 6).
/// - Sparse (pass [visibleValues]): only the numbers in [visibleValues] are
///   shown — typically the four corners plus one reference number —
///   everything else is a blank cell. [highlightValue] (the reference
///   number, one of [visibleValues]) gets a highlighted border so a question
///   can refer to "the highlighted number". [queryValue] is the neighbor
///   cell being asked about: it is never in [visibleValues], but it is
///   still highlighted and shown as "?", so the child sees exactly which
///   box to answer for instead of it blending into the other blank cells.
///   Because the query cell's actual number is never shown anywhere, the
///   answer must be derived from the ±1 (row) / ±10 (column) structure
///   instead of read off an already-labeled adjacent cell, which the
///   single-blank mode allows.
class HundredChartWidget extends StatelessWidget {
  final int? blankValue;
  final Set<int>? visibleValues;
  final int? highlightValue;
  final int? queryValue;
  final double size;

  const HundredChartWidget({
    super.key,
    this.blankValue,
    this.visibleValues,
    this.highlightValue,
    this.queryValue,
    this.size = 320,
  }) : assert(
          blankValue != null || visibleValues != null,
          'Provide blankValue for the single-blank mode or visibleValues '
          'for the sparse mode.',
        );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black87, width: 2),
      ),
      // The border insets shrink the space actually available to the child
      // below `size`, so the cell size must come from the real constraints,
      // not from `size` itself, or the grid overflows by the border width.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = constraints.maxWidth / 10;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var row = 0; row < 10; row++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var col = 0; col < 10; col++)
                      _cell(row * 10 + col + 1, cell),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _cell(int value, double cellSize) {
    final isSparse = visibleValues != null;
    final isBlankTarget = !isSparse && value == blankValue;
    final isQuery = isSparse && value == queryValue;
    final isGiven = isSparse && value == highlightValue;
    final isPlainShown =
        isSparse ? (visibleValues!.contains(value) && !isQuery) : !isBlankTarget;

    Color bgColor = Colors.white;
    Color borderColor = Colors.black26;
    double borderWidth = 0.5;
    String text = '';
    var weight = FontWeight.normal;

    if (isBlankTarget || isQuery) {
      bgColor = Colors.amber.shade100;
      text = '?';
      weight = FontWeight.bold;
      if (isQuery) {
        borderColor = Colors.orange.shade700;
        borderWidth = 2;
      }
    } else if (isGiven) {
      bgColor = Colors.amber.shade200;
      borderColor = Colors.orange.shade700;
      borderWidth = 2;
      text = '$value';
      weight = FontWeight.bold;
    } else if (isPlainShown) {
      text = '$value';
    }

    return Container(
      width: cellSize,
      height: cellSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: cellSize * 0.4, fontWeight: weight),
      ),
    );
  }
}
