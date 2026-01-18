import 'package:flutter/material.dart';
import 'common/rechenschiffchen_widget.dart';

class DoublingBoatLevel1Widget extends StatefulWidget {
  final int targetNumber; // Number in top row
  final Function(bool isCorrect) onResult; // Callback when solved

  const DoublingBoatLevel1Widget({
    super.key,
    required this.targetNumber,
    required this.onResult,
  });

  @override
  State<DoublingBoatLevel1Widget> createState() => _DoublingBoatLevel1WidgetState();
}

class _DoublingBoatLevel1WidgetState extends State<DoublingBoatLevel1Widget> {
  int _bottomCount = 0;
  bool _isComplete = false;
  List<bool> _bottomSlots = List.filled(10, false); // Track individual slots

  @override
  void didUpdateWidget(DoublingBoatLevel1Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetNumber != widget.targetNumber) {
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _bottomCount = 0;
      _isComplete = false;
      _bottomSlots = List.filled(10, false);
    });
  }

  void _handleSlotTap(int row, int col, bool isActive) {
    if (_isComplete || row != 1) return; // Only bottom row interaction

    setState(() {
      _bottomSlots[col] = !_bottomSlots[col]; // Toggle
      _bottomCount = _bottomSlots.where((b) => b).length;
    });

    // Check completion
    if (_bottomCount == widget.targetNumber) {
      // Check if they are in standard positions? 
      // iMINT usually emphasizes structure (filling from left).
      // But for "Doubling", structure matters.
      // Let's enforce standard filling (1-N)? Or allow any?
      // "Die Kinder legen lückenfrei". (Fill without gaps).
      // So we should enforce standard filling or check if slots 0..N-1 are filled.
      
      bool isStandard = true;
      for (int i = 0; i < 10; i++) {
        if (i < widget.targetNumber && !_bottomSlots[i]) isStandard = false;
        if (i >= widget.targetNumber && _bottomSlots[i]) isStandard = false;
      }

      if (isStandard) {
        setState(() => _isComplete = true);
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onResult(true);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Instruction
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Verdopple! Lege genauso viele blaue Plättchen.',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),

        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: RechenschiffchenWidget(
                topCount: widget.targetNumber,
                bottomCount: _bottomCount, // Visual count, but we need slot-specific rendering
                // Wait, RechenschiffchenWidget uses 'count' and fills from left.
                // If I want slot-specific interaction, I need to update RechenschiffchenWidget 
                // to accept List<bool> or handle interaction better.
                // My RechenschiffchenWidget currently takes `topCount` and fills 0..count-1.
                // This forces standard filling. 
                // If I use `onSlotTap` there, I can't visualize random patterns with the current widget.
                // HOWEVER, standard filling is preferred pedagogically here.
                // So, let's simplify: Tapping ANYWHERE in bottom row adds/removes?
                // OR: Tapping a specific slot toggles it, but the widget needs to support non-contiguous filling.
                
                // Let's stick to standard filling for simplicity and pedagogical structure.
                // User taps "Next available slot" behavior? No, that's not explicit.
                // Better: Tapping the Boat adds/removes from the end?
                // Or: Tapping a slot toggles it, but we modify the WIDGET to accept List<bool> or 
                // we just assume standard filling and use `count`.
                
                // Let's modify usage: 
                // If I pass `bottomCount`, it fills 0..N-1.
                // If user taps slot X:
                // If X == currentCount, add 1.
                // If X == currentCount - 1, remove 1.
                // This guides them to fill left-to-right.
                
                onSlotTap: (row, col, isActive) {
                  if (row != 1) return;
                  if (col == _bottomCount) {
                    setState(() => _bottomCount++);
                  } else if (col == _bottomCount - 1) {
                    setState(() => _bottomCount--);
                  }
                  
                  if (_bottomCount == widget.targetNumber) {
                    setState(() => _isComplete = true);
                    Future.delayed(const Duration(milliseconds: 500), () {
                      widget.onResult(true);
                    });
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
