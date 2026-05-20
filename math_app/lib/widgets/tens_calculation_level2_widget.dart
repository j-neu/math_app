import 'package:flutter/material.dart';
import 'dart:math';
import 'common/ten_strip_widget.dart';

class TensCalculationLevel2Widget extends StatefulWidget {
  final Function(bool) onComplete;

  const TensCalculationLevel2Widget({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<TensCalculationLevel2Widget> createState() => _TensCalculationLevel2WidgetState();
}

class _TensCalculationLevel2WidgetState extends State<TensCalculationLevel2Widget> {
  late int _totalTens;
  late int _subtractTens;
  late List<bool> _markedStrips;
  final TextEditingController _controller = TextEditingController();
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _generateProblem();
  }

  void _generateProblem() {
    final random = Random();
    _totalTens = 2 + random.nextInt(8); // 2-9
    _subtractTens = 1 + random.nextInt(_totalTens);

    _markedStrips = List.filled(_totalTens, false);
    _controller.clear();
    setState(() {
      _feedbackMessage = 'Streiche $_subtractTens Zehner durch!';
      _feedbackColor = Colors.blue;
    });
  }

  void _toggleStrip(int index) {
    setState(() {
      _markedStrips[index] = !_markedStrips[index];
    });
  }

  void _checkAnswer() {
    final input = int.tryParse(_controller.text);
    if (input == null) return;

    final correctTensLeft = _totalTens - _subtractTens;
    final markedCount = _markedStrips.where((m) => m).length;

    if (input == correctTensLeft) {
      if (markedCount == _subtractTens) {
        setState(() {
          _feedbackMessage = 'Richtig! $_totalTens Zehner - $_subtractTens Zehner = $correctTensLeft Zehner';
          _feedbackColor = Colors.green;
        });
        Future.delayed(const Duration(milliseconds: 1500), () {
          widget.onComplete(true);
          _generateProblem();
        });
      } else {
        setState(() {
          _feedbackMessage = 'Ergebnis stimmt, aber du musst $_subtractTens Zehner durchstreichen!';
          _feedbackColor = Colors.orange;
        });
      }
    } else {
      setState(() {
        _feedbackMessage = 'Das Ergebnis stimmt nicht. Zähle die übrigen Zehner.';
        _feedbackColor = Colors.orange;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '${_totalTens}0 - ${_subtractTens}0 = ?',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(_totalTens, (index) {
                return GestureDetector(
                  onTap: () => _toggleStrip(index),
                  child: TenStripWidget(
                    color: Colors.blue,
                    isMarked: _markedStrips[index],
                    width: 25,
                    height: 150,
                  ),
                );
              }),
            ),
          ),
        ),
        if (_feedbackMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _feedbackMessage,
              style: TextStyle(fontSize: 18, color: _feedbackColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Column(
            children: [
              const Text('Wie viele Zehner bleiben übrig?', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      onSubmitted: (_) => _checkAnswer(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('Zehner', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 24),
                  ElevatedButton(
                    onPressed: _checkAnswer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('OK', style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}