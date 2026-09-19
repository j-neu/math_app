import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Custom-widget template for the registry key `"doubling_tens_ikonisch"`
/// (double_decade, Level 2/ikonisch). Ported from the old engine's
/// `DoublingTensLevel2Widget`; that file is untouched. The child drags
/// ten-strips into a drop zone until it matches the target's tens count,
/// then reports the resulting number. The original asked for tens-count
/// and ones-count as two separate self-graded fields; this port collapses
/// that into a single live-reported field for the full doubled number,
/// consistent with every other skill in the `double` family.
class DoublingTensIkonischWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const DoublingTensIkonischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  State<DoublingTensIkonischWidget> createState() =>
      _DoublingTensIkonischWidgetState();
}

class _DoublingTensIkonischWidgetState
    extends State<DoublingTensIkonischWidget> {
  int _droppedTens = 0;
  bool _readyForInput = false;
  final TextEditingController _totalController = TextEditingController();

  int get _target => (widget.problem.display['target'] as num).toInt();
  int get _tensCount => _target ~/ 10;

  @override
  void didUpdateWidget(covariant DoublingTensIkonischWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      setState(() {
        _droppedTens = 0;
        _readyForInput = false;
        _totalController.clear();
      });
      widget.onValueChanged('');
    }
  }

  void _onStripDropped() {
    setState(() {
      _droppedTens++;
      if (_droppedTens == _tensCount) {
        _readyForInput = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _readyForInput
                ? 'Wie groß ist die Zahl jetzt?'
                : 'Lege genauso viele rote Zehnerstreifen.',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                  ),
                  child: Center(
                    child: _buildTenStrips(_tensCount, Colors.blue),
                  ),
                ),
              ),
              const VerticalDivider(),
              Expanded(
                child: DragTarget<int>(
                  onWillAccept: (data) => _droppedTens < _tensCount,
                  onAccept: (data) => _onStripDropped(),
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: candidateData.isNotEmpty
                              ? Colors.blue
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: _buildTenStrips(_droppedTens, Colors.red),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 140,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Center(
            child: _readyForInput
                ? SizedBox(
                    width: 200,
                    child: TextField(
                      key: const ValueKey('final-answer'),
                      controller: _totalController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '?',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      onChanged: widget.onValueChanged,
                      onSubmitted: (_) => widget.onSubmit?.call(),
                    ),
                  )
                : Draggable<int>(
                    data: 1,
                    feedback:
                        Opacity(opacity: 0.7, child: _TenStrip(color: Colors.red)),
                    childWhenDragging: _TenStrip(color: Colors.red),
                    child: _TenStrip(color: Colors.red),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTenStrips(int count, Color color) => Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: List.generate(count, (index) => _TenStrip(color: color)),
      );
}

class _TenStrip extends StatelessWidget {
  final Color color;

  const _TenStrip({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 100,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: List.generate(
          10,
          (index) => Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: Colors.black12, width: 1)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
