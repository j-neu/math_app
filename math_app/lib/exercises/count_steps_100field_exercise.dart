import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/count_steps_100field_widget.dart';
import '../widgets/common/instruction_modal.dart';
import '../widgets/common/segmented_progress_bar.dart';

/// Metadata for the 6 custom levels in this exercise
class _LevelConfig {
  final int levelNumber;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String pedagogicalAction;
  final ScaffoldLevel mappedScaffoldLevel; // For compatibility with drawer

  const _LevelConfig({
    required this.levelNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.pedagogicalAction,
    required this.mappedScaffoldLevel,
  });
}

/// Complete implementation of C6.2: Counting in steps in the 100 field
///
/// This exercise follows the framework documented in IMINT_TO_APP_FRAMEWORK.md.
///
/// **Source:** iMINT Arbeitskarte 8 (related to 100-field) and general step counting.
///
/// **Levels:**
/// 1. Steps of 2 (Visible Grid)
/// 2. Steps of 5 (Visible Grid)
/// 3. Steps of 10 (Visible Grid)
/// 4. Steps of 2 (Hidden Grid, Help available)
/// 5. Steps of 5 (Hidden Grid, Help available)
/// 6. Steps of 10 (Hidden Grid, Help available)
class CountSteps100FieldExercise extends StatefulWidget {
  final ExerciseConfig config;
  final UserProfile userProfile;

  const CountSteps100FieldExercise({
    super.key,
    required this.userProfile,
  }) : config = const ExerciseConfig(
          id: 'C6.2',
          title: 'Count in Steps on 100-Field',
          skillTags: ['counting_8', 'counting_6', 'counting_7'],
          sourceCard: 'iMINT Arbeitskarte 8 (Adapted for steps)',
          concept:
              'Navigating the 100-field using step counting patterns (2, 5, 10). '
              'Internalizing the position of numbers and their relationships.',
          observationPoints: [
            'Can child predict the next number in a sequence (+2, +5, +10)?',
            'Does child use the visual structure of the 100-field (columns for +10)?',
            'Can child count mentally without the field visible (Levels 4-6)?',
          ],
          internalizationPath:
              'Levels 1-3 (Visual support) → Levels 4-6 (Mental representation with scaffolding)',
          targetNumber: 100,
          hints: [
            'Steps of 10 go down one row.',
            'Steps of 5 end in 0 or 5.',
            'Steps of 2 skip one number.',
          ],
        );

  @override
  State<CountSteps100FieldExercise> createState() => _CountSteps100FieldExerciseState();
}

