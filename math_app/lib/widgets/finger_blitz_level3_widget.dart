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
  Set<int> _activeFingers = {};
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
        _activeFingers = {0,1,2,3,4,5,6,7,8,9};
      } else {
        // Start with 0 fingers up
        _activeFingers = {};
      }
      
      _feedbackMessage = null;
      _isSuccess = false;
    });
  }

  void _handleFingerTap(int fingerIndex) {
    if (_isSuccess) return;

    setState(() {
      if (_activeFingers.contains(fingerIndex)) {
        _activeFingers.remove(fingerIndex);
      } else {
        _activeFingers.add(fingerIndex);
      }
    });
  }

  void _handleHandTap(bool isLeft) {
    if (_isSuccess) return;

    // Convenience: Toggle whole hand
    // Left: 0-4, Right: 5-9
    final indices = isLeft ? [0,1,2,3,4] : [5,6,7,8,9];
    bool allActive = indices.every((i) => _activeFingers.contains(i));
    
    setState(() {
      if (allActive) {
        _activeFingers.removeAll(indices);
      } else {
        _activeFingers.addAll(indices);
      }
    });
  }

  void _checkAnswer() {
    int currentCount = _activeFingers.length;
    
    if (currentCount == _targetNumber) {
      // Check pattern validity?
      // For MVP, any N fingers is okay, but pedagogical goal is 5+N.
      // Let's check if it respects "Kraft der 5" (one full hand if > 5).
      // Not strictly enforced by "count", but we can give hint.
      
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
          activeFingers: _activeFingers,
          height: 220,
          activeColor: widget.mode == FingerConstructionMode.subtractive 
              ? const Color(0xFFE0AC69) // Normal skin
              : const Color(0xFFE0AC69), 
          // Maybe use different color for subtractive hints? 
          // For now, standard.
          onFingerTap: _handleFingerTap, // Individual control
          onHandTap: _handleHandTap,     // Hand block control
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
