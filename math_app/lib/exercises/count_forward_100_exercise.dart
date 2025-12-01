import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/countforward100_level1_widget.dart';
import '../widgets/countforward100_level2_widget.dart';
import '../widgets/countforward100_level3_widget.dart';
import '../widgets/countforward100_level4_widget.dart';
import '../widgets/common/instruction_modal.dart';
import '../widgets/common/level_selection_drawer.dart';
import '../widgets/common/segmented_progress_bar.dart';

/// Complete implementation of C3.3: Count Forward to 100 exercise with Card-Based Scaffolding.
///
/// This exercise follows the framework documented in IMINT_TO_APP_FRAMEWORK.md
/// to properly answer "Wie kommt die Handlung in den Kopf?" (How does action become mental?)
///
/// **Source:** iMINT Arbeitskarte 3: "Zählen am Zahlenband bis 100" (Pages 77-78)
/// **Note:** This is the 1-100 range version. See C3.1 (1-20) and C3.2 (1-50) for other ranges.
///
/// **Level 1: Tap Sequence (Activity B)**
/// - Tap numbers in sequence on visible band (1-50)
/// - Full visual support, SEE the sequence
/// - Generic feedback ("Keep going!"), minimal hand-holding
/// - Purpose: Recognize sequence patterns
///
/// **Level 2: Identify Covered Number (Activity C)**
/// - Marker covers current number
/// - Child must ENTER the number covered by marker
/// - Text input required (no "Next" button)
/// - Purpose: Mental work, think before seeing answer
///
/// **Level 3: Fill Sequence (Activity D)**
/// - Show first 2 and last 2 numbers only
/// - Child fills in middle numbers (3-8 blanks)
/// - Multiple text fields, prevents answer copying
/// - Purpose: Complete internalization, no visual reference
///
/// **Level 4: Finale (ADHD-Friendly Victory Lap)**
/// - Count to 20 with band VISIBLE (easier than L3)
/// - Both directions, 5-8 step sequences
/// - Confidence-building completion level
///
/// **COMPLETION CRITERIA (Level 4 Finale):**
/// - Minimum problems: 10
/// - Accuracy required: 100% (zero errors in last 10 problems)
/// - Time limit: 30 seconds per problem
/// - Status: "finished" → "completed" when all criteria met
///
/// **State Persistence:**
/// - Progress saves every 5 problems via ExerciseProgressMixin
/// - Progress saves on exit (dispose)
/// - Level unlocks persist across app restarts
/// - Child can exit and resume from same point
///
/// **Pedagogical Goal:** Internalize counting sequence 1-100 through
/// progressive scaffolding: Tap → Identify → Fill → Practice
///
/// **Skills:** counting_3 (forward/backward counting on number band)
class CountForward100Exercise extends StatefulWidget {
  final ExerciseConfig config;
  final UserProfile userProfile;

  const CountForward100Exercise({
    super.key,
    required this.userProfile,
  }) : config = const ExerciseConfig(
          id: 'C3.3',
          title: 'Count Forward to 100',
          skillTags: ['counting_3'],
          sourceCard: 'iMINT Arbeitskarte 3: Zählen am Zahlenband bis 100 (Pages 77-78) - Adapted for 1-100 range',
          concept:
              'Understanding the number sequence 1-100: recognizing patterns, '
              'counting forward and backward fluently, internalizing the sequence',
          observationPoints: [
            'Can child tap numbers in sequence without specific prompts?',
            'Can child identify covered numbers mentally (Level 2)?',
            'Can child fill in missing numbers in a sequence (Level 3)?',
            'Is counting automatic or does child still need to "figure it out"?',
            'Can child count mentally without copying visible answers?',
          ],
          internalizationPath:
              'Level 1 (Tap sequence) → Level 2 (Identify covered number) → '
              'Level 3 (Fill missing numbers) → Level 4 (Finale consolidation)',
          targetNumber: 100, // Count up to 20
          hints: [
            'The ones-digit counts up: 1,2,3...9, then starts again at 11,12,13...',
            'After 9 comes 10, after 19 comes 20',
            'Count in your head - what comes next?',
            'If you get stuck, try counting from 1',
          ],
        );

  @override
  State<CountForward100Exercise> createState() => _CountForward100ExerciseState();
}

