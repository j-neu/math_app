import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/countdots_level1_widget_v2.dart';
import '../widgets/countdots_level2_widget_v2.dart';
import '../widgets/countdots_level3_widget_v2.dart';
import '../widgets/countdots_level4_widget_v2.dart';
import '../widgets/common/segmented_progress_bar.dart';
import '../widgets/common/instruction_modal.dart';
import '../widgets/common/level_selection_drawer.dart';

/// Complete implementation of C1.1 V2: Count the Dots exercise with 4-Level Scaffolding.
///
/// This exercise follows the iMINT Card 1 prescription for "Plättchen zählen" which
/// explicitly describes 4 scaffolding levels:
///
/// **iMINT Card 1: "Wie kommt die Handlung in den Kopf?"**
/// 1. Zuerst wird das gezählte Objekt zur Seite geschoben (push aside while counting)
/// 2. Später wird es beim lauten Zählen nur angetippt (tap/touch while counting)
/// 3. Der nächste Schritt ist das laute Abzählen ohne weitere äußere Handlung (count without action)
/// 4. Das Verfolgen der Zählhandlung mit den Augen und die Nennung des Ergebnisses (eyes only, then result)
///
/// **Level 1: Drag to Count (zur Seite schieben)**
/// - Drag each dot to "counted" area
/// - Counter displays current count
/// - Learn one-to-one correspondence through physical action
/// - Structured layout (max 5 dots per row)
///
/// **Level 2: Tap to Count (antippen)**
/// - Tap dots (they mark as counted)
/// - Counter displays current count
/// - Reduced motor action, same concept
/// - Structured layout (max 5 dots per row)
///
/// **Level 3: No-Action Count (ohne Handlung)**
/// - Dots visible but no interaction (structured layout only)
/// - Child counts silently and enters result
/// - Mental counting with visual support
/// - Always structured layout (max 5 dots per row)
///
/// **Level 4: Eye-Tracking Count (mit den Augen)**
/// - Dots visible with random/scattered layout
/// - Child must count by tracking with eyes only
/// - Tests efficient eye-scanning patterns
/// - Always random layout (challenges eye-tracking)
///
/// **Pedagogical Goal:** Progressive reduction of support from physical to mental
///
/// Source: iMINT Green Card 1 (Plättchen zählen / Count dots)
class CountDotsExerciseV2 extends StatefulWidget {
  final ExerciseConfig config;
  final UserProfile userProfile;

  const CountDotsExerciseV2({
    super.key,
    required this.userProfile,
  }) : config = const ExerciseConfig(
          id: 'C1.1',
          title: 'Count the Dots',
          skillTags: ['counting_1'],
          sourceCard: 'iMINT Green Card 1: Plättchen zählen (4-level version)',
          concept:
              'Understanding counting through one-to-one correspondence with progressive scaffolding',
          observationPoints: [
            'Does child systematically move/tap dots or work randomly?',
            'Can child count without physical action (Level 3)?',
            'Can child efficiently track and count with eyes only (Level 4)?',
          ],
          internalizationPath:
              'L1 (Drag) → L2 (Tap) → L3 (Look-Structured) → L4 (Look-Random)',
          targetNumber: 20, // Max dots across all levels
          hints: [
            'Move each dot once as you count.',
            'Tap each dot once - no double counting!',
            'Count the dots you see, then enter the number.',
            'Track each dot with your eyes - don\'t miss any!',
          ],
        );

  @override
  State<CountDotsExerciseV2> createState() => _CountDotsExerciseV2State();
}

