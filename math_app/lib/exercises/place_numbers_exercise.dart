import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../widgets/placenumbers_level1_widget.dart';
import '../widgets/placenumbers_level2_widget.dart';
import '../widgets/placenumbers_level3_widget.dart';

/// Complete implementation of EX-C10.1: Place Numbers on Line exercise with 3-Level Scaffolding.
///
/// This exercise follows the framework documented in IMINT_TO_APP_FRAMEWORK.md
/// to properly answer "Wie kommt die Handlung in den Kopf?" (How does action become mental?)
///
/// **Level 1: Guided Exploration (Handlung)**
/// - Interactive drag-and-drop: child drags number cards to positions on line
/// - Visual feedback: green for correct, red for incorrect
/// - Purpose: SEE where numbers belong through concrete placement
/// - Builds spatial understanding of number positions
///
/// **Level 2: Supported Practice (Vorstellung begins)**
/// - Number line visible with marked positions
/// - Given a number, child must type where it belongs
/// - Immediate validation feedback with hints
/// - Purpose: Connect visual spacing to numerical position
/// - Unlocks Level 3 after 10 correct placements
///
/// **Level 3: Independent Mastery (Vorstellung → Symbol)**
/// - Number line HIDDEN by default
/// - Child works from mental imagery of number line
/// - Line appears briefly ONLY on errors (no-fail safety net)
/// - Adaptive difficulty: expands range as child succeeds
/// - Purpose: Internalize number line structure ("in den Kopf")
///
/// **Pedagogical Goal:** Build deep understanding of number positioning on
/// number line, from concrete manipulation to mental imagery.
///
/// **Skills:** counting_10 (number line positioning), counting_11 (spatial number sense)
///
/// Source: iMINT Green Card 10: Zahlen am Zahlenstrahl positionieren
/// Also relates to PIKAS representation skills
class PlaceNumbersExercise extends StatefulWidget {
  final ExerciseConfig config;

  const PlaceNumbersExercise({super.key})
      : config = const ExerciseConfig(
          id: 'C10.1',
          title: 'Place Numbers on Line',
          skillTags: ['counting_10', 'counting_11'],
          sourceCard: 'iMINT Green Card 10: Zahlen am Zahlenstrahl positionieren',
          concept:
              'Understanding number position: numbers have specific spatial positions on a number line',
          observationPoints: [
            'Can child understand relative position (closer to 0 or 20)?',
            'Does child recognize equal spacing between numbers?',
            'Can child estimate positions without counting from 0?',
            'Is positioning becoming automatic or does child still count?',
          ],
          internalizationPath:
              'Level 1 (Drag to place, see feedback) → Level 2 (Estimate with visual) → Level 3 (Mental positioning)',
          targetNumber: 20, // Work with numbers 0-20
          hints: [
            'Think about where the number sits between 0 and 20.',
            'Is this number closer to the beginning or the end?',
            'Imagine dividing the line into equal parts.',
            'Numbers are evenly spaced - each step is the same size.',
          ],
        );

  @override
  State<PlaceNumbersExercise> createState() => _PlaceNumbersExerciseState();
}

class _PlaceNumbersExerciseState extends State<PlaceNumbersExercise> {
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration;
  late ScaffoldProgress _progress;

  // Level 1 tracking
  int _level1Problems = 0;

  // Level 2 tracking
  int _level2Correct = 0;
  int _level2Total = 0;

  // Level 3 tracking
  int _level3Correct = 0;

  @override
  void initState() {
    super.initState();
    _progress = ScaffoldProgress();
  }

