import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/countobjects_level1_widget_v2.dart';
import '../widgets/countobjects_level2_widget_v2.dart';
import '../widgets/countobjects_level3_widget_v2.dart';
import '../widgets/countobjects_level4_widget_v2.dart';
import '../widgets/common/segmented_progress_bar.dart';
import '../widgets/common/instruction_modal.dart';
import '../widgets/common/level_selection_drawer.dart';

/// Complete implementation of C1.2: Count the Objects exercise with 4-Level Scaffolding + Finale.
///
/// This exercise is a COPY of C1.1 structure but uses various object types instead of
/// uniform dots. This teaches that counting works with ANY objects (abstraction).
///
/// **iMINT Card 1: "Wie kommt die Handlung in den Kopf?"**
/// 1. Zuerst wird das gezählte Objekt zur Seite geschoben (push aside while counting)
/// 2. Später wird es beim lauten Zählen nur angetippt (tap/touch while counting)
/// 3. Der nächste Schritt ist das laute Abzählen ohne weitere äußere Handlung (count without action)
/// 4. Das Verfolgen der Zählhandlung mit den Augen und die Nennung des Ergebnisses (eyes only, then result)
///
/// **Level 1: Drag Objects (zur Seite schieben)**
/// - Drag each object (stars, hearts, shapes) to "counted" area
/// - Counter displays current count
/// - Learn one-to-one correspondence through physical action
/// - Structured layout (max 5 objects per row)
///
/// **Level 2: Tap Objects (antippen)**
/// - Tap objects (they mark as counted)
/// - Counter displays current count
/// - Reduced motor action, same concept
/// - Structured layout (max 5 objects per row)
///
/// **Level 3: No-Action Count (ohne Handlung)**
/// - Objects visible but no interaction (structured layout only)
/// - Child counts silently and enters result
/// - Mental counting with visual support
/// - Always structured layout (max 5 objects per row)
///
/// **Level 4: Eye-Tracking Count (mit den Augen)**
/// - Objects visible with random/scattered layout
/// - Child must count by tracking with eyes only
/// - Tests efficient eye-scanning patterns
/// - Always random layout (challenges eye-tracking)
///
/// **Level 5: Finale (Summary Level)**
/// - Easier mixed review after completing all card levels
/// - ADHD-friendly Easy→Hard→Easy flow
/// - Must be completable (see COMPLETION_CRITERIA.md)
///
/// **Pedagogical Goal:** Progressive reduction of support from physical to mental,
/// using various object types to teach abstraction
///
/// **Key Difference from C1.1:**
/// - Uses various object types (stars, hearts, shapes) instead of uniform dots
/// - Teaches abstraction: counting concept applies to all objects equally
///
/// Source: iMINT Green Card 1 (Gegenstände zählen / Count objects - same card as C1.1)
class CountObjectsExercise extends StatefulWidget {
  final ExerciseConfig config;
  final UserProfile userProfile;

  const CountObjectsExercise({
    super.key,
    required this.userProfile,
  }) : config = const ExerciseConfig(
          id: 'C1.2',
          title: 'Gegenstände zählen',
          skillTags: ['counting_1'],
          sourceCard: 'iMINT Green Card 1: Gegenstände zählen (4-level version + finale)',
          concept:
              'Understanding counting through one-to-one correspondence with various object types - teaches abstraction',
          observationPoints: [
            'Does child systematically count objects or work randomly?',
            'Can child count without physical action (Level 3)?',
            'Can child efficiently track and count with eyes only (Level 4)?',
            'Does object type affect counting accuracy or strategy?',
          ],
          internalizationPath:
              'L1 (Drag) → L2 (Tap) → L3 (Look-Structured) → L4 (Look-Random) → L5 (Finale)',
          targetNumber: 20,
          hints: [
            'Schiebe jeden Gegenstand einmal zur Seite, während du zählst.',
            'Tippe jeden Gegenstand einmal an — nicht doppelt zählen!',
            'Zähle die Gegenstände und gib dann die Zahl ein.',
            'Verfolge jeden Gegenstand mit den Augen — verpasse keinen!',
            'Zeig, was du kannst!',
          ],
        );

  @override
  State<CountObjectsExercise> createState() => _CountObjectsExerciseState();
}

