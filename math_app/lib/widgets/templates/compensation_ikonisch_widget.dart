import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../common/wendeplaettchen_widget.dart';
import 'compensation_common.dart';

/// Ikonisch tier of `compensation_strategy_zr20` (BUILD_ORDER.md Batch
/// 1.13): the counter pile stays visible the whole time (never covered) --
/// "mental manipulation": the child reasons about the change from a
/// static picture rather than reconstructing it from memory.
class CompensationIkonischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const CompensationIkonischWidget({
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
          'Gesamt: $total',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_changeText(flip), style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 16),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < red; i++)
                WendeplaettchenWidget(
                  key: ValueKey('comp-ik-red-$i'),
                  color: Colors.red,
                ),
              for (var i = 0; i < blue; i++)
                WendeplaettchenWidget(
                  key: ValueKey('comp-ik-blue-$i'),
                  color: Colors.blue,
                ),
            ],
          ),
        ),
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
