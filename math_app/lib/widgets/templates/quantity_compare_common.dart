import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'answer_pad.dart';

/// Shared interaction core for the `quantity_compare_*` custom widgets
/// (compare_quantity_difference, BUILD_ORDER.md Batch 1.8): renders two
/// quantities via [buildQuantity], offers a three-way "wer hat mehr"
/// choice, then -- unless the choice is "gleich" -- a typed-difference
/// field. Reports the joined answer string the generator's `expected` is
/// built to match exactly: `"gleich"`, or `"links,<n>"` / `"rechts,<n>"`.
class QuantityCompareCore extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final Widget Function(BuildContext context, int value) buildQuantity;
  final VoidCallback? onSubmit;

  const QuantityCompareCore({
    super.key,
    required this.problem,
    required this.onValueChanged,
    required this.buildQuantity,
    this.onSubmit,
  });

  @override
  State<QuantityCompareCore> createState() => _QuantityCompareCoreState();
}

class _QuantityCompareCoreState extends State<QuantityCompareCore> {
  String? _winner;
  final TextEditingController _controller = TextEditingController();

  int get _left => (widget.problem.display['left'] as int?) ?? 0;
  int get _right => (widget.problem.display['right'] as int?) ?? 0;

  @override
  void didUpdateWidget(covariant QuantityCompareCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _winner = null;
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

  void _pick(String winner) {
    setState(() => _winner = winner);
    widget.onValueChanged(winner == 'gleich' ? 'gleich' : '');
  }

  void _submitDifference(String text) {
    if (_winner == null || _winner == 'gleich') return;
    widget.onValueChanged(text.isEmpty ? '' : '$_winner,$text');
  }

  Widget _choiceButton(String label, String value) {
    final isSelected = _winner == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        key: ValueKey('qc-choice-$value'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.indigo : null,
          foregroundColor: isSelected ? Colors.white : null,
        ),
        onPressed: () => _pick(value),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.buildQuantity(context, _left),
              const SizedBox(width: 28),
              widget.buildQuantity(context, _right),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _choiceButton('Links mehr', 'links'),
            _choiceButton('Gleich', 'gleich'),
            _choiceButton('Rechts mehr', 'rechts'),
          ],
        ),
        if (_winner != null && _winner != 'gleich') ...[
          const SizedBox(height: 16),
          BigAnswerField(
            key: const ValueKey('qc-diff-field'),
            controller: _controller,
            onChanged: _submitDifference,
            onSubmit: widget.onSubmit,
            hintText: '?',
          ),
        ],
      ],
    );
  }
}
