import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'compensation_common.dart';

/// Symbolisch tier of `compensation_strategy_zr20` (BUILD_ORDER.md Batch
/// 1.13): no counters at all -- bare numbers and text only, the most
/// abstract of the 3 representations ("numerical compensation").
class CompensationSymbolischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const CompensationSymbolischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  static String _changeText(String flip) =>
      flip == 'red_to_blue' ? 'Eine rote wird blau.' : 'Eine blaue wird rot.';

  static Widget _scene(
    BuildContext context,
    int total,
    int red,
    int blue,
    String flip,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$red rot, $blue blau (zusammen $total)',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(_changeText(flip), style: const TextStyle(fontSize: 18)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompensationCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildScene: _scene,
      onSubmit: onSubmit,
    );
  }
}
