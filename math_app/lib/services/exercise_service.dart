import 'package:math_app/widgets/number_line_widget.dart';
import '../models/exercise.dart';
import '../models/user_profile.dart';
import '../models/exercise_progress.dart';
import '../models/milestone.dart';
import '../exercises/decompose_10_exercise.dart';
import '../exercises/count_dots_exercise_v2.dart';
import '../exercises/count_objects_exercise.dart';
import '../exercises/order_cards_exercise.dart';
import '../exercises/count_forward_exercise.dart';
import '../exercises/count_forward_50_exercise.dart';
import '../exercises/count_forward_100_exercise.dart';
import '../exercises/what_comes_next_exercise.dart';
import '../exercises/place_numbers_exercise.dart';
import '../exercises/place_numbers_100_exercise.dart';
import '../exercises/find_neighbors_exercise.dart';
import '../exercises/count_steps2_exercise.dart';
import '../exercises/count_steps_100field_exercise.dart';
import '../exercises/count_steps_backwards_100field_exercise.dart';
import '../exercises/count_100field_exercise.dart';
import '../exercises/finger_blitz_exercise.dart';

class ExerciseService {
  // Exercise library with both legacy placeholders and new functional exercises
  // Using semantic skill IDs (e.g., 'counting_4', 'decomposition_3')
  final List<Exercise> _allExercises = [
    // NEW: Fully functional C1.1 implementation with 5-level scaffolding (V2 + Finale)
    // Phase 2.5: Uses exerciseBuilder for progress tracking
    Exercise(
      id: 'C1.1',
      title: 'Count the Dots',
      skillTags: ['counting_1'],
      exerciseBuilder: (userProfile) => CountDotsExerciseV2(userProfile: userProfile),
    ),
    // NEW: C1.2 - Count the Objects with various object types (V2 + Finale)
    // Phase 2.5: Uses exerciseBuilder for progress tracking
    Exercise(
      id: 'C1.2',
      title: 'Count the Objects',
      skillTags: ['counting_1'],
      exerciseBuilder: (userProfile) => CountObjectsExercise(userProfile: userProfile),
    ),
    // NEW: C2.1 - Order Cards to 20 with 4-level scaffolding + Finale
    // Phase 2.5: Uses exerciseBuilder for progress tracking
    Exercise(
      id: 'C2.1',
      title: 'Order Cards to 20',
      skillTags: ['counting_2'],
      exerciseBuilder: (userProfile) => OrderCardsExercise(userProfile: userProfile),
    ),
    // NEW: C3.1 - Count Forward to 20 with 4-level scaffolding + Finale
    // Phase 2.5: Uses exerciseBuilder for progress tracking
    Exercise(
      id: 'C3.1',
      title: 'Count Forward to 20',
      skillTags: ['counting_3'],
      exerciseBuilder: (userProfile) => CountForwardExercise(userProfile: userProfile),
    ),
    // NEW: C3.2 - Count Forward to 50 with 4-level scaffolding + Finale
    // Phase 2.5: Uses exerciseBuilder for progress tracking
    Exercise(
      id: 'C3.2',
      title: 'Count Forward to 50',
      skillTags: ['counting_3'],
      exerciseBuilder: (userProfile) => CountForward50Exercise(userProfile: userProfile),
    ),
    // NEW: C3.3 - Count Forward to 100 with 4-level scaffolding + Finale
    // Phase 2.5: Uses exerciseBuilder for progress tracking
    Exercise(
      id: 'C3.3',
      title: 'Count Forward to 100',
      skillTags: ['counting_3'],
      exerciseBuilder: (userProfile) => CountForward100Exercise(userProfile: userProfile),
    ),
    // NEW: C4.1 - What Comes Next? (Predecessor/Successor) with 5-level scaffolding + Finale
    // Phase 2.5: Uses exerciseBuilder for progress tracking
    Exercise(
      id: 'C4.1',
      title: 'What Comes Next?',
      skillTags: ['counting_4', 'counting_5'],
      exerciseBuilder: (userProfile) => WhatComesNextExercise(userProfile: userProfile),
    ),
    // NEW: C5.1 - Find Neighboring Numbers (Card Game) with 4-level scaffolding + Finale
    // Phase 2.5: Uses exerciseBuilder for progress tracking
    Exercise(
      id: 'C5.1',
      title: 'Find Neighboring Numbers',
      skillTags: ['counting_5'],
      exerciseBuilder: (userProfile) => FindNeighborsExercise(userProfile: userProfile),
    ),
    // NEW: C10.1 - Place Numbers on Line (0-20) with 3-level scaffolding
    Exercise(
      id: 'C10.1',
      title: 'Place Numbers on Line (0-20)',
      skillTags: ['counting_10', 'counting_11'],
      exerciseBuilder: (userProfile) => PlaceNumbersExercise(userProfile: userProfile),
    ),
    // NEW: C10.2 - Place Numbers on Line (0-100)
    Exercise(
      id: 'C10.2',
      title: 'Place Numbers on Line (0-100)',
      skillTags: ['counting_10', 'counting_11', 'number_range_100'],
      exerciseBuilder: (userProfile) => PlaceNumbers100Exercise(userProfile: userProfile),
    ),
    // NEW: C6.0 - Understanding Number Sequences on 100-Field with 5-level scaffolding
    Exercise(
      id: 'C6.0',
      title: 'Number Sequences on 100-Field',
      skillTags: ['counting_8'],
      exerciseBuilder: (userProfile) => Count100FieldExercise(userProfile: userProfile),
    ),
    // NEW: C6.1 - Count in Steps of 2 with 4-level scaffolding (NO finale)
    // Phase 2.5: Uses exerciseBuilder for progress tracking
    Exercise(
      id: 'C6.1',
      title: 'Count in Steps of 2',
      skillTags: ['counting_6', 'counting_7'],
      exerciseBuilder: (userProfile) => CountSteps2Exercise(userProfile: userProfile),
    ),
    // NEW: C6.2 - Count in Steps on 100-Field with 6-level scaffolding
    Exercise(
      id: 'C6.2',
      title: 'Count in Steps on 100-Field',
      skillTags: ['counting_8', 'counting_6', 'counting_7'],
      exerciseBuilder: (userProfile) => CountSteps100FieldExercise(userProfile: userProfile),
    ),
    // NEW: C6.3 - Count BACKWARDS on 100-Field with 6-level scaffolding
    Exercise(
      id: 'C6.3',
      title: 'Count Backwards Steps on 100-Field',
      skillTags: ['counting_8', 'counting_6', 'counting_7', 'counting_backward'],
      exerciseBuilder: (userProfile) => CountStepsBackwards100FieldExercise(userProfile: userProfile),
    ),
    // NEW: S1.1 - Fingerblitz (Finger Patterns)
    Exercise(
      id: 'S1.1',
      title: 'Fingerblitz',
      skillTags: ['basic_strategy_1'],
      exerciseBuilder: (userProfile) => FingerBlitzExercise(userProfile: userProfile),
    ),
    // NEW: Fully functional Z1 implementation based on PIKAS Card 9
    Exercise(
      id: 'Z1',
      title: 'Decompose 10',
      skillTags: ['decomposition_1', 'decomposition_3'],
      exerciseWidget: const Decompose10Exercise(),
    ),
    Exercise(
      id: 'Z2',
      title: 'Make 10',
      skillTags: ['decomposition_3', 'decomposition_15'],
    ),
  ];

