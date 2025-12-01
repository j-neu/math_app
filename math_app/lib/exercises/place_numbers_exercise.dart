import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/placenumbers_level1_widget.dart';
import '../widgets/placenumbers_level2_widget.dart';
import '../widgets/common/instruction_modal.dart';
import '../widgets/common/level_selection_drawer.dart';
import '../widgets/common/minimalist_exercise_scaffold.dart';

class PlaceNumbersExercise extends StatefulWidget {
  final ExerciseConfig config;
  // Add userProfile if needed by mixin, though constructor usually takes it
  // But the original file didn't take userProfile in constructor.
  // ExerciseService usually passes it. I should add it.
  final UserProfile? userProfile; 

  const PlaceNumbersExercise({
    super.key,
    this.userProfile, // Make optional to match existing signature if needed, or require it
  }) : config = const ExerciseConfig(
          id: 'C10.1',
          title: 'Place Numbers on Line',
          skillTags: ['counting_10', 'counting_11'],
          sourceCard: 'iMINT Green Card 10: Zahlen am Zahlenstrahl positionieren',
          concept: 'Understanding relative position of numbers on a line (0-20)',
          observationPoints: [
            'Can child order numbers correctly?',
            'Does child estimate position reasonably (e.g. 10 in middle)?',
          ],
          internalizationPath: 'Level 1 (3 cards) → Level 2 (5 cards)',
          targetNumber: 20,
          hints: [
            'Smaller numbers go left, larger to the right.',
            '10 is in the middle of 0 and 20.',
          ],
        );

  @override
  State<PlaceNumbersExercise> createState() => _PlaceNumbersExerciseState();
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

class _PlaceNumbersExerciseState extends State<PlaceNumbersExercise>
    with ExerciseProgressMixin {
  
  // Helper to access profile safely - if not passed, we can't save progress properly
  // but we should handle it. Ideally ExerciseService passes it.
  @override
  UserProfile get userProfile => widget.userProfile ?? UserProfile(
    id: 'guest',
    name: 'Guest',
    age: 5,
    skillTags: [],
  );

  @override
  String get exerciseId => widget.config.id;

  @override
  int get totalLevels => 2;

  @override
  int get finaleLevelNumber => 2; // Level 2 is the "mastery" level here

  @override
  int get problemTimeLimit => 60; // Longer time for drag & drop

  @override
  int get finaleMinProblems => 10;

  int _currentLevelNumber = 1;
  List<bool> _problemResults = [];
  int _currentProblemIndex = 0;

  final List<_LevelConfig> _levels = [
    _LevelConfig(
      levelNumber: 1,
      title: 'Place 3 Numbers',
      description: 'Drag 3 cards to the correct spots.',
      icon: Icons.filter_3,
      color: Colors.blue,
      scaffoldLevel: ScaffoldLevel.guidedExploration,
    ),
    _LevelConfig(
      levelNumber: 2,
      title: 'Place 5 Numbers',
      description: 'Drag 5 cards. A bit harder!',
      icon: Icons.filter_5,
      color: Colors.orange,
      scaffoldLevel: ScaffoldLevel.supportedPractice,
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
        // Start at highest unlocked
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
      
      // Mark completed if final level
      if (_currentLevelNumber == finaleLevelNumber) {
         // Simple check
         bool allCorrect = _problemResults.every((r) => r);
         if (allCorrect) {
           // Handled by saveProgress status calc usually, but we can force check
         }
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Level $_currentLevelNumber Complete! 🎉'),
        content: const Text('Great work!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Stop'),
          ),
          if (_currentLevelNumber < totalLevels)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _switchLevel(_levels[_currentLevelNumber]); // Index matches next level - 1? No. 
                // _levels indices: 0 (L1), 1 (L2).
                // current=1. next=2. _levels[1] is L2.
              },
              child: const Text('Next Level'),
            ),
        ],
      ),
    );
  }

  void _switchLevel(_LevelConfig level) {
    if (widget.userProfile != null && !isLevelUnlocked(level.levelNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Level locked!')),
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
            levels: ScaffoldLevel.values.take(2).toList(), // Only show 2 levels
            currentLevel: currentConfig.scaffoldLevel,
            onLevelSelected: (scaffoldLevel) {
              final config = _levels.firstWhere((l) => l.scaffoldLevel == scaffoldLevel);
              _switchLevel(config);
            },
            isLevelUnlocked: (l) => widget.userProfile == null || isLevelUnlocked(l.levelNumber),
          ),
        );
      },
      exerciseContent: _buildLevel(),
    );
  }

  Widget _buildLevel() {
    switch (_currentLevelNumber) {
      case 1:
        return PlaceNumbersLevel1Widget(onProblemSolved: _onProblemResult);
      case 2:
        return PlaceNumbersLevel2Widget(onProblemSolved: _onProblemResult);
      default:
        return const Center(child: Text('Error'));
    }
  }
}
