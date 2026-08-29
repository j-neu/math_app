import '../models/diagnostic_question.dart';
import '../models/diagnostic_session.dart';
import '../models/foerderplan.dart';
import '../models/skill_recommendation.dart';
import '../models/user_profile.dart';
import 'diagnostic_service.dart';
import 'skill_catalog.dart';

/// Builds a [Foerderplan] from a completed [DiagnosticSession].
class DiagnosticReportGenerator {
  /// Pedagogical category sequence — earlier categories must be mastered first.
  /// English-named categories fall through to the end.
  static const List<String> _categoryOrder = [
    'Zählen',
    'Zahlzerlegung / Schnelles Sehen',
    'Stellenwerte verstehen',
    'Grundstrategien',
    'Kombinierte Strategien',
  ];

  /// Fraction of *correct* answers that must exceed the per-question slow
  /// threshold for `slowResponseFlag` to fire.
  static const double _slowResponseFraction = 0.30;

  Future<Foerderplan> generate(
    UserProfile user,
    DiagnosticSession session,
  ) async {
    await SkillCatalog.instance.load();
    final catalog = SkillCatalog.instance;

    final questions = await DiagnosticService().loadQuestions();
    final questionsById = {for (final q in questions) q.listNumber: q};

    final triggersBySkill = _collectTriggersFromFailedQuestions(
      session,
      questionsById,
    );

    final recommendedSkills = _buildRecommendations(triggersBySkill, catalog);
    _sortPedagogically(recommendedSkills);

    final briefSkills = recommendedSkills.take(3).toList();
    final categoryStats = _computeCategoryStats(
      session,
      questionsById,
      catalog,
    );
    final slowResponseFlag = _computeSlowResponseFlag(session, questionsById);

    return Foerderplan(
      sessionDate: session.date,
      studentName: user.name,
      recommendedSkills: recommendedSkills,
      briefSkills: briefSkills,
      categoryStats: categoryStats,
      slowResponseFlag: slowResponseFlag,
    );
  }

  Map<String, List<int>> _collectTriggersFromFailedQuestions(
    DiagnosticSession session,
    Map<int, DiagnosticQuestion> questionsById,
  ) {
    final triggers = <String, List<int>>{};
    for (final result in session.results) {
      if (result.wasCorrect) continue;
      final qId = int.tryParse(result.questionId);
      if (qId == null) continue;
      final question = questionsById[qId];
      if (question == null) continue;
      for (final skillId in question.ifWrongPracticeSkills) {
        triggers.putIfAbsent(skillId, () => []).add(qId);
      }
    }
    return triggers;
  }

  List<SkillRecommendation> _buildRecommendations(
    Map<String, List<int>> triggersBySkill,
    SkillCatalog catalog,
  ) {
    final out = <SkillRecommendation>[];
    for (final entry in triggersBySkill.entries) {
      final meta = catalog.get(entry.key);
      if (meta == null) continue;
      out.add(SkillRecommendation(
        skillId: entry.key,
        skillNameDe: meta.nameDe,
        descriptionDe: meta.descriptionDe,
        category: meta.category,
        categoryColor: meta.categoryColor,
        cardNumber: meta.cardNumber,
        triggeringQuestionIds: entry.value,
      ));
    }
    return out;
  }

  void _sortPedagogically(List<SkillRecommendation> recs) {
    recs.sort((a, b) {
      final ar = _categoryRank(a.category);
      final br = _categoryRank(b.category);
      if (ar != br) return ar.compareTo(br);
      return a.cardNumber.compareTo(b.cardNumber);
    });
  }

  int _categoryRank(String category) {
    final idx = _categoryOrder.indexOf(category);
    return idx == -1 ? _categoryOrder.length : idx;
  }

  Map<String, ({int failed, int total})> _computeCategoryStats(
    DiagnosticSession session,
    Map<int, DiagnosticQuestion> questionsById,
    SkillCatalog catalog,
  ) {
    final failed = <String, int>{};
    final total = <String, int>{};

    for (final result in session.results) {
      final qId = int.tryParse(result.questionId);
      if (qId == null) continue;
      final question = questionsById[qId];
      if (question == null) continue;

      final categories = <String>{};
      for (final skillId in question.ifWrongPracticeSkills) {
        final meta = catalog.get(skillId);
        if (meta != null) categories.add(meta.category);
      }

      for (final c in categories) {
        total[c] = (total[c] ?? 0) + 1;
        if (!result.wasCorrect) failed[c] = (failed[c] ?? 0) + 1;
      }
    }

    return {
      for (final c in total.keys) c: (failed: failed[c] ?? 0, total: total[c]!),
    };
  }

  bool _computeSlowResponseFlag(
    DiagnosticSession session,
    Map<int, DiagnosticQuestion> questionsById,
  ) {
    int correctCount = 0;
    int slowCount = 0;
    for (final result in session.results) {
      if (!result.wasCorrect) continue;
      correctCount++;
      final qId = int.tryParse(result.questionId);
      final question = qId == null ? null : questionsById[qId];
      final threshold = _slowThresholdFor(
        question?.answerFormat ?? AnswerFormat.single,
      );
      if (result.responseTimeSeconds > threshold) slowCount++;
    }
    if (correctCount == 0) return false;
    return slowCount / correctCount >= _slowResponseFraction;
  }

  /// Tiered threshold by answer format: single answers should be near-instant
  /// for a calculating child; multi-step / sort tasks need more time.
  double _slowThresholdFor(AnswerFormat format) {
    switch (format) {
      case AnswerFormat.single:
        return 15.0;
      case AnswerFormat.multiple:
      case AnswerFormat.sort:
        return 30.0;
    }
  }
}
