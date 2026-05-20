import 'package:flutter/material.dart';
import '../widgets/common/numeric_input_widget.dart';

class DoublingFingers20Level3Widget extends StatelessWidget {
  final int targetNumber;
  final Function(bool) onComplete;

  const DoublingFingers20Level3Widget({
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Spacer(),
        Text(
          'Verdopple!',
          style: TextStyle(fontSize: 24, color: Colors.grey.shade600),
        ),
        SizedBox(height: 40),
        
        // Abstract representation: Equation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumberBox(targetNumber),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('+', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            ),
            _buildNumberBox(targetNumber),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('=', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).primaryColor, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                '?',
                style: TextStyle(fontSize: 48, color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        ),
        
        Spacer(),
        
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: NumericInputWidget(onSubmit: _onNumberSubmitted),
        ),
      ],
    );
  }

  Widget _buildNumberBox(int number) {
    return Container(
      width: 100,
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '$number',
        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
      ),
    );
  }
}
