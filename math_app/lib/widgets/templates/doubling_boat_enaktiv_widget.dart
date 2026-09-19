import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../common/rechenschiffchen_widget.dart';

/// Custom-widget template for the registry key `"doubling_boat_enaktiv"`
/// (double_crossing_10, Level 1/enaktiv). Ported from the old engine's
/// `DoublingBoatLevel1Widget` (math_app/lib/widgets/
/// doubling_boat_level1_widget.dart) -- that file and its parent exercise
/// are untouched; this is a fresh copy with an adapted contract, not a
/// refactor of the original.
///
/// The child taps the bottom row of the Rechenschiffchen to place counters
/// matching the top row, then -- since every target in this skill's range
/// crosses a ten -- answers two internally-gated structural questions (how
/// many in the highlighted tens block, how many in the remainder) before
/// reporting the final total. The structural steps stay internally gated
/// exactly like the original; only the final total is reported live via
/// [onValueChanged] for central grading by [TemplateEvaluator].
class DoublingBoatEnaktivWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const DoublingBoatEnaktivWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  State<DoublingBoatEnaktivWidget> createState() =>
      _DoublingBoatEnaktivWidgetState();
}

enum _Step { filling, checkTens, checkOnes, checkTotal }

class _DoublingBoatEnaktivWidgetState
    extends State<DoublingBoatEnaktivWidget> {
  _Step _step = _Step.filling;
  int _bottomCount = 0;
  final TextEditingController _stepController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.black;

  int get _target => (widget.problem.display['target'] as num).toInt();

  @override
  void didUpdateWidget(covariant DoublingBoatEnaktivWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _step = _Step.filling;
      _bottomCount = 0;
      _stepController.clear();
      _totalController.clear();
      _feedbackMessage = '';
    });
    widget.onValueChanged('');
  }

  void _handleSlotTap(int row, int col, bool isActive) {
    if (_step != _Step.filling || row != 1) return;
    setState(() {
      if (col == _bottomCount) {
        _bottomCount++;
      } else if (col == _bottomCount - 1) {
        _bottomCount--;
      }
    });
    if (_bottomCount == _target) {
      setState(() {
        _step = _target > 5 ? _Step.checkTens : _Step.checkTotal;
      });
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
          _feedbackMessage = 'Schau auf den roten Rahmen. 5 + 5 = ?';
          _feedbackColor = Colors.orange;
          _stepController.clear();
        });
      }
    } else if (_step == _Step.checkOnes) {
      final remainder = (_target - 5) * 2;
      if (input == remainder) {
        setState(() {
          _step = _Step.checkTotal;
          _feedbackMessage = 'Super! Wie viele insgesamt?';
          _feedbackColor = Colors.green;
          _stepController.clear();
        });
      } else {
        setState(() {
          _feedbackMessage =
              'Schau auf den roten Rahmen. $remainder Plättchen.';
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
                bottomCount: _bottomCount,
                onSlotTap: _handleSlotTap,
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
          child: switch (_step) {
            _Step.filling => const SizedBox.shrink(),
            _Step.checkTotal => _buildFinalAnswerField(),
            _ => _buildStepInput(),
          },
        ),
      ],
    );
  }

  String _instruction() {
    if (_feedbackMessage.isNotEmpty) return _feedbackMessage;
    switch (_step) {
      case _Step.filling:
        return 'Verdopple! Lege genauso viele blaue Plättchen.';
      case _Step.checkTens:
        return 'Wie viele Plättchen sind im roten Rahmen?';
      case _Step.checkOnes:
        return 'Wie viele Plättchen sind hier im roten Rahmen?';
      case _Step.checkTotal:
        return 'Wie viele Plättchen sind es insgesamt?';
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
