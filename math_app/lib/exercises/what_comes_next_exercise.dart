import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/whatcomesnext_level1_widget.dart';
import '../widgets/whatcomesnext_level2_widget.dart';
import '../widgets/whatcomesnext_level3_widget.dart';
import '../widgets/whatcomesnext_level4_widget.dart';
import '../widgets/whatcomesnext_level5_widget.dart';

/// Complete implementation of C4.1: What Comes Next? exercise with 5-Level Scaffolding.
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
/// - Unlocks Level 4 after 8 correct answers
///
/// **Level 4: Advanced Challenge (Extended Sequences)**
/// - Two-number sequences: "17, ___, ___" or "___, ___, 20"
/// - Child fills in TWO consecutive numbers (forward or backward)
/// - Tests deeper pattern recognition
/// - Adaptive difficulty: 5-15 (easy) → 1-19 (hard)
/// - Unlocks Level 5 (finale) after 5 correct answers
///
/// **Level 5: Finale (ADHD-Friendly Victory Lap)**
/// - Easier mixed review: before/after with narrower range (5-15)
/// - Completion criteria: 10 problems, 0 errors, <20s per problem
/// - Status: "finished" → "completed" when criteria met
/// - Victory celebration on completion
///
/// **COMPLETION CRITERIA (Level 5 Finale):**
/// - Minimum problems: 10
/// - Accuracy required: 100% (zero errors in last 10 problems)
/// - Time limit: 20 seconds per problem
/// - Status: "finished" → "completed" when all criteria met
///
/// **State Persistence:**
/// - Progress saves every 5 problems via ExerciseProgressMixin
/// - Progress saves on exit (WillPopScope/dispose)
/// - Level unlocks persist across app restarts
/// - Child can exit and resume from same point
///
/// **Pedagogical Goal:** Build understanding of predecessor and successor from
/// concrete visual exploration to abstract mental recall, with extended pattern work.
///
/// **Skills:** counting_4 (predecessor), counting_5 (successor)
///
/// Source: iMINT Green Card 4: Vorgänger/Nachfolger
class WhatComesNextExercise extends StatefulWidget {
  final ExerciseConfig config;
  final UserProfile userProfile;

