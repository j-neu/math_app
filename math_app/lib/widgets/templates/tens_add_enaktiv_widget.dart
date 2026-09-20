import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../common/ten_strip_widget.dart';
import 'tens_add_common.dart';

/// Enaktiv tier of `tens_add_tens` (BUILD_ORDER.md Batch 1.12): each decade
/// addend is rendered as that many actual ten-rods (`TenStripWidget`,
/// math_app/lib/widgets/common/ten_strip_widget.dart -- a shared
/// manipulative, imported unmodified). Visual layout ported from the old
/// engine's `TensCalculationLevel1Widget._buildGroup`
/// (math_app/lib/widgets/tens_calculation_level1_widget.dart, untouched) --
/// fresh copy, adapted contract, no self-grading.
class TensAddEnaktivWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const TensAddEnaktivWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  static Widget _rods(BuildContext context, int tensCount) {
    return Wrap(
      spacing: 4,
      children: [
        for (var i = 0; i < tensCount; i++)
          TenStripWidget(
            key: ValueKey('tens-add-rod-$tensCount-$i'),
            color: Colors.blue,
            width: 15,
            height: 100,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return TensAddCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildGroup: _rods,
      onSubmit: onSubmit,
    );
  }
}
