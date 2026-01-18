import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/common/minimalist_exercise_scaffold.dart';
import '../widgets/common/instruction_modal.dart';
import '../widgets/common/level_selection_drawer.dart';
import '../widgets/more_less_level1_widget.dart';

class MoreLessExercise extends StatefulWidget {
  final ExerciseConfig exerciseConfig;
  final UserProfile userProfile;

  const MoreLessExercise({
    Key? key,
    required this.exerciseConfig,
    required this.userProfile,
  }) : super(key: key);

  @override
  _MoreLessExerciseState createState() => _MoreLessExerciseState();
}

class _MoreLessExerciseState extends State<MoreLessExercise>
    with ExerciseProgressMixin {
  // Current level - only one level for this skill
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration;
  
  // Progress tracking
  List<bool> _problemResults = []; // true = won round, false = lost? Or just completed rounds?
  // For this game, a "problem" is a round. 
  // We track 10 rounds. 
  int _currentRoundIndex = 0;
  static const int _roundsPerGame = 10;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await initializeProgress();
    startProblemTimer();
  }

  @override
  int get problemTimeLimit => 0; // No time limit for this game

  @override
  int get finaleMinProblems => _roundsPerGame;

  // We only have 1 level, but the mixin expects totalLevels getter
  @override
  int get totalLevels => 1;

  @override
  int get finaleLevelNumber => 1;

  @override
  String get exerciseId => widget.exerciseConfig.id;

  @override
  UserProfile get userProfile => widget.userProfile;

  void _onRoundComplete(bool isWin) {
    setState(() {
      _problemResults.add(isWin);
      _currentRoundIndex++;
    });

    // Record result
    recordProblemResult(
      levelNumber: _currentLevel.levelNumber,
      correct: isWin, 
    );
    
    // Start timer for next round
    if (_currentRoundIndex < _roundsPerGame) {
      startProblemTimer();
    }

    if (_currentRoundIndex >= _roundsPerGame) {
      _onGameComplete();
    }
  }

  void _onGameComplete() async {
    await saveProgress();
    
    // Calculate winner
    int childWins = _problemResults.where((r) => r).length; 
    // Wait, _problemResults stores if the child *answered correctly*, not if they won the dice roll.
    // The widget handles the game logic (scores). The Coordinator tracks *learning progress*.
    // So "correct" here means "Child correctly identified who won and the difference".
    
    // Since this is a single level skill, completion marks the skill as mastered.
    // We check if accuracy is good enough to mark "completed".
    bool mastered = _problemResults.where((r) => r).length >= 8; // 80% accuracy in identifying difference
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Game Over!'),
        content: Text(mastered ? 'Great job! You are a master at comparing!' : 'Good game! Keep practicing!'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to menu
            },
            child: Text('Finish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MinimalistExerciseScaffold(
      exerciseTitle: widget.exerciseConfig.title,
      totalProblems: _roundsPerGame,
      currentProblemIndex: _currentRoundIndex,
      problemResults: _problemResults,
      onShowInstructions: _showInstructions,
      onShowLevelSelector: _showLevelSelector,
      exerciseContent: MoreLessLevel1Widget(
        onRoundComplete: _onRoundComplete,
        totalRounds: _roundsPerGame,
      ),
    );
  }

  void _showInstructions() {
    InstructionModal.show(
      context,
      levelTitle: 'More or Less (Hamstern)',
      instructionText: 'Roll the dice! Who has more? How many more? Collect the difference!',
      levelColor: Colors.purple,
    );
  }

  void _showLevelSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => LevelSelectionDrawer(
        levels: [_currentLevel],
        currentLevel: _currentLevel,
        onLevelSelected: (_) {}, // No switching possible
        isLevelUnlocked: (_) => true,
      ),
    );
  }
}
