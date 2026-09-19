import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'answer_pad.dart';

/// Custom-widget template for the registry key `"count_field_enaktiv"`
/// (quantify_count_zr10 level 1, BUILD_ORDER.md Batch 1.1): `display.count`
/// loose dots laid out in structured rows of at most 5 (a ten-frame-style
/// row), ported from the retired `CountDotsLevel2Widget`'s tap-to-count
/// mechanic. Tapping a dot toggles it as counted (a visual counting aid, not
/// part of the graded answer); the child types the total into
/// [BigAnswerField] and [onValueChanged] reports every typed value, `""`
/// while the field is empty.
class CountFieldEnaktivWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const CountFieldEnaktivWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  State<CountFieldEnaktivWidget> createState() =>
      _CountFieldEnaktivWidgetState();
}

class _CountFieldEnaktivWidgetState extends State<CountFieldEnaktivWidget> {
  final TextEditingController _controller = TextEditingController();
  final Set<int> _tapped = {};

  int get _count => (widget.problem.display['count'] as int?) ?? 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CountFieldEnaktivWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _controller.clear();
      _tapped.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
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
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isTapped ? Colors.green : Colors.indigo,
            border: Border.all(
              color: isTapped ? Colors.green.shade700 : Colors.indigo.shade700,
              width: 2,
            ),
          ),
          child: isTapped
              ? const Icon(Icons.check, color: Colors.white, size: 22)
              : null,
        ),
      ),
    );
  }

  Widget _rows() {
    const perRow = 5;
    final rows = <Widget>[];
    for (var start = 0; start < _count; start += perRow) {
      final end = (start + perRow > _count) ? _count : start + perRow;
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [for (var i = start; i < end; i++) _dot(i)],
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _rows(),
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
