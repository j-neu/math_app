import 'package:flutter/material.dart';

enum FingerInteractionType {
  direct,    // Tap specific finger position to set count
  increment, // Tap anywhere to add 1 (cycles 0-5)
  decrement, // Tap anywhere to remove 1 (cycles 5-0)
}

class FingerDisplayWidget extends StatelessWidget {
  final int leftCount;
  final int rightCount;
  final double height;
  final Function(bool isLeft, int count)? onCountChanged;
  final FingerInteractionType interactionType;

  const FingerDisplayWidget({
    Key? key,
    required this.leftCount,
    required this.rightCount,
    this.height = 200,
    this.onCountChanged,
    this.interactionType = FingerInteractionType.direct,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: height * 2.5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left Hand (Flipped Right Hand)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapUp: (details) => _handleTap(details, constraints.maxWidth, true),
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Transform.flip(
                      flipX: true,
                      child: _buildHandImage(leftCount),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Gap
          SizedBox(width: height * 0.1),

          // Right Hand
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapUp: (details) => _handleTap(details, constraints.maxWidth, false),
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: _buildHandImage(rightCount),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandImage(int count) {
    if (count == 0) {
      // Placeholder for 0 (Fist/Empty)
      // Visual cue that a hand is here
      return Container(
        height: height,
        width: height * 0.8,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 2),
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.withValues(alpha: 0.05),
        ),
        child: Center(
          child: Icon(Icons.back_hand_outlined, color: Colors.grey.withValues(alpha: 0.3), size: 40),
        ),
      );
    }
    
    return Image.asset(
      'assets/images/fingers/${count}_finger_right.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback if image missing
        return Container(
          height: height,
          width: height * 0.8,
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(fontSize: 40, color: Colors.brown),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(TapUpDetails details, double width, bool isLeft) {
    if (onCountChanged == null) return;

    int currentCount = isLeft ? leftCount : rightCount;
    int newCount = currentCount;

    if (interactionType == FingerInteractionType.increment) {
      newCount = (currentCount + 1) % 6;
      onCountChanged!(isLeft, newCount);
      return;
    } else if (interactionType == FingerInteractionType.decrement) {
      newCount = currentCount - 1;
      if (newCount < 0) newCount = 5;
      onCountChanged!(isLeft, newCount);
      return;
    }

    // Direct Mode: Use local position normalized to width
    final localX = details.localPosition.dx;
    final fraction = (localX / width).clamp(0.0, 1.0);

    int targetFinger;
    
    if (!isLeft) {
      // Right Hand: 1..5 (Left to Right)
      targetFinger = (fraction * 5).floor() + 1;
    } else {
      // Left Hand: 5..1 (Left to Right) - because Thumb(1) is on right
      targetFinger = 5 - (fraction * 5).floor();
    }
    
    newCount = targetFinger.clamp(0, 5);
    
    if (currentCount == newCount) {
       // Tapped the tip of the current count -> reduce by 1
       newCount = currentCount - 1;
    }
    
    onCountChanged!(isLeft, newCount);
  }
}