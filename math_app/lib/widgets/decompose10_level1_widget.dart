import 'package:flutter/material.dart';

/// Level 1: Guided Exploration for Decompose 10
///
/// Translation of iMINT Card 3 Activity A:
/// Physical: Partner places pen between your 10 fingers, you name counts left/right
/// Digital: Tap counters to flip them blue, equation auto-displays
///
/// Features:
/// - 10 counters displayed in a row (initially all red)
/// - Child taps counters to flip them blue
/// - Equation auto-displays: "10 = 4 blue + 6 red"
/// - Pure exploration, no completion criteria
/// - No writing required
class Decompose10Level1Widget extends StatefulWidget {
  final VoidCallback? onExplorationComplete;

  const Decompose10Level1Widget({
    super.key,
    this.onExplorationComplete,
  });

  @override
  State<Decompose10Level1Widget> createState() => _Decompose10Level1WidgetState();
}

class _Decompose10Level1WidgetState extends State<Decompose10Level1Widget> {
  // Track which counters are flipped (true = blue, false = red)
  final List<bool> _flippedStates = List.filled(10, false);

  // Track how many different decompositions the child has explored
  final Set<String> _exploredDecompositions = {};

  // Minimum explorations before suggesting to move on (not required)
  static const int _minExplorationsToSuggest = 5;

  void _toggleCounter(int index) {
    setState(() {
      _flippedStates[index] = !_flippedStates[index];

      // Track this decomposition
      final blueCount = _flippedStates.where((flipped) => flipped).length;
      final redCount = 10 - blueCount;
      // Normalize (always store as smaller_larger to count unique)
      final key = blueCount <= redCount ? '${blueCount}_$redCount' : '${redCount}_$blueCount';
      _exploredDecompositions.add(key);
    });
  }

  void _resetCounters() {
    setState(() {
      for (int i = 0; i < _flippedStates.length; i++) {
        _flippedStates[i] = false;
      }
    });
  }

  void _completeExploration() {
    widget.onExplorationComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final blueCount = _flippedStates.where((flipped) => flipped).length;
    final redCount = 10 - blueCount;
    final hasExploredEnough = _exploredDecompositions.length >= _minExplorationsToSuggest;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade300, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.touch_app, color: Colors.blue.shade700, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Level 1: Explore',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap counters to flip them blue. Watch what happens to the equation!',
                    style: TextStyle(fontSize: 16, color: Colors.blue.shade900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explored: ${_exploredDecompositions.length} different ways',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Counters in a row (two rows of 5 for better layout)
            Center(
              child: Column(
                children: [
                  // Top row (counters 0-4)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) => _buildCounter(i)),
                  ),
                  const SizedBox(height: 8),
                  // Bottom row (counters 5-9)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) => _buildCounter(i + 5)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Auto-displayed equation
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade600, width: 3),
              ),
              child: Column(
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      children: [
                        const TextSpan(text: '10 = '),
                        TextSpan(
                          text: '$blueCount blue',
                          style: const TextStyle(color: Colors.blue),
                        ),
                        const TextSpan(text: ' + '),
                        TextSpan(
                          text: '$redCount red',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey.shade700,
                      ),
                      children: [
                        const TextSpan(text: 'or: 10 = '),
                        TextSpan(
                          text: '$blueCount',
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' + '),
                        TextSpan(
                          text: '$redCount',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Reset button
            OutlinedButton.icon(
              onPressed: _resetCounters,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Counters'),
            ),

            const SizedBox(height: 16),

            // Suggestion to move on (appears after some exploration)
            if (hasExploredEnough)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Great exploring! You\'ve tried ${_exploredDecompositions.length} different ways.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _completeExploration,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Ready for Next Level'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '(You can keep exploring or move on)',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter(int index) {
    final isFlipped = _flippedStates[index];

    return GestureDetector(
      onTap: () => _toggleCounter(index),
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isFlipped ? Colors.blue : Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            isFlipped ? Icons.circle : Icons.circle_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
