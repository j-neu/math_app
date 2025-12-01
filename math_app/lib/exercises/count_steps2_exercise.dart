import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/countsteps2_level1_widget.dart';
import '../widgets/countsteps2_level2_widget.dart';
import '../widgets/countsteps2_level3_widget.dart';
import '../widgets/countsteps2_level4_widget.dart';
import '../widgets/common/minimalist_exercise_scaffold.dart';
import '../widgets/common/instruction_modal.dart';
import '../widgets/common/level_selection_drawer.dart';

/// Complete implementation of C6.1: Count in Steps of 2 exercise with Card-Based Scaffolding.
///
/// This exercise follows the framework documented in IMINT_TO_APP_FRAMEWORK.md
/// to properly answer "Wie kommt die Handlung in den Kopf?" (How does action become mental?)
///
/// **Source:** iMINT Arbeitskarte 6 + 7:
/// - Card 6: "Zweierschritte am Rechenschiffchen" (Page 84)
/// - Card 7: "Wie viele Würfel? In Zweierschritten zählen" (Page 85)
///
/// **Level 1: Forward Counting with Visual Support (Odd Numbers Visible)**
/// - Show odd numbers (1, 3, 5, 7, 9, 11, 13, 15, 17, 19)
/// - Child fills in even numbers (2, 4, 6, 8, 10, 12, 14, 16, 18, 20)
/// - Full visual scaffolding
/// - Purpose: See the pattern, recognize skip counting by 2s
///
/// **Level 2: Backward Counting with Visual Support (Even Numbers Visible)**
/// - Show even numbers (2, 4, 6, 8, 10, 12, 14, 16, 18, 20)
/// - Child fills in odd numbers (1, 3, 5, 7, 9, 11, 13, 15, 17, 19)
/// - Full visual scaffolding
/// - Purpose: Backward pattern recognition
///
/// **Level 3: Forward Counting WITHOUT Visual Support**
/// - Show NO numbers (all cells are X)
/// - Child fills in: 2, 4, 6, 8, 10, 12, 14, 16, 18
/// - NO visual scaffolding (mental work)
/// - Purpose: Internalize forward skip counting
///
/// **Level 4: Backward Counting WITHOUT Visual Support**
/// - Show only "20" (ending number)
/// - Child fills in: 18, 16, 14, 12, 10, 8, 6, 4, 2
/// - NO visual scaffolding (mental work)
/// - Purpose: Internalize backward skip counting
///
/// **COMPLETION CRITERIA (Level 4):**
/// - Minimum problems: 10
/// - Accuracy required: 100% (zero errors in last 10 problems)
/// - Time limit: 60 seconds per problem (more time for mental work)
/// - Status: "finished" → "completed" when all criteria met
///
/// **State Persistence:**
/// - Progress saves every 5 problems via ExerciseProgressMixin
/// - Progress saves on exit (dispose)
/// - Level unlocks persist across app restarts
/// - Child can exit and resume from same point
///
/// **Pedagogical Goal:** Internalize skip counting by 2s through
/// progressive scaffolding: Visual forward → Visual backward → Mental forward → Mental backward
///
/// **Skills:** counting_6, counting_7 (skip counting by 2s)
class CountSteps2Exercise extends StatefulWidget {
  final ExerciseConfig config;
  final UserProfile userProfile;