class _CountDotsExerciseV2State extends State<CountDotsExerciseV2>
    with ExerciseProgressMixin {
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration;

  // Progress tracking for segmented bar
  List<bool> _problemResults = []; // true = correct, false = incorrect
  int _currentProblemIndex = 0;
  static const int _problemsPerLevel = 10; // ALL levels have 10 problems (standard difficulty curve)

  // Level completion tracking (ephemeral, for unlock logic)
  int _level1ProblemsCompleted = 0;
  int _level2Correct = 0;
  int _level3Correct = 0;
  int _level4Correct = 0;

  // Unlock thresholds (minimum correct to unlock next level)
  static const int _level1RequiredProblems = 10; // All 10 problems
  static const int _level2RequiredCorrect = 8;   // 8/10 correct
  static const int _level3RequiredCorrect = 8;   // 8/10 correct
  static const int _level4RequiredCorrect = 8;   // 8/10 correct

  // ExerciseProgressMixin implementation
  @override
  String get exerciseId => widget.config.id;

  @override
  UserProfile get userProfile => widget.userProfile;

  @override
  int get totalLevels => 4;

  @override
  int get finaleLevelNumber => 4;

  @override
  int get problemTimeLimit => 20; // 20 seconds per problem for completion

  @override
  int get finaleMinProblems => 10;

  @override
  void initState() {
    super.initState();
    _initializeExercise();
  }

  Future<void> _initializeExercise() async {
    await initializeProgress();

    // Restore current level based on what's unlocked
    setState(() {
      if (isLevelUnlocked(4)) {
        _currentLevel = ScaffoldLevel.advancedChallenge;
      } else if (isLevelUnlocked(3)) {
        _currentLevel = ScaffoldLevel.independentMastery;
      } else if (isLevelUnlocked(2)) {
        _currentLevel = ScaffoldLevel.supportedPractice;
      } else {
        _currentLevel = ScaffoldLevel.guidedExploration;
      }
      _updateProblemsPerLevel();
    });
  }

  void _updateProblemsPerLevel() {
    // All levels have 10 problems (standard difficulty curve)
    // No need to update _problemsPerLevel as it's now a constant
    // This method kept for compatibility but does nothing
  }

  @override
  void dispose() {
    // Note: dispose is synchronous, we save in WillPopScope async callback
    super.dispose();
  }

  void _onLevel1Progress(int problemsSolved) {
    setState(() {
      _level1ProblemsCompleted = problemsSolved;

      // Update segmented bar (Level 1 doesn't track correct/incorrect, just completion)
      if (_problemResults.length < problemsSolved) {
        _problemResults.add(true); // Mark as correct (green)
        _currentProblemIndex = problemsSolved;
      }

      if (_level1ProblemsCompleted >= _level1RequiredProblems &&
          !isLevelUnlocked(2)) {
        unlockLevel(2);
        _showLevelUnlockedMessage('Level 2: Tap to Count',
            'Tap dots instead of dragging them!');
        _autoAdvanceToNextLevel();
      }
    });
  }

  void _onLevel2ProgressUpdate(int correct, int total) {
    setState(() {
      // Update segmented bar
      if (_problemResults.length < total) {
        bool isCorrect = (total - _problemResults.length == 1 && correct > _level2Correct);
        _problemResults.add(isCorrect);
        _currentProblemIndex = total;
      }

      _level2Correct = correct;

      if (correct >= _level2RequiredCorrect && !isLevelUnlocked(3)) {
        unlockLevel(3);
        _showLevelUnlockedMessage('Level 3: No-Action Count',
            'Count without touching - just look and think!');
        _autoAdvanceToNextLevel();
      }
    });
  }

  void _onLevel3ProgressUpdate(int correct, int total) {
    setState(() {
      // Update segmented bar
      if (_problemResults.length < total) {
        bool isCorrect = (total - _problemResults.length == 1 && correct > _level3Correct);
        _problemResults.add(isCorrect);
        _currentProblemIndex = total;
      }

      _level3Correct = correct;

      if (correct >= _level3RequiredCorrect && !isLevelUnlocked(4)) {
        unlockLevel(4);
        _showLevelUnlockedMessage('Level 4: Flash & Memory',
            'The ultimate challenge - count from memory!');
        _autoAdvanceToNextLevel();
      }
    });
  }

  void _onLevel4ProgressUpdate(int correct, int total) {
    setState(() {
      // Update segmented bar
      if (_problemResults.length < total) {
        bool isCorrect = (total - _problemResults.length == 1 && correct > _level4Correct);
        _problemResults.add(isCorrect);
        _currentProblemIndex = total;
      }

      _level4Correct = correct;

      // Level 4 is the final level - no more levels to unlock
    });
  }


  void _showLevelUnlockedMessage(String levelName, String description) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 $levelName Unlocked!\n$description'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _autoAdvanceToNextLevel() async {
    // Wait a moment for celebration
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      // Advance to next level
      final nextLevelNumber = _scaffoldLevelToInt(_currentLevel) + 1;
      if (nextLevelNumber <= 4 && isLevelUnlocked(nextLevelNumber)) {
        _currentLevel = _intToScaffoldLevel(nextLevelNumber);
        _problemResults = []; // Reset progress bar for new level
        _currentProblemIndex = 0;
        _updateProblemsPerLevel();
      }
    });
  }

  void _onLevelSelected(ScaffoldLevel level) {
    int levelNumber = _scaffoldLevelToInt(level);

    if (isLevelUnlocked(levelNumber)) {
      setState(() {
        _currentLevel = level;
        _problemResults = []; // Reset progress bar for new level
        _currentProblemIndex = 0;
        _updateProblemsPerLevel();
      });
    } else {
      String lockMessage = _getLockMessage(level);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lockMessage),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  int _scaffoldLevelToInt(ScaffoldLevel level) {
    switch (level) {
      case ScaffoldLevel.guidedExploration:
        return 1;
      case ScaffoldLevel.supportedPractice:
        return 2;
      case ScaffoldLevel.independentMastery:
        return 3;
      case ScaffoldLevel.advancedChallenge:
        return 4;
      case ScaffoldLevel.finale:
        return 5;
    }
  }

  ScaffoldLevel _intToScaffoldLevel(int levelNumber) {
    switch (levelNumber) {
      case 1:
        return ScaffoldLevel.guidedExploration;
      case 2:
        return ScaffoldLevel.supportedPractice;
      case 3:
        return ScaffoldLevel.independentMastery;
      case 4:
        return ScaffoldLevel.advancedChallenge;
      case 5:
        return ScaffoldLevel.finale;
      default:
        return ScaffoldLevel.guidedExploration;
    }
  }

  String _getLockMessage(ScaffoldLevel level) {
    switch (level) {
      case ScaffoldLevel.guidedExploration:
        return '';
      case ScaffoldLevel.supportedPractice:
        return 'Complete $_level1RequiredProblems problems in Level 1 first!';
      case ScaffoldLevel.independentMastery:
        return 'Get $_level2RequiredCorrect correct in Level 2 first!';
      case ScaffoldLevel.advancedChallenge:
        return 'Get $_level3RequiredCorrect correct in Level 3 first!';
      case ScaffoldLevel.finale:
        return 'Get $_level4RequiredCorrect correct in Level 4 first!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await onExerciseExit();
        return true;
      },
      child: Column(
        children: [
          // Action buttons row (replacing AppBar actions)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Choose Level',
                  onPressed: _showLevelSelector,
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  tooltip: 'Instructions',
                  onPressed: _showInstructions,
                ),
              ],
            ),
          ),
          SegmentedProgressBar(
            totalSegments: _problemsPerLevel,
            currentSegment: _currentProblemIndex,
            results: _problemResults,
          ),
          Expanded(
            child: _buildCurrentLevelWidget(),
          ),
        ],
      ),
    );
  }

  void _showInstructions() {
    final levelNumber = _scaffoldLevelToInt(_currentLevel);
    InstructionModal.show(
      context,
      levelTitle: 'Level $levelNumber: ${_getLevelTitle(_currentLevel)}',
      instructionText: _getLevelInstructions(_currentLevel),
      levelColor: _getLevelColor(_currentLevel),
    );
  }

  void _showLevelSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => LevelSelectionDrawer(
        levels: const [
          ScaffoldLevel.guidedExploration,
          ScaffoldLevel.supportedPractice,
          ScaffoldLevel.independentMastery,
          ScaffoldLevel.advancedChallenge,
        ],
        currentLevel: _currentLevel,
        onLevelSelected: _onLevelSelected,
        isLevelUnlocked: (level) => isLevelUnlocked(_scaffoldLevelToInt(level)),
      ),
    );
  }

  String _getLevelTitle(ScaffoldLevel level) {
    switch (level) {
      case ScaffoldLevel.guidedExploration:
        return 'Drag to Count';
      case ScaffoldLevel.supportedPractice:
        return 'Tap to Count';
      case ScaffoldLevel.independentMastery:
        return 'Look-Structured';
      case ScaffoldLevel.advancedChallenge:
        return 'Look-Random';
      case ScaffoldLevel.finale:
        return 'Not used in C1.1';
    }
  }

  String _getLevelInstructions(ScaffoldLevel level) {
    switch (level) {
      case ScaffoldLevel.guidedExploration:
        return 'Drag each dot to the "counted" area as you count them out loud. This helps you match each dot with a number word.';
      case ScaffoldLevel.supportedPractice:
        return 'Tap each dot once as you count. The dots will mark themselves as counted. No double counting!';
      case ScaffoldLevel.independentMastery:
        return 'Look at the dots (structured layout) and count them silently. When you know how many there are, enter the number.';
      case ScaffoldLevel.advancedChallenge:
        return 'Look at the randomly scattered dots and count by tracking with your eyes. Test your eye-scanning skills!';
      case ScaffoldLevel.finale:
        return 'Not used in C1.1 - this skill has 4 levels only.';
    }
  }

  Color _getLevelColor(ScaffoldLevel level) {
    switch (level) {
      case ScaffoldLevel.guidedExploration:
        return Colors.blue;
      case ScaffoldLevel.supportedPractice:
        return Colors.orange;
      case ScaffoldLevel.independentMastery:
        return Colors.purple;
      case ScaffoldLevel.advancedChallenge:
        return Colors.red;
      case ScaffoldLevel.finale:
        return Colors.green;
    }
  }


  Widget _buildCurrentLevelWidget() {
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        return CountDotsLevel1Widget(
          onProgressUpdate: _onLevel1Progress,
        );

      case ScaffoldLevel.supportedPractice:
        return CountDotsLevel2Widget(
          onProgressUpdate: _onLevel2ProgressUpdate,
        );

      case ScaffoldLevel.independentMastery:
        return CountDotsLevel3Widget(
          onProgressUpdate: _onLevel3ProgressUpdate,
        );

      case ScaffoldLevel.advancedChallenge:
        return CountDotsLevel4Widget(
          onProgressUpdate: _onLevel4ProgressUpdate,
        );

      case ScaffoldLevel.finale:
        // C1.1 has no finale level - only 4 card-prescribed levels
        return const Center(
          child: Text('Level 5 removed - C1.1 has 4 levels only'),
        );
    }
  }

}
