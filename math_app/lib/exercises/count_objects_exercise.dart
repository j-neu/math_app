import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/countobjects_level1_widget_v2.dart';
import '../widgets/countobjects_level2_widget_v2.dart';
import '../widgets/countobjects_level3_widget_v2.dart';
import '../widgets/countobjects_level4_widget_v2.dart';
import '../widgets/countobjects_level5_widget_v2.dart';

/// Complete implementation of C1.2: Count the Objects exercise with 5-Level Scaffolding.
///
/// This exercise follows the same iMINT Card 1 prescription as C1.1 but uses various
/// object types instead of uniform dots. This teaches that counting works with ANY objects.
///
/// **iMINT Card 1: "Wie kommt die Handlung in den Kopf?"**
/// 1. Zuerst wird das gezählte Objekt zur Seite geschoben (push aside while counting)
/// 2. Später wird es beim lauten Zählen nur angetippt (tap/touch while counting)
/// 3. Der nächste Schritt ist das laute Abzählen ohne weitere äußere Handlung (count without action)
/// 4. Das Verfolgen der Zählhandlung mit den Augen und die Nennung des Ergebnisses (eyes only, then result)
///
/// **CRITICAL DIFFERENCE FROM C1.1:** Child is NEVER shown the count during interaction.
/// They must count mentally and enter the number themselves at each level.
///
/// **Level 1: Drag Objects (zur Seite schieben)**
/// - Drag each object (stars, hearts, shapes) to "counted" area
/// - NO counter displayed (unlike C1.1)
/// - After dragging, child enters the total count
/// - Learn one-to-one correspondence without automatic feedback
///
/// **Level 2: Tap Objects (antippen)**
/// - Tap objects (they mark as counted)
/// - NO counter displayed
/// - Child must count mentally and enter result
/// - Reduced motor action, same concept
///
/// **Level 3: No-Action Count (ohne Handlung)**
/// - Objects visible but no interaction
/// - Child counts silently and enters result
/// - Mental counting with visual support
///
/// **Level 4: Flash-and-Memory (mit den Augen)**
/// - Objects flash briefly (2 seconds) then hide
/// - Child must remember pattern and count from memory
/// - Pure mental imagery and recall
///
/// **Level 5: Finale - Mixed Review**
/// - Easier than Level 4 (8-12 objects, structured layouts only)
/// - ADHD-friendly Easy→Hard→Easy flow
/// - Completion criteria: 10 problems, zero errors, <20s each
///
/// **Pedagogical Goal:** Learn that counting works with ANY objects (abstraction),
/// progressing from physical action to pure mental imagery
///
/// **Difference from C1.1:**
/// - Uses various object types (stars, hearts, apples, etc.) instead of uniform dots
/// - Child never sees automatic count feedback - must count independently
/// - Teaches abstraction: counting concept applies to all objects equally
///
/// Source: iMINT Green Card 1 (Gegenstände zählen / Count objects)
class CountObjectsExercise extends StatefulWidget {
  final ExerciseConfig config;
  final UserProfile userProfile;

  const CountObjectsExercise({
    super.key,
    required this.userProfile,
  }) : config = const ExerciseConfig(
          id: 'C1.2',
          title: 'Count the Objects',
          skillTags: ['counting_1'],
          sourceCard: 'iMINT Green Card 1: Gegenstände zählen (5-level version)',
          concept:
              'Understanding that counting applies to any objects - abstraction of one-to-one correspondence',
          observationPoints: [
            'Does child recognize that counting works the same for different objects?',
            'Can child count diverse visual representations equally well?',
            'Does object type affect counting accuracy?',
          ],
          internalizationPath:
              'L1 (Drag) → L2 (Tap) → L3 (Look) → L4 (Flash) → L5 (Finale)',
          targetNumber: 12, // Max objects in finale level
          hints: [
            'Drag each object once as you count.',
            'Tap each object once - no double counting!',
            'Count the objects you see, then enter the number.',
            'Try to remember the pattern - close your eyes and picture it!',
            'You\'ve got this! Show your mastery!',
          ],
        );

  @override
  State<CountObjectsExercise> createState() => _CountObjectsExerciseState();
}

