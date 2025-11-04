import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../widgets/countforward_level1_widget.dart';
import '../widgets/countforward_level2_widget.dart';
import '../widgets/countforward_level3_widget.dart';

/// Complete implementation of C3.1: Count Forward to 20 exercise with 3-Level Scaffolding.
///
/// This exercise follows the framework documented in IMINT_TO_APP_FRAMEWORK.md
/// to properly answer "Wie kommt die Handlung in den Kopf?" (How does action become mental?)
///
/// **Level 1: Guided Exploration (Handlung)**
/// - Interactive number line with forward/backward hopping
/// - Tap arrows to move position marker
/// - Current position displays prominently with animation
/// - Trail shows where they've been
/// - Purpose: SEE the forward counting sequence through movement
///
/// **Level 2: Supported Practice (Vorstellung begins)**
/// - Number line visible with starting position marked
/// - Child must WRITE the next 3-5 numbers in sequence
/// - Immediate validation feedback
/// - Purpose: Connect visual position to writing number sequence
/// - Unlocks Level 3 after 10 correct sequences
///
/// **Level 3: Independent Mastery (Vorstellung → Symbol)**
/// - Number line HIDDEN by default
/// - Child counts forward from memory
/// - Given starting number, writes next numbers without visual support
/// - Number line appears ONLY on errors (no-fail safety net)
/// - Adaptive difficulty increases with performance
/// - Purpose: Internalize counting sequence ("in den Kopf")
///
/// **Pedagogical Goal:** Build forward counting fluency from concrete movement
/// to abstract mental counting.
///
/// **Skills:** counting_3 (forward/backward counting on number line)
///
/// Source: iMINT Green Card 3: Zahlenreihe vor- und rückwärts
class CountForwardExercise extends StatefulWidget {
  final ExerciseConfig config;

  const CountForwardExercise({super.key})
      : config = const ExerciseConfig(
          id: 'C3.1',
          title: 'Count Forward to 20',
          skillTags: ['counting_3'],
          sourceCard: 'iMINT Green Card 3: Zahlenreihe vor- und rückwärts',
          concept:
              'Understanding the number sequence: counting forward and backward on a number line',
          observationPoints: [
            'Can child count forward fluently without errors?',
            'Does child understand position on number line?',
            'Can child count forward from any starting position?',
            'Is counting automatic or does child still need to "figure it out"?',
          ],
          internalizationPath:
              'Level 1 (Hop on line, see sequence) → Level 2 (See position, write sequence) → Level 3 (Count from memory)',
          targetNumber: 20, // Count up to 20
          hints: [
            'Each hop forward adds 1 to the number.',
            'Count in your head: add 1 each time.',
            'Imagine the number line in your mind.',
            'What number comes RIGHT AFTER this one?',
          ],
        );

  @override
  State<CountForwardExercise> createState() => _CountForwardExerciseState();
}

class _CountForwardExerciseState extends State<CountForwardExercise> {
  ScaffoldProgress _progress = const ScaffoldProgress();

  void _onLevel1Complete() {
    setState(() {
      _progress = _progress.copyWith(
        level1Complete: true,
        currentLevel: ScaffoldLevel.supportedPractice,
      );
    });

    _showLevelUnlockedMessage(ScaffoldLevel.supportedPractice);
  }

  void _showLevelUnlockedMessage(ScaffoldLevel level) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_open, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${level.displayName} unlocked!',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onLevelSelected(ScaffoldLevel level) {
    // Check if level is unlocked
    bool isUnlocked = false;
    String lockMessage = '';

    switch (level) {
      case ScaffoldLevel.guidedExploration:
        isUnlocked = true; // Always unlocked
        break;
      case ScaffoldLevel.supportedPractice:
        isUnlocked = _progress.level2Unlocked;
        lockMessage = 'Complete Level 1 first!';
        break;
      case ScaffoldLevel.independentMastery:
        isUnlocked = _progress.level3Unlocked;
        lockMessage =
            'Complete Level 2 first!';
        break;
      case ScaffoldLevel.advancedChallenge:
        isUnlocked = false;
        lockMessage = 'Not available for this exercise';
        break;
      case ScaffoldLevel.finale:
        isUnlocked = false;
        lockMessage = 'Finale level not yet implemented';
        break;
    }

