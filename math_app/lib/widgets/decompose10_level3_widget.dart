import 'package:flutter/material.dart';

/// Level 3: Independent Mastery for Decompose 10
///
/// Translation of iMINT Card 3 Activity B:
/// Physical: "Hands covered with cloth, imagine your 10 fingers and name decomposition"
/// Digital: Counters hidden, child writes from memory, counters appear ONLY on errors
///
/// Features:
/// - Visual HIDDEN by default
/// - Instruction: "Find ALL ways to make 10! How many can you find?"
/// - Input: 10 = ___ + ___
/// - Tracks found decompositions (prevents duplicates)
/// - Progress: "Found 3 of 11 ways"
/// - On error: Counters appear briefly (3 seconds), then hide again
/// - Hints available for finding all systematically
///
/// **CRITICAL DESIGN DECISION: Order-Dependent Tracking**
/// - This exercise tracks decompositions as ORDERED PAIRS (2+8 ≠ 8+2)
/// - WHY: Pedagogical goal is observing "gegensinniges Verändern" pattern
/// - Child must find all 11: 0+10, 1+9, 2+8, 3+7, 4+6, 5+5, 6+4, 7+3, 8+2, 9+1, 10+0
/// - Pattern: As first part +1, second part -1 (systematic inverse change)
/// - Implementation: Stores as "a_b" without normalization
class Decompose10Level3Widget extends StatefulWidget {
  final Function(int count) onProgressUpdate;

  const Decompose10Level3Widget({
    super.key,
    required this.onProgressUpdate,
  });

  @override
  State<Decompose10Level3Widget> createState() => _Decompose10Level3WidgetState();
}

class _Decompose10Level3WidgetState extends State<Decompose10Level3Widget> {
  final TextEditingController _firstPartController = TextEditingController();
  final TextEditingController _secondPartController = TextEditingController();

  // Track found decompositions (as ordered pairs "a_b")
  final Set<String> _foundDecompositions = {};

  // Feedback state
  String? _feedbackMessage;
  Color? _feedbackColor;

  // Visual support state (shows briefly on errors)
  bool _showingVisualSupport = false;
  int? _supportFirstPart;
  int? _supportSecondPart;

  // Hint state
  int _hintLevel = 0;

  static const int _totalDecompositions = 11; // 0+10, 1+9, 2+8, ..., 10+0 (all ordered pairs)

  @override
  void dispose() {
    _firstPartController.dispose();
    _secondPartController.dispose();
    super.dispose();
  }

  String _makeKey(int a, int b) {
    // Store as ordered pair (NOT normalized - 2+8 is different from 8+2)
    return '${a}_$b';
  }

  bool _isAlreadyFound(int a, int b) {
    return _foundDecompositions.contains(_makeKey(a, b));
  }

