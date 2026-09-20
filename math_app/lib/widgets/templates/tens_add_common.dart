import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'answer_pad.dart';

/// Shared interaction core for the `tens_add_*` custom widgets
/// (tens_add_tens, BUILD_ORDER.md Batch 1.12): renders the two decade
/// addends via [buildGroup] (called once per addend with its *tens count*,
/// e.g. 3 for the addend 30), then a single field for the typed sum --
/// reported live via [onValueChanged], graded centrally like every other
/// custom_widget. Mirrors the `QuantityCompareCore` pattern
/// (quantity_compare_common.dart, BUILD_ORDER.md Batch 1.8).
class TensAddCore extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final Widget Function(BuildContext context, int tensCount) buildGroup;
  final VoidCallback? onSubmit;

  const TensAddCore({
    super.key,
    required this.problem,
    required this.onValueChanged,
    required this.buildGroup,
    this.onSubmit,
  });

  @override
  State<TensAddCore> createState() => _TensAddCoreState();
}

class _TensAddCoreState extends State<TensAddCore> {
  final TextEditingController _controller = TextEditingController();

  int get _a => (widget.problem.display['a'] as num).toInt();
  int get _b => (widget.problem.display['b'] as num).toInt();

  @override
  void didUpdateWidget(covariant TensAddCore oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$_a + $_b = ?',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.buildGroup(context, _a ~/ 10),
              const SizedBox(width: 20),
              const Icon(Icons.add, size: 32),
              const SizedBox(width: 20),
              widget.buildGroup(context, _b ~/ 10),
            ],
          ),
        ),
        const SizedBox(height: 24),
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
