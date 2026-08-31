import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Enaktiv template widget for `drag_partition` (P2 plan §5 rule 1).
///
/// Renders a stash of `display.total` counters plus one labelled box per part
/// (labels from `display.box_labels`). Tapping a box's `+` zone adds one
/// counter to it; tapping a box's counter display removes one. [onValueChanged]
/// reports the current box counts joined `"+"` ("b1+b2+…") on every change,
/// `""` while nothing is placed.
///
/// The widget deliberately does NOT enforce `display.split_constraint` — any
/// placement is allowed and the evaluator judges the split.
class DragPartitionWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const DragPartitionWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<DragPartitionWidget> createState() => _DragPartitionWidgetState();
}

class _DragPartitionWidgetState extends State<DragPartitionWidget> {
  late List<int> _counts;

  int get _parts => (widget.problem.display['parts'] as int?) ?? 0;
  int get _total => (widget.problem.display['total'] as int?) ?? 0;

  List<String> get _boxLabels {
    final raw = widget.problem.display['box_labels'];
    if (raw is! List) return List.filled(_parts, '');
    return raw.map((e) => e.toString()).toList();
  }

  int get _placed => _counts.fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    _counts = List.filled(_parts, 0);
  }

  @override
  void didUpdateWidget(covariant DragPartitionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _counts = List.filled(_parts, 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  void _report() {
    if (_placed == 0) {
      widget.onValueChanged('');
      return;
    }
    widget.onValueChanged(_counts.join('+'));
  }

  void _addToBox(int index) {
    if (_placed >= _total) return;
    setState(() => _counts[index]++);
    _report();
  }

  void _removeFromBox(int index) {
    if (_counts[index] == 0) return;
    setState(() => _counts[index]--);
    _report();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$_placed von $_total',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < _total; i++)
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _placed ? Colors.indigo : Colors.transparent,
                  border: Border.all(
                    color: i < _placed ? Colors.indigo : Colors.blueGrey,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [for (var i = 0; i < _parts; i++) _box(i)],
        ),
      ],
    );
  }

  Widget _box(int index) {
    final label = _boxLabels.length > index ? _boxLabels[index] : '';
    final labelDe = label.isNotEmpty ? label : 'Kasten ${index + 1}';
    final count = _counts[index];
    return Container(
      width: 110,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: count > 0 ? Colors.indigo : Colors.black45,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
        color: count > 0 ? Colors.indigo.shade50 : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Semantics(
            button: true,
            label: '$labelDe zählt $count',
            excludeSemantics: true,
            child: GestureDetector(
              key: ValueKey('box-counters-$index'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _removeFromBox(index),
              child: SizedBox(
                height: 44,
                width: double.infinity,
                child: Center(
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: count > 0 ? Colors.indigo.shade800 : Colors.black38,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: '$labelDe hinzufügen',
            excludeSemantics: true,
            child: GestureDetector(
              key: ValueKey('box-add-$index'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _addToBox(index),
              child: Container(
                height: 44,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, size: 28, color: Colors.indigo),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
