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
import '../widgets/common/instruction_modal.dart';
import '../widgets/common/level_selection_drawer.dart';
import '../widgets/common/segmented_progress_bar.dart';

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

  // Progress bar tracking
  List<bool> _currentLevelResults = [];
  int _currentLevelTotalProblems = 5; // Default for Level 1

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

  /// Get total problems for a given level
  int _getProblemsForLevel(int level) {
    switch (level) {
      case 1:
        return 5; // Level 1: 5 explorations
      case 2:
        return 10; // Level 2: 10 problems
      case 3:
        return 8; // Level 3: 8 problems
      case 4:
        return 5; // Level 4: 5 problems
      case 5:
        return 10; // Level 5 finale: 10 problems
      default:
        return 10;
    }
  }

  /// Called when a problem is completed
  void _onProblemComplete(bool correct) {
    setState(() {
      _currentLevelResults.add(correct);
    });
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
        // CRITICAL: Reset progress bar for next level
        _currentLevelResults = [];
        _currentLevelTotalProblems = _getProblemsForLevel(2);
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
        // CRITICAL: Reset progress bar for next level
        _currentLevelResults = [];
        _currentLevelTotalProblems = _getProblemsForLevel(3);
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
        // CRITICAL: Reset progress bar for next level
        _currentLevelResults = [];
        _currentLevelTotalProblems = _getProblemsForLevel(4);
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
      setState(() {
        // CRITICAL: Reset progress bar for next level
        _currentLevelResults = [];
        _currentLevelTotalProblems = _getProblemsForLevel(5);
      });
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
        // CRITICAL: Reset progress bar when manually switching levels
        _currentLevelResults = [];
        _currentLevelTotalProblems = _getProblemsForLevel(levelNumber);
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

  /// Show level selection drawer
  void _showLevelDrawer() {
    showModalBottomSheet(
      context: context,
      builder: (context) => LevelSelectionDrawer(
        levels: [
          ScaffoldLevel.guidedExploration,
          ScaffoldLevel.supportedPractice,
          ScaffoldLevel.independentMastery,
          ScaffoldLevel.advancedChallenge,
          ScaffoldLevel.finale,
        ],
        currentLevel: _currentLevel,
        onLevelSelected: _onLevelSelected,
        isLevelUnlocked: (level) => isLevelUnlocked(level.levelNumber),
      ),
    );
  }

  /// Show instructions modal for current level
  void _showInstructions() {
    String levelTitle;
    String instructionText;
    Color levelColor;

    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        levelTitle = 'Level 1: Guided Exploration';
        instructionText = 'Explore which numbers come BEFORE and AFTER.\n\n'
            '• Tap a number on the line\n'
            '• Press "Before" to see the predecessor\n'
            '• Press "After" to see the successor\n'
            '• Explore 5 times to unlock Level 2';
        levelColor = Colors.blue;
        break;

      case ScaffoldLevel.supportedPractice:
        levelTitle = 'Level 2: Supported Practice';
        instructionText = 'Write the predecessor AND successor.\n\n'
            '• See the number highlighted on the line\n'
            '• Fill in what comes BEFORE and AFTER\n'
            '• Complete 10 correct answers to unlock Level 3';
        levelColor = Colors.orange;
        break;

      case ScaffoldLevel.independentMastery:
        levelTitle = 'Level 3: Independent Mastery';
        instructionText = 'Find predecessor and successor from memory!\n\n'
            '• Number line hidden (appears on errors)\n'
            '• Three different problem types\n'
            '• Complete 8 correct answers to unlock Level 4';
        levelColor = Colors.purple;
        break;

      case ScaffoldLevel.advancedChallenge:
        levelTitle = 'Level 4: Extended Sequences';
        instructionText = 'Fill in TWO consecutive numbers!\n\n'
            '• Example: 17, ___, ___ or ___, ___, 20\n'
            '• Tests deeper pattern recognition\n'
            '• Complete 5 correct answers to unlock Finale';
        levelColor = Colors.deepPurple;
        break;

      case ScaffoldLevel.finale:
        levelTitle = 'Level 5: Finale';
        instructionText = 'Easier mixed review to show your mastery!\n\n'
            '• Before/after with narrower range (5-15)\n'
            '• Complete 10 problems with 100% accuracy\n'
            '• Time limit: <20s per problem';
        levelColor = Colors.green;
        break;

      default:
        levelTitle = 'Instructions';
        instructionText = 'Select a level to see instructions.';
        levelColor = Colors.grey;
    }

    InstructionModal.show(
      context,
      levelTitle: levelTitle,
      instructionText: instructionText,
      levelColor: levelColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Choose Level',
            onPressed: _showLevelDrawer,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Instructions',
            onPressed: _showInstructions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented Progress Bar
          SegmentedProgressBar(
            totalSegments: _currentLevelTotalProblems,
            currentSegment: _currentLevelResults.length,
            results: _currentLevelResults,
          ),

          // Current level content
          Expanded(
            child: _buildCurrentLevelWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLevelWidget() {
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        return WhatComesNextLevel1Widget(
          onProgressUpdate: (explorations) {
            _onLevel1Progress(explorations);
            // Each exploration counts as a "problem" for progress bar
            _onProblemComplete(true);
          },
        );

      case ScaffoldLevel.supportedPractice:
        return WhatComesNextLevel2Widget(
          onProgressUpdate: _onLevel2Progress,
          onStartProblemTimer: startProblemTimer,
          onProblemComplete: (correct, userAnswer) async {
            _onProblemComplete(correct);
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
            _onProblemComplete(correct);
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
            _onProblemComplete(correct);
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
            _onProblemComplete(correct);
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
