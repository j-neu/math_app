import 'package:flutter/material.dart';
import '../common/finger_display_widget.dart';

class FingerCalcLevel2Widget extends StatefulWidget {
  final int initialLeft;
  final int initialRight;
  final int subtractAmount;
  final Function(bool) onComplete;

  const FingerCalcLevel2Widget({
    Key? key,
    required this.initialLeft,
    required this.initialRight,
    required this.subtractAmount,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<FingerCalcLevel2Widget> createState() => _FingerCalcLevel2WidgetState();
}

class _FingerCalcLevel2WidgetState extends State<FingerCalcLevel2Widget> {
  late int _currentLeft;
  late int _currentRight;
  final TextEditingController _controller = TextEditingController();
  bool _submitted = false;
  String? _feedbackMessage;
  Color? _feedbackColor;

  @override
  void initState() {
    super.initState();
    _resetState();
  }

  @override
  void didUpdateWidget(FingerCalcLevel2Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLeft != widget.initialLeft || 
        oldWidget.initialRight != widget.initialRight ||
        oldWidget.subtractAmount != widget.subtractAmount) {
      _resetState();
    }
  }

  void _resetState() {
    _currentLeft = widget.initialLeft;
    _currentRight = widget.initialRight;
    _controller.clear();
    _submitted = false;
    _feedbackMessage = null;
    _feedbackColor = null;
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
    
    final input = int.tryParse(_controller.text.trim());
    if (input == null) return; // Ignore empty input
    
    final startTotal = widget.initialLeft + widget.initialRight;
    final correctAnswer = startTotal - widget.subtractAmount;
    final isCorrect = input == correctAnswer;
    
    setState(() {
      _submitted = true;
      if (isCorrect) {
        _feedbackMessage = "Richtig!";
        _feedbackColor = Colors.green;
      } else {
        _feedbackMessage = "Fast! Die richtige Antwort ist $correctAnswer.";
        _feedbackColor = Colors.orange;
      }
    });

    Future.delayed(Duration(milliseconds: 1500), () {
      widget.onComplete(isCorrect);
    });
  }

  @override
  Widget build(BuildContext context) {
    final startTotal = widget.initialLeft + widget.initialRight;
    
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 24),
          
          // Equation Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$startTotal - ${widget.subtractAmount} = ",
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  enabled: !_submitted,
                  onSubmitted: (_) => _checkAnswer(),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 32),
          
          // Feedback
          if (_feedbackMessage != null)
            Text(
              _feedbackMessage!,
              style: TextStyle(
                fontSize: 24, 
                color: _feedbackColor, 
                fontWeight: FontWeight.bold
              ),
            ),
            
          SizedBox(height: 32),
          
          // Interactive Fingers (Helper)
          Text(
            "Benutze die Finger als Hilfe:",
            style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
          ),
          SizedBox(height: 8),
          FingerDisplayWidget(
            leftCount: _currentLeft,
            rightCount: _currentRight,
            height: 150,
            interactionType: FingerInteractionType.decrement,
            onCountChanged: _handleCountChanged,
          ),
          
          SizedBox(height: 32),
          
          // Check Button
          ElevatedButton(
            onPressed: _submitted ? null : _checkAnswer,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              "Prüfen",
              style: TextStyle(fontSize: 24),
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}
