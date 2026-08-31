import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../manipulatives/stellenwerttafel.dart';
import 'answer_pad.dart';

/// Ikonisch template widget for `stellenwerttafel_read` (P2 plan §5 rule 8).
///
/// Mode `read`: renders a [StellenwerttafelWidget] with `display.tens` /
/// `display.ones` counters and the child types the composed number.
///
/// Mode `sum_rows`: renders two rows of Z/E column counters
/// (`display.row1` / `display.row2`) joined by `display.op` (column-wise
/// addition or subtraction) and the child types the result.
///
/// [onValueChanged] reports the typed value, `""` while the field is empty.
class StellenwerttafelReadWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const StellenwerttafelReadWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<StellenwerttafelReadWidget> createState() =>
      _StellenwerttafelReadWidgetState();
}

class _StellenwerttafelReadWidgetState extends State<StellenwerttafelReadWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void didUpdateWidget(covariant StellenwerttafelReadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _columnCell(String text) {
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

  Widget _columnRow(List<int>? row) {
    final tens = row != null && row.isNotEmpty ? '${row[0]}' : '';
    final ones = row != null && row.length > 1 ? '${row[1]}' : '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _columnCell(tens),
        const SizedBox(width: 4),
        _columnCell(ones),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.problem.display;
    final mode = (d['mode'] as String?) ?? 'read';

    final Widget picture;
    if (mode == 'sum_rows') {
      final op = (d['op'] as String?) ?? '+';
      final row1 = (d['row1'] as List?)?.cast<num>().map((e) => e.toInt()).toList();
      final row2 = (d['row2'] as List?)?.cast<num>().map((e) => e.toInt()).toList();
      picture = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _columnRow(row1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              op,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ),
          _columnRow(row2),
          const SizedBox(height: 2),
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 3,
            width: 136,
            color: Colors.black,
          ),
        ],
      );
    } else {
      final tens = (d['tens'] as num?)?.toInt();
      final ones = (d['ones'] as num?)?.toInt();
      picture = StellenwerttafelWidget(tensValue: tens, onesValue: ones);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        picture,
        const SizedBox(height: 16),
        BigAnswerField(
          controller: _controller,
          onChanged: widget.onValueChanged,
          hintText: '?',
        ),
      ],
    );
  }
}
