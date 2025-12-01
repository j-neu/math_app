import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/common/scrolling_number_band.dart'; // Reusing for potential input style if needed, but 100-field is grid.

class CountSteps100FieldWidget extends StatefulWidget {
  final int levelNumber;
  final int stepSize;
  final bool isGridInitiallyVisible;
  final bool allowGridToggle;
  final Function(bool) onProblemComplete;
  final VoidCallback onLevelComplete;

  final bool isBackwards; // New parameter

  const CountSteps100FieldWidget({
    super.key,
    required this.levelNumber,
    required this.stepSize,
    required this.isGridInitiallyVisible,
    required this.allowGridToggle,
    required this.onProblemComplete,
    required this.onLevelComplete,
    this.isBackwards = false,
  });

  @override
  State<CountSteps100FieldWidget> createState() => _CountSteps100FieldWidgetState();
}

class _CountSteps100FieldWidgetState extends State<CountSteps100FieldWidget> {
  static const int totalProblems = 10;
  int _problemsCompleted = 0;
  
  // Problem State
  int _startNumber = 0;
  List<int> _targetNumbers = []; // The 4 numbers to guess
  int _currentStepIndex = 0; // 0 to 3 (tracking which of the 4 targets we are on)
  
  bool _isGridVisible = true;
  bool _showHelp = false; // For Levels 4-6
  
  // Input State
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _feedbackMessage = '';
  bool _isProblemComplete = false;

