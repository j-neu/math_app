import 'package:flutter/material.dart';

import 'dienes_block_widget.dart';

/// Shows [tens] Zehnerstangen and [ones] Einerwürfel side by side — the
/// bundled representation for the bundling-recognition task
/// (iMINT Testkarte 10).
///
/// The tens render as a single bundled block (rods stacked along the depth
/// axis, with divider lines between them) rather than separate widgets, so
/// they read as one tight group instead of a row of sticks with visible
/// gaps between them. The ones cubes keep a small gap so they stay
/// individually countable, with a wider gap separating the two groups.
class BundlingBlocksWidget extends StatelessWidget {
  final int tens;
  final int ones;
  final double cellSize;

  const BundlingBlocksWidget({
    super.key,
    required this.tens,
    required this.ones,
    this.cellSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (tens > 0)
          DienesBlockWidget(
              type: DienesType.rod, cellSize: cellSize, count: tens),
        if (ones > 0)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < ones; i++)
                DienesBlockWidget(type: DienesType.unit, cellSize: cellSize),
            ],
          ),
      ],
    );
  }
}
