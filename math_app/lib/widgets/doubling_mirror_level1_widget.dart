import 'package:flutter/material.dart';

class DoublingMirrorLevel1Widget extends StatefulWidget {
  final int targetCount;
  final Function(bool) onComplete;

  const DoublingMirrorLevel1Widget({
    Key? key,
    required this.targetCount,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<DoublingMirrorLevel1Widget> createState() => _DoublingMirrorLevel1WidgetState();
}

class _DoublingMirrorLevel1WidgetState extends State<DoublingMirrorLevel1Widget> {
  // Steps: 
  // 0: Count Left (Verify)
  // 1: Drag Right
  // 2: Count Total (Verify)
  int _step = 0;
  
  int _rightCount = 0;
  final TextEditingController _controller = TextEditingController();
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.black;

  @override
  void didUpdateWidget(DoublingMirrorLevel1Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetCount != widget.targetCount) {
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _step = 0;
      _rightCount = 0;
      _controller.clear();
      _feedbackMessage = '';
    });
  }

  void _checkInput() {
    final input = int.tryParse(_controller.text);
    if (input == null) return;

    if (_step == 0) {
      // Step 0: Verify Left Count
      if (input == widget.targetCount) {
        setState(() {
          _step = 1;
          _feedbackMessage = 'Richtig! Jetzt verdopple rechts.';
          _feedbackColor = Colors.green;
          _controller.clear();
        });
      } else {
        setState(() {
          _feedbackMessage = 'Fast! Zähl nochmal!';
          _feedbackColor = Colors.orange;
          _controller.clear();
        });
      }
    } else if (_step == 2) {
      // Step 2: Verify Total Count
      final total = widget.targetCount * 2;
      if (input == total) {
        widget.onComplete(true);
      } else {
         setState(() {
          _feedbackMessage = 'Versuch es nochmal. Zähle alle Punkte.';
          _feedbackColor = Colors.orange;
          _controller.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Instruction / Feedback Area
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            _getInstructionText(),
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: _feedbackMessage.isNotEmpty ? _feedbackColor : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Mirror Area
        Expanded(
          child: Row(
            children: [
              // Left Side (Original)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                  ),
                  child: Center(
                    child: _buildDotGrid(widget.targetCount, Colors.blue),
                  ),
                ),
              ),
              
              // Mirror Line
              Container(
                width: 4,
                color: Colors.grey.shade400,
              ),

              // Right Side (Reflection/Drop Zone)
              Expanded(
                child: DragTarget<int>(
                  onWillAccept: (data) => _step == 1,
                  onAccept: (data) {
                    setState(() {
                      _rightCount++;
                      if (_rightCount == widget.targetCount) {
                        _step = 2; // Auto-advance to counting total when matched
                         _feedbackMessage = 'Super! Wie viele sind es zusammen?';
                         _feedbackColor = Colors.green;
                         // Force focus request might be needed here but setState rebuilds _buildNumpad which has autofocus
                      }
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _step == 1 ? Colors.blue : Colors.grey.shade300, 
                          width: 2
                        ),
                      ),
                      child: Center(
                        child: _buildDotGrid(_rightCount, Colors.red),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Interaction Area (Input or Drag Source)
        Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: _step == 1 
            ? _buildDragSource() 
            : _buildNumpad(),
        ),
      ],
    );
  }

  String _getInstructionText() {
    if (_feedbackMessage.isNotEmpty) return _feedbackMessage;
    
    switch (_step) {
      case 0: return 'Wie viele blaue Punkte siehst du?';
      case 1: return 'Zieh genauso viele rote Punkte nach rechts!';
      case 2: return 'Wie viele Punkte sind es jetzt zusammen?';
      default: return '';
    }
  }

  Widget _buildDotGrid(int count, Color color) {
    // Simple wrap layout for dots
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: List.generate(count, (index) => _buildDot(color)),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(1,1))
        ]
      ),
    );
  }

  Widget _buildDragSource() {
    // Only visible in step 1
    // "Unlimited" supply
    return Center(
      child: Draggable<int>(
        data: 1,
        feedback: _buildDot(Colors.red.withOpacity(0.8)),
        childWhenDragging: _buildDot(Colors.red), // Keep showing it (unlimited)
        child: _buildDot(Colors.red),
      ),
    );
  }
  
  Widget _buildNumpad() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            readOnly: false,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: '?',
              filled: true,
              fillColor: Colors.white,
            ),
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            onSubmitted: (_) => _checkInput(),
          ),
        ),
        SizedBox(width: 16),
        ElevatedButton(
          onPressed: _checkInput,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            backgroundColor: Colors.green,
          ),
          child: Text('OK', style: TextStyle(fontSize: 24)),
        ),
      ],
    );
  }
  
  // Actually, for the input field, relying on system keyboard is risky on mobile if it covers UI.
  // I'll make the text field focused and ensure it works, but a custom numpad would be better.
  // Given constraints, I'll stick to a simple TextField that opens keyboard.
}
