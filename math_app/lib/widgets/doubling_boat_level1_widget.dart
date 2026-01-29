import 'package:flutter/material.dart';
import 'common/rechenschiffchen_widget.dart';
import 'common/numeric_input_widget.dart';

enum LevelStep { filling, checkTens, checkOnes, checkTotal, finished }

class DoublingBoatLevel1Widget extends StatefulWidget {
  final int targetNumber; // Number in top row
  final Function(bool isCorrect) onResult; // Callback when solved

  const DoublingBoatLevel1Widget({
    super.key,
    required this.targetNumber,
    required this.onResult,
  });

  @override
  State<DoublingBoatLevel1Widget> createState() => _DoublingBoatLevel1WidgetState();
}

class _DoublingBoatLevel1WidgetState extends State<DoublingBoatLevel1Widget> {
  int _bottomCount = 0;
  LevelStep _step = LevelStep.filling;
  
  @override
  void didUpdateWidget(DoublingBoatLevel1Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetNumber != widget.targetNumber) {
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _bottomCount = 0;
      _step = LevelStep.filling;
    });
  }

  void _handleSlotTap(int row, int col, bool isActive) {
    if (_step != LevelStep.filling || row != 1) return;

    setState(() {
      // Allow adding at end or removing from end
      if (col == _bottomCount) {
        _bottomCount++;
      } else if (col == _bottomCount - 1) {
        _bottomCount--;
      }
    });

    if (_bottomCount == widget.targetNumber) {
      // If target > 5, move to structural analysis
      if (widget.targetNumber > 5) {
        setState(() => _step = LevelStep.checkTens);
      } else {
        // Simple case: just ask for total
        setState(() => _step = LevelStep.checkTotal);
      }
    }
  }

  void _checkInput(int input) {
    final target = widget.targetNumber;
    
    if (_step == LevelStep.checkTens) {
      if (input == 10) {
        setState(() => _step = LevelStep.checkOnes);
      } else {
         _showFeedback('Look at the red box. 5 top + 5 bottom = ?');
      }
    } else if (_step == LevelStep.checkOnes) {
      final remainder = (target - 5) * 2;
      if (input == remainder) {
        setState(() => _step = LevelStep.checkTotal);
      } else {
        _showFeedback('Look at the red box. $remainder counters.');
      }
    } else if (_step == LevelStep.checkTotal) {
      final total = target * 2;
      if (input == total) {
        setState(() => _step = LevelStep.finished);
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onResult(true);
        });
      } else {
        _showFeedback('Try again!');
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
      case LevelStep.filling:
        return 'Verdopple! Lege genauso viele blaue Plättchen.';
      case LevelStep.checkTens:
        return 'Wie viele Plättchen sind im roten Rahmen?';
      case LevelStep.checkOnes:
        return 'Wie viele Plättchen sind hier im roten Rahmen?';
      case LevelStep.checkTotal:
        return 'Wie viele Plättchen sind es insgesamt?';
      case LevelStep.finished:
        return 'Super!';
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
                bottomCount: _bottomCount,
                onSlotTap: _handleSlotTap,
                highlightTensBlock: _step == LevelStep.checkTens,
                highlightOnesBlock: _step == LevelStep.checkOnes,
              ),
            ),
          ),
        ),
        
        // Input Area
        if (_step != LevelStep.filling && _step != LevelStep.finished)
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
          const Spacer(flex: 2),
      ],
    );
  }
}
