import 'package:flutter/material.dart';
import '../common/finger_display_widget.dart';

class FingerCalcLevel3Widget extends StatefulWidget {
  final int initialLeft;
  final int initialRight;
  final int subtractAmount;
  final Function(bool) onComplete;

  const FingerCalcLevel3Widget({
    Key? key,
    required this.initialLeft,
    required this.initialRight,
    required this.subtractAmount,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<FingerCalcLevel3Widget> createState() => _FingerCalcLevel3WidgetState();
}

class _FingerCalcLevel3WidgetState extends State<FingerCalcLevel3Widget> {
  final TextEditingController _controller = TextEditingController();
  bool _submitted = false;
  bool _showHelp = false;
  String? _feedbackMessage;
  Color? _feedbackColor;
  
  // Local state for helper fingers
  late int _currentLeft;
  late int _currentRight;

  @override
  void initState() {
    super.initState();
    _resetState();
  }

  @override
  void didUpdateWidget(FingerCalcLevel3Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLeft != widget.initialLeft || 
        oldWidget.initialRight != widget.initialRight ||
        oldWidget.subtractAmount != widget.subtractAmount) {
      _resetState();
    }
  }

  void _resetState() {
    _controller.clear();
    _submitted = false;
    _showHelp = false;
    _feedbackMessage = null;
    _feedbackColor = null;
    _currentLeft = widget.initialLeft;
    _currentRight = widget.initialRight;
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
    if (input == null) return;
    
    final startTotal = widget.initialLeft + widget.initialRight;
    final correctAnswer = startTotal - widget.subtractAmount;
    final isCorrect = input == correctAnswer;
    
    setState(() {
      _submitted = true;
      if (isCorrect) {
        _feedbackMessage = "Fantastisch!";
        _feedbackColor = Colors.green;
      } else {
        _feedbackMessage = "Die richtige Antwort ist $correctAnswer.";
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
          SizedBox(height: 48),
          
          Text(
            "Rechne im Kopf:",
            style: TextStyle(fontSize: 20, color: Colors.grey.shade700),
          ),
          SizedBox(height: 16),

          // Equation
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
          
          if (_feedbackMessage != null)
            Text(
              _feedbackMessage!,
              style: TextStyle(fontSize: 24, color: _feedbackColor, fontWeight: FontWeight.bold),
            ),
            
          SizedBox(height: 48),

          // Help Section
          if (!_showHelp && !_submitted)
            TextButton.icon(
              onPressed: () => setState(() => _showHelp = true),
              icon: Icon(Icons.help_outline),
              label: Text("Ich brauche Hilfe (Finger zeigen)"),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )
          else if (_showHelp) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Text("Nutze die Finger:", style: TextStyle(color: Colors.grey.shade700)),
                  SizedBox(height: 8),
                  FingerDisplayWidget(
                    leftCount: _currentLeft,
                    rightCount: _currentRight,
                    height: 120,
                    interactionType: FingerInteractionType.decrement,
                    onCountChanged: _handleCountChanged,
                  ),
                ],
              ),
            ),
          ],
          
          SizedBox(height: 48),
          
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
