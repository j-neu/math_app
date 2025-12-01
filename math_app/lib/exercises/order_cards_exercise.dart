import 'dart:math';
import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/common/instruction_modal.dart';
import '../widgets/common/level_selection_drawer.dart';
import '../widgets/common/minimalist_exercise_scaffold.dart';
import '../widgets/ordercards_level1_widget.dart';
import '../widgets/ordercards_level2_widget.dart';

class OrderCardsExercise extends StatefulWidget {
  final ExerciseConfig config;
  final UserProfile userProfile;

  const OrderCardsExercise({
    super.key,
    required this.userProfile,
  }) : config = const ExerciseConfig(
          id: 'C2.1',
          title: 'Order Cards to 20',
          skillTags: ['counting_2'],
          sourceCard: 'iMINT Green Card 2: Zahlenkarten bis 20 ordnen (Pages 75-76)',
          concept:
              'Understanding number sequence 1-20 and the tens-structure pattern. '
              'Numbers have fixed positions and predictable neighbor relationships.',
          observationPoints: [
            'Does child recognize the 2-row structure pattern?',
            'Can child identify missing numbers using neighbor logic?',
            'Can child reproduce the complete sequence from memory?',
            'Does child understand "13 is below 3 and follows 12" logic?',
          ],
          internalizationPath:
              'Level 1 (Read structured sequence) → Level 2 (Find 2-3 missing) → Level 3 (Find 5+ missing from memory)',
          targetNumber: 20, // Working with numbers 1-20
          hints: [
            'Look at the pattern: first row is 1-10, second row is 11-20.',
            'Each number in the second row is 10 more than the number above it!',
            'Use the neighbors: what comes before and after the gap?',
            'Remember: 11 follows 10 and is below 1, 12 follows 11 and is below 2...',
          ],
        );

  @override
  State<OrderCardsExercise> createState() => _OrderCardsExerciseState();
}

