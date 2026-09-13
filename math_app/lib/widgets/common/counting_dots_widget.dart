import 'dart:math';
import 'package:flutter/material.dart';

/// Displays [count] filled circles for counting tasks (iMINT Testkarte 1).
///
/// [structured] arranges dots in a tidy grid (max 5 per row, matching the
/// existing `CountDotsLevel3Widget` layout); otherwise they are scattered
/// with a minimum spacing so none touch (matching `CountDotsLevel4Widget`).
/// Positions are a deterministic function of (count, seed) — unlike the
/// practice exercises this feeds, a diagnostic item's stimulus must render
/// identically every time, not re-randomize per rebuild.
class CountingDotsWidget extends StatelessWidget {
  final int count;
  final bool structured;
  final Color dotColor;
  final double size;
  final int seed;

  const CountingDotsWidget({
    super.key,
    required this.count,
    this.structured = false,
    this.dotColor = Colors.purple,
    this.size = 280,
    this.seed = 7,
  });

  List<Offset> _positions() {
    if (structured) {
      const maxPerRow = 5;
      final cols = count <= maxPerRow ? count : maxPerRow;
      final rows = (count / maxPerRow).ceil();
      return [
        for (var i = 0; i < count; i++)
          Offset((i % cols + 0.5) / cols, (i ~/ cols + 0.5) / rows),
      ];
    }
    final random = Random(seed);
    const minDistance = 0.12;
    const maxAttempts = 300;
    final positions = <Offset>[];
    for (var i = 0; i < count; i++) {
      var attempts = 0;
      var candidate = Offset.zero;
      var valid = false;
      while (!valid && attempts < maxAttempts) {
        candidate = Offset(
          0.1 + random.nextDouble() * 0.8,
          0.1 + random.nextDouble() * 0.8,
        );
        valid = positions.every((p) => (p - candidate).distance >= minDistance);
        attempts++;
      }
      positions.add(candidate);
    }
    return positions;
  }

  @override
  Widget build(BuildContext context) {
    final positions = _positions();
    final dotSize = size * 0.1;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          for (final p in positions)
            Positioned(
              left: p.dx * size - dotSize / 2,
              top: p.dy * size - dotSize / 2,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
