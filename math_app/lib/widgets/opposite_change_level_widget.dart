import 'package:flutter/material.dart';
import 'dart:math';
import 'package:math_app/widgets/common/wendeplaettchen_widget.dart';

class OppositeChangeLevelWidget extends StatefulWidget {
  final int levelNumber;
  final int problemIndex;
  final VoidCallback onProblemComplete;
  final Function(bool) onResult; // Pass result back to coordinator

  const OppositeChangeLevelWidget({
    Key? key,
    required this.levelNumber,
    required this.problemIndex,
    required this.onProblemComplete,
    required this.onResult,
  }) : super(key: key);

  @override
  _OppositeChangeLevelWidgetState createState() => _OppositeChangeLevelWidgetState();
}

class _OppositeChangeLevelWidgetState extends State<OppositeChangeLevelWidget> with TickerProviderStateMixin {
  // State
  late int _totalItems;
  late int _redCount;
  late int _blueCount;
  
  // New state after change
  late int _targetRedCount;
  late int _targetBlueCount;
  
  bool _isCovered = false;
  bool _isAnimating = false;
  bool _showInput = false;
  bool _showFeedback = false;
  bool _isCorrect = false;

  // Animation
  late AnimationController _moveController;
  late AnimationController _flipController;
  Color _animatingColor = Colors.red; // Color of the moving piece
  
