import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable 2-row number grid widget with editable text fields.
///
/// Displays a 2x10 grid (0-19 or 1-20) with customizable:
/// - Visible/hidden numbers
/// - Editable fields
/// - Vertical divider after 5th column
///
/// Used for skip-counting exercises (e.g., count by 2s).
class NumberGridWidget extends StatefulWidget {
  /// Total number of cells (typically 20)
  final int totalCells;

  /// Starting number (0 or 1)
  final int startNumber;

  /// Map of cell index → visible number (if null, field is editable)
  /// Example: {0: 1, 2: 3, 4: 5} shows odd numbers, hides evens
  final Map<int, int> visibleNumbers;

  /// Indices of editable fields (only these can be edited)
  /// Example: [1, 3, 5, 7, 9] for even numbers
  final List<int> editableIndices;

  /// Callback when user submits answer (taps "Check" button)
  /// Returns map of index → user's answer
  final Function(Map<int, int> answers)? onSubmit;

  /// Whether to show the submit button
  final bool showSubmitButton;

  const NumberGridWidget({
    Key? key,
    this.totalCells = 20,
    this.startNumber = 1,
    required this.visibleNumbers,
    required this.editableIndices,
    this.onSubmit,
    this.showSubmitButton = true,
  }) : super(key: key);

  @override
  State<NumberGridWidget> createState() => _NumberGridWidgetState();
}

class _NumberGridWidgetState extends State<NumberGridWidget> {
  // Controllers for editable fields
  late Map<int, TextEditingController> _controllers;

  // Focus nodes for managing keyboard focus
  late Map<int, FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _controllers = {};
    _focusNodes = {};

    for (int index in widget.editableIndices) {
      _controllers[index] = TextEditingController();
      _focusNodes[index] = FocusNode();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  /// Get user's answers from text fields
  Map<int, int> _getUserAnswers() {
    Map<int, int> answers = {};

    for (int index in widget.editableIndices) {
      final text = _controllers[index]?.text ?? '';
      final value = int.tryParse(text);
      if (value != null) {
        answers[index] = value;
      }
    }

    return answers;
  }

  /// Handle submit button tap
  void _handleSubmit() {
    final answers = _getUserAnswers();
    widget.onSubmit?.call(answers);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Grid container
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Row 1 (first 10 cells)
              _buildRow(0, 10),

              const SizedBox(height: 8),

              // Row 2 (next 10 cells)
              _buildRow(10, 20),
            ],
          ),
        ),

        // Submit button
        if (widget.showSubmitButton) ...[
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _handleSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            child: const Text('Check'),
          ),
        ],
      ],
    );
  }

  Widget _buildRow(int startIndex, int endIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // First 5 cells
        for (int i = startIndex; i < startIndex + 5 && i < endIndex; i++)
          _buildCell(i),

        // Vertical divider
        Container(
          width: 2,
          height: 45,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          color: Colors.grey.shade400,
        ),

        // Last 5 cells
        for (int i = startIndex + 5; i < endIndex && i < widget.totalCells; i++)
          _buildCell(i),
      ],
    );
  }

  Widget _buildCell(int index) {
    final isEditable = widget.editableIndices.contains(index);
    final visibleNumber = widget.visibleNumbers[index];

    // If number is visible, show it as static text
    if (visibleNumber != null) {
      return Container(
        width: 28,
        height: 45,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(6),
          color: Colors.grey.shade50,
        ),
        alignment: Alignment.center,
        child: Text(
          visibleNumber.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      );
    }

    // If editable, show text field
    if (isEditable) {
      return Container(
        width: 28,
        height: 45,
        margin: const EdgeInsets.all(2),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 2,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            counterText: '', // Hide character counter
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
          onSubmitted: (_) {
            // Move to next editable field
            final currentIndexInList = widget.editableIndices.indexOf(index);
            if (currentIndexInList < widget.editableIndices.length - 1) {
              final nextIndex = widget.editableIndices[currentIndexInList + 1];
              _focusNodes[nextIndex]?.requestFocus();
            } else {
              // Last field - submit
              _handleSubmit();
            }
          },
        ),
      );
    }

    // Should not reach here, but show empty cell as fallback
    return Container(
      width: 28,
      height: 45,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(6),
        color: Colors.grey.shade100,
      ),
    );
  }
}
