import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/common/instruction_modal.dart';
import '../widgets/common/level_selection_drawer.dart';
import '../widgets/common/minimalist_exercise_scaffold.dart';
import '../widgets/finger_blitz_level1_widget.dart';
import '../widgets/finger_blitz_level3_widget.dart';

class FingerBlitzExercise extends StatefulWidget {
  final ExerciseConfig config;
  final UserProfile? userProfile;

  const FingerBlitzExercise({
    super.key,
    this.userProfile,
  }) : config = const ExerciseConfig(
          id: 'S1.1',
          title: 'Fingerblitz',
          skillTags: ['basic_strategy_1'],
          sourceCard: 'iMINT Green Card 137/138: Fingerblitz',
          concept: 'Subitizing and constructing numbers using finger patterns (Kraft der 5, Kraft der 10)',
          observationPoints: [
            'Can child recognize 5+n patterns instantly?',
            'Does child use "whole hand" strategy?',
            'Can child see 10-n relationships?',
          ],
          internalizationPath: 'See (No limit) → See (Flash) → Make (5+n) → Make (10-n)',
          targetNumber: 10,
          hints: [
            'Think: One hand is 5.',
            'Two hands are 10.',
          ],
        );

  @override
  State<FingerBlitzExercise> createState() => _FingerBlitzExerciseState();
}

class _LevelConfig {
  final int levelNumber;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final ScaffoldLevel scaffoldLevel;

  const _LevelConfig({
    required this.levelNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.scaffoldLevel,
  });
}

class _FingerBlitzExerciseState extends State<FingerBlitzExercise>
    with ExerciseProgressMixin {
  
  @override
  UserProfile get userProfile => widget.userProfile ?? UserProfile(id: 'guest', name: 'Guest', age: 5, skillTags: []);

  @override
  String get exerciseId => widget.config.id;

  @override
  int get totalLevels => 4;

  @override
  int get finaleLevelNumber => 4; // Level 4 is the "mastery" challenge

  @override
  int get problemTimeLimit => 30; // Fast perception needed

  @override
  int get finaleMinProblems => 10;

  int _currentLevelNumber = 1;
  List<bool> _problemResults = [];
  int _currentProblemIndex = 0;

  final List<_LevelConfig> _levels = [
    _LevelConfig(
      levelNumber: 1,
      title: 'Finger erkennen',
      description: 'Wie viele Finger siehst du? Nimm dir Zeit.',
      icon: Icons.visibility,
      color: Colors.blue,
      scaffoldLevel: ScaffoldLevel.guidedExploration,
    ),
    _LevelConfig(
      levelNumber: 2,
      title: 'Fingerblitz!',
      description: 'Pass gut auf! Die Finger verschwinden schnell.',
      icon: Icons.flash_on,
      color: Colors.orange,
      scaffoldLevel: ScaffoldLevel.supportedPractice,
    ),
    _LevelConfig(
      levelNumber: 3,
      title: 'Finger zeigen',
      description: 'Stelle die Zahl mit 5 und noch ein paar mehr dar.',
      icon: Icons.pan_tool,
      color: Colors.green,
      scaffoldLevel: ScaffoldLevel.independentMastery,
    ),
    _LevelConfig(
      levelNumber: 4,
      title: 'Von 10 abziehen',
      description: 'Starte mit 10 und nimm welche weg, um die Zahl zu bilden.',
      icon: Icons.remove_circle_outline,
      color: Colors.purple,
      scaffoldLevel: ScaffoldLevel.advancedChallenge,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeExercise();
  }

  Future<void> _initializeExercise() async {
    if (widget.userProfile != null) {
      await initializeProgress();
    }
    if (mounted) {
      setState(() {
        int highest = 1;
        for (int i = 1; i <= totalLevels; i++) {
          if (isLevelUnlocked(i)) highest = i;
        }
        _currentLevelNumber = highest;
      });
    }
  }

  @override
  void dispose() {
    if (widget.userProfile != null) saveProgress();
    super.dispose();
  }

  void _onProblemResult(bool isCorrect) {
    setState(() {
      _problemResults.add(isCorrect);
      _currentProblemIndex++;
    });

    if (widget.userProfile != null) {
      recordProblemResult(
        levelNumber: _currentLevelNumber,
        correct: isCorrect,
        userAnswer: null,
      );
    }

    if (_currentProblemIndex >= 10) {
      _onLevelComplete();
    }
  }

  void _onLevelComplete() async {
    if (widget.userProfile != null) {
      await saveProgress();
      if (_currentLevelNumber < totalLevels) {
        unlockLevel(_currentLevelNumber + 1);
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Level $_currentLevelNumber geschafft! 🎉'),
        content: const Text('Tolle Arbeit!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Stopp'),
          ),
          if (_currentLevelNumber < totalLevels)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _switchLevel(_levels[_currentLevelNumber]); // Index matches next level number (since index 0 is Level 1)
                // No wait.
                // _levels[0] -> Level 1
                // _levels[1] -> Level 2
                // if current=1, next=2. _levels[1] is correct.
              },
              child: const Text('Nächstes Level'),
            ),
        ],
      ),
    );
  }

  void _switchLevel(_LevelConfig level) {
    if (widget.userProfile != null && !isLevelUnlocked(level.levelNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Level gesperrt!')),
      );
      return;
    }

    setState(() {
      _currentLevelNumber = level.levelNumber;
      _problemResults = [];
      _currentProblemIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig = _levels.firstWhere((l) => l.levelNumber == _currentLevelNumber);

    return MinimalistExerciseScaffold(
      exerciseTitle: widget.config.title,
      totalProblems: 10,
      currentProblemIndex: _currentProblemIndex,
      problemResults: _problemResults,
      onShowInstructions: () {
        InstructionModal.show(
          context,
          levelTitle: currentConfig.title,
          instructionText: currentConfig.description,
          levelColor: currentConfig.color,
        );
      },
      onShowLevelSelector: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => LevelSelectionDrawer(
            levels: _levels.map((l) => l.scaffoldLevel).toList(),
            currentLevel: currentConfig.scaffoldLevel,
            onLevelSelected: (scaffoldLevel) {
              final config = _levels.firstWhere((l) => l.scaffoldLevel == scaffoldLevel);
              _switchLevel(config);
            },
            isLevelUnlocked: (scaffoldLevel) {
              final config = _levels.firstWhere((l) => l.scaffoldLevel == scaffoldLevel);
              return widget.userProfile == null || isLevelUnlocked(config.levelNumber);
            },
          ),
        );
      },
      exerciseContent: _buildLevel(),
    );
  }

  Widget _buildLevel() {
    switch (_currentLevelNumber) {
      case 1:
        return FingerBlitzLevel1Widget(
          key: const ValueKey(1),
          onProblemSolved: _onProblemResult,
          isFlashMode: false,
        );
      case 2:
        return FingerBlitzLevel1Widget(
          key: const ValueKey(2),
          onProblemSolved: _onProblemResult,
          isFlashMode: true,
        );
      case 3:
        return FingerBlitzLevel3Widget(
          key: const ValueKey(3),
          onProblemSolved: _onProblemResult,
          mode: FingerConstructionMode.additive,
        );
      case 4:
        return FingerBlitzLevel3Widget(
          key: const ValueKey(4),
          onProblemSolved: _onProblemResult,
          mode: FingerConstructionMode.subtractive,
        );
      default:
        return const Center(child: Text('Fehler'));
    }
  }
}
