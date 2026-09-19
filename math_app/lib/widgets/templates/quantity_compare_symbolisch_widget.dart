import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'quantity_compare_common.dart';

/// Symbolisch tier of `compare_quantity_difference` (Batch 1.8): each
/// quantity is shown as a bare numeral -- no counters, no frame -- the
/// most abstract of the 3 representations.
class QuantityCompareSymbolischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const QuantityCompareSymbolischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  static Widget _numeral(BuildContext context, int value) {
    return Container(
      key: ValueKey('qc-numeral-$value'),
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value',
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuantityCompareCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildQuantity: _numeral,
      onSubmit: onSubmit,
    );
  }
}
