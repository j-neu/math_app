import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

/// A widget that displays the "Find Missing Cards" challenge for levels 2, 3, and 4.
///
/// This widget is now stateless from a problem-generation perspective. It receives
/// the numbers to hide (`missingNumbers`) from its parent and invokes a callback
/// when the user submits an answer.
class OrderCardsLevel2Widget extends StatefulWidget {
  final List<int> missingNumbers;
  final Function(bool isCorrect) onCompleted;

  const OrderCardsLevel2Widget({
    super.key,
    required this.missingNumbers,
    required this.onCompleted,
  });

  @override
  State<OrderCardsLevel2Widget> createState() => _OrderCardsLevel2WidgetState();
}

class _OrderCardsLevel2WidgetState extends State<OrderCardsLevel2Widget> {
  final Map<int, TextEditingController> _controllers = {};
  String? _feedbackMessage;
  Color _feedbackColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _createControllers();
  }

  @override
  void didUpdateWidget(OrderCardsLevel2Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the missing numbers change, we have a new problem.
    // We need to recreate the controllers.
    if (!const ListEquality().equals(widget.missingNumbers, oldWidget.missingNumbers)) {
      _clearControllers();
      _createControllers();
      setState(() {
        _feedbackMessage = null;
      });
    }
  }

  void _createControllers() {
    for (var number in widget.missingNumbers) {
      _controllers[number] = TextEditingController();
    }
  }

  void _clearControllers() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  @override
  void dispose() {
    _clearControllers();
    super.dispose();
  }

  void _checkAnswer() {
    bool allCorrect = true;
    if (widget.missingNumbers.isEmpty) {
      widget.onCompleted(true);
      return;
    }
    
    for (var number in widget.missingNumbers) {
      final text = _controllers[number]?.text.trim();
      final userAnswer = int.tryParse(text ?? '');

      if (userAnswer != number) {
        allCorrect = false;
        break;
      }
    }

    if (!allCorrect) {
      setState(() {
        _feedbackMessage = 'Not quite! Look at the neighbors of the empty spots.';
        _feedbackColor = Colors.orange;
      });
      // Vibrate or shake animation can be triggered here
    }

    // The coordinator handles correct feedback and moving to the next problem.
    widget.onCompleted(allCorrect);
    
    if(allCorrect) {
        // Clear inputs for the next problem
        for (var controller in _controllers.values) {
            controller.clear();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (_feedbackMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _feedbackMessage!,
                style: TextStyle(
                  fontSize: 18,
                  color: _feedbackColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 20),
          _buildRow(List.generate(10, (i) => i + 1)),
          const SizedBox(height: 16),
          _buildRow(List.generate(10, (i) => i + 11)),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _checkAnswer,
            icon: const Icon(Icons.check_circle),
            label: const Text('Check Answer'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<int> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: numbers.map((number) {
        return Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: widget.missingNumbers.contains(number)
                ? _buildGapCard(number)
                : _buildCard(number),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCard(int number) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 30,
        maxWidth: 50,
        minHeight: 50,
        maxHeight: 65,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            number.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGapCard(int number) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 30,
        maxWidth: 50,
        minHeight: 50,
        maxHeight: 65,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange, width: 3),
      ),
      child: Center(
        child: SizedBox(
          width: 35,
          child: TextField(
            controller: _controllers[number],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              hintText: '?',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}
