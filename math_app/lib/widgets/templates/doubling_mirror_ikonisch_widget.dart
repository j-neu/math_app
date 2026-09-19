import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Custom-widget template for the registry key `"doubling_mirror_ikonisch"`
/// (verdoppeln-halbieren.ZR10, Level 2/ikonisch). Ported from the old
/// engine's `DoublingMirrorLevel2Widget`; that file is untouched. The child
/// counts the blue dots, presses a mirror button that animates a matching
/// red group into place, then reports the total -- reported live via
/// [onValueChanged], graded centrally like every other custom_widget.
class DoublingMirrorIkonischWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const DoublingMirrorIkonischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  State<DoublingMirrorIkonischWidget> createState() =>
      _DoublingMirrorIkonischWidgetState();
}

class _DoublingMirrorIkonischWidgetState
    extends State<DoublingMirrorIkonischWidget>
    with SingleTickerProviderStateMixin {
  // Steps: 0 count left (internal), 1 press mirror (internal), 2 report total.
  int _step = 0;

  bool _isMirrored = false;
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.black;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  int get _targetCount => (widget.problem.display['target'] as num).toInt();

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
  void didUpdateWidget(covariant DoublingMirrorIkonischWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _step = 0;
      _isMirrored = false;
      _leftController.clear();
      _totalController.clear();
      _feedbackMessage = '';
      _animController.reset();
    });
    widget.onValueChanged('');
  }

  void _checkLeftCount() {
    final input = int.tryParse(_leftController.text);
    if (input == null) return;

    if (input == _targetCount) {
      setState(() {
        _step = 1;
        _feedbackMessage = 'Richtig! Drücke den Spiegel-Knopf.';
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

  void _activateMirror() {
    setState(() {
      _isMirrored = true;
      _step = 2;
      _feedbackMessage = 'Verdoppelt! Wie viele sind es jetzt?';
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
                        child: _buildDotGrid(_targetCount, Colors.blue),
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
                        child: _isMirrored
                            ? ScaleTransition(
                                scale: _scaleAnimation,
                                child: _buildDotGrid(_targetCount, Colors.red),
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
            0 => _buildLeftCountInput(),
            1 => const Center(
                child: Text('Drücke den Spiegel-Knopf in der Mitte!',
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
        return 'Drücke den Spiegel-Knopf!';
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
