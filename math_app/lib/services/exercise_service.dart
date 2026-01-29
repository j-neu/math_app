import 'package:math_app/widgets/number_line_widget.dart';
import '../models/exercise.dart';
import '../models/user_profile.dart';
import '../models/exercise_progress.dart';
import '../models/milestone.dart';
import '../models/exercise_config.dart';
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
import '../exercises/finger_calculation_exercise.dart';
import '../exercises/more_less_exercise.dart';
import '../exercises/opposite_change_exercise.dart';
import '../exercises/doubling_mirror_exercise.dart';
import '../exercises/doubling_fingers_exercise.dart';
import '../exercises/doubling_fingers_20_exercise.dart';
import '../exercises/doubling_boat_exercise.dart';
import '../exercises/doubling_tens_exercise.dart';
import '../exercises/tens_calculation_exercise.dart';

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
    // NEW: S1.2 - Finger Folding (Finger Klappen)
    Exercise(
      id: 'S1.2',
      title: 'Finger Klappen',
      skillTags: ['basic_strategy_2'],
      exerciseBuilder: (userProfile) => FingerCalculationExercise(
        exerciseConfig: ExerciseConfig(
          id: 'S1.2',
          title: 'Finger Klappen',
          skillTags: ['basic_strategy_2'],
          sourceCard: 'iMINT Strategy Card: Finger Patterns',
          concept: 'Using finger patterns for calculation',
          observationPoints: ['Simultaneous finger usage vs counting'],
          internalizationPath: 'Action -> Mental Image -> Symbol',
          targetNumber: 10,
        ),
        userProfile: userProfile,
      ),
    ),
    // NEW: S1.4 - More or Less (Hamstern)
    Exercise(
      id: 'S1.4',
      title: 'More or Less (Hamstern)',
      skillTags: ['basic_strategy_4'],
      exerciseBuilder: (userProfile) => MoreLessExercise(
        exerciseConfig: ExerciseConfig(
          id: 'S1.4',
          title: 'More or Less (Hamstern)',
          skillTags: ['basic_strategy_4'],
          sourceCard: 'iMINT Strategy Card: Hamstern',
          concept: 'Comparing quantities and determining differences',
          observationPoints: [
            'Instant recognition of more/less',
            'Calculation of difference (Hamstern)',
          ],
          internalizationPath: 'Action (Dice) -> Visual comparison -> Mental calculation',
          targetNumber: 6,
        ),
        userProfile: userProfile,
      ),
    ),
    // NEW: S2.3 - Opposite Change (Gegensinniges Verändern)
    Exercise(
      id: 'S2.3',
      title: 'Opposite Change',
      skillTags: ['strategy_opposite_change_1'],
      exerciseBuilder: (userProfile) => OppositeChangeExercise(
        exerciseConfig: ExerciseConfig(
          id: 'S2.3',
          title: 'Opposite Change',
          skillTags: ['strategy_opposite_change_1'],
          sourceCard: 'iMINT Card 6: Gegensinniges Verändern',
          concept: 'Compensation Strategy',
          observationPoints: [
            'Simultaneous change (+1 and -1)',
            'Conservation of total quantity',
          ],
          internalizationPath: 'Covered manipulation -> Mental manipulation -> Numerical compensation',
          targetNumber: 20,
        ),
        userProfile: userProfile,
      ),
    ),
    // NEW: S3.1 - Doubling with Mirror (ZR 10)
    Exercise(
      id: 'S3.1',
      title: 'Verdoppeln mit Spiegel (ZR10)',
      skillTags: ['basic_strategy_7'],
      exerciseBuilder: (userProfile) => DoublingMirrorExercise(
        userProfile: userProfile,
        exerciseId: 'S3.1',
        title: 'Verdoppeln mit Spiegel (ZR10)',
        minInputNumber: 1,
        maxInputNumber: 5, // 1->2, 2->4, 3->6, 4->8, 5->10
      ),
    ),
    // NEW: S3.2 - Doubling with Mirror (ZR 20)
    Exercise(
      id: 'S3.2',
      title: 'Verdoppeln mit Spiegel (ZR20)',
      skillTags: ['basic_strategy_7'],
      exerciseBuilder: (userProfile) => DoublingMirrorExercise(
        userProfile: userProfile,
        exerciseId: 'S3.2',
        title: 'Verdoppeln mit Spiegel (ZR20)',
        minInputNumber: 6,
        maxInputNumber: 10, // 6->12, 7->14, 8->16, 9->18, 10->20
      ),
    ),
    // NEW: S3.3 - Doubling with Fingers (Verdoppeln mit Fingern)
    Exercise(
      id: 'S3.3',
      title: 'Verdoppeln mit Fingern',
      skillTags: ['basic_strategy_8'],
      exerciseBuilder: (userProfile) => DoublingFingersExercise(userProfile: userProfile),
    ),
    // NEW: S3.4 - Doubling on Calculation Boat (Verdoppeln am Rechenschiffchen)
    Exercise(
      id: 'S3.4',
      title: 'Verdoppeln am Rechenschiffchen',
      skillTags: ['basic_strategy_9', 'basic_strategy_10'],
      exerciseBuilder: (userProfile) => DoublingBoatExercise(userProfile: userProfile),
    ),
    // NEW: S3.5 - Doubling with Fingers to 20 (Verdoppeln mit Fingern bis 20)
    Exercise(
      id: 'S3.5',
      title: 'Verdoppeln mit Fingern (ZR20)',
      skillTags: ['basic_strategy_8', 'counting_20'],
      exerciseBuilder: (userProfile) => DoublingFingers20Exercise(userProfile: userProfile),
    ),
    // NEW: S3.6 - Doubling Tens
    Exercise(
      id: 'S3.6',
      title: 'Zehner verdoppeln',
      skillTags: ['strategy_doubling_tens_1'],
      exerciseBuilder: (userProfile) => DoublingTensExercise(
        userProfile: userProfile,
        exerciseId: 'S3.6',
      ),
    ),
    // NEW: S3.7 - Tens Calculation (Rechnen mit Zehnerzahlen)
    Exercise(
      id: 'S3.7',
      title: 'Rechnen mit Zehnern',
      skillTags: ['basic_strategy_11'],
      exerciseBuilder: (userProfile) => TensCalculationExercise(userProfile: userProfile),
    ),
    // NEW: Fully functional Z1 implementation based on PIKAS Card 9
    Exercise(
      id: 'Z1',
      title: 'Decompose 10',
      skillTags: ['decomposition_1', 'decomposition_3'],
      exerciseBuilder: (userProfile) => Decompose10Exercise(userProfile: userProfile),
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