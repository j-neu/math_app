import 'package:flutter/material.dart';

/// Interactive 20-frame widget with tap-to-flip Wendeplättchen (two-color counters).
///
/// Based on PIKAS Card 9, Activity 4: Wendeplättchen flipping.
/// Children tap counters to flip between two colors, discovering decompositions.
///
/// For "Decompose 10" exercise, only the first 10 positions are active.
class InteractiveTwentyFrameWidget extends StatefulWidget {
  /// Number of counters to display (10 for decompose 10, 20 for decompose 20)
  final int totalCounters;

  /// Callback when child discovers a new decomposition
  final Function(int redCount, int blueCount)? onDecompositionChanged;

  /// Whether to show visual feedback for correct decomposition
  final bool showFeedback;

  const InteractiveTwentyFrameWidget({
    super.key,
    this.totalCounters = 10,
    this.onDecompositionChanged,
    this.showFeedback = false,
  });

  @override
  State<InteractiveTwentyFrameWidget> createState() => _InteractiveTwentyFrameWidgetState();
}

class _InteractiveTwentyFrameWidgetState extends State<InteractiveTwentyFrameWidget> {
  // true = red, false = blue (Wendeplättchen are two-sided)
  late List<bool> _counterStates;

  @override
  void initState() {
    super.initState();
    // Start with all counters blue
    _counterStates = List.filled(20, false);
  }

  void _flipCounter(int index) {
    if (index >= widget.totalCounters) return; // Don't allow flipping inactive counters

    setState(() {
      _counterStates[index] = !_counterStates[index];
    });

    // Calculate current decomposition
    final redCount = _counterStates.take(widget.totalCounters).where((isRed) => isRed).length;
    final blueCount = widget.totalCounters - redCount;

    // Notify parent
    widget.onDecompositionChanged?.call(redCount, blueCount);
  }

  void _resetCounters() {
    setState(() {
      _counterStates = List.filled(20, false);
    });
    widget.onDecompositionChanged?.call(0, widget.totalCounters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final redCount = _counterStates.take(widget.totalCounters).where((isRed) => isRed).length;
    final blueCount = widget.totalCounters - redCount;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Instruction text
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Tap the counters to flip them between red and blue.\nFind different ways to make ${widget.totalCounters}!',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),

        // Current decomposition display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildColorIndicator(Colors.red, redCount),
                const SizedBox(width: 6),
                const Text('+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                _buildColorIndicator(Colors.blue, blueCount),
                const SizedBox(width: 6),
                const Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Text(
                  '${widget.totalCounters}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),

        // 20-frame grid
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 3),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade100,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row (10 counters)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(10, (index) => _buildCounter(index)),
                ),
                const SizedBox(height: 6),
                // Bottom row (10 counters)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(10, (index) => _buildCounter(index + 10)),
                ),
              ],
            ),
          ),
        ),

        // Reset button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _resetCounters,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounter(int index) {
    final isActive = index < widget.totalCounters;
    final isRed = _counterStates[index];

    return GestureDetector(
      onTap: isActive ? () => _flipCounter(index) : null,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: !isActive
              ? Colors.grey.shade300 // Inactive counters are greyed out
              : isRed
                  ? Colors.red
                  : Colors.blue,
          border: Border.all(
            color: isActive ? Colors.black : Colors.grey.shade400,
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: isActive
            ? const Icon(Icons.circle, color: Colors.transparent, size: 0)
            : null,
      ),
    );
  }

  Widget _buildColorIndicator(Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.black, width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
