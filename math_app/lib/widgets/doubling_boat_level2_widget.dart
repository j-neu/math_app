import 'package:flutter/material.dart';
import 'common/rechenschiffchen_widget.dart';
import 'common/numpad_widget.dart';

class DoublingBoatLevel2Widget extends StatefulWidget {
  final int targetNumber; // Number in top row
  final Function(bool isCorrect) onResult;

  const DoublingBoatLevel2Widget({
    super.key,
    required this.targetNumber,
    required this.onResult,
  });

  @override
  State<DoublingBoatLevel2Widget> createState() => _DoublingBoatLevel2WidgetState();
}

class _DoublingBoatLevel2WidgetState extends State<DoublingBoatLevel2Widget> {
  bool _isComplete = false;
  bool _reveal = false; // Reveal answer after correct input
  String _inputText = "";

  void _checkAnswer(int answer) {
    if (_isComplete) return;

    final expected = widget.targetNumber * 2;
    if (answer == expected) {
      setState(() {
        _isComplete = true;
        _reveal = true;
        _inputText = "$answer";
      });
      
      // Delay to show the revealed boat
      Future.delayed(const Duration(milliseconds: 1500), () {
        widget.onResult(true);
      });
    } else {
      // Shake or feedback?
      setState(() {
        _inputText = "$answer"; 
        // Maybe clearer to clear it after a moment or show incorrect
      });
      Future.delayed(const Duration(milliseconds: 500), () {
         setState(() => _inputText = "");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Instruction
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Stell dir die blauen Plättchen vor. Wie viele sind es zusammen?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),

        Expanded(
          flex: 2,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: RechenschiffchenWidget(
                topCount: widget.targetNumber,
                bottomCount: _reveal ? widget.targetNumber : 0, // Show if revealed
                coverBottom: !_reveal, // Cover if not revealed
                coverAll: false,
              ),
            ),
          ),
        ),
        
        // Input Display
        Text(
          _inputText.isEmpty ? "?" : _inputText,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: _isComplete ? Colors.green : Colors.black,
          ),
        ),
        
        Expanded(
          flex: 3,
          child: Numpad(onNumberSelected: _checkAnswer),
        ),
      ],
    );
  }
}