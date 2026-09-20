import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../common/wendeplaettchen_widget.dart';

/// Enaktiv tier of `compensation_strategy_zr20` (BUILD_ORDER.md Batch
/// 1.13): shows the two-colour counter pile, lets the child press a
/// button to cover it once they've studied the starting counts and the
/// change rule, then reveals two input fields and asks for the new
/// red/blue counts from memory -- mirroring the old engine's
/// `OppositeChangeLevelWidget` cover-then-reveal flow
/// (math_app/lib/widgets/opposite_change_level_widget.dart, untouched;
/// this is a fresh copy with a simplified, non-animated cover and an
/// adapted contract, not a refactor of the original). Both counts are
/// reported together as a single `"red,blue"` string via [onValueChanged]
/// once both fields parse -- graded centrally via a plain string match
/// against `problem.expected`, like every other custom_widget.
class CompensationEnaktivWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const CompensationEnaktivWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  State<CompensationEnaktivWidget> createState() =>
      _CompensationEnaktivWidgetState();
}

class _CompensationEnaktivWidgetState
    extends State<CompensationEnaktivWidget> {
  bool _covered = false;
  final TextEditingController _redController = TextEditingController();
  final TextEditingController _blueController = TextEditingController();

  int get _total => (widget.problem.display['total'] as num).toInt();
  int get _red => (widget.problem.display['red'] as num).toInt();
  int get _blue => (widget.problem.display['blue'] as num).toInt();
  String get _flip => widget.problem.display['flip'] as String;

  String get _changeText =>
      _flip == 'red_to_blue' ? 'Eine rote wird blau.' : 'Eine blaue wird rot.';

  @override
  void didUpdateWidget(covariant CompensationEnaktivWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      setState(() {
        _covered = false;
        _redController.clear();
        _blueController.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  @override
  void dispose() {
    _redController.dispose();
    _blueController.dispose();
    super.dispose();
  }

  void _reportIfComplete() {
    final red = int.tryParse(_redController.text);
    final blue = int.tryParse(_blueController.text);
    if (red != null && blue != null) {
      widget.onValueChanged('$red,$blue');
    } else {
      widget.onValueChanged('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Gesamt: $_total',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_changeText, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 16),
        if (!_covered)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < _red; i++)
                  WendeplaettchenWidget(
                    key: ValueKey('comp-red-$i'),
                    color: Colors.red,
                  ),
                for (var i = 0; i < _blue; i++)
                  WendeplaettchenWidget(
                    key: ValueKey('comp-blue-$i'),
                    color: Colors.blue,
                  ),
              ],
            ),
          )
        else
          Container(
            width: 200,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.help_outline, size: 48, color: Colors.grey.shade600),
          ),
        const SizedBox(height: 16),
        if (!_covered)
          ElevatedButton(
            key: const ValueKey('comp-cover-button'),
            onPressed: () => setState(() => _covered = true),
            child: const Text('Zudecken'),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInput('Rot', Colors.red, _redController),
              const SizedBox(width: 24),
              _buildInput('Blau', Colors.blue, _blueController),
            ],
          ),
      ],
    );
  }

  Widget _buildInput(
    String label,
    Color color,
    TextEditingController controller,
  ) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          width: 60,
          child: TextField(
            key: ValueKey('comp-input-$label'),
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onChanged: (_) => _reportIfComplete(),
            onSubmitted: (_) => widget.onSubmit?.call(),
          ),
        ),
      ],
    );
  }
}
