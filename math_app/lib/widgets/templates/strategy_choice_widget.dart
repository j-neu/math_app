import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/problem.dart';

/// Symbolic template widget for `strategy_choice` (P2 plan §5 rule 15).
///
/// The child first solves `a op b` into the equation's result field, then
/// picks one of the strategy buttons from `problem.display['strategies']`
/// (labels shown, ids reported). [onValueChanged] reports `"result|strategyId"`
/// only when both parts are done; re-tapping a strategy re-picks it.
class StrategyChoiceWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const StrategyChoiceWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<StrategyChoiceWidget> createState() => _StrategyChoiceWidgetState();
}

class _StrategyChoiceWidgetState extends State<StrategyChoiceWidget> {
  final TextEditingController _resultController = TextEditingController();
  String? _strategy;

  @override
  void didUpdateWidget(covariant StrategyChoiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _resultController.clear();
      _strategy = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  @override
  void dispose() {
    _resultController.dispose();
    super.dispose();
  }

  void _report() {
    final result = _resultController.text.trim();
    if (result.isEmpty || _strategy == null) {
      widget.onValueChanged('');
      return;
    }
    widget.onValueChanged('$result|$_strategy');
  }

  List<Map<String, String>> get _strategies {
    final raw = widget.problem.display['strategies'];
    if (raw is! List) return const [];
    return raw
        .map((e) => (e as Map).cast<String, dynamic>())
        .map((e) => {
              'id': (e['id'] ?? '').toString(),
              'label_de': (e['label_de'] ?? '').toString(),
            })
        .toList();
  }

  Widget _strategyButton(Map<String, String> strategy) {
    final id = strategy['id']!;
    final selected = _strategy == id;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.tonal(
          onPressed: () {
            setState(() => _strategy = id);
            _report();
          },
          style: FilledButton.styleFrom(
            backgroundColor: selected ? colors.primaryContainer : null,
            foregroundColor: selected ? colors.onPrimaryContainer : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            strategy['label_de']!,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.problem.display;
    final op = (d['op'] ?? '+').toString();
    final a = (d['a'] ?? 0).toString();
    final b = (d['b'] ?? 0).toString();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              '$a $op $b =',
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              width: 88,
              height: 56,
              child: TextField(
                controller: _resultController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: '?',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (_) => _report(),
              ),
            ),
          ],
        ),
        if (_strategies.isNotEmpty) ...[
          const SizedBox(height: 16),
          ..._strategies.map(_strategyButton),
        ],
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
