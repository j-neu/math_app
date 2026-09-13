import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/services/skill_catalog.dart';
import 'package:math_app/services/skill_recommendation_order.dart';

/// Rewritten 2026-09-13 for the v3/v4 taxonomy: the old fixtures used dotted
/// legacy IDs (`A1.1`, `C2.2`, ...) that no longer exist in
/// `Research/skills_taxonomy.csv`; ordering is now resolved via a
/// [SkillCatalog] lookup rather than by parsing the skill ID string.
void main() {
  final catalog = SkillCatalog.loadFromCsv(
    File('Research/skills_taxonomy.csv').readAsStringSync(),
  );

  test('canonical construct order is complete and matches the catalog', () {
    final constructsInCatalog =
        catalog.all.map((e) => e.constructId).toSet();
    expect(canonicalConstructOrder.toSet(), constructsInCatalog);
    expect(canonicalConstructOrder.length, canonicalConstructOrder.toSet().length,
        reason: 'no duplicate constructs');
  });

  test('orders across constructs by domain/card sequence', () {
    final fixture = <String>[
      'derive_via_10_sub', // Kombinierte Strategien
      'quantify_count_zr10', // Zählen, card 1
      'bundling_recognition_zr100', // Stellenwerte verstehen
      'double_zr10', // Grundstrategien
    ];
    expect(
      sortSkillIds(fixture, catalog),
      <String>[
        'quantify_count_zr10',
        'bundling_recognition_zr100',
        'double_zr10',
        'derive_via_10_sub',
      ],
    );
  });

  test('orders within a construct by taxonomy row order (ZR10 -> ZR20 -> ZR100)',
      () {
    final fixture = <String>[
      'double_2digit_with_carry', // ZR100
      'double_zr10', // ZR10
      'double_crossing_10', // ZR20
    ];
    expect(
      sortSkillIds(fixture, catalog),
      <String>['double_zr10', 'double_crossing_10', 'double_2digit_with_carry'],
    );
  });

  test('deterministic tie-break regardless of input order', () {
    final set = <String>[
      'halve_decade',
      'count_forward_zr20',
      'complete_to_10',
      'ordinal_1',
    ];
    final shuffled = <String>[
      'ordinal_1',
      'complete_to_10',
      'count_forward_zr20',
      'halve_decade',
    ];
    expect(sortSkillIds(set, catalog), sortSkillIds(shuffled, catalog));
  });

  test('an ID absent from the catalog sorts deterministically after known constructs',
      () {
    final fixture = <String>['quantify_count_zr10', 'not_a_real_skill'];
    expect(
      sortSkillIds(fixture, catalog),
      <String>['quantify_count_zr10', 'not_a_real_skill'],
    );
  });
}
