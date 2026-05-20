import 'package:flutter/material.dart';
import '../widgets/common/finger_display_widget.dart';

class DoublingFingersLevel1Widget extends StatefulWidget {
  final int targetNumber;
  final Function(bool) onComplete;

  const DoublingFingersLevel1Widget({
    Key? key,
    required this.targetNumber,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<DoublingFingersLevel1Widget> createState() => _DoublingFingersLevel1WidgetState();
}

class _DoublingFingersLevel1WidgetState extends State<DoublingFingersLevel1Widget> {
  int _currentRightHand = 0;
  bool _isChecking = false;
  bool _showSuccess = false;

  @override
  void didUpdateWidget(DoublingFingersLevel1Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetNumber != widget.targetNumber) {
      setState(() {
        _currentRightHand = 0;
        _isChecking = false;
        _showSuccess = false;
      });
    }
  }

  void _checkAnswer() async {
    if (_isChecking) return;
    setState(() {
      _isChecking = true;
    });

    bool isCorrect = _currentRightHand == widget.targetNumber;

    if (isCorrect) {
      setState(() {
        _showSuccess = true;
      });
      await Future.delayed(Duration(seconds: 1)); // Show success state briefly
    } else {
      // Feedback for incorrect answer could be added here (shake, message)
      await Future.delayed(Duration(milliseconds: 500));
    }
    
    widget.onComplete(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Verdopple ${widget.targetNumber}!',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Text(
          'Die rechte Hand soll die linke Hand kopieren.',
          style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
        ),
        SizedBox(height: 40),
        
        // Finger Display
        // Left hand is fixed target. Right hand is interactive.
        FingerDisplayWidget(
          leftCount: widget.targetNumber,
          rightCount: _currentRightHand,
          height: 180,
          interactionType: FingerInteractionType.increment, // Cycle fingers 0-5
          onCountChanged: (isLeft, count) {
            if (!isLeft && !_isChecking) {
              setState(() {
                _currentRightHand = count;
              });
            }
          },
        ),

        SizedBox(height: 40),
        
        if (_showSuccess)
          Text(
            '${widget.targetNumber} + ${widget.targetNumber} = ${widget.targetNumber * 2}',
            style: TextStyle(fontSize: 40, color: Colors.green, fontWeight: FontWeight.bold),
          ),
          
        if (!_showSuccess)
          ElevatedButton(
            onPressed: _currentRightHand > 0 ? _checkAnswer : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              textStyle: TextStyle(fontSize: 24),
            ),
            child: Text('Prüfen'),
          ),
      ],
    );
  }
}
