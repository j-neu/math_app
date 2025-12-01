import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Level 4: Count Backward in Steps of 2 (Starting from 20, No Visual Support)
///
/// **Source:** iMINT Card 6 + 7: "Zweierschritte am Rechenschiffchen" / "In Zweierschritten zählen"
/// **Physical action from card:** Mental counting backward in steps of 2
/// **App translation:** Fill in ONE even number at a time, starting from 20, counting BACKWARD (18, 16, 14...)
///
/// **Grid Layout (Example for Problem 1 - asking for "18"):**
/// ```
/// X   X   X   X   X  |   X   X   X   X   X
/// X   X   X   X   X  |   X   X   X  [?]  20
/// ```
/// Only last cell shows "20", all others are X except current target
///
/// **Features:**
/// - Only "20" is visible (last cell)
/// - ONE even number is editable per problem (marked with ?)
/// - Other numbers shown as X (completely hidden)
/// - 9 problems total (one for each even number: 18, 16, 14, 12, 10, 8, 6, 4, 2)
/// - Child must count BACKWARD mentally
///
/// **Scaffolding Level 4 of 4:**
/// NO visual support - complete mental work, backward direction
class CountSteps2Level4Widget extends StatefulWidget {
  final Function(bool)? onProblemComplete;
  final Function()? onLevelComplete;

  const CountSteps2Level4Widget({
    Key? key,
    this.onProblemComplete,
    this.onLevelComplete,
  }) : super(key: key);

  @override
  State<CountSteps2Level4Widget> createState() =>
      _CountSteps2Level4WidgetState();
}

class _CountSteps2Level4WidgetState extends State<CountSteps2Level4Widget> {
  static const int totalProblems = 9;

  int _currentProblem = 0; // 0-8, representing even numbers 18, 16, 14, 12, 10, 8, 6, 4, 2
  bool _showFeedback = false;
  bool _isCorrect = false;

  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocus = FocusNode();

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocus.dispose();
    super.dispose();
  }

  int get _targetNumber => 18 - (_currentProblem * 2); // 18, 16, 14, 12, 10, 8, 6, 4, 2

  void _checkAnswer() {
    final userAnswer = int.tryParse(_answerController.text);
    final isCorrect = userAnswer == _targetNumber;

    setState(() {
      _isCorrect = isCorrect;
      _showFeedback = true;
    });

    widget.onProblemComplete?.call(isCorrect);

    if (isCorrect) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _currentProblem++;
            _answerController.clear();
            _showFeedback = false;

            if (_currentProblem >= totalProblems) {
              // Level complete
              widget.onLevelComplete?.call();
            } else {
              // Next problem - auto-focus
              _answerFocus.requestFocus();
            }
          });
        }
      });
    } else {
      // Wrong answer - allow retry
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showFeedback = false;
            _answerController.clear();
            _answerFocus.requestFocus();
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentProblem >= totalProblems) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Instructions
            Text(
              'Count BACKWARD by 2s from 20',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Fill in: ?, ?, ?... 20',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade700,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Number Grid
            _buildGrid(),

            const SizedBox(height: 24),

            // Feedback
            if (_showFeedback) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isCorrect ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isCorrect ? Colors.green.shade300 : Colors.orange.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isCorrect ? Icons.check_circle : Icons.info_outline,
                      color: _isCorrect ? Colors.green.shade700 : Colors.orange.shade700,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isCorrect
                            ? 'Perfect! $_targetNumber is correct!'
                            : 'Try again! Start at 20, subtract 2 each time.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isCorrect ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Progress indicator
            Text(
              'Problem ${_currentProblem + 1} / $totalProblems',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Column(
      children: [
        _buildRow(1, 11), // Row 1: numbers 1-10
        const SizedBox(height: 8),
        _buildRow(11, 21), // Row 2: numbers 11-20
      ],
    );
  }

  Widget _buildRow(int startIndex, int endIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // First 5 cells
        for (int i = startIndex; i < startIndex + 5 && i < endIndex; i++)
          _buildCell(i),

        // Vertical divider
        Container(
          width: 2,
          height: 45,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          color: Colors.grey.shade400,
        ),

        // Last 5 cells
        for (int i = startIndex + 5; i < endIndex && i <= 20; i++) _buildCell(i),
      ],
    );
  }

  Widget _buildCell(int number) {
    final isTwenty = number == 20;
    final isTarget = number == _targetNumber;
    final isAlreadyFilled = number > _targetNumber && number < 20 && number % 2 == 0;

    // Show "20" in last cell
    if (isTwenty) {
      return Container(
        width: 28,
        height: 45,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(6),
          color: Colors.grey.shade50,
        ),
        alignment: Alignment.center,
        child: const Text(
          '20',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      );
    }

    // Target number - editable
    if (isTarget) {
      return Container(
        width: 28,
        height: 45,
        margin: const EdgeInsets.all(2),
        child: TextField(
          controller: _answerController,
          focusNode: _answerFocus,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 2,
          autofocus: true,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            hintText: '?',
            hintStyle: TextStyle(color: Colors.red.shade300),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.red, width: 2.5),
            ),
            fillColor: Colors.red.shade50,
            filled: true,
          ),
          onSubmitted: (_) => _checkAnswer(),
        ),
      );
    }

    // Already filled or hidden numbers - show X or number
    return Container(
      width: 28,
      height: 45,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(6),
        color: isAlreadyFilled ? Colors.green.shade50 : Colors.grey.shade100,
      ),
      alignment: Alignment.center,
      child: Text(
        isAlreadyFilled ? number.toString() : 'X',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isAlreadyFilled ? Colors.green.shade700 : Colors.grey.shade400,
        ),
      ),
    );
  }
}
