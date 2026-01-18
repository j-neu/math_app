import 'package:flutter/material.dart';
import 'dart:math';
import 'common/finger_display_widget.dart';

enum FingerConstructionMode {
  additive,    // Start 0, add to N
  subtractive, // Start 10, subtract to N
}

class FingerBlitzLevel3Widget extends StatefulWidget {
  final Function(bool) onProblemSolved;
  final FingerConstructionMode mode;

  const FingerBlitzLevel3Widget({
    super.key,
    required this.onProblemSolved,
    required this.mode,
  });

  @override
  State<FingerBlitzLevel3Widget> createState() => _FingerBlitzLevel3WidgetState();
}

class _FingerBlitzLevel3WidgetState extends State<FingerBlitzLevel3Widget> {
  final Random _random = Random();
  int _targetNumber = 0;
  int _leftCount = 0;
  int _rightCount = 0;
  String? _feedbackMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _generateProblem();
  }

  void _generateProblem() {
    setState(() {
      _targetNumber = _random.nextInt(10) + 1; // 1-10
      
      if (widget.mode == FingerConstructionMode.subtractive) {
        // Start with 10 fingers up
        _leftCount = 5;
        _rightCount = 5;
      } else {
        // Start with 0 fingers up
        _leftCount = 0;
        _rightCount = 0;
      }
      
      _feedbackMessage = null;
      _isSuccess = false;
    });
  }

  void _handleCountChanged(bool isLeft, int count) {
    if (_isSuccess) return;

    setState(() {
      if (isLeft) {
        _leftCount = count;
      } else {
        _rightCount = count;
      }
    });
  }

  void _checkAnswer() {
    int currentCount = _leftCount + _rightCount;
    
    if (currentCount == _targetNumber) {
      setState(() {
        _isSuccess = true;
        if (widget.mode == FingerConstructionMode.subtractive) {
           int diff = 10 - _targetNumber;
           _feedbackMessage = 'Correct! 10 - $diff = $_targetNumber';
        } else {
           _feedbackMessage = 'Correct!';
        }
      });
      
      widget.onProblemSolved(true);
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _generateProblem();
      });
    } else {
      setState(() {
        _feedbackMessage = 'You have $currentCount fingers. Need $_targetNumber.';
      });
      // No penalty, just feedback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Instruction
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                widget.mode == FingerConstructionMode.subtractive
                    ? 'Start with 10. Make $_targetNumber by hiding fingers.'
                    : 'Show me $_targetNumber fingers.',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (_feedbackMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _feedbackMessage!,
                    style: TextStyle(
                      fontSize: 18,
                      color: _isSuccess ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Finger Display (Interactive)
        FingerDisplayWidget(
          leftCount: _leftCount,
          rightCount: _rightCount,
          height: 220,
          onCountChanged: _handleCountChanged,
          interactionType: widget.mode == FingerConstructionMode.additive
              ? FingerInteractionType.increment
              : FingerInteractionType.decrement,
        ),

        const SizedBox(height: 40),
        
        // Hint / Control
        if (!_isSuccess)
          ElevatedButton(
            onPressed: _checkAnswer,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: const Text('Check', style: TextStyle(fontSize: 20)),
          ),
      ],
    );
  }
}