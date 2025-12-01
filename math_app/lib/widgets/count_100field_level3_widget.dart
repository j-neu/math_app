import 'package:flutter/material.dart';
import 'dart:math';
import 'common/count_100_field_board.dart';

class Count100FieldLevel3Widget extends StatefulWidget {
  final Function(bool) onProblemSolved;

  const Count100FieldLevel3Widget({
    super.key,
    required this.onProblemSolved,
  });

  @override
  State<Count100FieldLevel3Widget> createState() => _Count100FieldLevel3WidgetState();
}

class _Count100FieldLevel3WidgetState extends State<Count100FieldLevel3Widget> {
  final Random _random = Random();
  late int _startNumber;
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  final TransformationController _transformationController = TransformationController();
  bool _isChecking = false;

  // Indices
  Set<int> _activeIndices = {};
  Set<int> _missingIndices = {};

  @override
  void initState() {
    super.initState();
    _generateProblem();
  }

  @override
  void dispose() {
    _disposeControllers();
    _transformationController.dispose();
    super.dispose();
  }

  void _disposeControllers() {
    for (var c in _controllers.values) c.dispose();
    for (var f in _focusNodes.values) f.dispose();
    _controllers.clear();
    _focusNodes.clear();
  }

  void _generateProblem() {
    setState(() {
      // Horizontal sequence: start, +1, +2, +3, +4.
      // Ensure it fits in one row (0-9).
      // Start col index <= 5.
      
      int row = _random.nextInt(10);
      int col = _random.nextInt(6); // 0 to 5
      
      // Start number (1-100)
      _startNumber = row * 10 + col + 1;
      
      _disposeControllers();
      _activeIndices = {};
      _missingIndices = {};
      
      // Add start number
      _activeIndices.add(_startNumber - 1);
      
      // Add 4 missing numbers
      for (int i = 1; i <= 4; i++) {
        int num = _startNumber + i;
        int index = num - 1;
        _activeIndices.add(index);
        _missingIndices.add(index);
        
        _controllers[index] = TextEditingController();
        _focusNodes[index] = FocusNode();
      }
      
      _isChecking = false;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _zoomToProblem();
      if (mounted && _focusNodes.isNotEmpty) {
        // Focus first missing
        int firstMissing = _startNumber + 1 - 1;
        _focusNodes[firstMissing]?.requestFocus();
      }
    });
  }

  Size? _viewportSize;

  void _zoomToProblem() {
    // Center of horizontal sequence (length 5).
    // Center index is start + 2.
    int centerNum = _startNumber + 2;
    int row = (centerNum - 1) ~/ 10;
    int col = (centerNum - 1) % 10;
    
    double x = col * 80.0 + 40;
    double y = row * 80.0 + 40;
    
    // Use captured viewport size or fallback
    double viewportW = _viewportSize?.width ?? MediaQuery.of(context).size.width;
    double viewportH = _viewportSize?.height ?? MediaQuery.of(context).size.height * 0.6;
    
    double scale = 1.0; // Reduced scale
    
    final Matrix4 matrix = Matrix4.identity()
      ..translate(-x * scale + viewportW / 2, -y * scale + viewportH / 2)
      ..scale(scale);
      
    _transformationController.value = matrix;
  }

  void _checkAnswer() async {
    if (_isChecking) return;
    setState(() { _isChecking = true; });

    bool allCorrect = true;
    for (int index in _missingIndices) {
      int expected = index + 1;
      int? input = int.tryParse(_controllers[index]?.text.trim() ?? '');
      if (input != expected) {
        allCorrect = false;
        break;
      }
    }

    widget.onProblemSolved(allCorrect);
    if (mounted) {
        _generateProblem();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        
        return Stack(
          children: [
            Count100FieldBoard(
              transformationController: _transformationController,
              isInteractive: true, // Allow panning
              activeIndices: _activeIndices,
              missingIndices: _missingIndices,
              inputControllers: _controllers,
              focusNodes: _focusNodes,
              onInputSubmitted: (_, __) => _checkAnswer(),
            ),
            
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: _checkAnswer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    elevation: 6,
                  ),
                  child: const Text('Check', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
