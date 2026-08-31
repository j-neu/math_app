import 'package:flutter/material.dart';

/// A single ten-stick bundle ("Zehnerbündel") with two rubber bands.
class StaebchenBundelWidget extends StatelessWidget {
  const StaebchenBundelWidget();

  Widget _band() => Container(
        height: 3,
        color: Colors.brown.shade600,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < 10; i++)
                Expanded(
                  child: Center(
                    child: Container(
                      width: 3,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Positioned(top: 5, left: 4, right: 4, child: _band()),
          Positioned(bottom: 5, left: 4, right: 4, child: _band()),
        ],
      ),
    );
  }
}

/// A single loose stick.
class StaebchenEinzelWidget extends StatelessWidget {
  const StaebchenEinzelWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: Colors.deepOrange.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Bundled tens and loose single sticks with a visible gap between the two
/// groups (B1.2-01, B1.2-02, DDB-01, DDB-02).
class StaebchenWidget extends StatelessWidget {
  final int bundles;
  final int singles;

  const StaebchenWidget({required this.bundles, required this.singles});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < bundles; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            const StaebchenBundelWidget(),
          ],
          const SizedBox(width: 26),
          for (var i = 0; i < singles; i++) const StaebchenEinzelWidget(),
        ],
      ),
    );
  }
}

/// B1.3-01: one bundle + 3 single sticks; tapping the bundle opens it into
/// ten single sticks (interactive Entbündelung per the item file).
class StaebchenOeffnenWidget extends StatefulWidget {
  const StaebchenOeffnenWidget();

  @override
  State<StaebchenOeffnenWidget> createState() => _StaebchenOeffnenWidgetState();
}

class _StaebchenOeffnenWidgetState extends State<StaebchenOeffnenWidget> {
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
                for (var i = 0; i < 13; i++) const StaebchenEinzelWidget(),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '13 einzelne Stäbchen',
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
          children: [
            GestureDetector(
              onTap: () => setState(() => _opened = true),
              child: const StaebchenBundelWidget(),
            ),
            const SizedBox(width: 26),
            for (var i = 0; i < 3; i++) const StaebchenEinzelWidget(),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Tippe auf das Bündel, um es zu öffnen.',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }
}