  const CountSteps2Exercise({
    super.key,
    required this.userProfile,
  }) : config = const ExerciseConfig(
          id: 'C6.1',
          title: 'Count in Steps of 2',
          skillTags: ['counting_6', 'counting_7'],
          sourceCard:
              'iMINT Arbeitskarte 6: Zweierschritte am Rechenschiffchen (Page 84)\n'
              'iMINT Arbeitskarte 7: In Zweierschritten zählen (Page 85)',
          concept:
              'Skip counting by 2s: recognizing patterns, counting forward and backward '
              'in steps of 2, internalizing the sequence without visual support',
          observationPoints: [
            'Can child recognize the skip-2 pattern with visual support?',
            'Can child count forward by 2s (2, 4, 6, 8...)?',
            'Can child count backward by 2s (20, 18, 16, 14...)?',
            'Can child skip count mentally without visible numbers?',
            'Is counting automatic or does child still need to calculate?',
          ],
          internalizationPath:
              'Level 1 (Forward with support) → Level 2 (Backward with support) → '
              'Level 3 (Forward mental) → Level 4 (Backward mental)',
          targetNumber: 20,
          hints: [
            'Start at 0 or 1, skip one number, count the next',
            'Even numbers: 2, 4, 6, 8, 10, 12, 14, 16, 18, 20',
            'Odd numbers: 1, 3, 5, 7, 9, 11, 13, 15, 17, 19',
            'Count in your head - add 2 or subtract 2',
          ],
        );

  @override
  State<CountSteps2Exercise> createState() => _CountSteps2ExerciseState();
}

