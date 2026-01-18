import 'package:flutter/material.dart';

class Numpad extends StatelessWidget {
  final Function(int) onNumberSelected;

  const Numpad({super.key, required this.onNumberSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: List.generate(10, (index) {
        final number = index + 1;
        return ElevatedButton(
          onPressed: () => onNumberSelected(number),
          style: ElevatedButton.styleFrom(
            fixedSize: Size(80, 80),
            shape: CircleBorder(),
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).primaryColor,
            elevation: 4,
            side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), width: 1),
          ),
          child: Text(
            '$number',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        );
      }),
    );
  }
}
