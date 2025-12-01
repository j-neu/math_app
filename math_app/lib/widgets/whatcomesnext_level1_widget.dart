import 'package:flutter/material.dart';

/// Level 1: Guided Exploration - Explore Predecessor and Successor
///
/// **Pedagogical Purpose:**
/// - Understand predecessor (number before) and successor (number after)
/// - Build visual connection between consecutive numbers on number line
/// - Explore the concepts of "before" and "after" interactively
///
/// **How It Works:**
/// - Child sees number line from 0 to 20
/// - Clicks any number to select it (highlighted)
/// - Taps "Before" button to see predecessor (with arrow animation)
/// - Taps "After" button to see successor (with arrow animation)
/// - Explores multiple numbers to understand the pattern
///
/// **Translation from Physical Activity:**
/// - Physical: Point to number card, then to card before/after it
/// - Digital: Tap number, see visual arrows to before/after
///
/// **"Wie kommt die Handlung in den Kopf?"**
/// - Level 1: SEE the before/after relationship visually
/// - Prepares for Level 2: WRITE the predecessor/successor
/// - Prepares for Level 3: RECALL from memory
class WhatComesNextLevel1Widget extends StatefulWidget {
  final Function(int explorationsCount) onProgressUpdate;

  const WhatComesNextLevel1Widget({
    super.key,
    required this.onProgressUpdate,
  });

  @override
  State<WhatComesNextLevel1Widget> createState() =>
      _WhatComesNextLevel1WidgetState();
}

class _WhatComesNextLevel1WidgetState extends State<WhatComesNextLevel1Widget>
    with SingleTickerProviderStateMixin {
  int? _selectedNumber; // Currently selected number
  int? _highlightedNumber; // Number to highlight (predecessor or successor)
  String _highlightType = ''; // 'before' or 'after'
  int _explorationsCount = 0; // Track how many explorations
  static const int _requiredExplorations = 5;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _selectNumber(int number) {
    setState(() {
      _selectedNumber = number;
      _highlightedNumber = null;
      _highlightType = '';
    });
  }

  void _showBefore() {
    if (_selectedNumber == null) {
      _showSelectNumberMessage();
      return;
    }

    if (_selectedNumber == 0) {
      _showMessage('There is no number before 0!', Colors.orange);
      return;
    }

    setState(() {
      _highlightedNumber = _selectedNumber! - 1;
      _highlightType = 'before';
      _explorationsCount++;
    });

    // Notify coordinator of progress
    widget.onProgressUpdate(_explorationsCount);

    _pulseController.forward(from: 0);

    // Auto-hide highlight after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _highlightType == 'before') {
        setState(() {
          _highlightedNumber = null;
          _highlightType = '';
        });
      }
    });

    if (_explorationsCount >= _requiredExplorations) {
      _checkCompletion();
    }
  }

  void _showAfter() {
    if (_selectedNumber == null) {
      _showSelectNumberMessage();
      return;
    }

    if (_selectedNumber == 20) {
      _showMessage('We stop at 20 in this exercise!', Colors.orange);
      return;
    }

    setState(() {
      _highlightedNumber = _selectedNumber! + 1;
      _highlightType = 'after';
      _explorationsCount++;
    });

    // Notify coordinator of progress
    widget.onProgressUpdate(_explorationsCount);

    _pulseController.forward(from: 0);

    // Auto-hide highlight after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _highlightType == 'after') {
        setState(() {
          _highlightedNumber = null;
          _highlightType = '';
        });
      }
    });

    if (_explorationsCount >= _requiredExplorations) {
      _checkCompletion();
    }
  }

  void _showSelectNumberMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('First, tap a number on the line!'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _checkCompletion() {
    if (_explorationsCount >= _requiredExplorations) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 32),
            SizedBox(width: 12),
            Expanded(child: Text('Ready for Level 2?')),
          ],
        ),
        content: const Text(
          'Great exploring! You\'ve learned about numbers that come BEFORE and AFTER!\n\n'
          'In Level 2, you\'ll practice WRITING the predecessor and successor.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _explorationsCount = 0;
              });
            },
            child: const Text('Practice more here'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Progress already reported via onProgressUpdate
            },
            child: const Text('Go to Level 2'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [

          // Number line
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildNumberLine(),
            ),
          ),
          const SizedBox(height: 24),

          // Control buttons
          if (_selectedNumber != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Before button
                ElevatedButton.icon(
                  onPressed: _showBefore,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Before'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 24),

                // After button
                ElevatedButton.icon(
                  onPressed: _showAfter,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('After'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Feedback message
          if (_highlightedNumber != null) ...[
            const SizedBox(height: 16),
            Card(
              color: _highlightType == 'before'
                  ? Colors.orange.shade50
                  : Colors.green.shade50,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _highlightType == 'before'
                          ? Icons.arrow_back
                          : Icons.arrow_forward,
                      color: _highlightType == 'before'
                          ? Colors.orange
                          : Colors.green,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _highlightType == 'before'
                          ? '$_highlightedNumber comes BEFORE $_selectedNumber'
                          : '$_highlightedNumber comes AFTER $_selectedNumber',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _highlightType == 'before'
                            ? Colors.orange.shade800
                            : Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNumberLine() {
    // Build number line in rows for better mobile display
    return Column(
      children: [
        // First row: 0-10
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List.generate(11, (index) => _buildNumberButton(index)),
        ),
        const SizedBox(height: 12),
        // Second row: 11-20
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List.generate(10, (index) => _buildNumberButton(index + 11)),
        ),
      ],
    );
  }

  Widget _buildNumberButton(int number) {
    final bool isSelected = _selectedNumber == number;
    final bool isHighlighted = _highlightedNumber == number;

    Color bgColor;
    Color textColor;

    if (isHighlighted) {
      bgColor = _highlightType == 'before' ? Colors.orange : Colors.green;
      textColor = Colors.white;
    } else if (isSelected) {
      bgColor = Colors.blue;
      textColor = Colors.white;
    } else {
      bgColor = Colors.grey.shade200;
      textColor = Colors.black87;
    }

    Widget button = GestureDetector(
      onTap: () => _selectNumber(number),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.blue.shade700
                : isHighlighted
                    ? (_highlightType == 'before'
                        ? Colors.orange.shade700
                        : Colors.green.shade700)
                    : Colors.grey.shade400,
            width: isSelected || isHighlighted ? 2 : 1,
          ),
          boxShadow: isSelected || isHighlighted
              ? [
                  BoxShadow(
                    color: bgColor.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: isSelected || isHighlighted ? 20 : 16,
              fontWeight:
                  isSelected || isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ),
      ),
    );

    // Animate highlighted number
    if (isHighlighted) {
      button = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: button,
      );
    }

    return button;
  }
}
