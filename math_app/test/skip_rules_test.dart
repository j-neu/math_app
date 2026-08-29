import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/services/skip_rules.dart';

// Ground truth from docs/clean-room/02-blueprint.md §Break-off.
const expectedSkipTable = <String, List<String>>{
  'A1.3': ['C1', 'C2', 'C3', 'C4'],
  'A1.5': ['C1', 'C2', 'C3', 'C4'],
  'A3': ['C2.1', 'C2.2'],
  'C2': ['C3', 'C4'],
  'C3': ['C4'],
  'D1.1': ['D1.2'],
};

void main() {
  test('matches the documented rules for every construct', () {
    expect(BreakOffRules.rules.length, 5);
    expect(BreakOffRules.skipTable, expectedSkipTable);
  });

  test('AND rule for A1.3/A1.5', () {
    final andRule = BreakOffRules.rules.first;
    expect(andRule.triggers, {'A1.3', 'A1.5'});
    expect(andRule.skipGroup, {'C1', 'C2', 'C3', 'C4'});
    expect(andRule.requiresAll, isTrue);

    for (final rule in BreakOffRules.rules.skip(1)) {
      expect(rule.requiresAll, isFalse);
    }
  });

  test('no legacy question numbers', () {
    final allIds = <String>{};
    for (final rule in BreakOffRules.rules) {
      allIds.addAll(rule.triggers);
      allIds.addAll(rule.skipGroup);
    }

    // Construct IDs are "letter-digit.digit" like A1.3, so an unanchored
    // `\b\d{1,3}\b` would match the trailing digit of a valid ID; the check is
    // therefore anchored to the full ID token.
    final pureNumber = RegExp(r'^\d{1,3}$');
    final legacySkillScheme = RegExp(r'^[ZPSO]\d');
    final legacySnakePrefix = RegExp(
      r'^(basic|combined|counting|decomposition|number|operation|'
      r'ordinal|place|representation)_',
    );

    for (final id in allIds) {
      expect(pureNumber.hasMatch(id), isFalse,
          reason: '"$id" must not be a legacy question number');
      expect(legacySkillScheme.hasMatch(id), isFalse,
          reason: '"$id" must not use the legacy Z/P/S/O skill scheme');
      expect(legacySnakePrefix.hasMatch(id), isFalse,
          reason: '"$id" must not use a legacy snake_case skill prefix');
    }
  });

  test('trigger and skipped sets are consistent with the rules', () {
    final derivedTriggers = <String>{
      for (final rule in BreakOffRules.rules) ...rule.triggers,
    };
    final derivedSkipped = <String>{
      for (final rule in BreakOffRules.rules) ...rule.skipGroup,
    };
    expect(BreakOffRules.triggerConstructs, derivedTriggers);
    expect(BreakOffRules.skippedConstructs, derivedSkipped);
  });
}
