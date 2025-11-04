import 'dart:async';
import 'package:flutter/material.dart';
import '../models/exercise_progress.dart';
import '../models/level_progress.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';

/// Mixin that provides reusable progress tracking logic for exercises.
///
/// Usage:
/// 1. Apply mixin to exercise State class: `class _MyExerciseState extends State<MyExercise> with ExerciseProgressMixin`
/// 2. Call `initializeProgress()` in initState
/// 3. Call `recordProblemResult()` after each problem attempt
/// 4. Call `unlockLevel()` when level unlocks
/// 5. Call `saveProgress()` periodically and on exit
///
/// The mixin handles:
/// - Loading saved progress from UserProfile
/// - Tracking problem results (correct/incorrect, time taken)
/// - Level unlock tracking
/// - Completion status calculation
/// - Periodic and on-exit saving
mixin ExerciseProgressMixin<T extends StatefulWidget> on State<T> {
  // Abstract properties - must be implemented by exercise
  String get exerciseId;
  UserProfile get userProfile;
  int get totalLevels; // Including finale
  int get finaleLevelNumber; // Usually totalLevels
  int get problemTimeLimit; // Seconds per problem for completion
  int get finaleMinProblems; // Minimum problems in finale for completion (usually 10)

  // Progress tracking state
  ExerciseProgress? _currentProgress;
  final Map<int, LevelProgress> _levelProgressMap = {};
  int _problemsSinceLastSave = 0;
  Stopwatch? _currentProblemTimer;
  DateTime? _firstAttemptDate;

  // Getters for exercises to use
  ExerciseProgress? get currentProgress => _currentProgress;
  Map<int, LevelProgress> get levelProgressMap => _levelProgressMap;

  /// Check if a level is unlocked
  bool isLevelUnlocked(int levelNumber) {
    return _levelProgressMap[levelNumber]?.unlocked ?? false;
  }

  /// Get progress for a specific level
  LevelProgress? getLevelProgress(int levelNumber) {
    return _levelProgressMap[levelNumber];
  }

  /// Initialize progress tracking - call in initState
  Future<void> initializeProgress() async {
    await _loadSavedProgress();

    // Ensure Level 1 is always unlocked
    if (!isLevelUnlocked(1)) {
      _levelProgressMap[1] = LevelProgress(
        levelNumber: 1,
        unlocked: true,
        correctAnswers: 0,
        totalAttempts: 0,
        problemResults: [],
        unlockedDate: DateTime.now(),
      );
    }
  }

  /// Load saved progress from UserProfile
  Future<void> _loadSavedProgress() async {
    try {
      final userService = UserService();
      final profile = await userService.getUserById(userProfile.id);

      if (profile != null) {
        final savedProgress = profile.exerciseProgress?[exerciseId];
        if (savedProgress != null) {
          _currentProgress = savedProgress;
          _levelProgressMap.addAll(savedProgress.levelProgress);
          _firstAttemptDate = savedProgress.firstAttemptDate;

          debugPrint('[ExerciseProgressMixin] Loaded progress for $exerciseId: ${savedProgress.status}');
        } else {
          // First time - initialize with Level 1 unlocked
          _firstAttemptDate = DateTime.now();
          _levelProgressMap[1] = LevelProgress(
            levelNumber: 1,
            unlocked: true,
            correctAnswers: 0,
            totalAttempts: 0,
            problemResults: [],
            unlockedDate: DateTime.now(),
          );
        }
      }
    } catch (e) {
      debugPrint('[ExerciseProgressMixin] Error loading progress: $e');
    }
  }

  /// Start timing a problem - call when problem is presented
  void startProblemTimer() {
    _currentProblemTimer = Stopwatch()..start();
  }

  /// Record result of a problem attempt
  ///
  /// [levelNumber] - Which level this problem is in
  /// [correct] - Was the answer correct?
  /// [userAnswer] - Optional: what the user entered
  Future<void> recordProblemResult({
    required int levelNumber,
    required bool correct,
    String? userAnswer,
  }) async {
    // Stop timer and get elapsed time
    _currentProblemTimer?.stop();
    final timeSeconds = _currentProblemTimer?.elapsed.inSeconds ?? 0;
    _currentProblemTimer = null;

    // Create problem result
    final result = ProblemResult(
      correct: correct,
      timeSeconds: timeSeconds,
      timestamp: DateTime.now(),
      userAnswer: userAnswer,
    );

    // Update level progress
    final currentLevel = _levelProgressMap[levelNumber];
    if (currentLevel != null) {
      final updatedResults = [...currentLevel.problemResults, result];
      final updatedLevel = currentLevel.copyWith(
        totalAttempts: currentLevel.totalAttempts + 1,
        correctAnswers: correct ? currentLevel.correctAnswers + 1 : currentLevel.correctAnswers,
        problemResults: updatedResults,
      );
      _levelProgressMap[levelNumber] = updatedLevel;
    }

    // Increment problems counter
    _problemsSinceLastSave++;

    // Auto-save every 5 problems
    if (_problemsSinceLastSave >= 5) {
      await saveProgress();
      _problemsSinceLastSave = 0;
    }
  }

  /// Unlock a level - call when unlock criteria met
  Future<void> unlockLevel(int levelNumber) async {
    if (isLevelUnlocked(levelNumber)) {
      return; // Already unlocked
    }

    final newLevel = LevelProgress(
      levelNumber: levelNumber,
      unlocked: true,
      correctAnswers: 0,
      totalAttempts: 0,
      problemResults: [],
      unlockedDate: DateTime.now(),
    );

    _levelProgressMap[levelNumber] = newLevel;

    debugPrint('[ExerciseProgressMixin] Unlocked level $levelNumber for $exerciseId');

    // Save immediately when level unlocks
    await saveProgress();
  }

  /// Calculate current completion status
  ExerciseCompletionStatus _calculateStatus() {
    // Check if all levels unlocked
    final allLevelsUnlocked = List.generate(totalLevels, (i) => i + 1)
        .every((level) => isLevelUnlocked(level));

    if (!allLevelsUnlocked) {
      return ExerciseCompletionStatus.inProgress;
    }

    // All levels unlocked - at least "finished"
    // Now check completion criteria for finale level
    final finaleProgress = _levelProgressMap[finaleLevelNumber];
    if (finaleProgress == null) {
      return ExerciseCompletionStatus.finished;
    }

    final finaleProblems = finaleProgress.problemResults;
    if (finaleProblems.length < finaleMinProblems) {
      return ExerciseCompletionStatus.finished; // Not enough problems
    }

    // Check last N problems (where N = finaleMinProblems)
    final recentProblems = finaleProblems.length > finaleMinProblems
        ? finaleProblems.sublist(finaleProblems.length - finaleMinProblems)
        : finaleProblems;

    // Check zero errors
    final hasErrors = recentProblems.any((p) => !p.correct);
    if (hasErrors) {
      return ExerciseCompletionStatus.finished;
    }

    // Check time limits
    final tooSlow = recentProblems.any((p) => p.timeSeconds > problemTimeLimit);
    if (tooSlow) {
      return ExerciseCompletionStatus.finished;
    }

    // All criteria met!
    return ExerciseCompletionStatus.completed;
  }

  /// Save progress to UserProfile
  Future<void> saveProgress() async {
    try {
      final userService = UserService();
      final profile = await userService.getUserById(userProfile.id);

      if (profile == null) {
        debugPrint('[ExerciseProgressMixin] Error: User profile not found');
        return;
      }

      // Calculate status
      final status = _calculateStatus();

      // Determine dates
      final firstAttempt = _firstAttemptDate ?? DateTime.now();
      final now = DateTime.now();

      DateTime? finishedDate;
      DateTime? completedDate;

      if (status == ExerciseCompletionStatus.finished || status == ExerciseCompletionStatus.completed) {
        finishedDate = _currentProgress?.finishedDate ?? now;
      }

      if (status == ExerciseCompletionStatus.completed) {
        completedDate = _currentProgress?.completedDate ?? now;
      }

      // Calculate best accuracy
      double bestAccuracy = 0.0;
      for (final levelProg in _levelProgressMap.values) {
        if (levelProg.totalAttempts > 0) {
          final acc = levelProg.correctAnswers / levelProg.totalAttempts;
          if (acc > bestAccuracy) bestAccuracy = acc;
        }
      }

      // Calculate total time
      int totalTimeSeconds = 0;
      for (final levelProg in _levelProgressMap.values) {
        for (final result in levelProg.problemResults) {
          totalTimeSeconds += result.timeSeconds;
        }
      }

      // Create updated progress
      final updatedProgress = ExerciseProgress(
        exerciseId: exerciseId,
        status: status,
        levelProgress: Map.from(_levelProgressMap),
        firstAttemptDate: firstAttempt,
        finishedDate: finishedDate,
        completedDate: completedDate,
        totalAttempts: (_currentProgress?.totalAttempts ?? 0) + 1,
        bestAccuracy: bestAccuracy,
        totalTimeSeconds: totalTimeSeconds,
      );

      // Update profile
      final updatedExerciseProgress = {...profile.exerciseProgress ?? {}};
      updatedExerciseProgress[exerciseId] = updatedProgress;

      final updatedProfile = profile.copyWith(
        exerciseProgress: updatedExerciseProgress,
        lastSessionDate: now,
      );

      await userService.saveUser(updatedProfile);

      _currentProgress = updatedProgress;

      debugPrint('[ExerciseProgressMixin] Saved progress for $exerciseId: $status');
    } catch (e) {
      debugPrint('[ExerciseProgressMixin] Error saving progress: $e');
    }
  }

  /// Call this in WillPopScope or dispose to save on exit
  Future<void> onExerciseExit() async {
    await saveProgress();
  }

  /// Get a summary of current progress for display
  String getProgressSummary() {
    final unlockedLevels = _levelProgressMap.values.where((lp) => lp.unlocked).length;
    final status = _currentProgress?.status ?? ExerciseCompletionStatus.inProgress;

    return 'Status: $status, Levels: $unlockedLevels/$totalLevels';
  }
}
