import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/findneighbors_level1_widget.dart';
import '../widgets/findneighbors_level2_widget.dart';
import '../widgets/findneighbors_level3_widget.dart';
import '../widgets/findneighbors_level4_widget.dart';

/// Complete implementation of C5.1: Find Neighboring Numbers (Card Game) exercise with Card-Based Scaffolding.
///
/// This exercise follows the framework documented in IMINT_TO_APP_FRAMEWORK.md
/// to properly answer "Wie kommt die Handlung in den Kopf?" (How does action become mental?)
///
/// **Source:** iMINT Arbeitskarte 5: "Nachbarzahlen finden (Spiel: 'Die grüne 50')" (Pages 81-82)
///
/// **Concept:** A digital version of the card game "Die grüne 50" (similar to "Elfer raus").
/// Children place numbered cards in ascending/descending sequence by dragging and dropping them
/// onto a scrollable game board. This playful approach consolidates understanding of neighboring
/// numbers and number sequence patterns.
///
/// **Pedagogical Context:** This is a CONSOLIDATION activity, not initial instruction.
/// It assumes children have already explored neighboring numbers via C4.1 (What Comes Next?).
/// The card game provides playful practice to internalize number sequences.
///
/// **Level 1: Learn the Rules (Range 40-50)**
/// - Goal: Place 5 cards correctly
/// - All generated cards are valid (can always be placed)
/// - Visual support: Anchor cards visible (e.g., 38-40-42)
/// - Purpose: Learn drag-and-drop mechanics, understand sequence building
///
/// **Level 2: Strategic Thinking (Range 50-70)**
/// - Goal: Place 10 cards correctly
/// - Some cards must be skipped (don't fit in current sequence)
/// - Subtle hints if valid card skipped multiple times
/// - Purpose: Develop strategic decision-making about neighboring numbers
///
/// **Level 3: Master the Game (Range 30-90)**
/// - Goal: Place 20 cards correctly
/// - More cards must be skipped, faster pace
/// - Full independence, minimal hints
/// - Purpose: Fluent neighboring number recognition across wider range
///
/// **Level 4: Finale (ADHD-Friendly Victory Lap)**
/// - Goal: Place 10 cards correctly (easier than L3)
/// - Range: 40-60 (narrower, familiar)
/// - All cards valid (no skipping needed)
/// - Confidence-building completion level
///
/// **GAME MECHANICS:**
/// - Random starting anchor (40, 50, 60, 70, or 80)
/// - 3 anchor cards placed vertically (anchor-2, anchor, anchor+2)
/// - Child drags cards from pickup area to slots on scrollable board
/// - Correct placement: Card locks in, stays on board
/// - Incorrect placement: Card bounces back with shake animation
/// - Skip card: Returns to pool, can reappear later
/// - Next card: Generates new random card from valid range
///
/// **COMPLETION CRITERIA (Level 4 Finale):**
/// - Minimum problems: 10 (10 correct card placements)
/// - Accuracy required: 100% (zero errors in last 10 problems)
/// - Time limit: 30 seconds per card placement
/// - Status: "finished" → "completed" when all criteria met
///
/// **State Persistence:**
/// - Progress saves every 5 problems via ExerciseProgressMixin
/// - Progress saves on exit (dispose)
/// - Level unlocks persist across app restarts
/// - Game board state (placed cards) persists during session
/// - Child can exit and resume from same point
///
/// **Pedagogical Goal:** Consolidate neighboring number knowledge through
/// playful card game: Rules → Strategy → Mastery → Celebrate
///
/// **Skills:** counting_5 (neighboring numbers - game-based practice)
class FindNeighborsExercise extends StatefulWidget {
  final ExerciseConfig config;
  final UserProfile userProfile;

