import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/skill_spec.dart';

Map<String, dynamic> _level(
  int level,
  String representation,
  String template,
  Map<String, dynamic> params,
  int slowBandMs, {
  String? customWidget,
}) => {
  'level': level,
  'representation': representation,
  'template': template,
  'custom_widget': customWidget,
  'params': params,
  'problem_count': 8,
  'prompt_de': 'Test-Prompt.',
  'slow_band_ms': slowBandMs,
};

/// A minimal but fully valid spec, mirroring the P2 §4 schema.
Map<String, dynamic> _validSpec() => {
  'spec_version': 1,
  'skill_id': 'T1',
  'construct_id': 'T1',
  'domain': 'A',
  'title_de': 'Test-Skill',
  'level_titles_de': ['Stufe 1', 'Stufe 2', 'Stufe 3'],
  'levels': [
    _level(1, 'enaktiv', 'place_counters', {
      'count_range': [1, 5],
      'frame': 'zehnerfeld',
      'action': 'fill',
    }, 9000),
    _level(2, 'ikonisch', 'zehnerfeld_read', {
      'count_range': [1, 5],
      'arrangement': 'structured',
    }, 7000),
    _level(3, 'symbolisch', 'equation_solve', {
      'op': '+',
      'unknown': 'result',
      'zr': 10,
      'a_range': [1, 5],
      'b_range': [1, 5],
      'mode': 'standard',
    }, 6000),
  ],
  'mastery': {'correct_of': 8},
  'error_taxonomy': [
    {
      'code': 'miscount',
      'label_de': 'verzählt',
      'hint_de': 'Zähle noch einmal langsam.',
    },
    {
      'code': 'other',
      'label_de': 'noch einmal probieren',
      'hint_de': 'Schau noch einmal genau hin.',
    },
  ],
  'provenance': {
    'sources': ['Testquelle 2026'],
    'author': 'Test',
    'reviewed_by': 'open',
  },
};

void _expectThrows(Map<String, dynamic> mutated) {
  expect(
    () => SkillSpec.fromJson(mutated),
    throwsA(isA<SpecFormatException>()),
    reason: 'expected SpecFormatException for ${jsonEncode(mutated)}',
  );
}

