// Canonical didactic order of every construct in the v3/v4 taxonomy
// (Research/skills_taxonomy.csv), sequenced by that CSV's domain/card order
// (Zaehlen -> Zahlzerlegung/Schnelles Sehen -> Stellenwerte verstehen ->
// Grundstrategien -> Kombinierte Strategien -> the PIKAS-sourced extras).
// Dart twin: math_app/lib/services/skill_recommendation_order.dart.
//
// Rebuilt 2026-09-13: this used to hold the old dotted construct IDs
// (`A1.1`, `C2.2`, ...) parsed out of the skill ID string via a regex. None
// of those IDs exist in the live content any more, so every recommendation
// silently fell through to alphabetical order. Construct membership is now
// resolved via a caller-supplied lookup (the `skills` table's `construct_id`
// column) instead of being parsed from the ID text.
export const canonicalConstructOrder: readonly string[] = [
  "quantify_count", "count_forward", "count_backward", "successor",
  "predecessor", "skip2_forward", "skip2_backward", "order_cards",
  "decompose", "complete_to", "structured_quantity_recognition",
  "quick_recognition", "dot_field", "bundling_recognition",
  "number_word_dictation", "skip5_forward", "skip5_backward",
  "skip10_forward", "skip10_backward", "compare_quantity", "basic_fact_5",
  "complete_gap", "double", "halve", "tens_add_sub", "decade_analogy",
  "derive_near_double", "derive_5", "derive_10", "cross_decade_add",
  "cross_decade_sub", "place_on_numberline", "hundred_chart",
  "shift_plus_minus", "compensation_strategy", "even_odd", "fingerblitz",
  "equation_equivalence", "commutativity", "number_wall",
  "calculation_triangle", "magnitude_estimate", "ordinal",
  "representation_bild_symbol", "operation_sense", "number_line_strategy",
];

/** Resolves a skill ID to its construct ID, e.g. via the `skills` table. */
export type ConstructIdOf = (skillId: string) => string;

/**
 * Construct position in [canonicalConstructOrder] first (construct
 * membership from [constructIdOf]), then the skill ID itself as a
 * deterministic tie-break within a construct.
 */
export function compareRecommendations(
  skillIdA: string,
  skillIdB: string,
  constructIdOf: ConstructIdOf,
): number {
  const constructA = constructIdOf(skillIdA) || skillIdA;
  const constructB = constructIdOf(skillIdB) || skillIdB;

  if (constructA !== constructB) {
    const rankA = canonicalConstructOrder.indexOf(constructA);
    const rankB = canonicalConstructOrder.indexOf(constructB);
    if (rankA >= 0 && rankB >= 0) return rankA - rankB;
    if (rankA >= 0) return -1;
    if (rankB >= 0) return 1;
    return constructA < constructB ? -1 : constructA > constructB ? 1 : 0;
  }

  return skillIdA < skillIdB ? -1 : skillIdA > skillIdB ? 1 : 0;
}

/** Returns a new sorted array; never mutates the input. */
export function sortSkillIds(skillIds: string[], constructIdOf: ConstructIdOf): string[] {
  return [...skillIds].sort((a, b) => compareRecommendations(a, b, constructIdOf));
}
