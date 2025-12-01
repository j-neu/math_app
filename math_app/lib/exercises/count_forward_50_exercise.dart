import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/countforward50_level1_widget.dart';
import '../widgets/countforward50_level2_widget.dart';
import '../widgets/countforward50_level3_widget.dart';
import '../widgets/countforward50_level4_widget.dart';
import '../widgets/common/minimalist_exercise_scaffold.dart';
import '../widgets/common/instruction_modal.dart';
import '../widgets/common/level_selection_drawer.dart';

/// Complete implementation of C3.2: Count Forward to 50 exercise with Card-Based Scaffolding.
///
/// This exercise follows the framework documented in IMINT_TO_APP_FRAMEWORK.md
/// to properly answer "Wie kommt die Handlung in den Kopf?" (How does action become mental?)
///
/// **Source:** iMINT Arbeitskarte 3: "Zählen am Zahlenband bis 100" (Pages 77-78)
/// **Note:** This is the 1-50 range version. See C3.1 (1-20) and C3.3 (1-100) for other ranges.
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
/// **Pedagogical Goal:** Internalize counting sequence 1-50 through
/// progressive scaffolding: Tap → Identify → Fill → Practice
///
/// **Skills:** counting_3 (forward/backward counting on number band)
class CountForward50Exercise extends StatefulWidget {
  final ExerciseConfig config;
  final UserProfile userProfile;

  const CountForward50Exercise({
    super.key,
    required this.userProfile,
  }) : config = const ExerciseConfig(
          id: 'C3.2',
          title: 'Count Forward to 50',
          skillTags: ['counting_3'],
          sourceCard: 'iMINT Arbeitskarte 3: Zählen am Zahlenband bis 100 (Pages 77-78) - Adapted for 1-50 range',
          concept:
              'Understanding the number sequence 1-50: recognizing patterns, '
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
          targetNumber: 50,
          hints: [
            'The ones-digit counts up: 1,2,3...9, then starts again at 11,12,13...',
            'After 9 comes 10, after 19 comes 20',
            'Count in your head - what comes next?',
            'If you get stuck, try counting from 1',
          ],
        );

  @override
  State<CountForward50Exercise> createState() => _CountForward50ExerciseState();
}

class _CountForward50ExerciseState extends State<CountForward50Exercise>
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
  int _currentLevel = 1;

  // Progress bar tracking - CRITICAL: Reset when changing levels!
  List<bool> _currentLevelResults = [];
  int _currentLevelTotalProblems = 5; // Level 1 default

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
      _currentLevelTotalProblems = _getProblemsForLevel(_currentLevel);
      _currentLevelResults = [];
    });
  }

  @override
  void dispose() {
    saveProgress();
    super.dispose();
  }

  int _getProblemsForLevel(int level) {
    switch (level) {
      case 1: return 5;
      case 2: return 12;
      case 3: return 8;
      case 4: return 10;
      default: return 10;
    }
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
      _currentLevelTotalProblems = _getProblemsForLevel(2);
    });
    saveProgress();
  }

  void _onLevel2Complete() {
    unlockLevel(3);
    setState(() {
      _currentLevel = 3;
      // CRITICAL: Reset progress bar when advancing levels
      _currentLevelResults = [];
      _currentLevelTotalProblems = _getProblemsForLevel(3);
    });
    saveProgress();
  }

  void _onLevel3Complete() {
    unlockLevel(4);
    setState(() {
      _currentLevel = 4;
      // CRITICAL: Reset progress bar when advancing levels
      _currentLevelResults = [];
      _currentLevelTotalProblems = _getProblemsForLevel(4);
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
            Text('Congratulations! You\'ve completed counting to 50!'),
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
        _currentLevelTotalProblems = _getProblemsForLevel(level);
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
        title = 'Level 1: Tap Sequence';
        instructions = 'Tap numbers in order from the start number to the target number. '
            'Say each number out loud as you tap it! Notice how decade numbers (10, 20, 30...) are highlighted.';
        color = Colors.blue;
        break;
      case 2:
        title = 'Level 2: Walking Marker';
        instructions = 'A marker covers the current number (shown as ?). Type what number you think is covered, '
            'then press Check. You\'ll count both FORWARD and BACKWARD!';
        color = Colors.orange;
        break;
      case 3:
        title = 'Level 3: Mental Counting';
        instructions = 'Fill in the missing numbers in the sequence. The first 2 and last 2 numbers are shown. '
            'Count in your head to figure out what goes in the blanks!';
        color = Colors.purple;
        break;
      case 4:
        title = 'Level 4: Finale';
        instructions = 'Final practice! Tap numbers forward or backward from start to target. '
            'The number band is visible to help you succeed. Complete 10 problems to finish!';
        color = Colors.green;
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
          ScaffoldLevel.finale,
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
      case 1: return ScaffoldLevel.guidedExploration;
      case 2: return ScaffoldLevel.supportedPractice;
      case 3: return ScaffoldLevel.independentMastery;
      case 4: return ScaffoldLevel.finale;
      default: return ScaffoldLevel.guidedExploration;
    }
  }

  int _getLevelNumber(ScaffoldLevel level) {
    switch (level) {
      case ScaffoldLevel.guidedExploration: return 1;
      case ScaffoldLevel.supportedPractice: return 2;
      case ScaffoldLevel.independentMastery: return 3;
      case ScaffoldLevel.finale: return 4;
      case ScaffoldLevel.advancedChallenge: return 4; // Not used
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
        return CountForwardLevel1Widget(
          onProblemComplete: (correct) {
            _onProblemComplete(correct);
            recordProblemResult(correct: correct, levelNumber: 1);
          },
          onLevelComplete: _onLevel1Complete,
        );

      case 2:
        return CountForwardLevel2Widget(
          onProblemComplete: (correct) {
            _onProblemComplete(correct);
            recordProblemResult(correct: correct, levelNumber: 2);
          },
          onLevelComplete: _onLevel2Complete,
        );

      case 3:
        return CountForwardLevel3Widget(
          onProblemComplete: (correct) {
            _onProblemComplete(correct);
            recordProblemResult(correct: correct, levelNumber: 3);
          },
          onLevelComplete: _onLevel3Complete,
        );

      case 4:
        return CountForwardLevel4Widget(
          startProblemTimer: startProblemTimer,
          recordProblemResult: (correct) {
            _onProblemComplete(correct);
            recordProblemResult(correct: correct, levelNumber: 4);
          },
          onProblemComplete: (correct) {
            // Already recorded via recordProblemResult
          },
          onLevelComplete: _onLevel4Complete,
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
