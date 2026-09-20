import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Custom-widget template for the registry key `"doubling_tens_enaktiv"`
/// (double_decade, Level 1/enaktiv). Ported from the old engine's
/// `DoublingTensLevel1Widget` (math_app/lib/widgets/
/// doubling_tens_level1_widget.dart) -- that file is untouched. Shows
/// [target] (a decade number, e.g. 30) as ten-strips, the child confirms
/// the reading, presses a mirror button to double the strips, then reports
/// the resulting number. Unlike the original, which asked for a raw
/// "tens count" at every step, every step here asks for the actual decade
/// number -- see this task's rationale in the plan. Only the final total
/// is reported live via [onValueChanged] for central grading.
class DoublingTensEnaktivWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const DoublingTensEnaktivWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  State<DoublingTensEnaktivWidget> createState() =>
      _DoublingTensEnaktivWidgetState();
}

class _DoublingTensEnaktivWidgetState extends State<DoublingTensEnaktivWidget>
    with SingleTickerProviderStateMixin {
  // Steps: 0 confirm reading (internal), 1 press mirror (internal), 2 report total.
  int _step = 0;
  bool _isMirrored = false;
  final TextEditingController _stepController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.black;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  int get _target => (widget.problem.display['target'] as num).toInt();
  int get _tensCount => _target ~/ 10;

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
  void didUpdateWidget(covariant DoublingTensEnaktivWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _step = 0;
      _isMirrored = false;
      _stepController.clear();
      _totalController.clear();
      _feedbackMessage = '';
      _animController.reset();
    });
    widget.onValueChanged('');
  }

  void _checkStepInput() {
    final input = int.tryParse(_stepController.text);
    if (input == null) return;
    if (input == _target) {
      setState(() {
        _step = 1;
        _feedbackMessage = 'Richtig! Drücke den Spiegel-Knopf.';
        _feedbackColor = Colors.green;
        _stepController.clear();
      });
    } else {
      setState(() {
        _feedbackMessage = 'Fast! Zähle die Zehnerstreifen genau.';
        _feedbackColor = Colors.orange;
        _stepController.clear();
      });
    }
  }

  void _activateMirror() {
    setState(() {
      _isMirrored = true;
      _step = 2;
      _feedbackMessage = 'Verdoppelt! Wie groß ist die Zahl jetzt?';
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
                        child: _buildTenStrips(_tensCount, Colors.blue),
                      ),
                    ),
                  ),
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
                        child: _isMirrored
                            ? ScaleTransition(
                                scale: _scaleAnimation,
                                child: _buildTenStrips(_tensCount,
                                    Colors.blue.withValues(alpha: 0.7)),
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
                        onPressed: _activateMirror,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(24),
                          backgroundColor: Colors.purple,
                        ),
                        child: const Icon(Icons.compare_arrows,
                            size: 32, color: Colors.white),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.compare_arrows,
                            color: Colors.grey),
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
            0 => _buildStepInput(),
            1 => const Center(
                child: Text('Drücke den Knopf in der Mitte!',
                    style: TextStyle(fontSize: 18)),
              ),
            _ => _buildFinalAnswerField(),
          },
        ),
      ],
    );
  }

  String _instruction() {
    if (_feedbackMessage.isNotEmpty) return _feedbackMessage;
    switch (_step) {
      case 0:
        return 'Wie groß ist diese Zehnerzahl?';
      case 1:
        return 'Drücke den Spiegel-Knopf!';
      default:
        return 'Wie groß ist die Zahl jetzt?';
    }
  }

  Widget _buildTenStrips(int count, Color color) => Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: List.generate(count, (index) => _TenStrip(color: color)),
      );

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

class _TenStrip extends StatelessWidget {
  final Color color;

  const _TenStrip({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 120,
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
