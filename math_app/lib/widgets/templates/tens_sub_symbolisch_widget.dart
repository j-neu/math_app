import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'tens_sub_common.dart';

/// Symbolisch tier of `tens_sub_tens` / `tens_sub_crossing_hundred`
/// (BUILD_ORDER.md Batch 1.12): bare numerals only, no chips or rods --
/// the most abstract of the 3 representations.
class TensSubSymbolischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const TensSubSymbolischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  static Widget _equation(BuildContext context, int tensA, int tensB) {
    return Text(
      '${tensA * 10} - ${tensB * 10} = ?',
      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TensSubCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildVisual: _equation,
      onSubmit: onSubmit,
    );
  }
}
