import 'package:flutter/material.dart';

/// Level 1: Read the Sequence - Understanding the 2-Row Structure
///
/// **Source:** iMINT Green Card 2, Activity A
/// **Physical Activity:** "Die Lehrkraft legt die Zahlenkarten bis 20 geordnet auf
/// den Tisch. Kind B liest die Reihenfolge der Karten laut vor und zeigt dabei auf
/// die entsprechenden Karten."
///
/// **Purpose:** Understand number sequence and the tens-structure pattern
///
/// **How it works:**
/// - Cards 1-20 displayed in 2-row structure (1-10 top row, 11-20 bottom row)
/// - Child taps each card in sequence to "read" it (simulates reading aloud)
/// - Correct tap: card highlights, moves to next expected number
/// - Visual emphasis on the pattern: ones are directly above corresponding tens
/// - Prompt: "Was fällt dir auf?" (What do you notice?)
///
/// **Pedagogical Goal:**
/// - Recognize tens-structure (13 is below 3, follows 12)
/// - Understand positional patterns in number sequence
/// - Build foundation for place value understanding
///
/// **Unlocks Level 2:** After reading sequence 3 times
class OrderCardsLevel1Widget extends StatefulWidget {
  final Function(int problemsSolved) onProgressUpdate;

  const OrderCardsLevel1Widget({
    super.key,
    required this.onProgressUpdate,
  });

  @override
  State<OrderCardsLevel1Widget> createState() => _OrderCardsLevel1WidgetState();
}

class _OrderCardsLevel1WidgetState extends State<OrderCardsLevel1Widget>
    with SingleTickerProviderStateMixin {
  int _nextExpected = 1;
  int _sequencesCompleted = 0;
  String? _feedbackMessage;
  final Set<int> _highlightedCards = {};
  int? _shakingCard;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _feedbackMessage = 'Tap the cards in order, starting with 1!';
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onCardTapped(int number) {
    if (number == _nextExpected) {
      // Correct!
      setState(() {
        _highlightedCards.add(number);
        _nextExpected++;

        if (_nextExpected <= 10) {
          _feedbackMessage = 'Great! Keep going... Tap $_nextExpected';
        } else if (_nextExpected <= 20) {
          _feedbackMessage = 'Now the second row! Tap $_nextExpected';
        } else {
          // Completed sequence!
          _sequencesCompleted++;
          _feedbackMessage = '🎉 Perfect! You read all 20 numbers in order!';
          widget.onProgressUpdate(_sequencesCompleted);

          // Reset after 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _resetSequence();
            }
          });
        }
      });
    } else {
      // Incorrect
      setState(() {
        _shakingCard = number;
        if (number < _nextExpected) {
          _feedbackMessage = 'You already read that one! Look for $_nextExpected.';
        } else {
          _feedbackMessage = 'Not yet! First find $_nextExpected.';
        }
      });

      _shakeController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _shakingCard = null;
          });
        }
      });
    }
  }

  void _resetSequence() {
    setState(() {
      _nextExpected = 1;
      _highlightedCards.clear();
      _feedbackMessage = 'Great work! Let\'s read the sequence again.';
    });
  }

  void _showPatternDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Was fällt dir auf?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Look at the pattern:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('• The first row has numbers 1-10'),
            const Text('• The second row has numbers 11-20'),
            const SizedBox(height: 12),
            const Text(
              'Notice:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• 11 is below 1'),
            const Text('• 12 is below 2'),
            const Text('• 13 is below 3'),
            const SizedBox(height: 8),
            const Text('Each number in the second row is 10 more than the number above it!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Instructions
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Read the Numbers: Tap them in order from 1 to 20',
            style: Theme.of(context).textTheme.titleMedium,
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
                color: _feedbackMessage!.contains('Great') ||
                        _feedbackMessage!.contains('Perfect')
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Progress indicator
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Next: $_nextExpected',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 20),
              Text(
                'Sequences completed: $_sequencesCompleted/3',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Pattern help button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: OutlinedButton.icon(
            onPressed: _showPatternDialog,
            icon: const Icon(Icons.help_outline),
            label: const Text('Was fällt dir auf? (What do you notice?)'),
          ),
        ),

        const SizedBox(height: 20),

        // Number cards in 2-row structure
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Row 1: Numbers 1-10
                _buildRow(List.generate(10, (i) => i + 1)),
                const SizedBox(height: 16),
                // Row 2: Numbers 11-20
                _buildRow(List.generate(10, (i) => i + 11)),
              ],
            ),
          ),
        ),

        // Completion status
        if (_sequencesCompleted >= 3)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '✨ Excellent! You understand the pattern! Ready for Level 2?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRow(List<int> numbers) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: numbers.map((number) => _buildCard(number)).toList(),
    );
  }

  Widget _buildCard(int number) {
    final isHighlighted = _highlightedCards.contains(number);
    final isNext = number == _nextExpected;
    final isShaking = _shakingCard == number;

    Widget card = Container(
      width: 55,
      height: 70,
      decoration: BoxDecoration(
        color: isHighlighted
            ? Colors.green.shade100
            : (isNext ? Colors.blue.shade50 : Colors.white),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted
              ? Colors.green
              : (isNext ? Colors.blue : Colors.grey.shade400),
          width: isNext ? 3 : 2,
        ),
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
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isHighlighted ? Colors.green.shade800 : Colors.black,
          ),
        ),
      ),
    );

    if (isShaking) {
      card = AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          );
        },
        child: card,
      );
    }

    return GestureDetector(
      onTap: () => _onCardTapped(number),
      child: card,
    );
  }
}
