import 'dart:math';
import 'package:flutter/material.dart';

/// Level 2: Strategic Thinking (Range 50-70)
///
/// **Purpose:** Develop decision-making about which cards can be placed
///
/// **Goal:** Place 10 cards correctly in sequence
///
/// **Mechanics:**
/// - Random starting anchor (50, 60, or 70)
/// - 3 anchor cards placed initially
/// - NOT all generated cards can be placed (some must be skipped)
/// - Child must decide: Can this card be placed now? Or skip it?
/// - Skipped cards return to pool, can reappear later
/// - Subtle hint if valid card skipped multiple times
///
/// **Difficulty Increase from Level 1:**
/// - Wider range (50-70 vs 40-50)
/// - More cards required (10 vs 5)
/// - Some cards are invalid and must be skipped
/// - Strategic thinking required
///
/// **Completion:** 10 cards placed correctly (automatically unlocks Level 3)
class FindNeighborsLevel2Widget extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onStartProblemTimer;
  final Function(bool correct, String? userAnswer) onProblemComplete;

  const FindNeighborsLevel2Widget({
    super.key,
    required this.onComplete,
    required this.onStartProblemTimer,
    required this.onProblemComplete,
  });

  @override
  State<FindNeighborsLevel2Widget> createState() => _FindNeighborsLevel2WidgetState();
}

class _FindNeighborsLevel2WidgetState extends State<FindNeighborsLevel2Widget>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final ScrollController _scrollController = ScrollController();

  // Game state
  int _anchor = 60;
  int _rangeMin = 48;
  int _rangeMax = 72;
  List<int?> _boardSlots = [];
  int? _currentCard;
  int _cardsPlaced = 0;
  final int _requiredCards = 10;

  // Skip tracking
  final List<int> _skippedCards = [];
  Map<int, int> _cardSkipCount = {}; // Track how many times each card was skipped

  // Feedback
  String _feedback = '';
  Color _feedbackColor = Colors.grey;
  bool _showFeedback = false;

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
    // Pick random anchor (50, 60, or 70)
    final List<int> anchors = [50, 60, 70];
    _anchor = anchors[_random.nextInt(anchors.length)];

    // Set range (anchor ± 12)
    _rangeMin = _anchor - 12;
    _rangeMax = _anchor + 12;

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

      // For Level 2, sometimes generate invalid cards to require skipping
      // 60% chance of valid card, 40% chance of any card in range
      if (validCards.isNotEmpty && _random.nextDouble() < 0.6) {
        // Prioritize previously skipped cards
        if (_skippedCards.isNotEmpty && _random.nextBool()) {
          final int skippedCard = _skippedCards[_random.nextInt(_skippedCards.length)];
          if (validCards.contains(skippedCard)) {
            _currentCard = skippedCard;
            _skippedCards.remove(skippedCard);
            return;
          }
        }

        _currentCard = validCards[_random.nextInt(validCards.length)];
      } else {
        // Generate any card in range (might not be placeable)
        _currentCard = _rangeMin + _random.nextInt(_rangeMax - _rangeMin + 1);
      }
    });
  }

  bool _isCardPlaceable(int cardNumber) {
    final int slotIndex = cardNumber - _rangeMin;
    if (slotIndex < 0 || slotIndex >= _boardSlots.length) return false;
    if (_boardSlots[slotIndex] != null) return false;

    // Check if neighbors exist
    if (slotIndex > 0 && _boardSlots[slotIndex - 1] == cardNumber - 1) {
      return true;
    }
    if (slotIndex < _boardSlots.length - 1 &&
        _boardSlots[slotIndex + 1] == cardNumber + 1) {
      return true;
    }
    return false;
  }

  void _onCardDraggedToSlot(int slotNumber) {
    if (_currentCard == null) return;

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
        _cardSkipCount.remove(_currentCard); // Clear skip count
        _feedback = _getPositiveFeedback();
        _feedbackColor = Colors.green;
        _showFeedback = true;
        _currentCard = null;
      });

      // Check if level complete
      if (_cardsPlaced >= _requiredCards) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            widget.onComplete();
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
        _feedback = 'That card doesn\'t fit there. Check the numbers!';
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
    if (_currentCard != null && _cardsPlaced < _requiredCards) {
      widget.onStartProblemTimer();
      _generateNextCard();
    }
  }

  void _onSkipCardPressed() {
    if (_currentCard != null) {
      final int skippedCard = _currentCard!;

      // Track skip count
      _cardSkipCount[skippedCard] = (_cardSkipCount[skippedCard] ?? 0) + 1;

      // Check if this card is actually placeable
      if (_isCardPlaceable(skippedCard)) {
        // Card IS placeable but was skipped
        if (_cardSkipCount[skippedCard]! >= 2) {
          // Skipped twice - give hint
          setState(() {
            _feedback = 'Hint: $skippedCard can be placed! Look at the numbers carefully.';
            _feedbackColor = Colors.blue;
            _showFeedback = true;
          });

          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showFeedback = false;
              });
            }
          });
        }

        // Add to skipped pool
        if (!_skippedCards.contains(skippedCard)) {
          _skippedCards.add(skippedCard);
        }
      } else {
        // Card is NOT placeable - good skip!
        setState(() {
          _feedback = 'Good choice! That card doesn\'t fit right now.';
          _feedbackColor = Colors.green;
          _showFeedback = true;
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showFeedback = false;
            });
          }
        });

        // Add to pool for later
        if (!_skippedCards.contains(skippedCard)) {
          _skippedCards.add(skippedCard);
        }
      }

      // Generate next card
      widget.onStartProblemTimer();
      _generateNextCard();
    }
  }

  String _getPositiveFeedback() {
    final List<String> messages = [
      'Perfect placement!',
      'Great thinking!',
      'You got it!',
      'Excellent!',
      'Nice work!',
      'Spot on!',
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
            color: Colors.green.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.green.shade200, width: 1),
            ),
          ),
          child: Column(
            children: [
              Text(
                'Think strategically!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Some cards won\'t fit yet. Skip them and come back later!',
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
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
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
                            _cardsPlaced >= _requiredCards
                                ? 'Complete!'
                                : 'Press Next Card',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Buttons
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: _currentCard == null && _cardsPlaced < _requiredCards
                          ? _onNextCardPressed
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 32),
                      ),
                      child: const Text('Next Card'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _currentCard != null ? _onSkipCardPressed : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 32),
                      ),
                      child: const Text('Skip'),
                    ),
                  ],
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
                      onWillAcceptWithDetails: (details) => cardInSlot == null,
                      onAcceptWithDetails: (details) => _onCardDraggedToSlot(slotNumber),
                      builder: (context, candidateData, rejectedData) {
                        final bool isHighlighted = candidateData.isNotEmpty;

                        return Container(
                          width: 56,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? Colors.green.shade100
                                : (cardInSlot != null
                                    ? Colors.white
                                    : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isHighlighted
                                  ? Colors.green
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
          color: isDragging ? Colors.green : Colors.blue.shade400,
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