class _CountSteps100FieldExerciseState extends State<CountSteps100FieldExercise>
    with ExerciseProgressMixin {
  @override
  String get exerciseId => widget.config.id;

  @override
  UserProfile get userProfile => widget.userProfile;

  @override
  int get totalLevels => 6;

  @override
  int get finaleLevelNumber => 6;

  @override
  int get problemTimeLimit => 30; // 30s per problem for completion

  @override
  int get finaleMinProblems => 10;

  // Track problem results for current level (for segmented bar)
  List<bool> _currentLevelResults = [];

  // Level configurations
  final List<_LevelConfig> _levelConfigs = [
    const _LevelConfig(
      levelNumber: 1,
      title: 'Steps of 2 (Grid)',
      description: 'Count by 2s with the 100-field',
      icon: Icons.grid_on,
      color: Colors.blue,
      pedagogicalAction: 'Handlung: Visual skip counting',
      mappedScaffoldLevel: ScaffoldLevel.guidedExploration,
    ),
    const _LevelConfig(
      levelNumber: 2,
      title: 'Steps of 5 (Grid)',
      description: 'Count by 5s with the 100-field',
      icon: Icons.grid_on,
      color: Colors.green,
      pedagogicalAction: 'Handlung: Visual skip counting',
      mappedScaffoldLevel: ScaffoldLevel.supportedPractice,
    ),
    const _LevelConfig(
      levelNumber: 3,
      title: 'Steps of 10 (Grid)',
      description: 'Count by 10s with the 100-field',
      icon: Icons.grid_on,
      color: Colors.orange,
      pedagogicalAction: 'Handlung: Visual skip counting',
      mappedScaffoldLevel: ScaffoldLevel.independentMastery,
    ),
    const _LevelConfig(
      levelNumber: 4,
      title: 'Steps of 2 (Mental)',
      description: 'Count by 2s without the grid',
      icon: Icons.psychology,
      color: Colors.purple,
      pedagogicalAction: 'Bild/Symbol: Mental skip counting',
      mappedScaffoldLevel: ScaffoldLevel.advancedChallenge,
    ),
    const _LevelConfig(
      levelNumber: 5,
      title: 'Steps of 5 (Mental)',
      description: 'Count by 5s without the grid',
      icon: Icons.psychology,
      color: Colors.teal,
      pedagogicalAction: 'Bild/Symbol: Mental skip counting',
      mappedScaffoldLevel: ScaffoldLevel.advancedChallenge, // Reuse enum
    ),
    const _LevelConfig(
      levelNumber: 6,
      title: 'Steps of 10 (Mental)',
      description: 'Count by 10s without the grid',
      icon: Icons.emoji_events,
      color: Colors.amber,
      pedagogicalAction: 'Finale: Mastery of patterns',
      mappedScaffoldLevel: ScaffoldLevel.finale,
    ),
  ];

  int _currentLevelNumber = 1;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    await initializeProgress(); // From Mixin
    setState(() {
      // Ensure level 1 is unlocked
      if (!isLevelUnlocked(1)) {
        unlockLevel(1);
      }
      
      // Resume from last unlocked level if possible, or stay at 1
      // Simple logic: find highest unlocked level
      for (int i = 6; i >= 1; i--) {
        if (isLevelUnlocked(i)) {
          _currentLevelNumber = i;
          break;
        }
      }
    });
  }

  @override
  void dispose() {
    // Note: Mixin handles saveProgress, but we can also call it manually
    saveProgress();
    super.dispose();
  }

  void _switchLevel(int levelNum) {
    if (!isLevelUnlocked(levelNum)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Complete Level ${levelNum - 1} first!')), 
      );
      return;
    }

    setState(() {
      _currentLevelNumber = levelNum;
      _currentLevelResults = []; // Reset visual progress for new level
    });
    saveProgress();
    Navigator.pop(context); // Close drawer if open
  }

  void _showLevelSelector() {
    // Since LevelSelectionDrawer expects List<ScaffoldLevel>, and we have custom 6 levels,
    // we'll use a custom bottom sheet instead to properly show our 6 levels.
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Level',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _levelConfigs.length,
                itemBuilder: (context, index) {
                  final config = _levelConfigs[index];
                  final isUnlocked = isLevelUnlocked(config.levelNumber);
                  final isCurrent = config.levelNumber == _currentLevelNumber;
                  
                  return ListTile(
                    leading: Icon(
                      isUnlocked ? config.icon : Icons.lock,
                      color: isUnlocked ? config.color : Colors.grey,
                    ),
                    title: Text(
                      config.title,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isUnlocked ? Colors.black : Colors.grey,
                      ),
                    ),
                    subtitle: Text(config.description),
                    selected: isCurrent,
                    enabled: isUnlocked,
                    onTap: () => _switchLevel(config.levelNumber),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInstructions() {
    final config = _levelConfigs.firstWhere((l) => l.levelNumber == _currentLevelNumber);
    InstructionModal.show(
      context,
      levelTitle: config.title,
      instructionText: _getInstructionsForLevel(_currentLevelNumber),
      levelColor: config.color,
    );
  }

  String _getInstructionsForLevel(int level) {
    switch (level) {
      case 1: return 'Count forward in steps of 2! \nLook at the 100-field. \nTap the blocked square and type the number.';
      case 2: return 'Count forward in steps of 5! \nNotice the pattern: numbers end in 5 or 0.';
      case 3: return 'Count forward in steps of 10! \nNotice: you just move down one row!';
      case 4: return 'Count forward in steps of 2! \nThe grid is hidden now. \nUse the "Help" button if you need to peek.';
      case 5: return 'Count forward in steps of 5! \nGrid hidden. Remember: 5, 10, 15, 20...';
      case 6: return 'Finale: Steps of 10! \nThis should be easy: just add 10 each time.';
      default: return '';
    }
  }

  void _onLevelComplete(int levelNumber) async {
    await saveProgress(); // Mixin save

    if (levelNumber < totalLevels) {
      unlockLevel(levelNumber + 1);
      // Don't auto-advance immediately, let user decide or show dialog
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Level $levelNumber Complete! 🎉'),
        content: Text(levelNumber == totalLevels 
            ? 'Congratulations! You finished the entire exercise!' 
            : 'Great job! Level ${levelNumber + 1} is now unlocked.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit exercise
            },
            child: const Text('Stop for Today'),
          ),
          if (levelNumber < totalLevels)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                setState(() {
                  _currentLevelNumber = levelNumber + 1;
                  _currentLevelResults = [];
                });
              },
              child: Text('Start Level ${levelNumber + 1}'),
            ),
        ],
      ),
    );
  }

  void _onProblemResult(bool correct) {
    setState(() {
      _currentLevelResults.add(correct);
    });
    recordProblemResult(
      levelNumber: _currentLevelNumber, 
      correct: correct,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) await saveProgress();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.config.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.menu), // Level selector
              onPressed: _showLevelSelector,
              tooltip: 'Select Level',
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showInstructions,
              tooltip: 'Instructions',
            ),
          ],
        ),
        body: Column(
          children: [
            // Show progress for current level
            SegmentedProgressBar(
              totalSegments: 10, // Fixed 10 problems per level
              currentSegment: _currentLevelResults.length,
              results: _currentLevelResults,
            ),
            Expanded(
              child: _buildLevelWidget(_currentLevelNumber),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelWidget(int levelNumber) {
    int stepSize = 2;
    bool isGridVisible = true;
    bool allowToggle = false;

    switch (levelNumber) {
      case 1: stepSize = 2; isGridVisible = true; break;
      case 2: stepSize = 5; isGridVisible = true; break;
      case 3: stepSize = 10; isGridVisible = true; break;
      case 4: stepSize = 2; isGridVisible = false; allowToggle = true; break;
      case 5: stepSize = 5; isGridVisible = false; allowToggle = true; break;
      case 6: stepSize = 10; isGridVisible = false; allowToggle = true; break;
    }

    return CountSteps100FieldWidget(
      // Key forces rebuild when level changes
      key: ValueKey(levelNumber), 
      levelNumber: levelNumber,
      stepSize: stepSize,
      isGridInitiallyVisible: isGridVisible,
      allowGridToggle: allowToggle,
      onProblemComplete: _onProblemResult,
      onLevelComplete: () => _onLevelComplete(levelNumber),
    );
  }
}