class _CountForward100ExerciseState extends State<CountForward100Exercise>
    with ExerciseProgressMixin {
  // Mixin requirements
  @override
  String get exerciseId => widget.config.id;

  @override
  UserProfile get userProfile => widget.userProfile;

  @override
  int get totalLevels => 4; // 3 card levels + 1 finale

  @override
  int get finaleLevelNumber => 4;

  @override
  int get problemTimeLimit => 30; // 30 seconds per problem

  @override
  int get finaleMinProblems => 10;

  // UI state
  ScaffoldProgress _progress = const ScaffoldProgress();

  // Progress bar tracking
  List<bool> _currentLevelResults = [];
  int _currentLevelTotalProblems = 5; // Default for Level 1

  @override
  void initState() {
    super.initState();
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
        _progress = _progress.copyWith(level1Complete: true, level3Unlocked: true);
      }
      if (isLevelUnlocked(4)) {
        _progress = _progress.copyWith(level1Complete: true, level3Unlocked: true, level4Unlocked: true);
      }
    });
  }

  @override
  void dispose() {
    saveProgress();
    super.dispose();
  }

  /// Get total problems for a given level
  int _getProblemsForLevel(int level) {
    switch (level) {
      case 1:
        return 5; // Level 1
      case 2:
        return 12; // Level 2
      case 3:
        return 8; // Level 3
      case 4:
        return 10; // Level 4 finale
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

  void _onLevel1Complete() {
    unlockLevel(2);
    setState(() {
      _progress = _progress.copyWith(
        level1Complete: true,
        currentLevel: ScaffoldLevel.supportedPractice,
      );
      // CRITICAL: Reset progress bar for next level
      _currentLevelResults = [];
      _currentLevelTotalProblems = _getProblemsForLevel(2);
    });

    _showLevelUnlockedMessage(ScaffoldLevel.supportedPractice);
  }

  void _onLevel2Complete() {
    unlockLevel(3);
    setState(() {
      _progress = _progress.copyWith(
        level3Unlocked: true,
        currentLevel: ScaffoldLevel.independentMastery,
      );
      // CRITICAL: Reset progress bar for next level
      _currentLevelResults = [];
      _currentLevelTotalProblems = _getProblemsForLevel(3);
    });

    _showLevelUnlockedMessage(ScaffoldLevel.independentMastery);
  }

  void _onLevel3Complete() {
    unlockLevel(4);
    setState(() {
      _progress = _progress.copyWith(
        level4Unlocked: true,
        currentLevel: ScaffoldLevel.finale,
      );
      // CRITICAL: Reset progress bar for next level
      _currentLevelResults = [];
      _currentLevelTotalProblems = _getProblemsForLevel(4);
    });

    _showLevelUnlockedMessage(ScaffoldLevel.finale);
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
        isUnlocked = _progress.level4Unlocked;
        lockMessage = 'Complete Level 3 first!';
        break;
    }

    if (isUnlocked) {
      setState(() {
        _progress = _progress.copyWith(currentLevel: level);
        // CRITICAL: Reset progress bar when manually switching levels
        _currentLevelResults = [];
        _currentLevelTotalProblems = _getProblemsForLevel(level.levelNumber);
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

  /// Show level selection drawer
  void _showLevelDrawer() {
    showModalBottomSheet(
      context: context,
      builder: (context) => LevelSelectionDrawer(
        levels: [
          ScaffoldLevel.guidedExploration,
          ScaffoldLevel.supportedPractice,
          ScaffoldLevel.independentMastery,
          ScaffoldLevel.finale,
        ],
        currentLevel: _progress.currentLevel,
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

    switch (_progress.currentLevel) {
      case ScaffoldLevel.guidedExploration:
        levelTitle = 'Level 1: Tap Sequence';
        instructionText = 'Tap the numbers in order on the number band.\n\n'
            '• The number band shows 1-100\n'
            '• Tap each number in sequence\n'
            '• Say the numbers out loud as you tap\n'
            '• Notice the pattern: the ones-digit repeats!';
        levelColor = Colors.blue;
        break;

      case ScaffoldLevel.supportedPractice:
        levelTitle = 'Level 2: Covered Number';
        instructionText = 'The marker covers the current number - you must figure it out!\n\n'
            '• A marker (?) covers the number you\'re on\n'
            '• Type what number is covered\n'
            '• You can see the numbers before and after\n'
            '• Count forward OR backward';
        levelColor = Colors.orange;
        break;

      case ScaffoldLevel.independentMastery:
        levelTitle = 'Level 3: Fill the Sequence';
        instructionText = 'Fill in the missing numbers in the sequence.\n\n'
            '• You see the first 2 and last 2 numbers\n'
            '• Fill in the middle numbers\n'
            '• Count in your head!\n'
            '• Works forward and backward';
        levelColor = Colors.purple;
        break;

      case ScaffoldLevel.finale:
        levelTitle = 'Level 4: Finale';
        instructionText = 'Practice makes perfect! Tap to count forward or backward.\n\n'
            '• The number band is visible to help\n'
            '• Shorter sequences (easier than Level 3)\n'
            '• Both forward and backward\n'
            '• Celebrate your success!';
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

  Widget _buildCurrentLevelWidget() {
    switch (_progress.currentLevel) {
      case ScaffoldLevel.guidedExploration:
        return CountForwardLevel1Widget(
          onProblemComplete: (correct) {
            _onProblemComplete(correct);
            recordProblemResult(correct: correct, levelNumber: 1);
          },
          onLevelComplete: _onLevel1Complete,
        );

      case ScaffoldLevel.supportedPractice:
        return CountForwardLevel2Widget(
          onProblemComplete: (correct) {
            _onProblemComplete(correct);
            recordProblemResult(correct: correct, levelNumber: 2);
          },
          onLevelComplete: _onLevel2Complete,
        );

      case ScaffoldLevel.independentMastery:
        return CountForwardLevel3Widget(
          onProblemComplete: (correct) {
            _onProblemComplete(correct);
            recordProblemResult(correct: correct, levelNumber: 3);
          },
          onLevelComplete: _onLevel3Complete,
        );

      case ScaffoldLevel.advancedChallenge:
        return const SizedBox.shrink();

      case ScaffoldLevel.finale:
        return CountForwardLevel4Widget(
          startProblemTimer: startProblemTimer,
          recordProblemResult: (correct) {
            recordProblemResult(correct: correct, levelNumber: 4);
          },
          onProblemComplete: (correct) {
            _onProblemComplete(correct);
          },
          onLevelComplete: () {
            // Mark exercise as completed
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Congratulations! You\'ve completed counting to 100!'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          },
        );
    }
  }
}
