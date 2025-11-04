import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../widgets/decompose10_level1_widget.dart';
import '../widgets/decompose10_level2_widget.dart';
import '../widgets/decompose10_level3_widget.dart';

/// Complete implementation of Z1: Decompose 10 exercise with 3-Level Scaffolding.
///
/// This exercise follows the framework documented in IMINT_TO_APP_FRAMEWORK.md
/// to properly answer "Wie kommt die Handlung in den Kopf?" (How does action become mental?)
///
/// **Level 1: Guided Exploration (Handlung)**
/// - Tap counters to flip them, equation auto-displays
/// - Pure exploration, no writing required
/// - Unlocks Level 2 after child explores (suggested at 5+ different ways)
///
/// **Level 2: Supported Practice (Vorstellung begins)**
/// - Visual counters shown with random decomposition
/// - Child must WRITE the equation
/// - Immediate feedback
/// - Unlocks Level 3 after 10 correct answers (80% accuracy)
///
/// **Level 3: Independent Mastery (Vorstellung → Symbol)**
/// - Visual HIDDEN by default
/// - Child writes from memory/mental imagery
/// - Visual appears ONLY on errors (no-fail safety net)
/// - Complete by finding all 11 decompositions
///
/// Source: PIKAS Card 9 (Zahlen zerlegen), iMINT decomposition_1, decomposition_3
class Decompose10Exercise extends StatefulWidget {
  final ExerciseConfig config;

  const Decompose10Exercise({super.key})
      : config = const ExerciseConfig(
          id: 'Z1',
          title: 'Decompose 10',
          skillTags: ['decomposition_1', 'decomposition_3'],
          sourceCard: 'PIKAS Card 9: Zahlen zerlegen',
          concept: 'Understanding part-whole relationships: 10 can be split into pairs',
          observationPoints: [
            'Gegensinniges Verändern: As one part increases (+1), other decreases (-1)',
            'Systematic finding: Can child find ALL decompositions?',
            'Pattern recognition through 3-level progression',
          ],
          internalizationPath:
              'Level 1 (Handlung) → Level 2 (Vorstellung begins) → Level 3 (Vorstellung → Symbol)',
          targetNumber: 10,
          expectedDecompositions: 11,
          hints: [
            'Try flipping the counters to see different combinations.',
            'Have you found them all? How do you know?',
          ],
        );

  @override
  State<Decompose10Exercise> createState() => _Decompose10ExerciseState();
}

class _Decompose10ExerciseState extends State<Decompose10Exercise> {
  ScaffoldProgress _progress = const ScaffoldProgress();

  // Level 2 tracking
  int _level2Correct = 0;
  static const int _level2RequiredCorrect = 10;

  // Level 3 tracking
  int _level3Found = 0;

  void _onLevel1Complete() {
    setState(() {
      _progress = _progress.copyWith(
        level1Complete: true,
        currentLevel: ScaffoldLevel.supportedPractice,
      );
    });

    _showLevelUnlockedMessage(ScaffoldLevel.supportedPractice);
  }

  void _onLevel2Answer(bool correct) {
    setState(() {
      if (correct) {
        _level2Correct++;
      }

      // Check if Level 3 should unlock (10+ correct answers)
      if (_level2Correct >= _level2RequiredCorrect && !_progress.level3Unlocked) {
        _progress = _progress.copyWith(level3Unlocked: true);
        _showLevelUnlockedMessage(ScaffoldLevel.independentMastery);
      }
    });
  }

  void _onLevel3Progress(int foundCount) {
    setState(() {
      _level3Found = foundCount;
    });
  }

  void _switchLevel(ScaffoldLevel newLevel) {
    // Check if level is unlocked
    if (newLevel == ScaffoldLevel.supportedPractice && !_progress.level2Unlocked) {
      _showLockedMessage(newLevel);
      return;
    }
    if (newLevel == ScaffoldLevel.independentMastery && !_progress.level3Unlocked) {
      _showLockedMessage(newLevel);
      return;
    }

    setState(() {
      _progress = _progress.copyWith(currentLevel: newLevel);
    });
  }

