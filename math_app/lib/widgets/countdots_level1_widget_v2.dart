import 'package:flutter/material.dart';
import 'dart:math';

/// Level 1: Zur Seite geschoben (Push Aside)
///
/// **From Card 1:** "Zuerst wird das gezählte Objekt zur Seite geschoben.
/// Dabei wird die Zählzahl genannt."
///
/// **Purpose:** Child learns one-to-one correspondence by physically moving
/// each object as they count it. This is the most concrete level.
///
/// **App Translation:**
/// - Dots displayed in source area
/// - Child drags each dot to "counted" area
/// - App shows running count as dots are moved
/// - After all dots moved, child enters the total
/// - Reinforces: each object counted exactly once, final number = total
class CountDotsLevel1Widget extends StatefulWidget {
  final Function(int problemsSolved) onProgressUpdate;

  const CountDotsLevel1Widget({
    super.key,
    required this.onProgressUpdate,
  });

  @override
  State<CountDotsLevel1Widget> createState() => _CountDotsLevel1WidgetState();
}

class _CountDotsLevel1WidgetState extends State<CountDotsLevel1Widget>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocus = FocusNode();

  List<int> _sourceDotsIds = [];
  List<int> _countedDotsIds = [];
  int _targetCount = 5;
  int _problemsSolved = 0;
  bool _showFeedback = false;
  bool _isCorrect = false;
  String _feedbackMessage = '';
  bool _allDotsMovedToCountedArea = false;

  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    );
    _generateNewProblem();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocus.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _generateNewProblem() {
    setState(() {
      // Adaptive difficulty: start at 5, gradually increase
      if (_problemsSolved < 3) {
        _targetCount = 5 + _random.nextInt(3); // 5-7
      } else if (_problemsSolved < 6) {
        _targetCount = 7 + _random.nextInt(4); // 7-10
      } else {
        _targetCount = 10 + _random.nextInt(6); // 10-15
      }

      _sourceDotsIds = List.generate(_targetCount, (i) => i);
      _countedDotsIds = [];
      _answerController.clear();
      _showFeedback = false;
      _isCorrect = false;
      _feedbackMessage = '';
      _allDotsMovedToCountedArea = false;
    });
  }

  void _onDotMoved(int dotId) {
    setState(() {
      _sourceDotsIds.remove(dotId);
      _countedDotsIds.add(dotId);

      // Check if all dots have been moved
      if (_sourceDotsIds.isEmpty) {
        _allDotsMovedToCountedArea = true;
        // Auto-focus input after small delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _answerFocus.requestFocus();
          }
        });
      }
    });
  }

  void _checkAnswer() {
    if (_answerController.text.isEmpty) return;

    final answer = int.tryParse(_answerController.text);
    if (answer == null) return;

    setState(() {
      _isCorrect = (answer == _targetCount);

      if (_isCorrect) {
        _feedbackMessage = 'Perfect! You counted $_targetCount dots correctly!';
        _problemsSolved++;
        widget.onProgressUpdate(_problemsSolved);

        // Move to next problem after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _generateNewProblem();
          }
        });
      } else {
        if (answer == _countedDotsIds.length) {
          _feedbackMessage = 'You counted the dots you moved: ${_countedDotsIds.length}. But count ALL the dots you moved!';
        } else {
          _feedbackMessage = 'Not quite. Count again carefully - move each dot and count as you go.';
        }
      }

      _showFeedback = true;
      _feedbackController.forward(from: 0);
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
                          Icon(Icons.swap_horiz, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Level 1: Move Dots to Count',
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
                        'Drag each dot to the "Counted" area as you count. After moving all dots, enter how many you counted.',
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
                        'Moved: ${_countedDotsIds.length}/$_targetCount',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Counting areas
              Expanded(
                child: Row(
                  children: [
                    // Source area (uncounted dots)
                    Expanded(
                      child: _buildSourceArea(),
                    ),
                    const SizedBox(width: 16),
                    // Arrow
                    const Icon(
                      Icons.arrow_forward,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    // Counted area
                    Expanded(
                      child: _buildCountedArea(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Answer input (only shown after all dots moved)
              if (_allDotsMovedToCountedArea)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'How many dots did you count?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _answerController,
                                focusNode: _answerFocus,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Enter number...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                onSubmitted: (_) => _checkAnswer(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _checkAnswer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.all(20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Icon(Icons.check, size: 32, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Feedback message
              if (_showFeedback)
                ScaleTransition(
                  scale: _feedbackAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: _isCorrect ? Colors.green.shade100 : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isCorrect ? Colors.green : Colors.orange,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isCorrect ? Icons.check_circle : Icons.info_outline,
                          color: _isCorrect ? Colors.green : Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _feedbackMessage,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _isCorrect ? Colors.green.shade800 : Colors.orange.shade800,
                            ),
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

  Widget _buildSourceArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'Dots to Count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _sourceDotsIds.isEmpty
                ? Center(
                    child: Text(
                      'All dots moved!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _sourceDotsIds.map((id) {
                      return Draggable<int>(
                        data: id,
                        feedback: _buildDot(Colors.blue.shade300, 40),
                        childWhenDragging: _buildDot(Colors.grey.shade300, 40),
                        onDragCompleted: () => _onDotMoved(id),
                        child: _buildDot(Colors.blue, 40),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountedArea() {
    return DragTarget<int>(
      onWillAccept: (data) => true,
      onAccept: (data) {
        // Already handled in onDragCompleted
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? Colors.green.shade100
                : Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: candidateData.isNotEmpty ? Colors.green : Colors.green.shade300,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              const Text(
                'Counted Dots',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Count: ${_countedDotsIds.length}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _countedDotsIds.isEmpty
                    ? Center(
                        child: Text(
                          'Drag dots here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: _countedDotsIds.map((id) {
                          return _buildDot(Colors.green, 40);
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