class _CountSteps2ExerciseState extends State<CountSteps2Exercise>
    with ExerciseProgressMixin {
  // Mixin requirements
  @override
  String get exerciseId => widget.config.id;

  @override
  UserProfile get userProfile => widget.userProfile;

  @override
  int get totalLevels => 4; // 4 card levels (no finale)

  @override
  int get finaleLevelNumber => 4;

  @override
  int get problemTimeLimit => 60; // 60 seconds per problem (mental work takes longer)

  @override
  int get finaleMinProblems => 10;

  // UI state
  int _currentLevel = 1;

  // Progress bar tracking - CRITICAL: Reset when changing levels!
  List<bool> _currentLevelResults = [];
  int _currentLevelTotalProblems = 10; // All levels have 10 problems

  @override
  void initState() {
    super.initState();
    _initializeExercise();
  }

  Future<void> _initializeExercise() async {
    await initializeProgress();

    // Determine current level from saved progress
    setState(() {
      if (isLevelUnlocked(4)) {
        _currentLevel = 4;
      } else if (isLevelUnlocked(3)) {
        _currentLevel = 3;
      } else if (isLevelUnlocked(2)) {
        _currentLevel = 2;
      } else {
        _currentLevel = 1;
      }

      // Initialize progress bar for current level
      _currentLevelTotalProblems = 10; // All levels have 10 problems
      _currentLevelResults = [];
    });
  }

  @override
  void dispose() {
    saveProgress();
    super.dispose();
  }

  void _onProblemComplete(bool correct) {
    setState(() {
      _currentLevelResults.add(correct);
    });
  }

  void _onLevel1Complete() {
    unlockLevel(2);
    setState(() {
      _currentLevel = 2;
      // CRITICAL: Reset progress bar when advancing levels
      _currentLevelResults = [];
    });
    saveProgress();
  }

  void _onLevel2Complete() {
    unlockLevel(3);
    setState(() {
      _currentLevel = 3;
      // CRITICAL: Reset progress bar when advancing levels
      _currentLevelResults = [];
    });
    saveProgress();
  }

  void _onLevel3Complete() {
    unlockLevel(4);
    setState(() {
      _currentLevel = 4;
      // CRITICAL: Reset progress bar when advancing levels
      _currentLevelResults = [];
    });
    saveProgress();
  }

  void _onLevel4Complete() {
    // Mark exercise as completed
    saveProgress();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.celebration, color: Colors.white),
            SizedBox(width: 12),
            Text('Congratulations! You mastered counting in steps of 2!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _onLevelSelected(int level) {
    if (isLevelUnlocked(level)) {
      setState(() {
        _currentLevel = level;
        // CRITICAL: Reset progress bar when manually switching levels
        _currentLevelResults = [];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock, color: Colors.white),
              const SizedBox(width: 12),
              Text('Complete Level ${level - 1} first!'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showInstructions() {
    String title = '';
    String instructions = '';
    Color color = Colors.blue;

    switch (_currentLevel) {
      case 1:
        title = 'Level 1: Forward with Support';
        instructions =
            'The ODD numbers (1, 3, 5, 7...) are shown. Fill in the EVEN numbers (2, 4, 6, 8...) by counting forward in steps of 2.';
        color = Colors.blue;
        break;
      case 2:
        title = 'Level 2: Backward with Support';
        instructions =
            'The EVEN numbers (2, 4, 6, 8...) are shown. Fill in the ODD numbers (1, 3, 5, 7...) by thinking backward in steps of 2.';
        color = Colors.purple;
        break;
      case 3:
        title = 'Level 3: Forward Mental Counting';
        instructions =
            'All numbers are hidden. Count forward in steps of 2 mentally: 2, 4, 6, 8... Fill in all the even numbers!';
        color = Colors.orange;
        break;
      case 4:
        title = 'Level 4: Backward Mental Counting';
        instructions =
            'Only "20" is shown. Count backward in steps of 2 mentally: 20, 18, 16, 14... Fill in all the even numbers!';
        color = Colors.red;
        break;
    }

    InstructionModal.show(
      context,
      levelTitle: title,
      instructionText: instructions,
      levelColor: color,
    );
  }

  void _showLevelSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => LevelSelectionDrawer(
        levels: [
          ScaffoldLevel.guidedExploration,
          ScaffoldLevel.supportedPractice,
          ScaffoldLevel.independentMastery,
          ScaffoldLevel.finale, // 4th level
        ],
        currentLevel: _getLevelEnum(_currentLevel),
        onLevelSelected: (level) {
          Navigator.pop(context);
          _onLevelSelected(_getLevelNumber(level));
        },
        isLevelUnlocked: (level) => isLevelUnlocked(_getLevelNumber(level)),
      ),
    );
  }

  ScaffoldLevel _getLevelEnum(int levelNumber) {
    switch (levelNumber) {
      case 1:
        return ScaffoldLevel.guidedExploration;
      case 2:
        return ScaffoldLevel.supportedPractice;
      case 3:
        return ScaffoldLevel.independentMastery;
      case 4:
        return ScaffoldLevel.finale; // 4th level
      default:
        return ScaffoldLevel.guidedExploration;
    }
  }

  int _getLevelNumber(ScaffoldLevel level) {
    switch (level) {
      case ScaffoldLevel.guidedExploration:
        return 1;
      case ScaffoldLevel.supportedPractice:
        return 2;
      case ScaffoldLevel.independentMastery:
        return 3;
      case ScaffoldLevel.advancedChallenge:
        return 4; // Not used in level selector, but needed for exhaustive switch
      case ScaffoldLevel.finale:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MinimalistExerciseScaffold(
      exerciseTitle: widget.config.title,
      totalProblems: _currentLevelTotalProblems,
      currentProblemIndex: _currentLevelResults.length,
      problemResults: _currentLevelResults,
      onShowInstructions: _showInstructions,
      onShowLevelSelector: _showLevelSelector,
      exerciseContent: _buildCurrentLevelWidget(),
    );
  }

  Widget _buildCurrentLevelWidget() {
    switch (_currentLevel) {
      case 1:
        return CountSteps2Level1Widget(
          onProblemComplete: (correct) {
            _onProblemComplete(correct);
            recordProblemResult(correct: correct, levelNumber: 1);
          },
          onLevelComplete: _onLevel1Complete,
        );

      case 2:
        return CountSteps2Level2Widget(
          onProblemComplete: (correct) {
            _onProblemComplete(correct);
            recordProblemResult(correct: correct, levelNumber: 2);
          },
          onLevelComplete: _onLevel2Complete,
        );

      case 3:
        return CountSteps2Level3Widget(
          onProblemComplete: (correct) {
            _onProblemComplete(correct);
            recordProblemResult(correct: correct, levelNumber: 3);
          },
          onLevelComplete: _onLevel3Complete,
        );

      case 4:
        return CountSteps2Level4Widget(
          onProblemComplete: (correct) {
            _onProblemComplete(correct);
            recordProblemResult(correct: correct, levelNumber: 4);
          },
          onLevelComplete: _onLevel4Complete,
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
