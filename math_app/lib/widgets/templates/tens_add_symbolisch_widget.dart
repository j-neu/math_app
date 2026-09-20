import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'tens_add_common.dart';

/// Symbolisch tier of `tens_add_tens` (BUILD_ORDER.md Batch 1.12): each
/// decade addend is shown as a bare boxed numeral (e.g. "30") -- no rods,
/// no chips -- the most abstract of the 3 representations.
class TensAddSymbolischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const TensAddSymbolischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  static Widget _numeral(BuildContext context, int tensCount) {
    final value = tensCount * 10;
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value',
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TensAddCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildGroup: _numeral,
      onSubmit: onSubmit,
    );
  }
}
