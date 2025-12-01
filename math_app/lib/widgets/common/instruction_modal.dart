import 'package:flutter/material.dart';

class InstructionModal extends StatelessWidget {
  final String levelTitle;
  final String instructionText;
  final Color? levelColor;

  const InstructionModal({
    super.key,
    required this.levelTitle,
    required this.instructionText,
    this.levelColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = levelColor ?? Theme.of(context).primaryColor;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.help_outline, size: 32, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    levelTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const Divider(height: 24),

            // Instructions
            Text(
              instructionText,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),

            const SizedBox(height: 24),

            // Dismiss button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Got It!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> show(
    BuildContext context, {
    required String levelTitle,
    required String instructionText,
    Color? levelColor,
  }) {
    return showDialog(
      context: context,
      builder: (context) => InstructionModal(
        levelTitle: levelTitle,
        instructionText: instructionText,
        levelColor: levelColor,
      ),
    );
  }
}