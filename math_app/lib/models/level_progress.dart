/// Tracks the result of a single problem attempt within a level.
///
/// Used to analyze child's performance patterns:
/// - Response time reveals strategy (counting vs recall)
/// - Error patterns help identify misconceptions
/// - Timestamps enable session analysis
class ProblemResult {
  /// Was the answer correct?
  final bool correct;

  /// Time taken to solve (seconds)
  final int timeSeconds;

  /// When this problem was attempted
  final DateTime timestamp;

  /// Optional: What the child entered (for error analysis)
  final String? userAnswer;

  ProblemResult({
    required this.correct,
    required this.timeSeconds,
    required this.timestamp,
    this.userAnswer,
  });

  /// Create from JSON
  factory ProblemResult.fromJson(Map<String, dynamic> json) {
    return ProblemResult(
      correct: json['correct'] as bool,
      timeSeconds: json['timeSeconds'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userAnswer: json['userAnswer'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'correct': correct,
      'timeSeconds': timeSeconds,
      'timestamp': timestamp.toIso8601String(),
      'userAnswer': userAnswer,
    };
  }
}

/// Tracks progress for a single level within an exercise.
///
/// Captures:
/// - Whether level is unlocked
/// - Correct/total attempts for accuracy tracking
/// - Individual problem results for detailed analysis
/// - Timestamps for unlocking and mastery
///
/// Example: Level 2 of "Count the Dots" exercise
class LevelProgress {
  /// Level number (1-5, where 5 is typically finale)
  final int levelNumber;

  /// Can user access this level?
  final bool unlocked;

  /// Count of correct answers
  final int correctAnswers;

  /// Count of all attempts (correct + incorrect)
  final int totalAttempts;

  /// Individual problem results (for detailed analysis)
  final List<ProblemResult> problemResults;

  /// When level was first unlocked
  final DateTime? unlockedDate;

  /// When level was mastered (90%+ accuracy sustained)
  final DateTime? masteredDate;

  LevelProgress({
    required this.levelNumber,
    this.unlocked = false,
    this.correctAnswers = 0,
    this.totalAttempts = 0,
    this.problemResults = const [],
    this.unlockedDate,
    this.masteredDate,
  });

  /// Accuracy percentage (0.0 to 1.0)
  double get accuracy {
    if (totalAttempts == 0) return 0.0;
    return correctAnswers / totalAttempts;
  }

  /// Average time per problem (seconds)
  double get averageTimePerProblem {
    if (problemResults.isEmpty) return 0.0;

    final totalTime = problemResults.fold<int>(
      0,
      (sum, result) => sum + result.timeSeconds,
    );

    return totalTime / problemResults.length;
  }

  /// Has this level been mastered? (90%+ accuracy with at least 20 attempts)
  bool get isMastered {
    return accuracy >= 0.9 && totalAttempts >= 20;
  }

  /// Create from JSON
  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    List<ProblemResult> parsedResults = [];
    if (json['problemResults'] != null) {
      parsedResults = (json['problemResults'] as List<dynamic>)
          .map((result) => ProblemResult.fromJson(result as Map<String, dynamic>))
          .toList();
    }

    return LevelProgress(
      levelNumber: json['levelNumber'] as int,
      unlocked: json['unlocked'] as bool? ?? false,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      problemResults: parsedResults,
      unlockedDate: json['unlockedDate'] != null
          ? DateTime.parse(json['unlockedDate'] as String)
          : null,
      masteredDate: json['masteredDate'] != null
          ? DateTime.parse(json['masteredDate'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'levelNumber': levelNumber,
      'unlocked': unlocked,
      'correctAnswers': correctAnswers,
      'totalAttempts': totalAttempts,
      'problemResults': problemResults.map((result) => result.toJson()).toList(),
      'unlockedDate': unlockedDate?.toIso8601String(),
      'masteredDate': masteredDate?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  LevelProgress copyWith({
    int? levelNumber,
    bool? unlocked,
    int? correctAnswers,
    int? totalAttempts,
    List<ProblemResult>? problemResults,
    DateTime? unlockedDate,
    DateTime? masteredDate,
  }) {
    return LevelProgress(
      levelNumber: levelNumber ?? this.levelNumber,
      unlocked: unlocked ?? this.unlocked,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      problemResults: problemResults ?? this.problemResults,
      unlockedDate: unlockedDate ?? this.unlockedDate,
      masteredDate: masteredDate ?? this.masteredDate,
    );
  }

  /// Add a problem result and update statistics
  LevelProgress addProblemResult(ProblemResult result) {
    final updatedResults = [...problemResults, result];
    final updatedCorrect = correctAnswers + (result.correct ? 1 : 0);
    final updatedTotal = totalAttempts + 1;

    // Check if just achieved mastery
    DateTime? updatedMasteredDate = masteredDate;
    final newAccuracy = updatedCorrect / updatedTotal;
    if (masteredDate == null && newAccuracy >= 0.9 && updatedTotal >= 20) {
      updatedMasteredDate = DateTime.now();
    }

    return copyWith(
      correctAnswers: updatedCorrect,
      totalAttempts: updatedTotal,
      problemResults: updatedResults,
      masteredDate: updatedMasteredDate,
    );
  }

  /// Unlock this level
  LevelProgress unlock() {
    return copyWith(
      unlocked: true,
      unlockedDate: unlockedDate ?? DateTime.now(),
    );
  }
}
