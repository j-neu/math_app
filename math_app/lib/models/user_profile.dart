import 'diagnostic_result.dart';
import 'exercise_progress.dart';
import 'reward_config.dart';

class UserProfile {
  final String id;
  final String name;
  final int age;
  final List<String> skillTags;
  final int? diagnosticProgress; // Current question index in diagnostic test
  final Map<int, String>? diagnosticAnswers; // Saved answers during diagnostic
  final List<DiagnosticResult>? diagnosticResults; // Full diagnostic session data
  final bool useBreakOffLogic; // If true, skip harder questions when easier ones fail (default: true)
  final bool lockExercisesInOrder; // If true, exercises must be completed sequentially (default: true)

  // Phase 2.5: Exercise completion tracking
  final Map<String, ExerciseProgress>? exerciseProgress; // exerciseId → progress data
  final RewardConfig? rewardConfig; // Parent-configured reward settings
  final DateTime? lastSessionDate; // Last time user practiced
  final int totalExercisesCompleted; // Count of exercises with "completed" status
  final int exercisesCompletedToday; // Count of exercises finished today (any status)

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.skillTags,
    this.diagnosticProgress,
    this.diagnosticAnswers,
    this.diagnosticResults,
    this.useBreakOffLogic = true, // Default to shortened test
    this.lockExercisesInOrder = true, // Default to locked/sequential
    this.exerciseProgress,
    this.rewardConfig,
    this.lastSessionDate,
    this.totalExercisesCompleted = 0,
    this.exercisesCompletedToday = 0,
  });

  // Convert UserProfile to JSON
  Map<String, dynamic> toJson() {
    // Convert exerciseProgress map
    final exerciseProgressJson = <String, dynamic>{};
    exerciseProgress?.forEach((key, value) {
      exerciseProgressJson[key] = value.toJson();
    });

    return {
      'id': id,
      'name': name,
      'age': age,
      'skillTags': skillTags,
      'diagnosticProgress': diagnosticProgress,
      'diagnosticAnswers': diagnosticAnswers?.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'diagnosticResults': diagnosticResults?.map((result) => result.toJson()).toList(),
      'useBreakOffLogic': useBreakOffLogic,
      'lockExercisesInOrder': lockExercisesInOrder,
      'exerciseProgress': exerciseProgressJson,
      'rewardConfig': rewardConfig?.toJson(),
      'lastSessionDate': lastSessionDate?.toIso8601String(),
      'totalExercisesCompleted': totalExercisesCompleted,
      'exercisesCompletedToday': exercisesCompletedToday,
    };
  }

  // Create UserProfile from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    Map<int, String>? diagnosticAnswers;
    if (json['diagnosticAnswers'] != null) {
      final answersMap = json['diagnosticAnswers'] as Map<String, dynamic>;
      diagnosticAnswers = answersMap.map(
        (key, value) => MapEntry(int.parse(key), value as String),
      );
    }

    List<DiagnosticResult>? diagnosticResults;
    if (json['diagnosticResults'] != null) {
      diagnosticResults = (json['diagnosticResults'] as List<dynamic>)
          .map((result) => DiagnosticResult.fromJson(result as Map<String, dynamic>))
          .toList();
    }

    // Parse exerciseProgress map
    Map<String, ExerciseProgress>? parsedExerciseProgress;
    if (json['exerciseProgress'] != null) {
      final progressMap = json['exerciseProgress'] as Map<String, dynamic>;
      parsedExerciseProgress = {};
      progressMap.forEach((key, value) {
        parsedExerciseProgress![key] = ExerciseProgress.fromJson(value as Map<String, dynamic>);
      });
    }

    // Parse rewardConfig
    RewardConfig? parsedRewardConfig;
    if (json['rewardConfig'] != null) {
      parsedRewardConfig = RewardConfig.fromJson(json['rewardConfig'] as Map<String, dynamic>);
    }

    // Parse lastSessionDate
    DateTime? parsedLastSessionDate;
    if (json['lastSessionDate'] != null) {
      parsedLastSessionDate = DateTime.parse(json['lastSessionDate'] as String);
    }

    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      skillTags: (json['skillTags'] as List<dynamic>).cast<String>(),
      diagnosticProgress: json['diagnosticProgress'] as int?,
      diagnosticAnswers: diagnosticAnswers,
      diagnosticResults: diagnosticResults,
      useBreakOffLogic: json['useBreakOffLogic'] as bool? ?? true, // Default to true for backward compatibility
      lockExercisesInOrder: json['lockExercisesInOrder'] as bool? ?? true, // Default to true for backward compatibility
      exerciseProgress: parsedExerciseProgress,
      rewardConfig: parsedRewardConfig,
      lastSessionDate: parsedLastSessionDate,
      totalExercisesCompleted: json['totalExercisesCompleted'] as int? ?? 0,
      exercisesCompletedToday: json['exercisesCompletedToday'] as int? ?? 0,
    );
  }

  // Create a copy of UserProfile with updated fields
  UserProfile copyWith({
    String? id,
    String? name,
    int? age,
    List<String>? skillTags,
    int? diagnosticProgress,
    Map<int, String>? diagnosticAnswers,
    List<DiagnosticResult>? diagnosticResults,
    bool? useBreakOffLogic,
    bool? lockExercisesInOrder,
    bool clearDiagnosticProgress = false,
    Map<String, ExerciseProgress>? exerciseProgress,
    RewardConfig? rewardConfig,
    DateTime? lastSessionDate,
    int? totalExercisesCompleted,
    int? exercisesCompletedToday,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      skillTags: skillTags ?? this.skillTags,
      diagnosticProgress: clearDiagnosticProgress ? null : (diagnosticProgress ?? this.diagnosticProgress),
      diagnosticAnswers: clearDiagnosticProgress ? null : (diagnosticAnswers ?? this.diagnosticAnswers),
      diagnosticResults: clearDiagnosticProgress ? null : (diagnosticResults ?? this.diagnosticResults),
      useBreakOffLogic: useBreakOffLogic ?? this.useBreakOffLogic,
      lockExercisesInOrder: lockExercisesInOrder ?? this.lockExercisesInOrder,
      exerciseProgress: exerciseProgress ?? this.exerciseProgress,
      rewardConfig: rewardConfig ?? this.rewardConfig,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      totalExercisesCompleted: totalExercisesCompleted ?? this.totalExercisesCompleted,
      exercisesCompletedToday: exercisesCompletedToday ?? this.exercisesCompletedToday,
    );
  }
}