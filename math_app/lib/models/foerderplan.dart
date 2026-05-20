import 'skill_recommendation.dart';

/// A teacher-facing Förderplan generated from a completed diagnostic session.
///
/// Produced by [DiagnosticReportGenerator]; rendered by
/// `DiagnosticReportScreen` and `PdfReportService`.
class Foerderplan {
  final DateTime sessionDate;
  final String studentName;

  /// All recommended skills, deduped and pedagogically ordered
  /// (category sequence, then `cardNumber` ASC).
  final List<SkillRecommendation> recommendedSkills;

  /// First 3 of [recommendedSkills] — the "Kurzer Förderplan".
  final List<SkillRecommendation> briefSkills;

  /// Per-category counts: how many questions in that category were failed
  /// vs. the total number of questions tagged with skills in that category.
  final Map<String, ({int failed, int total})> categoryStats;

  /// True when ≥30% of *correct* answers exceeded the slow-response threshold —
  /// signals the child is likely counting rather than calculating.
  final bool slowResponseFlag;

  Foerderplan({
    required this.sessionDate,
    required this.studentName,
    required this.recommendedSkills,
    required this.briefSkills,
    required this.categoryStats,
    required this.slowResponseFlag,
  });
}
