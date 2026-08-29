import 'dart:math';
import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../widgets/common/minimalist_exercise_scaffold.dart';
import '../widgets/common/level_selection_drawer.dart';
import '../widgets/common/instruction_modal.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/doubling_fingers_20_level1_widget.dart';
import '../widgets/doubling_fingers_20_level2_widget.dart';
import '../widgets/doubling_fingers_20_level3_widget.dart';

class DoublingFingers20Exercise extends StatefulWidget {
  final UserProfile userProfile;

  const DoublingFingers20Exercise({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<DoublingFingers20Exercise> createState() => _DoublingFingers20ExerciseState();
}

class _DoublingFingers20ExerciseState extends State<DoublingFingers20Exercise>
    with ExerciseProgressMixin {
  
  // Current level tracking
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration;
  
  // Progress tracking
  final List<bool> _problemResults = [];
  int _currentProblemIndex = 0;
  final int _problemsPerLevel = 10;
  
  // Exercise-specific state
  int _targetNumber = 0; // The number to double (1-10)

  @override
  String get exerciseId => 'S3.5'; // Matches ExerciseService

  @override
  UserProfile get userProfile => widget.userProfile;

  @override
  int get totalLevels => 3;

  @override
  int get finaleLevelNumber => 3;

  @override
  int get problemTimeLimit => 20; // Slightly longer for higher numbers

  @override
  int get finaleMinProblems => 10;

  ExerciseConfig get exerciseConfig => const ExerciseConfig(
    id: 'S3.5',
    title: 'Doubling with Fingers (ZR20)',
    skillTags: ['basic_strategy_8', 'counting_20'],
    concept: 'Doubling numbers 1-10 using finger patterns',
    observationPoints: [
      'Does the child recognize the finger pattern instantly?',
      'Can the child solve without counting?',
    ],
    internalizationPath: 'Action (Copy) -> Image (Mental) -> Symbol (Abstract)',
    targetNumber: 20,
  );

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await initializeProgress();
    if (mounted) {
      _generateProblem();
    }
  }

  void _generateProblem() {
    // Generate a number 1-10 to double
    int newTarget;
    do {
      newTarget = 1 + Random().nextInt(10);
    } while (newTarget == _targetNumber && _currentProblemIndex > 0);
    
    setState(() {
      _targetNumber = newTarget;
    });
    
    startProblemTimer(); // Start timer from mixin
  }

  void _onProblemComplete(bool isCorrect) {
    setState(() {
      _problemResults.add(isCorrect);
      _currentProblemIndex++;
    });

    recordProblemResult(
      levelNumber: _currentLevel.levelNumber,
      correct: isCorrect,
      userAnswer: null,
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
    final isNextUnlocked = isLevelUnlocked(nextLevelNumber);

    if (!isNextUnlocked && nextLevelNumber <= totalLevels) {
       unlockLevel(nextLevelNumber);
    }
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Level ${_currentLevel.levelNumber} geschafft! 🎉'),
          content: Text('Toll gemacht! Bereit für die nächste Aufgabe?'),
          actions: [
            TextButton(
              onPressed: () {
                 Navigator.pop(context); // Close dialog
                 Navigator.of(context).pop(); // Exit exercise
              },
              child: Text('Für heute beenden'),
            ),
            if (nextLevelNumber <= totalLevels)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _switchLevel(ScaffoldLevel.values[nextLevelNumber - 1]);
                },
                child: Text('Nächstes Level'),
              ),
          ],
        ),
      );
    }
  }

  void _switchLevel(ScaffoldLevel level) {
    if (!isLevelUnlocked(level.levelNumber)) return;
    
    setState(() {
      _currentLevel = level;
      _currentProblemIndex = 0;
      _problemResults.clear();
      _generateProblem();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MinimalistExerciseScaffold(
      exerciseTitle: exerciseConfig.title,
      totalProblems: _problemsPerLevel,
      currentProblemIndex: _currentProblemIndex,
      problemResults: _problemResults,
      onShowInstructions: _showInstructions,
      onShowLevelSelector: _showLevelSelector,
      exerciseContent: _buildLevelContent(),
    );
  }

  Widget _buildLevelContent() {
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration: // Level 1
        return DoublingFingers20Level1Widget(
          targetNumber: _targetNumber,
          onComplete: _onProblemComplete,
        );
      case ScaffoldLevel.supportedPractice: // Level 2
        return DoublingFingers20Level2Widget(
          targetNumber: _targetNumber,
          onComplete: _onProblemComplete,
        );
      case ScaffoldLevel.independentMastery: // Level 3
        return DoublingFingers20Level3Widget(
          targetNumber: _targetNumber,
          onComplete: _onProblemComplete,
        );
      default:
        return Center(child: Text('Level noch nicht verfügbar'));
    }
  }

  void _showInstructions() {
    String text = '';
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        text = 'Look at the teacher\'s hands. Make your hands show the SAME number!';
        break;
      case ScaffoldLevel.supportedPractice:
        text = 'Look at the teacher\'s hands. Imagine your hands are the same. How many fingers in total?';
        break;
      case ScaffoldLevel.independentMastery:
        text = 'Double the number in your head. What is the total?';
        break;
      default:
        text = 'Follow the instructions.';
    }

    InstructionModal.show(
      context,
      levelTitle: 'Level ${_currentLevel.levelNumber}',
      instructionText: text,
    );
  }

  void _showLevelSelector() {
    final usedLevels = [
      ScaffoldLevel.guidedExploration,
      ScaffoldLevel.supportedPractice,
      ScaffoldLevel.independentMastery,
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => LevelSelectionDrawer(
        levels: usedLevels,
        currentLevel: _currentLevel,
        onLevelSelected: _switchLevel,
        isLevelUnlocked: (level) => isLevelUnlocked(level.levelNumber),
      ),
    );
  }
}
