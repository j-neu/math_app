import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/diagnostic_question.dart';
import '../services/answer_grading.dart';

/// Renders the input for one diagnostic question according to its answer mode
/// (see [AnswerGrading.modeFor]). All inputs write into the shared [controller]
/// so the caller's grading and persistence keep working unchanged.
class DiagnosticAnswerInput extends StatelessWidget {
  final DiagnosticQuestion question;
  final TextEditingController controller;
  final VoidCallback? onSubmit;

  const DiagnosticAnswerInput({
    super.key,
    required this.question,
    required this.controller,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final mode = AnswerGrading.modeFor(question);
    final label = answerFieldLabel(mode);
    switch (mode) {
      case DiagnosticAnswerMode.number:
        return _NumberField(controller: controller, onSubmit: onSubmit);
      case DiagnosticAnswerMode.sequence:
        return _SequenceFields(
          fieldCount: AnswerGrading.sequenceLength(question),
          controller: controller,
          onSubmit: onSubmit,
        );
      case DiagnosticAnswerMode.pairRows:
        return _PairRows(
          rows: AnswerGrading.pairRows(question),
          target: AnswerGrading.pairTarget(question),
          controller: controller,
          onSubmit: onSubmit,
        );
      case DiagnosticAnswerMode.choice:
        final options = AnswerGrading.choiceOptionsOf(question);
        if (options.isEmpty) {
          // No derivable tap options — fall back to a word-capable field so
          // the item stays answerable.
          return _FreeField(controller: controller, onSubmit: onSubmit);
        }
        return _ChoiceChips(
          options: options,
          controller: controller,
          onSubmit: onSubmit,
        );
      case DiagnosticAnswerMode.freeText:
        return _FreeField(controller: controller, onSubmit: onSubmit);
    }
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmit;

  const _NumberField({required this.controller, this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => onSubmit?.call(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Deine Antwort',
            ),
          ),
        ),
      ),
    );
  }
}

/// One small numeric field per expected number (counting sequences, Z/E
/// answers). Values are joined ", " into [controller].
class _SequenceFields extends StatefulWidget {
  final int fieldCount;
  final TextEditingController controller;
  final VoidCallback? onSubmit;

  const _SequenceFields({
    required this.fieldCount,
    required this.controller,
    this.onSubmit,
  });

  @override
  State<_SequenceFields> createState() => _SequenceFieldsState();
}

class _SequenceFieldsState extends State<_SequenceFields> {
  late final List<TextEditingController> _fields;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _fields = List.generate(
        widget.fieldCount, (_) => TextEditingController());
    _focusNodes = List.generate(widget.fieldCount, (_) => FocusNode());
    for (final c in _fields) {
      c.addListener(_join);
    }
  }

  @override
  void dispose() {
    for (final c in _fields) {
      c.removeListener(_join);
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _join() {
    widget.controller.text = _fields
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .join(', ');
  }

  void _submitted(int index) {
    if (index < widget.fieldCount - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      widget.onSubmit?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...List.generate(widget.fieldCount, (index) {
            final isLast = index == widget.fieldCount - 1;
            return SizedBox(
              width: 64,
              child: TextField(
                controller: _fields[index],
                focusNode: _focusNodes[index],
                autofocus: index == 0,
                keyboardType: TextInputType.number,
                textInputAction:
                    isLast ? TextInputAction.done : TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _submitted(index),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Decomposition rows: "target = [a] + [b]" per row, two numeric fields each.
/// Values are joined "a + b; c + d; …" into [controller].
class _PairRows extends StatefulWidget {
  final int rows;
  final int target;
  final TextEditingController controller;
  final VoidCallback? onSubmit;

  const _PairRows({
    required this.rows,
    required this.target,
    required this.controller,
    this.onSubmit,
  });

  @override
  State<_PairRows> createState() => _PairRowsState();
}

class _PairRowsState extends State<_PairRows> {
  late final List<List<TextEditingController>> _fields;
  late final List<List<FocusNode>> _focusNodes;

  @override
  void initState() {
    super.initState();
    _fields = List.generate(
        widget.rows, (_) => List.generate(2, (_) => TextEditingController()));
    _focusNodes = List.generate(
        widget.rows, (_) => List.generate(2, (_) => FocusNode()));
    for (final row in _fields) {
      for (final c in row) {
        c.addListener(_join);
      }
    }
  }

  @override
  void dispose() {
    for (final row in _fields) {
      for (final c in row) {
        c.removeListener(_join);
        c.dispose();
      }
    }
    for (final row in _focusNodes) {
      for (final n in row) {
        n.dispose();
      }
    }
    super.dispose();
  }

  void _join() {
    final parts = <String>[];
    for (final row in _fields) {
      final a = row[0].text.trim();
      final b = row[1].text.trim();
      if (a.isNotEmpty || b.isNotEmpty) parts.add('$a + $b');
    }
    widget.controller.text = parts.join('; ');
  }

  void _submitted(int row, int col) {
    if (col == 0) {
      _focusNodes[row][1].requestFocus();
    } else if (row < widget.rows - 1) {
      _focusNodes[row + 1][0].requestFocus();
    } else {
      widget.onSubmit?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < widget.rows; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${widget.target} = ',
                    style: Theme.of(context).textTheme.titleLarge),
                ...List.generate(2, (col) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(
                      width: 64,
                      child: TextField(
                        controller: _fields[row][col],
                        focusNode: _focusNodes[row][col],
                        autofocus: row == 0 && col == 0,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onSubmitted: (_) => _submitted(row, col),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}

/// Large tap chips for choice items ("links"/"rechts").
class _ChoiceChips extends StatefulWidget {
  final List<String> options;
  final TextEditingController controller;
  final VoidCallback? onSubmit;

  const _ChoiceChips({
    required this.options,
    required this.controller,
    this.onSubmit,
  });

  @override
  State<_ChoiceChips> createState() => _ChoiceChipsState();
}

class _ChoiceChipsState extends State<_ChoiceChips> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncFromController);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    super.dispose();
  }

  void _syncFromController() {
    final text = widget.controller.text.trim().toLowerCase();
    if (_selected == null && text.isNotEmpty) {
      for (final option in widget.options) {
        if (option.toLowerCase() == text) {
          setState(() => _selected = option);
          return;
        }
      }
    }
  }

  void _choose(String option) {
    setState(() => _selected = option);
    widget.controller.text = option;
    widget.onSubmit?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (final option in widget.options)
          ChoiceChip(
            label: Text(option,
                style: Theme.of(context).textTheme.titleLarge),
            selected: _selected == option,
            onSelected: (_) => _choose(option),
          ),
      ],
    );
  }
}

/// Free text field for equations and phrase answers.
class _FreeField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmit;

  const _FreeField({required this.controller, this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => onSubmit?.call(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Deine Antwort',
            ),
          ),
        ),
      ),
    );
  }
}
