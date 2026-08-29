import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/tens_calculation_level1_widget.dart';
import '../widgets/tens_calculation_level2_widget.dart';
import '../widgets/tens_calculation_level3_widget.dart';
import '../widgets/tens_calculation_level4_widget.dart';
import '../widgets/common/segmented_progress_bar.dart';
import '../widgets/common/instruction_modal.dart';
import '../widgets/common/level_selection_drawer.dart';

class TensCalculationExercise extends StatefulWidget {
  final ExerciseConfig config;
  final UserProfile userProfile;

  const TensCalculationExercise({
    super.key,
    required this.userProfile,
  }) : config = const ExerciseConfig(
          id: 'basic_strategy_11',
          title: 'Tens Calculation',
          skillTags: ['basic_strategy_11'],
          concept: 'Calculating with tens using the analogy to ones',
          observationPoints: [
            'Does the child understand 3 Zehner = 30?',
            'Can the child transfer 3+4 to 30+40?',
            'Does the child use the term "Zehner" correctly?',
          ],
          internalizationPath: 'L1 (Visual Add Tens) → L2 (Visual Sub Tens) → L3 (Symbolic Translation +) → L4 (Symbolic Translation -)',
          targetNumber: 100,
          hints: [
            'Wie viele Zehner sind das?',
            'Rechne erst mit Zehnern (3 Z + 2 Z), dann schreibe die Zahl (50).',
            'Denke an die Einer: 3 + 2 = 5, also 30 + 20 = 50.',
          ],
        );

  @override
  State<TensCalculationExercise> createState() => _TensCalculationExerciseState();
}

