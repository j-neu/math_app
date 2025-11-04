import 'package:flutter/material.dart';

class CircleDisplayWidget extends StatelessWidget {
  final int count;

  const CircleDisplayWidget({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    // Wrap is used to allow circles to flow to the next line if they don't fit.
    return Wrap(
      spacing: 8.0, // Gap between adjacent circles.
      runSpacing: 8.0, // Gap between lines.
      alignment: WrapAlignment.center,
      children: List.generate(count, (index) {
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}