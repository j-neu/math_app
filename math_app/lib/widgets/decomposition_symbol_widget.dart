import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Symbol view for decomposition practice with fill-in equations.
///
/// Based on PIKAS progression: Handlung → Vorstellung → Symbol.
/// This is the final abstraction level where children work with
/// mathematical notation without visual support.
///
/// Shows equations like: 10 = ___ + ___
class DecompositionSymbolWidget extends StatefulWidget {
  /// Target number to decompose
  final int targetNumber;

  /// Callback when child submits a valid decomposition
  final Function(int firstPart, int secondPart)? onDecompositionSubmitted;

  /// List of decompositions already found (to track progress)
  final Set<String> foundDecompositions;

  const DecompositionSymbolWidget({
    super.key,
    this.targetNumber = 10,
    this.onDecompositionSubmitted,
    this.foundDecompositions = const {},
  });

  @override
  State<DecompositionSymbolWidget> createState() => _DecompositionSymbolWidgetState();
}

class _DecompositionSymbolWidgetState extends State<DecompositionSymbolWidget> {
  final TextEditingController _firstPartController = TextEditingController();
  final TextEditingController _secondPartController = TextEditingController();
  final FocusNode _firstPartFocus = FocusNode();
  final FocusNode _secondPartFocus = FocusNode();

  String? _feedbackMessage;
  Color? _feedbackColor;

  @override
  void dispose() {
    _firstPartController.dispose();
    _secondPartController.dispose();
    _firstPartFocus.dispose();
    _secondPartFocus.dispose();
    super.dispose();
  }

  String _normalizeDecomposition(int a, int b) {
    // Always store as smaller_larger for consistency (treats 3+7 same as 7+3)
    return a <= b ? '${a}_$b' : '${b}_$a';
  }

  bool _isAlreadyFound(int firstPart, int secondPart) {
    // Check if this decomposition (or its reverse) has been found
    final normalized = _normalizeDecomposition(firstPart, secondPart);
    return widget.foundDecompositions.any((key) {
      final parts = key.split('_');
      final a = int.parse(parts[0]);
      final b = int.parse(parts[1]);
      return _normalizeDecomposition(a, b) == normalized;
    });
  }

  void _checkAnswer() {
    final firstPart = int.tryParse(_firstPartController.text);
    final secondPart = int.tryParse(_secondPartController.text);

    if (firstPart == null || secondPart == null) {
      setState(() {
        _feedbackMessage = 'Please enter both numbers';
        _feedbackColor = Colors.orange;
      });
      return;
    }

    if (firstPart < 0 || secondPart < 0) {
      setState(() {
        _feedbackMessage = 'Numbers must be 0 or positive';
        _feedbackColor = Colors.orange;
      });
      return;
    }

    if (firstPart + secondPart == widget.targetNumber) {
      // Correct sum!
      if (_isAlreadyFound(firstPart, secondPart)) {
        setState(() {
          _feedbackMessage = 'You already found this one! Try a different decomposition.';
          _feedbackColor = Colors.blue;
        });
      } else {
        setState(() {
          _feedbackMessage = '✓ Correct! $firstPart + $secondPart = ${widget.targetNumber}';
          _feedbackColor = Colors.green;
        });

        // Only call callback once with the entered order
        widget.onDecompositionSubmitted?.call(firstPart, secondPart);

        // Clear inputs after brief delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _firstPartController.clear();
            _secondPartController.clear();
            _firstPartFocus.requestFocus();
            setState(() {
              _feedbackMessage = null;
            });
          }
        });
      }
    } else {
      // Incorrect sum
      setState(() {
        _feedbackMessage = 'Hmm, $firstPart + $secondPart = ${firstPart + secondPart}, not ${widget.targetNumber}.\nLet\'s try again!';
        _feedbackColor = Colors.red.shade300;
      });
    }
  }

  int _countUniqueDecompositions() {
    // Count unique pairs (treating 3+7 and 7+3 as same)
    final Set<String> uniquePairs = {};
    for (final key in widget.foundDecompositions) {
      final parts = key.split('_');
      final a = int.parse(parts[0]);
      final b = int.parse(parts[1]);
      final normalized = _normalizeDecomposition(a, b);
      uniquePairs.add(normalized);
    }
    return uniquePairs.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalDecompositions = widget.targetNumber + 1;
    final foundCount = _countUniqueDecompositions();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            Text(
              'Decompose ${widget.targetNumber}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Progress indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Found $foundCount of $totalDecompositions ways',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 32),

            // Equation display
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Target number
                    Text(
                      '${widget.targetNumber}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Equals sign
                    const Text(
                      '=',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // First input box
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller: _firstPartController,
                        focusNode: _firstPartFocus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: '?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _secondPartFocus.requestFocus(),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Plus sign
                    const Text(
                      '+',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Second input box
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller: _secondPartController,
                        focusNode: _secondPartFocus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: '?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _checkAnswer(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit button
            ElevatedButton(
              onPressed: _checkAnswer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const Text('Check Answer'),
            ),

            const SizedBox(height: 16),

            // Feedback message
            if (_feedbackMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _feedbackColor?.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _feedbackColor ?? Colors.transparent, width: 2),
                ),
                child: Text(
                  _feedbackMessage!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _feedbackColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 24),

            // Found decompositions list
            if (widget.foundDecompositions.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300, width: 2),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Decompositions You Found:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.foundDecompositions.map((key) {
                        final parts = key.split('_');
                        return Chip(
                          label: Text(
                            '${parts[0]} + ${parts[1]}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.green.shade100,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
