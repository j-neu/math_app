import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Custom-widget template for the registry key `"doubling_mirror_enaktiv"`
/// (verdoppeln-halbieren.ZR10, Level 1/enaktiv). Ported from the old
/// engine's `DoublingMirrorLevel1Widget` (math_app/lib/widgets/
/// doubling_mirror_level1_widget.dart) -- that file is untouched; this is a
/// fresh copy with an adapted contract, not a refactor of the original.
///
/// The child counts the blue dots on the left, drags matching red dots to
/// the right one at a time, then reports the combined total. Steps 0
/// (verify the left count) and 1 (drag to match) stay internally gated
/// exactly like the original -- they are scaffolding, not the graded
/// answer. Step 2 (the final total) is reported live via [onValueChanged]
/// instead of self-grading with its own button; the practice screen's one
/// generic submit button and [TemplateEvaluator] decide correctness against
/// `problem.expected`.
class DoublingMirrorEnaktivWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const DoublingMirrorEnaktivWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  State<DoublingMirrorEnaktivWidget> createState() =>
      _DoublingMirrorEnaktivWidgetState();
}

class _DoublingMirrorEnaktivWidgetState
    extends State<DoublingMirrorEnaktivWidget> {
  // Steps:
  // 0: Count Left (internally verified)
  // 1: Drag Right (internally verified)
  // 2: Count Total (reported via onValueChanged, graded centrally)
  int _step = 0;

  int _rightCount = 0;
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.black;

  int get _targetCount => (widget.problem.display['target'] as num).toInt();

  @override
  void didUpdateWidget(covariant DoublingMirrorEnaktivWidget oldWidget) {
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
      _totalController.clear();
      _feedbackMessage = '';
    });
    widget.onValueChanged('');
  }

  void _checkLeftCount() {
    final input = int.tryParse(_leftController.text);
    if (input == null) return;

    if (input == _targetCount) {
      setState(() {
        _step = 1;
        _feedbackMessage = 'Richtig! Jetzt verdopple rechts.';
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
                    child: _buildDotGrid(_targetCount, Colors.blue),
                  ),
                ),
              ),
              Container(width: 4, color: Colors.grey.shade400),
              Expanded(
                child: DragTarget<int>(
                  onWillAccept: (data) => _step == 1,
                  onAccept: (data) {
                    setState(() {
                      _rightCount++;
                      if (_rightCount == _targetCount) {
                        _step = 2;
                        _feedbackMessage = 'Super! Wie viele sind es zusammen?';
                        _feedbackColor = Colors.green;
                      }
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
            0 => _buildLeftCountInput(),
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
        return 'Zieh genauso viele rote Punkte nach rechts!';
      default:
        return 'Wie viele Punkte sind es jetzt zusammen?';
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

  Widget _buildDragSource() => Center(
        child: Draggable<int>(
          data: 1,
          feedback: _buildDot(Colors.red.withOpacity(0.8)),
          childWhenDragging: _buildDot(Colors.red),
          child: _buildDot(Colors.red),
        ),
      );

  Widget _buildLeftCountInput() => Row(
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
              onSubmitted: (_) => _checkLeftCount(),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _checkLeftCount,
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
        controller: _totalController,
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
