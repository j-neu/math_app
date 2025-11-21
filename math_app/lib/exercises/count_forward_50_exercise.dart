import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/countforward50_level1_widget.dart';
import '../widgets/countforward50_level2_widget.dart';
import '../widgets/countforward50_level3_widget.dart';
import '../widgets/countforward50_level4_widget.dart';

/// Complete implementation of C3.2: Count Forward to 50 exercise with Card-Based Scaffolding.
///
/// This exercise follows the framework documented in IMINT_TO_APP_FRAMEWORK.md
/// to properly answer "Wie kommt die Handlung in den Kopf?" (How does action become mental?)
///
/// **Source:** iMINT Arbeitskarte 3: "Zählen am Zahlenband bis 100" (Pages 77-78)
/// **Note:** This is the 1-50 range version. See C3.1 (1-20) and C3.3 (1-100) for other ranges.
///
/// **Level 1: Tap Sequence (Activity B)**
/// - Tap numbers in sequence on visible band (1-50)
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
/// **Pedagogical Goal:** Internalize counting sequence 1-50 through
/// progressive scaffolding: Tap → Identify → Fill → Practice
///
/// **Skills:** counting_3 (forward/backward counting on number band)
class CountForward50Exercise extends StatefulWidget {
  final ExerciseConfig config;
  final UserProfile userProfile;

  const CountForward50Exercise({
    super.key,
    required this.userProfile,
  }) : config = const ExerciseConfig(
          id: 'C3.2',
          title: 'Count Forward to 50',
          skillTags: ['counting_3'],
          sourceCard: 'iMINT Arbeitskarte 3: Zählen am Zahlenband bis 100 (Pages 77-78) - Adapted for 1-50 range',
          concept:
              'Understanding the number sequence 1-50: recognizing patterns, '
              'counting forward and backward fluently, internalizing the sequence',
          observationPoints: [
            'Can child tap numbers in sequence without specific prompts?',
            'Can child identify covered numbers mentally (Level 2)?',
            'Can child fill in missing numbers in a sequence (Level 3)?',
            'Is counting automatic or does child still need to "figure it out"?',
            'Can child count mentally without copying visible answers?',
          ],
          internalizationPath:
              'Level 1 (Tap sequence) → Level 2 (Identify covered number) → '
              'Level 3 (Fill missing numbers) → Level 4 (Finale consolidation)',
          targetNumber: 50, // Count up to 20
          hints: [
            'The ones-digit counts up: 1,2,3...9, then starts again at 11,12,13...',
            'After 9 comes 10, after 19 comes 20',
            'Count in your head - what comes next?',
            'If you get stuck, try counting from 1',
          ],
        );

  @override
  State<CountForward50Exercise> createState() => _CountForward50ExerciseState();
}

class _CountForward50ExerciseState extends State<CountForward50Exercise>
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
                '${level.displayName} unlocked!',
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
        lockMessage = 'Complete Level 1 first!';
        break;
      case ScaffoldLevel.independentMastery:
        isUnlocked = _progress.level3Unlocked;
        lockMessage =
            'Complete Level 2 first!';
        break;
      case ScaffoldLevel.advancedChallenge:
        isUnlocked = false;
        lockMessage = 'Not available for this exercise';
        break;
      case ScaffoldLevel.finale:
        isUnlocked = _progress.level4Unlocked;
        lockMessage = 'Complete Level 3 first!';
        break;
    }

    if (isUnlocked) {
      setState(() {
        _progress = _progress.copyWith(currentLevel: level);
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Column(
        children: [
          // Level selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildLevelButton(
                    ScaffoldLevel.guidedExploration,
                    'Level 1',
                    Colors.blue,
                    Icons.touch_app,
                    true, // Always unlocked
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildLevelButton(
                    ScaffoldLevel.supportedPractice,
                    'Level 2',
                    Colors.orange,
                    Icons.create,
                    _progress.level2Unlocked,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildLevelButton(
                    ScaffoldLevel.independentMastery,
                    'Level 3',
                    Colors.purple,
                    Icons.psychology,
                    _progress.level3Unlocked,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildLevelButton(
                    ScaffoldLevel.finale,
                    'Finale',
                    Colors.green,
                    Icons.celebration,
                    _progress.level4Unlocked,
                  ),
                ),
              ],
            ),
          ),

          // Progress indicator for current level
          _buildLevelProgressIndicator(),

          // Current level content
          Expanded(
            child: _buildCurrentLevelWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelButton(
    ScaffoldLevel level,
    String label,
    Color color,
    IconData icon,
    bool isUnlocked,
  ) {
    final bool isActive = _progress.currentLevel == level;

    return GestureDetector(
      onTap: () => _onLevelSelected(level),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isUnlocked ? icon : Icons.lock,
              color: isActive ? Colors.white : (isUnlocked ? color : Colors.grey),
              size: 14,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : (isUnlocked ? color : Colors.grey),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelProgressIndicator() {
    String progressText = '';
    double progressValue = 0.0;
    Color progressColor = Colors.blue;

    switch (_progress.currentLevel) {
      case ScaffoldLevel.guidedExploration:
        progressText = 'Explore the number line - hop forward and backward!';
        progressValue = 0.0;
        progressColor = Colors.blue;
        break;
      case ScaffoldLevel.supportedPractice:
        progressText = 'Level 2: Walking Marker - Practice counting!';
        progressValue = 0.5;
        progressColor = Colors.orange;
        break;
      case ScaffoldLevel.independentMastery:
        progressText = 'Level 3: Mental Counting - Test your memory!';
        progressValue = 1.0;
        progressColor = Colors.purple;
        break;
      case ScaffoldLevel.advancedChallenge:
        progressText = '';
        progressValue = 0.0;
        progressColor = Colors.grey;
        break;
      case ScaffoldLevel.finale:
        progressText = 'Finale: Final review!';
        progressValue = 1.0;
        progressColor = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: progressColor.withOpacity(0.1),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  progressText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: progressColor.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          if (_progress.currentLevel == ScaffoldLevel.supportedPractice) ...[
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
    switch (_progress.currentLevel) {
      case ScaffoldLevel.guidedExploration:
        return CountForwardLevel1Widget(
          onProblemComplete: (correct) {
            recordProblemResult(correct: correct, levelNumber: 1);
          },
          onLevelComplete: _onLevel1Complete,
        );

      case ScaffoldLevel.supportedPractice:
        return CountForwardLevel2Widget(
          onProblemComplete: (correct) {
            recordProblemResult(correct: correct, levelNumber: 2);
          },
          onLevelComplete: _onLevel2Complete,
        );

      case ScaffoldLevel.independentMastery:
        return CountForwardLevel3Widget(
          onProblemComplete: (correct) {
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
            // Already recorded via recordProblemResult
          },
          onLevelComplete: () {
            // Mark exercise as completed
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Congratulations! You\'ve completed counting to 100!'),
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
