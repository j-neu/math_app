import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/skill_spec.dart';
import 'package:math_app/services/skill_spec_store.dart';

const String _specsDir = '../docs/clean-room/skills/specs';

/// Test-only loader: reads the real spec JSONs straight from the clean-room
/// source tree, so the parser is verified against exactly what the sync
/// script ships into the app bundle.
Map<String, String> _loadRealSpecJsons() {
  final dir = Directory(_specsDir);
  expect(dir.existsSync(), isTrue, reason: 'real spec tree must exist');
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
  group('SkillSpecStore.fromJsonMap', () {
    test('parses all 36 real spec JSONs', () {
      final jsons = _loadRealSpecJsons();
      expect(jsons, hasLength(36));

      final store = SkillSpecStore.fromJsonMap(jsons);
      expect(store.allIds(), hasLength(36));
      expect(store.allSpecs(), hasLength(36));
      expect(store.validateAll(), isEmpty);
    });

    test('byId returns the parsed spec', () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('C1.1a');
      expect(spec.skillId, 'C1.1a');
      expect(spec.levels, hasLength(3));
      expect(store.byId('A3.3').levels[1].params['progression'], 'double');
    });

    test('byId throws for an unknown id', () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      expect(() => store.byId('nope'), throwsA(isA<ArgumentError>()));
    });

    test('allIds sorts deterministically', () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final ids = store.allIds();
      final expected = List<String>.from(ids)..sort();
      expect(ids, expected);
      expect(ids, containsAll(['A1.1a', 'C1.1a', 'D1.2']));
    });

    test('a schema-invalid spec fails fast with SpecFormatException', () {
      final bad = jsonEncode({
        'skill_id': 'T1',
      }); // missing levels, mastery, ...
      expect(
        () => SkillSpecStore.fromJsonMap({'T1': bad}),
        throwsA(isA<SpecFormatException>()),
      );
    });

    test('a non-object JSON document is rejected', () {
      expect(
        () => SkillSpecStore.fromJsonMap({'T1': '[1, 2, 3]'}),
        throwsA(isA<SpecFormatException>()),
      );
    });

    test('specs keyed by their own skill_id, not the map key', () {
      final store = SkillSpecStore.fromJsonMap({
        'whatever': _loadRealSpecJsons()['C1.1a.json']!,
      });
      expect(store.byId('C1.1a').skillId, 'C1.1a');
    });
  });
}
