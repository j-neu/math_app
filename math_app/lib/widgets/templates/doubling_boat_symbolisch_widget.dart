import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Custom-widget template for the registry key `"doubling_boat_symbolisch"`
/// (double_crossing_10, Level 3/symbolisch). The original
/// `DoublingBoatLevel3Widget` kept a permanently-covered Rechenschiffchen
/// on screen purely as decoration; dropped here in favour of the plain
/// number-card convention every other symbolisch tier in this family uses
/// (see `doubling_mirror_symbolisch_widget.dart`), since "mental" means no
/// manipulative at all, not a manipulative you can't see.
class DoublingBoatSymbolischWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const DoublingBoatSymbolischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  State<DoublingBoatSymbolischWidget> createState() =>
      _DoublingBoatSymbolischWidgetState();
}

class _DoublingBoatSymbolischWidgetState
    extends State<DoublingBoatSymbolischWidget> {
  final TextEditingController _controller = TextEditingController();

  int get _target => (widget.problem.display['target'] as num).toInt();

  @override
  void didUpdateWidget(covariant DoublingBoatSymbolischWidget oldWidget) {
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
        Text(
          'Stell dir vor:',
          style: TextStyle(fontSize: 24, color: Colors.grey.shade600),
        ),
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
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          'Was ist das Doppelte?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
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
