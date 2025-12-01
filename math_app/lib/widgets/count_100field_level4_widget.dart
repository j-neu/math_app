import 'package:flutter/material.dart';
import 'dart:math';
import 'common/count_100_field_board.dart';

class Count100FieldLevel4Widget extends StatefulWidget {
  final Function(bool) onProblemSolved;

  const Count100FieldLevel4Widget({
    super.key,
    required this.onProblemSolved,
  });

  @override
  State<Count100FieldLevel4Widget> createState() => _Count100FieldLevel4WidgetState();
}

class _Count100FieldLevel4WidgetState extends State<Count100FieldLevel4Widget> {
  final Random _random = Random();
  late int _targetNumber;
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  final TransformationController _transformationController = TransformationController();
  bool _isChecking = false;

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
      // Cross shape. Target in center.
      // Valid target: not on edge. Rows 1-8, Cols 1-8.
      
      int row = _random.nextInt(8) + 1; // 1 to 8
      int col = _random.nextInt(8) + 1; // 1 to 8
      
      // Target number (1-100)
      _targetNumber = row * 10 + col + 1;
      int targetIndex = _targetNumber - 1;
      
      _disposeControllers();
      _activeIndices = {};
      _missingIndices = {};
      
      // Add target as missing
      _missingIndices.add(targetIndex);
      _activeIndices.add(targetIndex);
      _controllers[targetIndex] = TextEditingController();
      _focusNodes[targetIndex] = FocusNode();
      
      // Add neighbors as active (visible)
      _activeIndices.add(targetIndex - 10); // Top
      _activeIndices.add(targetIndex + 10); // Bottom
      _activeIndices.add(targetIndex - 1);  // Left
      _activeIndices.add(targetIndex + 1);  // Right
      
      _isChecking = false;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _zoomToProblem();
      if (mounted && _focusNodes.isNotEmpty) {
        _focusNodes[_targetNumber - 1]?.requestFocus();
      }
    });
  }

  Size? _viewportSize;

  void _zoomToProblem() {
    int row = (_targetNumber - 1) ~/ 10;
    int col = (_targetNumber - 1) % 10;
    
    double x = col * 80.0 + 40;
    double y = row * 80.0 + 40;
    
    // Use captured viewport size or fallback
    double viewportW = _viewportSize?.width ?? MediaQuery.of(context).size.width;
    double viewportH = _viewportSize?.height ?? MediaQuery.of(context).size.height * 0.6;
    
    double scale = 1.5; // Reduced scale
    
    final Matrix4 matrix = Matrix4.identity()
      ..translate(-x * scale + viewportW / 2, -y * scale + viewportH / 2)
      ..scale(scale);
      
    _transformationController.value = matrix;
  }

  void _checkAnswer() async {
    if (_isChecking) return;
    setState(() { _isChecking = true; });

    int targetIndex = _targetNumber - 1;
    int? input = int.tryParse(_controllers[targetIndex]?.text.trim() ?? '');
    bool isCorrect = input == _targetNumber;

    widget.onProblemSolved(isCorrect);
    
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
                    backgroundColor: Colors.purple,
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
