import 'package:flutter/material.dart';

class DoublingTensLevel2Widget extends StatefulWidget {
  final int targetTens;
  final Function(bool) onComplete;

  const DoublingTensLevel2Widget({
    Key? key,
    required this.targetTens,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<DoublingTensLevel2Widget> createState() => _DoublingTensLevel2WidgetState();
}

class _DoublingTensLevel2WidgetState extends State<DoublingTensLevel2Widget> {
  // Steps:
  // 1: Drag 10-strips to match target (make pairs)
  // 2: Input Zehner count AND Einer count
  
  int _currentRightTens = 0;
  
  final TextEditingController _tensController = TextEditingController();
  final TextEditingController _onesController = TextEditingController();
  
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.black;
  bool _readyForInput = false;

  @override
  void didUpdateWidget(DoublingTensLevel2Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetTens != widget.targetTens) {
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _currentRightTens = 0;
      _tensController.clear();
      _onesController.clear();
      _feedbackMessage = '';
      _readyForInput = false;
    });
  }

  void _checkInput() {
    final tensInput = int.tryParse(_tensController.text);
    final onesInput = int.tryParse(_onesController.text);
    
    if (tensInput == null || onesInput == null) return;
    
    final totalTens = widget.targetTens * 2;
    final totalOnes = totalTens * 10;
    
    if (tensInput == totalTens && onesInput == totalOnes) {
      widget.onComplete(true);
    } else {
      setState(() {
        if (tensInput != totalTens) {
           _feedbackMessage = 'Die Anzahl der Zehner stimmt nicht.';
        } else if (onesInput != totalOnes) {
           _feedbackMessage = 'Die Anzahl der Einer stimmt nicht. (1 Zehner = 10 Einer)';
        }
        _feedbackColor = Colors.orange;
        // Don't clear to let them fix it
      });
    }
  }
  
  void _onStripDropped() {
    setState(() {
      _currentRightTens++;
      if (_currentRightTens == widget.targetTens) {
        _readyForInput = true;
        _feedbackMessage = 'Super! Jetzt füll die Lücken aus.';
        _feedbackColor = Colors.green;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Instruction / Feedback
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

        Expanded(
          child: Row(
            children: [
              // Left Side (Target)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                  ),
                  child: Center(
                    child: _buildTenStrips(widget.targetTens, Colors.blue),
                  ),
                ),
              ),
              
              const VerticalDivider(),

              // Right Side (Drop Zone)
              Expanded(
                child: DragTarget<int>(
                  onWillAccept: (data) => _currentRightTens < widget.targetTens,
                  onAccept: (data) => _onStripDropped(),
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: candidateData.isNotEmpty ? Colors.blue : Colors.grey.shade300, 
                          width: 2
                        ),
                      ),
                      child: Center(
                        child: _buildTenStrips(_currentRightTens, Colors.red),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Bottom Area: Supply & Input
        Container(
          height: 160,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: _readyForInput 
            ? _buildInputArea() 
            : _buildDragSupply(),
        ),
      ],
    );
  }

  String _getInstructionText() {
    if (_feedbackMessage.isNotEmpty) return _feedbackMessage;
    if (!_readyForInput) return 'Lege genauso viele rote Zehnerstreifen.';
    return 'Wie viele Zehner und wie viele Einer sind es?';
  }

  Widget _buildTenStrips(int count, Color color) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(count, (index) => _TenStrip(color: color)),
    );
  }
  
  Widget _buildDragSupply() {
     return Center(
      child: Draggable<int>(
        data: 1,
        feedback: Opacity(opacity: 0.7, child: _TenStrip(color: Colors.red)),
        childWhenDragging: _TenStrip(color: Colors.red),
        child: _TenStrip(color: Colors.red),
      ),
    );
  }

  Widget _buildInputArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 70,
              child: TextField(
                controller: _tensController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Zehner  =  ', style: TextStyle(fontSize: 20)),
            SizedBox(
              width: 90,
              child: TextField(
                controller: _onesController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Einer', style: TextStyle(fontSize: 20)),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _checkInput,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            backgroundColor: Colors.green,
          ),
          child: const Text('OK', style: TextStyle(fontSize: 24)),
        ),
      ],
    );
  }
}

class _TenStrip extends StatelessWidget {
  final Color color;
  
  const _TenStrip({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 100, // Slightly smaller for drag
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: List.generate(10, (index) => Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black12, width: 1)),
            ),
          ),
        )),
      ),
    );
  }
}