class _TensCalculationExerciseState extends State<TensCalculationExercise>
    with ExerciseProgressMixin {
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration;

  // Progress tracking
  List<bool> _problemResults = [];
  int _currentProblemIndex = 0;
  static const int _problemsPerLevel = 10;
  static const int _requiredCorrect = 8; // 80% accuracy to pass

  @override
  String get exerciseId => widget.config.id;

  @override
  UserProfile get userProfile => widget.userProfile;

  @override
  int get totalLevels => 4;

  @override
  int get finaleLevelNumber => 4;

  @override
  int get problemTimeLimit => 30;

  @override
  int get finaleMinProblems => 10;

  @override
  void initState() {
    super.initState();
    _initializeExercise();
  }

  Future<void> _initializeExercise() async {
    await initializeProgress();
    setState(() {
      if (isLevelUnlocked(4)) {
        _currentLevel = ScaffoldLevel.advancedChallenge;
      } else if (isLevelUnlocked(3)) {
        _currentLevel = ScaffoldLevel.independentMastery;
      } else if (isLevelUnlocked(2)) {
        _currentLevel = ScaffoldLevel.supportedPractice;
      } else {
        _currentLevel = ScaffoldLevel.guidedExploration;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onProblemComplete(bool isCorrect) {
    setState(() {
      _problemResults.add(isCorrect);
      _currentProblemIndex++;
    });

    recordProblemResult(
      levelNumber: _scaffoldLevelToInt(_currentLevel),
      correct: isCorrect,
    );

    if (_currentProblemIndex >= _problemsPerLevel) {
      _onLevelComplete();
    }
  }

  void _onLevelComplete() {
    int correctCount = _problemResults.where((r) => r).length;
    int levelNum = _scaffoldLevelToInt(_currentLevel);

    if (correctCount >= _requiredCorrect) {
      if (levelNum < totalLevels) {
        unlockLevel(levelNum + 1);
        _showLevelUnlockedMessage(levelNum + 1);
        _autoAdvanceToNextLevel();
      } else {
        _showCompletionMessage();
      }
    } else {
       // Retry level logic or just stay
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Versuche es nochmal — du brauchst mindestens $_requiredCorrect richtige!'),
          backgroundColor: Colors.orange,
        ),
      );
      // Reset for retry
       Future.delayed(const Duration(seconds: 2), () {
         setState(() {
           _problemResults = [];
           _currentProblemIndex = 0;
         });
       });
    }
  }

  void _showLevelUnlockedMessage(int nextLevel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Level $nextLevel Unlocked!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _showCompletionMessage() {
     ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Skill Completed! Great job!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _autoAdvanceToNextLevel() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final nextLevelNumber = _scaffoldLevelToInt(_currentLevel) + 1;
    if (nextLevelNumber <= totalLevels) {
      setState(() {
        _currentLevel = _intToScaffoldLevel(nextLevelNumber);
        _problemResults = [];
        _currentProblemIndex = 0;
      });
    }
  }

  void _onLevelSelected(ScaffoldLevel level) {
    int levelNumber = _scaffoldLevelToInt(level);
    if (isLevelUnlocked(levelNumber)) {
      setState(() {
        _currentLevel = level;
        _problemResults = [];
        _currentProblemIndex = 0;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schließe zuerst die vorherigen Level ab!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  int _scaffoldLevelToInt(ScaffoldLevel level) {
    switch (level) {
      case ScaffoldLevel.guidedExploration: return 1;
      case ScaffoldLevel.supportedPractice: return 2;
      case ScaffoldLevel.independentMastery: return 3;
      case ScaffoldLevel.advancedChallenge: return 4;
      default: return 1;
    }
  }

  ScaffoldLevel _intToScaffoldLevel(int levelNumber) {
    switch (levelNumber) {
      case 1: return ScaffoldLevel.guidedExploration;
      case 2: return ScaffoldLevel.supportedPractice;
      case 3: return ScaffoldLevel.independentMastery;
      case 4: return ScaffoldLevel.advancedChallenge;
      default: return ScaffoldLevel.guidedExploration;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: WillPopScope(
          onWillPop: () async {
            await onExerciseExit();
            return true;
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      'Level ${_scaffoldLevelToInt(_currentLevel)}: ${_getLevelTitle(_currentLevel)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu),
                          tooltip: 'Level wählen',
                          onPressed: _showLevelSelector,
                        ),
                        IconButton(
                          icon: const Icon(Icons.help_outline),
                          tooltip: 'Anleitung',
                          onPressed: _showInstructions,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SegmentedProgressBar(
                totalSegments: _problemsPerLevel,
                currentSegment: _currentProblemIndex,
                results: _problemResults,
              ),
              Expanded(
                child: _buildCurrentLevelWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInstructions() {
    InstructionModal.show(
      context,
      levelTitle: 'Level ${_scaffoldLevelToInt(_currentLevel)}',
      instructionText: _getLevelInstructions(_currentLevel),
    );
  }

  void _showLevelSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => LevelSelectionDrawer(
        levels: const [
          ScaffoldLevel.guidedExploration,
          ScaffoldLevel.supportedPractice,
          ScaffoldLevel.independentMastery,
          ScaffoldLevel.advancedChallenge,
        ],
        currentLevel: _currentLevel,
        onLevelSelected: _onLevelSelected,
        isLevelUnlocked: (level) => isLevelUnlocked(_scaffoldLevelToInt(level)),
      ),
    );
  }

  String _getLevelTitle(ScaffoldLevel level) {
    switch (level) {
      case ScaffoldLevel.guidedExploration: return 'Addition of Tens';
      case ScaffoldLevel.supportedPractice: return 'Subtraction of Tens';
      case ScaffoldLevel.independentMastery: return 'Addition Language';
      case ScaffoldLevel.advancedChallenge: return 'Subtraction Language';
      default: return '';
    }
  }

  String _getLevelInstructions(ScaffoldLevel level) {
    switch (level) {
      case ScaffoldLevel.guidedExploration: return 'Add the tens strips together.';
      case ScaffoldLevel.supportedPractice: return 'Take away the tens strips.';
      case ScaffoldLevel.independentMastery: return 'Translate "Zehner" to numbers.';
      case ScaffoldLevel.advancedChallenge: return 'Translate subtraction to numbers.';
      default: return '';
    }
  }

  Widget _buildCurrentLevelWidget() {
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        return TensCalculationLevel1Widget(onComplete: _onProblemComplete);
      case ScaffoldLevel.supportedPractice:
        return TensCalculationLevel2Widget(onComplete: _onProblemComplete);
      case ScaffoldLevel.independentMastery:
        return TensCalculationLevel3Widget(onComplete: _onProblemComplete);
      case ScaffoldLevel.advancedChallenge:
        return TensCalculationLevel4Widget(onComplete: _onProblemComplete);
      default:
        return const Center(child: Text('Level noch nicht verfügbar'));
    }
  }
}