  void _onLevel1Progress(int problemsSolved) {
    setState(() {
      _level1Problems = problemsSolved;

      // Unlock Level 2 after 5 problems
      if (_level1Problems >= 5 && !_progress.level2Unlocked) {
        _progress = _progress.copyWith(level1Complete: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Level 2 Unlocked! Now estimate positions with numbers.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _onLevel2Progress(int correct, int total) {
    setState(() {
      _level2Correct = correct;
      _level2Total = total;

      // Update progress tracker
      _progress = _progress.copyWith(
        level2Correct: correct,
        level2Total: total,
      );

      // Unlock Level 3 after 10 correct
      if (_level2Correct >= 10 && !_progress.level3Unlocked) {
        _progress = _progress.copyWith(level3Unlocked: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '🎉 Level 3 Unlocked! Challenge yourself with mental positioning!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _onLevel3Progress(int correct) {
    setState(() {
      _level3Correct = correct;
    });
  }

  void _switchLevel(ScaffoldLevel level) {
    if (level == ScaffoldLevel.supportedPractice && !_progress.level2Unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete Level 1 first to unlock Level 2!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (level == ScaffoldLevel.independentMastery && !_progress.level3Unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete Level 2 first to unlock Level 3!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _currentLevel = level;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Column(
        children: [
          // Level selector
          _buildLevelSelector(),

          // Current level progress
          _buildProgressIndicator(),

          // Current level content
          Expanded(
            child: _buildCurrentLevel(),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLevelButton(
            level: ScaffoldLevel.guidedExploration,
            label: 'Level 1',
            icon: Icons.touch_app,
            color: Colors.blue,
            isLocked: false,
          ),
          _buildLevelButton(
            level: ScaffoldLevel.supportedPractice,
            label: 'Level 2',
            icon: Icons.create,
            color: Colors.orange,
            isLocked: !_progress.level2Unlocked,
          ),
          _buildLevelButton(
            level: ScaffoldLevel.independentMastery,
            label: 'Level 3',
            icon: Icons.psychology,
            color: Colors.purple,
            isLocked: !_progress.level3Unlocked,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelButton({
    required ScaffoldLevel level,
    required String label,
    required IconData icon,
    required Color color,
    required bool isLocked,
  }) {
    final isActive = _currentLevel == level;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: isLocked ? null : () => _switchLevel(level),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? color : Colors.white,
            foregroundColor: isActive ? Colors.white : color,
            padding: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                color: isActive ? color : Colors.grey.shade400,
                width: isActive ? 2 : 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLocked ? Icons.lock : icon,
                size: 14,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    String progressText;
    Color backgroundColor;

    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        progressText = 'Problems solved: $_level1Problems (5 to unlock Level 2)';
        backgroundColor = Colors.blue.shade50;
        break;
      case ScaffoldLevel.supportedPractice:
        final accuracy = _level2Total > 0
            ? ((_level2Correct / _level2Total) * 100).toStringAsFixed(0)
            : '0';
        progressText =
            'Correct: $_level2Correct/10 | Accuracy: $accuracy% (10 to unlock Level 3)';
        backgroundColor = Colors.orange.shade50;
        break;
      case ScaffoldLevel.independentMastery:
        progressText = 'Mental placements: $_level3Correct';
        backgroundColor = Colors.purple.shade50;
        break;
      case ScaffoldLevel.advancedChallenge:
        progressText = '';
        backgroundColor = Colors.grey.shade50;
        break;

      default:
        // Finale level not yet implemented
        return const Center(child: Text('Finale level coming soon!'));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: backgroundColor,
      child: Row(
        children: [
          Expanded(
            child: Text(
              progressText,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLevel() {
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        return PlaceNumbersLevel1Widget(
          onProgressUpdate: _onLevel1Progress,
        );
      case ScaffoldLevel.supportedPractice:
        return PlaceNumbersLevel2Widget(
          onProgressUpdate: _onLevel2Progress,
        );
      case ScaffoldLevel.independentMastery:
        return PlaceNumbersLevel3Widget(
          onProgressUpdate: _onLevel3Progress,
        );
      case ScaffoldLevel.advancedChallenge:
        return const SizedBox.shrink();
      case ScaffoldLevel.finale:
        // Finale level not yet implemented for this exercise
        return const Center(
          child: Text('Finale level coming soon!'),
        );
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About This Exercise'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.config.concept,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '3-Level Learning Path:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildInfoSection(
                '📍 Level 1: Drag to Place',
                'Drag number cards to their correct positions. See where each number belongs!',
                Colors.blue,
              ),
              _buildInfoSection(
                '🎯 Level 2: Estimate Position',
                'Given a number, find its position on the line. Visual support helps you.',
                Colors.orange,
              ),
              _buildInfoSection(
                '🧠 Level 3: Mental Positioning',
                'Use your mental number line! No visual support - work from memory.',
                Colors.purple,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Key Learning Goals:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...widget.config.observationPoints.map((point) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 12)),
                              Expanded(
                                child: Text(point, style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.check_circle, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
