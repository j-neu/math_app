import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/countforward_level1_widget.dart';
import '../widgets/countforward_level2_widget.dart';
import '../widgets/countforward_level3_widget.dart';
import '../widgets/countforward_level4_widget.dart';
import '../widgets/common/instruction_modal.dart';
import '../widgets/common/level_selection_drawer.dart';
import '../widgets/common/segmented_progress_bar.dart';

/// Complete implementation of C3.1: Count Forward to 20 exercise with Card-Based Scaffolding.
///
/// This exercise follows the framework documented in IMINT_TO_APP_FRAMEWORK.md
/// to properly answer "Wie kommt die Handlung in den Kopf?" (How does action become mental?)
///
/// **Source:** iMINT Arbeitskarte 3: "Zählen am Zahlenband bis 100" (Pages 77-78)
/// **Note:** This is the 1-20 range version. See C3.2 (1-50) and C3.3 (1-100) for extended ranges.
///
/// **Level 1: Tap Sequence (Activity B)**
/// - Tap numbers in sequence on visible band (1-20)
/// - Full visual support, SEE the sequence
/// - Generic feedback ("Keep going!"), minimal hand-holding
/// - Purpose: Recognize sequence patterns
///
/// **Level 2: Identify Covered Number (Activity C)**
/// - Marker covers current number
/// - Child must ENTER the number covered by marker
/// - Text input required (no "Next" button)
/// - Purpose: Mental work, think before seeing answer
///
/// **Level 3: Fill Sequence (Activity D)**
/// - Show first 2 and last 2 numbers only
/// - Child fills in middle numbers (3-8 blanks)
/// - Multiple text fields, prevents answer copying
/// - Purpose: Complete internalization, no visual reference
///
/// **Level 4: Finale (ADHD-Friendly Victory Lap)**
/// - Count to 20 with band VISIBLE (easier than L3)
/// - Both directions, 5-8 step sequences
/// - Confidence-building completion level
///
/// **COMPLETION CRITERIA (Level 4 Finale):**
/// - Minimum problems: 10
/// - Accuracy required: 100% (zero errors in last 10 problems)
/// - Time limit: 30 seconds per problem
/// - Status: "finished" → "completed" when all criteria met
///
/// **State Persistence:**
/// - Progress saves every 5 problems via ExerciseProgressMixin
/// - Progress saves on exit (dispose)
/// - Level unlocks persist across app restarts
/// - Child can exit and resume from same point
///
/// **Pedagogical Goal:** Internalize counting sequence 1-20 through
/// progressive scaffolding: Tap → Identify → Fill → Practice
///
/// **Skills:** counting_3 (forward/backward counting on number band)
class CountForwardExercise extends StatefulWidget {
  final ExerciseConfig config;
  final UserProfile userProfile;

  const CountForwardExercise({
    super.key,
    required this.userProfile,
  }) : config = const ExerciseConfig(
          id: 'C3.1',
          title: 'Zähl vorwärts bis 20',
          skillTags: ['counting_3'],
          sourceCard: 'iMINT Arbeitskarte 3: Zählen am Zahlenband bis 100 (Pages 77-78) - Adapted for 1-20 range',
          concept:
              'Understanding the number sequence 1-20: recognizing patterns, '
              'counting forward and backward fluently, internalizing the sequence',
          observationPoints: [
            'Does child tap numbers in sequence without specific prompts?',
            'Can child identify covered numbers mentally (Level 2)?',
            'Can child fill in missing numbers in a sequence (Level 3)?',
            'Is counting automatic or does child still need to "figure it out"?',
            'Can child count mentally without copying visible answers?',
          ],
          internalizationPath:
              'Level 1 (Tap sequence) → Level 2 (Identify covered number) → '
              'Level 3 (Fill missing numbers) → Level 4 (Finale consolidation)',
          targetNumber: 20,
          hints: [
            'Die Einerziffer zählt hoch: 1, 2, 3 … 9, dann geht es weiter mit 11, 12, 13 …',
            'Nach der 9 kommt die 10, nach der 19 kommt die 20.',
            'Zähle im Kopf — was kommt als Nächstes?',
            'Wenn du nicht weiter weißt, fang von vorne an zu zählen.',
          ],
        );

  @override
  State<CountForwardExercise> createState() => _CountForwardExerciseState();
}

