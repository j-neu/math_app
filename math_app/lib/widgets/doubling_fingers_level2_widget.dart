import 'package:flutter/material.dart';
import '../widgets/common/numpad_widget.dart';

class DoublingFingersLevel2Widget extends StatefulWidget {
  final int targetNumber;
  final Function(bool) onComplete;

  const DoublingFingersLevel2Widget({
    Key? key,
    required this.targetNumber,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<DoublingFingersLevel2Widget> createState() => _DoublingFingersLevel2WidgetState();
}

class _DoublingFingersLevel2WidgetState extends State<DoublingFingersLevel2Widget> {
  // We use a custom display where right hand is hidden by a box "?"
  
  void _onNumberSelected(int number) {
    bool isCorrect = number == (widget.targetNumber * 2);
    widget.onComplete(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20),
        Text(
          'Verdopple ${widget.targetNumber}!',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          'Stell dir die andere Hand vor.',
          style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
        ),
        
        Expanded(
          child: Center(
            child: SizedBox(
              height: 200, // Match FingerDisplayWidget height
              width: 500,  // Match approx width
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Visible Left Hand
                  Expanded(
                    child: Transform.flip(
                      flipX: true,
                      child: Image.asset(
                        'assets/images/fingers/${widget.targetNumber}_finger_right.png',
                        height: 200,
                        fit: BoxFit.contain,
                         errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: Colors.grey.shade200, 
                          child: Center(child: Text('${widget.targetNumber}', style: TextStyle(fontSize: 40))),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 20), // Gap
                  
                  // Hidden Right Hand (Box with ?)
                  Expanded(
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade400, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '?',
                          style: TextStyle(fontSize: 60, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Numpad for input (1-10)
        Padding(
          padding: const EdgeInsets.only(bottom: 40.0),
          child: Numpad(
            onNumberSelected: _onNumberSelected,
          ),
        ),
      ],
    );
  }
}