import 'dart:math';
import 'package:flutter/material.dart';

/// Level 4: Finale (ADHD-Friendly Victory Lap)
///
/// **Purpose:** Celebrate mastery with easier, confidence-building practice
///
/// **Goal:** Place 10 cards correctly (easier than Level 3's 20 cards)
///
/// **Difficulty:** EASIER than all previous levels
/// - Narrower range (40-60 vs 30-90)
/// - Fewer cards required (10 vs 20)
/// - All generated cards are valid (no skipping needed)
/// - Faster completion
/// - Celebration dialog on completion
///
/// **COMPLETION CRITERIA:**
/// - Minimum problems: 10 (10 correct card placements)
/// - Accuracy required: 100% (zero errors in last 10 problems)
/// - Time limit: 30 seconds per card placement
/// - Status: "finished" → "completed" when criteria met
///
/// **ADHD Design:** Easy→Hard→Easy flow for rewarding completion
class FindNeighborsLevel4Widget extends StatefulWidget {
  final VoidCallback onStartProblemTimer;
  final Function(bool correct, String? userAnswer) onProblemComplete;

  const FindNeighborsLevel4Widget({
    super.key,
    required this.onStartProblemTimer,
    required this.onProblemComplete,
  });

  @override
  State<FindNeighborsLevel4Widget> createState() => _FindNeighborsLevel4WidgetState();
}

