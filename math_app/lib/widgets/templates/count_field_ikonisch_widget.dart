import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'answer_pad.dart';

/// Custom-widget template for the registry key `"count_field_ikonisch"`
/// (quantify_count_zr10 level 2, BUILD_ORDER.md Batch 1.1): `display.count`
/// loose dots scattered inside a fixed area (no row structure), ported from
/// the retired `CountDotsLevel4Widget`'s rejection-sampled scatter
/// algorithm. Positions are seeded from `problem.seed`/`problem.index` so
/// the same problem always lays out the same way (no wall-clock or platform
/// randomness). Tapping a dot toggles it as counted (a visual counting aid);
/// the child types the total into [BigAnswerField] and [onValueChanged]
/// reports every typed value, `""` while the field is empty.
class CountFieldIkonischWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const CountFieldIkonischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  State<CountFieldIkonischWidget> createState() =>
      _CountFieldIkonischWidgetState();
}

class _CountFieldIkonischWidgetState extends State<CountFieldIkonischWidget> {
  final TextEditingController _controller = TextEditingController();
  final Set<int> _tapped = {};
  late List<Offset> _positions;

  int get _count => (widget.problem.display['count'] as int?) ?? 0;

  @override
  void initState() {
    super.initState();
    _positions = _scatter();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CountFieldIkonischWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _controller.clear();
      _tapped.clear();
      _positions = _scatter();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  List<Offset> _scatter() {
    final random = Random(
      widget.problem.seed * 97 + widget.problem.index * 31 + _count,
    );
    const minDistance = 0.18;
    const maxAttempts = 200;
    final positions = <Offset>[];
    for (var i = 0; i < _count; i++) {
      var placed = false;
      var attempts = 0;
      var candidate = const Offset(0.5, 0.5);
      while (!placed && attempts < maxAttempts) {
        candidate = Offset(
          0.1 + random.nextDouble() * 0.8,
          0.1 + random.nextDouble() * 0.8,
        );
        placed = positions.every(
          (existing) => (candidate - existing).distance >= minDistance,
        );
        attempts++;
      }
      positions.add(candidate);
    }
    return positions;
  }

  void _toggle(int index) {
    setState(() {
      if (!_tapped.remove(index)) _tapped.add(index);
    });
  }

  Widget _dot(int index) {
    final isTapped = _tapped.contains(index);
    return Semantics(
      button: true,
      label: isTapped ? 'Punkt ${index + 1} gezählt' : 'Punkt ${index + 1}',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('cf-dot-$index'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggle(index),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isTapped ? Colors.green : Colors.indigo,
            border: Border.all(
              color: isTapped ? Colors.green.shade700 : Colors.indigo.shade700,
              width: 2,
            ),
          ),
          child: isTapped
              ? const Icon(Icons.check, color: Colors.white, size: 20)
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
          height: 220,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  for (var i = 0; i < _positions.length; i++)
                    Positioned(
                      left: _positions[i].dx * constraints.maxWidth - 22,
                      top: _positions[i].dy * constraints.maxHeight - 22,
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
