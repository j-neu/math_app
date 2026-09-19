import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Custom-widget template for the registry key
/// `"doubling_mirror_symbolisch"` (verdoppeln-halbieren.ZR10, Level
/// 3/symbolisch). Ported from the old engine's `DoublingMirrorLevel3Widget`;
/// that file is untouched. Unlike Level 1/2, the original had no internal
/// scaffolding steps -- it showed a number card and self-graded a typed
/// answer with its own button. The port keeps the number card and drops the
/// self-grading entirely: the field reports live via [onValueChanged], and
/// the practice screen's one generic submit button grades it centrally.
class DoublingMirrorSymbolischWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const DoublingMirrorSymbolischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  State<DoublingMirrorSymbolischWidget> createState() =>
      _DoublingMirrorSymbolischWidgetState();
}

class _DoublingMirrorSymbolischWidgetState
    extends State<DoublingMirrorSymbolischWidget> {
  final TextEditingController _controller = TextEditingController();

  int get _targetCount => (widget.problem.display['target'] as num).toInt();

  @override
  void didUpdateWidget(covariant DoublingMirrorSymbolischWidget oldWidget) {
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
              '$_targetCount',
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
