import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'answer_pad.dart';

/// Symbolic template widget for `word_problem` (P2 plan §5 rule 16).
///
/// Renders the finished German story sentence from `problem.promptDe` in a
/// readable card and reports the typed result number via [onValueChanged].
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              widget.problem.promptDe,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ),
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
