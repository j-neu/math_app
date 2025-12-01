import 'package:flutter/material.dart';

/// Level 1: Explore the 100-Field
///
/// **Pedagogical Purpose:**
/// Free exploration of the 100-field structure. Child learns:
/// - Numbers are arranged in 10 rows × 10 columns
/// - Horizontal pattern: +1 (21, 22, 23...)
/// - Vertical pattern: +10 (5, 15, 25, 35...)
/// - Spatial relationship of numbers
///
/// **Activity:**
/// - Single "problem" - just exploration
/// - Can pan and zoom around the field
/// - "Start Level 2" button appears when ready
/// - No time pressure, no correctness tracking
///
/// **DIFFICULTY CURVE: N/A (exploration only)**
///
/// **Design Pattern:** Interactive visualization with gesture controls
class Count100FieldLevel1Widget extends StatefulWidget {
  final VoidCallback onComplete;
  final Function(int levelNumber, int problemNumber) startProblemTimer;
  final Function(int levelNumber, int problemNumber, bool isCorrect, double timeTaken)
      recordProblemResult;

  const Count100FieldLevel1Widget({
    super.key,
    required this.onComplete,
    required this.startProblemTimer,
    required this.recordProblemResult,
  });

  @override
  State<Count100FieldLevel1Widget> createState() => _Count100FieldLevel1WidgetState();
}

class _Count100FieldLevel1WidgetState extends State<Count100FieldLevel1Widget> {
  // Transform controller for pan/zoom
  final TransformationController _transformController = TransformationController();

  // Track if user has explored (panned or zoomed)
  bool _hasExplored = false;

  @override
  void initState() {
    super.initState();
    // Start timer for this exploration "problem"
    widget.startProblemTimer(1, 1);
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _handleExploration() {
    if (!_hasExplored) {
      setState(() {
        _hasExplored = true;
      });
    }
  }

  void _handleComplete() {
    // Record as "correct" (exploration complete)
    widget.recordProblemResult(1, 1, true, 0.0);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Interactive 100-field
        InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.5,
          maxScale: 3.0,
          boundaryMargin: const EdgeInsets.all(100),
          onInteractionUpdate: (details) {
            _handleExploration();
          },
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: _build100Field(),
            ),
          ),
        ),

        // Overlay button to start Level 2
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '👆 Pan and zoom to explore!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _handleComplete,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Start Level 2'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Help text at bottom
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Notice the patterns:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildHintRow(Icons.arrow_forward, 'Across (→): adds 1'),
                const SizedBox(height: 4),
                _buildHintRow(Icons.arrow_downward, 'Down (↓): adds 10'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHintRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue.shade800,
          ),
        ),
      ],
    );
  }

  Widget _build100Field() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int row = 0; row < 10; row++) _buildRow(row),
        ],
      ),
    );
  }

  Widget _buildRow(int row) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int col = 0; col < 10; col++) _buildCell(row, col),
      ],
    );
  }

  Widget _buildCell(int row, int col) {
    final number = row * 10 + col + 1;

    // Color coding for visual clarity
    Color backgroundColor;
    if (col == 9) {
      // Last column (10, 20, 30...) - highlight
      backgroundColor = Colors.blue.shade100;
    } else if (row == 0) {
      // First row (1-10) - highlight
      backgroundColor = Colors.green.shade50;
    } else {
      backgroundColor = Colors.white;
    }

    return Container(
      width: 45,
      height: 45,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString(),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: col == 9 ? Colors.blue.shade800 : Colors.black87,
        ),
      ),
    );
  }
}
