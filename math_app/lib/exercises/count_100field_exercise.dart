import 'package:flutter/material.dart';
import '../models/exercise_config.dart';
import '../models/scaffold_level.dart';
import '../models/user_profile.dart';
import '../mixins/exercise_progress_mixin.dart';
import '../widgets/count_100field_level1_widget.dart';
import '../widgets/count_100field_level2_widget.dart';
import '../widgets/count_100field_level3_widget.dart';
import '../widgets/count_100field_level4_widget.dart';
import '../widgets/count_100field_level5_widget.dart';
import '../widgets/common/instruction_modal.dart';
import '../widgets/common/level_selection_drawer.dart';
import '../widgets/common/minimalist_exercise_scaffold.dart';

class Count100FieldExercise extends StatefulWidget {
  final ExerciseConfig config;
  final UserProfile userProfile;

  const Count100FieldExercise({
    super.key,
    required this.userProfile,
  }) : config = const ExerciseConfig(
          id: 'C6.0',
          title: 'Zahlenfolgen im Hunderterfeld',
          skillTags: ['counting_8'],
          sourceCard: 'iMINT Arbeitskarte 8: Zahlenfolgen in der Hundertertafel verstehen (Pages 87-88)',
          concept:
              'Understanding the structure of the 100-field: horizontal rows increase by 1, '
              'vertical columns increase by 10.',
          observationPoints: [
            'Can child explain how they know which number is at a position?',
            'Does child recognize the +1 horizontal and +10 vertical patterns?',
          ],
          internalizationPath:
              'Level 1 (Explore) → Level 2 (Vertical +10) → Level 3 (Horizontal +1) → Level 4 (Context) → Level 5 (Finale)',
          targetNumber: 100,
          hints: [
            'Right adds 1',
            'Down adds 10',
          ],
        );

  @override
  State<Count100FieldExercise> createState() => _Count100FieldExerciseState();
}

class _LevelConfig {
  final int levelNumber;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String pedagogicalAction;
  final ScaffoldLevel scaffoldLevel;

  const _LevelConfig({
    required this.levelNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.pedagogicalAction,
    required this.scaffoldLevel,
  });
}

