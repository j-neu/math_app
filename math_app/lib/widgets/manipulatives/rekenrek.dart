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
        mainAxisAlignment: MainAxisAlignment.center,
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

enum _FlashStage { ready, fixation, countdown, flash, hidden }

/// Rekenrek flash presentation for A2.1-01. The child starts it
/// deliberately (Bereit), sees a fixation point and a 3-2-1 countdown, then
/// the frame shows for 1500 ms and fades out — replacing the old
/// build-triggered 800 ms flash, which fired in the corner before the child
/// was looking (diagnostic usability rework §4.5).
class RekenrekFlashWidget extends StatefulWidget {
  final int topLeft;
  final int bottomLeft;

  const RekenrekFlashWidget({
    super.key,
    required this.topLeft,
    required this.bottomLeft,
  });

  @override
  State<RekenrekFlashWidget> createState() => _RekenrekFlashWidgetState();
}

class _RekenrekFlashWidgetState extends State<RekenrekFlashWidget> {
  static const _fixationDuration = Duration(milliseconds: 500);
  static const _countdownTick = Duration(milliseconds: 700);
  static const _flashDuration = Duration(milliseconds: 1500);
  static const _fadeDuration = Duration(milliseconds: 200);

  _FlashStage _stage = _FlashStage.ready;
  int _countdownValue = 3;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _stage = _FlashStage.fixation);
    _timer = Timer(_fixationDuration, _beginCountdown);
  }

  void _beginCountdown() {
    if (!mounted) return;
    setState(() {
      _stage = _FlashStage.countdown;
      _countdownValue = 3;
    });
    _timer = Timer(_countdownTick, _tickCountdown);
  }

  void _tickCountdown() {
    if (!mounted) return;
    if (_countdownValue > 1) {
      setState(() => _countdownValue--);
      _timer = Timer(_countdownTick, _tickCountdown);
    } else {
      setState(() => _stage = _FlashStage.flash);
      _timer = Timer(_flashDuration, () {
        if (mounted) setState(() => _stage = _FlashStage.hidden);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _FlashStage.ready:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.center_focus_strong,
                size: 32, color: Colors.black54),
            const SizedBox(height: 16),
            FilledButton(onPressed: _start, child: const Text('Bereit')),
          ],
        );
      case _FlashStage.fixation:
        return const Text('+',
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold));
      case _FlashStage.countdown:
        return Text(
          '$_countdownValue',
          style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
        );
      case _FlashStage.flash:
      case _FlashStage.hidden:
        // Same AnimatedOpacity instance across both stages (only the
        // target `opacity` flips) so Flutter keeps the same element and
        // runs didUpdateWidget — which is what actually starts the 1->0
        // interpolation. Returning a *new* widget type per stage here
        // would unmount/remount on the transition, so the animation
        // would never play (it would just snap straight to the target).
        return AnimatedOpacity(
          opacity: _stage == _FlashStage.hidden ? 0 : 1,
          duration: _fadeDuration,
          child: RekenrekWidget(
              topLeft: widget.topLeft, bottomLeft: widget.bottomLeft),
        );
    }
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