  const WhatComesNextExercise({
    super.key,
    required this.userProfile,
  }) : config = const ExerciseConfig(
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
              'Level 1 (See before/after visually) → Level 2 (Write with support) → Level 3 (Recall from memory) → Level 4 (Extended sequences) → Level 5 (Finale easier review)',
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

class _WhatComesNextExerciseState extends State<WhatComesNextExercise>
    with ExerciseProgressMixin {
  // Mixin requirements
  @override
  String get exerciseId => widget.config.id;

  @override
  UserProfile get userProfile => widget.userProfile;

  @override
  int get totalLevels => 5; // 3 card levels + 1 challenge + 1 finale

  @override
  int get finaleLevelNumber => 5;

  @override
  int get problemTimeLimit => 20; // 20 seconds per problem

  @override
  int get finaleMinProblems => 10;

  // UI state
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration;
  late ScaffoldProgress _progress;

  // Level tracking (for UI/unlocking logic)
  int _level1Explorations = 0;
  int _level2Correct = 0;
  int _level3Correct = 0;
  int _level4Correct = 0;

  static const int _level2RequiredCorrect = 10;
  static const int _level3RequiredCorrect = 8; // Unlock L4
  static const int _level4RequiredCorrect = 5; // Unlock L5

  @override
  void initState() {
    super.initState();
    _progress = ScaffoldProgress();
    _initializeExercise();
  }

  Future<void> _initializeExercise() async {
    await initializeProgress();

    // Restore unlocked levels from saved progress
    setState(() {
      if (isLevelUnlocked(2)) {
        _progress = _progress.copyWith(level1Complete: true);
      }
      if (isLevelUnlocked(3)) {
        _progress = _progress.copyWith(level3Unlocked: true);
      }
      if (isLevelUnlocked(4)) {
        _progress = _progress.copyWith(level4Unlocked: true);
      }
      if (isLevelUnlocked(5)) {
        // Finale unlocked
      }
    });
  }

  @override
  void dispose() {
    onExerciseExit(); // Save progress on exit
    super.dispose();
  }

  void _onLevel1Progress(int explorations) async {
    setState(() {
      _level1Explorations = explorations;
    });

    // Unlock Level 2 after 5 explorations
    if (_level1Explorations >= 5 && !isLevelUnlocked(2)) {
      await unlockLevel(2);
      setState(() {
        _progress = _progress.copyWith(level1Complete: true);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Level 2 Unlocked! Now practice with support!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onLevel2Progress(int correct) async {
    setState(() {
      _level2Correct = correct;
    });

    // Unlock Level 3 after 10 correct
    if (_level2Correct >= _level2RequiredCorrect && !isLevelUnlocked(3)) {
      await unlockLevel(3);
      setState(() {
        _progress = _progress.copyWith(level3Unlocked: true);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Level 3 Unlocked! Test your memory!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onLevel3Progress(int correct) async {
    setState(() {
      _level3Correct = correct;
    });

    // Unlock Level 4 after 8 correct in Level 3
    if (_level3Correct >= _level3RequiredCorrect && !isLevelUnlocked(4)) {
      await unlockLevel(4);
      setState(() {
        _progress = _progress.copyWith(level4Unlocked: true);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Level 4 Unlocked! Extended sequence challenge!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onLevel4Progress(int correct) async {
    setState(() {
      _level4Correct = correct;
    });

    // Unlock Level 5 (finale) after 5 correct in Level 4
    if (_level4Correct >= _level4RequiredCorrect && !isLevelUnlocked(5)) {
      await unlockLevel(5);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Finale Unlocked! Easier review to complete!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onLevelSelected(ScaffoldLevel level) {
    // Map ScaffoldLevel to level number
    int levelNumber;
    switch (level) {
      case ScaffoldLevel.guidedExploration:
        levelNumber = 1;
        break;
      case ScaffoldLevel.supportedPractice:
        levelNumber = 2;
        break;
      case ScaffoldLevel.independentMastery:
        levelNumber = 3;
        break;
      case ScaffoldLevel.advancedChallenge:
        levelNumber = 4;
        break;
      case ScaffoldLevel.finale:
        levelNumber = 5;
        break;
    }

    // Check if level is unlocked using mixin
    if (isLevelUnlocked(levelNumber)) {
      setState(() {
        _currentLevel = level;
      });
    } else {
      // Show lock message
      String lockMessage;
      switch (levelNumber) {
        case 2:
          lockMessage = 'Complete 5 explorations in Level 1 first!';
          break;
        case 3:
          lockMessage = 'Get $_level2RequiredCorrect correct answers in Level 2 first!';
          break;
        case 4:
          lockMessage = 'Get $_level3RequiredCorrect correct answers in Level 3 first!';
          break;
        case 5:
          lockMessage = 'Get $_level4RequiredCorrect correct answers in Level 4 first!';
          break;
        default:
          lockMessage = 'This level is locked.';
      }

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
                'Learn about predecessor (before) and successor (after) with 5 levels:',
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
              const SizedBox(height: 12),
              _buildLevelInfo(
                'Level 4: Extended Sequences',
                'Fill in TWO consecutive numbers! Example: 17, ___, ___ or ___, ___, 20',
                Colors.deepPurple,
                Icons.extension,
              ),
              const SizedBox(height: 12),
              _buildLevelInfo(
                'Level 5: Finale',
                'Easier mixed review to show your mastery! Complete 10 problems to finish.',
                Colors.green,
                Icons.celebration,
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
                    'L1',
                    Colors.blue,
                    Icons.touch_app,
                    isLevelUnlocked(1),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildLevelButton(
                    ScaffoldLevel.supportedPractice,
                    'L2',
                    Colors.orange,
                    Icons.create,
                    isLevelUnlocked(2),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildLevelButton(
                    ScaffoldLevel.independentMastery,
                    'L3',
                    Colors.purple,
                    Icons.psychology,
                    isLevelUnlocked(3),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildLevelButton(
                    ScaffoldLevel.advancedChallenge,
                    'L4',
                    Colors.deepPurple,
                    Icons.extension,
                    isLevelUnlocked(4),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildLevelButton(
                    ScaffoldLevel.finale,
                    'L5',
                    Colors.green,
                    Icons.celebration,
                    isLevelUnlocked(5),
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
    bool showProgressBar = false;

    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        progressText = 'Explore: $_level1Explorations explorations (5 to unlock Level 2)';
        progressValue = _level1Explorations / 5.0;
        progressColor = Colors.blue;
        showProgressBar = true;
        break;
      case ScaffoldLevel.supportedPractice:
        progressText = 'Practice: $_level2Correct/$_level2RequiredCorrect correct (unlock Level 3)';
        progressValue = _level2Correct / _level2RequiredCorrect;
        progressColor = Colors.orange;
        showProgressBar = true;
        break;
      case ScaffoldLevel.independentMastery:
        progressText = 'Mastery: $_level3Correct/$_level3RequiredCorrect correct (unlock Level 4)';
        progressValue = _level3Correct / _level3RequiredCorrect;
        progressColor = Colors.purple;
        showProgressBar = true;
        break;
      case ScaffoldLevel.advancedChallenge:
        progressText = 'Challenge: $_level4Correct/$_level4RequiredCorrect correct (unlock Finale)';
        progressValue = _level4Correct / _level4RequiredCorrect;
        progressColor = Colors.deepPurple;
        showProgressBar = true;
        break;
      case ScaffoldLevel.finale:
        final finaleProgress = getLevelProgress(5);
        final finaleCorrect = finaleProgress?.correctAnswers ?? 0;
        final finaleTotal = finaleProgress?.totalAttempts ?? 0;
        final accuracy = finaleTotal > 0
            ? ((finaleCorrect / finaleTotal) * 100).toStringAsFixed(0)
            : '0';
        progressText = 'Finale: $finaleCorrect correct | Accuracy: $accuracy% (Need 10 with 100%)';
        progressValue = (finaleCorrect / 10).clamp(0.0, 1.0);
        progressColor = Colors.green;
        showProgressBar = true;
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
          if (showProgressBar) ...[
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
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        return WhatComesNextLevel1Widget(
          onProgressUpdate: _onLevel1Progress,
        );

      case ScaffoldLevel.supportedPractice:
        return WhatComesNextLevel2Widget(
          onProgressUpdate: _onLevel2Progress,
          onStartProblemTimer: startProblemTimer,
          onProblemComplete: (correct, userAnswer) async {
            await recordProblemResult(
              levelNumber: 2,
              correct: correct,
              userAnswer: userAnswer,
            );
          },
        );

      case ScaffoldLevel.independentMastery:
        return WhatComesNextLevel3Widget(
          onProgressUpdate: _onLevel3Progress,
          onStartProblemTimer: startProblemTimer,
          onProblemComplete: (correct, userAnswer) async {
            await recordProblemResult(
              levelNumber: 3,
              correct: correct,
              userAnswer: userAnswer,
            );
          },
        );

      case ScaffoldLevel.advancedChallenge:
        return WhatComesNextLevel4Widget(
          onProgressUpdate: _onLevel4Progress,
          onStartProblemTimer: startProblemTimer,
          onProblemComplete: (correct, userAnswer) async {
            await recordProblemResult(
              levelNumber: 4,
              correct: correct,
              userAnswer: userAnswer,
            );
          },
        );

      case ScaffoldLevel.finale:
        return WhatComesNextLevel5Widget(
          onStartProblemTimer: startProblemTimer,
          onProblemComplete: (correct, userAnswer) async {
            await recordProblemResult(
              levelNumber: 5,
              correct: correct,
              userAnswer: userAnswer,
            );
          },
        );
    }
  }
}
