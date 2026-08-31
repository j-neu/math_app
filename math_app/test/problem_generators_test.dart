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
          _level(2, 'symbolisch', 'strategy_choice', {
            'op': '+',
            'zr': 20,
            'a_range': [1, 5],
            'b_range': [1, 5],
            'strategies': [
              {'id': 'double', 'label_de': 'verdoppeln'},
              {'id': 'make_ten', 'label_de': 'zur vollen Zehn'},
            ],
            'correct_strategy': 'double',
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

  group('equation_solve generator', () {
    SkillSpec spec(Map<String, dynamic> params) => SkillSpec.fromJson(
      _baseSpec(_level(2, 'symbolisch', 'equation_solve', params, 6000)),
    );

    test('unknown=result op +: expected == a+b, result respects zr', () {
      final s = spec({
        'op': '+',
        'unknown': 'result',
        'zr': 20,
        'a_range': [2, 9],
        'b_range': [2, 9],
        'mode': 'standard',
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          final c = p.display['c'] as int;
          expect(c, a + b, reason: 'display c is the result');
          expect(p.expected, [c.toString()]);
          expect(c, lessThanOrEqualTo(20), reason: 'zr is the result bound');
        }
      }
    });

    test('unknown=result op -: never negative, a >= b, a==b gives result 0', () {
      final s = spec({
        'op': '-',
        'unknown': 'result',
        'zr': 20,
        'a_range': [2, 20],
        'b_range': [1, 10],
        'mode': 'standard',
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          expect(a, greaterThanOrEqualTo(b), reason: 'no negative result');
          expect(p.expected, [(a - b).toString()]);
        }
      }
      final fixed = spec({
        'op': '-',
        'unknown': 'result',
        'zr': 20,
        'a_range': [5, 5],
        'b_range': [5, 5],
        'mode': 'standard',
      });
      for (final p in generateProblems(spec: fixed, level: 2, seed: 3)) {
        expect(p.expected, ['0'], reason: 'subtract with a==b -> result 0');
      }
    });

    test('unknown=addend: _ + b = c with missing addend >= 1 and c <= zr', () {
      final s = spec({
        'op': '+',
        'unknown': 'addend',
        'zr': 20,
        'a_range': [1, 9],
        'b_range': [2, 9],
        'mode': 'standard',
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          final c = p.display['c'] as int;
          expect(a, greaterThanOrEqualTo(1), reason: 'addend >= 1');
          expect(a + b, c);
          expect(c, lessThanOrEqualTo(20), reason: 'result c <= zr');
          expect(p.expected, [a.toString()], reason: 'missing addend is a');
        }
      }
    });

    test('unknown=subtrahend: a - _ = c with 1 <= subtrahend <= a-1', () {
      final s = spec({
        'op': '-',
        'unknown': 'subtrahend',
        'zr': 20,
        'a_range': [5, 20],
        'b_range': [1, 9],
        'mode': 'standard',
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          final c = p.display['c'] as int;
          expect(a - b, c);
          expect(b, inInclusiveRange(1, a - 1));
          expect(p.expected, [b.toString()], reason: 'missing subtrahend is b');
        }
      }
    });

    test('unknown=minuend: _ - b = c with minuend c+b, boundary at zr', () {
      final s = spec({
        'op': '-',
        'unknown': 'minuend',
        'zr': 20,
        'a_range': [5, 20],
        'b_range': [1, 9],
        'mode': 'standard',
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          final c = p.display['c'] as int;
          expect(a, c + b, reason: 'minuend x = c + b');
          expect(c, greaterThanOrEqualTo(1));
          expect(a, lessThanOrEqualTo(20), reason: 'minuend <= zr');
          expect(p.expected, [a.toString()], reason: 'missing minuend is a');
        }
      }
      final atZr = spec({
        'op': '-',
        'unknown': 'minuend',
        'zr': 20,
        'a_range': [20, 20],
        'b_range': [1, 9],
        'mode': 'standard',
      });
      for (final p in generateProblems(spec: atZr, level: 2, seed: 5)) {
        expect(p.display['a'], 20, reason: 'minuend at zr');
        expect(p.expected, ['20']);
      }
    });

    test('equal:true forces a == b and expected is the double', () {
      final s = spec({
        'op': '+',
        'unknown': 'result',
        'zr': 20,
        'a_range': [2, 10],
        'b_range': [2, 10],
        'equal': true,
        'mode': 'standard',
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          expect(a, b, reason: 'equal forces a == b');
          expect(p.expected, [(2 * a).toString()]);
        }
      }
    });

    test('place_value mode op +: column-wise, expected == tens*10 + ones', () {
      final s = spec({
        'op': '+',
        'unknown': 'result',
        'zr': 100,
        'mode': 'place_value',
        'tens_range': [1, 4],
        'ones_range': [1, 4],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          final tens = p.display['tens'] as int;
          final ones = p.display['ones'] as int;
          expect(ones, lessThan(10), reason: 'no ones-column overstep');
          expect(tens, lessThan(10), reason: 'no tens-column overstep');
          expect(tens * 10 + ones, a + b);
          expect(p.expected, [(tens * 10 + ones).toString()]);
        }
      }
    });

    test('place_value mode op -: column-wise subtraction, never negative', () {
      final s = spec({
        'op': '-',
        'unknown': 'result',
        'zr': 100,
        'mode': 'place_value',
        'tens_range': [1, 9],
        'ones_range': [1, 9],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          final tens = p.display['tens'] as int;
          final ones = p.display['ones'] as int;
          expect(tens, greaterThanOrEqualTo(0));
          expect(ones, greaterThanOrEqualTo(0));
          expect(tens * 10 + ones, a - b);
          expect(p.expected, [(a - b).toString()]);
        }
      }
    });

    test('is deterministic and unique within a level', () {
      final s = spec({
        'op': '+',
        'unknown': 'addend',
        'zr': 100,
        'a_range': [21, 49],
        'b_range': [12, 39],
        'mode': 'standard',
      });
      for (var seed = 0; seed < 50; seed++) {
        final first = generateProblems(spec: s, level: 2, seed: seed);
        final second = generateProblems(spec: s, level: 2, seed: seed);
        expect(_signature(first), _signature(second));
        final keys = first.map((p) => jsonEncode(p.display)).toSet();
        expect(keys.length, first.length, reason: 'unique within a level');
      }
    });

    test('problems carry index, non-empty expected and prompt', () {
      final s = spec({
        'op': '+',
        'unknown': 'result',
        'zr': 20,
        'a_range': [2, 9],
        'b_range': [2, 9],
        'mode': 'standard',
      });
      final problems = generateProblems(spec: s, level: 2, seed: 11);
      for (var i = 0; i < problems.length; i++) {
        expect(problems[i].index, i);
        expect(problems[i].expected, isNotEmpty);
        expect(problems[i].promptDe, isNotEmpty);
        expect(problems[i].template, 'equation_solve');
      }
    });
  });

  group('equation_gap generator', () {
    SkillSpec spec(Map<String, dynamic> params) => SkillSpec.fromJson(
      _baseSpec(_level(2, 'symbolisch', 'equation_gap', params, 7000)),
    );

    test('form gap: a - b = _ with expected a-b and gap_after result', () {
      final s = spec({
        'op': '-',
        'form': 'gap',
        'zr': 20,
        'a_range': [5, 18],
        'b_range': [2, 9],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          expect(a, greaterThanOrEqualTo(b), reason: 'no negative result');
          expect(p.expected, [(a - b).toString()]);
          expect(p.display['gap_after'], 'result');
          expect(p.display['form'], 'gap');
        }
      }
    });

    test('form helper op + make_ten: a+b = 10+_, gap == a+b-10 >= 1', () {
      final s = spec({
        'op': '+',
        'form': 'helper',
        'zr': 20,
        'a_range': [8, 9],
        'b_range': [2, 9],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          final first = p.display['first'] as int;
          final gap = int.parse(p.expected.single);
          expect(first, 10, reason: 'volle Zehn');
          expect(gap, a + b - 10, reason: 'helper gap == a+b-10');
          expect(gap, greaterThanOrEqualTo(1));
          expect(first + gap, a + b, reason: 'whole equation holds');
          expect(p.display['gap_after'], 'right');
        }
      }
      final edge = spec({
        'op': '+',
        'form': 'helper',
        'zr': 20,
        'a_range': [9, 9],
        'b_range': [2, 2],
      });
      for (final p in generateProblems(spec: edge, level: 2, seed: 1)) {
        expect(p.expected, ['1'], reason: 'a+b-10 == 1 boundary');
      }
    });

    test('form helper op + tens_ones: a+b = (a+tens)+_, gap == b%10', () {
      final s = spec({
        'op': '+',
        'form': 'helper',
        'zr': 100,
        'a_range': [20, 49],
        'b_range': [12, 39],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          final first = p.display['first'] as int;
          final gap = int.parse(p.expected.single);
          expect(first, a + 10 * (b ~/ 10), reason: 'first is a + tens of b');
          expect(gap, b % 10);
          expect(gap, greaterThanOrEqualTo(1));
          expect(first + gap, a + b, reason: 'whole equation holds');
          expect(p.display['split'], 'tens_ones');
        }
      }
    });

    test('form helper op - make_ten: a-b = (a-ones)-_, rest >= 1', () {
      final s = spec({
        'op': '-',
        'form': 'helper',
        'zr': 100,
        'a_range': [23, 98],
        'b_range': [3, 9],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          final first = p.display['first'] as int;
          final gap = int.parse(p.expected.single);
          expect(first, a - a % 10, reason: 'first reaches the full ten');
          expect(gap, b - a % 10, reason: 'rest = b - ones of a');
          expect(gap, greaterThanOrEqualTo(1));
          expect(first - gap, a - b, reason: 'whole equation holds');
          expect(p.display['split'], 'make_ten');
        }
      }
    });

    test('form helper op - tens_ones: a-b = (a-tens)-_, gap == b%10', () {
      final s = spec({
        'op': '-',
        'form': 'helper',
        'zr': 100,
        'a_range': [40, 90],
        'b_range': [12, 39],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          final first = p.display['first'] as int;
          final gap = int.parse(p.expected.single);
          expect(first, a - 10 * (b ~/ 10), reason: 'first is a - tens of b');
          expect(gap, b % 10);
          expect(gap, greaterThanOrEqualTo(1));
          expect(first - gap, a - b, reason: 'whole equation holds');
          expect(p.display['split'], 'tens_ones');
        }
      }
    });

    test('form missing_addend: a + _ = c with expected c-a and c <= zr', () {
      final s = spec({
        'op': '+',
        'form': 'missing_addend',
        'zr': 20,
        'a_range': [5, 9],
        'b_range': [2, 9],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          final c = p.display['c'] as int;
          expect(c, a + b);
          expect(c, lessThanOrEqualTo(20));
          expect(p.expected, [(c - a).toString()]);
          expect(p.display['gap_after'], 'middle');
        }
      }
    });

    test('form any_split: expected lists all pairs i+(total-i)', () {
      final six = spec({
        'op': '+',
        'form': 'any_split',
        'zr': 10,
        'total_range': [6, 6],
      });
      for (final p in generateProblems(spec: six, level: 2, seed: 3)) {
        expect(p.display['total'], 6);
        expect(p.expected, ['1+5', '2+4', '3+3', '4+2', '5+1']);
      }
      final ten = spec({
        'op': '+',
        'form': 'any_split',
        'zr': 10,
        'total_range': [10, 10],
      });
      for (final p in generateProblems(spec: ten, level: 2, seed: 3)) {
        expect(p.expected, hasLength(9));
        expect(p.expected.first, '1+9');
        expect(p.expected.last, '9+1');
        for (final pair in p.expected) {
          final parts = pair.split('+').map(int.parse).toList();
          expect(parts[0] + parts[1], 10);
          expect(parts[0], inInclusiveRange(1, 9));
        }
      }
    });

    test('form place_value: expected == tens*10 + ones, ones may be >= 10', () {
      final s = spec({
        'op': '+',
        'form': 'place_value',
        'zr': 99,
        'tens_range': [1, 8],
        'ones_range': [10, 19],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final tens = p.display['tens'] as int;
          final ones = p.display['ones'] as int;
          expect(tens, inInclusiveRange(1, 8));
          expect(ones, inInclusiveRange(10, 19));
          expect(p.expected, [(tens * 10 + ones).toString()]);
          expect(tens * 10 + ones, lessThanOrEqualTo(99), reason: 'zr');
        }
      }
      final edge = spec({
        'op': '+',
        'form': 'place_value',
        'zr': 99,
        'tens_range': [2, 2],
        'ones_range': [19, 19],
      });
      for (final p in generateProblems(spec: edge, level: 2, seed: 1)) {
        expect(p.expected, ['39'], reason: '2 Zehner 19 Einer = 39');
      }
    });

    test('form half: total even, expected == total/2', () {
      final s = spec({
        'op': '+',
        'form': 'half',
        'zr': 20,
        'a_range': [2, 10],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final total = p.display['total'] as int;
          expect(total.isEven, isTrue);
          expect(total, lessThanOrEqualTo(20));
          expect(p.expected, [(total ~/ 2).toString()]);
          expect(int.parse(p.expected.single) * 2, total);
        }
      }
    });

    test('form double: expected == 2a and never exceeds zr', () {
      final s = spec({
        'op': '+',
        'form': 'double',
        'zr': 20,
        'a_range': [2, 10],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final a = p.display['a'] as int;
          expect(p.expected, [(2 * a).toString()]);
          expect(2 * a, lessThanOrEqualTo(20), reason: 'double <= zr');
        }
      }
    });

    test('form neighbor: expected == [n-1, n+1]', () {
      final s = spec({
        'op': '+',
        'form': 'neighbor',
        'zr': 20,
        'start_range': [2, 19],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final n = p.display['n'] as int;
          expect(n, inInclusiveRange(2, 19));
          expect(p.expected, [(n - 1).toString(), (n + 1).toString()]);
        }
      }
    });

    test('form helper_double: gap == (a+b)-2*min(a,b), 6+7 -> 1', () {
      final s = spec({
        'op': '+',
        'form': 'helper_double',
        'zr': 20,
        'a_range': [5, 9],
        'b_range': [6, 10],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          final first = p.display['first'] as int;
          final min = a < b ? a : b;
          final gap = int.parse(p.expected.single);
          expect(first, 2 * min, reason: 'Stützaufgabe is the double');
          expect(gap, a + b - 2 * min);
          expect(gap, greaterThanOrEqualTo(1), reason: 'a != b');
          expect(first + gap, a + b, reason: 'whole equation holds');
          expect(p.display['gap_after'], 'right');
        }
      }
      final edge = spec({
        'op': '+',
        'form': 'helper_double',
        'zr': 20,
        'a_range': [6, 6],
        'b_range': [7, 7],
      });
      for (final p in generateProblems(spec: edge, level: 2, seed: 1)) {
        expect(p.expected, ['1'], reason: '6+7 = 12+1');
      }
    });

    test('is deterministic and unique within a level', () {
      final s = spec({
        'op': '+',
        'form': 'helper',
        'zr': 20,
        'a_range': [8, 9],
        'b_range': [2, 9],
      });
      for (var seed = 0; seed < 50; seed++) {
        final first = generateProblems(spec: s, level: 2, seed: seed);
        final second = generateProblems(spec: s, level: 2, seed: seed);
        expect(_signature(first), _signature(second));
        final keys = first.map((p) => jsonEncode(p.display)).toSet();
        expect(keys.length, first.length, reason: 'unique within a level');
      }
    });

    test('problems carry index, non-empty expected and prompt', () {
      final s = spec({
        'op': '-',
        'form': 'gap',
        'zr': 20,
        'a_range': [5, 18],
        'b_range': [2, 9],
      });
      final problems = generateProblems(spec: s, level: 2, seed: 11);
      for (var i = 0; i < problems.length; i++) {
        expect(problems[i].index, i);
        expect(problems[i].expected, isNotEmpty);
        expect(problems[i].promptDe, isNotEmpty);
        expect(problems[i].template, 'equation_gap');
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
