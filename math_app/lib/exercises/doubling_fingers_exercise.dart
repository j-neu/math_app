import 'dart:math';
import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../widgets/common/minimalist_exercise_scaffold.dart';
import '../widgets/common/level_selection_drawer.dart';
import '../widgets/common/instruction_modal.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/doubling_fingers_level1_widget.dart';
import '../widgets/doubling_fingers_level2_widget.dart';
import '../widgets/doubling_fingers_level3_widget.dart';

class DoublingFingersExercise extends StatefulWidget {
  final UserProfile userProfile;

  const DoublingFingersExercise({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<DoublingFingersExercise> createState() => _DoublingFingersExerciseState();
}

class _DoublingFingersExerciseState extends State<DoublingFingersExercise>
    with ExerciseProgressMixin {
  
  // Current level tracking
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration;
  
  // Progress tracking
  final List<bool> _problemResults = [];
  int _currentProblemIndex = 0;
  final int _problemsPerLevel = 10;
  
  // Exercise-specific state
  int _targetNumber = 0; // The number to double (1-5)

  @override
  String get exerciseId => 'S3.3'; // Matches ExerciseService

  @override
  UserProfile get userProfile => widget.userProfile;

  @override
  int get totalLevels => 3;

  @override
  int get finaleLevelNumber => 3;

  @override
  int get problemTimeLimit => 15; // Fast recall

  @override
  int get finaleMinProblems => 10;

  ExerciseConfig get exerciseConfig => const ExerciseConfig(
    id: 'S3.3',
    title: 'Doubling with Fingers',
    skillTags: ['basic_strategy_8', 'counting_1'],
    concept: 'Doubling numbers 1-5 using finger patterns',
    observationPoints: [
      'Does the child recognize the finger pattern instantly?',
      'Does the child need to count fingers 1-by-1?',
      'Can the child solve without looking at hands?'
    ],
    internalizationPath: 'Action (Match) -> Image (One hand) -> Symbol (Abstract)',
    targetNumber: 10,
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
    // Generate a number 1-5 to double
    int newTarget;
    do {
      newTarget = 1 + Random().nextInt(5);
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
      userAnswer: null, // Not tracking exact answer input yet
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
        return DoublingFingersLevel1Widget(
          targetNumber: _targetNumber,
          onComplete: _onProblemComplete,
        );
      case ScaffoldLevel.supportedPractice: // Level 2
        return DoublingFingersLevel2Widget(
          targetNumber: _targetNumber,
          onComplete: _onProblemComplete,
        );
      case ScaffoldLevel.independentMastery: // Level 3
        return DoublingFingersLevel3Widget(
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
        text = 'Look at the left hand. Show the SAME number on the right hand to double it!';
        break;
      case ScaffoldLevel.supportedPractice:
        text = 'Look at the left hand. Imagine the other hand is the same. How many fingers in total?';
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
    // ScaffoldLevel.values is [guidedExploration, supportedPractice, independentMastery, challenge, finale]
    // We only use first 3.
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