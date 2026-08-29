import '../models/diagnostic_question.dart';
import '../models/foerderplan.dart';
import '../models/skill_recommendation.dart';
import 'skill_recommendation_order.dart';

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

/// Generates structured Ist / Soll / Lernweg content from a [Foerderplan].
///
/// Rewritten per tasks.md R4.3: rows are grouped by Domain (A–D) instead of
/// the legacy categories. A skill ID matching `^[A-D]\d` maps to its domain
/// label (Domäne A — Zahlbegriff, …); any other ID falls back to the skill's
/// own legacy `category` value as the group label. Rows are ordered by domain
/// (A, B, C, D) and skills within a domain by the documented recommendation
/// order ([sortSkillIds]). The text templates are neutral and contain no card
/// reference and no protected work title.
class KurzFoerderplanService {
  static const _domainLabels = <String, String>{
    'A': 'Domäne A — Zahlbegriff',
    'B': 'Domäne B — Stellenwertverständnis',
    'C': 'Domäne C — Rechenstrategien',
    'D': 'Domäne D — Sachsituationen',
  };

  static final RegExp _domainPattern = RegExp(r'^([A-D])\d');

  KurzFoerderplanData generate(
    Foerderplan plan,
    Map<int, DiagnosticQuestion> questionsById,
  ) {
    final byGroup = <String, List<SkillRecommendation>>{};
    for (final s in plan.recommendedSkills) {
      byGroup.putIfAbsent(_groupLabel(s), () => []).add(s);
    }

    final rows = <KurzFoerderplanRow>[];
    bool firstRow = true;

    for (final label in _orderedGroupLabels(byGroup.keys)) {
      final skills = _sortedSkills(byGroup[label]!);
      final stats = plan.categoryStats[label];
      rows.add(KurzFoerderplanRow(
        category: label,
        categoryColor: skills.first.categoryColor,
        ist: _buildIst(label, stats, skills, plan.slowResponseFlag && firstRow),
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

  /// The group label for a recommendation: its domain label for new-taxonomy
  /// IDs, otherwise the skill's own legacy category value.
  String _groupLabel(SkillRecommendation s) {
    final match = _domainPattern.firstMatch(s.skillId);
    if (match != null) return _domainLabels[match.group(1)] ?? s.category;
    return s.category;
  }

  /// Domain groups (A, B, C, D) first in canonical order, then any legacy
  /// groups deterministically by label.
  List<String> _orderedGroupLabels(Iterable<String> labels) {
    final sorted = labels.toList();
    sorted.sort((a, b) {
      final ra = _labelRank(a);
      final rb = _labelRank(b);
      if (ra != rb) return ra - rb;
      return a.compareTo(b);
    });
    return sorted;
  }

  int _labelRank(String label) {
    final values = _domainLabels.values.toList();
    final idx = values.indexOf(label);
    return idx == -1 ? values.length : idx;
  }

  /// Skills within a group ordered by the documented recommendation order.
  List<SkillRecommendation> _sortedSkills(List<SkillRecommendation> skills) {
    final byId = {for (final s in skills) s.skillId: s};
    return [
      for (final id in sortSkillIds(byId.keys.toList())) byId[id]!,
    ];
  }

  String _buildIst(
    String label,
    ({int failed, int total})? stats,
    List<SkillRecommendation> skills,
    bool addSlowNote,
  ) {
    final buf = StringBuffer();
    if (stats != null && stats.failed > 0) {
      buf.write(
          'Im Bereich $label wurden ${stats.failed} von ${stats.total} Aufgaben nicht gelöst.');
    } else {
      buf.write('Im Bereich $label besteht Förderbedarf.');
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
