import 'package:flutter/material.dart';
import '../common/finger_display_widget.dart';

class FingerCalcLevel1Widget extends StatefulWidget {
  final int initialLeft;
  final int initialRight;
  final int subtractAmount;
  final Function(bool) onComplete;

  const FingerCalcLevel1Widget({
    Key? key,
    required this.initialLeft,
    required this.initialRight,
    required this.subtractAmount,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<FingerCalcLevel1Widget> createState() => _FingerCalcLevel1WidgetState();
}

class _FingerCalcLevel1WidgetState extends State<FingerCalcLevel1Widget> {
  late int _currentLeft;
  late int _currentRight;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _currentLeft = widget.initialLeft;
    _currentRight = widget.initialRight;
  }

  // Check if reset is needed when problem changes
  @override
  void didUpdateWidget(FingerCalcLevel1Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLeft != widget.initialLeft || 
        oldWidget.initialRight != widget.initialRight ||
        oldWidget.subtractAmount != widget.subtractAmount) {
      _currentLeft = widget.initialLeft;
      _currentRight = widget.initialRight;
      _submitted = false;
    }
  }

  void _handleCountChanged(bool isLeft, int count) {
    if (_submitted) return;
    setState(() {
      if (isLeft) _currentLeft = count;
      else _currentRight = count;
    });
  }

  void _checkAnswer() {
    if (_submitted) return;
    
    final startTotal = widget.initialLeft + widget.initialRight;
    final targetTotal = startTotal - widget.subtractAmount;
    final currentTotal = _currentLeft + _currentRight;
    
    // We check if the total remaining fingers match the target
    final isCorrect = currentTotal == targetTotal;
    
    setState(() {
      _submitted = true;
    });

    // Provide feedback then move on
    Future.delayed(Duration(milliseconds: 1000), () {
      widget.onComplete(isCorrect);
    });
  }

  @override
  Widget build(BuildContext context) {
    final startTotal = widget.initialLeft + widget.initialRight;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Instruction / Task
        Text(
          "Du hast $startTotal Finger.",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            "Nimm ${widget.subtractAmount} weg!",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepOrange),
          ),
        ),
        
        Spacer(),
        
        // Interactive Fingers
        FingerDisplayWidget(
          leftCount: _currentLeft,
          rightCount: _currentRight,
          height: 180,
          interactionType: FingerInteractionType.decrement,
          onCountChanged: _handleCountChanged,
        ),
        
        Spacer(),
        
        // Submit Button
        ElevatedButton(
          onPressed: _submitted ? null : _checkAnswer,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            "Fertig",
            style: TextStyle(fontSize: 24),
          ),
        ),
        SizedBox(height: 32),
      ],
    );
  }
}
