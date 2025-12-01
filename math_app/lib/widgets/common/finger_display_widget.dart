import 'package:flutter/material.dart';

class FingerDisplayWidget extends StatelessWidget {
  final int leftCount;
  final int rightCount;
  final double height;
  final Function(bool isLeft, int count)? onCountChanged;

  const FingerDisplayWidget({
    Key? key,
    required this.leftCount,
    required this.rightCount,
    this.height = 200,
    this.onCountChanged,
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
            child: GestureDetector(
              onTapUp: (details) => _handleTap(context, details, true),
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: Transform.flip(
                  flipX: true,
                  child: _buildHandImage(leftCount),
                ),
              ),
            ),
          ),
          
          // Gap
          SizedBox(width: height * 0.1),

          // Right Hand
          Expanded(
            child: GestureDetector(
              onTapUp: (details) => _handleTap(context, details, false),
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: _buildHandImage(rightCount),
              ),
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
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.withOpacity(0.05),
        ),
        child: Center(
          child: Icon(Icons.back_hand_outlined, color: Colors.grey.withOpacity(0.3), size: 40),
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

  void _handleTap(BuildContext context, TapUpDetails details, bool isLeft) {
    if (onCountChanged == null) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    // Local position is within the ROW. We need position within the Expanded/Image.
    // But GestureDetector wraps the expanded child Container.
    // The 'details.localPosition' is relative to the specific GestureDetector's child (the half-width container).
    
    final width = (box.size.width - (height * 0.1)) / 2; // Approx width of one hand area
    final localX = details.localPosition.dx;
    final fraction = (localX / width).clamp(0.0, 1.0);

    // Zones: 5 slices.
    // Right Hand (Normal): Left->Right = 1..5
    // Left Hand (Flipped): Left->Right = 1..5 (Visually)
    // Wait, we flipped the IMAGE, not the touch coordinates?
    // Transform.flip applies to painting. GestureDetector is outside it?
    // Yes, GestureDetector is parent of Transform.flip.
    // So coordinates are "Normal".
    // Right Hand Image: Thumb is Left. (1 is Left).
    // Left Hand Image: Flipped. Thumb is Right. (1 is Right).
    
    // Logic:
    // Right Hand: 0.0-0.2 = 1 (Thumb), ... 0.8-1.0 = 5 (Pinky)
    // Left Hand: Flipped. 
    // Visually: Thumb is on Right.
    // BUT we want "Count".
    // Usually we fill Thumb->Pinky.
    // Left Hand: Thumb is Rightmost. So we fill Right->Left?
    // Or do we simply map "Tapping Thumb" -> Count 1?
    // Yes.
    // Right Hand: Thumb(1) is at 0.0. Tapping there -> Count 1.
    // Left Hand: Thumb(1) is at 1.0 (Visual Right). Tapping there -> Count 1.
    
    int targetFinger;
    
    if (!isLeft) {
      // Right Hand: 1..5 (Left to Right)
      targetFinger = (fraction * 5).floor() + 1;
    } else {
      // Left Hand: 5..1 (Left to Right) - because Thumb(1) is on right
      targetFinger = 5 - (fraction * 5).floor();
    }
    
    int newCount = targetFinger.clamp(0, 5);
    
    // Toggle logic:
    // If I tap "3", and current is 3 -> Go to 2? Or 0?
    // Common UI: Tap 3 -> Set to 3. Tap 3 again -> no change?
    // Or Tap 3 -> Set to 3.
    // What if I want 2? Tap 2.
    // What if I want 0? Tap... where?
    // Maybe Toggle: If current == target, set to target-1?
    
    int currentCount = isLeft ? leftCount : rightCount;
    
    if (currentCount == newCount) {
       // Tapped the tip of the current count -> reduce by 1
       newCount = currentCount - 1;
    }
    
    onCountChanged!(isLeft, newCount);
  }
}
