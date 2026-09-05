import 'package:flutter/material.dart';
import '../common/dienes_block_widget.dart';

/// Dienes place-value display: [tens] Zehner rods + [ones] Einer units, with
/// a visible gap between the two groups — replaces [StaebchenWidget] in the
/// diagnostic (a Stäbchen bundle reads as a tin at item scale, diagnostic
/// usability rework §4.7). `StaebchenWidget` itself stays in place; the
/// practice runtime still uses it.
class DienesPlaceValueWidget extends StatelessWidget {
  final int tens;
  final int ones;

  const DienesPlaceValueWidget({
    super.key,
    required this.tens,
    required this.ones,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < tens; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            const DienesBlockWidget(type: DienesType.rod),
          ],
          const SizedBox(width: 26),
          for (var i = 0; i < ones; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            const DienesBlockWidget(type: DienesType.unit),
          ],
        ],
      ),
    );
  }
}

/// B1.3-01: one Dienes rod (Zehner) + 3 units; tapping the rod "opens" it
/// into ten units — the same interaction [StaebchenOeffnenWidget] has, now
/// against Dienes blocks (diagnostic usability rework §4.7).
class DienesOeffnenWidget extends StatefulWidget {
  const DienesOeffnenWidget({super.key});

  @override
  State<DienesOeffnenWidget> createState() => _DienesOeffnenWidgetState();
}

class _DienesOeffnenWidgetState extends State<DienesOeffnenWidget> {
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    if (_opened) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 13; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  const DienesBlockWidget(type: DienesType.unit),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '13 einzelne Einer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () => setState(() => _opened = true),
              child: const DienesBlockWidget(type: DienesType.rod),
            ),
            const SizedBox(width: 26),
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              const DienesBlockWidget(type: DienesType.unit),
            ],
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Tippe auf den Zehner, um ihn zu öffnen.',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }
}
