/// Ordering rule for Förderplan skill recommendations.
///
/// Rebuilt 2026-09-13 for the v3/v4 taxonomy (`Research/skills_taxonomy.csv`):
/// the legacy dotted construct IDs (`A1.1`, `C2.2`, ...) this file used to
/// parse out of the skill ID string no longer exist anywhere in the live
/// content, so every recommendation used to fall through to alphabetical
/// order. Construct membership is now looked up in [SkillCatalog] instead of
/// being parsed from the ID text, and within-construct order falls back to
/// the taxonomy CSV's own row order (already pedagogically sequenced by
/// `_sources_private/skills_taxonomy_v3_diagnostic.csv`'s card_number) rather
/// than an `a`/`b` suffix convention the new flat IDs don't use.
library;

import 'skill_catalog.dart';

/// Canonical didactic order of every construct in the v3/v4 taxonomy,
/// sequenced by the domain/card order of `Research/skills_taxonomy.csv`
/// (Zählen -> Zahlzerlegung/Schnelles Sehen -> Stellenwerte verstehen ->
/// Grundstrategien -> Kombinierte Strategien -> the PIKAS-sourced extras).
const List<String> canonicalConstructOrder = <String>[
  'quantify_count', 'count_forward', 'count_backward', 'successor',
  'predecessor', 'skip2_forward', 'skip2_backward', 'order_cards',
  'decompose', 'complete_to', 'structured_quantity_recognition',
  'quick_recognition', 'dot_field', 'bundling_recognition',
  'number_word_dictation', 'skip5_forward', 'skip5_backward',
  'skip10_forward', 'skip10_backward', 'compare_quantity', 'basic_fact_5',
  'complete_gap', 'double', 'halve', 'tens_add_sub', 'decade_analogy',
  'derive_near_double', 'derive_5', 'derive_10', 'cross_decade_add',
  'cross_decade_sub', 'place_on_numberline', 'hundred_chart',
  'shift_plus_minus', 'compensation_strategy', 'even_odd', 'fingerblitz',
  'equation_equivalence', 'commutativity', 'number_wall',
  'calculation_triangle', 'magnitude_estimate', 'ordinal',
  'representation_bild_symbol', 'operation_sense', 'number_line_strategy',
];

/// Compares two skill IDs by the documented recommendation order: construct
/// position in [canonicalConstructOrder] first (construct membership from
/// [catalog]), then the skill's own row position in the taxonomy CSV.
int compareRecommendations(
  String skillIdA,
  String skillIdB,
  SkillCatalog catalog,
) {
  final constructA = catalog.get(skillIdA)?.constructId ?? skillIdA;
  final constructB = catalog.get(skillIdB)?.constructId ?? skillIdB;

  if (constructA != constructB) {
    final rankA = canonicalConstructOrder.indexOf(constructA);
    final rankB = canonicalConstructOrder.indexOf(constructB);
    if (rankA >= 0 && rankB >= 0) return rankA - rankB;
    if (rankA >= 0) return -1;
    if (rankB >= 0) return 1;
    return constructA.compareTo(constructB);
  }

  final order = catalog.all.map((e) => e.skillId).toList();
  final idxA = order.indexOf(skillIdA);
  final idxB = order.indexOf(skillIdB);
  if (idxA >= 0 && idxB >= 0) return idxA - idxB;
  return skillIdA.compareTo(skillIdB);
}

/// Returns [ids] sorted by the documented recommendation order.
List<String> sortSkillIds(List<String> ids, SkillCatalog catalog) {
  final sorted = [...ids];
  sorted.sort((a, b) => compareRecommendations(a, b, catalog));
  return sorted;
}
