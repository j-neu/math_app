import 'package:flutter/material.dart';

/// A standard 20-frame (Rechenschiffchen) widget.
/// 
/// Structure:
/// - 2 Rows of 10 slots.
/// - Gap between column 5 and 6 to show 5-structure.
/// - Supports filling slots with colors (counters).
/// - Supports covering (masking) parts of the boat with a "cloth".
class RechenschiffchenWidget extends StatelessWidget {
  /// Number of counters in the top row (0-10).
  final int topCount;

  /// Number of counters in the bottom row (0-10).
  final int bottomCount;

  /// Color of counters in the top row.
  final Color topColor;

  /// Color of counters in the bottom row.
  final Color bottomColor;

  /// Whether to cover the entire boat with a "cloth".
  final bool coverAll;

  /// Whether to cover only the bottom row.
  final bool coverBottom;

  /// Whether to highlight the left 5+5 block (Tens structure).
  final bool highlightTensBlock;

  /// Whether to highlight the right block (Ones/Remainder).
  final bool highlightOnesBlock;

  /// Callback when a slot is tapped.
  /// row: 0 (top) or 1 (bottom).
  /// col: 0-9.
  /// isActive: true if the slot is currently filled.
  final Function(int row, int col, bool isActive)? onSlotTap;

  const RechenschiffchenWidget({
    super.key,
    this.topCount = 0,
    this.bottomCount = 0,
    this.topColor = Colors.red,
    this.bottomColor = Colors.blue,
    this.coverAll = false,
    this.coverBottom = false,
    this.highlightTensBlock = false,
    this.highlightOnesBlock = false,
    this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate optimal size based on width
        // We need 10 slots + 1 gap + padding
        // Aspect ratio of whole boat approx 2:1 or 3:1
        
        final availableWidth = constraints.maxWidth;
        // Total width needed:
        // Padding: 24 (12 * 2)
        // Slots: 10 * (size + 0.2*size) = 12 * size (margin is 0.1*size on each side)
        // Gap: 0.8 * size
        // Total factors: 12 + 0.8 = 12.8 units
        final slotSize = (availableWidth - 24) / 12.8;
        
        // Ensure not too big, but allow shrinking to fit
        final effectiveSlotSize = slotSize.clamp(10.0, 50.0);

        // Dimensions for highlights
        final slotCellWidth = effectiveSlotSize * 1.2; // size + 2*margin
        final slotCellHeight = effectiveSlotSize * 1.2; 
        final gapWidth = effectiveSlotSize * 0.8;
        final rowGapHeight = effectiveSlotSize * 0.2;
        
        final leftBlockWidth = 5 * slotCellWidth;
        final blockHeight = 2 * slotCellHeight + rowGapHeight;
        final rightBlockStart = leftBlockWidth + gapWidth;
        final rightBlockWidth = 5 * slotCellWidth;

        // Container padding offset
        final paddingOffset = 12.0;
        
        return Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5DC), // Beige/Wood color
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.brown, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRow(0, topCount, topColor, effectiveSlotSize),
                  SizedBox(height: rowGapHeight), // Gap between rows
                  _buildRow(1, bottomCount, bottomColor, effectiveSlotSize),
                ],
              ),
            ),
            
            // Highlights
            if (highlightTensBlock)
              Positioned(
                left: paddingOffset - 4,
                top: paddingOffset - 4,
                width: leftBlockWidth + 8,
                height: blockHeight + 8,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red, width: 4),
                  ),
                ),
              ),

            if (highlightOnesBlock)
              Positioned(
                left: paddingOffset + rightBlockStart - 4,
                top: paddingOffset - 4,
                width: rightBlockWidth + 8,
                height: blockHeight + 8,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red, width: 4),
                  ),
                ),
              ),

            // Cloth covers
            if (coverAll)
              Positioned.fill(
                child: _buildCloth(context, "Imagine..."),
              ),
              
            if (!coverAll && coverBottom)
              Positioned(
                top: (effectiveSlotSize * 1.5) + 24, // Approx half height + padding
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildCloth(context, "?"),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRow(int rowIndex, int count, Color color, double size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // First block of 5
        Row(
          children: List.generate(5, (colIndex) {
            return _buildSlot(rowIndex, colIndex, count, color, size);
          }),
        ),
        
        // Gap (The "5er-Lücke")
        SizedBox(width: size * 0.8),
        
        // Second block of 5
        Row(
          children: List.generate(5, (colIndex) {
            return _buildSlot(rowIndex, colIndex + 5, count, color, size);
          }),
        ),
      ],
    );
  }

  Widget _buildSlot(int rowIndex, int colIndex, int count, Color color, double size) {
    final bool isFilled = colIndex < count;
    
    return GestureDetector(
      onTap: onSlotTap != null ? () => onSlotTap!(rowIndex, colIndex, isFilled) : null,
      child: Container(
        width: size,
        height: size,
        margin: EdgeInsets.all(size * 0.1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.5), // Empty slot placeholder
          border: Border.all(color: Colors.brown.shade300),
        ),
        child: isFilled
            ? Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                  border: Border.all(color: Colors.black12),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildCloth(BuildContext context, String text) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade700,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
