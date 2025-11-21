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
/// - Show the 2-row structure with 4-6 cards missing (gaps shown)
/// - Child must identify ALL missing numbers
/// - Tests deeper internalization than Level 2 (more gaps to fill)
/// - On error: Show complete structure briefly (no-fail safety net)
/// - Success: Validates understanding of full sequence 1-20
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
  List<int> _missingNumbers = []; // 4-6 missing numbers
  final Map<int, TextEditingController> _controllers = {};
  int _correctCount = 0;
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
    _generateProblem();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _generateProblem() {
    // Select 4-6 random numbers to hide (adaptive difficulty)
    final difficulty = _correctCount < 3 ? 4 : (_correctCount < 7 ? 5 : 6);
    final allNumbers = List.generate(20, (i) => i + 1);
    allNumbers.shuffle();
    _missingNumbers = allNumbers.take(difficulty).toList()..sort();

    // Create controllers for missing numbers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    for (var number in _missingNumbers) {
      _controllers[number] = TextEditingController();
    }

    setState(() {
      _feedbackMessage = '$difficulty numbers are missing! Use the 2-row pattern to find them.';
      _feedbackColor = Colors.blue;
    });
  }

  void _checkAnswer() {
    bool allCorrect = true;
    List<String> wrongInputs = [];

    for (var number in _missingNumbers) {
      final text = _controllers[number]!.text.trim();
      final userAnswer = int.tryParse(text);

      if (userAnswer != number) {
        allCorrect = false;
        if (text.isNotEmpty) {
          wrongInputs.add('$text (should be $number)');
        }
      }
    }

    // Check if all filled
    if (_missingNumbers.any((n) => _controllers[n]!.text.trim().isEmpty)) {
      setState(() {
        _feedbackMessage = 'Fill in all ${_missingNumbers.length} missing numbers!';
        _feedbackColor = Colors.orange;
      });
      return;
    }

    if (allCorrect) {
      _correctCount++;

      setState(() {
        _feedbackMessage = '🎉 Perfect! You found all ${_missingNumbers.length} missing numbers!';
        _feedbackColor = Colors.green;
      });

      widget.onProgressUpdate(_correctCount);

      // Generate new problem
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _generateProblem();
        }
      });
    } else {
      setState(() {
        if (wrongInputs.isEmpty) {
          _feedbackMessage = 'Fill in all the gaps first!';
        } else {
          _feedbackMessage = 'Not quite! Check: ${wrongInputs.take(2).join(", ")}';
        }
        _feedbackColor = Colors.orange;
      });
    }
  }

  // Removed _resetProblem - now using _generateProblem directly

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
              'Find All Missing Numbers!',
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

          // 2-row structure with gaps
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                // Row 1: Numbers 1-10 (some missing)
                _buildRow(List.generate(10, (i) => i + 1)),
                const SizedBox(height: 16),
                // Row 2: Numbers 11-20 (some missing)
                _buildRow(List.generate(10, (i) => i + 11)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
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
                OutlinedButton.icon(
                  onPressed: _showHint,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Hint'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<int> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: numbers.map((number) {
        return Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _missingNumbers.contains(number)
                ? _buildGapCard(number)
                : _buildCard(number),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCard(int number) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 30,
        maxWidth: 50,
        minHeight: 50,
        maxHeight: 65,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            number.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGapCard(int number) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 30,
        maxWidth: 50,
        minHeight: 50,
        maxHeight: 65,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 40,
          child: TextField(
            controller: _controllers[number],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              hintText: '?',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}
