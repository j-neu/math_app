import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/problem.dart';

/// Symbolic template widget for `sequence_gap` (P2 plan §5 rule 13).
///
/// Renders the arithmetic sequence from `problem.display['values']` with a
/// blank box at every `gap_indices` position. The child types each missing
/// value; [onValueChanged] reports the filled values joined `","` in sequence
/// order once every gap is filled, `""` while incomplete.
class SequenceGapWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const SequenceGapWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<SequenceGapWidget> createState() => _SequenceGapWidgetState();
}

class _SequenceGapWidgetState extends State<SequenceGapWidget> {
  late List<TextEditingController> _controllers;

  List<int> get _gapIndices =>
      ((widget.problem.display['gap_indices'] as List?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _gapIndices.length,
      (_) => TextEditingController(),
    );
  }

  @override
  void didUpdateWidget(covariant SequenceGapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      for (final c in _controllers) {
        c.dispose();
      }
      _controllers = List.generate(
        _gapIndices.length,
        (_) => TextEditingController(),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String get _currentValue {
    final texts = _controllers.map((c) => c.text.trim()).toList();
    if (texts.isEmpty || texts.any((t) => t.isEmpty)) return '';
    return texts.join(',');
  }

  Widget _text(String s) {
    return Text(
      s,
      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
    );
  }

  Widget _gap(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 68,
        height: 56,
        child: TextField(
          controller: _controllers[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: '?',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
          onChanged: (_) => widget.onValueChanged(_currentValue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final values = ((widget.problem.display['values'] as List?) ?? const [])
        .map((e) => (e as num).toInt())
        .toList();
    final gaps = _gapIndices.toSet();
    final gapOrder = <int, int>{
      for (var i = 0; i < _gapIndices.length; i++) _gapIndices[i]: i,
    };

    final children = <Widget>[];
    for (var i = 0; i < values.length; i++) {
      if (gaps.contains(i)) {
        children.add(_gap(gapOrder[i]!));
      } else {
        children.add(_text('${values[i]}'));
      }
      if (i < values.length - 1) {
        children.add(_text(','));
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 8,
          children: children,
        ),
        if (widget.problem.promptDe.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            widget.problem.promptDe,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ],
    );
  }
}
