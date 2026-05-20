import 'package:flutter/material.dart';
import 'package:math_app/mixins/exercise_progress_mixin.dart';
import 'package:math_app/models/exercise_config.dart';
import 'package:math_app/models/scaffold_level.dart';
import 'package:math_app/models/user_profile.dart';
import 'package:math_app/widgets/common/minimalist_exercise_scaffold.dart';
import 'package:math_app/widgets/common/instruction_modal.dart';
import 'package:math_app/widgets/common/level_selection_drawer.dart';
import 'package:math_app/widgets/opposite_change_level_widget.dart';

class OppositeChangeExercise extends StatefulWidget {
  final ExerciseConfig exerciseConfig;
  final UserProfile userProfile;

  const OppositeChangeExercise({
    Key? key,
    required this.exerciseConfig,
    required this.userProfile,
  }) : super(key: key);

  @override
  _OppositeChangeExerciseState createState() => _OppositeChangeExerciseState();
}

class _OppositeChangeExerciseState extends State<OppositeChangeExercise>
    with ExerciseProgressMixin {
  
  @override
  String get exerciseId => widget.exerciseConfig.id;

  @override
  UserProfile get userProfile => widget.userProfile;

  // Current level tracking
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration;
  
  // Progress tracking (for segmented bar)
  List<bool> _problemResults = []; // true = correct, false = incorrect
  int _currentProblemIndex = 0;
  
  // Level unlock tracking (loaded from mixin)
  // We use isLevelUnlocked(int) from mixin

  @override
  void initState() {
    super.initState();
    initializeProgress();
    startProblemTimer();
  }

  @override
  int get totalLevels => 3;

  @override
  int get finaleLevelNumber => 3; // L3 is the last one here

  @override
  int get problemTimeLimit => 30; // 30s seems reasonable for mental manipulation

  @override
  int get finaleMinProblems => 10;

  void _onLevelComplete() async {
    // Unlock next level
    final nextLevelNumber = _currentLevel.levelNumber + 1;
    if (nextLevelNumber <= totalLevels) {
      unlockLevel(nextLevelNumber);
    }

    // Show celebration
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Level ${_currentLevel.levelNumber} geschafft! 🎉'),
        content: Text('Toll gemacht! Bereit für die nächste Aufgabe?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to menu
            },
            child: Text('Für heute beenden'),
          ),
          if (nextLevelNumber <= totalLevels)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _switchLevel(ScaffoldLevel.values[nextLevelNumber - 1]);
              },
              child: Text('Weiter'),
            ),
        ],
      ),
    );
  }

  void _switchLevel(ScaffoldLevel level) {
    if (!isLevelUnlocked(level.levelNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Schließe zuerst die vorherigen Level ab!')),
      );
      return;
    }

    setState(() {
      _currentLevel = level;
      _problemResults = [];
      _currentProblemIndex = 0;
      startProblemTimer(); // Start timer for new level
    });
  }

  String _getInstructionText(ScaffoldLevel level) {
    switch (level) {
      case ScaffoldLevel.guidedExploration: // Level 1
        return "Watch the animation carefully. One counter changes color! How many Red and Blue are there now?";
      case ScaffoldLevel.supportedPractice: // Level 2
        return "Numbers are getting bigger (6-15). Watch the change and count carefully.";
      case ScaffoldLevel.independentMastery: // Level 3
        return "Challenge time! Numbers up to 20. Remember: Only one changes!";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return MinimalistExerciseScaffold(
      exerciseTitle: widget.exerciseConfig.title,
      totalProblems: 10,
      currentProblemIndex: _currentProblemIndex,
      problemResults: _problemResults,
      onShowInstructions: () => InstructionModal.show(
        context,
        levelTitle: 'Level ${_currentLevel.levelNumber}',
        instructionText: _getInstructionText(_currentLevel),
      ),
      onShowLevelSelector: () => showModalBottomSheet(
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
      ),
      exerciseContent: KeyedSubtree(
        key: ValueKey('${_currentLevel.index}_$_currentProblemIndex'), // Force rebuild on new problem
        child: OppositeChangeLevelWidget(
          levelNumber: _currentLevel.levelNumber,
          problemIndex: _currentProblemIndex,
          onResult: (isCorrect) {
             setState(() {
              _problemResults.add(isCorrect);
            });
            
            recordProblemResult(
              levelNumber: _currentLevel.levelNumber,
              correct: isCorrect,
            );
          },
          onProblemComplete: () {
             setState(() {
               _currentProblemIndex++;
             });
             if (_currentProblemIndex >= 10) {
               _onLevelComplete();
             } else {
               startProblemTimer();
             }
          },
        ),
      ),
    );
  }
}
