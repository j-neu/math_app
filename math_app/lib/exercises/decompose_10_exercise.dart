import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/decompose10_level1_widget.dart';
import '../widgets/decompose10_level2_widget.dart';
import '../widgets/decompose10_level3_widget.dart';
import '../widgets/decompose10_level4_widget.dart';

/// Complete implementation of Z1: Decompose 10 exercise with 3-Level Scaffolding + Finale.
///
/// **Level 1: Guided Exploration (Handlung)**
/// - Tap counters to flip them, equation auto-displays
///
/// **Level 2: Supported Practice (Vorstellung begins)**
/// - Visual counters shown with random decomposition
/// - Child must WRITE the equation
///
/// **Level 3: Independent Mastery (Vorstellung → Symbol)**
/// - Visual HIDDEN by default
/// - Child writes from memory/mental imagery
/// - Visual appears ONLY on errors (no-fail safety net)
///
/// **Level 4: Finale (Mental Decomposition 5-9)**
/// - Easier mixed review with variable totals
/// - Ensures completion on success
class Decompose10Exercise extends StatefulWidget {
  final ExerciseConfig config;
  final UserProfile userProfile;

  const Decompose10Exercise({
    super.key,
    required this.userProfile,
  }) : config = const ExerciseConfig(
          id: 'Z1',
          title: 'Decompose 10',
          skillTags: ['decomposition_1', 'decomposition_3'],
          concept: 'Understanding part-whole relationships: 10 can be split into pairs',
          observationPoints: [
            'Gegensinniges Verändern: As one part increases (+1), other decreases (-1)',
            'Systematic finding: Can child find ALL decompositions?',
            'Pattern recognition through 3-level progression',
          ],
          internalizationPath:
              'Level 1 (Handlung) → Level 2 (Vorstellung begins) → Level 3 (Vorstellung → Symbol) → Finale',
          targetNumber: 10,
          expectedDecompositions: 11,
          hints: [
            'Try flipping the counters to see different combinations.',
            'Have you found them all? How do you know?',
          ],
        );

  @override
  State<Decompose10Exercise> createState() => _Decompose10ExerciseState();
}

