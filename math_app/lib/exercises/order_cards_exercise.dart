import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../widgets/ordercards_level1_widget.dart';
import '../widgets/ordercards_level2_widget.dart';
import '../widgets/ordercards_level3_widget.dart';

/// Complete implementation of EX-C2.1: Order Cards to 20 exercise
/// **REDESIGNED to follow iMINT Green Card 2 exactly**
///
/// This exercise follows the card-based scaffolding framework documented in
/// IMINT_TO_APP_FRAMEWORK.md and CLAUDE.md to properly answer
/// "Wie kommt die Handlung in den Kopf?" (How does action become mental?)
///
/// **Source:** iMINT Green Card 2: "Zahlenkarten bis 20 ordnen"
/// **Card Activities:**
/// - Activity A: Teacher lays cards 1-20 in 2-row structure, child reads sequence
/// - Activity B: Partner removes 2 cards, child finds missing numbers by neighbor logic
/// - Assessment: Child reproduces complete sequence from memory without structure
///
/// **Level 1: Read the Sequence (Activity A)**
/// - Cards 1-20 displayed in 2-row structure (1-10 top, 11-20 bottom)
/// - Child taps each card in order to "read" the sequence
/// - Emphasizes tens-structure: "13 is below 3, follows 12"
/// - Prompt: "Was fällt dir auf?" (What do you notice?)
/// - Unlocks Level 2 after reading sequence 3 times
///
/// **Level 2: Find Missing Cards (Activity B)**
/// - 2-row structure with 2 random cards missing (gaps shown)
/// - Child identifies missing numbers using neighbor relationships
/// - After correct answer: "Woher weißt du, dass die Zahl an diesen Platz gehört?"
/// - Shows positional logic: "13 follows 12 and is below 3"
/// - Unlocks Level 3 after 10 correct identifications
///
/// **Level 3: Reproduce from Memory (Assessment)**
/// - Flash 2-row structure briefly (3 seconds), then hide
/// - Child writes ALL 20 numbers in order from memory
/// - Tests complete internalization: "ohne Vorgabe einer Struktur aufschreiben"
/// - On error: Show structure briefly (no-fail safety net)
/// - Continuous practice with feedback
///
/// **Pedagogical Goals:**
/// - Understand number sequence 1-20 has fixed order
/// - Recognize tens-structure pattern (11 is 10+1, below 1)
/// - Use neighbor relationships to identify missing numbers
/// - Internalize sequence for mental work
///
/// **CRITICAL DIFFERENCE from old implementation:**
/// Old: Tap-in-order → Drag-to-sort → Memory-sort (generic sorting)
/// New: Read-structured → Find-gaps → Reproduce-from-memory (follows card exactly)
class OrderCardsExercise extends StatefulWidget {
  final ExerciseConfig config;

  const OrderCardsExercise({super.key})
      : config = const ExerciseConfig(
          id: 'C2.1',
          title: 'Order Cards to 20',
          skillTags: ['counting_2'],
          sourceCard: 'iMINT Green Card 2: Zahlenkarten bis 20 ordnen (Pages 75-76)',
          concept:
              'Understanding number sequence 1-20 and the tens-structure pattern. '
              'Numbers have fixed positions and predictable neighbor relationships.',
          observationPoints: [
            'Does child recognize the 2-row structure pattern?',
            'Can child identify missing numbers using neighbor logic?',
            'Can child reproduce the complete sequence from memory?',
            'Does child understand "13 is below 3 and follows 12" logic?',
          ],
          internalizationPath:
              'Level 1 (Read structured sequence) → Level 2 (Find missing with neighbors) → Level 3 (Reproduce from pure memory)',
          targetNumber: 20, // Working with numbers 1-20
          hints: [
            'Look at the pattern: first row is 1-10, second row is 11-20.',
            'Each number in the second row is 10 more than the number above it!',
            'Use the neighbors: what comes before and after the gap?',
            'Remember: 11 follows 10 and is below 1, 12 follows 11 and is below 2...',
          ],
        );

  @override
  State<OrderCardsExercise> createState() => _OrderCardsExerciseState();
}

class _OrderCardsExerciseState extends State<OrderCardsExercise> {
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration;
  late ScaffoldProgress _progress;

  // Level 1 tracking
  int _level1Sequences = 0;

  // Level 2 tracking
  int _level2Correct = 0;
  int _level2Total = 0;

  // Level 3 tracking
  int _level3Correct = 0;

  @override
  void initState() {
    super.initState();
    _progress = ScaffoldProgress();
  }

