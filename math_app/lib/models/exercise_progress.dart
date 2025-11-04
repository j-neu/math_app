import 'level_progress.dart';

/// Exercise completion status tracking
///
/// Defines the four states of exercise completion:
/// - notStarted: Exercise never opened
/// - inProgress: Some levels unlocked, not all
/// - finished: All levels unlocked at least once
/// - completed: Finished + mastered (zero errors + time limits in finale)
enum ExerciseCompletionStatus {
  notStarted('Not Started'),
  inProgress('In Progress'),
  finished('Finished'),
  completed('Completed');

  final String displayName;
  const ExerciseCompletionStatus(this.displayName);
}

/// Tracks progress for a single exercise across all its levels.
///
/// This model captures:
/// - Current completion status (notStarted → inProgress → finished → completed)
/// - Per-level progress data (see LevelProgress)
/// - Timestamps for first attempt, finished, and completed
/// - Overall statistics (attempts, accuracy, time spent)
///
/// See COMPLETION_CRITERIA.md for complete specification.
class ExerciseProgress {
  /// Exercise identifier (e.g., 'C1.1', 'Z1')
  final String exerciseId;

  /// Current completion status
  final ExerciseCompletionStatus status;

  /// Progress data per level (levelNumber → LevelProgress)
  /// Example: {1: LevelProgress(...), 2: LevelProgress(...), 3: LevelProgress(...)}
  final Map<int, LevelProgress> levelProgress;

  /// When user first opened this exercise
  final DateTime? firstAttemptDate;

  /// When all levels were unlocked (status = finished)
  final DateTime? finishedDate;

  /// When completion criteria met (status = completed)
  final DateTime? completedDate;

  /// How many times user has opened this exercise
  final int totalAttempts;

  /// Best accuracy achieved across all levels (0.0 to 1.0)
  final double bestAccuracy;

  /// Cumulative time spent on this exercise (seconds)
  final int totalTimeSeconds;

  ExerciseProgress({
    required this.exerciseId,
    this.status = ExerciseCompletionStatus.notStarted,
    this.levelProgress = const {},
    this.firstAttemptDate,
    this.finishedDate,
    this.completedDate,
    this.totalAttempts = 0,
    this.bestAccuracy = 0.0,
    this.totalTimeSeconds = 0,
  });

  /// Create from JSON
  factory ExerciseProgress.fromJson(Map<String, dynamic> json) {
    // Parse levelProgress map
    Map<int, LevelProgress> parsedLevelProgress = {};
    if (json['levelProgress'] != null) {
      final levelProgressMap = json['levelProgress'] as Map<String, dynamic>;
      levelProgressMap.forEach((key, value) {
        parsedLevelProgress[int.parse(key)] =
            LevelProgress.fromJson(value as Map<String, dynamic>);
      });
    }

    return ExerciseProgress(
      exerciseId: json['exerciseId'] as String,
      status: ExerciseCompletionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ExerciseCompletionStatus.notStarted,
      ),
      levelProgress: parsedLevelProgress,
      firstAttemptDate: json['firstAttemptDate'] != null
          ? DateTime.parse(json['firstAttemptDate'] as String)
          : null,
      finishedDate: json['finishedDate'] != null
          ? DateTime.parse(json['finishedDate'] as String)
          : null,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      bestAccuracy: (json['bestAccuracy'] as num?)?.toDouble() ?? 0.0,
      totalTimeSeconds: json['totalTimeSeconds'] as int? ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    // Convert levelProgress map (int keys to string keys for JSON)
    final levelProgressJson = <String, dynamic>{};
    levelProgress.forEach((key, value) {
      levelProgressJson[key.toString()] = value.toJson();
    });

    return {
      'exerciseId': exerciseId,
      'status': status.name,
      'levelProgress': levelProgressJson,
      'firstAttemptDate': firstAttemptDate?.toIso8601String(),
      'finishedDate': finishedDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'totalAttempts': totalAttempts,
      'bestAccuracy': bestAccuracy,
      'totalTimeSeconds': totalTimeSeconds,
    };
  }

  /// Create a copy with updated fields
  ExerciseProgress copyWith({
    String? exerciseId,
    ExerciseCompletionStatus? status,
    Map<int, LevelProgress>? levelProgress,
    DateTime? firstAttemptDate,
    DateTime? finishedDate,
    DateTime? completedDate,
    int? totalAttempts,
    double? bestAccuracy,
    int? totalTimeSeconds,
  }) {
    return ExerciseProgress(
      exerciseId: exerciseId ?? this.exerciseId,
      status: status ?? this.status,
      levelProgress: levelProgress ?? this.levelProgress,
      firstAttemptDate: firstAttemptDate ?? this.firstAttemptDate,
      finishedDate: finishedDate ?? this.finishedDate,
      completedDate: completedDate ?? this.completedDate,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      bestAccuracy: bestAccuracy ?? this.bestAccuracy,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
    );
  }

  /// Check if all levels are unlocked
  bool areAllLevelsUnlocked(int totalLevels) {
    if (levelProgress.isEmpty) return false;

    for (int i = 1; i <= totalLevels; i++) {
      final level = levelProgress[i];
      if (level == null || !level.unlocked) {
        return false;
      }
    }
    return true;
  }

  /// Get progress for a specific level
  LevelProgress? getLevelProgress(int levelNumber) {
    return levelProgress[levelNumber];
  }
}
