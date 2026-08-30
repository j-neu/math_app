// Canonical didactic order of every construct in the construct map
// (docs/clean-room/01-construct-map.md; rule: docs/clean-room/foerderplan/ordering-rule.md).
// Dart twin: math_app/lib/services/skill_recommendation_order.dart (tasks.md R4.2).
export const canonicalConstructOrder: readonly string[] = [
  "A1.1", "A1.2", "A1.3", "A1.4", "A1.5",
  "A2.1", "A2.2", "A2.3",
  "A3.1", "A3.2", "A3.3",
  "B1.1", "B1.2", "B1.3",
  "B2.1", "B2.2", "B2.3",
  "C1.1", "C1.2", "C1.3",
  "C2.1", "C2.2", "C2.3",
  "C3.1", "C3.2", "C3.3", "C3.4",
  "C4.1", "C4.2",
  "D1.1", "D1.2",
];

const SKILL_ID_PATTERN = /^([A-D]\d\.\d)(.*)$/;

/** `A1.1a` → `["A1.1", "a"]`; an ID without a construct prefix is kept whole. */
export function splitSkillId(skillId: string): [string, string] {
  const m = SKILL_ID_PATTERN.exec(skillId);
  if (!m) return [skillId, ""];
  return [m[1]!, m[2]!];
}

/** Construct position first, then suffix (none before `a`), then the full ID. */
export function compareRecommendations(skillIdA: string, skillIdB: string): number {
  const [constructA, suffixA] = splitSkillId(skillIdA);
  const [constructB, suffixB] = splitSkillId(skillIdB);

  if (constructA !== constructB) {
    const rankA = canonicalConstructOrder.indexOf(constructA);
    const rankB = canonicalConstructOrder.indexOf(constructB);
    if (rankA >= 0 && rankB >= 0) return rankA - rankB;
    if (rankA >= 0) return -1;
    if (rankB >= 0) return 1;
    return constructA < constructB ? -1 : constructA > constructB ? 1 : 0;
  }

  if (suffixA !== suffixB) {
    if (suffixA === "") return -1;
    if (suffixB === "") return 1;
    return suffixA < suffixB ? -1 : suffixA > suffixB ? 1 : 0;
  }

  return skillIdA < skillIdB ? -1 : skillIdA > skillIdB ? 1 : 0;
}

/** Returns a new sorted array; never mutates the input. */
export function sortSkillIds(skillIds: string[]): string[] {
  return [...skillIds].sort(compareRecommendations);
}
