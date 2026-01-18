import 'dart:math';
import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/common/instruction_modal.dart';
import '../widgets/common/level_selection_drawer.dart';
import '../widgets/common/minimalist_exercise_scaffold.dart';
import '../widgets/basic_strategies/finger_calc_level1_widget.dart';
import '../widgets/basic_strategies/finger_calc_level2_widget.dart';
import '../widgets/basic_strategies/finger_calc_level3_widget.dart';

import '../models/user_profile.dart';

class FingerCalculationExercise extends StatefulWidget {
  final ExerciseConfig exerciseConfig;
  final UserProfile? userProfile;

  const FingerCalculationExercise({
    Key? key,
    required this.exerciseConfig,
    this.userProfile,
  }) : super(key: key);

  @override
  State<FingerCalculationExercise> createState() => _FingerCalculationExerciseState();
}

class _FingerCalculationExerciseState extends State<FingerCalculationExercise>
    with ExerciseProgressMixin {
  
  @override
  UserProfile get userProfile => widget.userProfile ?? UserProfile(id: 'guest', name: 'Guest', age: 5, skillTags: []);

  // Current state
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration;
  int _currentProblemIndex = 0;
  List<bool> _problemResults = [];
  
  // Current problem data
  late int _leftHand;
  late int _rightHand;
  late int _subtractAmount;

  @override
  void initState() {
    super.initState();
    _init();
    _generateProblem();
  }

  Future<void> _init() async {
    await initializeProgress();
    if (mounted) setState(() {});
  }
  
  @override
  String get exerciseId => widget.exerciseConfig.id;
  
  @override
  int get totalLevels => 3;
  
  @override
  int get finaleLevelNumber => 3; // Level 3 is Mastery/Finale here

  @override
  int get problemTimeLimit => 20; // 20s per problem

  @override
  int get finaleMinProblems => 10;

  void _generateProblem() {
    startProblemTimer();
    final rand = Random();
    
    // Default to subtraction as per card "Finger Klappen"

    // Difficulty Curve Application
    // Level 1-3 all use standard curve roughly
    // P1-2: Trivial (e.g. 5-5, 5-1)
    // P3-6: Easy/Medium
    // P7-8: Hard (Crossing 5 boundary e.g. 7-3)
    
    int startTotal;
    
    if (_currentProblemIndex < 2) {
      // Trivial: Start with 5 or small number, subtract 0 or 1 or all
      if (rand.nextBool()) {
        startTotal = 5;
        _subtractAmount = rand.nextBool() ? 5 : 0;
      } else {
        startTotal = 3 + rand.nextInt(3); // 3-5
        _subtractAmount = 1;
      }
    } else if (_currentProblemIndex < 6) {
      // Medium: Within one hand or simple cross
      startTotal = 5 + rand.nextInt(6); // 5-10
      _subtractAmount = 1 + rand.nextInt(4); // 1-4
    } else if (_currentProblemIndex < 8) {
      // Hard: Crossing 5 boundary explicitly?
      // e.g. 7 - 3 (needs taking from 5 and 2? No, 7 is 5+2. 7-3 is taking 2 then 1)
      startTotal = 7 + rand.nextInt(4); // 7-10
      _subtractAmount = 3 + rand.nextInt(startTotal - 5); // Ensure we cross or use 5
    } else {
      // Easy ending
      startTotal = 5 + rand.nextInt(3);
      _subtractAmount = 2;
    }
    
    // Ensure valid
    if (_subtractAmount > startTotal) _subtractAmount = startTotal;
    
    // Distribute startTotal to hands (Power of 5 strategy: Fill left first)
    if (startTotal <= 5) {
      _leftHand = startTotal;
      _rightHand = 0;
    } else {
      _leftHand = 5;
      _rightHand = startTotal - 5;
    }
  }

  void _onProblemComplete(bool isCorrect) {
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
  }

  void _onLevelComplete() async {
    await saveProgress();
    
    final nextLevelNum = _currentLevel.levelNumber + 1;
    if (nextLevelNum <= totalLevels) {
       await unlockLevel(nextLevelNum);
    }

    // Standard completion dialog logic would go here
    // For now, auto-advance if unlocked
    if (nextLevelNum <= totalLevels && isLevelUnlocked(nextLevelNum)) {
      _switchLevel(ScaffoldLevel.values[nextLevelNum - 1]);
    }
  }

  void _switchLevel(ScaffoldLevel level) {
    if (isLevelUnlocked(level.levelNumber)) {
      setState(() {
        _currentLevel = level;
        _currentProblemIndex = 0;
        _problemResults.clear();
        _generateProblem();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MinimalistExerciseScaffold(
      exerciseTitle: 'Finger Klappen',
      totalProblems: _problemsPerLevel,
      currentProblemIndex: _currentProblemIndex,
      problemResults: _problemResults,
      onShowInstructions: () => InstructionModal.show(
        context,
        levelTitle: 'Level ${_currentLevel.levelNumber}',
        instructionText: _getInstructions(),
      ),
      onShowLevelSelector: () => showModalBottomSheet(
        context: context,
        builder: (context) => LevelSelectionDrawer(
          levels: ScaffoldLevel.values.take(totalLevels).toList(),
          currentLevel: _currentLevel,
          onLevelSelected: _switchLevel,
          isLevelUnlocked: (l) => isLevelUnlocked(l.levelNumber),
        ),
      ),
      exerciseContent: _buildLevelContent(),
    );
  }

  Widget _buildLevelContent() {
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration: // Level 1
        return FingerCalcLevel1Widget(
          key: ValueKey(_currentProblemIndex),
          initialLeft: _leftHand,
          initialRight: _rightHand,
          subtractAmount: _subtractAmount,
          onComplete: _onProblemComplete,
        );
      case ScaffoldLevel.supportedPractice: // Level 2
        return FingerCalcLevel2Widget(
          key: ValueKey(_currentProblemIndex),
          initialLeft: _leftHand,
          initialRight: _rightHand,
          subtractAmount: _subtractAmount,
          onComplete: _onProblemComplete,
        );
      case ScaffoldLevel.independentMastery: // Level 3
        return FingerCalcLevel3Widget(
          key: ValueKey(_currentProblemIndex),
          initialLeft: _leftHand,
          initialRight: _rightHand,
          subtractAmount: _subtractAmount,
          onComplete: _onProblemComplete,
        );
      default:
        return Center(child: Text("Level not implemented"));
    }
  }

  String _getInstructions() {
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        return "Nimm die angegebene Anzahl Finger weg, indem du auf die Hände tippst.";
      case ScaffoldLevel.supportedPractice:
        return "Löse die Aufgabe. Du kannst die Finger benutzen, um dir zu helfen.";
      case ScaffoldLevel.independentMastery:
        return "Löse die Aufgabe im Kopf. Wenn du Hilfe brauchst, tippe auf 'Zeige Finger'.";
      default:
        return "";
    }
  }
  
  // Internal helper for problem count
  int get _problemsPerLevel => 10;
}
