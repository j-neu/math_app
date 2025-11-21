import 'package:flutter/material.dart';

/// Level 4: Finale - Easier Mixed Review
///
/// **Purpose:** ADHD-friendly "victory lap" after completing card-prescribed levels
///
/// **Difficulty:** EASIER than Level 3
/// - Level 3: 4-6 missing numbers (harder)
/// - Level 4: 2-3 missing numbers (easier, confidence-building)
///
/// **Layout:** Full 2-row structure (1-10 top, 11-20 bottom) - CONSISTENT with Levels 1-3
///
/// **Completion Criteria (from COMPLETION_CRITERIA.md):**
/// - Minimum 10 problems completed
/// - Zero errors (100% accuracy in last 10 problems)
/// - Time limit: <30 seconds per problem
///
/// **Integration:** Uses ExerciseProgressMixin callbacks for timing and result tracking
class OrderCardsLevel4Widget extends StatefulWidget {
  final VoidCallback onStartProblemTimer;
  final Function(bool correct, String? userAnswer) onProblemComplete;

  const OrderCardsLevel4Widget({
    super.key,
    required this.onStartProblemTimer,
    required this.onProblemComplete,
  });

  @override
  State<OrderCardsLevel4Widget> createState() => _OrderCardsLevel4WidgetState();
}

class _OrderCardsLevel4WidgetState extends State<OrderCardsLevel4Widget> {
  List<int> _missingNumbers = []; // 2-3 missing numbers (easier than L3)
  final Map<int, TextEditingController> _controllers = {};

  int _correctAnswers = 0;
  int _totalAttempts = 0;
  String? _feedbackMessage;
  Color _feedbackColor = Colors.blue;
  bool _showingFeedback = false;

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
    // Adaptive difficulty: Start with 2, increase to 3 after 5 correct
    final difficulty = _correctAnswers < 5 ? 2 : 3;

    // Select random numbers to hide
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
      _feedbackMessage = 'Find the ${difficulty == 2 ? '2' : '3'} missing numbers!';
      _feedbackColor = Colors.blue;
      _showingFeedback = false;
    });

    // Start timer for this problem
    widget.onStartProblemTimer();
  }

  void _checkAnswer() {
    _totalAttempts++;

    bool allFilled = true;
    bool allCorrect = true;
    List<String> userAnswers = [];

    // Check if all fields are filled
    for (var number in _missingNumbers) {
      final text = _controllers[number]!.text.trim();
      if (text.isEmpty) {
        allFilled = false;
      } else {
        userAnswers.add(text);
        final userAnswer = int.tryParse(text);
        if (userAnswer != number) {
          allCorrect = false;
        }
      }
    }

    if (!allFilled) {
      setState(() {
        _feedbackMessage = 'Fill in all ${_missingNumbers.length} missing numbers!';
        _feedbackColor = Colors.orange;
        _showingFeedback = true;
      });

      // Record as incorrect (incomplete answer)
      widget.onProblemComplete(false, 'incomplete');
      return;
    }

    // Record result with mixin
    final userAnswerString = userAnswers.join(', ');
    widget.onProblemComplete(allCorrect, userAnswerString);

    if (allCorrect) {
      _correctAnswers++;

      setState(() {
        _feedbackMessage = '🎉 Perfect! You found all ${_missingNumbers.length} numbers!';
        _feedbackColor = Colors.green;
        _showingFeedback = true;
      });

      // Auto-advance to next problem after brief celebration
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _generateProblem();
        }
      });
    } else {
      setState(() {
        _feedbackMessage = 'Not quite! Check your answers and try again.';
        _feedbackColor = Colors.red;
        _showingFeedback = true;
      });

      // Clear incorrect answers after showing feedback
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showingFeedback = false;
          });
        }
      });
    }
  }

  void _showHint() {
    if (_missingNumbers.isEmpty) return;

    final firstMissing = _missingNumbers.first;
    final before = firstMissing > 1 ? firstMissing - 1 : null;
    final after = firstMissing < 20 ? firstMissing + 1 : null;

    String hint = 'Look at the neighbors! ';
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
      _showingFeedback = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = _totalAttempts > 0
        ? ((_correctAnswers / _totalAttempts) * 100).toStringAsFixed(0)
        : '0';

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header - Level 4 Finale
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.green.shade300, width: 2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Level 4: Finale 🎉',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Easier mixed review - Show your mastery!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Feedback message
          if (_feedbackMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Correct: $_correctAnswers',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      'Total: $_totalAttempts',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      'Accuracy: $accuracy%',
                      style: TextStyle(
                        fontSize: 14,
                        color: int.parse(accuracy) >= 90 ? Colors.green : Colors.grey.shade600,
                        fontWeight: int.parse(accuracy) >= 90 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _correctAnswers / 10,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_correctAnswers/10 problems (need 10 with zero errors to complete)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Full 2-row structure (1-10 top, 11-20 bottom) with 2-3 gaps
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
          if (!_showingFeedback || _feedbackColor != Colors.green)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _checkAnswer,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Check Answer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _showHint,
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('Need a hint?'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),
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
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade600, width: 3),
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
