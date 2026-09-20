import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../common/ten_strip_widget.dart';
import 'answer_pad.dart';

/// Enaktiv tier of `tens_sub_tens` / `tens_sub_crossing_hundred`
/// (BUILD_ORDER.md Batch 1.12): the total is shown as `tensA` actual
/// ten-rods (`TenStripWidget`, a shared manipulative, imported unmodified).
/// The child taps rods to cross them out, mirroring the old engine's
/// `TensCalculationLevel2Widget` tap-to-mark interaction
/// (math_app/lib/widgets/tens_calculation_level2_widget.dart, untouched) --
/// fresh copy, adapted contract. Crossing out is an optional manipulative
/// aid, not gated: the final answer is always typed freely and reported
/// live via [onValueChanged], graded centrally like every other
/// custom_widget.
class TensSubEnaktivWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const TensSubEnaktivWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  State<TensSubEnaktivWidget> createState() => _TensSubEnaktivWidgetState();
}

class _TensSubEnaktivWidgetState extends State<TensSubEnaktivWidget> {
  final TextEditingController _controller = TextEditingController();
  late List<bool> _crossed;

  int get _a => (widget.problem.display['a'] as num).toInt();
  int get _b => (widget.problem.display['b'] as num).toInt();
  int get _tensA => _a ~/ 10;

  @override
  void initState() {
    super.initState();
    _crossed = List.filled(_tensA, false);
  }

  @override
  void didUpdateWidget(covariant TensSubEnaktivWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _controller.clear();
      _crossed = List.filled(_tensA, false);
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

  void _toggle(int index) {
    setState(() => _crossed[index] = !_crossed[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$_a - $_b = ?',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Streiche $_b Zehner durch!',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < _tensA; i++)
                GestureDetector(
                  key: ValueKey('tens-sub-rod-$_tensA-$i'),
                  onTap: () => _toggle(i),
                  child: TenStripWidget(
                    color: Colors.blue,
                    isMarked: _crossed[i],
                    width: 20,
                    height: 120,
                  ),
                ),
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