  @override
  void initState() {
    super.initState();
    _isGridVisible = widget.isGridInitiallyVisible;
    _generateNewProblem();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _generateNewProblem() {
    final random = Random();
    
    if (widget.isBackwards) {
      // Counting backwards
      // Start must be high enough to subtract 4 steps
      // Min start = 1 + (4 * stepSize)
      // Max start = 100
      int minStart = 1 + (4 * widget.stepSize);
      if (minStart > 100) minStart = 100; // Safety, though step 10 -> 41 is fine
      
      int range = 100 - minStart;
      if (range < 0) range = 0; // Should not happen
      
      setState(() {
        _startNumber = minStart + random.nextInt(range + 1);
        _targetNumbers = List.generate(4, (i) => _startNumber - ((i + 1) * widget.stepSize));
        _currentStepIndex = 0;
        _isProblemComplete = false;
        _feedbackMessage = 'Count backwards in steps of ${widget.stepSize}';
        _inputController.clear();
        _showHelp = false;
      });
    } else {
      // Counting forwards
      // Max start number: 100 - (4 * stepSize)
      int maxStart = 100 - (4 * widget.stepSize);
      if (maxStart < 1) maxStart = 1; 
      
      setState(() {
        _startNumber = 1 + random.nextInt(maxStart);
        _targetNumbers = List.generate(4, (i) => _startNumber + ((i + 1) * widget.stepSize));
        _currentStepIndex = 0;
        _isProblemComplete = false;
        _feedbackMessage = 'Count in steps of ${widget.stepSize}';
        _inputController.clear();
        _showHelp = false; 
      });
    }
    
    // Request focus for input if grid is hidden (Levels 4-6)
    if (!widget.isGridInitiallyVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  void _checkAnswer(String value) {
    if (_isProblemComplete) return;
    if (value.isEmpty) return;

    int? entered = int.tryParse(value);
    if (entered == null) return;

    final currentTarget = _targetNumbers[_currentStepIndex];

    if (entered == currentTarget) {
      // Correct
      setState(() {
        _currentStepIndex++;
        _inputController.clear();
        
        if (_currentStepIndex >= _targetNumbers.length) {
          // Problem complete
          _isProblemComplete = true;
          _problemsCompleted++;
          _feedbackMessage = 'Correct! Well done.';
          widget.onProblemComplete(true);
          
          if (_problemsCompleted >= totalProblems) {
            widget.onLevelComplete();
          } else {
             Future.delayed(const Duration(seconds: 1), _generateNewProblem);
          }
        } else {
           _feedbackMessage = 'Correct! Next number?';
           _focusNode.requestFocus();
        }
      });
    } else {
      // Incorrect
      setState(() {
        _feedbackMessage = 'Try again! Step is ${widget.stepSize}.';
        _inputController.clear();
        _focusNode.requestFocus();
      });
    }
  }

  void _toggleHelp() {
    if (!widget.allowGridToggle) return;
    setState(() {
      _showHelp = !_showHelp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Problem: ${_problemsCompleted + 1}/$totalProblems', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Step Size: ${widget.stepSize}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
        ),

        // Instruction
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.blue.shade50,
          width: double.infinity,
          child: Text(
            _feedbackMessage,
            style: TextStyle(fontSize: 18, color: Colors.blue.shade900),
            textAlign: TextAlign.center,
          ),
        ),

        Expanded(
          child: widget.isGridInitiallyVisible 
              ? _buildVisibleGridMode() 
              : _buildHiddenGridMode(),
        ),
      ],
    );
  }

  Widget _buildVisibleGridMode() {
    // Levels 1-3: Grid always visible. 
    // Current target number is "covered" (clickable tile).
    // Previous targets are revealed.
    // Future targets are hidden or plain? "the user has to click on the tile covering the 15"
    // This implies future targets are also covered.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate optimal cell size
        double gridSize = min(constraints.maxWidth, constraints.maxHeight - 100); // Reserve space for input
        double cellSize = gridSize / 10;

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: gridSize,
                height: gridSize,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 100,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 10,
                  ),
                  itemBuilder: (context, index) {
                    int number = index + 1;
                    return _buildGridTile(number, cellSize);
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Input Area (only shown if a tile is clicked or active)
              // Actually, the prompt says "click on the tile ... and enter 15".
              // Maybe a dialog? Or persistent input at bottom.
              // Persistent input is smoother.
              if (!_isProblemComplete)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          focusNode: _focusNode,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Enter number',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: _checkAnswer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => _checkAnswer(_inputController.text),
                        child: const Text('Check'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildHiddenGridMode() {
    // Levels 4-6: Grid hidden (help button). Show start number.
    // List of "bubbles" for the sequence: [Start] [?] [?] [?] [?]
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_showHelp)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                  child: GridView.builder(
                    itemCount: 100,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
                    itemBuilder: (context, index) {
                       int number = index + 1;
                       bool isStart = number == _startNumber;
                       return Container(
                         decoration: BoxDecoration(
                           border: Border.all(color: Colors.grey.shade300),
                           color: isStart ? Colors.green.shade200 : null,
                         ),
                         child: Center(child: Text('$number', style: const TextStyle(fontSize: 10))),
                       );
                    },
                  ),
                ),
              ),
            ),
          ),
          
        if (!_showHelp)
          const SizedBox(height: 40),
          
        // Sequence Row
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildNumberBubble(_startNumber, true, false), // Start
            for (int i = 0; i < 4; i++)
              _buildNumberBubble(
                _targetNumbers[i], 
                false, // isStart
                i < _currentStepIndex // isRevealed
              ),
          ],
        ),
        
        const SizedBox(height: 40),
        
        if (!_isProblemComplete)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                const Text('Next number:', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _inputController,
                        focusNode: _focusNode,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24),
                        keyboardType: TextInputType.number,
                        onSubmitted: _checkAnswer,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => _checkAnswer(_inputController.text),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                      child: const Text('Check', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
         if (widget.allowGridToggle)
           Padding(
             padding: const EdgeInsets.only(top: 32),
             child: TextButton.icon(
               onPressed: _toggleHelp,
               icon: Icon(_showHelp ? Icons.visibility_off : Icons.visibility),
               label: Text(_showHelp ? 'Hide 100-Field' : 'Show 100-Field Help'),
             ),
           ),
      ],
    );
  }

  Widget _buildNumberBubble(int number, bool isStart, bool isRevealed) {
    bool isCurrentTarget = !isStart && !isRevealed && _targetNumbers.indexOf(number) == _currentStepIndex;
    
    Color color;
    if (isStart) color = Colors.green.shade100;
    else if (isRevealed) color = Colors.blue.shade100;
    else if (isCurrentTarget) color = Colors.orange.shade100;
    else color = Colors.grey.shade200;

    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrentTarget ? Colors.orange : Colors.grey,
          width: isCurrentTarget ? 3 : 1,
        ),
      ),
      child: Text(
        (isStart || isRevealed) ? '$number' : '?',
        style: TextStyle(
          fontSize: 20, 
          fontWeight: FontWeight.bold,
          color: (isStart || isRevealed) ? Colors.black : Colors.grey.shade600
        ),
      ),
    );
  }

  Widget _buildGridTile(int number, double size) {
    // Determine state of this tile
    bool isStart = number == _startNumber;
    bool isTarget = _targetNumbers.contains(number);
    int targetIndex = _targetNumbers.indexOf(number);
    
    bool isRevealed = isTarget && targetIndex < _currentStepIndex;
    bool isCurrentTarget = isTarget && targetIndex == _currentStepIndex;
    bool isFutureTarget = isTarget && targetIndex > _currentStepIndex;
    
    Color bgColor = Colors.white;
    Widget content = Text('$number', style: TextStyle(fontSize: size * 0.4));
    
    if (isStart) {
      bgColor = Colors.green.shade200;
    } else if (isRevealed) {
      bgColor = Colors.blue.shade100;
      content = Text('$number', style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.bold));
    } else if (isCurrentTarget) {
      bgColor = Colors.grey.shade400; // "Blocked"
      content = const Icon(Icons.lock, size: 16, color: Colors.white);
    } else if (isFutureTarget) {
      bgColor = Colors.grey.shade300; // Also blocked but not active
      content = const SizedBox(); // Empty/Hidden
    }

    return GestureDetector(
      onTap: () {
        if (isCurrentTarget) {
          // Focus input when tapping the blocked tile
           _focusNode.requestFocus();
           setState(() {
             _feedbackMessage = 'Type the number for this block!';
           });
        }
      },
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}
