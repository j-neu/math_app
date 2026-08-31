import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'answer_pad.dart';

/// Symbolic template widget for `equation_solve` (P2 plan §5 rule 11).
///
/// Renders `a op b = ?` (or the unknown on the left for
/// `unknown: addend|minuend`, in the middle for `subtrahend`) from
/// `problem.display` and reports the typed number via [onValueChanged].
/// `mode: "place_value"` renders both operands decomposed as
/// `"4 Zehner 3 Einer + 2 Zehner 2 Einer = ?"`.
class EquationSolveWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const EquationSolveWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<EquationSolveWidget> createState() => _EquationSolveWidgetState();
}

class _EquationSolveWidgetState extends State<EquationSolveWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void didUpdateWidget(covariant EquationSolveWidget oldWidget) {
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

  String get _equationText {
    final d = widget.problem.display;
    if (d['mode'] == 'place_value') {
      final aTens = (d['a_tens'] ?? 0).toString();
      final aOnes = (d['a_ones'] ?? 0).toString();
      final bTens = (d['b_tens'] ?? 0).toString();
      final bOnes = (d['b_ones'] ?? 0).toString();
      final op = (d['op'] ?? '+').toString();
      return '$aTens Zehner $aOnes Einer $op $bTens Zehner $bOnes Einer = ?';
    }
    final a = (d['a'] ?? 0).toString();
    final b = (d['b'] ?? 0).toString();
    final c = (d['c'] ?? 0).toString();
    final op = (d['op'] ?? '+').toString();
    return switch (d['unknown']) {
      'addend' || 'minuend' => '? $op $b = $c',
      'subtrahend' => '$a $op ? = $c',
      _ => '$a $op $b = ?',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _equationText,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
        ),
        if (widget.problem.promptDe.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.problem.promptDe,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
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
