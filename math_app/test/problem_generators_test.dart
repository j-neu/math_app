import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/problem.dart';
import 'package:math_app/models/skill_spec.dart';
import 'package:math_app/practice/problem_generators.dart';

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

Map<String, dynamic> _baseSpec(Map<String, dynamic> level2) => {
  'spec_version': 1,
  'skill_id': 'G1',
  'construct_id': 'G1',
  'domain': 'A',
  'title_de': 'Generator-Test',
  'level_titles_de': ['Stufe 1', 'Stufe 2', 'Stufe 3'],
  'levels': [
    _level(1, 'enaktiv', 'place_counters', {
      'count_range': [1, 5],
      'frame': 'zehnerfeld',
      'action': 'fill',
    }, 9000),
    level2,
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

SkillSpec _sequenceSpec({
  String direction = 'up',
  int step = 1,
  List<int> startRange = const [5, 14],
  int length = 5,
  List<int> gapIndices = const [2],
  String? progression,
}) => SkillSpec.fromJson(
  _baseSpec(
    _level(2, 'symbolisch', 'sequence_gap', {
      'direction': direction,
      'step': step,
      'start_range': startRange,
      'length': length,
      'gap_indices': gapIndices,
      if (progression != null) 'progression': progression,
    }, 7000),
  ),
);

SkillSpec _compareSpec() => SkillSpec.fromJson(
  _baseSpec(
    _level(2, 'symbolisch', 'compare_symbols', {
      'a_range': [1, 10],
      'b_range': [1, 10],
      'zr': 10,
    }, 7000),
  ),
);

String _signature(List<Problem> problems) =>
    jsonEncode(problems.map((p) => p.toJson()).toList());

void main() {
  group('generateProblems harness', () {
    test('is deterministic: same seed produces an identical problem list', () {
      final spec = _sequenceSpec();
      final first = generateProblems(spec: spec, level: 2, seed: 42);
      final second = generateProblems(spec: spec, level: 2, seed: 42);
      expect(_signature(first), _signature(second));
    });

    test('is deterministic across 50 seeds', () {
      final specs = [
        _sequenceSpec(),
        _sequenceSpec(direction: 'down', startRange: [14, 18]),
        _compareSpec(),
      ];
      for (final spec in specs) {
        for (var seed = 0; seed < 50; seed++) {
          final a = generateProblems(spec: spec, level: 2, seed: seed);
          final b = generateProblems(spec: spec, level: 2, seed: seed);
          expect(_signature(a), _signature(b), reason: 'seed $seed');
        }
      }
    });

    test('produces exactly problem_count problems', () {
      for (final spec in [
        _sequenceSpec(),
        _sequenceSpec(direction: 'down', startRange: [14, 18]),
        _compareSpec(),
      ]) {
        for (var seed = 0; seed < 20; seed++) {
          final problems = generateProblems(spec: spec, level: 2, seed: seed);
          expect(problems, hasLength(spec.levels[1].problemCount));
          expect(problems.length, 8);
        }
      }
    });

    test('problems carry index, skillId, level and template', () {
      final spec = _compareSpec();
      final problems = generateProblems(spec: spec, level: 2, seed: 7);
      for (var i = 0; i < problems.length; i++) {
        expect(problems[i].index, i);
        expect(problems[i].skillId, 'G1');
        expect(problems[i].level, 2);
        expect(problems[i].seed, 7);
        expect(problems[i].template, 'compare_symbols');
      }
    });

    test('contains no duplicate problems within a level', () {
      for (final spec in [
        _sequenceSpec(),
        _sequenceSpec(direction: 'down', startRange: [12, 20]),
        _sequenceSpec(step: 2, startRange: [2, 20]),
        _compareSpec(),
      ]) {
        for (var seed = 0; seed < 20; seed++) {
          final problems = generateProblems(spec: spec, level: 2, seed: seed);
          final keys = problems.map((p) => jsonEncode(p.display)).toSet();
          expect(keys.length, problems.length, reason: 'seed $seed');
        }
      }
    });

    test('unimplemented templates throw UnimplementedError', () {
      final spec = SkillSpec.fromJson(
        _baseSpec(
          _level(2, 'symbolisch', 'equation_solve', {
            'op': '+',
            'unknown': 'result',
            'zr': 10,
            'a_range': [1, 5],
            'b_range': [1, 5],
            'mode': 'standard',
          }, 7000),
        ),
      );
      expect(
        () => generateProblems(spec: spec, level: 2, seed: 1),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  group('sequence_gap generator', () {
    test(
      'arithmetic up sequence: values increase by step and expected is exact',
      () {
        final spec = _sequenceSpec(
          direction: 'up',
          step: 1,
          startRange: [5, 14],
          length: 5,
          gapIndices: [2],
        );
        for (var seed = 0; seed < 100; seed++) {
          final problems = generateProblems(spec: spec, level: 2, seed: seed);
          for (final p in problems) {
            final values = (p.display['values'] as List).cast<int>();
            expect(values, hasLength(5));
            for (var i = 0; i < values.length - 1; i++) {
              expect(values[i + 1] - values[i], 1, reason: 'up by step 1');
            }
            expect(p.display['direction'], 'up');
            expect(p.display['step'], 1);
            expect(p.expected, [values[2].toString()]);
          }
        }
      },
    );

    test('step 2 up: values increase by 2', () {
      final spec = _sequenceSpec(
        direction: 'up',
        step: 2,
        startRange: [2, 10],
        length: 5,
        gapIndices: [1, 3],
      );
      for (var seed = 0; seed < 100; seed++) {
        final problems = generateProblems(spec: spec, level: 2, seed: seed);
        for (final p in problems) {
          final values = (p.display['values'] as List).cast<int>();
          for (var i = 0; i < values.length - 1; i++) {
            expect(values[i + 1] - values[i], 2, reason: 'up by step 2');
          }
          expect(p.expected, [values[1].toString(), values[3].toString()]);
        }
      }
    });

    test('down sequence: values decrease by step and never go below 1', () {
      final spec = _sequenceSpec(
        direction: 'down',
        step: 1,
        startRange: [14, 18],
        length: 5,
        gapIndices: [2],
      );
      for (var seed = 0; seed < 100; seed++) {
        final problems = generateProblems(spec: spec, level: 2, seed: seed);
        for (final p in problems) {
          final values = (p.display['values'] as List).cast<int>();
          for (var i = 0; i < values.length - 1; i++) {
            expect(values[i + 1] - values[i], -1, reason: 'down by step 1');
          }
          expect(values.last, greaterThanOrEqualTo(1));
          expect(p.display['direction'], 'down');
          expect(p.expected, [values[2].toString()]);
        }
      }
    });

    test('progression double: geometric doubling and step ignored', () {
      final spec = _sequenceSpec(
        direction: 'up',
        step: 5,
        startRange: [2, 3],
        length: 3,
        gapIndices: [1],
        progression: 'double',
      );
      for (var seed = 0; seed < 100; seed++) {
        final problems = generateProblems(spec: spec, level: 2, seed: seed);
        for (final p in problems) {
          final values = (p.display['values'] as List).cast<int>();
          expect(p.display['progression'], 'double');
          expect(values[1], values[0] * 2, reason: 'doubling, not step 5');
          expect(values[2], values[0] * 4);
          expect(p.expected, [values[1].toString()]);
        }
      }
    });

    test('ZR bounds: up sequences in ZR20 never exceed 20', () {
      final spec = _sequenceSpec(
        direction: 'up',
        step: 1,
        startRange: [5, 13],
        length: 8,
        gapIndices: [2, 5],
      );
      for (var seed = 0; seed < 100; seed++) {
        final problems = generateProblems(spec: spec, level: 2, seed: seed);
        for (final p in problems) {
          final values = (p.display['values'] as List).cast<int>();
          expect(values.last, lessThanOrEqualTo(20), reason: 'ZR20 boundary');
          expect(values.first, greaterThanOrEqualTo(5));
        }
      }
    });

    test('ZR bounds: up sequences in ZR100 never exceed 100', () {
      final spec = _sequenceSpec(
        direction: 'up',
        step: 1,
        startRange: [11, 92],
        length: 5,
        gapIndices: [0, 4],
      );
      for (var seed = 0; seed < 100; seed++) {
        final problems = generateProblems(spec: spec, level: 2, seed: seed);
        for (final p in problems) {
          final values = (p.display['values'] as List).cast<int>();
          expect(values.last, lessThanOrEqualTo(100));
        }
      }
    });

    test('gap indices never coincide with an out-of-range position', () {
      final spec = _sequenceSpec(
        direction: 'up',
        step: 1,
        startRange: [5, 14],
        length: 5,
        gapIndices: [0, 2, 4],
      );
      for (var seed = 0; seed < 100; seed++) {
        final problems = generateProblems(spec: spec, level: 2, seed: seed);
        for (final p in problems) {
          final values = (p.display['values'] as List).cast<int>();
          final gapIndices = (p.display['gap_indices'] as List).cast<int>();
          expect(
            p.expected,
            gapIndices.map((i) => values[i].toString()).toList(),
          );
        }
      }
    });
  });

  group('compare_symbols generator', () {
    test('expected operator always matches the true relation', () {
      final spec = _compareSpec();
      for (var seed = 0; seed < 200; seed++) {
        final problems = generateProblems(spec: spec, level: 2, seed: seed);
        for (final p in problems) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          final expected = a > b ? '>' : (a < b ? '<' : '=');
          expect(p.expected, [expected], reason: 'a=$a b=$b');
          expect(p.expected.single, anyOf('<', '>', '='));
        }
      }
    });

    test('values stay within the parameterised ranges', () {
      final spec = _compareSpec();
      for (var seed = 0; seed < 200; seed++) {
        final problems = generateProblems(spec: spec, level: 2, seed: seed);
        for (final p in problems) {
          expect(p.display['a'] as int, inInclusiveRange(1, 10));
          expect(p.display['b'] as int, inInclusiveRange(1, 10));
        }
      }
    });
  });

  group('Problem JSON round-trip', () {
    test('toJson/fromJson preserves every field', () {
      final spec = _compareSpec();
      final problems = generateProblems(spec: spec, level: 2, seed: 3);
      for (final p in problems) {
        final restored = Problem.fromJson(p.toJson());
        expect(restored.template, p.template);
        expect(restored.skillId, p.skillId);
        expect(restored.level, p.level);
        expect(restored.seed, p.seed);
        expect(restored.index, p.index);
        expect(restored.promptDe, p.promptDe);
        expect(jsonEncode(restored.display), jsonEncode(p.display));
        expect(restored.expected, p.expected);
      }
    });
  });
}