class _Decompose10ExerciseState extends State<Decompose10Exercise>
    with ExerciseProgressMixin {
  
  // COMPLETION CRITERIA:
  // 1. All levels unlocked (1->2->3->4)
  // 2. Finale (Level 4):
  //    - Min 10 problems attempted
  //    - Zero errors in last 10 problems
  //    - Time < 15s per problem in last 10 problems
  
  @override
  String get exerciseId => widget.config.id;

  @override
  UserProfile get userProfile => widget.userProfile;

  @override
  int get totalLevels => 4;

  @override
  int get finaleLevelNumber => 4;
  
  @override
  int get problemTimeLimit => 15; // 15 seconds per problem for mastery
  
  @override
  int get finaleMinProblems => 10;

  // Local UI State
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration;
  
  // Level 2 specific state (Supported Practice)
  int _level2Correct = 0;
  static const int _level2RequiredCorrect = 10;

  // Level 3 specific state (Independent Mastery)
  int _level3FoundCount = 0;
  static const int _level3RequiredFound = 11;

  // Level 4 specific state (Finale)
  int _level4Correct = 0;
  static const int _level4RequiredCorrect = 10;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await initializeProgress();
    if (mounted) {
      _loadStateFromProgress();
      setState(() {});
    }
  }

  void _loadStateFromProgress() {
    // Level 2: Supported Practice
    final l2 = getLevelProgress(2);
    if (l2 != null) {
      // Count actual correct answers from history to be safe
      _level2Correct = l2.problemResults.where((p) => p.correct).length;
    }

    // Level 3: Independent Mastery
    // We track "found count" locally. If L4 is unlocked, we assume L3 is done.
    if (isLevelUnlocked(4)) {
      _level3FoundCount = _level3RequiredFound;
    } else {
      final l3 = getLevelProgress(3);
      if (l3 != null) {
        _level3FoundCount = l3.problemResults.where((p) => p.correct).length;
      }
    }

    // Level 4: Finale
    final l4 = getLevelProgress(4);
    if (l4 != null) {
      // Only count recent correct answers for current session "streak"?
      // Or cumulative? For finale, usually we want 10 *in a row* or 10 *total*?
      // The mixin checks "last N problems" for completion.
      // For UI progress bar, we can show cumulative or session. 
      // Let's show cumulative to avoid discouraging child on reload.
      _level4Correct = l4.problemResults.where((p) => p.correct).length;
    }
  }

  void _setActiveLevel(ScaffoldLevel level) {
    setState(() {
      _currentLevel = level;
    });
    // Start timer if we moved to a problem-solving level
    if (level.levelNumber == 2 || level.levelNumber == 4) {
      startProblemTimer();
    }
  }

  void _onLevel1Complete() {
    unlockLevel(2);
    _showLevelUnlockedMessage(ScaffoldLevel.supportedPractice);
    _setActiveLevel(ScaffoldLevel.supportedPractice);
  }

  void _onLevel2Answer(bool correct) {
    if (correct) {
      setState(() {
        _level2Correct++;
      });
      
      recordProblemResult(
        levelNumber: 2, 
        correct: true, 
      );
      
      if (_level2Correct >= _level2RequiredCorrect) {
        if (!isLevelUnlocked(3)) {
          unlockLevel(3);
          _showLevelUnlockedMessage(ScaffoldLevel.independentMastery);
        }
      }
    } else {
      recordProblemResult(
        levelNumber: 2, 
        correct: false, 
      );
    }
    startProblemTimer(); // Start for next problem
  }

  void _onLevel3Progress(int foundCount) {
    setState(() {
      _level3FoundCount = foundCount;
    });
    
    // For L3, we might want to record 'correct' for every new found pair.
    // However, the widget callback only gives total count. 
    // We'll record a "problem" for each new one found?
    // Or just record once at the end?
    // Let's rely on the user finding all 11 to unlock L4.
    
    if (foundCount >= _level3RequiredFound) {
      if (!isLevelUnlocked(4)) {
        unlockLevel(4);
        _showLevelUnlockedMessage(ScaffoldLevel.finale);
        
        // Record a "problem result" to ensure progress is saved/activity tracked
        recordProblemResult(levelNumber: 3, correct: true);
      }
    }
  }

  void _onLevel4Answer(bool correct) {
    if (correct) {
      setState(() {
        _level4Correct++;
      });
      
      recordProblemResult(
        levelNumber: 4,
        correct: true,
      );

      if (_level4Correct >= _level4RequiredCorrect) {
        _showCompletionDialog();
        saveProgress(); 
      }
    } else {
      recordProblemResult(
        levelNumber: 4,
        correct: false,
      );
    }
    startProblemTimer();
  }

  void _trySwitchLevel(ScaffoldLevel newLevel) {
    if (isLevelUnlocked(newLevel.levelNumber)) {
      _setActiveLevel(newLevel);
    } else {
      _showLockedMessage(newLevel);
    }
  }

  void _showLevelUnlockedMessage(ScaffoldLevel level) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Level ${level.levelNumber} Unlocked: ${level.displayName}!',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLockedMessage(ScaffoldLevel level) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Level ${level.levelNumber} is locked. Complete previous levels first.',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Übung geschafft! 🏆'),
        content: const Text(
          'Du hast die Zahlen erfolgreich zerlegt!\nToll gemacht!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Belohnung abholen'),
          ),
        ],
      ),
    );
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
              // Level selector
              _buildLevelSelector(),
    
              // Divider
              const Divider(height: 1),
    
              // Current level content
              Expanded(
                child: _buildCurrentLevel(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _buildLevelTab(
            level: ScaffoldLevel.guidedExploration, // L1
            icon: Icons.touch_app,
            color: Colors.blue,
            isUnlocked: true,
          ),
          const SizedBox(width: 8),
          _buildLevelTab(
            level: ScaffoldLevel.supportedPractice, // L2
            icon: Icons.edit,
            color: Colors.purple,
            isUnlocked: isLevelUnlocked(2),
            progressText: '$_level2Correct/$_level2RequiredCorrect',
          ),
          const SizedBox(width: 8),
          _buildLevelTab(
            level: ScaffoldLevel.independentMastery, // L3
            icon: Icons.psychology,
            color: Colors.green,
            isUnlocked: isLevelUnlocked(3),
            progressText: '$_level3FoundCount/$_level3RequiredFound',
          ),
          const SizedBox(width: 8),
          _buildLevelTab(
            level: ScaffoldLevel.finale, // L4
            icon: Icons.star,
            color: Colors.indigo,
            isUnlocked: isLevelUnlocked(4),
            progressText: '$_level4Correct/$_level4RequiredCorrect',
          ),
        ],
      ),
    );
  }

  Widget _buildLevelTab({
    required ScaffoldLevel level,
    required IconData icon,
    required Color color,
    required bool isUnlocked,
    String? progressText,
  }) {
    final isActive = _currentLevel == level;

    return Expanded(
      child: GestureDetector(
        onTap: () => _trySwitchLevel(level),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive
                ? color.withOpacity(0.2)
                : (isUnlocked ? Colors.white : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? color : (isUnlocked ? Colors.grey.shade400 : Colors.grey.shade500),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isUnlocked ? icon : Icons.lock,
                    color: isUnlocked ? color : Colors.grey.shade600,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'L${level.levelNumber}',
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      fontSize: 10,
                      color: isUnlocked ? color : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (progressText != null && isUnlocked)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    progressText,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLevel() {
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        return Decompose10Level1Widget(
          onExplorationComplete: _onLevel1Complete,
        );

      case ScaffoldLevel.supportedPractice:
        return Decompose10Level2Widget(
          onAnswerSubmitted: _onLevel2Answer,
          correctAnswersNeeded: _level2RequiredCorrect,
          currentCorrectCount: _level2Correct,
        );

      case ScaffoldLevel.independentMastery:
        return Decompose10Level3Widget(
          onProgressUpdate: _onLevel3Progress,
        );

      case ScaffoldLevel.finale:
        return Decompose10Level4Widget(
          onAnswerSubmitted: _onLevel4Answer,
          correctAnswersNeeded: _level4RequiredCorrect,
          currentCorrectCount: _level4Correct,
        );
        
      default:
        return const Center(child: Text('Level noch nicht verfügbar'));
    }
  }
}