class _Count100FieldExerciseState extends State<Count100FieldExercise>
    with ExerciseProgressMixin {
  @override
  String get exerciseId => widget.config.id;

  @override
  UserProfile get userProfile => widget.userProfile;

  @override
  int get totalLevels => 5;

  @override
  int get finaleLevelNumber => 5;

  @override
  int get problemTimeLimit => 30;

  @override
  int get finaleMinProblems => 10;

  int _currentLevelNumber = 1;
  List<bool> _problemResults = []; // Tracks success for current level
  int _currentProblemIndex = 0;

  // Define levels using local config class
  final List<_LevelConfig> _levels = [
    _LevelConfig(
      levelNumber: 1,
      title: 'Entdecke das Hunderterfeld',
      description: 'Erkunde das Feld',
      icon: Icons.explore,
      color: Colors.blue,
      pedagogicalAction: 'Free exploration',
      scaffoldLevel: ScaffoldLevel.guidedExploration,
    ),
    _LevelConfig(
      levelNumber: 2,
      title: 'Senkrechte Zahlenfolgen',
      description: 'Fülle die Zahlen nach unten (+10)',
      icon: Icons.arrow_downward,
      color: Colors.green,
      pedagogicalAction: 'Vertical +10 pattern',
      scaffoldLevel: ScaffoldLevel.supportedPractice,
    ),
    _LevelConfig(
      levelNumber: 3,
      title: 'Waagerechte Zahlenfolgen',
      description: 'Fülle die Zahlen nach rechts (+1)',
      icon: Icons.arrow_forward,
      color: Colors.orange,
      pedagogicalAction: 'Horizontal +1 pattern',
      scaffoldLevel: ScaffoldLevel.independentMastery,
    ),
    _LevelConfig(
      levelNumber: 4,
      title: 'Aus dem Zusammenhang',
      description: 'Finde die fehlende Zahl',
      icon: Icons.question_mark,
      color: Colors.purple,
      pedagogicalAction: 'Context filling',
      scaffoldLevel: ScaffoldLevel.advancedChallenge,
    ),
    _LevelConfig(
      levelNumber: 5,
      title: 'Finale: Gemischte Aufgaben',
      description: 'Zeig, was du gelernt hast!',
      icon: Icons.emoji_events,
      color: Colors.amber,
      pedagogicalAction: 'Consolidation',
      scaffoldLevel: ScaffoldLevel.finale,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeExercise();
  }

  Future<void> _initializeExercise() async {
    await initializeProgress();
    if (mounted) {
      setState(() {
        // Determine the highest unlocked level to start at
        int highestUnlocked = 1;
        for (int i = 1; i <= totalLevels; i++) {
          if (isLevelUnlocked(i)) {
            highestUnlocked = i;
          }
        }
        _currentLevelNumber = highestUnlocked;
        
        // Reset problem tracking
        _problemResults = [];
        _currentProblemIndex = 0;
      });
    }
  }

  @override
  void dispose() {
    saveProgress();
    super.dispose();
  }

  void _onProblemResult(bool isCorrect) {
    setState(() {
      _problemResults.add(isCorrect);
      _currentProblemIndex++;
    });

    recordProblemResult(
      levelNumber: _currentLevelNumber,
      correct: isCorrect,
      userAnswer: null,
    );

    // Check completion (Level 1 is special - 1 "problem")
    int requiredProblems = _currentLevelNumber == 1 ? 1 : 10;
    
    if (_currentProblemIndex >= requiredProblems) {
      _onLevelComplete();
    }
  }

  void _onLevelComplete() async {
    await saveProgress();
    
    // Unlock next level
    if (_currentLevelNumber < totalLevels) {
      unlockLevel(_currentLevelNumber + 1);
    }
    
    // Note: Status updates are handled automatically by saveProgress in the mixin

    if (!mounted) return;
    
    // Determine if this is a finale completion
    bool isFinaleComplete = false;
    if (_currentLevelNumber == finaleLevelNumber) {
       // Simple check for now - could rely on mixin status if needed
       isFinaleComplete = _problemResults.take(10).every((r) => r);
    }
    
    // Show dialog
    showDialog(
       context: context,
       barrierDismissible: false,
       builder: (context) => AlertDialog(
          title: Text(
              isFinaleComplete ? 'Übung geschafft! 🎉' : 'Level $_currentLevelNumber geschafft! 🎉'
          ),
          content: Text(
              isFinaleComplete 
                  ? 'Toll gemacht! Du kennst dich jetzt im Hunderterfeld aus! 🌟' 
                  : 'Toll gemacht! Bereit für die nächste Aufgabe?'
          ),
         actions: [
           TextButton(
             onPressed: () {
               Navigator.pop(context);
               Navigator.pop(context); // Return to path
             },
             child: const Text('Für heute beenden'),
           ),
           if (_currentLevelNumber < totalLevels)
             ElevatedButton(
               onPressed: () {
                 Navigator.pop(context);
                 _switchLevel(ScaffoldLevel.values[_currentLevelNumber]); // Move to next (index + 1)
               },
               child: const Text('Weiter'),
             ),
         ],
       ),
    );
  }

  void _switchLevel(ScaffoldLevel level) {
    if (!isLevelUnlocked(level.levelNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Level gesperrt. Schließe zuerst die vorherigen Level ab.')),
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
    final currentLevelDef = _levels.firstWhere((l) => l.levelNumber == _currentLevelNumber);
    
    return MinimalistExerciseScaffold(
      exerciseTitle: widget.config.title,
      totalProblems: _currentLevelNumber == 1 ? 1 : 10,
      currentProblemIndex: _currentProblemIndex,
      problemResults: _problemResults,
      onShowInstructions: () {
         InstructionModal.show(
           context,
           levelTitle: currentLevelDef.title,
           instructionText: _getInstructions(_currentLevelNumber),
           levelColor: currentLevelDef.color,
         );
      },
      onShowLevelSelector: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => LevelSelectionDrawer(
            levels: ScaffoldLevel.values, // Pass standard enum values
            currentLevel: ScaffoldLevel.values[_currentLevelNumber - 1], // Pass current enum level
            onLevelSelected: _switchLevel,
            isLevelUnlocked: (l) => isLevelUnlocked(l.levelNumber),
          ),
        );
      },
      exerciseContent: _buildLevelWidget(),
    );
  }

  String _getInstructions(int level) {
    switch(level) {
      case 1: return "Erkunde das Feld! Schau dich um. Wenn du bereit bist, tippe auf den Knopf.";
      case 2: return "Fülle die Zahlen nach UNTEN ein. Denk dran: +10!";
      case 3: return "Fülle die Zahlen nach RECHTS ein. Denk dran: +1!";
      case 4: return "Fülle die fehlende Zahl in der Mitte ein.";
      case 5: return "Gemischte Aufgaben aus allen Leveln. Viel Erfolg!";
      default: return "";
    }
  }

  Widget _buildLevelWidget() {
    switch (_currentLevelNumber) {
      case 1: return Count100FieldLevel1Widget(onComplete: () => _onProblemResult(true));
      case 2: return Count100FieldLevel2Widget(onProblemSolved: _onProblemResult);
      case 3: return Count100FieldLevel3Widget(onProblemSolved: _onProblemResult);
      case 4: return Count100FieldLevel4Widget(onProblemSolved: _onProblemResult);
      case 5: return Count100FieldLevel5Widget(onProblemSolved: _onProblemResult);
      default: return const Center(child: Text("Fehler"));
    }
  }
}