/// A single skill recommendation in a Förderplan.
///
/// Built by [DiagnosticReportGenerator] from one or more failed/timeout
/// diagnostic questions whose `IfWrong_practice_skills` reference this skill.
class SkillRecommendation {
  final String skillId;
  final String skillNameDe;
  final String descriptionDe;
  final String category;
  final String categoryColor;
  final int cardNumber;
  final List<int> triggeringQuestionIds;

  SkillRecommendation({
    required this.skillId,
    required this.skillNameDe,
    required this.descriptionDe,
    required this.category,
    required this.categoryColor,
    required this.cardNumber,
    required this.triggeringQuestionIds,
  });
}
