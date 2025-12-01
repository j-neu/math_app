import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'common/finger_display_widget.dart';

class FingerBlitzLevel1Widget extends StatefulWidget {
  final Function(bool) onProblemSolved;
  final bool isFlashMode;

  const FingerBlitzLevel1Widget({
    super.key,
    required this.onProblemSolved,
    required this.isFlashMode,
  });

  @override
  State<FingerBlitzLevel1Widget> createState() => _FingerBlitzLevel1WidgetState();
}

class _FingerBlitzLevel1WidgetState extends State<FingerBlitzLevel1Widget> {
  final Random _random = Random();
  int _targetNumber = 0;
  Set<int> _activeFingers = {};
  bool _isVisible = true;
  String? _feedbackMessage;
  bool _isSuccess = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _generateProblem();
  }

  void _generateProblem() {
    setState(() {
      _targetNumber = _random.nextInt(10) + 1; // 1-10
      _activeFingers = _generateFingerPattern(_targetNumber);
      _isVisible = true;
      _feedbackMessage = null;
      _isSuccess = false;
      _isError = false;
    });

    if (widget.isFlashMode) {
      Timer(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() {
            _isVisible = false;
          });
        }
      });
    }
  }

  Set<int> _generateFingerPattern(int number) {
    // Standard "Kraft der 5" pattern
    // L-Hand: 0,1,2,3,4 (Thumb->Pinky or Pinky->Thumb depending on visual mapping)
    // Our widget visual order:
    // L-Hand (Visual Left to Right): Pinky(4), Ring(3), Middle(2), Index(1), Thumb(0)
    // R-Hand (Visual Left to Right): Thumb(5), Index(6), Middle(7), Ring(8), Pinky(9)
    
    // Standard counting: Fill L-Hand first, then R-Hand.
    // Usually Thumb first. 
    // L-Thumb=0, L-Index=1... L-Pinky=4.
    // R-Thumb=5... R-Pinky=9.
    
    Set<int> fingers = {};
    for (int i = 0; i < number; i++) {
      fingers.add(i);
    }
    return fingers;
  }

  void _checkAnswer(int answer) {
    if (_isSuccess) return;

    if (answer == _targetNumber) {
      setState(() {
        _isSuccess = true;
        _isVisible = true; // Reveal if hidden
        _feedbackMessage = 'Correct!';
      });
      widget.onProblemSolved(true);
      
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _generateProblem();
      });
    } else {
      setState(() {
        _isError = true;
        _isVisible = true; // Show for learning
        _feedbackMessage = 'Look again!';
      });
      
      widget.onProblemSolved(false); // Record error but let them retry or move on? 
      // Coordinator advances on 10 problems. Usually "onProblemSolved" advances index.
      // If we call onProblemSolved(false), it counts as a problem done (incorrectly).
      // For this app, usually we want them to get it right?
      // But "onProblemSolved" usually advances problem index.
      // I'll just delay and generate new problem if error? 
      // Or let them retry? 
      // App standard: "No fail". Switch representation?
      // For now: Show correct, wait, next problem.
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _generateProblem();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Feedback / Instruction
        Container(
          height: 60,
          alignment: Alignment.center,
          child: Text(
            _feedbackMessage ?? (widget.isFlashMode ? 'Watch closely...' : 'How many fingers?'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isSuccess ? Colors.green : (_isError ? Colors.orange : Colors.black),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Finger Display
        AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: FingerDisplayWidget(
            activeFingers: _activeFingers,
            height: 180,
          ),
        ),

        const SizedBox(height: 40),

        // Number Pad
        if (!_isSuccess && !_isError) ...[
             if (widget.isFlashMode && _isVisible)
               // Don't show pad while flashing? Or allow immediate answer?
               // Card says "Blitz". Usually hide first?
               // But fast kids might type immediately.
               const SizedBox(height: 200, child: Center(child: Text('Wait...', style: TextStyle(fontSize: 20, color: Colors.grey))))
             else
               _buildNumberPad()
        ] else ...[
             const SizedBox(height: 200), // Placeholder to keep layout stable
        ],
      ],
    );
  }

  Widget _buildNumberPad() {
    return Center(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: List.generate(10, (index) {
          final number = index + 1;
          return ElevatedButton(
            onPressed: () => _checkAnswer(number),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(20),
              shape: const CircleBorder(),
              minimumSize: const Size(70, 70),
            ),
            child: Text(
              '$number',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          );
        }),
      ),
    );
  }
}
