import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'count_field20_common.dart';

/// Custom-widget template for the registry key `"count_field20_symbolisch"`
/// (quantify_count_zr20 level 3, BUILD_ORDER.md Batch 2.1): dots scattered
/// at three sizes (all >= the 44 px touch-target floor) with the tally
/// hidden, so the child cannot estimate the total from covered area and must
/// actually count.
class CountField20SymbolischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const CountField20SymbolischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return CountField20Core(
      problem: problem,
      onValueChanged: onValueChanged,
      onSubmit: onSubmit,
      dotSizes: const [44, 50, 56],
      showTally: false,
    );
  }
}