class _CountForwardExerciseState extends State<CountForwardExercise>
    with ExerciseProgressMixin {
  // Mixin requirements
  @override
  String get exerciseId => widget.config.id;

  @override
  UserProfile get userProfile => widget.userProfile;

  @override
  int get totalLevels => 4; // 3 card levels + 1 finale

  @override
  int get finaleLevelNumber => 4;

  @override
  int get problemTimeLimit => 30; // 30 seconds per problem

  @override
  int get finaleMinProblems => 10;

  // UI state
  ScaffoldProgress _progress = const ScaffoldProgress();

  // Progress bar tracking
  List<bool> _currentLevelResults = [];
  int _currentLevelTotalProblems = 10; // Default, updated per level

  @override
  void initState() {
    super.initState();
    _initializeExercise();
  }

  Future<void> _initializeExercise() async {
    await initializeProgress();

    // Restore unlocked levels from saved progress
    setState(() {
      if (isLevelUnlocked(2)) {
        _progress = _progress.copyWith(level1Complete: true);
      }
      if (isLevelUnlocked(3)) {
        _progress = _progress.copyWith(level1Complete: true, level3Unlocked: true);
      }
      if (isLevelUnlocked(4)) {
        _progress = _progress.copyWith(level1Complete: true, level3Unlocked: true, level4Unlocked: true);
      }

      // Initialize progress bar for current level
      _currentLevelTotalProblems = _getProblemsForLevel(_progress.currentLevel);
    });
  }

  @override
  void dispose() {
    saveProgress();
    super.dispose();
  }

  void _onLevel1Complete() {
    unlockLevel(2);
    setState(() {
      _progress = _progress.copyWith(
        level1Complete: true,
        currentLevel: ScaffoldLevel.supportedPractice,
      );
      // Reset progress bar for new level
      _currentLevelResults = [];
      _currentLevelTotalProblems = _getProblemsForLevel(ScaffoldLevel.supportedPractice);
    });

    _showLevelUnlockedMessage(ScaffoldLevel.supportedPractice);
  }

  void _onLevel2Complete() {
    unlockLevel(3);
    setState(() {
      _progress = _progress.copyWith(
        level3Unlocked: true,
        currentLevel: ScaffoldLevel.independentMastery,
      );
      // Reset progress bar for new level
      _currentLevelResults = [];
      _currentLevelTotalProblems = _getProblemsForLevel(ScaffoldLevel.independentMastery);
    });

    _showLevelUnlockedMessage(ScaffoldLevel.independentMastery);
  }

  void _onLevel3Complete() {
    unlockLevel(4);
    setState(() {
      _progress = _progress.copyWith(
        level4Unlocked: true,
        currentLevel: ScaffoldLevel.finale,
      );
      // Reset progress bar for new level
      _currentLevelResults = [];
      _currentLevelTotalProblems = _getProblemsForLevel(ScaffoldLevel.finale);
    });

    _showLevelUnlockedMessage(ScaffoldLevel.finale);
  }

  void _showLevelUnlockedMessage(ScaffoldLevel level) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_open, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${level.displayName} freigeschaltet!',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onLevelSelected(ScaffoldLevel level) {
    // Check if level is unlocked
    bool isUnlocked = false;
    String lockMessage = '';

    switch (level) {
      case ScaffoldLevel.guidedExploration:
        isUnlocked = true; // Always unlocked
        break;
      case ScaffoldLevel.supportedPractice:
        isUnlocked = _progress.level2Unlocked;
        lockMessage = 'Schließe zuerst Level 1 ab!';
        break;
      case ScaffoldLevel.independentMastery:
        isUnlocked = _progress.level3Unlocked;
        lockMessage =
            'Schließe zuerst Level 2 ab!';
        break;
      case ScaffoldLevel.advancedChallenge:
        isUnlocked = false;
        lockMessage = 'Nicht verfügbar für diese Übung';
        break;
      case ScaffoldLevel.finale:
        isUnlocked = _progress.level4Unlocked;
        lockMessage = 'Schließe zuerst Level 3 ab!';
        break;
    }

    if (isUnlocked) {
      setState(() {
        _progress = _progress.copyWith(currentLevel: level);
        _currentLevelResults = []; // Reset progress bar for new level
        _currentLevelTotalProblems = _getProblemsForLevel(level);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(lockMessage)),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  int _getProblemsForLevel(ScaffoldLevel level) {
    switch (level) {
      case ScaffoldLevel.guidedExploration:
        return 5; // Level 1
      case ScaffoldLevel.supportedPractice:
        return 12; // Level 2
      case ScaffoldLevel.independentMastery:
        return 8; // Level 3
      case ScaffoldLevel.finale:
        return 10; // Level 4
      default:
        return 10;
    }
  }

  void _onProblemComplete(bool correct) {
    setState(() {
      _currentLevelResults.add(correct);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await saveProgress();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.config.title),
          actions: [
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
        body: Column(
          children: [
            // Segmented Progress Bar
            SegmentedProgressBar(
              totalSegments: _currentLevelTotalProblems,
              currentSegment: _currentLevelResults.length,
              results: _currentLevelResults,
            ),
            // Level content
            Expanded(
              child: _buildCurrentLevelWidget(),
            ),
          ],
        ),
      ),
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
          ScaffoldLevel.finale,
        ],
        currentLevel: _progress.currentLevel,
        onLevelSelected: _onLevelSelected,
        isLevelUnlocked: (level) {
          switch (level) {
            case ScaffoldLevel.guidedExploration:
              return true;
            case ScaffoldLevel.supportedPractice:
              return _progress.level2Unlocked;
            case ScaffoldLevel.independentMastery:
              return _progress.level3Unlocked;
            case ScaffoldLevel.finale:
              return _progress.level4Unlocked;
            case ScaffoldLevel.advancedChallenge:
              return false;
          }
        },
      ),
    );
  }

  void _showInstructions() {
    String levelTitle = '';
    String instructionText = '';

    switch (_progress.currentLevel) {
      case ScaffoldLevel.guidedExploration:
        levelTitle = 'Level 1: Vorwärts zählen';
        instructionText = 'Tippe die Zahlen in der richtigen Reihenfolge und sage sie laut! '
            'Das Zahlenband hilft dir, das Muster zu sehen. '
            'Beachte: Die 10 und die 20 sind hervorgehoben — das sind Zehnerzahlen!';
        break;
      case ScaffoldLevel.supportedPractice:
        levelTitle = 'Level 2: Wandernde Markierung';
        instructionText = 'Zähle vorwärts oder rückwärts! Die Markierung verdeckt die aktuelle Zahl (als ?). '
            'Du musst DENKEN, welche Zahl drunter steht, bevor du deine Antwort eingibst.';
        break;
      case ScaffoldLevel.independentMastery:
        levelTitle = 'Level 3: Im Kopf zählen';
        instructionText = 'Fülle die fehlenden Zahlen aus! Du siehst die ersten 2 und die letzten 2 Zahlen. '
            'Zähle im Kopf, um die mittleren Zahlen herauszufinden.';
        break;
      case ScaffoldLevel.finale:
        levelTitle = 'Level 4: Finale';
        instructionText = 'Übe das Vorwärts- und Rückwärtszählen bis 20! '
            'Das ist das Finale — das Zahlenband ist sichtbar, damit du Erfolg hast. '
            'Die Aufgaben sind kürzer als in Level 3.';
        break;
      case ScaffoldLevel.advancedChallenge:
        levelTitle = 'Nicht verfügbar';
        instructionText = '';
        break;
    }

    InstructionModal.show(
      context,
      levelTitle: levelTitle,
      instructionText: instructionText,
    );
  }


  Widget _buildCurrentLevelWidget() {
    switch (_progress.currentLevel) {
      case ScaffoldLevel.guidedExploration:
        return CountForwardLevel1Widget(
          onProblemComplete: (correct) {
            _onProblemComplete(correct);
            recordProblemResult(correct: correct, levelNumber: 1);
          },
          onLevelComplete: _onLevel1Complete,
        );

      case ScaffoldLevel.supportedPractice:
        return CountForwardLevel2Widget(
          onProblemComplete: (correct) {
            _onProblemComplete(correct);
            recordProblemResult(correct: correct, levelNumber: 2);
          },
          onLevelComplete: _onLevel2Complete,
        );

      case ScaffoldLevel.independentMastery:
        return CountForwardLevel3Widget(
          onProblemComplete: (correct) {
            _onProblemComplete(correct);
            recordProblemResult(correct: correct, levelNumber: 3);
          },
          onLevelComplete: _onLevel3Complete,
        );

      case ScaffoldLevel.advancedChallenge:
        return const SizedBox.shrink();

      case ScaffoldLevel.finale:
        return CountForwardLevel4Widget(
          startProblemTimer: startProblemTimer,
          recordProblemResult: (correct) {
            recordProblemResult(correct: correct, levelNumber: 4);
          },
          onProblemComplete: (correct) {
            _onProblemComplete(correct);
          },
          onLevelComplete: () {
            // Mark exercise as completed
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Toll gemacht! Du kannst jetzt bis 20 zählen!'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          },
        );
    }
  }
}
