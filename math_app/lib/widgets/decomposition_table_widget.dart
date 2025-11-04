import 'package:flutter/material.dart';

/// Static decomposition table showing all ways to decompose a target number.
///
/// Based on PIKAS Card 9: Image representation (Vorstellung).
/// Shows structured visual of all decomposition pairs to help children
/// recognize patterns like "gegensinniges Verändern" (opposite change).
///
/// For target=10: Shows 0+10, 1+9, 2+8, ..., 10+0
class DecompositionTableWidget extends StatelessWidget {
  /// Target number to decompose (e.g., 10)
  final int targetNumber;

  /// Whether to highlight the pattern of opposite changes
  final bool highlightPattern;

  const DecompositionTableWidget({
    super.key,
    this.targetNumber = 10,
    this.highlightPattern = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'All Ways to Make $targetNumber',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Pattern observation text
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.secondary, width: 2),
            ),
            child: const Text(
              'Notice the pattern:\n'
              'As one part gets BIGGER (+1), the other gets SMALLER (-1).\n'
              'This is called "gegensinniges Verändern" (opposite change).',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),

          // Decomposition table
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                targetNumber + 1,
                (index) => _buildDecompositionRow(
                  context,
                  firstPart: index,
                  secondPart: targetNumber - index,
                  isHighlighted: highlightPattern && (index == targetNumber ~/ 2),
                ),
              ),
            ),
          ),

          // Visual dots representation
          _buildDotsVisualization(context),
        ],
      ),
    );
  }

  Widget _buildDecompositionRow(
    BuildContext context, {
    required int firstPart,
    required int secondPart,
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlighted
            ? theme.colorScheme.primaryContainer.withOpacity(0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // First part (red circles) - limited width
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                firstPart,
                (i) => Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),

          // Spacer
          SizedBox(width: firstPart == 0 ? 0 : 4),

          // Number representation - smaller
          SizedBox(
            width: 80,
            child: Text(
              '$firstPart + $secondPart',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Spacer
          SizedBox(width: secondPart == 0 ? 0 : 4),

          // Second part (blue circles) - limited width
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                secondPart,
                (i) => Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ),

          // Equals sign and result
          const SizedBox(width: 8),
          Text(
            '= $targetNumber',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotsVisualization(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        children: [
          const Text(
            'Every row shows the same total!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'There are ${targetNumber + 1} different ways to make $targetNumber.',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
