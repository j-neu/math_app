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
  });
}
