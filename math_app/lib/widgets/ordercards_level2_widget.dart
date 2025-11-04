import 'package:flutter/material.dart';
import 'dart:math';

/// Level 2: Find the Missing Cards
///
/// **Source:** iMINT Green Card 2, Activity B
/// **Physical Activity:** "Kind A hält sich nun die Augen zu und Kind B nimmt
/// zwei Karten weg. Kind A muss jetzt die fehlenden Karten benennen und sie dann
/// in die richtige Lücke einfügen."
///
/// **Purpose:** Understand neighbor relationships and gap-filling in sequence
///
/// **How it works:**
/// - Display 1-20 in 2-row structure with 2 cards missing (shown as gaps)
/// - Child must identify which numbers are missing
/// - Input fields appear at the gap locations
/// - After correct identification, asks: "Woher weißt du, dass die Zahl an
///   diesen Platz gehört?" (How do you know this number belongs here?)
/// - Shows neighbor relationships: "13 is below 3 and follows 12"
///
/// **Pedagogical Goal:**
/// - Use neighbor relationships to identify missing numbers
/// - Understand positional logic in number sequence
/// - Build mental model of structured number arrangement
///
/// **Unlocks Level 3:** After finding missing cards 10 times correctly
class OrderCardsLevel2Widget extends StatefulWidget {
  final Function(int correctCount, int totalAttempts) onProgressUpdate;

  const OrderCardsLevel2Widget({
    super.key,
    required this.onProgressUpdate,
  });

  @override
  State<OrderCardsLevel2Widget> createState() => _OrderCardsLevel2WidgetState();
}

class _OrderCardsLevel2WidgetState extends State<OrderCardsLevel2Widget> {
  List<int> _missingNumbers = [];
  final Map<int, TextEditingController> _controllers = {};
  int _correctCount = 0;
  int _totalAttempts = 0;
  String? _feedbackMessage;
  Color _feedbackColor = Colors.blue;
  bool _showingExplanation = false;
  String? _explanationText;

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
    // Select 2 random numbers from 1-20 to hide
    final allNumbers = List.generate(20, (i) => i + 1);
    allNumbers.shuffle();
    _missingNumbers = allNumbers.take(2).toList()..sort();

    // Create controllers for missing numbers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    for (var number in _missingNumbers) {
      _controllers[number] = TextEditingController();
    }

    setState(() {
      _feedbackMessage = 'Two numbers are missing! Can you find them?';
      _feedbackColor = Colors.blue;
      _showingExplanation = false;
      _explanationText = null;
    });
  }

  void _checkAnswer() {
    _totalAttempts++;

    bool allCorrect = true;
    List<String> wrongInputs = [];

    for (var number in _missingNumbers) {
      final text = _controllers[number]!.text.trim();
      final userAnswer = int.tryParse(text);

      if (userAnswer != number) {
        allCorrect = false;
        if (text.isNotEmpty) {
          wrongInputs.add(text);
        }
      }
    }

    if (allCorrect) {
      _correctCount++;

      setState(() {
        _feedbackMessage = 'Perfect! You found both missing numbers: ${_missingNumbers.join(" and ")}!';
        _feedbackColor = Colors.green;
        _showingExplanation = true;
        _explanationText = _generateExplanation();
      });

      widget.onProgressUpdate(_correctCount, _totalAttempts);

      // Show explanation, then generate new problem
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          _generateProblem();
        }
      });
    } else {
      setState(() {
        if (wrongInputs.isEmpty) {
          _feedbackMessage = 'Fill in the missing numbers first!';
        } else {
          _feedbackMessage = 'Not quite! Look at the neighbors of the empty spots.';
        }
        _feedbackColor = Colors.orange;
        _showingExplanation = false;
      });

      widget.onProgressUpdate(_correctCount, _totalAttempts);
    }
  }

  String _generateExplanation() {
    // Generate explanation based on position logic
    List<String> explanations = [];

    for (var number in _missingNumbers) {
      final before = number - 1;
      final after = number + 1;
      final above = number <= 10 ? null : number - 10;
      final below = number >= 11 ? null : number + 10;

      String exp = '$number: ';
      List<String> clues = [];

      if (before >= 1) clues.add('follows $before');
      if (after <= 20) clues.add('comes before $after');
      if (above != null) clues.add('is below $above');
      if (below != null) clues.add('is above $below');

      exp += clues.take(2).join(' and ');
      explanations.add(exp);
    }

    return 'Woher weißt du das?\n${explanations.join('\n')}';
  }

  void _showHint() {
    if (_missingNumbers.isEmpty) return;

    final firstMissing = _missingNumbers.first;
    final before = firstMissing > 1 ? firstMissing - 1 : null;
    final after = firstMissing < 20 ? firstMissing + 1 : null;

    String hint = 'Look for the gaps! ';
    if (before != null && after != null) {
      hint += 'What number goes between $before and $after?';
    } else if (before != null) {
      hint += 'What number comes after $before?';
    } else if (after != null) {
      hint += 'What number comes before $after?';
    }

    setState(() {
      _feedbackMessage = hint;
      _feedbackColor = Colors.purple;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = _totalAttempts > 0
        ? ((_correctCount / _totalAttempts) * 100).toStringAsFixed(0)
        : '0';

    return SingleChildScrollView(
      child: Column(
        children: [
          // Instructions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Find the Missing Numbers!',
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

          // Explanation (after correct answer)
          if (_showingExplanation && _explanationText != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _explanationText!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ),

          // Progress display
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  'Found: $_correctCount / $_totalAttempts',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Accuracy: $accuracy%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _correctCount / 10,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_correctCount/10 to unlock Level 3',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Number cards with gaps
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                // Row 1: Numbers 1-10
                _buildRow(List.generate(10, (i) => i + 1)),
                const SizedBox(height: 16),
                // Row 2: Numbers 11-20
                _buildRow(List.generate(10, (i) => i + 11)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          if (!_showingExplanation)
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: numbers.map((number) {
        return _missingNumbers.contains(number)
            ? _buildGapCard(number)
            : _buildCard(number);
      }).toList(),
    );
  }

  Widget _buildCard(int number) {
    return Container(
      width: 55,
      height: 70,
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
        child: Text(
          number.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildGapCard(int number) {
    return Container(
      width: 55,
      height: 70,
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
