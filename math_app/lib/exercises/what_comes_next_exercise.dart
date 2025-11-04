import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../widgets/whatcomesnext_level1_widget.dart';
import '../widgets/whatcomesnext_level2_widget.dart';
import '../widgets/whatcomesnext_level3_widget.dart';

/// Complete implementation of C4.1: What Comes Next? exercise with 3-Level Scaffolding.
///
/// This exercise follows the framework documented in IMINT_TO_APP_FRAMEWORK.md
/// to properly answer "Wie kommt die Handlung in den Kopf?" (How does action become mental?)
///
/// **Level 1: Guided Exploration (Handlung)**
/// - Interactive number line exploration
/// - Click any number to select it
/// - Tap "Before" or "After" buttons to see predecessor/successor highlighted
/// - Visual arrows and animations show the relationship
/// - Purpose: SEE the before/after relationship on number line
///
/// **Level 2: Supported Practice (Vorstellung begins)**
/// - Number line visible with target number highlighted
/// - Child must WRITE both predecessor AND successor
/// - Two input fields (before/after)
/// - Immediate validation feedback
/// - Purpose: Connect visual to writing both directions
/// - Unlocks Level 3 after 10 correct answers
///
/// **Level 3: Independent Mastery (Vorstellung → Symbol)**
/// - Number line HIDDEN by default
/// - Three problem types for variety:
///   1. Given number, write before AND after
///   2. Fill the gap: _, X, _
///   3. Sequence: Find missing: X, _, Y
/// - Number line appears ONLY on errors (no-fail safety net)
/// - Adaptive difficulty increases range
/// - Purpose: Internalize predecessor/successor ("in den Kopf")
///
/// **Pedagogical Goal:** Build understanding of predecessor and successor from
/// concrete visual exploration to abstract mental recall.
///
/// **Skills:** counting_4 (predecessor), counting_5 (successor)
///
/// Source: iMINT Green Card 4: Vorgänger/Nachfolger
class WhatComesNextExercise extends StatefulWidget {
  final ExerciseConfig config;

  const WhatComesNextExercise({super.key})
      : config = const ExerciseConfig(
          id: 'C4.1',
          title: 'What Comes Next?',
          skillTags: ['counting_4', 'counting_5'],
          sourceCard: 'iMINT Green Card 4: Vorgänger/Nachfolger',
          concept:
              'Understanding predecessor (number before) and successor (number after) relationships',
          observationPoints: [
            'Can child identify the number that comes before?',
            'Can child identify the number that comes after?',
            'Does child understand the +1/-1 relationship?',
            'Can child work bidirectionally (before AND after)?',
          ],
          internalizationPath:
              'Level 1 (See before/after visually) → Level 2 (Write with support) → Level 3 (Recall from memory)',
          targetNumber: 20, // Working within 0-20
          hints: [
            'The number BEFORE is one less (subtract 1).',
            'The number AFTER is one more (add 1).',
            'Count backwards for "before", forwards for "after".',
            'Imagine the numbers in a line in your mind.',
          ],
        );

  @override
  State<WhatComesNextExercise> createState() => _WhatComesNextExerciseState();
}

class _WhatComesNextExerciseState extends State<WhatComesNextExercise> {
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
                'Learn about predecessor (before) and successor (after) with 3 levels:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildLevelInfo(
                'Level 1: Guided Exploration',
                'Click numbers and explore which numbers come before and after using the buttons.',
                Colors.blue,
                Icons.touch_app,
              ),
              const SizedBox(height: 12),
              _buildLevelInfo(
                'Level 2: Supported Practice',
                'See the number on the line and write what comes before and after it.',
                Colors.orange,
                Icons.create,
              ),
              const SizedBox(height: 12),
              _buildLevelInfo(
                'Level 3: Independent Mastery',
                'Find the predecessor and successor from memory! Various challenge types.',
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
        progressText = 'Explore before and after on the number line!';
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
        return WhatComesNextLevel1Widget(
          onReadyForNextLevel: _onLevel1Complete,
        );

      case ScaffoldLevel.supportedPractice:
        return WhatComesNextLevel2Widget(
          correctAnswersRequired: _level2RequiredCorrect,
          onProgressUpdate: _onLevel2ProgressUpdate,
        );

      case ScaffoldLevel.independentMastery:
        return WhatComesNextLevel3Widget(
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
