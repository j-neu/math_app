import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../common/hundred_chart_widget.dart';
import 'answer_pad.dart';

/// Custom-widget template for the registry key `"hundred_chart_skip"`
/// (skip2/5/10_forward/backward_zr100's field-visible levels, BUILD_ORDER.md
/// Batch 1.4b): renders `display.visible_values` on the existing
/// [HundredChartWidget] (already used by the diagnostic screen) in its
/// sparse mode, highlighting the most recent visible number and blanking
/// `display.query_value` with "?". The child derives the single next number
/// in the step pattern and types it into [BigAnswerField]; [onValueChanged]
/// reports every typed value, `""` while the field is empty.
class HundredChartStepWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const HundredChartStepWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<HundredChartStepWidget> createState() =>
      _HundredChartStepWidgetState();
}

class _HundredChartStepWidgetState extends State<HundredChartStepWidget> {
  final TextEditingController _controller = TextEditingController();

  List<int> get _visible =>
      ((widget.problem.display['visible_values'] as List?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList();

  int get _highlight => (widget.problem.display['highlight_value'] as int?) ?? 0;

  int get _query => (widget.problem.display['query_value'] as int?) ?? 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HundredChartStepWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HundredChartWidget(
          visibleValues: _visible.toSet(),
          highlightValue: _highlight,
          queryValue: _query,
        ),
        const SizedBox(height: 12),
        BigAnswerField(
          controller: _controller,
          onChanged: widget.onValueChanged,
          hintText: '?',
        ),
      ],
    );
  }
}
