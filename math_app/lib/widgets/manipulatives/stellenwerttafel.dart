import 'package:flutter/material.dart';

/// Stellenwerttafel with Z/E columns (B2.1-01, B2.1-02, DDB-04). When
/// [numberAbove] is set it is shown above the table; null column values
/// render as empty entry cells.
class StellenwerttafelWidget extends StatelessWidget {
  final int? tensValue;
  final int? onesValue;
  final String? numberAbove;

  const StellenwerttafelWidget({
    this.tensValue,
    this.onesValue,
    this.numberAbove,
  });

  @override
  Widget build(BuildContext context) {
    Widget columnCell(String text) {
      return Container(
        width: 64,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (numberAbove != null) ...[
            Text(
              numberAbove!,
              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              columnCell('Z'),
              const SizedBox(width: 4),
              columnCell('E'),
            ],
          ),
          Row(
            children: [
              columnCell(tensValue?.toString() ?? ''),
              const SizedBox(width: 4),
              columnCell(onesValue?.toString() ?? ''),
            ],
          ),
        ],
      ),
    );
  }
}
