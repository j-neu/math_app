import 'package:flutter/material.dart';
import '../widgets/common/numeric_input_widget.dart';
import '../widgets/common/finger_display_widget.dart';

class DoublingFingers20Level2Widget extends StatelessWidget {
  final int targetNumber;
  final Function(bool) onComplete;

  const DoublingFingers20Level2Widget({
    Key? key,
    required this.targetNumber,
    required this.onComplete,
  }) : super(key: key);

  void _onNumberSubmitted(int number) {
    bool isCorrect = number == (targetNumber * 2);
    onComplete(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    int leftCount = targetNumber >= 5 ? 5 : targetNumber;
    int rightCount = targetNumber > 5 ? targetNumber - 5 : 0;

    return Column(
      children: [
        SizedBox(height: 20),
        Text(
          'Verdopple ${targetNumber}!',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          'Stell dir vor, deine Hände zeigen dasselbe.',
          style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Visible Target Hands
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Lehrerin', style: TextStyle(color: Colors.grey)),
                    FingerDisplayWidget(
                      leftCount: leftCount,
                      rightCount: rightCount,
                      height: 120,
                      onCountChanged: null,
                    ),
                  ],
                ),
                
                SizedBox(height: 20),
                Text('+', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                
                // Hidden/Imagined Hands
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Du', style: TextStyle(color: Colors.grey)),
                    Container(
                      height: 120,
                      width: 300, // Match width of FingerDisplayWidget (120 * 2.5)
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                      child: Center(
                        child: Icon(Icons.psychology, size: 60, color: Colors.grey.shade400),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Input for answer (up to 20)
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: NumericInputWidget(
            onSubmit: _onNumberSubmitted,
          ),
        ),
      ],
    );
  }
}