class _CountObjectsExerciseState extends State<CountObjectsExercise>
    with ExerciseProgressMixin {
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration;

  // Progress tracking for segmented bar
  List<bool> _problemResults = []; // true = correct, false = incorrect
  int _currentProblemIndex = 0;
  static const int _problemsPerLevel = 10; // ALL levels have 10 problems (standard difficulty curve)

  // Level completion tracking (ephemeral, for unlock logic)
  int _level1ProblemsCompleted = 0;
  int _level2Correct = 0;
  int _level3Correct = 0;
  int _level4Correct = 0;

  // Unlock thresholds (minimum correct to unlock next level)
  static const int _level1RequiredProblems = 10; // All 10 problems
  static const int _level2RequiredCorrect = 8;   // 8/10 correct
  static const int _level3RequiredCorrect = 8;   // 8/10 correct
  static const int _level4RequiredCorrect = 8;   // 8/10 correct

  // ExerciseProgressMixin implementation
  @override
  String get exerciseId => widget.config.id;

  @override
  UserProfile get userProfile => widget.userProfile;

  @override
  int get totalLevels => 4;

  @override
  int get finaleLevelNumber => 4;

  @override
  int get problemTimeLimit => 20; // 20 seconds per problem for completion

  @override
  int get finaleMinProblems => 10;

  @override
  void initState() {
    super.initState();
    _initializeExercise();
  }

  Future<void> _initializeExercise() async {
    await initializeProgress();

    // Restore current level based on what's unlocked
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
    // Note: dispose is synchronous, we save in WillPopScope async callback
    super.dispose();
  }

  void _onLevel1Progress(int problemsSolved) {
    setState(() {
      _level1ProblemsCompleted = problemsSolved;

      // Update segmented bar (Level 1 doesn't track correct/incorrect, just completion)
      if (_problemResults.length < problemsSolved) {
        _problemResults.add(true); // Mark as correct (green)
        _currentProblemIndex = problemsSolved;
      }

      if (_level1ProblemsCompleted >= _level1RequiredProblems &&
          !isLevelUnlocked(2)) {
        unlockLevel(2);
        _showLevelUnlockedMessage('Level 2: Gegenstände antippen',
            'Tippe die Gegenstände an, statt sie zu schieben!');
        _autoAdvanceToNextLevel();
      }
    });
  }

  void _onLevel2ProgressUpdate(int correct, int total) {
    setState(() {
      // Update segmented bar
      if (_problemResults.length < total) {
        bool isCorrect = (total - _problemResults.length == 1 && correct > _level2Correct);
        _problemResults.add(isCorrect);
        _currentProblemIndex = total;
      }

      _level2Correct = correct;

      if (correct >= _level2RequiredCorrect && !isLevelUnlocked(3)) {
        unlockLevel(3);
        _showLevelUnlockedMessage('Level 3: Nur zählen',
            'Zähle ohne zu berühren — nur schauen und denken!');
        _autoAdvanceToNextLevel();
      }
    });
  }

  void _onLevel3ProgressUpdate(int correct, int total) {
    setState(() {
      // Update segmented bar
      if (_problemResults.length < total) {
        bool isCorrect = (total - _problemResults.length == 1 && correct > _level3Correct);
        _problemResults.add(isCorrect);
        _currentProblemIndex = total;
      }

      _level3Correct = correct;

      if (correct >= _level3RequiredCorrect && !isLevelUnlocked(4)) {
        unlockLevel(4);
        _showLevelUnlockedMessage('Level 4: Kurz zeigen',
            'Verfolge die Gegenstände mit den Augen!');
        _autoAdvanceToNextLevel();
      }
    });
  }

  void _onLevel4ProgressUpdate(int correct, int total) {
    setState(() {
      // Update segmented bar
      if (_problemResults.length < total) {
        bool isCorrect = (total - _problemResults.length == 1 && correct > _level4Correct);
        _problemResults.add(isCorrect);
        _currentProblemIndex = total;
      }

      _level4Correct = correct;

      // Level 4 is the final level in C1.2 - no more levels to unlock
    });
  }

  void _showLevelUnlockedMessage(String levelName, String description) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 $levelName freigeschaltet!\n$description'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _autoAdvanceToNextLevel() async {
    // Wait a moment for celebration
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      // Advance to next level
      final nextLevelNumber = _scaffoldLevelToInt(_currentLevel) + 1;
      if (nextLevelNumber <= 4 && isLevelUnlocked(nextLevelNumber)) {
        _currentLevel = _intToScaffoldLevel(nextLevelNumber);
        _problemResults = []; // Reset progress bar for new level
        _currentProblemIndex = 0;
      }
    });
  }

  void _onLevelSelected(ScaffoldLevel level) {
    int levelNumber = _scaffoldLevelToInt(level);

    if (isLevelUnlocked(levelNumber)) {
      setState(() {
        _currentLevel = level;
        _problemResults = []; // Reset progress bar for new level
        _currentProblemIndex = 0;
      });
    } else {
      String lockMessage = _getLockMessage(level);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lockMessage),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  int _scaffoldLevelToInt(ScaffoldLevel level) {
    switch (level) {
      case ScaffoldLevel.guidedExploration:
        return 1;
      case ScaffoldLevel.supportedPractice:
        return 2;
      case ScaffoldLevel.independentMastery:
        return 3;
      case ScaffoldLevel.advancedChallenge:
        return 4;
      case ScaffoldLevel.finale:
        return 5;
    }
  }

  ScaffoldLevel _intToScaffoldLevel(int levelNumber) {
    switch (levelNumber) {
      case 1:
        return ScaffoldLevel.guidedExploration;
      case 2:
        return ScaffoldLevel.supportedPractice;
      case 3:
        return ScaffoldLevel.independentMastery;
      case 4:
        return ScaffoldLevel.advancedChallenge;
      case 5:
        return ScaffoldLevel.finale;
      default:
        return ScaffoldLevel.guidedExploration;
    }
  }

  String _getLockMessage(ScaffoldLevel level) {
    switch (level) {
      case ScaffoldLevel.guidedExploration:
        return '';
      case ScaffoldLevel.supportedPractice:
        return 'Schließe zuerst $_level1RequiredProblems Aufgaben in Level 1 ab!';
      case ScaffoldLevel.independentMastery:
        return 'Du brauchst mindestens $_level2RequiredCorrect richtige in Level 2!';
      case ScaffoldLevel.advancedChallenge:
        return 'Du brauchst mindestens $_level3RequiredCorrect richtige in Level 3!';
      case ScaffoldLevel.finale:
        return 'Du brauchst mindestens $_level4RequiredCorrect richtige in Level 4!';
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
              // Action buttons row (replacing AppBar actions)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
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
    final levelNumber = _scaffoldLevelToInt(_currentLevel);
    InstructionModal.show(
      context,
      levelTitle: 'Level $levelNumber: ${_getLevelTitle(_currentLevel)}',
      instructionText: _getLevelInstructions(_currentLevel),
      levelColor: _getLevelColor(_currentLevel),
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
      case ScaffoldLevel.guidedExploration:
        return 'Gegenstände schieben';
      case ScaffoldLevel.supportedPractice:
        return 'Gegenstände antippen';
      case ScaffoldLevel.independentMastery:
        return 'Nur schauen';
      case ScaffoldLevel.advancedChallenge:
        return 'Kurz zeigen';
      case ScaffoldLevel.finale:
        return 'Nicht verwendet';
    }
  }

  String _getLevelInstructions(ScaffoldLevel level) {
    switch (level) {
      case ScaffoldLevel.guidedExploration:
        return 'Schiebe jeden Gegenstand in den „gezählt"-Bereich, während du laut zählst. So ordnest du jeden Gegenstand einem Zahlwort zu.';
      case ScaffoldLevel.supportedPractice:
        return 'Tippe jeden Gegenstand einmal an, während du zählst. Die Gegenstände werden als gezählt markiert. Nicht doppelt zählen!';
      case ScaffoldLevel.independentMastery:
        return 'Schau dir die Gegenstände an (ordentlich angeordnet) und zähle leise. Wenn du weißt, wie viele es sind, gib die Zahl ein.';
      case ScaffoldLevel.advancedChallenge:
        return 'Schau dir die wild verteilten Gegenstände an und zähle, indem du mit den Augen verfolgst. Teste dein Augen-Scanning!';
      case ScaffoldLevel.finale:
        return 'Nicht verwendet — diese Übung hat 4 Level.';
    }
  }

  Color _getLevelColor(ScaffoldLevel level) {
    switch (level) {
      case ScaffoldLevel.guidedExploration:
        return Colors.blue;
      case ScaffoldLevel.supportedPractice:
        return Colors.orange;
      case ScaffoldLevel.independentMastery:
        return Colors.purple;
      case ScaffoldLevel.advancedChallenge:
        return Colors.red;
      case ScaffoldLevel.finale:
        return Colors.green;
    }
  }

  Widget _buildCurrentLevelWidget() {
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        return CountObjectsLevel1WidgetV2(
          onProgressUpdate: _onLevel1Progress,
        );

      case ScaffoldLevel.supportedPractice:
        return CountObjectsLevel2WidgetV2(
          onProgressUpdate: _onLevel2ProgressUpdate,
        );

      case ScaffoldLevel.independentMastery:
        return CountObjectsLevel3Widget(
          onProgressUpdate: _onLevel3ProgressUpdate,
        );

      case ScaffoldLevel.advancedChallenge:
        return CountObjectsLevel4Widget(
          onProgressUpdate: _onLevel4ProgressUpdate,
        );

      case ScaffoldLevel.finale:
        // C1.2 has no finale level - only 4 card-prescribed levels (matching C1.1)
        return const Center(
          child: Text('Level 5 entfernt — C1.2 hat nur 4 Level'),
        );
    }
  }
}