class _FindNeighborsLevel4WidgetState extends State<FindNeighborsLevel4Widget>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final ScrollController _scrollController = ScrollController();

  // Game state
  int _anchor = 50;
  int _rangeMin = 40;
  int _rangeMax = 60;
  List<int?> _boardSlots = [];
  int? _currentCard;
  int _cardsPlaced = 0;
  final int _requiredCards = 10;

  // Feedback
  String _feedback = '';
  Color _feedbackColor = Colors.grey;
  bool _showFeedback = false;
  bool _isComplete = false;

  // Animation for incorrect placement
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isShaking = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakeController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          setState(() {
            _isShaking = false;
          });
        }
      });

    _initializeGame();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    // Pick random anchor (45, 50, or 55 - centered in range)
    final List<int> anchors = [45, 50, 55];
    _anchor = anchors[_random.nextInt(anchors.length)];

    // Set narrower range (40-60 for easier finale)
    _rangeMin = 40;
    _rangeMax = 60;

    // Initialize board
    final int totalSlots = _rangeMax - _rangeMin + 1;
    _boardSlots = List<int?>.filled(totalSlots, null);

    // Place the 3 anchor cards
    _boardSlots[(_anchor - 2) - _rangeMin] = _anchor - 2;
    _boardSlots[_anchor - _rangeMin] = _anchor;
    _boardSlots[(_anchor + 2) - _rangeMin] = _anchor + 2;

    // Generate first card
    _generateNextCard();

    // Start timer for first problem
    widget.onStartProblemTimer();
  }

  void _generateNextCard() {
    setState(() {
      _showFeedback = false;

      // Find all valid (placeable) cards
      final List<int> validCards = [];
      for (int i = 0; i < _boardSlots.length; i++) {
        if (_boardSlots[i] == null) {
          final int cardNumber = _rangeMin + i;
          // Check if left neighbor exists
          if (i > 0 && _boardSlots[i - 1] != null) {
            validCards.add(cardNumber);
          }
          // Check if right neighbor exists
          else if (i < _boardSlots.length - 1 && _boardSlots[i + 1] != null) {
            validCards.add(cardNumber);
          }
        }
      }

      // For Finale, ALWAYS generate a valid card (no skipping needed)
      if (validCards.isNotEmpty) {
        _currentCard = validCards[_random.nextInt(validCards.length)];
      } else {
        // Fallback: generate any card in range
        _currentCard = _rangeMin + _random.nextInt(_rangeMax - _rangeMin + 1);
      }
    });
  }

  void _onCardDraggedToSlot(int slotNumber) {
    if (_currentCard == null || _isComplete) return;

    final int slotIndex = slotNumber - _rangeMin;

    // Check if placement is valid
    bool isValid = false;
    if (_boardSlots[slotIndex] == null && slotNumber == _currentCard) {
      // Check if left neighbor exists and matches
      if (slotIndex > 0 && _boardSlots[slotIndex - 1] == slotNumber - 1) {
        isValid = true;
      }
      // Check if right neighbor exists and matches
      else if (slotIndex < _boardSlots.length - 1 &&
          _boardSlots[slotIndex + 1] == slotNumber + 1) {
        isValid = true;
      }
    }

    if (isValid) {
      // Correct placement!
      widget.onProblemComplete(true, _currentCard.toString());

      setState(() {
        _boardSlots[slotIndex] = _currentCard;
        _cardsPlaced++;
        _feedback = _getPositiveFeedback();
        _feedbackColor = Colors.green;
        _showFeedback = true;
        _currentCard = null;
      });

      // Check if level complete
      if (_cardsPlaced >= _requiredCards) {
        setState(() {
          _isComplete = true;
        });

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _showCompletionCelebration();
          }
        });
      } else {
        _scrollToPlacedCard(slotNumber);
      }
    } else {
      // Incorrect placement
      widget.onProblemComplete(false, _currentCard.toString());

      setState(() {
        _isShaking = true;
        _feedback = 'Not quite! Try the correct slot.';
        _feedbackColor = Colors.orange;
        _showFeedback = true;
      });

      _shakeController.forward(from: 0);

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showFeedback = false;
          });
        }
      });
    }
  }

  void _scrollToPlacedCard(int cardNumber) {
    final double cardWidth = 60.0;
    final double padding = 4.0;
    final int slotIndex = cardNumber - _rangeMin;
    final double targetPosition = slotIndex * (cardWidth + padding);

    _scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onNextCardPressed() {
    if (_currentCard != null && _cardsPlaced < _requiredCards && !_isComplete) {
      widget.onStartProblemTimer();
      _generateNextCard();
    }
  }

  void _showCompletionCelebration() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.celebration, color: Colors.amber, size: 40),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Congratulations!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You completed the Finale level!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Cards placed: $_cardsPlaced',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Exercise completed!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You\'ve mastered neighboring numbers! Great work!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to learning path
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _getPositiveFeedback() {
    final List<String> messages = [
      'Perfect!',
      'Excellent!',
      'You\'re amazing!',
      'Fantastic!',
      'Wonderful!',
      'Outstanding!',
    ];
    return messages[_random.nextInt(messages.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Instructions and progress
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.amber.shade200, width: 1),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.celebration, color: Colors.amber, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Finale!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Place 10 cards to complete the exercise!',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _cardsPlaced / _requiredCards,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$_cardsPlaced/$_requiredCards',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Feedback message
        if (_showFeedback)
          Container(
            padding: const EdgeInsets.all(12),
            color: _feedbackColor.withOpacity(0.1),
            width: double.infinity,
            child: Text(
              _feedback,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _feedbackColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Pickup area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Card pickup area
              Expanded(
                flex: 2,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                  ),
                  child: _currentCard != null
                      ? Center(
                          child: AnimatedBuilder(
                            animation: _shakeAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: _isShaking
                                    ? Offset(_shakeAnimation.value, 0)
                                    : Offset.zero,
                                child: child,
                              );
                            },
                            child: Draggable<int>(
                              data: _currentCard!,
                              feedback: _buildCard(_currentCard!, isDragging: true),
                              childWhenDragging: _buildCard(_currentCard!, isGhost: true),
                              child: _buildCard(_currentCard!),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _isComplete ? 'Complete!' : 'Press Next Card',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Next Card button (no skip needed for finale)
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: _currentCard == null && !_isComplete
                      ? _onNextCardPressed
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text(
                    'Next Card',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Game board (scrollable)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_boardSlots.length, (index) {
                  final int slotNumber = _rangeMin + index;
                  final int? cardInSlot = _boardSlots[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: DragTarget<int>(
                      onWillAcceptWithDetails: (details) => cardInSlot == null && !_isComplete,
                      onAcceptWithDetails: (details) => _onCardDraggedToSlot(slotNumber),
                      builder: (context, candidateData, rejectedData) {
                        final bool isHighlighted = candidateData.isNotEmpty && !_isComplete;

                        return Container(
                          width: 56,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? Colors.amber.shade100
                                : (cardInSlot != null
                                    ? Colors.white
                                    : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isHighlighted
                                  ? Colors.amber
                                  : (cardInSlot != null
                                      ? Colors.blue.shade300
                                      : Colors.grey.shade400),
                              width: 2,
                            ),
                            boxShadow: cardInSlot != null
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: cardInSlot != null
                                ? Text(
                                    cardInSlot.toString(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  )
                                : Text(
                                    slotNumber.toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(int number, {bool isDragging = false, bool isGhost = false}) {
    return Container(
      width: 56,
      height: 80,
      decoration: BoxDecoration(
        color: isGhost ? Colors.grey.shade300 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDragging ? Colors.amber : Colors.blue.shade400,
          width: 2,
        ),
        boxShadow: isDragging || !isGhost
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(isDragging ? 0.3 : 0.1),
                  blurRadius: isDragging ? 12 : 4,
                  offset: Offset(0, isDragging ? 4 : 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isGhost ? Colors.grey.shade400 : Colors.black87,
          ),
        ),
      ),
    );
  }
}
