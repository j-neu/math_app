import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/problem.dart';

/// Symbolic template widget for `equation_gap` (P2 plan §5 rule 12).
///
/// Renders the Stützpunkt-form equation from `problem.display` with gap
/// box(es) at the position given by `gap_after` / `form`:
/// `result` (gap, place_value, double), `middle` (missing_addend),
/// `right` (helper, helper_double) and `both` (any_split, half, neighbor).
///
/// Value formats match [TemplateEvaluator]'s string match: a single typed
/// number for one-gap forms; `"i+j"` for `any_split` once both fields are
/// filled; the number once both `half` fields agree; the first filled field
/// for `neighbor`. `""` while incomplete keeps the host's submit disabled.
class EquationGapWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const EquationGapWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<EquationGapWidget> createState() => _EquationGapWidgetState();
}

class _EquationGapWidgetState extends State<EquationGapWidget> {
  late List<TextEditingController> _controllers;

  String get _form =>
      widget.problem.display['form'] as String? ?? 'gap';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_gapCount, (_) => TextEditingController());
  }

  @override
  void didUpdateWidget(covariant EquationGapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      for (final c in _controllers) {
        c.dispose();
      }
      _controllers = List.generate(_gapCount, (_) => TextEditingController());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  int get _gapCount {
    if (_form == 'any_split' || _form == 'half' || _form == 'neighbor') {
      return 2;
    }
    return 1;
  }

  String get _currentValue {
    final texts = _controllers.map((c) => c.text.trim()).toList();
    switch (_form) {
      case 'any_split':
        if (texts.length == 2 && texts[0].isNotEmpty && texts[1].isNotEmpty) {
          return '${texts[0]}+${texts[1]}';
        }
        return '';
      case 'half':
        if (texts.length == 2 &&
            texts[0].isNotEmpty &&
            texts[1].isNotEmpty &&
            texts[0] == texts[1]) {
          return texts[0];
        }
        return '';
      case 'neighbor':
        // Both neighbours must be filled: report "n-1,n+1" so the evaluator
        // can validate each side. A single filled gap stays incomplete.
        if (texts.length == 2 && texts[0].isNotEmpty && texts[1].isNotEmpty) {
          return '${texts[0]},${texts[1]}';
        }
        return '';
      default:
        return texts.isEmpty ? '' : texts[0];
    }
  }

  Widget _text(String s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        s,
        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _gap(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        width: 76,
        height: 56,
        child: TextField(
          controller: _controllers[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: '?',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
          onChanged: (_) => widget.onValueChanged(_currentValue),
        ),
      ),
    );
  }

  List<Widget> _equationParts() {
    final d = widget.problem.display;
    final op = (d['op'] ?? '+').toString();
    final gap = _gap(0);
    switch (_form) {
      case 'helper':
      case 'helper_double':
        return [
          _text('${d['a']} $op ${d['b']} ='),
          _text('${d['first']} $op'),
          gap,
        ];
      case 'missing_addend':
        return [_text('${d['a']} $op'), gap, _text('= ${d['c']}')];
      case 'any_split':
      case 'half':
        return [_gap(0), _text(op), _gap(1), _text('= ${d['total']}')];
      case 'neighbor':
        return [_gap(0), _text('${d['n']}'), _gap(1)];
      case 'place_value':
        return [_text('${d['tens']} Zehner ${d['ones']} Einer ='), gap];
      case 'double':
        return [_text('${d['a']} $op ${d['a']} ='), gap];
      default:
        return [_text('${d['a']} $op ${d['b']} ='), gap];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 2,
          runSpacing: 8,
          children: _equationParts(),
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
