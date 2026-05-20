import 'package:flutter/material.dart';
import 'common/rechenschiffchen_widget.dart';
import 'common/numeric_input_widget.dart';

enum LevelStep { checkTens, checkOnes, checkTotal, finished }

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
  LevelStep _step = LevelStep.checkTotal;
  bool _reveal = false;

  @override
  void initState() {
    super.initState();
    _initStep();
  }

  @override
  void didUpdateWidget(DoublingBoatLevel2Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetNumber != widget.targetNumber) {
      _initStep();
    }
  }

  void _initStep() {
    setState(() {
      _reveal = false;
      if (widget.targetNumber > 5) {
        _step = LevelStep.checkTens;
      } else {
        _step = LevelStep.checkTotal;
      }
    });
  }

  void _checkInput(int input) {
    final target = widget.targetNumber;
    
    if (_step == LevelStep.checkTens) {
      if (input == 10) {
        setState(() => _step = LevelStep.checkOnes);
      } else {
         _showFeedback('Verdopple die Fünfen. 5 + 5 = ?');
      }
    } else if (_step == LevelStep.checkOnes) {
      final remainder = (target - 5) * 2;
      if (input == remainder) {
        setState(() => _step = LevelStep.checkTotal);
      } else {
        _showFeedback('Verdopple den Rest. ${target-5} + ${target-5} = ?');
      }
    } else if (_step == LevelStep.checkTotal) {
      final total = target * 2;
      if (input == total) {
        setState(() {
          _step = LevelStep.finished;
          _reveal = true;
        });
        Future.delayed(const Duration(milliseconds: 1500), () {
          widget.onResult(true);
        });
      } else {
        _showFeedback('Versuche es nochmal!');
      }
    }
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1), backgroundColor: Colors.orange),
    );
  }

  String _getInstruction() {
    switch (_step) {
      case LevelStep.checkTens:
        return 'Stell dir die blauen Plättchen vor. Wie viele im roten Rahmen?';
      case LevelStep.checkOnes:
        return 'Und wie viele hier im roten Rahmen?';
      case LevelStep.checkTotal:
        return 'Wie viele sind es zusammen?';
      case LevelStep.finished:
        return 'Richtig!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _getInstruction(),
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
                topCount: widget.targetNumber,
                bottomCount: _reveal ? widget.targetNumber : 0,
                coverBottom: !_reveal,
                coverAll: false,
                highlightTensBlock: _step == LevelStep.checkTens,
                highlightOnesBlock: _step == LevelStep.checkOnes,
              ),
            ),
          ),
        ),
        
        // Input Area
        if (_step != LevelStep.finished)
          Expanded(
            flex: 2,
            child: Center(
              child: NumericInputWidget(
                onSubmit: _checkInput,
                hintText: '?',
              ),
            ),
          )
        else
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                '${widget.targetNumber * 2}',
                style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
          ),
      ],
    );
  }
}