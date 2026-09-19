import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Custom-widget template for the registry key `"halving_mirror_enaktiv"`
/// (halve_zr10, Level 1/enaktiv). Mirrors `DoublingMirrorEnaktivWidget` in
/// reverse: the child starts with the full amount and splits it into two
/// equal piles instead of building up to a doubled total. Not a refactor of
/// the doubling widget -- a fresh copy with the loop bound and final
/// question inverted.
///
/// The child counts the blue dots on the left (the full amount), drags them
/// one at a time to the right pile, and stops once exactly half have moved
/// across. Steps 0 (verify the full count) and 1 (drag until half) stay
/// internally gated -- scaffolding, not the graded answer. Step 2 (how many
/// moved, i.e. the half) is reported live via [onValueChanged]; the practice
/// screen's generic submit button and [TemplateEvaluator] decide correctness
/// against `problem.expected`.
class HalvingMirrorEnaktivWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const HalvingMirrorEnaktivWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  State<HalvingMirrorEnaktivWidget> createState() =>
      _HalvingMirrorEnaktivWidgetState();
}

class _HalvingMirrorEnaktivWidgetState
    extends State<HalvingMirrorEnaktivWidget> {
  // Steps:
  // 0: Count Full (internally verified)
  // 1: Drag Right until half has moved (internally verified)
  // 2: Report Half (reported via onValueChanged, graded centrally)
  int _step = 0;

  int _rightCount = 0;
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _halfController = TextEditingController();
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.black;

  int get _fullCount => (widget.problem.display['full'] as num).toInt();

  @override
  void didUpdateWidget(covariant HalvingMirrorEnaktivWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _step = 0;
      _rightCount = 0;
      _leftController.clear();
      _halfController.clear();
      _feedbackMessage = '';
    });
    widget.onValueChanged('');
  }

  void _checkFullCount() {
    final input = int.tryParse(_leftController.text);
    if (input == null) return;

    if (input == _fullCount) {
      setState(() {
        _step = 1;
        _feedbackMessage = 'Richtig! Jetzt teile sie auf.';
        _feedbackColor = Colors.green;
        _leftController.clear();
      });
    } else {
      setState(() {
        _feedbackMessage = 'Fast! Zähl nochmal!';
        _feedbackColor = Colors.orange;
        _leftController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            _getInstructionText(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  _feedbackMessage.isNotEmpty ? _feedbackColor : Colors.black87,
            ),
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
                    child: _buildDotGrid(_fullCount - _rightCount, Colors.blue),
                  ),
                ),
              ),
              Container(width: 4, color: Colors.grey.shade400),
              Expanded(
                child: DragTarget<int>(
                  onWillAccept: (data) => _step == 1 && _rightCount < _fullCount,
                  onAccept: (data) {
                    setState(() {
                      _rightCount++;
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              _step == 1 ? Colors.blue : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: _buildDotGrid(_rightCount, Colors.red),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: switch (_step) {
            0 => _buildFullCountInput(),
            1 => _buildDragSource(),
            _ => _buildFinalAnswerField(),
          },
        ),
      ],
    );
  }

  String _getInstructionText() {
    if (_feedbackMessage.isNotEmpty) return _feedbackMessage;
    switch (_step) {
      case 0:
        return 'Wie viele blaue Punkte siehst du?';
      case 1:
        return 'Zieh die Hälfte der Punkte nach rechts!';
      default:
        return 'Wie viele hast du herübergezogen?';
    }
  }

  Widget _buildDotGrid(int count, Color color) => Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: List.generate(count, (index) => _buildDot(color)),
      );

  Widget _buildDot(Color color) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      );

  Widget _buildDragSource() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Draggable<int>(
            data: 1,
            feedback: _buildDot(Colors.red.withOpacity(0.8)),
            childWhenDragging: _buildDot(Colors.red),
            child: _buildDot(Colors.red),
          ),
          const SizedBox(width: 32),
          ElevatedButton(
            onPressed: _rightCount > 0 ? _confirmHalf : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.green,
            ),
            child: const Text('Fertig', style: TextStyle(fontSize: 24)),
          ),
        ],
      );

  void _confirmHalf() {
    setState(() {
      _step = 2;
      _feedbackMessage = 'Super! Wie viele hast du herübergezogen?';
      _feedbackColor = Colors.green;
    });
  }

  Widget _buildFullCountInput() => Row(
        children: [
          Expanded(
            child: TextField(
              controller: _leftController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '?',
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              onSubmitted: (_) => _checkFullCount(),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _checkFullCount,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.green,
            ),
            child: const Text('OK', style: TextStyle(fontSize: 24)),
          ),
        ],
      );

  Widget _buildFinalAnswerField() => TextField(
        key: const ValueKey('final-answer'),
        controller: _halfController,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: '?',
          filled: true,
          fillColor: Colors.white,
        ),
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        onChanged: widget.onValueChanged,
        onSubmitted: (_) => widget.onSubmit?.call(),
      );
}
