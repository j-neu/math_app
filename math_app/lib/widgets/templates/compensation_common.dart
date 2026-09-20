import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Shared interaction core for the `compensation_ikonisch`/
/// `compensation_symbolisch` custom widgets (compensation_strategy_zr20,
/// BUILD_ORDER.md Batch 1.13): renders the scene via [buildScene], then
/// two number fields (red/blue) whose combined `"red,blue"` string is
/// reported live via [onValueChanged] once both parse -- graded centrally
/// like every other custom_widget. `compensation_enaktiv` (cover-then-
/// reveal) is a standalone widget and does not use this core.
class CompensationCore extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final Widget Function(BuildContext context, int total, int red, int blue, String flip)
      buildScene;
  final VoidCallback? onSubmit;

  const CompensationCore({
    super.key,
    required this.problem,
    required this.onValueChanged,
    required this.buildScene,
    this.onSubmit,
  });

  @override
  State<CompensationCore> createState() => _CompensationCoreState();
}

class _CompensationCoreState extends State<CompensationCore> {
  final TextEditingController _redController = TextEditingController();
  final TextEditingController _blueController = TextEditingController();

  int get _total => (widget.problem.display['total'] as num).toInt();
  int get _red => (widget.problem.display['red'] as num).toInt();
  int get _blue => (widget.problem.display['blue'] as num).toInt();
  String get _flip => widget.problem.display['flip'] as String;

  @override
  void didUpdateWidget(covariant CompensationCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _redController.clear();
      _blueController.clear();
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
        widget.buildScene(context, _total, _red, _blue, _flip),
        const SizedBox(height: 16),
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
