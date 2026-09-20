import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'tens_sub_common.dart';

/// Ikonisch tier of `tens_sub_tens` / `tens_sub_crossing_hundred`
/// (BUILD_ORDER.md Batch 1.12): the total is shown as `tensA` compact
/// "10er" chips; the last `tensB` are struck through to depict the
/// subtraction as a static picture -- no tapping, unlike the enaktiv tier.
class TensSubIkonischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const TensSubIkonischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  static Widget _chips(BuildContext context, int tensA, int tensB) {
    final remaining = tensA - tensB;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${tensA * 10} - ${tensB * 10} = ?',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < tensA; i++)
              Container(
                key: ValueKey('tens-sub-chip-$tensA-$tensB-$i'),
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i < remaining ? Colors.blue.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: i < remaining ? Colors.blue.shade400 : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: i < remaining
                    ? const Text('10', style: TextStyle(fontWeight: FontWeight.bold))
                    : const Icon(Icons.close, color: Colors.redAccent),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return TensSubCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildVisual: _chips,
      onSubmit: onSubmit,
    );
  }
}
