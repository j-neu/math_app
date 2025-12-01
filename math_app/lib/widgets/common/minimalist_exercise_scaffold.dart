import 'package:flutter/material.dart';
import 'segmented_progress_bar.dart';

class MinimalistExerciseScaffold extends StatelessWidget {
  final String exerciseTitle;
  final int totalProblems;
  final int currentProblemIndex;
  final List<bool> problemResults; // true = correct, false = incorrect
  final VoidCallback onShowInstructions;
  final VoidCallback onShowLevelSelector;
  final Widget exerciseContent;

  const MinimalistExerciseScaffold({
    super.key,
    required this.exerciseTitle,
    required this.totalProblems,
    required this.currentProblemIndex,
    required this.problemResults,
    required this.onShowInstructions,
    required this.onShowLevelSelector,
    required this.exerciseContent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(exerciseTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Choose Level',
            onPressed: onShowLevelSelector,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Instructions',
            onPressed: onShowInstructions,
          ),
        ],
      ),
      body: Column(
        children: [
          SegmentedProgressBar(
            totalSegments: totalProblems,
            currentSegment: currentProblemIndex,
            results: problemResults,
          ),
          Expanded(
            child: exerciseContent,
          ),
        ],
      ),
    );
  }
}