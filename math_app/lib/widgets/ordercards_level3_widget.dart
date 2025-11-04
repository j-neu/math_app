import 'package:flutter/material.dart';

/// Level 3: Reproduce from Memory - No Structure Given
///
/// **Source:** iMINT Green Card 2, Assessment
/// **Card Quote:** "Eine gute Überprüfung des Lernzuwachses besteht darin, dass
/// die Kinder nach der Übung die vollständige Auslage — ohne Vorgabe einer
/// Struktur und ohne Sicht — aufschreiben bzw. aufmalen können."
///
/// **Purpose:** Internalize the complete number sequence 1-20 from mental imagery
///
/// **How it works:**
/// - Flash the 2-row structure briefly (3 seconds)
/// - Hide everything
/// - Child must write ALL 20 numbers in correct sequence from memory
/// - No structure hints given (testing complete internalization)
/// - On error: Show structure again briefly (no-fail safety net)
/// - Success: Validates complete sequence understanding
///
/// **Pedagogical Goal:**
/// - Complete internalization: "die Auslage ohne Vorgabe einer Struktur aufschreiben"
/// - Work from pure mental imagery
/// - Demonstrate mastery of entire number sequence 1-20
///
/// **This is the assessment level** - child proves they've fully internalized the pattern
class OrderCardsLevel3Widget extends StatefulWidget {
  final Function(int correctCount) onProgressUpdate;

  const OrderCardsLevel3Widget({
    super.key,
    required this.onProgressUpdate,
  });

  @override
  State<OrderCardsLevel3Widget> createState() => _OrderCardsLevel3WidgetState();
}

class _OrderCardsLevel3WidgetState extends State<OrderCardsLevel3Widget> {
  List<TextEditingController> _controllers = [];
  int _correctCount = 0;
  bool _showStructure = true;
  bool _isFlashing = false;
  String? _feedbackMessage;
  Color _feedbackColor = Colors.blue;

  final List<String> _hints = [
    'Start with 1, then 2, 3, 4... Keep counting up!',
    'Remember the pattern: first row is 1-10, second row is 11-20.',
    'Each number in the second row is 10 more than the number above it.',
    'If stuck, use the Peek button to see the structure again.',
  ];
  int _currentHint = 0;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _startFlashSequence();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    _controllers = List.generate(20, (_) => TextEditingController());
    _feedbackMessage = 'Watch the pattern carefully!';
    _feedbackColor = Colors.blue;
  }

  void _startFlashSequence() async {
    setState(() {
      _isFlashing = true;
      _showStructure = true;
      _feedbackMessage = 'Memorize all 20 numbers and their positions...';
      _feedbackColor = Colors.blue;
    });

    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _showStructure = false;
        _isFlashing = false;
        _feedbackMessage = 'Now write all 20 numbers in order from memory!';
        _feedbackColor = Colors.orange;
      });
    }
  }

  void _checkAnswer() {
    List<int?> userAnswers = _controllers.map((c) {
      final text = c.text.trim();
      return text.isEmpty ? null : int.tryParse(text);
    }).toList();

    // Check if all filled
    if (userAnswers.contains(null)) {
      setState(() {
        _feedbackMessage = 'Please fill in all 20 numbers!';
        _feedbackColor = Colors.orange;
      });
      return;
    }

    // Check if sequence is correct (1, 2, 3, ..., 20)
    bool isCorrect = true;
    int? firstWrong;
    for (int i = 0; i < 20; i++) {
      if (userAnswers[i] != i + 1) {
        isCorrect = false;
        firstWrong = i + 1;
        break;
      }
    }

    if (isCorrect) {
      _correctCount++;

      setState(() {
        _feedbackMessage = '🎉 Perfect! You wrote all 20 numbers from memory!';
        _feedbackColor = Colors.green;
      });

      widget.onProgressUpdate(_correctCount);

      // Reset and start new round
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _resetProblem();
        }
      });
    } else {
      setState(() {
        _feedbackMessage = 'Not quite! Position $firstWrong needs attention. Let\'s see the pattern again!';
        _feedbackColor = Colors.orange;
        _showStructure = true;
      });

      // Flash structure briefly, then hide
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showStructure = false;
            _feedbackMessage = 'Try again! Remember the sequence: 1, 2, 3...';
          });
        }
      });
    }
  }

  void _resetProblem() {
    // Clear all inputs
    for (var controller in _controllers) {
      controller.clear();
    }

    setState(() {
      _feedbackMessage = 'Great work! Let\'s try another round.';
      _feedbackColor = Colors.green;
      _currentHint = 0;
    });

    // Start new flash sequence
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _startFlashSequence();
      }
    });
  }

  void _peek() {
    setState(() {
      _showStructure = true;
      _feedbackMessage = 'Here\'s the pattern! Study it, then I\'ll hide it again.';
      _feedbackColor = Colors.blue;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showStructure = false;
          _feedbackMessage = 'Now try to write all 20 numbers!';
        });
      }
    });
  }

  void _showHint() {
    setState(() {
      _feedbackMessage = _hints[_currentHint];
      _feedbackColor = Colors.purple;
      _currentHint = (_currentHint + 1) % _hints.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Instructions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Write All 20 Numbers from Memory!',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),

          // Feedback message
          if (_feedbackMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                _feedbackMessage!,
                style: TextStyle(
                  fontSize: 18,
                  color: _feedbackColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Progress display
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Completed from memory: $_correctCount times',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 20),

          // Structure display (flash or hidden)
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _showStructure ? Colors.blue.shade50 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showStructure ? Colors.blue : Colors.grey,
                width: 2,
              ),
            ),
            child: _showStructure
                ? Column(
                    children: [
                      // Row 1: 1-10
                      _buildStructureRow(List.generate(10, (i) => i + 1)),
                      const SizedBox(height: 12),
                      // Row 2: 11-20
                      _buildStructureRow(List.generate(10, (i) => i + 11)),
                    ],
                  )
                : Column(
                    children: [
                      Icon(Icons.visibility_off, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Pattern hidden\nImagine it in your mind...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 30),

          // Input area - 20 fields in sequence
          if (!_isFlashing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const Text(
                    'Write the numbers 1-20 in order:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Input grid (2 rows like the structure)
                  Column(
                    children: [
                      _buildInputRow(0, 10), // Positions 0-9 (numbers 1-10)
                      const SizedBox(height: 12),
                      _buildInputRow(10, 20), // Positions 10-19 (numbers 11-20)
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Action buttons
          if (!_isFlashing)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _checkAnswer,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Check Answer'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _showStructure ? null : _peek,
                        icon: const Icon(Icons.visibility),
                        label: const Text('Peek'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _showHint,
                        icon: const Icon(Icons.lightbulb_outline),
                        label: const Text('Hint'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStructureRow(List<int> numbers) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: numbers.map((number) {
        return Container(
          width: 50,
          height: 65,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputRow(int startIndex, int endIndex) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: List.generate(endIndex - startIndex, (i) {
        final index = startIndex + i;
        return SizedBox(
          width: 50,
          child: TextField(
            controller: _controllers[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: '${index + 1}',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      }),
    );
  }
}
