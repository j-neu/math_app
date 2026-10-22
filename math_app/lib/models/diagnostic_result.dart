/// Represents the result of a single diagnostic question attempt.
/// Used to track performance, response times, and strategy development.
class DiagnosticResult {
  /// The question identifier from the CSV (e.g., "1", "2", "3")
  final String questionId;

  /// Whether the answer was correct
  final bool wasCorrect;

  /// Time taken to answer in seconds
  final double responseTimeSeconds;

  /// Status of the question: 'attempted', 'skipped', 'timeout'
  final String status;

  /// The user's answer (for analysis purposes)
  final String? userAnswer;

  /// Highest help stage the child opened (0-3)
  final int helpLevel;

  DiagnosticResult({
    required this.questionId,
    required this.wasCorrect,
    required this.responseTimeSeconds,
    this.status = 'attempted',
    this.userAnswer,
    this.helpLevel = 0,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'wasCorrect': wasCorrect,
      'responseTimeSeconds': responseTimeSeconds,
      'status': status,
      'userAnswer': userAnswer,
      'helpLevel': helpLevel,
    };
  }

  /// Create from JSON
  factory DiagnosticResult.fromJson(Map<String, dynamic> json) {
    return DiagnosticResult(
      questionId: json['questionId'] as String,
      wasCorrect: json['wasCorrect'] as bool,
      responseTimeSeconds: (json['responseTimeSeconds'] as num).toDouble(),
      status: json['status'] as String? ?? 'attempted',
      userAnswer: json['userAnswer'] as String?,
      helpLevel: json['helpLevel'] as int? ?? 0,
    );
  }

  /// Copy with modifications
  DiagnosticResult copyWith({
    String? questionId,
    bool? wasCorrect,
    double? responseTimeSeconds,
    String? status,
    String? userAnswer,
    int? helpLevel,
  }) {
    return DiagnosticResult(
      questionId: questionId ?? this.questionId,
      wasCorrect: wasCorrect ?? this.wasCorrect,
      responseTimeSeconds: responseTimeSeconds ?? this.responseTimeSeconds,
      status: status ?? this.status,
      userAnswer: userAnswer ?? this.userAnswer,
      helpLevel: helpLevel ?? this.helpLevel,
    );
  }
}
