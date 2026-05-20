import 'package:flutter/material.dart';
import 'common/rechenschiffchen_widget.dart';
import 'common/numeric_input_widget.dart';

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
  String _resultText = "";

  void _checkAnswer(int answer) {
    if (_isComplete) return;

    final expected = widget.targetNumber * 2;
    if (answer == expected) {
      setState(() {
        _isComplete = true;
        _reveal = true;
        _resultText = "$answer";
      });
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        widget.onResult(true);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fast! Versuche das Verdoppeln nochmal.'),
          duration: Duration(milliseconds: 1000),
          backgroundColor: Colors.orange,
        ),
      );
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
        
        Expanded(
          flex: 3,
          child: Center(
            child: _isComplete
                ? Text(
                    _resultText,
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  )
                : NumericInputWidget(
                    onSubmit: _checkAnswer,
                    hintText: '?',
                  ),
          ),
        ),
      ],
    );
  }
}