import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'count_field20_common.dart';

/// Custom-widget template for the registry key `"count_field20_ikonisch"`
/// (quantify_count_zr20 level 2, BUILD_ORDER.md Batch 2.1): uniform 48 px
/// dots scattered without row structure; tapping still marks a dot counted
/// but the tally is hidden, so the child keeps the running count in their
/// head.
class CountField20IkonischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const CountField20IkonischWidget({
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
      dotSizes: const [48],
      showTally: false,
    );
  }
}
