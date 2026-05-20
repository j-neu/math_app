import 'package:flutter/material.dart';
import 'dart:math';
import 'common/ten_strip_widget.dart';

class TensCalculationLevel1Widget extends StatefulWidget {
  final Function(bool) onComplete;

  const TensCalculationLevel1Widget({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<TensCalculationLevel1Widget> createState() => _TensCalculationLevel1WidgetState();
}

class _TensCalculationLevel1WidgetState extends State<TensCalculationLevel1Widget> {
  late int _tensA;
  late int _tensB;
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
    _tensA = 1 + random.nextInt(5); // 1-5
    _tensB = 1 + random.nextInt(9 - _tensA); // Sum <= 9
    
    _controller.clear();
    setState(() {
      _feedbackMessage = '';
    });
  }

  void _checkAnswer() {
    final input = int.tryParse(_controller.text);
    if (input == null) return;

    final correctTens = _tensA + _tensB;
    
    if (input == correctTens) {
      setState(() {
        _feedbackMessage = 'Richtig! $_tensA Zehner + $_tensB Zehner = $correctTens Zehner (${correctTens}0)';
        _feedbackColor = Colors.green;
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        widget.onComplete(true);
        _generateProblem();
      });
    } else {
      setState(() {
        _feedbackMessage = 'Versuche es nochmal. Zähle die Streifen.';
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
            '${_tensA}0 + ${_tensB}0 = ?',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildGroup(_tensA, Colors.blue),
              const SizedBox(width: 20),
              const Icon(Icons.add, size: 40),
              const SizedBox(width: 20),
              _buildGroup(_tensB, Colors.blue.shade300),
            ],
          ),
        ),
        if (_feedbackMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _feedbackMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: _feedbackColor, fontWeight: FontWeight.bold),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Column(
            children: [
              const Text('Wie viele Zehner?', style: TextStyle(fontSize: 18)),
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

  Widget _buildGroup(int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 4,
        direction: Axis.horizontal,
        children: List.generate(count, (index) => TenStripWidget(color: color, width: 15, height: 100)),
      ),
    );
  }
}