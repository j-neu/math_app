import 'package:flutter/material.dart';
import 'dart:math';

class TensCalculationLevel3Widget extends StatefulWidget {
  final Function(bool) onComplete;

  const TensCalculationLevel3Widget({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<TensCalculationLevel3Widget> createState() => _TensCalculationLevel3WidgetState();
}

class _TensCalculationLevel3WidgetState extends State<TensCalculationLevel3Widget> {
  late int _tensA;
  late int _tensB;
  
  final TextEditingController _tensAController = TextEditingController();
  final TextEditingController _tensBController = TextEditingController();
  final TextEditingController _tensSumController = TextEditingController();
  final TextEditingController _finalResultController = TextEditingController();
  
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _generateProblem();
  }

  void _generateProblem() {
    final random = Random();
    _tensA = 1 + random.nextInt(5); 
    _tensB = 1 + random.nextInt(9 - _tensA); 
    
    _tensAController.clear();
    _tensBController.clear();
    _tensSumController.clear();
    _finalResultController.clear();
    setState(() {
      _feedbackMessage = '';
    });
  }

  void _checkAnswer() {
    final inputA = int.tryParse(_tensAController.text);
    final inputB = int.tryParse(_tensBController.text);
    final inputSum = int.tryParse(_tensSumController.text);
    final inputFinal = int.tryParse(_finalResultController.text);

    if (inputA == null || inputB == null || inputSum == null || inputFinal == null) return;

    final correctSum = _tensA + _tensB;
    final correctFinal = correctSum * 10;

    if (inputA == _tensA && inputB == _tensB && inputSum == correctSum && inputFinal == correctFinal) {
      setState(() {
        _feedbackMessage = 'Super!';
        _feedbackColor = Colors.green;
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        widget.onComplete(true);
        _generateProblem();
      });
    } else {
      setState(() {
        _feedbackMessage = 'Überprüfe deine Eingaben.';
        _feedbackColor = Colors.orange;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Text(
              '${_tensA}0 + ${_tensB}0',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
          ),
          
          // Step 1: Translate to Tens
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                const Text('Rechne mit Zehnern:', style: TextStyle(fontSize: 16, color: Colors.blue)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSmallInput(_tensAController),
                    const Text(' Z  +  ', style: TextStyle(fontSize: 20)),
                    _buildSmallInput(_tensBController),
                    const Text(' Z  =  ', style: TextStyle(fontSize: 20)),
                    _buildSmallInput(_tensSumController),
                    const Text(' Z', style: TextStyle(fontSize: 20)),
                  ],
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Icon(Icons.arrow_downward, size: 32, color: Colors.grey),
          ),

          // Step 2: Final Result
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${_tensA}0 + ${_tensB}0 = ', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _finalResultController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.all(8),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _checkAnswer(),
                  ),
                ),
              ],
            ),
          ),

          if (_feedbackMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _feedbackMessage,
                style: TextStyle(fontSize: 18, color: _feedbackColor, fontWeight: FontWeight.bold),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: _checkAnswer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: const Text('Prüfen', style: TextStyle(fontSize: 20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInput(TextEditingController controller) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.all(8),
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}