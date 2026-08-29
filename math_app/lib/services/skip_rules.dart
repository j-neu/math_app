/// Break-off (abbreviated-diagnostic) skip rules.
///
/// These rules are derived from the published argument — failure at ZR20
/// with Zehnerübergang predicts failure at ZR100 — as documented in
/// `docs/clean-room/02-blueprint.md` §Break-off (Wartha 2019, Eintrag A2 in
/// `03-bibliography.md`). They reference construct IDs from the construct
/// map, never question numbers.
class SkipRule {
  /// Construct IDs that must fail for this rule to fire.
  final Set<String> triggers;

  /// Construct IDs to skip when the trigger(s) fail.
  final Set<String> skipGroup;

  /// Cited rationale from the blueprint table's "Grundlage" column.
  final String basis;

  /// True when *all* [triggers] must fail (AND); false when any suffices.
  final bool requiresAll;

  const SkipRule({
    required this.triggers,
    required this.skipGroup,
    required this.basis,
    this.requiresAll = false,
  });
}

/// The documented break-off skip table (blueprint §Break-off).
class BreakOffRules {
  BreakOffRules._();

  /// The five documented rules, in blueprint order.
  static const List<SkipRule> rules = [
    // Rule 1: AND — both A1.3 and A1.5 must fail.
    SkipRule(
      triggers: {'A1.3', 'A1.5'},
      skipGroup: {'C1', 'C2', 'C3', 'C4'},
      basis: 'Zählkompetenz ist das Fundament der Operationsvorstellungen; '
          'ohne gesichertes Zählen über die Zehn sind additive Strategien '
          'nicht erreichbar — deren Items wären reine Frustrationsitems.',
      requiresAll: true,
    ),
    SkipRule(
      triggers: {'A3'},
      skipGroup: {'C2.1', 'C2.2'},
      basis: 'Zerlegungssicherheit ist Voraussetzung der Teilschritt-Verfahren; '
          'ohne sie tragen diese Items keine Information.',
    ),
    SkipRule(
      triggers: {'C2'},
      skipGroup: {'C3', 'C4'},
      basis: 'Kernregel: Scheitern im ZR20 mit Zehnerübergang sagt Scheitern '
          'im ZR100 voraus (Wartha 2019).',
    ),
    SkipRule(
      triggers: {'C3'},
      skipGroup: {'C4'},
      basis: 'Flexibles Rechnen setzt operative Sicherheit im Hunderterraum '
          'voraus; ohne sie ist Strategiewahl nicht aussagekräftig beobachtbar.',
    ),
    SkipRule(
      triggers: {'D1.1'},
      skipGroup: {'D1.2'},
      basis: 'Ohne Übersetzung der Sachsituation in eine Darstellung ist die '
          'Operationserkennung nicht sinnvoll testbar.',
    ),
  ];

  /// Trigger construct → sorted list of skipped constructs.
  ///
  /// The AND rule (A1.3 + A1.5) contributes one entry per trigger; a skip must
  /// only be applied once *every* trigger of an AND rule has failed.
  static Map<String, List<String>> get skipTable {
    final table = <String, List<String>>{};
    for (final rule in rules) {
      for (final trigger in rule.triggers) {
        table[trigger] = [...rule.skipGroup]..sort();
      }
    }
    return table;
  }

  /// Construct IDs that can trigger a skip.
  static const Set<String> triggerConstructs = {
    'A1.3',
    'A1.5',
    'A3',
    'C2',
    'C3',
    'D1.1',
  };

  /// Construct IDs that may be skipped.
  static const Set<String> skippedConstructs = {
    'C1',
    'C2',
    'C3',
    'C4',
    'C2.1',
    'C2.2',
    'D1.2',
  };
}
