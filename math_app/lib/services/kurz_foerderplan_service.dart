import '../models/diagnostic_question.dart';
import '../models/foerderplan.dart';
import '../models/skill_recommendation.dart';

class KurzFoerderplanRow {
  final String category;
  final String categoryColor;
  final String ist;
  final String soll;
  final String lernweg;

  KurzFoerderplanRow({
    required this.category,
    required this.categoryColor,
    required this.ist,
    required this.soll,
    required this.lernweg,
  });
}

class KurzFoerderplanData {
  final List<KurzFoerderplanRow> rows;
  final bool hasSlowResponseNote;

  KurzFoerderplanData({required this.rows, required this.hasSlowResponseNote});
}

/// Generates structured Ist / Soll / Lernweg content from a [Foerderplan],
/// grouped by skill category.
///
/// The text templates here are rewritten against the new taxonomy in
/// tasks.md R4.3; this version only removes the protected work title and the
/// card references from the generated output (tasks.md R0.3).
class KurzFoerderplanService {
  static const _categoryOrder = [
    'Zählen',
    'Zahlzerlegung / Schnelles Sehen',
    'Stellenwerte verstehen',
    'Grundstrategien',
    'Kombinierte Strategien',
  ];

  KurzFoerderplanData generate(
    Foerderplan plan,
    Map<int, DiagnosticQuestion> questionsById,
  ) {
    final byCategory = <String, List<SkillRecommendation>>{};
    for (final s in plan.recommendedSkills) {
      byCategory.putIfAbsent(s.category, () => []).add(s);
    }

    final rows = <KurzFoerderplanRow>[];
    bool firstRow = true;

    for (final cat in _categoryOrder) {
      final skills = byCategory[cat];
      if (skills == null || skills.isEmpty) continue;

      final stats = plan.categoryStats[cat];
      rows.add(KurzFoerderplanRow(
        category: cat,
        categoryColor: skills.first.categoryColor,
        ist: _buildIst(cat, stats, skills, plan.slowResponseFlag && firstRow),
        soll: _buildSoll(skills),
        lernweg: _buildLernweg(skills),
      ));
      firstRow = false;
    }

    return KurzFoerderplanData(
      rows: rows,
      hasSlowResponseNote: plan.slowResponseFlag,
    );
  }

  String _buildIst(
    String category,
    ({int failed, int total})? stats,
    List<SkillRecommendation> skills,
    bool addSlowNote,
  ) {
    final buf = StringBuffer();
    if (stats != null && stats.failed > 0) {
      buf.write(
          'Im Bereich $category wurden ${stats.failed} von ${stats.total} Aufgaben nicht gelöst.');
    } else {
      buf.write('Im Bereich $category besteht Förderbedarf.');
    }
    buf.write('\nBeobachtete Schwierigkeiten:');
    for (final s in skills) {
      buf.write('\n- ${s.skillNameDe}');
    }
    if (addSlowNote) {
      buf.write(
          '\nHinweis: Kind löst Aufgaben zählend statt denkend (verlangsamte Antwortzeiten).');
    }
    return buf.toString();
  }

  String _buildSoll(List<SkillRecommendation> skills) {
    return skills.map((s) => '- Das Kind kann: ${s.descriptionDe}').join('\n');
  }

  String _buildLernweg(List<SkillRecommendation> skills) {
    final buf = StringBuffer('Fördervorschläge:');
    for (final s in skills) {
      buf.write('\n- ${s.skillNameDe}');
      buf.write('\n  ${s.descriptionDe}');
    }
    return buf.toString();
  }
}
