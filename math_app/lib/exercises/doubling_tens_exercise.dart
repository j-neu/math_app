import 'dart:math';
import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/common/minimalist_exercise_scaffold.dart';
import '../widgets/common/instruction_modal.dart';
import '../widgets/common/level_selection_drawer.dart';
import '../widgets/doubling_tens_level1_widget.dart';
import '../widgets/doubling_tens_level2_widget.dart';
import '../widgets/doubling_tens_level3_widget.dart';

class DoublingTensExercise extends StatefulWidget {
  final UserProfile userProfile;
  final String exerciseId;

  const DoublingTensExercise({
    Key? key,
    required this.userProfile,
    this.exerciseId = 'strategy_doubling_tens_1',
  }) : super(key: key);

  @override
  State<DoublingTensExercise> createState() => _DoublingTensExerciseState();
}

class _DoublingTensExerciseState extends State<DoublingTensExercise>
    with ExerciseProgressMixin {
  
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration;
  List<bool> _problemResults = [];
  int _currentProblemIndex = 0;
  final int _problemsPerLevel = 10;
  
  int _targetTens = 2; // Default 2 tens (20)
  int _lastTargetTens = -1;

  @override
  String get exerciseId => widget.exerciseId;

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

  @override
  ExerciseConfig get exerciseConfig => ExerciseConfig(
    id: widget.exerciseId,
    title: 'Zehner verdoppeln',
    skillTags: ['strategy_doubling_tens_1'],
    concept: 'Doubling multiples of 10',
    observationPoints: ['Can child double tens?', 'Does child connect tens to ones (3 tens = 30)?'],
    internalizationPath: 'Mirror/Material -> Manual Placing -> Mental',
    targetNumber: 100,
  );

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await initializeProgress();
    if (mounted) {
      _generateProblem();
    }
  }

  void _generateProblem() {
    startProblemTimer();
    final r = Random();
    
    // Difficulty Curve for Tens (Range 1-5, results 20-100)
    // Standard Curve from DIFFICULTY_CURVE.md:
    // P1-2: Trivial (1-2 tens)
    // P3-4: Easy (2-3 tens)
    // P5-6: Medium (3-4 tens)
    // P7-8: Hard (4-5 tens)
    // P9: Medium (3-4 tens)
    // P10: Easy (1-2 tens)
    
    int minT = 1;
    int maxT = 5;

    if (_currentProblemIndex < 2) {
      // Trivial
      minT = 1;
      maxT = 2;
    } else if (_currentProblemIndex < 4) {
      // Easy
      minT = 2;
      maxT = 3;
    } else if (_currentProblemIndex < 6) {
      // Medium
      minT = 3;
      maxT = 4;
    } else if (_currentProblemIndex < 8) {
      // Hard
      minT = 4;
      maxT = 5;
    } else if (_currentProblemIndex < 9) {
      // Medium
      minT = 3;
      maxT = 4;
    } else {
      // Easy (End on success)
      minT = 1;
      maxT = 2;
    }
    
    // Generate new target, avoiding repeat if possible
    int newTarget;
    int attempts = 0;
    do {
      newTarget = minT + r.nextInt(maxT - minT + 1);
      attempts++;
    } while (newTarget == _lastTargetTens && (maxT > minT) && attempts < 10);
    
    _targetTens = newTarget;
    _lastTargetTens = newTarget;
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
    
    final nextLevelNumber = _currentLevel.levelNumber + 1;
    if (nextLevelNumber <= totalLevels) {
      unlockLevel(nextLevelNumber);
    }

    if (!mounted) return;
    
    // Auto-advance logic could go here, but using dialog for now per standard
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Level ${_currentLevel.levelNumber} Geschafft! 🎉'),
        content: const Text('Toll gemacht! Weiter zum nächsten Level?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pop();
            },
            child: const Text('Pause machen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (nextLevelNumber <= totalLevels) {
                _switchLevel(ScaffoldLevel.values[nextLevelNumber - 1]);
              } else {
                 Navigator.of(context).pop();
              }
            },
            child: Text(nextLevelNumber <= totalLevels ? 'Weiter' : 'Fertig'),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await onExerciseExit();
        return true;
      },
      child: MinimalistExerciseScaffold(
        exerciseTitle: exerciseConfig.title,
        totalProblems: _problemsPerLevel,
        currentProblemIndex: _currentProblemIndex,
        problemResults: _problemResults,
        onShowInstructions: _showInstructions,
        onShowLevelSelector: _showLevelSelector,
        exerciseContent: _buildCurrentLevelWidget(),
      ),
    );
  }

  Widget _buildCurrentLevelWidget() {
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        return DoublingTensLevel1Widget(
          key: ValueKey(_currentProblemIndex),
          targetTens: _targetTens,
          onComplete: _onProblemComplete,
        );
      case ScaffoldLevel.supportedPractice:
        return DoublingTensLevel2Widget(
          key: ValueKey(_currentProblemIndex),
          targetTens: _targetTens,
          onComplete: _onProblemComplete,
        );
      case ScaffoldLevel.independentMastery:
        return DoublingTensLevel3Widget(
          key: ValueKey(_currentProblemIndex),
          targetTens: _targetTens,
          onComplete: _onProblemComplete,
        );
      default:
        return const Center(child: Text('Level kommt bald'));
    }
  }

  void _showInstructions() {
    String text = '';
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        text = 'Zähle die Zehnerstreifen. Drücke den Spiegel-Knopf, um sie zu verdoppeln.';
        break;
      case ScaffoldLevel.supportedPractice:
        text = 'Lege genauso viele Zehner dazu. Wie viele Zehner und wie viele Einer sind es?';
        break;
      case ScaffoldLevel.independentMastery:
        text = 'Verdopple die Zahl im Kopf.';
        break;
      default:
        text = '';
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