  /// Returns a prioritized list of exercises for the given user.
  List<Exercise> getLearningPath(UserProfile userProfile) {
    final learningPath = <Exercise>[];
    final userTags = userProfile.skillTags.toSet();

    for (final exercise in _allExercises) {
      // If the user has any of the skill tags required by the exercise, add it.
      if (exercise.skillTags.any((tag) => userTags.contains(tag))) {
        learningPath.add(exercise);
      }
    }

    // In the future, we can add more complex prioritization logic here.
    return learningPath;
  }

  /// Returns exercises grouped by milestone for the given user.
  ///
  /// Returns a map of Milestone → List<Exercise> for all milestones that
  /// contain at least one exercise relevant to the user's skill tags.
  ///
  /// If [showAll] is true (development mode), shows ALL exercises regardless of skill tags.
  Map<Milestone, List<Exercise>> getLearningPathGroupedByMilestone(
    UserProfile userProfile, {
    bool showAll = false,
  }) {
    final grouped = <Milestone, List<Exercise>>{};
    final userTags = userProfile.skillTags.toSet();

    for (final milestone in Milestone.allMilestones) {
      final milestoneExercises = <Exercise>[];

      for (final exerciseId in milestone.exerciseIds) {
        final exercise = _allExercises.firstWhere(
          (ex) => ex.id == exerciseId,
          orElse: () => Exercise(
            id: exerciseId,
            title: 'Unknown Exercise',
            skillTags: [],
          ),
        );

        // Include exercise if:
        // 1. showAll is true (development mode), OR
        // 2. User has any matching skill tags
        if (showAll || exercise.skillTags.any((tag) => userTags.contains(tag))) {
          milestoneExercises.add(exercise);
        }
      }

      // Only include milestone if it has exercises for this user
      if (milestoneExercises.isNotEmpty) {
        grouped[milestone] = milestoneExercises;
      }
    }

    return grouped;
  }