  // Input controllers
  final TextEditingController _redInputController = TextEditingController();
  final TextEditingController _blueInputController = TextEditingController();
  final FocusNode _redFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000), // Total move out/in time
    );
    _flipController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _generateProblem();
  }

  @override
  void dispose() {
    _moveController.dispose();
    _flipController.dispose();
    _redInputController.dispose();
    _blueInputController.dispose();
    _redFocus.dispose();
    super.dispose();
  }

  void _generateProblem() {
    final random = Random();
    int min, max;

    // Difficulty Curve Logic based on widget.problemIndex
    // P0-1: Trivial (Lowest range)
    // P2-3: Easy (Low-Mid range)
    // P4-5: Medium (Mid-High range)
    // P6-7: Hard (Highest range)
    // P8: Medium (Mid-High range)
    // P9: Easy (Low-Mid range)
    
    // Determine difficulty tier (0=Trivial, 1=Easy, 2=Medium, 3=Hard)
    int difficultyTier;
    if (widget.problemIndex <= 1) difficultyTier = 0;
    else if (widget.problemIndex <= 3) difficultyTier = 1;
    else if (widget.problemIndex <= 5) difficultyTier = 2;
    else if (widget.problemIndex <= 7) difficultyTier = 3;
    else if (widget.problemIndex == 8) difficultyTier = 2;
    else difficultyTier = 1;

    // Level-based difficulty ranges
    if (widget.levelNumber == 1) {
      // Level 1: Max 10 items (4-10)
      if (difficultyTier == 0) { min = 4; max = 5; }      // Trivial
      else if (difficultyTier == 1) { min = 6; max = 7; } // Easy
      else if (difficultyTier == 2) { min = 8; max = 8; } // Medium
      else { min = 9; max = 10; }                         // Hard
    } else if (widget.levelNumber == 2) {
      // Level 2: 6-15 items
      if (difficultyTier == 0) { min = 6; max = 7; }      // Trivial
      else if (difficultyTier == 1) { min = 8; max = 10; } // Easy
      else if (difficultyTier == 2) { min = 11; max = 13; } // Medium
      else { min = 14; max = 15; }                          // Hard
    } else {
      // Level 3: 10-20 items
      if (difficultyTier == 0) { min = 10; max = 12; }    // Trivial
      else if (difficultyTier == 1) { min = 13; max = 15; } // Easy
      else if (difficultyTier == 2) { min = 16; max = 18; } // Medium
      else { min = 19; max = 20; }                          // Hard
    }

    _totalItems = min + random.nextInt(max - min + 1);
    
    // Distribute Red/Blue (ensure at least 1 of each to allow flipping either way)
    _redCount = 1 + random.nextInt(_totalItems - 1);
    _blueCount = _totalItems - _redCount;

    // Decide which color flips
    // If we flip Red -> Blue, Red decreases, Blue increases
    // If we flip Blue -> Red, Blue decreases, Red increases
    bool flipRedToBlue = random.nextBool();
    
    // Ensure we have enough to flip
    if (flipRedToBlue && _redCount == 0) flipRedToBlue = false;
    if (!flipRedToBlue && _blueCount == 0) flipRedToBlue = true;

    if (flipRedToBlue) {
      _targetRedCount = _redCount - 1;
      _targetBlueCount = _blueCount + 1;
      _animatingColor = Colors.red; // The one moving out is Red
    } else {
      _targetRedCount = _redCount + 1;
      _targetBlueCount = _blueCount - 1;
      _animatingColor = Colors.blue; // The one moving out is Blue
    }

    // Reset State
    _isCovered = false;
    _isAnimating = false;
    _showInput = false;
    _showFeedback = false;
    _redInputController.clear();
    _blueInputController.clear();
  }

  void _startSequence() async {
    setState(() {
      _isCovered = true;
    });

    await Future.delayed(Duration(milliseconds: 1000)); // Wait for cover to settle

    // Start Animation
    setState(() {
      _isAnimating = true;
    });

    // 1. Move Out (0.0 -> 0.4)
    await _moveController.animateTo(0.4, duration: Duration(milliseconds: 800), curve: Curves.easeOut);
    
    // 2. Flip (Change Color)
    await _flipController.forward();
    setState(() {
      // Logic handled in build, but conceptually color changed
      _animatingColor = (_animatingColor == Colors.red) ? Colors.blue : Colors.red;
    });
    await _flipController.reverse(); // Visual reset for next time, but color stays switched in our logic variable? 
    // Actually, simpler: animate _flipController 0->1, build widget interpolates color.
    
    await Future.delayed(Duration(milliseconds: 500)); // Pause to let user see

    // 3. Move In (0.4 -> 0.0) - Reversing the move controller to "put back"
    await _moveController.animateBack(0.0, duration: Duration(milliseconds: 800), curve: Curves.easeIn);

    setState(() {
      _isAnimating = false;
      _showInput = true;
    });
    
    // Focus first input
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_redFocus);
      }
    });
  }

  void _checkAnswer() {
    int? userRed = int.tryParse(_redInputController.text);
    int? userBlue = int.tryParse(_blueInputController.text);

    if (userRed == null || userBlue == null) return;

    bool correct = (userRed == _targetRedCount && userBlue == _targetBlueCount);

    setState(() {
      _isCorrect = correct;
      _showFeedback = true;
      _isCovered = false; // Reveal true state
      
      // Update the main counters to reflect reality
      _redCount = _targetRedCount;
      _blueCount = _targetBlueCount;
    });

    widget.onResult(correct);

    Future.delayed(Duration(milliseconds: 2000), () {
      if (mounted) {
        widget.onProblemComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Info / Instruction
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _showInput 
                ? "How many now?" 
                : (_isCovered ? "Watch closely..." : "Remember the counts!"),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),

        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Total count indicator (always visible)
              Positioned(
                top: 20,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    "Total: $_totalItems",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ),

              // 1. The Counters (Underneath)
              _buildCounterField(),

              // 2. The Cover
              if (_isCovered)
                Container(
                  width: 350,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.help_outline, size: 64, color: Colors.grey.shade400),
                  ),
                ),

              // 3. Animation Layer (Moving Counter)
              if (_isAnimating)
                _buildAnimatingCounter(),
            ],
          ),
        ),

        // 4. Controls / Input
        if (!_isCovered && !_showInput && !_showFeedback)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: ElevatedButton(
              onPressed: _startSequence,
              child: Text("Cover & Change", style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
            ),
          ),

        if (_showInput && !_showFeedback)
          _buildInputSection(),
          
        if (_showFeedback)
          _buildFeedbackSection(),
          
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCounterField() {
    // Arrange in 2 rows (like 20-field) if possible, or just Wrap
    return Container(
      width: 320,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          ...List.generate(_redCount, (_) => WendeplaettchenWidget(color: Colors.red)),
          ...List.generate(_blueCount, (_) => WendeplaettchenWidget(color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildAnimatingCounter() {
    return AnimatedBuilder(
      animation: Listenable.merge([_moveController, _flipController]),
      builder: (context, child) {
        // Move: 0.0 (Hidden) -> 0.4 (Out)
        // We map 0.0-0.4 value to a vertical translation
        double moveVal = _moveController.value;
        double displayY = 100 - (moveVal * 2.5 * 150); // Move UP out of box (assuming box center is 0)
        // Adjust translation logic to simulate "coming out from under"
        // Let's say box is at center. We move roughly 120px UP.
        
        // Flip color interpolation
        
        // We updated _animatingColor in logic during sequence, but here we need stable ref.
        // Actually, in _startSequence I updated _animatingColor halfway. 
        // So `_animatingColor` holds current state.
        
        return Transform.translate(
          offset: Offset(0, displayY - 100), // Start at center, move up
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateX(_flipController.value * pi), // Flip effect
            child: WendeplaettchenWidget(
              color: _animatingColor, 
              size: 48,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNumberInput("Red", Colors.red, _redInputController, _redFocus),
          SizedBox(width: 24),
          _buildNumberInput("Blue", Colors.blue, _blueInputController, null),
          SizedBox(width: 24),
          ElevatedButton(
            onPressed: _checkAnswer,
            child: Icon(Icons.check),
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(), 
              padding: EdgeInsets.all(16)
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNumberInput(String label, Color color, TextEditingController controller, FocusNode? focus) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        SizedBox(
          width: 60,
          child: TextField(
            controller: controller,
            focusNode: focus,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: _isCorrect ? Colors.green.shade100 : Colors.orange.shade100,
      child: Column(
        children: [
          Text(
            _isCorrect ? "Correct! One changed color." : "Not quite. Look again!",
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: _isCorrect ? Colors.green.shade800 : Colors.orange.shade800
            ),
          ),
          if (!_isCorrect)
            Text("Total is still ${_totalItems}."),
        ],
      ),
    );
  }
}