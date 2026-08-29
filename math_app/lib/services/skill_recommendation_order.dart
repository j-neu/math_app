/// Ordering rule for Förderplan skill recommendations.
///
/// Replaces the legacy "category order → card_number ASC" sort. The rule is
/// documented in `docs/clean-room/foerderplan/ordering-rule.md`; its construct
/// sequence is derived from the construct map
/// (`docs/clean-room/01-construct-map.md`) and the blueprint's §Sequenzregeln
/// (`docs/clean-room/02-blueprint.md`).
library;

/// Canonical didactic order of every construct from the construct map
/// (Domäne A — Zahlbegriff, B — Stellenwertverständnis,
/// C — Rechenstrategien, D — Sachsituationen), sequenced per the blueprint
/// A1 → A2 → A3 → B1 → B2 → C1 → C2 → C3 → C4 → D1.
const List<String> canonicalConstructOrder = <String>[
  // Domäne A — Zahlbegriff
  'A1.1', 'A1.2', 'A1.3', 'A1.4', 'A1.5',
  'A2.1', 'A2.2', 'A2.3',
  'A3.1', 'A3.2', 'A3.3',
  // Domäne B — Stellenwertverständnis
  'B1.1', 'B1.2', 'B1.3',
  'B2.1', 'B2.2', 'B2.3',
  // Domäne C — Rechenstrategien
  'C1.1', 'C1.2', 'C1.3',
  'C2.1', 'C2.2', 'C2.3',
  'C3.1', 'C3.2', 'C3.3', 'C3.4',
  'C4.1', 'C4.2',
  // Domäne D — Sachsituationen
  'D1.1', 'D1.2',
];

final RegExp _constructPattern = RegExp(r'^([A-D]\d\.\d)(.*)$');

/// Splits a skill ID into (constructId, suffix): `A1.1a` → (`A1.1`, `a`),
/// `C2.2` → (`C2.2`, ``). IDs without a construct prefix are kept whole as
/// the construct with an empty suffix so they sort deterministically after
/// all known constructs.
(String, String) _splitSkillId(String skillId) {
  final match = _constructPattern.firstMatch(skillId);
  if (match == null) return (skillId, '');
  return (match.group(1)!, match.group(2)!);
}

/// Compares two skill IDs by the documented recommendation order:
/// construct position in [canonicalConstructOrder] first, then the suffix
/// within the same construct (no suffix first, `a` < `b`), then the full ID.
int compareRecommendations(String skillIdA, String skillIdB) {
  final (constructA, suffixA) = _splitSkillId(skillIdA);
  final (constructB, suffixB) = _splitSkillId(skillIdB);

  if (constructA != constructB) {
    final rankA = canonicalConstructOrder.indexOf(constructA);
    final rankB = canonicalConstructOrder.indexOf(constructB);
    if (rankA >= 0 && rankB >= 0) return rankA - rankB;
    if (rankA >= 0) return -1;
    if (rankB >= 0) return 1;
    return constructA.compareTo(constructB);
  }

  // Same construct: no suffix first, then a < b < …
  if (suffixA != suffixB) {
    if (suffixA.isEmpty) return -1;
    if (suffixB.isEmpty) return 1;
    return suffixA.compareTo(suffixB);
  }

  return skillIdA.compareTo(skillIdB);
}

/// Returns [ids] sorted by the documented recommendation order.
List<String> sortSkillIds(List<String> ids) {
  final sorted = [...ids];
  sorted.sort(compareRecommendations);
  return sorted;
}
