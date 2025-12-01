import 'package:flutter/material.dart';
import 'placenumbers_level1_widget.dart';

/// Level 2: Same as Level 1 but with 5 cards
class PlaceNumbersLevel2Widget extends StatelessWidget {
  final Function(bool) onProblemSolved;
  final int maxNumber;
  final int tolerance;

  const PlaceNumbersLevel2Widget({
    super.key,
    required this.onProblemSolved,
    this.maxNumber = 20,
    this.tolerance = 3,
  });

  @override
  Widget build(BuildContext context) {
    return PlaceNumbersLevel1Widget(
      onProblemSolved: onProblemSolved,
      cardCount: 5,
      maxNumber: maxNumber,
      tolerance: tolerance,
    );
  }
}