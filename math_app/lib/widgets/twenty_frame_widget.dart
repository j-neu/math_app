import 'package:flutter/material.dart';

class TwentyFrameWidget extends StatelessWidget {
  const TwentyFrameWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // A visual placeholder for a 2x10 grid.
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 20,
        itemBuilder: (context, index) {
          // Placeholder for an individual cell/dot
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blueGrey),
            ),
          );
        },
      ),
    );
  }
}