import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/services/skill_recommendation_order.dart';

// Ground truth from docs/clean-room/01-construct-map.md (all 31 constructs in
// map order) sequenced per docs/clean-room/02-blueprint.md §Sequenzregeln and
// documented in docs/clean-room/foerderplan/ordering-rule.md.
const constructsFromMap = <String>[
  'A1.1', 'A1.2', 'A1.3', 'A1.4', 'A1.5',
  'A2.1', 'A2.2', 'A2.3',
  'A3.1', 'A3.2', 'A3.3',
  'B1.1', 'B1.2', 'B1.3',
  'B2.1', 'B2.2', 'B2.3',
  'C1.1', 'C1.2', 'C1.3',
  'C2.1', 'C2.2', 'C2.3',
  'C3.1', 'C3.2', 'C3.3', 'C3.4',
  'C4.1', 'C4.2',
  'D1.1', 'D1.2',
];

void main() {
  test('canonical construct order is complete', () {
    expect(canonicalConstructOrder.length, constructsFromMap.length);
    expect(canonicalConstructOrder.toSet(), constructsFromMap.toSet());
    expect(canonicalConstructOrder, constructsFromMap);

    // Domains are grouped A, B, C, D in that order.
    final domains = canonicalConstructOrder.map((id) => id[0]).toList();
    expect(domains, [...domains]..sort());
  });

  test('orders across constructs', () {
    final fixture = <String>['C3.2', 'A1.5', 'B2.1', 'D1.1', 'A1.1'];
    expect(
      sortSkillIds(fixture),
      <String>['A1.1', 'A1.5', 'B2.1', 'C3.2', 'D1.1'],
    );
  });

  test('orders within a construct', () {
    final fixture = <String>['A1.1b', 'A1.1a', 'A1.1'];
    expect(sortSkillIds(fixture), <String>['A1.1', 'A1.1a', 'A1.1b']);
  });

  test('deterministic tie-break', () {
    final set = <String>['C2.2', 'A3.1', 'B1.2', 'A1.1', 'D1.2'];
    final shuffled = <String>['D1.2', 'A1.1', 'B1.2', 'A3.1', 'C2.2'];
    expect(sortSkillIds(set), sortSkillIds(shuffled));
  });
}
