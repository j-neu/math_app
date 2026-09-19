import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Custom-widget template for the registry key `"doubling_tens_symbolisch"`
/// (double_decade, Level 3/symbolisch). Shows the decade number as a plain
/// number card, matching every other symbolisch tier in this family (see
/// `doubling_mirror_symbolisch_widget.dart`) rather than the original
/// `DoublingTensLevel3Widget`'s "N Zehner" text framing -- consistent with
/// how the rest of the family reports the full doubled number, not an
/// intermediate tens-only abstraction.
class DoublingTensSymbolischWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const DoublingTensSymbolischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  State<DoublingTensSymbolischWidget> createState() =>
      _DoublingTensSymbolischWidgetState();
}

class _DoublingTensSymbolischWidgetState
    extends State<DoublingTensSymbolischWidget> {
  final TextEditingController _controller = TextEditingController();

  int get _target => (widget.problem.display['target'] as num).toInt();

  @override
  void didUpdateWidget(covariant DoublingTensSymbolischWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _controller.clear();
      widget.onValueChanged('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Stell dir vor:',
            style: TextStyle(fontSize: 24, color: Colors.grey.shade600)),
        const SizedBox(height: 20),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.blue.shade200, width: 2),
          ),
          child: Center(
            child: Text(
              '$_target',
              style: const TextStyle(
                  fontSize: 56, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text('Was ist das Doppelte?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        SizedBox(
          width: 200,
          child: TextField(
            key: const ValueKey('final-answer'),
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              hintText: '?',
            ),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            autofocus: true,
            onChanged: widget.onValueChanged,
            onSubmitted: (_) => widget.onSubmit?.call(),
          ),
        ),
      ],
    );
  }
}
