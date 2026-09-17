import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../manipulatives/zehnerfeld.dart';
import 'quantity_compare_common.dart';

/// Ikonisch tier of `compare_quantity_difference` (Batch 1.8): each
/// quantity is rendered as a `ZehnerfeldWidget` ten-frame -- structured
/// (5+5), semi-abstract, capped at 10.
class QuantityCompareIkonischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const QuantityCompareIkonischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  static Widget _frame(BuildContext context, int value) {
    return ZehnerfeldWidget(filled: {for (var i = 0; i < value; i++) i});
  }

  @override
  Widget build(BuildContext context) {
    return QuantityCompareCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildQuantity: _frame,
    );
  }
}
