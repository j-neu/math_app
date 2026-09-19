import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'quantity_compare_common.dart';

/// Enaktiv tier of `compare_quantity_difference` (Batch 1.8): each quantity
/// is rendered as that many loose round counters ("Plättchen"), directly
/// countable one by one -- the most concrete of the 3 representations.
class QuantityCompareEnaktivWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const QuantityCompareEnaktivWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  static Widget _tokens(BuildContext context, int value) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < value; i++)
          Container(
            key: ValueKey('qc-token-$value-$i'),
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.indigo,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuantityCompareCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildQuantity: _tokens,
      onSubmit: onSubmit,
    );
  }
}
