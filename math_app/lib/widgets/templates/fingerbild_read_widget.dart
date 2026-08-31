import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../manipulatives/fingerbild.dart';
import 'answer_pad.dart';

/// Ikonisch template widget for `fingerbild_read` (P2 plan §5 rule 7).
///
/// Renders a [FingerBildWidget] showing `display.count` fingers (one hand for
/// `hands: 1`, split 5/rest across both hands for `hands: 2`) and the child
/// types the count into a [BigAnswerField]. [onValueChanged] reports the typed
/// value, `""` while the field is empty.
class FingerbildReadWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const FingerbildReadWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<FingerbildReadWidget> createState() => _FingerbildReadWidgetState();
}

class _FingerbildReadWidgetState extends State<FingerbildReadWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void didUpdateWidget(covariant FingerbildReadWidget oldWidget) {
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
    final d = widget.problem.display;
    final count = (d['count'] as num?)?.toInt() ?? 0;
    final hands = (d['hands'] as num?)?.toInt() ?? 2;
    final left = hands == 1 ? count : (count < 5 ? count : 5);
    final right = count - left;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FingerBildWidget(leftCount: left, rightCount: right),
        const SizedBox(height: 8),
        BigAnswerField(
          controller: _controller,
          onChanged: widget.onValueChanged,
          hintText: '?',
        ),
      ],
    );
  }
}
