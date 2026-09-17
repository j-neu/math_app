import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/skill_spec.dart';
import 'package:math_app/services/skill_spec_store.dart';

const String _specsDir = '../docs/clean-room/v4/skills/specs';

/// Test-only loader: reads the real v4 spec JSONs straight from the source
/// tree, so the parser is verified against exactly what the sync script
/// ships into the app bundle. Grows as batches add specs -- unlike the
/// retired v1/v2 suite this replaces, it does not hard-code a total count.
Map<String, String> _loadRealSpecJsons() {
  final dir = Directory(_specsDir);
  expect(dir.existsSync(), isTrue, reason: 'v4 spec tree must exist');
  final jsons = <String, String>{};
  final files =
      dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    jsons[file.path.split(Platform.pathSeparator).last] = file
        .readAsStringSync();
  }
  return jsons;
}

void main() {
  group('SkillSpecStore.fromJsonMap (v4 specs)', () {
    test('every bundled v4 spec parses and validates', () {
      final jsons = _loadRealSpecJsons();
      final store = SkillSpecStore.fromJsonMap(jsons);
      expect(store.allIds(), hasLength(jsons.length));
      expect(store.allSpecs(), hasLength(jsons.length));
      expect(store.validateAll(), isEmpty);
    });

    test('every spec id matches its own file name', () {
      for (final entry in _loadRealSpecJsons().entries) {
        final decoded = jsonDecode(entry.value) as Map<String, dynamic>;
        expect('${decoded['skill_id']}.json', entry.key);
      }
    });

    test('byId throws for an unknown id', () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      expect(() => store.byId('nope'), throwsA(isA<ArgumentError>()));
    });

    test('a schema-invalid spec fails fast with SpecFormatException', () {
      final bad = jsonEncode({'skill_id': 'T1'});
      expect(
        () => SkillSpecStore.fromJsonMap({'T1': bad}),
        throwsA(isA<SpecFormatException>()),
      );
    });

    test('double_zr10 (Pilot A) parses with the doubling-mirror widgets', () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('double_zr10');
      expect(spec.constructId, 'double');
      expect(spec.domain, 'C');
      expect(spec.titleDe, 'Verdoppeln im ZR10');
      expect(spec.levels.map((l) => l.customWidget), [
        'doubling_mirror_enaktiv',
        'doubling_mirror_ikonisch',
        'doubling_mirror_symbolisch',
      ]);
    });

    test('halve_zr10 (Pilot B) parses with the new halving-mirror widgets',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('halve_zr10');
      expect(spec.constructId, 'halve');
      expect(spec.domain, 'C');
      expect(spec.levels.map((l) => l.customWidget), [
        'halving_mirror_enaktiv',
        'halving_mirror_ikonisch',
        'halving_mirror_symbolisch',
      ]);
    });

    test(
        'quantify_count_zr10 (Batch 1.1) parses with the count-field widgets',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('quantify_count_zr10');
      expect(spec.constructId, 'quantify_count');
      expect(spec.domain, 'A');
      expect(spec.titleDe, 'Mengen zählen bis 10');
      expect(spec.levels.map((l) => l.customWidget), [
        'count_field_enaktiv',
        'count_field_ikonisch',
        'count_field_symbolisch',
      ]);
    });

    test(
        'count_forward_zr20 (Batch 1.2) parses with the sequence_gap template',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('count_forward_zr20');
      expect(spec.constructId, 'count_forward');
      expect(spec.domain, 'A');
      expect(spec.titleDe, 'Vorwärts zählen im ZR20');
      expect(spec.levels.map((l) => l.template),
          ['sequence_gap', 'sequence_gap', 'sequence_gap']);
      expect(spec.levels.map((l) => l.customWidget), [null, null, null]);
    });

    test(
        'count_forward_zr100 (Batch 1.2) parses with the sequence_gap template',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('count_forward_zr100');
      expect(spec.constructId, 'count_forward');
      expect(spec.domain, 'A');
      expect(spec.titleDe, 'Vorwärts zählen im ZR100');
      expect(spec.levels.map((l) => l.template),
          ['sequence_gap', 'sequence_gap', 'sequence_gap']);
    });

    test(
        'skip2_forward_zr20 (Batch 1.4a) parses with numberline_step/sequence_gap',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('skip2_forward_zr20');
      expect(spec.constructId, 'skip2_forward');
      expect(spec.domain, 'A');
      expect(spec.titleDe, 'Zweierschritte vorwärts (ZR20)');
      expect(spec.levels.map((l) => l.template),
          ['numberline_step', 'numberline_step', 'sequence_gap']);
    });

    test(
        'skip2_backward_zr20 (Batch 1.4a) parses with numberline_step/sequence_gap',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('skip2_backward_zr20');
      expect(spec.constructId, 'skip2_backward');
      expect(spec.domain, 'A');
      expect(spec.titleDe, 'Zweierschritte rückwärts (ZR20)');
      expect(spec.levels.map((l) => l.template),
          ['numberline_step', 'numberline_step', 'sequence_gap']);
    });

    test(
        'skip2_forward_zr100 (Batch 1.4b) parses with hundred_chart_skip/sequence_gap',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('skip2_forward_zr100');
      expect(spec.constructId, 'skip2_forward');
      expect(spec.domain, 'A');
      expect(spec.titleDe, 'Zweierschritte vorwärts (ZR100)');
      expect(spec.levels.map((l) => l.template),
          ['custom_widget', 'custom_widget', 'sequence_gap']);
      expect(spec.levels[0].customWidget, 'hundred_chart_skip');
      expect(spec.levels[1].customWidget, 'hundred_chart_skip');
    });

    test(
        'skip2_backward_zr100 (Batch 1.4b) parses with hundred_chart_skip/sequence_gap',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('skip2_backward_zr100');
      expect(spec.constructId, 'skip2_backward');
      expect(spec.domain, 'A');
      expect(spec.titleDe, 'Zweierschritte rückwärts (ZR100)');
      expect(spec.levels.map((l) => l.template),
          ['custom_widget', 'custom_widget', 'sequence_gap']);
      expect(spec.levels[0].customWidget, 'hundred_chart_skip');
      expect(spec.levels[1].customWidget, 'hundred_chart_skip');
    });

    for (final id in [
      'skip5_forward_zr100',
      'skip5_backward_zr100',
      'skip10_forward_zr100',
      'skip10_backward_zr100',
    ]) {
      test('$id (Batch 1.4c) parses with hundred_chart_skip/sequence_gap', () {
        final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
        final spec = store.byId(id);
        expect(spec.domain, 'A');
        expect(spec.levels.map((l) => l.template),
            ['custom_widget', 'custom_widget', 'sequence_gap']);
        expect(spec.levels[0].customWidget, 'hundred_chart_skip');
        expect(spec.levels[1].customWidget, 'hundred_chart_skip');
      });
    }

    test(
        'order_cards_zr20 (Batch 1.5) parses with the order_cards widget',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('order_cards_zr20');
      expect(spec.constructId, 'order_cards');
      expect(spec.domain, 'A');
      expect(spec.titleDe, 'Zahlenkarten ordnen im ZR20');
      expect(spec.levels.map((l) => l.customWidget),
          ['order_cards', 'order_cards', 'order_cards']);
    });

    test(
        'place_on_numberline_zr20 (Batch 1.6) parses with the numberline_place widget',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('place_on_numberline_zr20');
      expect(spec.constructId, 'place_on_numberline');
      expect(spec.domain, 'A');
      expect(spec.levels.map((l) => l.customWidget),
          ['numberline_place', 'numberline_place', 'numberline_place']);
    });

    test(
        'place_on_numberline_zr100 (Batch 1.6) parses with the numberline_place widget',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('place_on_numberline_zr100');
      expect(spec.constructId, 'place_on_numberline');
      expect(spec.domain, 'A');
      expect(spec.levels.map((l) => l.customWidget),
          ['numberline_place', 'numberline_place', 'numberline_place']);
    });

    test(
        'decompose_single_digit (Batch 1.7) parses with the drag_partition template',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('decompose_single_digit');
      expect(spec.constructId, 'decompose');
      expect(spec.domain, 'A');
      expect(spec.levels.map((l) => l.template),
          ['drag_partition', 'drag_partition', 'drag_partition']);
    });

    test(
        'compare_quantity_difference (Batch 1.8) parses with the '
        'quantity_compare widgets', () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('compare_quantity_difference');
      expect(spec.constructId, 'compare_quantity');
      expect(spec.domain, 'C');
      expect(spec.levels.map((l) => l.customWidget), [
        'quantity_compare_enaktiv',
        'quantity_compare_ikonisch',
        'quantity_compare_symbolisch',
      ]);
      expect(spec.levels.map((l) => l.problemCount), [10, 10, 10]);
    });

    test(
        'fingerblitz_quantity_zr10 (Batch 1.9) parses with fingerbild_read '
        'and the extended flash_subitize', () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('fingerblitz_quantity_zr10');
      expect(spec.constructId, 'fingerblitz');
      expect(spec.domain, 'C');
      expect(spec.levels.map((l) => l.template),
          ['fingerbild_read', 'custom_widget', 'custom_widget']);
      expect(spec.levels[1].customWidget, 'flash_subitize');
      expect(spec.levels[2].customWidget, 'flash_subitize');
    });

    test(
        'derive_via_10_add_minus1 (Batch 1.10) parses with strategy_choice',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('derive_via_10_add_minus1');
      expect(spec.constructId, 'derive_10');
      expect(spec.domain, 'C');
      expect(spec.levels.map((l) => l.template),
          ['strategy_choice', 'strategy_choice', 'strategy_choice']);
    });

    test(
        'derive_via_10_add_plus1 (Batch 1.10) parses with strategy_choice',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('derive_via_10_add_plus1');
      expect(spec.constructId, 'derive_10');
      expect(spec.domain, 'C');
      expect(spec.levels.map((l) => l.template),
          ['strategy_choice', 'strategy_choice', 'strategy_choice']);
    });

    test('derive_via_10_sub (Batch 1.10) parses with strategy_choice', () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('derive_via_10_sub');
      expect(spec.constructId, 'derive_10');
      expect(spec.domain, 'C');
      expect(spec.levels.map((l) => l.template),
          ['strategy_choice', 'strategy_choice', 'strategy_choice']);
    });

    test(
        'successor_zr20_decade (Batch 1.3) parses with the sequence_gap template',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('successor_zr20_decade');
      expect(spec.constructId, 'successor');
      expect(spec.domain, 'A');
      expect(spec.titleDe, 'Nachfolger an der Zehnergrenze (ZR20)');
      expect(spec.levels.map((l) => l.template),
          ['sequence_gap', 'sequence_gap', 'sequence_gap']);
    });

    test(
        'predecessor_zr20_decade (Batch 1.3) parses with the sequence_gap template',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('predecessor_zr20_decade');
      expect(spec.constructId, 'predecessor');
      expect(spec.domain, 'A');
      expect(spec.titleDe, 'Vorgänger an der Zehnergrenze (ZR20)');
      expect(spec.levels.map((l) => l.template),
          ['sequence_gap', 'sequence_gap', 'sequence_gap']);
    });
  });
}
