import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../widgets/countobjects_level1_widget.dart';
import '../widgets/countobjects_level2_widget.dart';
import '../widgets/countobjects_level3_widget.dart';

/// Complete implementation of C1.2: Count the Objects exercise with 3-Level Scaffolding.
///
/// This exercise follows the framework documented in IMINT_TO_APP_FRAMEWORK.md
/// to properly answer "Wie kommt die Handlung in den Kopf?" (How does action become mental?)
///
/// **Level 1: Guided Exploration (Handlung)**
/// - Tap each object (stars, hearts, circles, etc.) to count
/// - Counter auto-displays as child taps
/// - Pure exploration with various object types
/// - Unlocks Level 2 after child counts 3 problems
///
/// **Level 2: Supported Practice (Vorstellung begins)**
/// - Structured objects displayed (apples, books, toys, animals)
/// - Child must WRITE the number they counted
/// - Immediate feedback with emoji representations
/// - Unlocks Level 3 after 10 correct answers
///
/// **Level 3: Independent Mastery (Vorstellung → Symbol)**
/// - Objects FLASH briefly (2 seconds), then HIDDEN
/// - Child counts from memory/mental imagery
/// - Objects appear ONLY on errors (no-fail safety net)
/// - Difficulty increases adaptively
///
/// **Pedagogical Goal:** Build counting ability with diverse objects - from concrete (tap) to abstract (mental)
///
/// **Difference from C1.1:** Uses various object types instead of uniform dots,
/// teaching that counting works with any objects (abstraction of counting concept)
///
/// Source: iMINT counting_1 (Objects counting / Gegenstände zählen)
class CountObjectsExercise extends StatefulWidget {
  final ExerciseConfig config;

  const CountObjectsExercise({super.key})
      : config = const ExerciseConfig(
          id: 'C1.2',
          title: 'Count the Objects',
          skillTags: ['counting_1'],
          sourceCard: 'iMINT Green Card 1: Gegenstände zählen',
          concept:
              'Understanding that counting applies to any objects - abstraction of one-to-one correspondence',
          observationPoints: [
            'Does child recognize that counting works the same for different objects?',
            'Can child count diverse visual representations equally well?',
            'Does object type affect counting accuracy?',
          ],
          internalizationPath:
              'Level 1 (Tap objects to count) → Level 2 (See objects and write) → Level 3 (Imagine objects and count)',
          targetNumber: 15, // Max objects in problems
          hints: [
            'It doesn\'t matter what the objects are - count them the same way!',
            'Try counting in order: left to right, top to bottom.',
            'Close your eyes and picture the objects you just saw.',
          ],
        );

  @override
  State<CountObjectsExercise> createState() => _CountObjectsExerciseState();
}

class _CountObjectsExerciseState extends State<CountObjectsExercise> {
  ScaffoldProgress _progress = const ScaffoldProgress();

  // Level 2 tracking
  int _level2Correct = 0;
  static const int _level2RequiredCorrect = 10;

  // Level 3 tracking
  int _level3Correct = 0;

  void _onLevel1Complete() {
    setState(() {
      _progress = _progress.copyWith(
        level1Complete: true,
        currentLevel: ScaffoldLevel.supportedPractice,
      );
    });

    _showLevelUnlockedMessage(ScaffoldLevel.supportedPractice);
  }

  void _onLevel2ProgressUpdate(int correctCount) {
    setState(() {
      _level2Correct = correctCount;
      _progress = _progress.copyWith(
        level2Correct: correctCount,
        level2Total: _progress.level2Total + 1,
      );

      // Unlock Level 3 after reaching required correct answers
      if (correctCount >= _level2RequiredCorrect && !_progress.level3Unlocked) {
        _progress = _progress.copyWith(
          level3Unlocked: true,
          currentLevel: ScaffoldLevel.independentMastery,
        );
        _showLevelUnlockedMessage(ScaffoldLevel.independentMastery);
      }
    });
  }

  void _onLevel3ProgressUpdate(int correctCount) {
    setState(() {
      _level3Correct = correctCount;
    });
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
                '${level.displayName} unlocked! 🎉',
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
            'Complete Level 2 with $_level2RequiredCorrect correct answers first!';
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
                'This exercise uses 3 levels to help you master counting with various objects:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildLevelInfo(
                'Level 1: Guided Exploration',
                'Tap each object (stars, hearts, shapes) and watch the counter grow.',
                Colors.blue,
                Icons.touch_app,
              ),
              const SizedBox(height: 12),
              _buildLevelInfo(
                'Level 2: Supported Practice',
                'See the objects (apples, books, animals) and write how many.',
                Colors.orange,
                Icons.create,
              ),
              const SizedBox(height: 12),
              _buildLevelInfo(
                'Level 3: Independent Mastery',
                'The objects flash, then hide. Count from memory!',
                Colors.purple,
                Icons.visibility_off,
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
                  'Learn that counting works the same for any objects - dots, shapes, or things!',
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
                    Icons.visibility_off,
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
        progressText = 'Explore freely - tap objects to count!';
        progressValue = 0.0;
        progressColor = Colors.blue;
        break;
      case ScaffoldLevel.supportedPractice:
        progressText =
            'Progress: $_level2Correct/$_level2RequiredCorrect to unlock Level 3';
        progressValue = _level2Correct / _level2RequiredCorrect;
        progressColor = Colors.orange;
        break;
      case ScaffoldLevel.independentMastery:
        progressText = 'Mastery Level - Correct: $_level3Correct';
        progressValue = 1.0;
        progressColor = Colors.purple;
        break;
      case ScaffoldLevel.advancedChallenge:
        progressText = '';
        progressValue = 0.0;
        progressColor = Colors.grey;
        break;

      default:
        // Finale level not yet implemented
        return const Center(child: Text('Finale level coming soon!'));
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
        return CountObjectsLevel1Widget(
          numberOfObjects: 8, // Start with 8 objects
          onReadyForNextLevel: _onLevel1Complete,
        );

      case ScaffoldLevel.supportedPractice:
        return CountObjectsLevel2Widget(
          correctAnswersRequired: _level2RequiredCorrect,
          onProgressUpdate: _onLevel2ProgressUpdate,
        );

      case ScaffoldLevel.independentMastery:
        return CountObjectsLevel3Widget(
          onProgressUpdate: _onLevel3ProgressUpdate,
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
