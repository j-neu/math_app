import 'package:flutter/material.dart';
import 'package:math_app/models/exercise.dart';
import 'package:math_app/models/user_profile.dart';
import 'package:math_app/services/exercise_service.dart';

class ExerciseScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Exercise? exerciseOverride; // If provided, show this specific exercise

  const ExerciseScreen({
    super.key,
    required this.userProfile,
    this.exerciseOverride,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  late List<Exercise> _learningPath;
  final int _currentExerciseIndex = 0;
  int _currentRepresentation = 0; // 0: Action, 1: Image, 2: Symbol

  @override
  void initState() {
    super.initState();
    // If exerciseOverride is provided, use only that exercise
    if (widget.exerciseOverride != null) {
      _learningPath = [widget.exerciseOverride!];
    } else {
      _learningPath = ExerciseService().getLearningPath(widget.userProfile);
    }
  }

  Widget _buildRepresentationView(Exercise exercise) {
    // Phase 2.5: If exercise has a builder, use that (passes UserProfile for progress tracking)
    if (exercise.exerciseBuilder != null) {
      return exercise.exerciseBuilder!(widget.userProfile);
    }

    // Legacy: If exercise has a dedicated widget, use that instead of representation switcher
    if (exercise.exerciseWidget != null) {
      return exercise.exerciseWidget!;
    }

    // Legacy representation switcher for placeholder exercises
    switch (_currentRepresentation) {
      case 0:
        // If actionContent is a Widget, display it. Otherwise, show placeholder.
        return exercise.actionContent as Widget? ?? const Center(child: Text('No Action Content'));
      case 1:
        return exercise.imageContent as Widget? ?? const Center(child: Text('No Image Content'));
      case 2:
        return exercise.symbolContent as Widget? ?? const Center(child: Text('No Symbol Content'));
      default:
        return const Center(child: Text('Unknown View'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_learningPath.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Learning Path')),
        body: const Center(
          child: Text('Congratulations! You have mastered all skills.'),
        ),
      );
    }

    final currentExercise = _learningPath[_currentExerciseIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentExercise.title),
      ),
      body: _buildRepresentationView(currentExercise),
      // Only show representation switcher for legacy placeholder exercises
      bottomNavigationBar: (currentExercise.exerciseBuilder == null &&
                            currentExercise.exerciseWidget == null)
          ? BottomNavigationBar(
              currentIndex: _currentRepresentation,
              onTap: (index) {
                setState(() {
                  _currentRepresentation = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.touch_app),
                  label: 'Action',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.image),
                  label: 'Image',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.functions),
                  label: 'Symbol',
                ),
              ],
            )
          : null,
    );
  }
}