import 'package:flutter/material.dart';

/// Zehnerfeld (5×2 raster of ten cells) with the given cells filled.
///
/// [filled] holds cell indices 0..9 in row-major order (row 0 = cells 0–4,
/// row 1 = cells 5–9), matching the coordinate specs of the item files
/// (A2.2-01, A2.3-01, DDA-04).
class ZehnerfeldWidget extends StatelessWidget {
  final Set<int> filled;

  const ZehnerfeldWidget({required this.filled});

  @override
  Widget build(BuildContext context) {
    const cellSize = 36.0;

    Widget cell(int index) {
      final isFilled = filled.contains(index);
      return Container(
        width: cellSize,
        height: cellSize,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isFilled ? Colors.indigo : Colors.transparent,
          border: Border.all(
            color: isFilled ? Colors.indigo : Colors.blueGrey,
            width: 2,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (var c = 0; c < 5; c++) cell(c)],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (var c = 5; c < 10; c++) cell(c)],
          ),
        ],
      ),
    );
  }
}

/// Two Zehnerfelder side by side (A2.3-01): left 6 (5+1), right 8 (5+3).
class VergleichZehnerfelderWidget extends StatelessWidget {
  const VergleichZehnerfelderWidget();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _labeled(
            'links',
            const ZehnerfeldWidget(filled: {0, 1, 2, 3, 4, 5}),
          ),
          const SizedBox(width: 28),
          _labeled(
            'rechts',
            const ZehnerfeldWidget(filled: {0, 1, 2, 3, 4, 5, 6, 7}),
          ),
        ],
      ),
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