  void _showVisualSupport(int firstPart, int secondPart) {
    setState(() {
      _showingVisualSupport = true;
      _supportFirstPart = firstPart;
      _supportSecondPart = secondPart;
    });

    // Hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showingVisualSupport = false;
          _supportFirstPart = null;
          _supportSecondPart = null;
        });
      }
    });
  }

  void _checkAnswer() {
    final firstPart = int.tryParse(_firstPartController.text) ?? -1;
    final secondPart = int.tryParse(_secondPartController.text) ?? -1;

    // Validation
    if (firstPart < 0 || secondPart < 0) {
      setState(() {
        _feedbackMessage = 'Please enter both numbers.';
        _feedbackColor = Colors.orange;
      });
      return;
    }

    if (firstPart + secondPart != 10) {
      // Wrong sum - show visual support
      final actualSum = firstPart + secondPart;
      setState(() {
        _feedbackMessage = '$firstPart + $secondPart = $actualSum, not 10. Let\'s see the counters!';
        _feedbackColor = Colors.orange;
      });
      _showVisualSupport(firstPart, secondPart);
      return;
    }

    // Correct sum - check if already found
    if (_isAlreadyFound(firstPart, secondPart)) {
      setState(() {
        _feedbackMessage = 'Great! You already found $firstPart + $secondPart. Can you find a different one?';
        _feedbackColor = Colors.blue;
      });
      return;
    }

    // New decomposition found!
    setState(() {
      _foundDecompositions.add(_makeKey(firstPart, secondPart));
      _feedbackMessage = 'Excellent! You found $firstPart + $secondPart! (${_foundDecompositions.length}/$_totalDecompositions)';
      _feedbackColor = Colors.green;
      _firstPartController.clear();
      _secondPartController.clear();
      _hintLevel = 0; // Reset hint level on success
    });

    widget.onProgressUpdate(_foundDecompositions.length);

    // Check for completion
    if (_foundDecompositions.length >= _totalDecompositions) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showCompletionDialog();
        }
      });
    }
  }

  void _showHint() {
    setState(() {
      _hintLevel++;
      switch (_hintLevel) {
        case 1:
          _feedbackMessage = 'Hint: Try starting with 0. What is 0 + ?';
          _feedbackColor = Colors.blue;
          break;
        case 2:
          _feedbackMessage = 'Hint: You found some pairs. Do you see a pattern? (0+10, 1+9, 2+8...)';
          _feedbackColor = Colors.blue;
          break;
        case 3:
          _feedbackMessage = 'Hint: Don\'t forget about 5+5!';
          _feedbackColor = Colors.blue;
          break;
        case 4:
          _feedbackMessage = 'Hint: Count up from 0+10, 1+9, 2+8... all the way to 10+0';
          _feedbackColor = Colors.blue;
          break;
        default:
          final missingCount = _totalDecompositions - _foundDecompositions.length;
          _feedbackMessage = 'You\'re missing $missingCount more. Keep trying!';
          _feedbackColor = Colors.blue;
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber, size: 40),
            SizedBox(width: 12),
            Text('🎉 Amazing! 🎉'),
          ],
        ),
        content: Text(
          'You found all $_totalDecompositions ways to make 10 from memory!\n\nYou\'ve mastered this skill!',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _foundDecompositions.clear();
                _feedbackMessage = null;
                _hintLevel = 0;
              });
              widget.onProgressUpdate(0);
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to learning path
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete Exercise'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _foundDecompositions.length / _totalDecompositions;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.green.shade700, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Level 3: Find All Ways',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You know 10 can be broken into parts. How many ways can you find?',
                    style: TextStyle(fontSize: 16, color: Colors.green.shade900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Found: ${_foundDecompositions.length} of $_totalDecompositions ways',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Progress bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? Colors.amber : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_foundDecompositions.length / _totalDecompositions * 100).toStringAsFixed(0)}% Complete',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Visual support area (shown only on errors, for 3 seconds)
            if (_showingVisualSupport && _supportFirstPart != null && _supportSecondPart != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      'Here\'s what $_supportFirstPart + $_supportSecondPart looks like:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildVisualSupport(_supportFirstPart!, _supportSecondPart!),
                    const SizedBox(height: 8),
                    Text(
                      '(Counters will disappear in a moment)',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                    ),
                  ],
                ),
              ),

            // Equation input
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('10 = ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _firstPartController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const Text(' + ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _secondPartController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (_) => _checkAnswer(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Submit and Hint buttons
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _checkAnswer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Submit', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showHint,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Icon(Icons.help_outline),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Feedback message
            if (_feedbackMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _feedbackColor?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _feedbackColor ?? Colors.grey, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(
                      _feedbackColor == Colors.green
                          ? Icons.check_circle
                          : (_feedbackColor == Colors.blue ? Icons.lightbulb : Icons.info_outline),
                      color: _feedbackColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _feedbackMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _feedbackColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // List of found decompositions
            if (_foundDecompositions.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Found Decompositions:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _foundDecompositions.map((key) {
                        final parts = key.split('_');
                        return Chip(
                          label: Text('${parts[0]}+${parts[1]}'),
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

  Widget _buildVisualSupport(int firstPart, int secondPart) {
    return Center(
      child: Column(
        children: [
          // Top row (counters 0-4)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) => _buildCounter(i, firstPart)),
          ),
          const SizedBox(height: 8),
          // Bottom row (counters 5-9)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) => _buildCounter(i + 5, firstPart)),
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(int index, int blueCount) {
    final isBlue = index < blueCount;

    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isBlue ? Colors.blue : Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.circle,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
      ),
    );
  }
}