class _CountObjectsExerciseState extends State<CountObjectsExercise>
    with ExerciseProgressMixin {
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration;

  // Level completion tracking (ephemeral, for unlock logic)
  int _level1ProblemsCompleted = 0;
  int _level2Correct = 0;
  int _level3Correct = 0;
  int _level4Correct = 0;

  // Unlock thresholds
  static const int _level1RequiredProblems = 3;
  static const int _level2RequiredCorrect = 8;
  static const int _level3RequiredCorrect = 10;
  static const int _level4RequiredCorrect = 10;

  // ExerciseProgressMixin implementation
  @override
  String get exerciseId => widget.config.id;

  @override
  UserProfile get userProfile => widget.userProfile;

  @override
  int get totalLevels => 5;

  @override
  int get finaleLevelNumber => 5;

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
      if (isLevelUnlocked(5)) {
        _currentLevel = ScaffoldLevel.finale;
      } else if (isLevelUnlocked(4)) {
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

      if (_level1ProblemsCompleted >= _level1RequiredProblems &&
          !isLevelUnlocked(2)) {
        unlockLevel(2);
        _showLevelUnlockedMessage('Level 2: Tap Objects',
            'Tap objects instead of dragging them!');
      }
    });
  }

  void _onLevel2ProgressUpdate(int correct, int total) {
    setState(() {
      _level2Correct = correct;

      if (correct >= _level2RequiredCorrect && !isLevelUnlocked(3)) {
        unlockLevel(3);
        _showLevelUnlockedMessage('Level 3: No-Action Count',
            'Count without touching - just look and think!');
      }
    });
  }

  void _onLevel3ProgressUpdate(int correct, int total) {
    setState(() {
      _level3Correct = correct;

      if (correct >= _level3RequiredCorrect && !isLevelUnlocked(4)) {
        unlockLevel(4);
        _showLevelUnlockedMessage('Level 4: Flash & Memory',
            'The ultimate challenge - count from memory!');
      }
    });
  }

  void _onLevel4ProgressUpdate(int correct) {
    setState(() {
      _level4Correct = correct;

      if (correct >= _level4RequiredCorrect && !isLevelUnlocked(5)) {
        unlockLevel(5);
        _showLevelUnlockedMessage('Level 5: Finale - Show Your Mastery!',
            'Time for a victory lap! 🎉');
      }
    });
  }

  void _showLevelUnlockedMessage(String levelName, String description) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 $levelName Unlocked!\n$description'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onLevelSelected(ScaffoldLevel level) {
    int levelNumber = _scaffoldLevelToInt(level);

    if (isLevelUnlocked(levelNumber)) {
      setState(() {
        _currentLevel = level;
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

  String _getLockMessage(ScaffoldLevel level) {
    switch (level) {
      case ScaffoldLevel.guidedExploration:
        return '';
      case ScaffoldLevel.supportedPractice:
        return 'Complete $_level1RequiredProblems problems in Level 1 first!';
      case ScaffoldLevel.independentMastery:
        return 'Get $_level2RequiredCorrect correct in Level 2 first!';
      case ScaffoldLevel.advancedChallenge:
        return 'Get $_level3RequiredCorrect correct in Level 3 first!';
      case ScaffoldLevel.finale:
        return 'Get $_level4RequiredCorrect correct in Level 4 first!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await onExerciseExit();
        return true;
      },
      child: Column(
        children: [
          // Level selector
          _buildLevelSelector(),

          // Progress indicator
          _buildLevelProgressIndicator(),

          // Current level widget
          Expanded(
            child: _buildCurrentLevelWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLevelButton(
            level: ScaffoldLevel.guidedExploration,
            label: 'L1\nDrag',
            color: Colors.blue,
          ),
          _buildLevelButton(
            level: ScaffoldLevel.supportedPractice,
            label: 'L2\nTap',
            color: Colors.orange,
          ),
          _buildLevelButton(
            level: ScaffoldLevel.independentMastery,
            label: 'L3\nLook',
            color: Colors.purple,
          ),
          _buildLevelButton(
            level: ScaffoldLevel.advancedChallenge,
            label: 'L4\nFlash',
            color: Colors.red,
          ),
          _buildLevelButton(
            level: ScaffoldLevel.finale,
            label: 'L5\nFinale',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelButton({
    required ScaffoldLevel level,
    required String label,
    required Color color,
  }) {
    int levelNumber = _scaffoldLevelToInt(level);
    bool isUnlocked = isLevelUnlocked(levelNumber);
    bool isActive = _currentLevel == level;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: ElevatedButton(
          onPressed: isUnlocked ? () => _onLevelSelected(level) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? color : Colors.grey.shade300,
            foregroundColor: isActive ? Colors.white : Colors.grey.shade600,
            padding: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: isActive
                  ? BorderSide(color: color, width: 2)
                  : BorderSide.none,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isUnlocked) const Icon(Icons.lock, size: 14),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelProgressIndicator() {
    String progressText = '';
    double progressValue = 0.0;
    Color progressColor = Colors.blue;

    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        progressText =
            'Problems completed: $_level1ProblemsCompleted/$_level1RequiredProblems';
        progressValue = _level1ProblemsCompleted / _level1RequiredProblems;
        progressColor = Colors.blue;
        break;
      case ScaffoldLevel.supportedPractice:
        progressText =
            'Correct: $_level2Correct/$_level2RequiredCorrect to unlock Level 3';
        progressValue = _level2Correct / _level2RequiredCorrect;
        progressColor = Colors.orange;
        break;
      case ScaffoldLevel.independentMastery:
        progressText =
            'Correct: $_level3Correct/$_level3RequiredCorrect to unlock Level 4';
        progressValue = _level3Correct / _level3RequiredCorrect;
        progressColor = Colors.purple;
        break;
      case ScaffoldLevel.advancedChallenge:
        progressText =
            'Correct: $_level4Correct/$_level4RequiredCorrect to unlock Finale';
        progressValue = _level4Correct / _level4RequiredCorrect;
        progressColor = Colors.red;
        break;
      case ScaffoldLevel.finale:
        progressText = 'Finale Level - Show your mastery!';
        progressValue = 1.0;
        progressColor = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: progressColor.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            progressText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: progressColor,
            ),
          ),
          if (_currentLevel != ScaffoldLevel.finale) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
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
        return CountObjectsLevel5Widget(
          onStartProblemTimer: startProblemTimer,
          onProblemComplete: (correct, userAnswer) async {
            await recordProblemResult(
              levelNumber: 5,
              correct: correct,
              userAnswer: userAnswer,
            );
          },
          onLevelComplete: () {
            // Level 5 completed! Save progress and notify user
            saveProgress();
          },
        );
    }
  }
}