class _OrderCardsExerciseState extends State<OrderCardsExercise>
    with ExerciseProgressMixin {
  // Mixin requirements
  @override
  String get exerciseId => widget.config.id;

  @override
  UserProfile get userProfile => widget.userProfile;

  @override
  int get totalLevels => 3;

  @override
  int get finaleLevelNumber => 3;

  @override
  int get problemTimeLimit => 30;

  @override
  int get finaleMinProblems => 10;

  // New state management for EXERCISE_DESIGN_SYSTEM
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration;
  int _currentProblemIndex = 0;
  final int _problemsPerLevel = 10;
  List<bool> _problemResults = [];
  List<int> _missingNumbers = []; // Data for the current problem

  @override
  void initState() {
    super.initState();
    _initializeExercise();
  }

  Future<void> _initializeExercise() async {
    await initializeProgress();
    _switchLevel(_currentLevel, force: true);
  }

  @override
  void dispose() {
    onExerciseExit();
    super.dispose();
  }

  /// DIFFICULTY CURVE IMPLEMENTATION
  /// Returns the number of cards to hide based on the problem index.
  int _getMissingCardCountForProblem(int problemIndex) {
    // For Level 1, we don't hide cards, so we return 0.
    if (_currentLevel == ScaffoldLevel.guidedExploration) return 0;
    // Finale is always easy
    if (_currentLevel == ScaffoldLevel.finale) return 2 + Random().nextInt(2); // 2-3

    // Standard Difficulty Curve: Easy -> Hard -> Easy
    switch (problemIndex) {
      case 0: // Problem 1
      case 1: // Problem 2
        return 2; // Trivial: 2 missing (original L2)
      case 2: // Problem 3
      case 3: // Problem 4
        return 3; // Easy: 3 missing
      case 4: // Problem 5
      case 5: // Problem 6
        return 4; // Medium: 4 missing
      case 6: // Problem 7
      case 7: // Problem 8
        return 5; // Hard: 5 missing
      case 8: // Problem 9
        return 4; // Medium: 4 missing (cooldown)
      case 9: // Problem 10
        return 2; // Easy: 2 missing (end on success)
      default:
        return 2;
    }
  }

  /// Generates a new problem based on the current level and problem index.
  void _generateProblem() {
    final int numToHide = _getMissingCardCountForProblem(_currentProblemIndex);
    if (numToHide == 0) {
      _missingNumbers = [];
      setState(() {});
      return;
    }

    final allNumbers = List.generate(20, (i) => i + 1);
    allNumbers.shuffle();
    _missingNumbers = allNumbers.take(numToHide).toList()..sort();
    
    setState(() {});
  }

  void _onProblemComplete(bool isCorrect) {
    // This delay gives the progress bar time to animate before the widget rebuilds
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _problemResults.add(isCorrect);
        _currentProblemIndex++;
      });

      recordProblemResult(
        levelNumber: _currentLevel.levelNumber,
        correct: isCorrect,
      );

      if (_currentProblemIndex >= _problemsPerLevel) {
        _onLevelComplete();
      } else {
        _generateProblem();
      }
    });
  }

  void _onLevelComplete() async {
    final nextLevelNumber = _currentLevel.levelNumber + 1;
    bool didUnlock = false;
    if (nextLevelNumber <= totalLevels && !isLevelUnlocked(nextLevelNumber)) {
      await unlockLevel(nextLevelNumber);
      didUnlock = true;
    }

    // Show celebration dialog
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '🎉 Level ${_currentLevel.levelNumber} Complete! ${didUnlock ? "Level $nextLevelNumber unlocked!" : ""}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // Auto-advance
    if (nextLevelNumber <= totalLevels && isLevelUnlocked(nextLevelNumber)) {
       Future.delayed(const Duration(seconds: 1), () {
         if(mounted) _switchLevel(ScaffoldLevel.values[nextLevelNumber - 1]);
       });
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        if(mounted) _switchLevel(_currentLevel, force: true);
      });
    }
  }

  void _switchLevel(ScaffoldLevel level, {bool force = false}) {
    if (!force && !isLevelUnlocked(level.levelNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Complete Level ${level.levelNumber - 1} to unlock!'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _currentLevel = level;
      _currentProblemIndex = 0;
      _problemResults = [];
      _generateProblem();
    });
  }

  void _showLevelSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => LevelSelectionDrawer(
        levels: const [
          ScaffoldLevel.guidedExploration,
          ScaffoldLevel.supportedPractice,
          ScaffoldLevel.independentMastery,
        ],
        currentLevel: _currentLevel,
        onLevelSelected: _switchLevel,
        isLevelUnlocked: (level) => isLevelUnlocked(level.levelNumber),
      ),
    );
  }

  void _showInstructions() {
    InstructionModal.show(
      context,
      levelTitle:
          'Level ${_currentLevel.levelNumber}: ${_currentLevel.displayName}',
      instructionText: _getInstructionText(_currentLevel),
    );
  }

  String _getInstructionText(ScaffoldLevel level) {
    switch (level) {
      case ScaffoldLevel.guidedExploration:
        return 'Tap all 20 cards in order to "read" the sequence. Notice the pattern!';
      case ScaffoldLevel.supportedPractice:
        return 'Some numbers are missing. Find them by looking at the numbers that come before and after the gaps.';
      case ScaffoldLevel.independentMastery:
        return 'More numbers are missing now. Use the 2-row pattern and your memory to fill in the gaps. This is the final level!';
      default:
        return 'Order the cards to 20.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: MinimalistExerciseScaffold(
        exerciseTitle: widget.config.title,
        totalProblems: _problemsPerLevel,
        currentProblemIndex: _currentProblemIndex,
        problemResults: _problemResults,
        onShowInstructions: _showInstructions,
        onShowLevelSelector: _showLevelSelector,
        exerciseContent: _buildCurrentLevel(),
      ),
    );
  }

  Widget _buildCurrentLevel() {
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        return OrderCardsLevel1Widget(
          onProgressUpdate: (sequences) {
            if (sequences >= 1) {
              // For L1, one sequence completion counts as finishing the "level".
              _onLevelComplete();
            }
          },
        );
      case ScaffoldLevel.supportedPractice:
      case ScaffoldLevel.independentMastery:
        return OrderCardsLevel2Widget(
          key: ValueKey(_currentProblemIndex), // Ensures widget rebuilds on new problem
          missingNumbers: _missingNumbers,
          onCompleted: _onProblemComplete,
        );
      case ScaffoldLevel.advancedChallenge:
      case ScaffoldLevel.finale:
        return const SizedBox.shrink();
    }
  }
}
