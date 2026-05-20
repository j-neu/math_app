import 'package:flutter/material.dart';
import '../widgets/common/finger_display_widget.dart';

class DoublingFingers20Level1Widget extends StatefulWidget {
  final int targetNumber;
  final Function(bool) onComplete;

  const DoublingFingers20Level1Widget({
    Key? key,
    required this.targetNumber,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<DoublingFingers20Level1Widget> createState() => _DoublingFingers20Level1WidgetState();
}

class _DoublingFingers20Level1WidgetState extends State<DoublingFingers20Level1Widget> {
  int _userLeftCount = 0;
  int _userRightCount = 0;
  bool _isChecking = false;
  bool _showSuccess = false;

  @override
  void didUpdateWidget(DoublingFingers20Level1Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetNumber != widget.targetNumber) {
      setState(() {
        _userLeftCount = 0;
        _userRightCount = 0;
        _isChecking = false;
        _showSuccess = false;
      });
    }
  }

  void _checkAnswer() async {
    if (_isChecking) return;
    
    // Calculate expected split for target
    // We expect the user to fill hands logically: 5 then remainder
    int expectedLeft = widget.targetNumber >= 5 ? 5 : widget.targetNumber;
    int expectedRight = widget.targetNumber > 5 ? widget.targetNumber - 5 : 0;
    
    // Check if total matches (allow flexibility e.g. 3+3 for 6, though 5+1 is preferred)
    // Actually, for consistency with "Kraft der 5" (Power of 5), we usually enforce 5+N structure.
    // But let's be flexible on total count for now, or strict on copying?
    // "Make your hands look like the teacher's hands" implies strict copying.
    bool isCorrect = _userLeftCount == expectedLeft && _userRightCount == expectedRight;
    
    // If strict copying fails, maybe check total?
    // No, instruction is "copy".

    setState(() {
      _isChecking = true;
    });

    if (isCorrect) {
      setState(() {
        _showSuccess = true;
      });
      await Future.delayed(Duration(seconds: 1));
    } else {
      await Future.delayed(Duration(milliseconds: 500));
    }
    
    widget.onComplete(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate teacher's finger split
    int teacherLeft = widget.targetNumber >= 5 ? 5 : widget.targetNumber;
    int teacherRight = widget.targetNumber > 5 ? widget.targetNumber - 5 : 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Verdopple ${widget.targetNumber}!',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          'Kopiere die Hände der Lehrerin.',
          style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
        ),
        SizedBox(height: 20),
        
        // Teacher's Hands (Static)
        Text('Lehrerin', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        FingerDisplayWidget(
          leftCount: teacherLeft,
          rightCount: teacherRight,
          height: 120, // Smaller than main interaction
          interactionType: FingerInteractionType.direct, // Actually disable interaction
          onCountChanged: null, // Disable interaction
        ),
        
        SizedBox(height: 30),
        
        // Student's Hands (Interactive)
        Text('Du', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        FingerDisplayWidget(
          leftCount: _userLeftCount,
          rightCount: _userRightCount,
          height: 150,
          interactionType: FingerInteractionType.increment,
          onCountChanged: (isLeft, count) {
            if (!_isChecking) {
              setState(() {
                if (isLeft) {
                  _userLeftCount = count;
                } else {
                  _userRightCount = count;
                }
              });
            }
          },
        ),

        SizedBox(height: 30),
        
        if (_showSuccess)
          Text(
            '${widget.targetNumber} + ${widget.targetNumber} = ${widget.targetNumber * 2}',
            style: TextStyle(fontSize: 40, color: Colors.green, fontWeight: FontWeight.bold),
          ),
          
        if (!_showSuccess)
          ElevatedButton(
            onPressed: (_userLeftCount > 0 || _userRightCount > 0) ? _checkAnswer : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              textStyle: TextStyle(fontSize: 24),
            ),
            child: Text('Prüfen'),
          ),
      ],
    );
  }
}
