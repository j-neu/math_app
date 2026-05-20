import 'package:flutter/material.dart';

class DoublingMirrorLevel3Widget extends StatefulWidget {
  final int targetCount;
  final Function(bool) onComplete;

  const DoublingMirrorLevel3Widget({
    Key? key,
    required this.targetCount,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<DoublingMirrorLevel3Widget> createState() => _DoublingMirrorLevel3WidgetState();
}

class _DoublingMirrorLevel3WidgetState extends State<DoublingMirrorLevel3Widget> {
  final TextEditingController _controller = TextEditingController();
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.black;

  @override
  void didUpdateWidget(DoublingMirrorLevel3Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetCount != widget.targetCount) {
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _controller.clear();
      _feedbackMessage = '';
    });
  }

  void _checkInput() {
    final input = int.tryParse(_controller.text);
    if (input == null) return;

    final total = widget.targetCount * 2;
    if (input == total) {
       setState(() {
         _feedbackMessage = 'Richtig! Das Doppelte von ${widget.targetCount} ist $total.';
         _feedbackColor = Colors.green;
       });
       Future.delayed(const Duration(seconds: 1), () {
         widget.onComplete(true);
       });
    } else {
      setState(() {
        _feedbackMessage = 'Fast! Stell dir die Punkte vor...';
        _feedbackColor = Colors.orange;
        _controller.clear();
      });
      // Maybe show hint after failure? "4 + 4 = ?"
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Stell dir vor:',
          style: TextStyle(fontSize: 24, color: Colors.grey.shade600),
        ),
        SizedBox(height: 20),
        
        // Number Card
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
            ],
            border: Border.all(color: Colors.blue.shade200, width: 2),
          ),
          child: Center(
            child: Text(
              '${widget.targetCount}',
              style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        ),
        
        SizedBox(height: 40),
        
        Text(
          'Was ist das Doppelte?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        
        if (_feedbackMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _feedbackMessage,
              style: TextStyle(fontSize: 20, color: _feedbackColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          
        SizedBox(height: 20),
        
        // Input
        Container(
          width: 200,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: '?',
                  ),
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  onSubmitted: (_) => _checkInput(),
                  autofocus: true,
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: _checkInput,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(16),
                  shape: CircleBorder(),
                  backgroundColor: Colors.green,
                ),
                child: Icon(Icons.check, size: 32),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