    if (isUnlocked) {
      setState(() {
        _progress = _progress.copyWith(currentLevel: level);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(lockMessage)),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 12),
            Text('About This Exercise'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Learn to count forward fluently with 3 levels:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildLevelInfo(
                'Level 1: Guided Exploration',
                'Hop on the number line. See how numbers increase as you move forward.',
                Colors.blue,
                Icons.touch_app,
              ),
              const SizedBox(height: 12),
              _buildLevelInfo(
                'Level 2: Supported Practice',
                'Look at the starting position and write the next numbers in order.',
                Colors.orange,
                Icons.create,
              ),
              const SizedBox(height: 12),
              _buildLevelInfo(
                'Level 3: Independent Mastery',
                'Count forward from memory! No number line - use your mental counting skills.',
                Colors.purple,
                Icons.psychology,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  'You can switch between levels anytime for more practice!',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelInfo(
      String title, String description, Color color, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
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
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildLevelButton(
                    ScaffoldLevel.guidedExploration,
                    'Level 1',
                    Colors.blue,
                    Icons.touch_app,
                    true, // Always unlocked
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildLevelButton(
                    ScaffoldLevel.supportedPractice,
                    'Level 2',
                    Colors.orange,
                    Icons.create,
                    _progress.level2Unlocked,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildLevelButton(
                    ScaffoldLevel.independentMastery,
                    'Level 3',
                    Colors.purple,
                    Icons.psychology,
                    _progress.level3Unlocked,
                  ),
                ),
              ],
            ),
          ),

          // Progress indicator for current level
          _buildLevelProgressIndicator(),

          // Current level content
          Expanded(
            child: _buildCurrentLevelWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelButton(
    ScaffoldLevel level,
    String label,
    Color color,
    IconData icon,
    bool isUnlocked,
  ) {
    final bool isActive = _progress.currentLevel == level;

    return GestureDetector(
      onTap: () => _onLevelSelected(level),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isUnlocked ? icon : Icons.lock,
              color: isActive ? Colors.white : (isUnlocked ? color : Colors.grey),
              size: 14,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : (isUnlocked ? color : Colors.grey),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelProgressIndicator() {
    String progressText = '';
    double progressValue = 0.0;
    Color progressColor = Colors.blue;

    switch (_progress.currentLevel) {
      case ScaffoldLevel.guidedExploration:
        progressText = 'Explore the number line - hop forward and backward!';
        progressValue = 0.0;
        progressColor = Colors.blue;
        break;
      case ScaffoldLevel.supportedPractice:
        progressText = 'Level 2: Walking Marker - Practice counting!';
        progressValue = 0.5;
        progressColor = Colors.orange;
        break;
      case ScaffoldLevel.independentMastery:
        progressText = 'Level 3: Mental Counting - Test your memory!';
        progressValue = 1.0;
        progressColor = Colors.purple;
        break;
      case ScaffoldLevel.advancedChallenge:
        progressText = '';
        progressValue = 0.0;
        progressColor = Colors.grey;
        break;
      case ScaffoldLevel.finale:
        progressText = 'Finale: Final review!';
        progressValue = 1.0;
        progressColor = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: progressColor.withOpacity(0.1),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  progressText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: progressColor.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          if (_progress.currentLevel == ScaffoldLevel.supportedPractice) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentLevelWidget() {
    switch (_progress.currentLevel) {
      case ScaffoldLevel.guidedExploration:
        return CountForwardLevel1Widget(
          onProblemComplete: (_) {},
          onLevelComplete: _onLevel1Complete,
        );

      case ScaffoldLevel.supportedPractice:
        return CountForwardLevel2Widget(
          onProblemComplete: (_) {},
          onLevelComplete: () {
            setState(() {
              _progress = _progress.copyWith(
                level3Unlocked: true,
                currentLevel: ScaffoldLevel.independentMastery,
              );
            });
            _showLevelUnlockedMessage(ScaffoldLevel.independentMastery);
          },
        );

      case ScaffoldLevel.independentMastery:
        return CountForwardLevel3Widget(
          onProblemComplete: (_) {},
          onLevelComplete: () {
            // Level complete!
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Congratulations! You\'ve mastered counting forward!'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          },
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
}
