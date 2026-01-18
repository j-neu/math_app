import 'package:flutter/material.dart';

class DoublingMirrorLevel2Widget extends StatefulWidget {
  final int targetCount;
  final Function(bool) onComplete;

  const DoublingMirrorLevel2Widget({
    Key? key,
    required this.targetCount,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<DoublingMirrorLevel2Widget> createState() => _DoublingMirrorLevel2WidgetState();
}

class _DoublingMirrorLevel2WidgetState extends State<DoublingMirrorLevel2Widget> with SingleTickerProviderStateMixin {
  // Steps: 
  // 0: Count Left
  // 1: Press Mirror
  // 2: Count Total
  int _step = 0;
  
  bool _isMirrored = false;
  final TextEditingController _controller = TextEditingController();
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.black;
  
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DoublingMirrorLevel2Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetCount != widget.targetCount) {
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _step = 0;
      _isMirrored = false;
      _controller.clear();
      _feedbackMessage = '';
      _animController.reset();
    });
  }

  void _checkInput() {
    final input = int.tryParse(_controller.text);
    if (input == null) return;

    if (_step == 0) {
      if (input == widget.targetCount) {
        setState(() {
          _step = 1;
          _feedbackMessage = 'Richtig! Drücke den Spiegel-Knopf.';
          _feedbackColor = Colors.green;
          _controller.clear();
        });
      } else {
        setState(() {
          _feedbackMessage = 'Versuch es nochmal!';
          _feedbackColor = Colors.orange;
          _controller.clear();
        });
      }
    } else if (_step == 2) {
      final total = widget.targetCount * 2;
      if (input == total) {
        widget.onComplete(true);
      } else {
         setState(() {
          _feedbackMessage = 'Zähle alle Punkte zusammen.';
          _feedbackColor = Colors.orange;
          _controller.clear();
        });
      }
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
              color: _feedbackMessage.isNotEmpty ? _feedbackColor : Colors.black87,
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
                        border: Border.all(color: Colors.blue.shade200, width: 2),
                      ),
                      child: Center(
                        child: _buildDotGrid(widget.targetCount, Colors.blue),
                      ),
                    ),
                  ),
                  
                  Container(width: 4, color: Colors.transparent), // Spacer for mirror line

                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                      child: Center(
                        child: _isMirrored 
                          ? ScaleTransition(
                              scale: _scaleAnimation,
                              child: _buildDotGrid(widget.targetCount, Colors.red),
                            )
                          : null,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Mirror Line & Button
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
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(24),
                        backgroundColor: Colors.purple,
                      ),
                      child: Icon(Icons.compare_arrows, size: 32, color: Colors.white),
                    )
                  : Container(
                      width: 40, 
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.compare_arrows, color: Colors.grey),
                    ),
              ),
            ],
          ),
        ),

        Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: _step != 1 
            ? _buildInputArea()
            : Center(child: Text('Drücke den Knopf in der Mitte!', style: TextStyle(fontSize: 18))),
        ),
      ],
    );
  }

  String _getInstructionText() {
    if (_feedbackMessage.isNotEmpty) return _feedbackMessage;
    switch (_step) {
      case 0: return 'Wie viele blaue Punkte siehst du?';
      case 1: return 'Drücke den Spiegel-Knopf!';
      case 2: return 'Wie viele Punkte sind es jetzt zusammen?';
      default: return '';
    }
  }

  Widget _buildDotGrid(int count, Color color) {
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

  Widget _buildInputArea() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
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
}
