import 'dart:math';
import 'package:flutter/material.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../widgets/common/minimalist_exercise_scaffold.dart';
import '../widgets/doubling_boat_level1_widget.dart';
import '../widgets/doubling_boat_level2_widget.dart';
import '../widgets/doubling_boat_level3_widget.dart';
import '../widgets/common/instruction_modal.dart';
import '../widgets/common/level_selection_drawer.dart';

class DoublingBoatExercise extends StatefulWidget {
  final UserProfile userProfile;

  const DoublingBoatExercise({
    super.key,
    required this.userProfile,
  });

  @override
  State<DoublingBoatExercise> createState() => _DoublingBoatExerciseState();
}

class _DoublingBoatExerciseState extends State<DoublingBoatExercise> with ExerciseProgressMixin {
  int _targetNumber = 5;
  final Random _random = Random();
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration;
  
  // Progress tracking for minimalist scaffold
  List<bool> _problemResults = [];
  int _currentProblemIndex = 0;

  @override
  void initState() {
    super.initState();
    initializeProgress();
  }

  @override
  String get exerciseId => 'S3.4'; // Matches ExerciseService and Milestone

  @override
  ExerciseConfig get exerciseConfig => const ExerciseConfig(
    id: 'S3.4',
    title: 'Verdoppeln am Rechenschiffchen',
    skillTags: ['basic_strategy_9', 'basic_strategy_10'],
    concept: 'Doubling using the 5/10 structure of the boat.',
    observationPoints: [
      'Does the child use the structure (5+5) or count by ones?',
      'Can the child double numbers > 5 mentally?',
    ],
    internalizationPath: 'Action (Place) -> Partial View (Cover) -> Mental (Empty)',
    targetNumber: 20,
    hints: ['Look at the groups of 5.', 'Double the 5 first, then the rest.'],
    successMessages: ['Correct!', 'Great doubling!', 'You got it!'],
  );

  @override
  UserProfile get userProfile => widget.userProfile;
  
  @override
  int get totalLevels => 3; // Guided, Supported, Mastery (Finale)
  
  @override
  int get finaleLevelNumber => 3; // ScaffoldLevel.independentMastery.levelNumber

  @override
  int get problemTimeLimit => 20;
  
  @override
  int get finaleMinProblems => 10;

  void _generateProblem() {
    int min = 1; 
    int max = 10;

    // Difficulty Curve
    if (_currentProblemIndex < 2) {
      max = 3; // Trivial
    } else if (_currentProblemIndex < 4) {
      min = 4; max = 5; // Easy
    } else if (_currentProblemIndex < 8) {
      min = 6; max = 10; // Hard
    } else {
      min = 2; max = 5; // End Easy
    }
    
    int newTarget;
    do {
      newTarget = min + _random.nextInt(max - min + 1);
    } while (newTarget == _targetNumber && (max - min) > 0);
    
    setState(() {
      _targetNumber = newTarget;
      startProblemTimer(); // Mixin method
    });
  }

  void _onLevelComplete() async {
    await saveProgress();

    // Determine next level
    ScaffoldLevel? nextLevel;
    if (_currentLevel == ScaffoldLevel.guidedExploration) {
      nextLevel = ScaffoldLevel.supportedPractice;
    } else if (_currentLevel == ScaffoldLevel.supportedPractice) {
      nextLevel = ScaffoldLevel.independentMastery;
    } else {
      nextLevel = null; // Finished
    }

    if (nextLevel != null) {
       unlockLevel(nextLevel.levelNumber);
    }

    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Level ${_currentLevel.levelNumber} geschafft! 🎉'),
        content: const Text('Toll gemacht! Bereit für das nächste Level?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Für heute beenden'),
          ),
          if (nextLevel != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _switchLevel(nextLevel!);
              },
              child: const Text('Nächstes Level'),
            ),
        ],
      ),
    );
  }

  void _switchLevel(ScaffoldLevel level) {
    if (!isLevelUnlocked(level.levelNumber)) return;
    
    setState(() {
      _currentLevel = level;
      _problemResults = [];
      _currentProblemIndex = 0;
      _generateProblem();
    });
  }

  void _onProblemComplete(bool isCorrect) {
    setState(() {
      _problemResults.add(isCorrect);
      _currentProblemIndex++;
    });

    // Record result (mixin handles timer stop)
    recordProblemResult(
      levelNumber: _currentLevel.levelNumber,
      correct: isCorrect,
    );

    if (_currentProblemIndex >= 10) {
      _onLevelComplete();
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _generateProblem();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        content = DoublingBoatLevel1Widget(
          key: ValueKey('L1_$_targetNumber'),
          targetNumber: _targetNumber,
          onResult: _onProblemComplete,
        );
        break;
      case ScaffoldLevel.supportedPractice:
        content = DoublingBoatLevel2Widget(
          key: ValueKey('L2_$_targetNumber'),
          targetNumber: _targetNumber,
          onResult: _onProblemComplete,
        );
        break;
      case ScaffoldLevel.independentMastery:
      default: // Also covers Finale if erroneously reached
        content = DoublingBoatLevel3Widget(
          key: ValueKey('L3_$_targetNumber'),
          targetNumber: _targetNumber,
          onResult: _onProblemComplete,
        );
        break;
    }

    return MinimalistExerciseScaffold(
      exerciseTitle: exerciseConfig.title,
      totalProblems: 10,
      currentProblemIndex: _currentProblemIndex,
      problemResults: _problemResults,
      onShowInstructions: _showInstructions,
      onShowLevelSelector: _showLevelSelector,
      exerciseContent: content,
    );
  }

  void _showInstructions() {
    String text = "";
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        text = "Tap the empty slots in the bottom row to make it match the top row. Double the number!";
        break;
      case ScaffoldLevel.supportedPractice:
        text = "Imagine the blue counters in the bottom row. How many are there in total?";
        break;
      default:
        text = "Imagine the whole boat! If you have $_targetNumber red counters, and double them, how many do you have?";
        break;
    }
    
    InstructionModal.show(
      context,
      levelTitle: 'Level ${_currentLevel.levelNumber}',
      instructionText: text,
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
        ],
        currentLevel: _currentLevel,
        onLevelSelected: _switchLevel,
        isLevelUnlocked: (level) => isLevelUnlocked(level.levelNumber),
      ),
    );
  }
}