import 'dart:math';
import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/common/minimalist_exercise_scaffold.dart';
import '../widgets/common/instruction_modal.dart';
import '../widgets/common/level_selection_drawer.dart';
import '../widgets/doubling_mirror_level1_widget.dart';
import '../widgets/doubling_mirror_level2_widget.dart';
import '../widgets/doubling_mirror_level3_widget.dart';

class DoublingMirrorExercise extends StatefulWidget {
  final UserProfile userProfile;
  final String exerciseId;
  final String title;
  final int minInputNumber;
  final int maxInputNumber;

  const DoublingMirrorExercise({
    Key? key,
    required this.userProfile,
    required this.exerciseId,
    required this.title,
    this.minInputNumber = 1,
    this.maxInputNumber = 10,
  }) : super(key: key);

  @override
  State<DoublingMirrorExercise> createState() => _DoublingMirrorExerciseState();
}

class _DoublingMirrorExerciseState extends State<DoublingMirrorExercise>
    with ExerciseProgressMixin {
  // Current level tracking
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration; // L1

  // Progress tracking (for segmented bar)
  List<bool> _problemResults = []; // true = correct, false = incorrect
  int _currentProblemIndex = 0;
  final int _problemsPerLevel = 10;
  
  @override
  String get exerciseId => widget.exerciseId;

  @override
  UserProfile get userProfile => widget.userProfile;
  
  // Difficulty parameters
  int _targetNumber = 3;

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
  
  @override
  int get totalLevels => 3;
  
  @override
  int get finaleLevelNumber => 3;

  @override
  int get problemTimeLimit => 30; // 30s for doubling seems reasonable

  @override
  int get finaleMinProblems => 10;
  
  @override
  ExerciseConfig get exerciseConfig => ExerciseConfig(
    id: widget.exerciseId,
    title: widget.title,
    skillTags: ['basic_strategy_7'],
    sourceCard: 'iMINT-Kartei 149-150',
    concept: 'Doubling as adding same quantity',
    observationPoints: ['Can child double numbers up to ${widget.maxInputNumber}?', 'Does child understand 1:1 relation?'],
    internalizationPath: 'Manual placing -> Mirror tool -> Mental doubling',
    targetNumber: widget.maxInputNumber * 2,
  );

  void _generateProblem() {
    startProblemTimer(); // Start mixin timer
    final r = Random();
    
    // Range Calculation
    // Respect widget.minInputNumber and widget.maxInputNumber
    // BUT also apply standard difficulty curve if possible within that range
    
    int rangeMin = widget.minInputNumber;
    int rangeMax = widget.maxInputNumber;
    
    // If range is large enough (e.g. 1-5 or 6-10), try to apply curve
    // Trivial: Start of range
    // Easy: Middle of range
    // Hard: End of range
    
    // For small ranges (e.g. 5 numbers), standard curve is compressed
    // Range Size = 5 (e.g. 1,2,3,4,5)
    // Trivial (1-2): 1-2
    // Easy (3-4): 2-3
    // Medium (5-6): 3-4
    // Hard (7-8): 4-5
    // Medium (9): 3-4
    // Easy (10): 2-3
    
    int localMin = rangeMin;
    int localMax = rangeMax;

    if (rangeMax - rangeMin >= 2) {
      if (_currentProblemIndex < 2) { // 0, 1: Trivial
        localMax = rangeMin + 1;
      } else if (_currentProblemIndex < 4) { // 2, 3: Easy
        localMin = rangeMin + 1;
        localMax = rangeMin + 2;
      } else if (_currentProblemIndex < 6) { // 4, 5: Medium
        localMin = rangeMin + 2;
        localMax = rangeMax - 1; 
      } else if (_currentProblemIndex < 8) { // 6, 7: Hard
        localMin = rangeMax - 1;
        localMax = rangeMax;
      } else if (_currentProblemIndex == 8) { // 8: Medium
        localMin = rangeMin + 2;
        localMax = rangeMax - 1;
      } else { // 9: Easy
        localMin = rangeMin + 1;
        localMax = rangeMin + 2;
      }
    }
    
    // Safety clamp
    if (localMin < widget.minInputNumber) localMin = widget.minInputNumber;
    if (localMax > widget.maxInputNumber) localMax = widget.maxInputNumber;
    if (localMax < localMin) localMax = localMin;
    
    _targetNumber = localMin + r.nextInt(localMax - localMin + 1);
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

    // Show celebration
    if (!mounted) return;
    
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
              Navigator.of(context).pop(); // Exit
            },
            child: const Text('Pause machen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (nextLevelNumber <= totalLevels) {
                _switchLevel(ScaffoldLevel.values[nextLevelNumber - 1]);
              } else {
                 Navigator.of(context).pop(); // Finished all
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
    return MinimalistExerciseScaffold(
      exerciseTitle: widget.title,
      totalProblems: _problemsPerLevel,
      currentProblemIndex: _currentProblemIndex,
      problemResults: _problemResults,
      onShowInstructions: _showInstructions,
      onShowLevelSelector: _showLevelSelector,
      exerciseContent: _buildCurrentLevelWidget(),
    );
  }

  Widget _buildCurrentLevelWidget() {
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration: // Level 1
        return DoublingMirrorLevel1Widget(
          targetCount: _targetNumber,
          onComplete: _onProblemComplete,
        );
      case ScaffoldLevel.supportedPractice: // Level 2
        return DoublingMirrorLevel2Widget(
          targetCount: _targetNumber,
          onComplete: _onProblemComplete,
        );
      case ScaffoldLevel.independentMastery: // Level 3
        return DoublingMirrorLevel3Widget(
          targetCount: _targetNumber,
          onComplete: _onProblemComplete,
        );
      default:
        return const Center(child: Text('Level noch nicht verfügbar'));
    }
  }

  void _showInstructions() {
    String text = '';
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        text = 'Zähle die Punkte links. Lege dann GENAUSO VIELE Punkte auf die rechte Seite.';
        break;
      case ScaffoldLevel.supportedPractice:
        text = 'Zähle die Punkte. Benutze dann den Spiegel-Knopf, um zu verdoppeln.';
        break;
      case ScaffoldLevel.independentMastery:
        text = 'Stell dir die Punkte vor. Wie viele sind es, wenn du verdoppelst?';
        break;
      default:
        text = 'Viel Erfolg!';
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