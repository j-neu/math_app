import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../common/rechenschiffchen_widget.dart';

/// Custom-widget template for the registry key `"doubling_boat_ikonisch"`
/// (double_crossing_10, Level 2/ikonisch). Ported from the old engine's
/// `DoublingBoatLevel2Widget`; that file is untouched. The bottom row stays
/// covered by a cloth for the whole level -- the child answers the same
/// structural questions as Level 1 (tens block, then remainder) purely
/// from the visible top row and imagination, then reports the total.
///
/// The original revealed the covered row as a reward once its own
/// self-graded total was correct. That mechanism doesn't fit here: the
/// final total is reported live via [onValueChanged] and graded centrally,
/// so the widget itself never learns whether it was correct. The cloth
/// therefore stays on for the whole level -- which is exactly what "partial
/// view" (as opposed to Level 1's fully visible action) is meant to test.
class DoublingBoatIkonischWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const DoublingBoatIkonischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  State<DoublingBoatIkonischWidget> createState() =>
      _DoublingBoatIkonischWidgetState();
}

enum _Step { checkTens, checkOnes, checkTotal }

class _DoublingBoatIkonischWidgetState
    extends State<DoublingBoatIkonischWidget> {
  late _Step _step;
  final TextEditingController _stepController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.black;

  int get _target => (widget.problem.display['target'] as num).toInt();

  @override
  void initState() {
    super.initState();
    _step = _target > 5 ? _Step.checkTens : _Step.checkTotal;
  }

  @override
  void didUpdateWidget(covariant DoublingBoatIkonischWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      setState(() {
        _step = _target > 5 ? _Step.checkTens : _Step.checkTotal;
        _stepController.clear();
        _totalController.clear();
        _feedbackMessage = '';
      });
      widget.onValueChanged('');
    }
  }

  void _checkStepInput() {
    final input = int.tryParse(_stepController.text);
    if (input == null) return;
    if (_step == _Step.checkTens) {
      if (input == 10) {
        setState(() {
          _step = _Step.checkOnes;
          _feedbackMessage = 'Richtig! Und der Rest?';
          _feedbackColor = Colors.green;
          _stepController.clear();
        });
      } else {
        setState(() {
          _feedbackMessage = 'Verdopple die Fünfen. 5 + 5 = ?';
          _feedbackColor = Colors.orange;
          _stepController.clear();
        });
      }
    } else if (_step == _Step.checkOnes) {
      final remainder = (_target - 5) * 2;
      if (input == remainder) {
        setState(() {
          _step = _Step.checkTotal;
          _feedbackMessage = 'Super! Wie viele zusammen?';
          _feedbackColor = Colors.green;
          _stepController.clear();
        });
      } else {
        setState(() {
          _feedbackMessage =
              'Verdopple den Rest. ${_target - 5} + ${_target - 5} = ?';
          _feedbackColor = Colors.orange;
          _stepController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _instruction(),
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: RechenschiffchenWidget(
                topCount: _target,
                bottomCount: 0,
                coverBottom: true,
                highlightTensBlock: _step == _Step.checkTens,
                highlightOnesBlock: _step == _Step.checkOnes,
              ),
            ),
          ),
        ),
        Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: _step == _Step.checkTotal
              ? _buildFinalAnswerField()
              : _buildStepInput(),
        ),
      ],
    );
  }

  String _instruction() {
    if (_feedbackMessage.isNotEmpty) return _feedbackMessage;
    switch (_step) {
      case _Step.checkTens:
        return 'Stell dir die blauen Plättchen vor. Wie viele im roten Rahmen?';
      case _Step.checkOnes:
        return 'Und wie viele hier im roten Rahmen?';
      case _Step.checkTotal:
        return 'Wie viele sind es zusammen?';
    }
  }

  Widget _buildStepInput() => Row(
        children: [
          Expanded(
            child: TextField(
              controller: _stepController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '?',
                filled: true,
                fillColor: Colors.white,
              ),
              style:
                  const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              onSubmitted: (_) => _checkStepInput(),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _checkStepInput,
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
