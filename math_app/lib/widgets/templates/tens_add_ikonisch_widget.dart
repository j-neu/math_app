import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'tens_add_common.dart';

/// Ikonisch tier of `tens_add_tens` (BUILD_ORDER.md Batch 1.12): each
/// decade addend is rendered as that many compact "10er" chips (a picture
/// standing for one ten, not an actual counted-out rod) -- less concrete
/// than the enaktiv tier's rods, more concrete than the symbolisch tier's
/// bare numeral.
class TensAddIkonischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const TensAddIkonischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  static Widget _chips(BuildContext context, int tensCount) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < tensCount; i++)
          Container(
            key: ValueKey('tens-add-chip-$tensCount-$i'),
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade400, width: 2),
            ),
            child: const Text('10', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return TensAddCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildGroup: _chips,
      onSubmit: onSubmit,
    );
  }
}
