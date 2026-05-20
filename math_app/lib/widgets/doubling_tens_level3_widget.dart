import 'package:flutter/material.dart';

class DoublingTensLevel3Widget extends StatefulWidget {
  final int targetTens;
  final Function(bool) onComplete;

  const DoublingTensLevel3Widget({
    Key? key,
    required this.targetTens,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<DoublingTensLevel3Widget> createState() => _DoublingTensLevel3WidgetState();
}

class _DoublingTensLevel3WidgetState extends State<DoublingTensLevel3Widget> {
  final TextEditingController _controller = TextEditingController();
  String _feedbackMessage = '';
  
  @override
  void didUpdateWidget(DoublingTensLevel3Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetTens != widget.targetTens) {
      _controller.clear();
      _feedbackMessage = '';
    }
  }

  void _checkInput() {
    final input = int.tryParse(_controller.text);
    if (input == null) return;
    
    final correctTotal = widget.targetTens * 20; // e.g. 3 tens -> 60
    
    if (input == correctTotal) {
      widget.onComplete(true);
    } else {
      setState(() {
        _feedbackMessage = 'Fast! Verdopple ${widget.targetTens} Zehner.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Verdopple:',
          style: TextStyle(fontSize: 24, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 24),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${widget.targetTens} Zehner',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),
        
        const SizedBox(height: 48),
        
        Text(
          'Ergebnis:',
          style: TextStyle(fontSize: 24, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 140,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  hintText: '?',
                ),
                onSubmitted: (_) => _checkInput(),
              ),
            ),
          ],
        ),
        
        if (_feedbackMessage.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            _feedbackMessage,
            style: const TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ],
        
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _checkInput,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            backgroundColor: Colors.green,
          ),
          child: const Text('OK', style: TextStyle(fontSize: 24)),
        ),
      ],
    );
  }
}