  const FindNeighborsExercise({
    super.key,
    required this.userProfile,
  }) : config = const ExerciseConfig(
          id: 'C5.1',
          title: 'Find Neighboring Numbers',
          skillTags: ['counting_5'],
          sourceCard: 'iMINT Arbeitskarte 5: Nachbarzahlen finden (Spiel: "Die grüne 50") (Pages 81-82)',
          concept:
              'Consolidate understanding of neighboring numbers through a playful card game. '
              'Children place cards in sequence, developing fluency with ascending/descending number patterns.',
          observationPoints: [
            'Can child identify which numbers can be placed next to existing cards?',
            'Does child recognize when a card cannot be placed (needs to be skipped)?',
            'Is decision-making quick or does child need to count/calculate?',
            'Can child extend sequences in both directions (ascending and descending)?',
            'Does child use strategic thinking (skip now, place later)?',
          ],
          internalizationPath:
              'Level 1 (Learn rules, all cards valid) → Level 2 (Strategic skipping, 50-70) → '
              'Level 3 (Master game, 30-90) → Level 4 (Finale celebration)',
          targetNumber: 90, // Up to 90 in Level 3
          hints: [
            'Neighboring numbers are right next to each other: 40-41-42',
            'Look at the last card in each row - what comes next?',
            'If a card doesn\'t fit now, skip it and try the next one',
            'Cards can go in both directions: 39←40→41',
          ],
        );

  @override
  State<FindNeighborsExercise> createState() => _FindNeighborsExerciseState();
}

class _FindNeighborsExerciseState extends State<FindNeighborsExercise>
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
  int get problemTimeLimit => 30; // 30 seconds per card placement

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
        lockMessage = 'Complete Level 2 first!';
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
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          saveProgress();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.config.title),
          backgroundColor: Colors.green,
        ),
        body: Column(
          children: [
            // Level selection header
            _buildLevelSelector(),

            // Current level widget
            Expanded(
              child: _buildCurrentLevelWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.green.shade200, width: 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLevelButton(
            level: ScaffoldLevel.guidedExploration,
            label: 'L1',
            isUnlocked: true,
          ),
          _buildLevelButton(
            level: ScaffoldLevel.supportedPractice,
            label: 'L2',
            isUnlocked: _progress.level2Unlocked,
          ),
          _buildLevelButton(
            level: ScaffoldLevel.independentMastery,
            label: 'L3',
            isUnlocked: _progress.level3Unlocked,
          ),
          _buildLevelButton(
            level: ScaffoldLevel.finale,
            label: 'Finale',
            isUnlocked: _progress.level4Unlocked,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelButton({
    required ScaffoldLevel level,
    required String label,
    required bool isUnlocked,
  }) {
    final bool isSelected = _progress.currentLevel == level;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: isUnlocked ? () => _onLevelSelected(level) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.green : Colors.white,
            foregroundColor: isSelected ? Colors.white : Colors.green.shade700,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected ? Colors.green.shade700 : Colors.green.shade300,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isUnlocked)
                const Icon(Icons.lock, size: 16)
              else
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLevelWidget() {
    switch (_progress.currentLevel) {
      case ScaffoldLevel.guidedExploration:
        return FindNeighborsLevel1Widget(
          onComplete: _onLevel1Complete,
          onStartProblemTimer: startProblemTimer,
          onProblemComplete: (correct, answer) {
            recordProblemResult(
              levelNumber: 1,
              correct: correct,
              userAnswer: answer,
            );
          },
        );

      case ScaffoldLevel.supportedPractice:
        return FindNeighborsLevel2Widget(
          onComplete: _onLevel2Complete,
          onStartProblemTimer: startProblemTimer,
          onProblemComplete: (correct, answer) {
            recordProblemResult(
              levelNumber: 2,
              correct: correct,
              userAnswer: answer,
            );
          },
        );

      case ScaffoldLevel.independentMastery:
        return FindNeighborsLevel3Widget(
          onComplete: _onLevel3Complete,
          onStartProblemTimer: startProblemTimer,
          onProblemComplete: (correct, answer) {
            recordProblemResult(
              levelNumber: 3,
              correct: correct,
              userAnswer: answer,
            );
          },
        );

      case ScaffoldLevel.finale:
        return FindNeighborsLevel4Widget(
          onStartProblemTimer: startProblemTimer,
          onProblemComplete: (correct, answer) {
            recordProblemResult(
              levelNumber: 4,
              correct: correct,
              userAnswer: answer,
            );
          },
        );

      default:
        return Center(
          child: Text(
            'Level not implemented',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        );
    }
  }
}