void main() {
  group('SkillSpec.fromJson', () {
    test('parses the real C1.1a fixture spec', () {
      final raw = File('test/fixtures/specs/c1_1a.json').readAsStringSync();
      final spec = SkillSpec.fromJson(jsonDecode(raw) as Map<String, dynamic>);

      expect(spec.specVersion, 1);
      expect(spec.skillId, 'C1.1a');
      expect(spec.constructId, 'C1.1');
      expect(spec.domain, 'C');
      expect(spec.titleDe, 'Additionsaufgaben bis 10 sicher lösen');
      expect(spec.levelTitlesDe, hasLength(3));

      expect(spec.levels, hasLength(3));
      expect(spec.levels[0].level, 1);
      expect(spec.levels[0].representation, 'enaktiv');
      expect(spec.levels[0].template, 'place_counters');
      expect(spec.levels[0].params['frame'], 'zehnerfeld');
      expect(spec.levels[0].problemCount, 8);
      expect(spec.levels[0].promptDe, isNotEmpty);
      expect(spec.levels[0].slowBandMs, 9000);
      expect(spec.levels[1].template, 'zehnerfeld_read');
      expect(spec.levels[1].slowBandMs, 7000);
      expect(spec.levels[2].template, 'equation_solve');
      expect(spec.levels[2].slowBandMs, 6000);

      expect(spec.mastery.correctOf, 8);
      expect(spec.errorTaxonomy, hasLength(5));
      expect(spec.errorTaxonomy[0].code, 'miscount');
      expect(spec.errorTaxonomy[0].labelDe, 'verzählt');
      expect(spec.errorTaxonomy[0].hintDe, isNotEmpty);
      expect(
        spec.provenance.sources,
        contains('Gaidoschik 2010; Padberg & Benz 2021'),
      );
      expect(spec.provenance.author, 'Claude (domain author)');
      expect(spec.provenance.reviewedBy, 'open');

      expect(spec.levelSpec(1).template, 'place_counters');
      expect(spec.levelSpec(3).template, 'equation_solve');
    });

    test('parses a minimal hand-written valid spec', () {
      final spec = SkillSpec.fromJson(_validSpec());
      expect(spec.skillId, 'T1');
      expect(spec.levels, hasLength(3));
      expect(spec.mastery.correctOf, 8);
    });

    test('parses a custom_widget level with a known registry key', () {
      final spec = _validSpec();
      spec['levels'][0] = _level(
        1,
        'ikonisch',
        'custom_widget',
        {
          'count_range': [1, 5],
          'flash_ms': 800,
          'display': 'dots',
        },
        9000,
        customWidget: 'flash_subitize',
      );
      final parsed = SkillSpec.fromJson(spec);
      expect(parsed.levels[0].template, 'custom_widget');
      expect(parsed.levels[0].customWidget, 'flash_subitize');
    });

    test('levelSpec rejects out-of-range levels', () {
      final spec = SkillSpec.fromJson(_validSpec());
      expect(() => spec.levelSpec(0), throwsA(isA<ArgumentError>()));
      expect(() => spec.levelSpec(4), throwsA(isA<ArgumentError>()));
    });

    group('injected schema violations throw SpecFormatException', () {
      test('unknown template', () {
        final s = _validSpec();
        s['levels'][2]['template'] = 'bogus_template';
        _expectThrows(s);
      });

      test('level count != 3', () {
        final s = _validSpec();
        s['levels'].removeLast();
        _expectThrows(s);
      });

      test('levels not numbered 1..3', () {
        final s = _validSpec();
        s['levels'][0]['level'] = 2;
        _expectThrows(s);
      });

      test('missing slow_band_ms', () {
        final s = _validSpec();
        s['levels'][0].remove('slow_band_ms');
        _expectThrows(s);
      });

      test('problem_count below 4', () {
        final s = _validSpec();
        s['levels'][0]['problem_count'] = 3;
        _expectThrows(s);
      });

      test('problem_count above 12', () {
        final s = _validSpec();
        s['levels'][0]['problem_count'] = 13;
        _expectThrows(s);
      });

      test('problem_count not an int', () {
        final s = _validSpec();
        s['levels'][0]['problem_count'] = 'eight';
        _expectThrows(s);
      });

      test('mastery.correct_of of 0', () {
        final s = _validSpec();
        s['mastery']['correct_of'] = 0;
        _expectThrows(s);
      });

      test('mastery.correct_of above problem_count', () {
        final s = _validSpec();
        s['mastery']['correct_of'] = 9;
        _expectThrows(s);
      });

      test('missing mastery object', () {
        final s = _validSpec();
        s.remove('mastery');
        _expectThrows(s);
      });

      test('duplicate error taxonomy codes', () {
        final s = _validSpec();
        s['error_taxonomy'][1]['code'] = 'miscount';
        _expectThrows(s);
      });

      test('empty error taxonomy code', () {
        final s = _validSpec();
        s['error_taxonomy'][0]['code'] = '';
        _expectThrows(s);
      });

      test('empty error taxonomy hint', () {
        final s = _validSpec();
        s['error_taxonomy'][0]['hint_de'] = '';
        _expectThrows(s);
      });

      test('empty error taxonomy label', () {
        final s = _validSpec();
        s['error_taxonomy'][0]['label_de'] = '';
        _expectThrows(s);
      });

      test('custom_widget template without a registry key', () {
        final s = _validSpec();
        s['levels'][0] = _level(1, 'ikonisch', 'custom_widget', {}, 9000);
        _expectThrows(s);
      });

      test('unknown custom_widget registry key', () {
        final s = _validSpec();
        s['levels'][0] = _level(
          1,
          'ikonisch',
          'custom_widget',
          {
            'count_range': [1, 5],
          },
          9000,
          customWidget: 'bogus_widget',
        );
        _expectThrows(s);
      });

      test('custom_widget set on a non-custom template', () {
        final s = _validSpec();
        s['levels'][0]['custom_widget'] = 'bundling';
        _expectThrows(s);
      });

      test('missing params object', () {
        final s = _validSpec();
        s['levels'][0].remove('params');
        _expectThrows(s);
      });

      test('missing prompt_de', () {
        final s = _validSpec();
        s['levels'][0].remove('prompt_de');
        _expectThrows(s);
      });

      test('missing title_de', () {
        final s = _validSpec();
        s.remove('title_de');
        _expectThrows(s);
      });

      test('missing provenance', () {
        final s = _validSpec();
        s.remove('provenance');
        _expectThrows(s);
      });
    });
  });
}
