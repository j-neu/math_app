import 'package:flutter/material.dart';
import 'common/rechenschiffchen_widget.dart';
import 'common/numpad_widget.dart';

class DoublingBoatLevel3Widget extends StatefulWidget {
  final int targetNumber; // Number in top row (implied)
  final Function(bool isCorrect) onResult;

  const DoublingBoatLevel3Widget({
    super.key,
    required this.targetNumber,
    required this.onResult,
  });

  @override
  State<DoublingBoatLevel3Widget> createState() => _DoublingBoatLevel3WidgetState();
}

class _DoublingBoatLevel3WidgetState extends State<DoublingBoatLevel3Widget> {
  bool _isComplete = false;
  bool _reveal = false;
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
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        widget.onResult(true);
      });
    } else {
      setState(() {
        _inputText = "$answer"; 
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Stell dir ${widget.targetNumber} rote Plättchen vor. Verdopple sie! Wie viele sind es?',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),

        Expanded(
          flex: 2,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: RechenschiffchenWidget(
                topCount: _reveal ? widget.targetNumber : 0,
                bottomCount: _reveal ? widget.targetNumber : 0,
                coverAll: !_reveal, // Cover all until solved
              ),
            ),
          ),
        ),
        
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