  /// Get exercises filtered by completion status
  List<Exercise> getExercisesByStatus(
    UserProfile profile,
    ExerciseCompletionStatus status,
  ) {
    return _allExercises.where((ex) {
      final progress = profile.exerciseProgress?[ex.id];
      return progress?.status == status;
    }).toList();
  }

  /// Get in-progress exercises (started but not finished)
  List<Exercise> getInProgressExercises(UserProfile profile) {
    return getExercisesByStatus(profile, ExerciseCompletionStatus.inProgress);
  }

  /// Get finished exercises (all levels unlocked, but not completed)
  List<Exercise> getFinishedButNotCompleted(UserProfile profile) {
    return getExercisesByStatus(profile, ExerciseCompletionStatus.finished);
  }

  /// Get completed exercises (mastered with zero errors + time limits)
  List<Exercise> getCompletedExercises(UserProfile profile) {
    return getExercisesByStatus(profile, ExerciseCompletionStatus.completed);
  }

  /// Get next recommended exercise based on priority:
  /// 1. In-progress exercises (continue what you started)
  /// 2. Not started exercises in unlocked milestones
  /// 3. Finished but not completed (review for mastery)
  Exercise? getNextRecommendedExercise(UserProfile profile) {
    final userTags = profile.skillTags.toSet();

    // Priority 1: In-progress exercises
    final inProgress = getInProgressExercises(profile);
    if (inProgress.isNotEmpty) return inProgress.first;

    // Priority 2: Not started exercises that match user's skills
    final notStarted = _allExercises.where((ex) {
      final progress = profile.exerciseProgress?[ex.id];
      final isNotStarted = progress == null ||
          progress.status == ExerciseCompletionStatus.notStarted;
      final hasMatchingSkills =
          ex.skillTags.any((tag) => userTags.contains(tag));
      return isNotStarted && hasMatchingSkills;
    }).toList();

    if (notStarted.isNotEmpty) return notStarted.first;

    // Priority 3: Finished but not completed (review for mastery)
    final needsReview = getFinishedButNotCompleted(profile);
    if (needsReview.isNotEmpty) return needsReview.first;

    return null; // All exercises completed!
  }

  /// Check if a milestone is complete (all exercises completed)
  bool isMilestoneComplete(Milestone milestone, UserProfile profile) {
    return milestone.exerciseIds.every((exId) {
      final progress = profile.exerciseProgress?[exId];
      return progress?.status == ExerciseCompletionStatus.completed;
    });
  }

  /// Get milestone progress (0.0 to 1.0)
  double getMilestoneProgress(Milestone milestone, UserProfile profile) {
    if (milestone.exerciseIds.isEmpty) return 0.0;

    final completedCount = milestone.exerciseIds.where((exId) {
      final progress = profile.exerciseProgress?[exId];
      return progress?.status == ExerciseCompletionStatus.completed;
    }).length;

    return completedCount / milestone.exerciseIds.length;
  }

  /// Get exercise by ID
  Exercise? getExerciseById(String id) {
    try {
      return _allExercises.firstWhere((ex) => ex.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get all exercises (for admin/debug purposes)
  List<Exercise> getAllExercises() {
    return List.unmodifiable(_allExercises);
  }
}