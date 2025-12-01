import 'package:flutter/material.dart';
import 'common/count_100_field_board.dart';

class Count100FieldLevel1Widget extends StatelessWidget {
  final VoidCallback onComplete;

  const Count100FieldLevel1Widget({
    super.key,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full visibility board
        Count100FieldBoard(
          isInteractive: true,
          activeIndices: List.generate(100, (i) => i).toSet(),
        ),

        // Overlay button
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: Center(
            child: ElevatedButton(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 4,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Start Level 2',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
