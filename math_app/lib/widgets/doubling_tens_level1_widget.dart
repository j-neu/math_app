import 'package:flutter/material.dart';

class DoublingTensLevel1Widget extends StatefulWidget {
  final int targetTens;
  final Function(bool) onComplete;

  const DoublingTensLevel1Widget({
    Key? key,
    required this.targetTens,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<DoublingTensLevel1Widget> createState() => _DoublingTensLevel1WidgetState();
}

class _DoublingTensLevel1WidgetState extends State<DoublingTensLevel1Widget> with SingleTickerProviderStateMixin {
  // Steps:
  // 0: Count initial tens (Input: Tens count)
  // 1: Activate mirror
  // 2: Count total tens (Input: Tens count)
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
  void didUpdateWidget(DoublingTensLevel1Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetTens != widget.targetTens) {
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
      if (input == widget.targetTens) {
        setState(() {
          _step = 1;
          _feedbackMessage = 'Richtig! Jetzt drücke den Spiegel-Knopf.';
          _feedbackColor = Colors.green;
          _controller.clear();
        });
      } else {
        setState(() {
          _feedbackMessage = 'Fast! Zähle die Zehnerstreifen.';
          _feedbackColor = Colors.orange;
          _controller.clear();
        });
      }
    } else if (_step == 2) {
      final total = widget.targetTens * 2;
      if (input == total) {
        widget.onComplete(true);
      } else {
         setState(() {
          _feedbackMessage = 'Zähle alle Zehnerstreifen zusammen.';
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
      _feedbackMessage = 'Verdoppelt! Wie viele Zehner sind es jetzt?';
      _feedbackColor = Colors.green;
    });
    _animController.forward();
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

        // Content Area
        Expanded(
          child: Stack(
            children: [
              Row(
                children: [
                  // Left Side
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
                  
                  Container(width: 4, color: Colors.transparent),

                  // Right Side (Mirror)
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
                              child: _buildTenStrips(widget.targetTens, Colors.blue.withOpacity(0.7)),
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
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24),
                        backgroundColor: Colors.purple,
                      ),
                      child: const Icon(Icons.compare_arrows, size: 32, color: Colors.white),
                    )
                  : Container(
                      width: 40, 
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.compare_arrows, color: Colors.grey),
                    ),
              ),
            ],
          ),
        ),

        // Input Area
        Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: _step != 1 
            ? _buildInputArea()
            : const Center(child: Text('Drücke den Knopf in der Mitte!', style: TextStyle(fontSize: 18))),
        ),
      ],
    );
  }

  String _getInstructionText() {
    if (_feedbackMessage.isNotEmpty) return _feedbackMessage;
    switch (_step) {
      case 0: return 'Wie viele Zehner siehst du?';
      case 1: return 'Drücke den Spiegel-Knopf!';
      case 2: return 'Wie viele Zehner sind es jetzt zusammen?';
      default: return '';
    }
  }

  Widget _buildTenStrips(int count, Color color) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(count, (index) => _TenStrip(color: color)),
    );
  }

  Widget _buildInputArea() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '?',
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            onSubmitted: (_) => _checkInput(),
          ),
        ),
        const SizedBox(width: 16),
        const Text('Zehner', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(width: 24),
        ElevatedButton(
          onPressed: _checkInput,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
    // A visual representation of a "10-strip" (Zehnerstreifen)
    // Long vertical bar, maybe with 10 divisions
    return Container(
      width: 20,
      height: 120,
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
