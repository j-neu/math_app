import 'package:flutter/material.dart';
import 'package:math_app/widgets/common/finger_display_widget.dart';

/// Fingerbild of two hands (palms facing out), reusing [FingerDisplayWidget].
class FingerBildWidget extends StatelessWidget {
  final int leftCount;
  final int rightCount;

  const FingerBildWidget({required this.leftCount, required this.rightCount});

  @override
  Widget build(BuildContext context) {
    return FingerDisplayWidget(
      leftCount: leftCount,
      rightCount: rightCount,
      height: 180,
    );
  }
}
