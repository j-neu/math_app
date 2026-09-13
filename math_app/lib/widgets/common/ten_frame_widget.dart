import 'package:flutter/material.dart';

/// A 5x2 ten-frame (Zehnerfeld) with [filledCount] dots filled from the
/// start, left-to-right, top row first — the standard "structured seeing"
/// layout for subitizing tasks up to 10 (iMINT Testkarte 8).
class TenFrameWidget extends StatelessWidget {
  final int filledCount;
  final Color dotColor;
  final double size;

  const TenFrameWidget({
    super.key,
    required this.filledCount,
    this.dotColor = const Color(0xFF1E88E5),
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    final cellSize = size / 5.6;
    return Container(
      padding: EdgeInsets.all(cellSize * 0.2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black87, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(0, cellSize),
          SizedBox(height: cellSize * 0.15),
          _row(1, cellSize),
        ],
      ),
    );
  }

  Widget _row(int rowIndex, double cellSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var col = 0; col < 5; col++) _cell(rowIndex * 5 + col, cellSize),
      ],
    );
  }

  Widget _cell(int index, double cellSize) {
    final filled = index < filledCount;
    return Container(
      width: cellSize,
      height: cellSize,
      margin: EdgeInsets.all(cellSize * 0.08),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? dotColor : Colors.transparent,
        border: Border.all(color: Colors.black38),
      ),
    );
  }
}
