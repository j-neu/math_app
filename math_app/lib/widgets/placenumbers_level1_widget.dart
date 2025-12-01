import 'package:flutter/material.dart';
import 'dart:math';

class PlaceNumbersLevel1Widget extends StatefulWidget {
  final Function(bool) onProblemSolved;
  final int cardCount; // Number of cards to place (3 or 5)
  final int maxNumber; // Maximum number on the line (20 or 100)
  final int tolerance; // Allowed difference for approximate position

  const PlaceNumbersLevel1Widget({
    super.key,
    required this.onProblemSolved,
    this.cardCount = 3,
    this.maxNumber = 20,
    this.tolerance = 3,
  });

  @override
  State<PlaceNumbersLevel1Widget> createState() => _PlaceNumbersLevel1WidgetState();
}

class _PlaceNumbersLevel1WidgetState extends State<PlaceNumbersLevel1Widget> {
  final Random _random = Random();
  final GlobalKey _lineKey = GlobalKey();
  
  List<int> _targetNumbers = [];
  Map<int, int> _placedCards = {}; // Map<NumberValue, PositionValue>
  
  // Hover state for visual feedback
  int? _hoverValue;
  
  bool _isChecking = false;
  String? _feedbackMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _generateProblem();
  }

  void _generateProblem() {
    setState(() {
      _placedCards.clear();
      _isChecking = false;
      _feedbackMessage = null;
      _isSuccess = false;
      _hoverValue = null;

      final Set<int> numbers = {};
      while (numbers.length < widget.cardCount) {
        numbers.add(_random.nextInt(widget.maxNumber - 1) + 1);
      }
      _targetNumbers = numbers.toList();
    });
  }

  void _onCardDropped(int number, int position) {
    setState(() {
      _placedCards.remove(number);
      _placedCards[number] = position;
      _feedbackMessage = null;
      _hoverValue = null; // Clear ghost
    });
  }

  void _returnCardToHand(int number) {
    setState(() {
      _placedCards.remove(number);
      _feedbackMessage = null;
    });
  }

  void _checkAnswer() {
    if (_placedCards.length < _targetNumbers.length) {
      setState(() => _feedbackMessage = 'Please place all cards first!');
      return;
    }

    final placedEntries = _placedCards.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // 1. Check Order
    bool orderCorrect = true;
    for (int i = 0; i < placedEntries.length - 1; i++) {
      if (placedEntries[i].key > placedEntries[i+1].key) {
        orderCorrect = false;
        break;
      }
    }

    if (!orderCorrect) {
      setState(() => _feedbackMessage = 'Check the order! Smaller numbers go to the left.');
      return;
    }

    // 2. Check Position with Tolerance
    bool positionCorrect = true;
    for (var entry in placedEntries) {
      int value = entry.key;
      int pos = entry.value;
      if ((pos - value).abs() > widget.tolerance) {
        positionCorrect = false;
        break;
      }
    }

    if (!positionCorrect) {
      setState(() => _feedbackMessage = 'Good order, but check positions! Some numbers are too far off.');
      return;
    }

    setState(() {
      _isSuccess = true;
      _feedbackMessage = 'Correct! Great estimation!';
    });
    
    widget.onProblemSolved(true);
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _generateProblem();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              height: 80,
              alignment: Alignment.center,
              child: Text(
                _feedbackMessage ?? 'Drag the cards to the correct spot on the line.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isSuccess 
                      ? Colors.green 
                      : (_feedbackMessage != null ? Colors.orange : Colors.grey[700]),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: LayoutBuilder(
                  builder: (context, lineConstraints) {
                    return Center(
                      child: SizedBox(
                        key: _lineKey,
                        height: 200,
                        width: lineConstraints.maxWidth,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // The Line
                            Container(
                              height: 4,
                              color: Colors.black,
                              width: double.infinity,
                            ),
                            
                            // Endpoints
                            const Positioned(
                              left: 0,
                              top: 110,
                              child: Text('0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            ),
                            Positioned(
                              right: 0,
                              top: 110,
                              child: Text('${widget.maxNumber}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            ),
                            
                            // Ticks
                            ..._buildTicks(lineConstraints.maxWidth),

                            // Drop Zone & Ghost
                            Positioned.fill(
                              child: _buildDropZone(lineConstraints.maxWidth),
                            ),

                            // Placed Cards
                            ..._placedCards.entries.map((entry) {
                              double relativePos = entry.value / widget.maxNumber;
                              double left = (relativePos * lineConstraints.maxWidth) - 22;
                              return Positioned(
                                left: left,
                                top: 40, 
                                child: _buildPlacedCard(entry.key),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.grey[100],
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: _targetNumbers.map((number) {
                      if (_placedCards.containsKey(number)) {
                        return const SizedBox(width: 60, height: 80);
                      }
                      return _buildDraggableCard(number);
                    }).toList(),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _checkAnswer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                child: const Text('Check'),
              ),
            ),
          ],
        );
      }
    );
  }

  List<Widget> _buildTicks(double width) {
    List<Widget> ticks = [];
    // 0-20: tick every 5. 0-100: tick every 10.
    int interval = widget.maxNumber > 20 ? 10 : 5;
    
    for (int i = 0; i <= widget.maxNumber; i += interval) {
      double relativeX = i / widget.maxNumber;
      double left = relativeX * width;
      bool isEndpoint = i == 0 || i == widget.maxNumber;
      
      ticks.add(Positioned(
        left: left - (isEndpoint ? 2 : 1), // Center the tick
        child: Container(
          width: isEndpoint ? 4 : 2,
          height: isEndpoint ? 20 : 10,
          color: isEndpoint ? Colors.black : Colors.grey.shade400,
        ),
      ));
    }
    return ticks;
  }

  Widget _buildDropZone(double totalWidth) {
    return DragTarget<int>(
      onWillAccept: (_) => true,
      onMove: (details) {
         final RenderBox? renderBox = _lineKey.currentContext?.findRenderObject() as RenderBox?;
         if (renderBox != null) {
           final localOffset = renderBox.globalToLocal(details.offset);
           double relativeX = localOffset.dx.clamp(0.0, renderBox.size.width);
           double value = (relativeX / renderBox.size.width) * widget.maxNumber;
           int snappedValue = value.round().clamp(0, widget.maxNumber);
           
           if (_hoverValue != snappedValue) {
             setState(() => _hoverValue = snappedValue);
           }
         }
      },
      onAcceptWithDetails: (details) {
        // Find render box to calculate local position
        final RenderBox? renderBox = _lineKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localOffset = renderBox.globalToLocal(details.offset);
          double relativeX = localOffset.dx.clamp(0.0, renderBox.size.width);
          double value = (relativeX / renderBox.size.width) * widget.maxNumber;
          int snappedValue = value.round().clamp(0, widget.maxNumber);
          
          _onCardDropped(details.data, snappedValue);
        }
      },
      onLeave: (_) {
        setState(() => _hoverValue = null);
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Transparent hit test area
            Container(color: Colors.transparent),
            
            // Ghost Card (Visual Feedback)
            if (candidateData.isNotEmpty && _hoverValue != null) ...[
              // Preview Dot on Line
              Positioned(
                left: (_hoverValue! / widget.maxNumber * totalWidth) - 5, // Center 10px dot
                top: 95, // Line is at 100 (height 200 / 2). Dot 10px tall -> top 95.
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              // Ghost Card
              Positioned(
                left: (_hoverValue! / widget.maxNumber * totalWidth) - 22,
                top: 40,
                child: Opacity(
                  opacity: 0.5,
                  child: _buildCardVisual(candidateData.first!, scale: 1.0),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
  
  Widget _buildDraggableCard(int number) {
    return Draggable<int>(
      data: number,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: _buildCardVisual(number, scale: 1.1),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCardVisual(number),
      ),
      child: _buildCardVisual(number),
    );
  }

  Widget _buildPlacedCard(int number) {
    return GestureDetector(
      onTap: () => _returnCardToHand(number),
      child: Draggable<int>(
        data: number,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
          color: Colors.transparent,
          child: _buildCardVisual(number, scale: 1.1),
        ),
        childWhenDragging: Opacity(
          opacity: 0.0,
          child: _buildCardVisual(number),
        ),
        child: _buildCardVisual(number, isPlaced: true),
        onDragEnd: (details) {
           if (!details.wasAccepted) {
             _returnCardToHand(number);
           }
        },
      ),
    );
  }

  Widget _buildCardVisual(int number, {double scale = 1.0, bool isPlaced = false}) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 44,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }
}