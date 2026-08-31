import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Symbolic template widget for `compare_symbols` (P2 plan §5 rule 14).
///
/// Shows the two numbers from `problem.display` with three large choice
/// buttons `<`, `>`, `=`; the chosen operator is reported via
/// [onValueChanged], `""` until a button is tapped. Re-tapping a different
/// button re-picks the operator.
class CompareSymbolsWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const CompareSymbolsWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<CompareSymbolsWidget> createState() => _CompareSymbolsWidgetState();
}

class _CompareSymbolsWidgetState extends State<CompareSymbolsWidget> {
  String? _selected;

  @override
  void didUpdateWidget(covariant CompareSymbolsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _selected = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  Widget _operatorButton(String op) {
    final selected = _selected == op;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 84,
        height: 64,
        child: Material(
          color: selected ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() => _selected = op);
              widget.onValueChanged(op);
            },
            child: Center(
              child: Text(
                op,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: selected ? colors.onPrimary : colors.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.problem.display;
    final a = (d['a'] ?? 0).toString();
    final b = (d['b'] ?? 0).toString();
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          children: [
            Text(
              a,
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
            ),
            Text(
              _selected ?? '?',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: _selected != null ? colors.primary : colors.outline,
              ),
            ),
            Text(
              b,
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _operatorButton('<'),
            _operatorButton('>'),
            _operatorButton('='),
          ],
        ),
        if (widget.problem.promptDe.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            widget.problem.promptDe,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ],
    );
  }
}
