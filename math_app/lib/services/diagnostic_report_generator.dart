import '../models/diagnostic_question.dart';
import '../models/diagnostic_session.dart';
import '../models/foerderplan.dart';
import '../models/skill_recommendation.dart';
import '../models/user_profile.dart';
import 'diagnostic_service.dart';
import 'skill_catalog.dart';
import 'skill_recommendation_order.dart';

/// Builds a [Foerderplan] from a completed [DiagnosticSession].
class DiagnosticReportGenerator {
  /// Domain labels for the new taxonomy (matches the labels used by
  /// `KurzFoerderplanService`), keyed by the skill's domain letter.
  static const Map<String, String> _domainLabels = <String, String>{
    'A': 'Domäne A — Zahlbegriff',
    'B': 'Domäne B — Stellenwertverständnis',
    'C': 'Domäne C — Rechenstrategien',
    'D': 'Domäne D — Sachsituationen',
  };

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
        category: _domainLabel(meta.domain),
        categoryColor: meta.color,
        cardNumber: 0,
        triggeringQuestionIds: entry.value,
      ));
    }
    return out;
  }

  /// Domain label for a taxonomy skill; unknown domains keep the raw letter.
  String _domainLabel(String domain) => _domainLabels[domain] ?? domain;

  /// Orders recommendations by the documented R4.2 rule: canonical construct
  /// position first, then ID suffix (see `skill_recommendation_order.dart`).
  void _sortPedagogically(List<SkillRecommendation> recs) {
    final order = sortSkillIds(recs.map((r) => r.skillId).toList());
    final rank = {for (var i = 0; i < order.length; i++) order[i]: i};
    recs.sort((a, b) => rank[a.skillId]!.compareTo(rank[b.skillId]!));
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
        if (meta != null) categories.add(_domainLabel(meta.domain));
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
