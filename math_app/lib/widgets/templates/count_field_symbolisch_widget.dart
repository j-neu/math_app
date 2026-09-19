import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'answer_pad.dart';

/// Custom-widget template for the registry key `"count_field_symbolisch"`
/// (quantify_count_zr10 level 3, the hardest arrangement per
/// BUILD_ORDER.md Batch 1.1): `display.count` loose dots scattered like
/// level 2, but each drawn at one of three sizes (all >= the 44px
/// touch-target floor) so the child cannot estimate the total from the
/// covered area and must actually count. Positions and sizes are seeded
/// from `problem.seed`/`problem.index` for determinism. Tapping a dot
/// toggles it as counted (a visual counting aid); the child types the total
/// into [BigAnswerField] and [onValueChanged] reports every typed value,
/// `""` while the field is empty.
class CountFieldSymbolischWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const CountFieldSymbolischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  State<CountFieldSymbolischWidget> createState() =>
      _CountFieldSymbolischWidgetState();
}

class _CountFieldSymbolischWidgetState
    extends State<CountFieldSymbolischWidget> {
  static const List<double> _sizes = [44, 58, 72];

  final TextEditingController _controller = TextEditingController();
  final Set<int> _tapped = {};
  late List<Offset> _positions;
  late List<double> _dotSizes;

  int get _count => (widget.problem.display['count'] as int?) ?? 0;

  @override
  void initState() {
    super.initState();
    _layout();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CountFieldSymbolischWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _controller.clear();
      _tapped.clear();
      _layout();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  void _layout() {
    final random = Random(
      widget.problem.seed * 131 + widget.problem.index * 47 + _count,
    );
    const minDistance = 0.24;
    const maxAttempts = 200;
    final positions = <Offset>[];
    for (var i = 0; i < _count; i++) {
      var placed = false;
      var attempts = 0;
      var candidate = const Offset(0.5, 0.5);
      while (!placed && attempts < maxAttempts) {
        candidate = Offset(
          0.14 + random.nextDouble() * 0.72,
          0.14 + random.nextDouble() * 0.72,
        );
        placed = positions.every(
          (existing) => (candidate - existing).distance >= minDistance,
        );
        attempts++;
      }
      positions.add(candidate);
    }
    _positions = positions;
    _dotSizes = [
      for (var i = 0; i < _count; i++) _sizes[random.nextInt(_sizes.length)],
    ];
  }

  void _toggle(int index) {
    setState(() {
      if (!_tapped.remove(index)) _tapped.add(index);
    });
  }

  Widget _dot(int index) {
    final isTapped = _tapped.contains(index);
    final size = _dotSizes[index];
    return Semantics(
      button: true,
      label: isTapped ? 'Punkt ${index + 1} gezählt' : 'Punkt ${index + 1}',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('cf-dot-$index'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggle(index),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isTapped ? Colors.green : Colors.indigo,
            border: Border.all(
              color: isTapped ? Colors.green.shade700 : Colors.indigo.shade700,
              width: 2,
            ),
          ),
          child: isTapped
              ? Icon(Icons.check, color: Colors.white, size: size * 0.4)
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 320,
          height: 240,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  for (var i = 0; i < _positions.length; i++)
                    Positioned(
                      left: _positions[i].dx * constraints.maxWidth -
                          _dotSizes[i] / 2,
                      top: _positions[i].dy * constraints.maxHeight -
                          _dotSizes[i] / 2,
                      child: _dot(i),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Angetippt: ${_tapped.length}',
          key: const ValueKey('cf-tapped-count'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        BigAnswerField(
          controller: _controller,
          onChanged: widget.onValueChanged,
          onSubmit: widget.onSubmit,
          hintText: '?',
        ),
      ],
    );
  }
}
