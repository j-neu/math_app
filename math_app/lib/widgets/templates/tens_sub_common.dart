import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'answer_pad.dart';

/// Shared interaction core for the `tens_sub_ikonisch`/`tens_sub_symbolisch`
/// custom widgets (tens_sub_tens, tens_sub_crossing_hundred, BUILD_ORDER.md
/// Batch 1.12): renders the subtraction via [buildVisual] (called with the
/// *tens counts*, not the decade numbers), then a single field for the
/// typed result -- reported live via [onValueChanged], graded centrally
/// like every other custom_widget. `tens_sub_enaktiv` (tap-to-cross-out) is
/// a standalone widget and does not use this core.
class TensSubCore extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final Widget Function(BuildContext context, int tensA, int tensB) buildVisual;
  final VoidCallback? onSubmit;

  const TensSubCore({
    super.key,
    required this.problem,
    required this.onValueChanged,
    required this.buildVisual,
    this.onSubmit,
  });

  @override
  State<TensSubCore> createState() => _TensSubCoreState();
}

class _TensSubCoreState extends State<TensSubCore> {
  final TextEditingController _controller = TextEditingController();

  int get _a => (widget.problem.display['a'] as num).toInt();
  int get _b => (widget.problem.display['b'] as num).toInt();

  @override
  void didUpdateWidget(covariant TensSubCore oldWidget) {
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: widget.buildVisual(context, _a ~/ 10, _b ~/ 10),
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
