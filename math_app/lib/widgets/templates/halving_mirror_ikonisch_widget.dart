import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Custom-widget template for the registry key `"halving_mirror_ikonisch"`
/// (halve_zr10, Level 2/ikonisch). Mirrors `DoublingMirrorIkonischWidget` in
/// reverse. The child counts the full amount, presses a split button that
/// reveals a group showing half that amount, then reports how many are in
/// it -- reported live via [onValueChanged], graded centrally like every
/// other custom_widget.
class HalvingMirrorIkonischWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const HalvingMirrorIkonischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  State<HalvingMirrorIkonischWidget> createState() =>
      _HalvingMirrorIkonischWidgetState();
}

class _HalvingMirrorIkonischWidgetState
    extends State<HalvingMirrorIkonischWidget>
    with SingleTickerProviderStateMixin {
  // Steps: 0 count full (internal), 1 press split (internal), 2 report half.
  int _step = 0;

  bool _isSplit = false;
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _halfController = TextEditingController();
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.black;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  int get _fullCount => (widget.problem.display['full'] as num).toInt();
  int get _halfCount => _fullCount ~/ 2;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HalvingMirrorIkonischWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _step = 0;
      _isSplit = false;
      _leftController.clear();
      _halfController.clear();
      _feedbackMessage = '';
      _animController.reset();
    });
    widget.onValueChanged('');
  }

  void _checkFullCount() {
    final input = int.tryParse(_leftController.text);
    if (input == null) return;

    if (input == _fullCount) {
      setState(() {
        _step = 1;
        _feedbackMessage = 'Richtig! Drücke den Teilen-Knopf.';
        _feedbackColor = Colors.green;
        _leftController.clear();
      });
    } else {
      setState(() {
        _feedbackMessage = 'Fast! Versuch es nochmal!';
        _feedbackColor = Colors.orange;
        _leftController.clear();
      });
    }
  }

  void _activateSplit() {
    setState(() {
      _isSplit = true;
      _step = 2;
      _feedbackMessage = 'Geteilt! Wie viele sind es in einer Gruppe?';
      _feedbackColor = Colors.green;
    });
    _animController.forward();
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
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.blue.shade200, width: 2),
                      ),
                      child: Center(
                        child: _buildDotGrid(_fullCount, Colors.blue),
                      ),
                    ),
                  ),
                  Container(width: 4, color: Colors.transparent),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                      child: Center(
                        child: _isSplit
                            ? ScaleTransition(
                                scale: _scaleAnimation,
                                child: _buildDotGrid(_halfCount, Colors.red),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              Center(
                child: Container(
                  width: 4,
                  height: double.infinity,
                  color: Colors.grey.shade400,
                ),
              ),
              Center(
                child: _step == 1
                    ? ElevatedButton(
                        onPressed: _activateSplit,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(24),
                          backgroundColor: Colors.purple,
                        ),
                        child: const Icon(Icons.call_split,
                            size: 32, color: Colors.white),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call_split, color: Colors.grey),
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
            1 => const Center(
                child: Text('Drücke den Teilen-Knopf in der Mitte!',
                    style: TextStyle(fontSize: 18)),
              ),
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
        return 'Drücke den Teilen-Knopf!';
      default:
        return 'Wie viele sind es in einer Gruppe?';
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
