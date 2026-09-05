import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'answer_pad.dart';

/// Symbolic template widget for `word_problem` (P2 plan §5 rule 16).
///
/// Collects the typed result number for the finished German story sentence.
/// The story itself renders ONCE, in PracticeScreen's prompt card above the
/// template (§3a 2026-09-05: a second copy inside this widget was confirmed
/// redundant); [onValueChanged] is reported on every edit.
class WordProblemWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const WordProblemWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<WordProblemWidget> createState() => _WordProblemWidgetState();
}

class _WordProblemWidgetState extends State<WordProblemWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void didUpdateWidget(covariant WordProblemWidget oldWidget) {
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
    return BigAnswerField(
      controller: _controller,
      onChanged: widget.onValueChanged,
      hintText: '?',
    );
  }
}