  void _onLevel1Progress(int sequencesCompleted) {
    setState(() {
      _level1Sequences = sequencesCompleted;

      // Unlock Level 2 after 3 complete sequences
      if (_level1Sequences >= 3 && !_progress.level2Unlocked) {
        _progress = _progress.copyWith(level1Complete: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Level 2 Unlocked! Now find the missing numbers!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _onLevel2Progress(int correct, int total) {
    setState(() {
      _level2Correct = correct;
      _level2Total = total;

      // Update progress tracker
      _progress = _progress.copyWith(
        level2Correct: correct,
        level2Total: total,
      );

      // Unlock Level 3 after 10 correct
      if (_level2Correct >= 10 && !_progress.level3Unlocked) {
        _progress = _progress.copyWith(level3Unlocked: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '🎉 Level 3 Unlocked! Challenge: reproduce from memory!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _onLevel3Progress(int correct) {
    setState(() {
      _level3Correct = correct;
    });
  }

  void _switchLevel(ScaffoldLevel level) {
    if (level == ScaffoldLevel.supportedPractice && !_progress.level2Unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete Level 1 first to unlock Level 2!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (level == ScaffoldLevel.independentMastery && !_progress.level3Unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete Level 2 first to unlock Level 3!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _currentLevel = level;
    });
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
          _buildLevelSelector(),

          // Current level progress
          _buildProgressIndicator(),

          // Current level content
          Expanded(
            child: _buildCurrentLevel(),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLevelButton(
            level: ScaffoldLevel.guidedExploration,
            label: 'Level 1',
            icon: Icons.visibility,
            isLocked: false,
          ),
          _buildLevelButton(
            level: ScaffoldLevel.supportedPractice,
            label: 'Level 2',
            icon: Icons.search,
            isLocked: !_progress.level2Unlocked,
          ),
          _buildLevelButton(
            level: ScaffoldLevel.independentMastery,
            label: 'Level 3',
            icon: Icons.psychology,
            isLocked: !_progress.level3Unlocked,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelButton({
    required ScaffoldLevel level,
    required String label,
    required IconData icon,
    required bool isLocked,
  }) {
    final isActive = _currentLevel == level;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: isLocked ? null : () => _switchLevel(level),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? Colors.blue : Colors.white,
            foregroundColor: isActive ? Colors.white : Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                color: isActive ? Colors.blue : Colors.grey.shade400,
                width: isActive ? 2 : 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLocked ? Icons.lock : icon,
                size: 14,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    String progressText;
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        progressText = 'Sequences read: $_level1Sequences/3 (unlock Level 2)';
        break;
      case ScaffoldLevel.supportedPractice:
        final accuracy = _level2Total > 0
            ? ((_level2Correct / _level2Total) * 100).toStringAsFixed(0)
            : '0';
        progressText =
            'Found: $_level2Correct/10 | Accuracy: $accuracy% (unlock Level 3)';
        break;
      case ScaffoldLevel.independentMastery:
        progressText = 'Completed from memory: $_level3Correct times';
        break;
      case ScaffoldLevel.advancedChallenge:
        progressText = '';
        break;

      default:
        // Finale level not yet implemented
        return const Center(child: Text('Finale level coming soon!'));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Expanded(
            child: Text(
              progressText,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLevel() {
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        return OrderCardsLevel1Widget(
          onProgressUpdate: _onLevel1Progress,
        );
      case ScaffoldLevel.supportedPractice:
        return OrderCardsLevel2Widget(
          onProgressUpdate: _onLevel2Progress,
        );
      case ScaffoldLevel.independentMastery:
        return OrderCardsLevel3Widget(
          onProgressUpdate: _onLevel3Progress,
        );
      case ScaffoldLevel.advancedChallenge:
        return const SizedBox.shrink();
      case ScaffoldLevel.finale:
        // Finale level not yet implemented for this exercise
        return const Center(
          child: Text('Finale level coming soon!'),
        );
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About This Exercise'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.config.concept,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '3-Level Learning Path:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildInfoSection(
                '👁️ Level 1: Read the Sequence',
                'Tap cards 1-20 in order. Notice the 2-row pattern: 1-10 on top, 11-20 below.',
              ),
              _buildInfoSection(
                '🔍 Level 2: Find Missing Numbers',
                'Two numbers are hidden! Use neighbor logic to find them: "13 follows 12 and is below 3"',
              ),
              _buildInfoSection(
                '🧠 Level 3: Write from Memory',
                'Flash, then hide! Write all 20 numbers in order from your mental image.',
              ),
              const SizedBox(height: 16),
              Text(
                'Source: ${widget.config.sourceCard}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
