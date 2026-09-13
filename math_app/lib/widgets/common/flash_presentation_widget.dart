import 'dart:async';

import 'package:flutter/material.dart';

enum _FlashStage { ready, fixation, countdown, flash, hidden }

/// Generic flash-then-hide presentation, extracted from the original
/// Rekenrek-only `RekenrekFlashWidget` (A2.1-01) so any quantity display
/// (Rekenrek, Fingerbild, dots, ...) can reuse the same interaction: the
/// child starts it deliberately (Bereit), sees a fixation point and a 3-2-1
/// countdown, then [child] shows for 1500 ms and fades out.
class FlashPresentationWidget extends StatefulWidget {
  final Widget child;

  const FlashPresentationWidget({super.key, required this.child});

  @override
  State<FlashPresentationWidget> createState() =>
      _FlashPresentationWidgetState();
}

class _FlashPresentationWidgetState extends State<FlashPresentationWidget> {
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
          child: widget.child,
        );
    }
  }
}
