import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../manipulatives/rekenrek.dart';
import 'answer_pad.dart';

/// Custom-widget template for the registry key `"flash_subitize"` (A2.1,
/// P2 plan §5): a dot or Rekenrek pattern is shown for `display.flash_ms`
/// (800 ms) and then fades out via [AnimatedOpacity] so the child answers
/// from memory — the `_RekenrekFlashWidget` pattern.
///
/// The child types the count into a [BigAnswerField]; [onValueChanged]
/// reports every typed value, `""` while the field is empty. A "Nochmal
/// sehen" button re-shows the pattern briefly (ADHD / working-memory
/// support). `display.count` is always within the subitizable range 1..5 and
/// `display.display` is `"dots"` or `"rekenrek"`. The flash timer is
/// cancelled in dispose.
class FlashSubitizeWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const FlashSubitizeWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<FlashSubitizeWidget> createState() => _FlashSubitizeWidgetState();
}

class _FlashSubitizeWidgetState extends State<FlashSubitizeWidget> {
  final TextEditingController _controller = TextEditingController();
  Timer? _timer;
  bool _visible = true;

  int get _count => (widget.problem.display['count'] as int?) ?? 0;
  int get _flashMs => (widget.problem.display['flash_ms'] as int?) ?? 800;
  String get _pattern =>
      (widget.problem.display['display'] as String?) ?? 'dots';

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void didUpdateWidget(covariant FlashSubitizeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _controller.clear();
      _timer?.cancel();
      _visible = true;
      _scheduleHide();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleHide() {
    _timer = Timer(Duration(milliseconds: _flashMs), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  void _reshow() {
    _timer?.cancel();
    setState(() => _visible = true);
    _scheduleHide();
  }

  Widget _visual() {
    if (_pattern == 'rekenrek') {
      return RekenrekWidget(topLeft: _count, bottomLeft: 0);
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        for (var i = 0; i < _count; i++)
          Container(
            key: ValueKey('flash-dot-$i'),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.indigo,
              border: Border.all(color: Colors.indigo, width: 2),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          key: const ValueKey('flash-visual'),
          opacity: _visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: _visual(),
        ),
        const SizedBox(height: 12),
        TextButton(
          key: const ValueKey('flash-reshow'),
          onPressed: _reshow,
          child: const Text('Nochmal sehen'),
        ),
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
