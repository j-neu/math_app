import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'count_field20_common.dart';

/// Custom-widget template for the registry key `"count_field20_enaktiv"`
/// (quantify_count_zr20 level 1, BUILD_ORDER.md Batch 2.1): uniform 48 px
/// dots scattered without row structure; tapping marks a dot counted and a
/// live "Angetippt: n" tally is shown.
class CountField20EnaktivWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const CountField20EnaktivWidget({
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
      showTally: true,
    );
  }
}
