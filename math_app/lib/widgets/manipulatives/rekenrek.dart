import 'dart:async';
import 'package:flutter/material.dart';

/// Rechenrahmen (Rekenrek) with two rods of ten beads each (5 red + 5 white
/// per rod). [topLeft]/[bottomLeft] are the numbers of beads pushed to the
/// left on the upper/lower rod; the remaining beads sit at the right end.
class RekenrekWidget extends StatelessWidget {
  final int topLeft;
  final int bottomLeft;

  const RekenrekWidget({required this.topLeft, required this.bottomLeft});

  Widget _bead({required bool red}) {
    return Container(
      width: 16,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: red ? Colors.red.shade700 : Colors.white,
        border: Border.all(color: Colors.black26),
      ),
    );
  }

  Widget _rod(int leftCount) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.brown.shade200,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.brown.shade400),
      ),
      child: Row(
        children: [
          for (var i = 0; i < leftCount; i++) _bead(red: true),
          const SizedBox(width: 20),
          for (var i = leftCount; i < 10; i++) _bead(red: i < 5),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _rod(topLeft),
        const SizedBox(height: 6),
        _rod(bottomLeft),
      ],
    );
  }
}

/// Rekenrek flash presentation for A2.1-01: the frame is shown for exactly
/// 800 ms and then fades out so the child answers from memory.
class RekenrekFlashWidget extends StatefulWidget {
  final int topLeft;
  final int bottomLeft;

  const RekenrekFlashWidget({
    required this.topLeft,
    required this.bottomLeft,
  });

  @override
  State<RekenrekFlashWidget> createState() => _RekenrekFlashWidgetState();
}

class _RekenrekFlashWidgetState extends State<RekenrekFlashWidget> {
  Timer? _timer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: RekenrekWidget(
        topLeft: widget.topLeft,
        bottomLeft: widget.bottomLeft,
      ),
    );
  }
}

/// Two Rekenreks side by side (DDA-06): left 8 (5 top + 3 bottom), right 5.
class VergleichRekenrekWidget extends StatelessWidget {
  const VergleichRekenrekWidget();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labeled(
            'links',
            const RekenrekWidget(topLeft: 5, bottomLeft: 3),
          ),
          const SizedBox(width: 40),
          _labeled(
            'rechts',
            const RekenrekWidget(topLeft: 5, bottomLeft: 0),
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
