import 'package:flutter/material.dart';
import 'dart:math';
import 'common/count_100_field_board.dart';

enum ProblemType { vertical, horizontal, context }

class Count100FieldLevel5Widget extends StatefulWidget {
  final Function(bool) onProblemSolved;

  const Count100FieldLevel5Widget({
    super.key,
    required this.onProblemSolved,
  });

  @override
  State<Count100FieldLevel5Widget> createState() => _Count100FieldLevel5WidgetState();
}

class _Count100FieldLevel5WidgetState extends State<Count100FieldLevel5Widget> {
  final Random _random = Random();
  late ProblemType _currentType;
  
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  final TransformationController _transformationController = TransformationController();
  bool _isChecking = false;

  Set<int> _activeIndices = {};
  Set<int> _missingIndices = {};
  int _focusNumber = 1; // The number to center zoom on

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
      _currentType = ProblemType.values[_random.nextInt(3)];
      _disposeControllers();
      _activeIndices = {};
      _missingIndices = {};
      _isChecking = false;
      
      if (_currentType == ProblemType.vertical) {
        // Vertical (+10)
        int start = _random.nextInt(60) + 1;
        _focusNumber = start + 20; // Center on middle of sequence
        
        _activeIndices.add(start - 1);
        for (int i = 1; i <= 4; i++) {
          int num = start + (i * 10);
          int index = num - 1;
          _activeIndices.add(index);
          _missingIndices.add(index);
          _controllers[index] = TextEditingController();
          _focusNodes[index] = FocusNode();
        }
        
      } else if (_currentType == ProblemType.horizontal) {
        // Horizontal (+1)
        int row = _random.nextInt(10);
        int col = _random.nextInt(6);
        int start = row * 10 + col + 1;
        _focusNumber = start + 2; // Center on middle
        
        _activeIndices.add(start - 1);
        for (int i = 1; i <= 4; i++) {
          int num = start + i;
          int index = num - 1;
          _activeIndices.add(index);
          _missingIndices.add(index);
          _controllers[index] = TextEditingController();
          _focusNodes[index] = FocusNode();
        }
        
      } else {
        // Context (Cross)
        int row = _random.nextInt(8) + 1;
        int col = _random.nextInt(8) + 1;
        int target = row * 10 + col + 1;
        _focusNumber = target;
        
        int targetIndex = target - 1;
        _missingIndices.add(targetIndex);
        _activeIndices.add(targetIndex);
        _controllers[targetIndex] = TextEditingController();
        _focusNodes[targetIndex] = FocusNode();
        
        _activeIndices.add(targetIndex - 10); // Top
        _activeIndices.add(targetIndex + 10); // Bottom
        _activeIndices.add(targetIndex - 1);  // Left
        _activeIndices.add(targetIndex + 1);  // Right
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _zoomToProblem();
      if (mounted && _focusNodes.isNotEmpty) {
        // Focus first available field
        _focusNodes.values.first.requestFocus();
      }
    });
  }

  Size? _viewportSize;

  void _zoomToProblem() {
    int row = (_focusNumber - 1) ~/ 10;
    int col = (_focusNumber - 1) % 10;
    
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
    Color btnColor;
    switch (_currentType) {
      case ProblemType.vertical: btnColor = Colors.green; break;
      case ProblemType.horizontal: btnColor = Colors.orange; break;
      case ProblemType.context: btnColor = Colors.purple; break;
    }

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
                    backgroundColor: btnColor,
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
