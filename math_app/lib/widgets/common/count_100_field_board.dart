import 'package:flutter/material.dart';

class Count100FieldBoard extends StatelessWidget {
  final TransformationController? transformationController;
  final Set<int> activeIndices; // Indices (0-99) that are part of the problem
  final Set<int> missingIndices; // Indices (0-99) that need input
  final Map<int, TextEditingController> inputControllers;
  final Map<int, FocusNode> focusNodes;
  final Function(int index, String value)? onInputSubmitted;
  final bool isInteractive; // Can user pan/zoom manually?

  const Count100FieldBoard({
    super.key,
    this.transformationController,
    this.activeIndices = const {},
    this.missingIndices = const {},
    this.inputControllers = const {},
    this.focusNodes = const {},
    this.onInputSubmitted,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    // Base size of the grid
    const double gridSize = 800.0;

    return InteractiveViewer(
      transformationController: transformationController,
      panEnabled: isInteractive,
      scaleEnabled: isInteractive,
      minScale: 0.5,
      maxScale: 3.0,
      boundaryMargin: const EdgeInsets.all(200),
      child: Center(
        child: Container(
          width: gridSize,
          height: gridSize,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              mainAxisSpacing: 8, // More spacing
              crossAxisSpacing: 8,
            ),
            itemCount: 100,
            itemBuilder: (context, index) {
              final number = index + 1;
              final isMissing = missingIndices.contains(index);
              final isActive = activeIndices.contains(index);
              
              // If not active and not missing, it's a background cell
              final isBackground = !isActive && !isMissing;

              if (isMissing) {
                return _buildInputCell(index);
              } else {
                return _buildStaticCell(number, isBackground);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStaticCell(int number, bool isBackground) {
    return Container(
      decoration: BoxDecoration(
        color: isBackground ? Colors.grey.shade50 : Colors.white,
        border: Border.all(
          color: isBackground ? Colors.grey.shade200 : Colors.blue.shade200,
          width: isBackground ? 1 : 2,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isBackground ? null : [
           BoxShadow(
             color: Colors.blue.withOpacity(0.1),
             blurRadius: 4,
             spreadRadius: 1,
           )
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 18, // Reduced from 24
          fontWeight: isBackground ? FontWeight.normal : FontWeight.bold,
          color: isBackground ? Colors.grey.shade300 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInputCell(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.orange, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
           BoxShadow(
             color: Colors.orange.withOpacity(0.2),
             blurRadius: 8,
             spreadRadius: 2,
           )
        ],
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: inputControllers[index],
        focusNode: focusNodes[index],
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center, // Center vertically
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          counterText: '',
          isDense: true, // Remove extra padding
        ),
        maxLength: 3,
        onSubmitted: (val) => onInputSubmitted?.call(index, val),
      ),
    );
  }
}
