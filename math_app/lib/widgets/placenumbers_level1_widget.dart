import 'package:flutter/material.dart';
import 'dart:math';

/// Level 1: Guided Exploration - Drag numbers to correct positions on number line
///
/// **Purpose:** Child sees the number line structure and learns where numbers
/// belong by dragging them to the correct positions. Visual feedback confirms
/// correct placement.
///
/// **Pedagogical Goal (Handlung):**
/// - See the number line with marked positions
/// - Drag number cards to positions
/// - Understand spatial relationship between numbers
/// - Build mental model of number positioning
///
/// **Progression:** After successfully placing 5 complete sets, Level 2 unlocks
class PlaceNumbersLevel1Widget extends StatefulWidget {
  final Function(int problemsSolved) onProgressUpdate;

  const PlaceNumbersLevel1Widget({
    super.key,
    required this.onProgressUpdate,
  });

  @override
  State<PlaceNumbersLevel1Widget> createState() =>
      _PlaceNumbersLevel1WidgetState();
}

class _PlaceNumbersLevel1WidgetState extends State<PlaceNumbersLevel1Widget>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  List<int> _numbersToPlace = [];
  Map<int, int?> _placedNumbers = {}; // position -> number placed there
  Set<int> _correctlyPlaced = {};
  int _problemsSolved = 0;
  int _minNumber = 0;
  int _maxNumber = 10;
  int _numberOfPositions = 11; // 0 to 10

  late AnimationController _successController;
  late Animation<double> _successAnimation;
  bool _showingSuccess = false;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _successAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
    _generateNewProblem();
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  void _generateNewProblem() {
    setState(() {
      _correctlyPlaced.clear();
      _placedNumbers.clear();
      _showingSuccess = false;

      // Generate 3-5 random numbers to place
      final count = 3 + _random.nextInt(3); // 3, 4, or 5 numbers
      final allNumbers =
          List.generate(_numberOfPositions, (i) => _minNumber + i);
      allNumbers.shuffle(_random);
      _numbersToPlace = allNumbers.take(count).toList()..sort();
    });
  }

  void _onNumberPlaced(int number, int position) {
    final correctPosition = number - _minNumber;

    // Check if this position already has a number
    if (_placedNumbers.containsValue(number)) {
      // Remove old placement
      _placedNumbers.removeWhere((key, value) => value == number);
    }

    setState(() {
      _placedNumbers[position] = number;

      if (position == correctPosition) {
        _correctlyPlaced.add(number);

        // Check if all numbers are correctly placed
        if (_correctlyPlaced.length == _numbersToPlace.length) {
          _showingSuccess = true;
          _successController.forward(from: 0);
          _problemsSolved++;
          widget.onProgressUpdate(_problemsSolved);

          // Generate new problem after delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _generateNewProblem();
            }
          });
        }
      } else {
        _correctlyPlaced.remove(number);
      }
    });
  }

  void _onNumberRemoved(int number) {
    setState(() {
      _placedNumbers.removeWhere((key, value) => value == number);
      _correctlyPlaced.remove(number);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Instructions
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.touch_app, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Level 1: Drag Numbers to the Line',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Drag each number to its correct position on the number line. Watch where each number belongs!',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Progress indicator
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Problems solved: $_problemsSolved',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Placed: ${_correctlyPlaced.length}/${_numbersToPlace.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Number line with drag targets
              Expanded(
                flex: 2,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return _buildNumberLine(constraints);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Draggable numbers area
              Expanded(
                child: _buildNumbersArea(),
              ),

              // Success message
              if (_showingSuccess)
                ScaleTransition(
                  scale: _successAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 32),
                        SizedBox(width: 12),
                        Text(
                          'Perfect! All numbers placed correctly!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberLine(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final positionWidth = width / _numberOfPositions;

    return CustomPaint(
      size: Size(width, constraints.maxHeight),
      painter: NumberLinePainter(
        minNumber: _minNumber,
        maxNumber: _maxNumber,
      ),
      child: Stack(
        children: [
          // Position indicators and drag targets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_numberOfPositions, (index) {
              final number = _minNumber + index;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Drag target slot
                    DragTarget<int>(
                      onAccept: (draggedNumber) {
                        _onNumberPlaced(draggedNumber, index);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final placedNumber = _placedNumbers[index];
                        final isOccupied = placedNumber != null;
                        final isCorrect = _correctlyPlaced.contains(placedNumber);

                        return Container(
                          width: positionWidth * 0.8,
                          height: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isOccupied
                                ? (isCorrect ? Colors.green.shade200 : Colors.red.shade200)
                                : (candidateData.isNotEmpty
                                    ? Colors.blue.shade100
                                    : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isOccupied
                                  ? (isCorrect ? Colors.green : Colors.red)
                                  : (candidateData.isNotEmpty
                                      ? Colors.blue
                                      : Colors.grey.shade400),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: isOccupied
                                ? GestureDetector(
                                    onTap: () => _onNumberRemoved(placedNumber),
                                    child: Text(
                                      placedNumber.toString(),
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                                      ),
                                    ),
                                  )
                                : Text(
                                    '?',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // Position label
                    Text(
                      number.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNumbersArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Text(
            'Drag these numbers:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _numbersToPlace.map((number) {
                final isPlaced = _correctlyPlaced.contains(number);

                if (isPlaced) {
                  // Show grayed out version
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        number.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  );
                }

                return Draggable<int>(
                  data: number,
                  feedback: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade300,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          number.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400, width: 2),
                    ),
                  ),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        number.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the number line
class NumberLinePainter extends CustomPainter {
  final int minNumber;
  final int maxNumber;

  NumberLinePainter({
    required this.minNumber,
    required this.maxNumber,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final tickPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 2;

    // Draw main horizontal line
    final y = size.height * 0.5;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      paint,
    );

    // Draw tick marks
    final numberOfPositions = maxNumber - minNumber + 1;
    for (int i = 0; i < numberOfPositions; i++) {
      final x = (size.width / numberOfPositions) * i + (size.width / numberOfPositions / 2);
      canvas.drawLine(
        Offset(x, y - 10),
        Offset(x, y + 10),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(NumberLinePainter oldDelegate) => false;
}