  void _showLevelUnlockedMessage(ScaffoldLevel level) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Level ${level.levelNumber} Unlocked: ${level.displayName}!',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLockedMessage(ScaffoldLevel level) {
    String requirement = '';
    if (level == ScaffoldLevel.supportedPractice) {
      requirement = 'Complete Level 1 exploration first';
    } else if (level == ScaffoldLevel.independentMastery) {
      final remaining = _level2RequiredCorrect - _level2Correct;
      requirement = 'Get $remaining more correct in Level 2';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Level ${level.levelNumber} is locked. $requirement.',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

          // Divider
          const Divider(height: 1),

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
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _buildLevelTab(
            level: ScaffoldLevel.guidedExploration,
            icon: Icons.touch_app,
            color: Colors.blue,
            isUnlocked: true,
          ),
          const SizedBox(width: 8),
          _buildLevelTab(
            level: ScaffoldLevel.supportedPractice,
            icon: Icons.edit,
            color: Colors.purple,
            isUnlocked: _progress.level2Unlocked,
            progressText: '$_level2Correct/$_level2RequiredCorrect',
          ),
          const SizedBox(width: 8),
          _buildLevelTab(
            level: ScaffoldLevel.independentMastery,
            icon: Icons.psychology,
            color: Colors.green,
            isUnlocked: _progress.level3Unlocked,
            progressText: '$_level3Found/11',
          ),
        ],
      ),
    );
  }

  Widget _buildLevelTab({
    required ScaffoldLevel level,
    required IconData icon,
    required Color color,
    required bool isUnlocked,
    String? progressText,
  }) {
    final isActive = _progress.currentLevel == level;

    return Expanded(
      child: GestureDetector(
        onTap: () => _switchLevel(level),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive
                ? color.withOpacity(0.2)
                : (isUnlocked ? Colors.white : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? color : (isUnlocked ? Colors.grey.shade400 : Colors.grey.shade500),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isUnlocked ? icon : Icons.lock,
                    color: isUnlocked ? color : Colors.grey.shade600,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'L${level.levelNumber}',
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      fontSize: 10,
                      color: isUnlocked ? color : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (progressText != null && isUnlocked)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    progressText,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLevel() {
    switch (_progress.currentLevel) {
      case ScaffoldLevel.guidedExploration:
        return Decompose10Level1Widget(
          onExplorationComplete: _onLevel1Complete,
        );

      case ScaffoldLevel.supportedPractice:
        return Decompose10Level2Widget(
          onAnswerSubmitted: _onLevel2Answer,
          correctAnswersNeeded: _level2RequiredCorrect,
          currentCorrectCount: _level2Correct,
        );

      case ScaffoldLevel.independentMastery:
        return Decompose10Level3Widget(
          onProgressUpdate: _onLevel3Progress,
        );

      case ScaffoldLevel.advancedChallenge:
        // This exercise doesn't use a 4th level
        return const SizedBox.shrink();

      case ScaffoldLevel.finale:
        // Finale level not yet implemented for this exercise
        return const Center(
          child: Text('Finale level coming soon!'),
        );
    }
  }

  void _showExerciseInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.school, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Expanded(child: Text('Exercise Information')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.config.concept,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const Text(
                '3-Level Scaffolding:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _infoLevel('Level 1: Guided Exploration',
                  'Tap counters to explore. Equation auto-displays.', Colors.blue),
              const SizedBox(height: 8),
              _infoLevel('Level 2: Supported Practice',
                  'See counters, write the equation yourself.', Colors.purple),
              const SizedBox(height: 8),
              _infoLevel('Level 3: Independent Mastery',
                  'Visual hidden. Work from memory!', Colors.green),
              const SizedBox(height: 16),
              Text(
                'Source: ${widget.config.sourceCard}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoLevel(String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle, color: color, size: 12),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
              Text(description, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
