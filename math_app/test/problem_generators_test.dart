import 'dart:convert';
import 'dart:io';

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

SkillSpec _wordSpec({
  String op = '+',
  int zr = 10,
  bool askOperation = false,
}) => SkillSpec.fromJson(
  _baseSpec(
    _level(2, 'symbolisch', 'word_problem', {
      'contexts': [
        {'setting_de': 'im Korb', 'object_de': 'Äpfel'},
        {'setting_de': 'auf dem Tisch', 'object_de': 'Kekse'},
        {'setting_de': 'im Garten', 'object_de': 'Tomaten'},
        {'setting_de': 'am Teich', 'object_de': 'Enten'},
      ],
      'op': op,
      'zr': zr,
      'ask_operation': askOperation,
    }, 7000),
  ),
);

const List<Map<String, String>> _c41Strategies = [
  {'id': 'verdoppeln', 'label_de': 'Verdoppeln'},
  {'id': 'fast_verdoppeln', 'label_de': 'Fast verdoppeln'},
  {'id': 'ueber_die_zehn', 'label_de': 'Über die Zehn'},
];

SkillSpec _strategySpec({
  String correctStrategy = 'verdoppeln',
  int zr = 20,
  List<int> aRange = const [2, 10],
  List<int> bRange = const [2, 10],
  String op = '+',
}) => SkillSpec.fromJson(
  _baseSpec(
    _level(2, 'symbolisch', 'strategy_choice', {
      'op': op,
      'zr': zr,
      'a_range': aRange,
      'b_range': bRange,
      'strategies': _c41Strategies,
      'correct_strategy': correctStrategy,
    }, 7000),
  ),
);

/// Loads a real skill spec straight from the clean-room source tree, so the
/// generators are verified against exactly what the sync script ships.
SkillSpec _realSpec(String id) => SkillSpec.fromJson(
  jsonDecode(File('../docs/clean-room/skills/specs/$id.json').readAsStringSync())
      as Map<String, dynamic>,
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
          _level(2, 'ikonisch', 'custom_widget', {
            'count_range': [1, 5],
            'flash_ms': 800,
            'display': 'dots',
          }, 9000, customWidget: 'flash_subitize'),
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

  group('word_problem generator', () {
    test('plus: result == a+b, both numbers >= 2, sum stays in ZR', () {
      final s = _wordSpec(op: '+', zr: 10);
      for (var seed = 0; seed < 100; seed++) {
        final problems = generateProblems(spec: s, level: 2, seed: seed);
        for (final p in problems) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          expect(p.display['op'], '+');
          expect(a, greaterThanOrEqualTo(2));
          expect(b, greaterThanOrEqualTo(2));
          expect(a + b, lessThanOrEqualTo(10), reason: 'story stays in ZR10');
          expect(p.expected, [(a + b).toString()], reason: 'expected == result');
        }
      }
    });

    test('minus: result == a-b >= 0 and a >= b', () {
      final s = _wordSpec(op: '-', zr: 20);
      for (var seed = 0; seed < 100; seed++) {
        final problems = generateProblems(spec: s, level: 2, seed: seed);
        for (final p in problems) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          expect(p.display['op'], '-');
          expect(a, greaterThanOrEqualTo(b), reason: 'no negative result');
          expect(a - b, greaterThanOrEqualTo(0));
          expect(p.expected, [(a - b).toString()]);
        }
      }
    });

    test('prompt_de is a complete grammatical German story sentence', () {
      final s = _wordSpec(op: '+', zr: 10);
      for (var seed = 0; seed < 100; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final setting = p.display['setting_de'] as String;
          final object = p.display['object_de'] as String;
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          final prompt = p.promptDe;
          expect(prompt, isNotEmpty);
          expect(prompt, startsWith(setting[0].toUpperCase()));
          expect(prompt, contains('$a $object'));
          expect(prompt, contains('$b kommen dazu'));
          expect(prompt, endsWith('Wie viele sind es?'));
        }
      }
      final minus = _wordSpec(op: '-', zr: 20);
      final p = generateProblems(spec: minus, level: 2, seed: 3).first;
      expect(p.promptDe, contains('weggenommen'));
    });

    test('op "+|-" re-rolls the operation per problem and honours its '
        'constraints', () {
      final s = _wordSpec(op: '+|-', zr: 10, askOperation: true);
      for (var seed = 0; seed < 100; seed++) {
        final problems = generateProblems(spec: s, level: 2, seed: seed);
        for (final p in problems) {
          final op = p.display['op'] as String;
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          expect(op, anyOf('+', '-'));
          expect(p.display['ask_operation'], isTrue);
          if (op == '-') {
            expect(a, greaterThanOrEqualTo(b));
            expect(a - b, greaterThanOrEqualTo(0));
            expect(p.expected, [(a - b).toString()]);
          } else {
            expect(a + b, lessThanOrEqualTo(10));
            expect(p.expected, [(a + b).toString()]);
          }
        }
      }
    });

    test('op "+|-" actually produces both operations in one level', () {
      final s = _wordSpec(op: '+|-', zr: 20);
      var sawBoth = false;
      for (var seed = 0; seed < 50 && !sawBoth; seed++) {
        final ops = generateProblems(
          spec: s,
          level: 2,
          seed: seed,
        ).map((p) => p.display['op'] as String).toSet();
        sawBoth = ops.contains('+') && ops.contains('-');
      }
      expect(sawBoth, isTrue,
          reason: 'the operation must be re-rolled, not fixed');
    });

    test('no two problems share the same (setting, object, a, b, op) tuple', () {
      for (final s in [_wordSpec(op: '+', zr: 10), _wordSpec(op: '+|-', zr: 20)]) {
        for (var seed = 0; seed < 50; seed++) {
          final problems = generateProblems(spec: s, level: 2, seed: seed);
          final keys = problems.map((p) => jsonEncode(p.display)).toSet();
          expect(keys.length, problems.length, reason: 'seed $seed');
        }
      }
    });

    test('is deterministic and yields exactly problem_count problems', () {
      for (final s in [_wordSpec(op: '+', zr: 10), _wordSpec(op: '-', zr: 20)]) {
        for (var seed = 0; seed < 50; seed++) {
          final first = generateProblems(spec: s, level: 2, seed: seed);
          final second = generateProblems(spec: s, level: 2, seed: seed);
          expect(_signature(first), _signature(second));
          expect(first, hasLength(8));
        }
      }
    });

    test('real D1.1 levels 1-3 generate valid stories in their ZR', () {
      final spec = _realSpec('D1.1');
      final expectedOp = ['+', '-', '+'];
      final zr = [10, 20, 100];
      for (var level = 1; level <= 3; level++) {
        for (var seed = 0; seed < 20; seed++) {
          final problems = generateProblems(spec: spec, level: level, seed: seed);
          for (final p in problems) {
            final a = p.display['a'] as int;
            final b = p.display['b'] as int;
            final op = p.display['op'] as String;
            expect(op, expectedOp[level - 1]);
            if (op == '-') {
              expect(a, greaterThanOrEqualTo(b));
              expect(p.expected, [(a - b).toString()]);
            } else {
              expect(a + b, lessThanOrEqualTo(zr[level - 1]));
              expect(p.expected, [(a + b).toString()]);
            }
            expect(p.promptDe, contains('Wie viele sind es?'));
          }
        }
      }
    });

    test('real D1.2 levels re-roll the operation and ask for it first', () {
      final spec = _realSpec('D1.2');
      final zr = [10, 20, 100];
      for (var level = 1; level <= 3; level++) {
        final levelSpec = spec.levelSpec(level);
        expect(levelSpec.boolParam('ask_operation'), isTrue,
            reason: 'D1.2 L$level asks for the operation');
        for (var seed = 0; seed < 20; seed++) {
          final problems = generateProblems(spec: spec, level: level, seed: seed);
          for (final p in problems) {
            final op = p.display['op'] as String;
            final a = p.display['a'] as int;
            final b = p.display['b'] as int;
            expect(op, anyOf('+', '-'));
            expect(p.display['ask_operation'], isTrue);
            if (op == '-') {
              expect(a, greaterThanOrEqualTo(b), reason: 'minus never negative');
              expect(p.expected, [(a - b).toString()]);
            } else {
              expect(a + b, lessThanOrEqualTo(zr[level - 1]));
              expect(p.expected, [(a + b).toString()]);
            }
          }
        }
      }
    });

    test('hand-computed minus story keeps result >= 0 (here exactly 0)', () {
      final spec = _realSpec('D1.1');
      final problems = generateProblems(spec: spec, level: 2, seed: 5);
      final p = problems[5];
      expect(p.display['a'], 17);
      expect(p.display['b'], 17);
      expect(p.display['op'], '-');
      expect(p.expected, ['0'], reason: '17 - 17 = 0, non-negative');
      expect(
        p.promptDe,
        'In der Pausentasche sind 17 Mandarinen. 17 werden weggenommen. '
        'Wie viele sind es?',
      );
    });

    test('hand-computed op "+|-" re-rolls the sign within one level', () {
      final spec = _realSpec('D1.2');
      final problems = generateProblems(spec: spec, level: 1, seed: 7);
      final ops = problems.map((p) => p.display['op']).toList();
      expect(ops, ['+', '+', '-', '+', '-', '+', '+', '-']);
      for (var i = 0; i < problems.length; i++) {
        final p = problems[i];
        final a = p.display['a'] as int;
        final b = p.display['b'] as int;
        expect(p.expected, [(p.display['op'] == '-' ? a - b : a + b).toString()]);
      }
      expect(int.parse(problems[2].expected.single), 7, reason: '10 - 3 = 7');
      expect(int.parse(problems[4].expected.single), 2, reason: '5 - 3 = 2');
      expect(int.parse(problems[7].expected.single), 2, reason: '4 - 2 = 2');
    });
  });

  group('strategy_choice generator', () {
    test('verdoppeln: a == b and expected == 2a within ZR20', () {
      final s = _strategySpec(correctStrategy: 'verdoppeln', zr: 20);
      for (var seed = 0; seed < 100; seed++) {
        final problems = generateProblems(spec: s, level: 2, seed: seed);
        for (final p in problems) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          expect(a, b, reason: 'verdoppeln must use equal addends');
          expect(2 * a, lessThanOrEqualTo(20), reason: 'ZR20');
          expect(p.expected, [(2 * a).toString()]);
          expect(p.display['correct_strategy'], 'verdoppeln');
        }
      }
    });

    test('fast_verdoppeln: |a - b| == 1 (near-doubles)', () {
      final s = _strategySpec(
        correctStrategy: 'fast_verdoppeln',
        zr: 20,
      );
      for (var seed = 0; seed < 100; seed++) {
        final problems = generateProblems(spec: s, level: 2, seed: seed);
        for (final p in problems) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          expect((a - b).abs(), 1, reason: 'fast_verdoppeln needs neighbours');
          expect(a + b, lessThanOrEqualTo(20), reason: 'ZR20');
          expect(p.expected, [(a + b).toString()]);
        }
      }
    });

    test('ueber_die_zehn: ones cross a ten and it is not a double', () {
      final s = _strategySpec(
        correctStrategy: 'ueber_die_zehn',
        zr: 100,
        aRange: [21, 48],
        bRange: [12, 39],
      );
      for (var seed = 0; seed < 100; seed++) {
        final problems = generateProblems(spec: s, level: 2, seed: seed);
        for (final p in problems) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          expect(
            (a % 10) + (b % 10),
            greaterThanOrEqualTo(10),
            reason: 'ones must cross the ten (a=$a b=$b)',
          );
          expect(a, isNot(b), reason: 'not a plain double');
          expect((a - b).abs(), greaterThan(1), reason: 'not a near-double');
          expect(a + b, lessThanOrEqualTo(100), reason: 'ZR100');
          expect(p.expected, [(a + b).toString()]);
        }
      }
    });

    test('mixed: strategies vary and every problem exemplifies its own', () {
      final s = _strategySpec(
        correctStrategy: 'mixed',
        zr: 100,
        aRange: [12, 48],
        bRange: [12, 48],
      );
      for (var seed = 0; seed < 100; seed++) {
        final problems = generateProblems(spec: s, level: 2, seed: seed);
        final used = problems
            .map((p) => p.display['correct_strategy'] as String)
            .toSet();
        expect(
          used.length,
          greaterThanOrEqualTo(2),
          reason: 'a mixed level must vary its strategy',
        );
        for (final p in problems) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          final strategy = p.display['correct_strategy'] as String;
          switch (strategy) {
            case 'verdoppeln':
              expect(a, b, reason: 'verdoppeln problem must use a == b');
            case 'fast_verdoppeln':
              expect((a - b).abs(), 1);
            case 'ueber_die_zehn':
              expect((a % 10) + (b % 10), greaterThanOrEqualTo(10));
              expect((a - b).abs(), greaterThan(1));
            default:
              fail('unknown strategy "$strategy"');
          }
          expect(a + b, lessThanOrEqualTo(100), reason: 'ZR100');
          expect(p.expected, [(a + b).toString()]);
        }
      }
    });

    test('display carries op, a, b, strategies with labels and the correct '
        'strategy', () {
      final s = _strategySpec(correctStrategy: 'verdoppeln', zr: 20);
      final p = generateProblems(spec: s, level: 2, seed: 1).first;
      expect(p.display['op'], '+');
      expect(p.display['a'], isA<int>());
      expect(p.display['b'], isA<int>());
      final strategies = p.display['strategies'] as List;
      expect(strategies, hasLength(3));
      for (final entry in strategies) {
        final map = entry as Map;
        expect(map['id'], isA<String>());
        expect(map['label_de'], isA<String>());
        expect((map['label_de'] as String).isNotEmpty, isTrue);
      }
      expect(p.display['correct_strategy'], 'verdoppeln');
      expect(p.expected, isNotEmpty);
      expect(p.promptDe, isNotEmpty);
    });

    test('expected == a op b for every strategy', () {
      for (final strategy in ['verdoppeln', 'fast_verdoppeln', 'ueber_die_zehn']) {
        final s = _strategySpec(
          correctStrategy: strategy,
          zr: 100,
          aRange: [12, 48],
          bRange: [12, 48],
        );
        for (var seed = 0; seed < 50; seed++) {
          for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
            final a = p.display['a'] as int;
            final b = p.display['b'] as int;
            expect(p.expected, [(a + b).toString()], reason: strategy);
          }
        }
      }
    });

    test('is deterministic and unique within a level', () {
      for (final strategy in ['verdoppeln', 'mixed']) {
        final s = _strategySpec(correctStrategy: strategy, zr: 20);
        for (var seed = 0; seed < 50; seed++) {
          final first = generateProblems(spec: s, level: 2, seed: seed);
          final second = generateProblems(spec: s, level: 2, seed: seed);
          expect(_signature(first), _signature(second), reason: strategy);
          final keys = first.map((p) => jsonEncode(p.display)).toSet();
          expect(keys.length, first.length, reason: '$strategy seed $seed');
        }
      }
    });

    test('real C4.1 levels: ZR20 L1, ZR100 L2/L3 with strategy constraints', () {
      final spec = _realSpec('C4.1');
      final expectations = [
        ('verdoppeln', 20),
        ('ueber_die_zehn', 100),
        ('mixed', 100),
      ];
      for (var level = 1; level <= 3; level++) {
        final (expectedDirective, zr) = expectations[level - 1];
        final levelSpec = spec.levelSpec(level);
        expect(levelSpec.stringParam('correct_strategy'), expectedDirective,
            reason: 'C4.1 L$level directive');
        for (var seed = 0; seed < 20; seed++) {
          final problems = generateProblems(spec: spec, level: level, seed: seed);
          for (final p in problems) {
            final a = p.display['a'] as int;
            final b = p.display['b'] as int;
            final strategy = p.display['correct_strategy'] as String;
            final ids = (p.display['strategies'] as List)
                .map((e) => (e as Map)['id'])
                .toSet();
            expect(ids, contains(strategy));
            expect(a + b, lessThanOrEqualTo(zr), reason: 'C4.1 L$level ZR');
            expect(p.expected, [(a + b).toString()]);
            switch (strategy) {
              case 'verdoppeln':
                expect(a, b);
              case 'fast_verdoppeln':
                expect((a - b).abs(), 1);
              case 'ueber_die_zehn':
                expect((a % 10) + (b % 10), greaterThanOrEqualTo(10));
                expect((a - b).abs(), greaterThan(1));
              default:
                fail('unknown strategy "$strategy"');
            }
          }
        }
        if (expectedDirective == 'mixed') {
          final ops = generateProblems(spec: spec, level: 3, seed: 1)
              .map((p) => p.display['correct_strategy'] as String)
              .toSet();
          expect(ops.length, greaterThanOrEqualTo(2),
              reason: 'C4.1 L3 must vary its strategies');
        }
      }
    });

    test('an unknown correct_strategy is a spec error', () {
      final s = _strategySpec(correctStrategy: 'bogus');
      expect(
        () => generateProblems(spec: s, level: 2, seed: 1),
        throwsA(isA<SpecFormatException>()),
      );
    });

    test('hand-computed C4.1 L1: every problem is a genuine double', () {
      final spec = _realSpec('C4.1');
      final problems = generateProblems(spec: spec, level: 1, seed: 7);
      // i0: 9 + 9 -> 18 (verdoppeln)      i1: 10 + 10 -> 20
      // i2: 7 + 7 -> 14                   i3: 2 + 2 -> 4
      final expected = [
        (9, 9, 18),
        (10, 10, 20),
        (7, 7, 14),
        (2, 2, 4),
      ];
      for (var i = 0; i < expected.length; i++) {
        final p = problems[i];
        expect(p.display['a'], expected[i].$1, reason: 'i$i a');
        expect(p.display['b'], expected[i].$2, reason: 'i$i b');
        expect(p.display['correct_strategy'], 'verdoppeln');
        expect(p.expected, [expected[i].$3.toString()], reason: 'i$i result');
      }
      for (final p in problems) {
        expect(p.display['a'], p.display['b'], reason: 'all doubles');
        expect((p.display['a'] as int) * 2, int.parse(p.expected.single));
      }
    });

    test('hand-computed C4.1 L2: ones cross a ten on every problem', () {
      final spec = _realSpec('C4.1');
      final problems = generateProblems(spec: spec, level: 2, seed: 7);
      // i0: 47 + 38 -> 85 (ones 7 + 8 = 15 > 10)
      // i1: 35 + 39 -> 74 (ones 5 + 9 = 14 > 10)
      // i3: 44 + 38 -> 82 (ones 4 + 8 = 12 > 10)
      final p0 = problems[0];
      expect(p0.display['a'], 47);
      expect(p0.display['b'], 38);
      expect(p0.display['correct_strategy'], 'ueber_die_zehn');
      expect(p0.expected, ['85']);
      for (final p in problems) {
        final a = p.display['a'] as int;
        final b = p.display['b'] as int;
        expect((a % 10) + (b % 10), greaterThanOrEqualTo(10));
        expect(a + b, int.parse(p.expected.single));
      }
    });

    test('hand-computed C4.1 L3 mixed: strategies rotate and fit the numbers',
        () {
      final spec = _realSpec('C4.1');
      final problems = generateProblems(spec: spec, level: 3, seed: 7);
      // Rotation index % 3: 0 verdoppeln, 1 fast_verdoppeln, 2 ueber_die_zehn.
      // i0: 47+47=94 (verdoppeln)  i1: 29+30=59 (fast)  i2: 19+27=46 (ueber)
      final p0 = problems[0];
      expect(p0.display['a'], 47);
      expect(p0.display['b'], 47);
      expect(p0.display['correct_strategy'], 'verdoppeln');
      expect(p0.expected, ['94']);
      final p1 = problems[1];
      expect(p1.display['a'], 29);
      expect(p1.display['b'], 30);
      expect(p1.display['correct_strategy'], 'fast_verdoppeln');
      expect(p1.expected, ['59']);
      final p2 = problems[2];
      expect(p2.display['a'], 19);
      expect(p2.display['b'], 27);
      expect(p2.display['correct_strategy'], 'ueber_die_zehn');
      expect(p2.expected, ['46']);
      final strategies = problems.map((p) => p.display['correct_strategy']).toSet();
      expect(strategies, {'verdoppeln', 'fast_verdoppeln', 'ueber_die_zehn'});
    });
  });

  group('drag_partition generator', () {
    SkillSpec spec(Map<String, dynamic> params) => SkillSpec.fromJson(
      _baseSpec(_level(2, 'enaktiv', 'drag_partition', params, 9000)),
    );

    test('sum (default): positive boxes summing to total, expected empty', () {
      final s = spec({
        'total_range': [6, 10],
        'parts': 2,
        'box_labels': ['Teil 1', 'Teil 2'],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final total = p.display['total'] as int;
          final boxes = (p.display['boxes'] as List).cast<int>();
          expect(total, inInclusiveRange(6, 10));
          expect(boxes, hasLength(2));
          expect(boxes.reduce((a, b) => a + b), total);
          expect(boxes.every((b) => b >= 1), isTrue);
          expect(p.display['split_constraint'], 'sum');
          expect(p.display['parts'], 2);
          expect(p.display['box_labels'], ['Teil 1', 'Teil 2']);
          expect(p.expected, isEmpty, reason: 'widget evaluates semantically');
        }
      }
    });

    test('sum with 3 boxes keeps every part >= 1 (no empty Kasten)', () {
      final s = spec({
        'total_range': [6, 10],
        'parts': 3,
        'box_labels': ['Teil 1', 'Teil 2', 'Teil 3'],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final total = p.display['total'] as int;
          final boxes = (p.display['boxes'] as List).cast<int>();
          expect(boxes, hasLength(3));
          expect(boxes.reduce((a, b) => a + b), total);
          expect(boxes.every((b) => b >= 1), isTrue);
        }
      }
    });

    test('equal: even totals split in two equal halves (A3.3/C1.2/C1.3)', () {
      final s = spec({
        'total_range': [2, 20],
        'parts': 2,
        'equal': true,
        'box_labels': ['Teil 1', 'Teil 2'],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final total = p.display['total'] as int;
          final boxes = (p.display['boxes'] as List).cast<int>();
          expect(total.isEven, isTrue, reason: 'equal needs even totals');
          expect(boxes, [total ~/ 2, total ~/ 2]);
          expect(p.display['split_constraint'], 'equal');
        }
      }
    });

    test('equal via split_constraint string works the same', () {
      final s = spec({
        'total_range': [2, 10],
        'parts': 2,
        'split_constraint': 'equal',
        'box_labels': ['Teil 1', 'Teil 2'],
      });
      for (var seed = 0; seed < 100; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final total = p.display['total'] as int;
          final boxes = (p.display['boxes'] as List).cast<int>();
          expect(total.isEven, isTrue);
          expect(boxes, [total ~/ 2, total ~/ 2]);
        }
      }
    });

    test('make_ten: totals 11..19 and exactly 10 + (total-10)', () {
      final s = spec({
        'total_range': [11, 19],
        'parts': 2,
        'split_constraint': 'make_ten',
        'box_labels': ['volle Zehn', 'Rest'],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final total = p.display['total'] as int;
          final boxes = (p.display['boxes'] as List).cast<int>();
          expect(total, inInclusiveRange(11, 19));
          final sorted = [...boxes]..sort();
          expect(sorted, [10, total - 10]..sort(),
              reason: 'a wrong split like 15=9+6 must never be emitted');
        }
      }
    });

    test('near_double: odd totals 11..19, boxes [n, n, 1] (7+7+1=15)', () {
      final s = spec({
        'total_range': [11, 19],
        'parts': 3,
        'split_constraint': 'near_double',
        'box_labels': ['Verdopplung', 'Verdopplung', '1 dazu'],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final total = p.display['total'] as int;
          final boxes = (p.display['boxes'] as List).cast<int>();
          expect(total.isOdd, isTrue, reason: 'near_double totals are odd');
          expect(total, inInclusiveRange(11, 19));
          final n = (total - 1) ~/ 2;
          expect(boxes, [n, n, 1]);
          expect(boxes.reduce((a, b) => a + b), total);
          expect(boxes.reduce((a, b) => a + b), 2 * n + 1);
        }
      }
    });

    test('tens_ones: boxes [a, 10*(b~/10), b%10] with a+b == total', () {
      final s = spec({
        'total_range': [30, 99],
        'parts': 3,
        'split_constraint': 'tens_ones',
        'box_labels': ['1. Summand', 'Zehner', 'Einer'],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final total = p.display['total'] as int;
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          final boxes = (p.display['boxes'] as List).cast<int>();
          expect(total, inInclusiveRange(30, 99));
          expect(a, greaterThanOrEqualTo(1));
          expect(b, greaterThanOrEqualTo(11), reason: 'Zehner box >= 1');
          expect(b % 10, greaterThanOrEqualTo(1), reason: 'Einer box >= 1');
          expect(a + b, total);
          expect(boxes, [a, 10 * (b ~/ 10), b % 10]);
        }
      }
    });

    test('hand-computed tens_ones example 35 + 27 -> [35, 20, 7]', () {
      final spec = _realSpec('C3.4a');
      final problems = generateProblems(spec: spec, level: 1, seed: 369);
      final p = problems[6];
      expect(p.display['total'], 62);
      expect(p.display['a'], 35);
      expect(p.display['b'], 27);
      expect(p.display['boxes'], [35, 20, 7]);
      expect(p.display['split_constraint'], 'tens_ones');
      expect(p.expected, isEmpty);
    });

    test('is deterministic and unique within a level where the range allows', () {
      for (final s in [
        spec({
          'total_range': [6, 10],
          'parts': 2,
          'box_labels': ['Teil 1', 'Teil 2'],
        }),
        spec({
          'total_range': [11, 19],
          'parts': 2,
          'split_constraint': 'make_ten',
          'box_labels': ['volle Zehn', 'Rest'],
        }),
      ]) {
        for (var seed = 0; seed < 50; seed++) {
          final first = generateProblems(spec: s, level: 2, seed: seed);
          final second = generateProblems(spec: s, level: 2, seed: seed);
          expect(_signature(first), _signature(second));
          final keys = first.map((p) => jsonEncode(p.display)).toSet();
          expect(keys.length, first.length, reason: 'seed $seed');
        }
      }
    });

    test('hand-computed real C2.1 L1: every split is a full ten + rest', () {
      final spec = _realSpec('C2.1');
      for (var seed = 0; seed < 20; seed++) {
        for (final p in generateProblems(spec: spec, level: 1, seed: seed)) {
          final total = p.display['total'] as int;
          final boxes = (p.display['boxes'] as List).cast<int>();
          expect(total, inInclusiveRange(11, 19));
          final sorted = [...boxes]..sort();
          expect(sorted, [10, total - 10]..sort());
        }
      }
    });
  });

  group('place_counters generator', () {
    SkillSpec spec(Map<String, dynamic> params) => SkillSpec.fromJson(
      _baseSpec(_level(2, 'enaktiv', 'place_counters', params, 9000)),
    );

    test('fill: count in range, frame/action carried, expected == count', () {
      final s = spec({
        'count_range': [1, 10],
        'frame': 'zehnerfeld',
        'action': 'fill',
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final count = p.display['count'] as int;
          expect(count, inInclusiveRange(1, 10));
          expect(p.display['frame'], 'zehnerfeld');
          expect(p.display['action'], 'fill');
          expect(p.expected, [count.toString()]);
        }
      }
    });

    test('zehnerfeld capacity: count never exceeds 10 per frame', () {
      final s = spec({
        'count_range': [1, 20],
        'frame': 'zehnerfeld',
        'action': 'fill',
      });
      for (var seed = 0; seed < 100; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          expect(p.display['count'] as int, inInclusiveRange(1, 10));
        }
      }
    });

    test('take_away: total >= count and remaining >= 0', () {
      final s = spec({
        'count_range': [2, 10],
        'frame': 'zehnerfeld',
        'action': 'take_away',
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final count = p.display['count'] as int;
          final total = p.display['total'] as int;
          final remaining = p.display['remaining'] as int;
          expect(count, inInclusiveRange(2, 10));
          expect(total, greaterThanOrEqualTo(count));
          expect(remaining, total - count);
          expect(remaining, greaterThanOrEqualTo(0));
          expect(p.display['action'], 'take_away');
          expect(p.expected, [count.toString()]);
        }
      }
    });

    test('rekenrek frame allows counts up to 20', () {
      final s = spec({
        'count_range': [1, 20],
        'frame': 'rekenrek',
        'action': 'fill',
      });
      for (var seed = 0; seed < 100; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          expect(p.display['count'] as int, inInclusiveRange(1, 20));
          expect(p.display['frame'], 'rekenrek');
        }
      }
    });

    test('stellenwerttafel allows two-digit counts (B2.1/C3.1)', () {
      final s = spec({
        'count_range': [11, 99],
        'frame': 'stellenwerttafel',
        'action': 'fill',
      });
      for (var seed = 0; seed < 100; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          expect(p.display['count'] as int, inInclusiveRange(11, 99));
          expect(p.display['frame'], 'stellenwerttafel');
        }
      }
    });

    test('is deterministic and unique within a level', () {
      for (final s in [
        spec({
          'count_range': [1, 10],
          'frame': 'zehnerfeld',
          'action': 'fill',
        }),
        spec({
          'count_range': [2, 10],
          'frame': 'zehnerfeld',
          'action': 'take_away',
        }),
      ]) {
        for (var seed = 0; seed < 50; seed++) {
          final first = generateProblems(spec: s, level: 2, seed: seed);
          final second = generateProblems(spec: s, level: 2, seed: seed);
          expect(_signature(first), _signature(second));
          final keys = first.map((p) => jsonEncode(p.display)).toSet();
          expect(keys.length, first.length, reason: 'seed $seed');
        }
      }
    });
  });

  group('bundle_sticks generator', () {
    SkillSpec spec(Map<String, dynamic> params) => SkillSpec.fromJson(
      _baseSpec(_level(2, 'enaktiv', 'bundle_sticks', params, 9000)),
    );

    test('count in range and canonical Z Zehner, E Einer answer', () {
      final s = spec({
        'count_range': [12, 39],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final count = p.display['count'] as int;
          expect(count, inInclusiveRange(12, 39));
          final bundles = count ~/ 10;
          final singles = count % 10;
          expect(p.display['bundles'], bundles);
          expect(p.display['singles'], singles);
          expect(bundles, greaterThanOrEqualTo(1),
              reason: 'count >= 10 requires at least one bundle');
          expect(p.expected, ['$bundles Zehner, $singles Einer']);
        }
      }
    });

    test('39 sticks -> 3 Zehner, 9 Einer', () {
      final s = spec({
        'count_range': [39, 39],
      });
      for (final p in generateProblems(spec: s, level: 2, seed: 1)) {
        expect(p.display['count'], 39);
        expect(p.display['bundles'], 3);
        expect(p.display['singles'], 9);
        expect(p.expected, ['3 Zehner, 9 Einer']);
      }
    });

    test('never generates counts < 12 (bundling needs >= 1 bundle)', () {
      final s = spec({
        'count_range': [12, 39],
      });
      for (var seed = 0; seed < 100; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          expect(p.display['count'] as int, greaterThanOrEqualTo(12));
        }
      }
    });

    test('a count_range below 12 is a spec error', () {
      final s = spec({
        'count_range': [5, 9],
      });
      expect(
        () => generateProblems(spec: s, level: 2, seed: 1),
        throwsA(isA<SpecFormatException>()),
      );
    });

    test('is deterministic and unique within a level', () {
      final s = spec({
        'count_range': [12, 39],
      });
      for (var seed = 0; seed < 50; seed++) {
        final first = generateProblems(spec: s, level: 2, seed: seed);
        final second = generateProblems(spec: s, level: 2, seed: seed);
        expect(_signature(first), _signature(second));
        final keys = first.map((p) => jsonEncode(p.display)).toSet();
        expect(keys.length, first.length, reason: 'seed $seed');
      }
    });
  });

  group('rekenrek_set generator', () {
    SkillSpec spec(Map<String, dynamic> params) => SkillSpec.fromJson(
      _baseSpec(_level(2, 'enaktiv', 'rekenrek_set', params, 9000)),
    );

    test('count in 1..20, rows carried, expected == count', () {
      final s = spec({
        'count_range': [1, 20],
        'rows': 2,
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final count = p.display['count'] as int;
          expect(count, inInclusiveRange(1, 20));
          expect(p.display['rows'], 2);
          expect(p.expected, [count.toString()]);
        }
      }
    });

    test('20 beads reproduce 20', () {
      final s = spec({
        'count_range': [20, 20],
        'rows': 2,
      });
      for (final p in generateProblems(spec: s, level: 2, seed: 1)) {
        expect(p.display['count'], 20);
        expect(p.expected, ['20']);
      }
    });

    test('is deterministic and unique within a level', () {
      final s = spec({
        'count_range': [1, 20],
        'rows': 2,
      });
      for (var seed = 0; seed < 50; seed++) {
        final first = generateProblems(spec: s, level: 2, seed: seed);
        final second = generateProblems(spec: s, level: 2, seed: seed);
        expect(_signature(first), _signature(second));
        final keys = first.map((p) => jsonEncode(p.display)).toSet();
        expect(keys.length, first.length, reason: 'seed $seed');
      }
    });
  });

  group('numberline_step generator', () {
    SkillSpec spec(Map<String, dynamic> params) => SkillSpec.fromJson(
      _baseSpec(_level(2, 'enaktiv', 'numberline_step', params, 9000)),
    );

    List<int> tapped(Problem p) => p.expected.map(int.parse).toList();

    test('up step 1 (A1.1a): start in start_range, run reaches target 20', () {
      final s = spec({
        'range': [0, 20],
        'start_range': [10, 12],
        'target': 20,
        'step': 1,
        'direction': 'up',
      });
      for (var seed = 0; seed < 100; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final start = p.display['start'] as int;
          final values = tapped(p);
          expect(start, inInclusiveRange(10, 12));
          expect(p.display['range'], [0, 20]);
          expect(p.display['target'], 20);
          expect(p.display['step'], 1);
          expect(p.display['direction'], 'up');
          expect(values, hasLength(20 - start));
          expect(values.first, start + 1);
          expect(values.last, 20, reason: 'run reaches the target');
          expect(
            values,
            [for (var v = start + 1; v <= 20; v++) v],
            reason: 'exact sequence the child taps',
          );
          expect(values.every((v) => v <= 20), isTrue);
          expect(values.every((v) => v >= 0), isTrue);
        }
      }
    });

    test('down step 1 (A1.2a): run descends to target 12', () {
      final s = spec({
        'range': [0, 20],
        'start_range': [18, 20],
        'target': 12,
        'step': 1,
        'direction': 'down',
      });
      for (var seed = 0; seed < 100; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final start = p.display['start'] as int;
          final values = tapped(p);
          expect(start, inInclusiveRange(18, 20));
          expect(p.display['direction'], 'down');
          expect(values.first, start - 1);
          expect(values.last, 12);
          for (var i = 0; i < values.length - 1; i++) {
            expect(values[i] - values[i + 1], 1, reason: 'down by one');
          }
          expect(values.every((v) => v >= 0), isTrue);
        }
      }
    });

    test('A1.3 step 2: start_range [2,10] filtered to even starts only', () {
      final s = spec({
        'range': [0, 30],
        'start_range': [2, 10],
        'target': 20,
        'step': 2,
        'direction': 'up',
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final start = p.display['start'] as int;
          expect(start.isEven, isTrue,
              reason: 'start must be congruent to 20 mod 2');
          final values = tapped(p);
          expect(values.every((v) => v.isEven), isTrue);
          expect(values.last, 20);
          for (var i = 0; i < values.length - 1; i++) {
            expect(values[i + 1] - values[i], 2, reason: 'step 2');
          }
        }
      }
    });

    test('A1.5 window crossing 30: run crosses the tens boundary', () {
      final s = spec({
        'range': [28, 32],
        'start_range': [28, 29],
        'target': 30,
        'step': 1,
        'direction': 'up',
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final start = p.display['start'] as int;
          final values = tapped(p);
          expect(start, inInclusiveRange(28, 29));
          expect(values.contains(30), isTrue, reason: 'crosses the window');
          expect(values.last, 30);
          expect(values.every((v) => v >= 28 && v <= 32), isTrue);
        }
      }
    });

    test('C3.2 step 5: start congruent to 45 mod 5, run to 45', () {
      final s = spec({
        'range': [0, 50],
        'start_range': [25, 35],
        'target': 45,
        'step': 5,
        'direction': 'up',
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final start = p.display['start'] as int;
          expect(start % 5, 0, reason: 'congruent to 45 mod 5');
          final values = tapped(p);
          expect(values.last, 45);
          for (var i = 0; i < values.length - 1; i++) {
            expect(values[i + 1] - values[i], 5, reason: 'step 5');
          }
        }
      }
    });

    test('hand-computed: A1.1a seed 3 starts at 11 and taps 12..20', () {
      final s = spec({
        'range': [0, 20],
        'start_range': [10, 12],
        'target': 20,
        'step': 1,
        'direction': 'up',
      });
      final p = generateProblems(spec: s, level: 2, seed: 3).first;
      expect(p.display['start'], 11);
      expect(p.expected, [for (var v = 12; v <= 20; v++) '$v']);
    });

    test('a start_range that cannot reach the target is a spec error', () {
      final s = spec({
        'range': [0, 20],
        'start_range': [19, 19],
        'target': 20,
        'step': 2,
        'direction': 'up',
      });
      expect(
        () => generateProblems(spec: s, level: 2, seed: 1),
        throwsA(isA<SpecFormatException>()),
      );
    });

    test('real A1.3 L1 and A1.5 L1 stay inside their windows', () {
      for (final id in ['A1.3', 'A1.5']) {
        final real = _realSpec(id);
        for (var seed = 0; seed < 30; seed++) {
          for (final p in generateProblems(spec: real, level: 1, seed: seed)) {
            final range = (p.display['range'] as List).cast<int>();
            expect(range, hasLength(2));
            for (final v in tapped(p)) {
              expect(v, inInclusiveRange(range[0], range[1]),
                  reason: '$id L1 seed $seed');
            }
          }
        }
      }
    });

    test('is deterministic, unique within a level and carries all fields', () {
      final s = spec({
        'range': [0, 20],
        'start_range': [2, 18],
        'target': 20,
        'step': 2,
        'direction': 'up',
      });
      for (var seed = 0; seed < 50; seed++) {
        final first = generateProblems(spec: s, level: 2, seed: seed);
        final second = generateProblems(spec: s, level: 2, seed: seed);
        expect(_signature(first), _signature(second));
        final keys = first.map((p) => jsonEncode(p.display)).toSet();
        expect(keys.length, first.length, reason: 'unique seed $seed');
      }
      final problems = generateProblems(spec: s, level: 2, seed: 7);
      for (var i = 0; i < problems.length; i++) {
        expect(problems[i].index, i);
        expect(problems[i].expected, isNotEmpty);
        expect(problems[i].promptDe, isNotEmpty);
        expect(problems[i].template, 'numberline_step');
      }
    });
  });

  group('zehnerfeld_read generator', () {
    SkillSpec spec(Map<String, dynamic> params) => SkillSpec.fromJson(
      _baseSpec(_level(2, 'ikonisch', 'zehnerfeld_read', params, 7000)),
    );

    test('structured: count in range, expected == count', () {
      final s = spec({'count_range': [1, 10], 'arrangement': 'structured'});
      for (var seed = 0; seed < 100; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final count = p.display['count'] as int;
          expect(count, inInclusiveRange(1, 10));
          expect(p.display['arrangement'], 'structured');
          expect(p.expected, [count.toString()]);
        }
      }
    });

    test('five_pattern: count <= 10 (A2.2 L2)', () {
      final s = spec({'count_range': [1, 10], 'arrangement': 'five_pattern'});
      for (var seed = 0; seed < 100; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          expect(p.display['count'] as int, inInclusiveRange(1, 10));
          expect(p.display['arrangement'], 'five_pattern');
          expect(p.expected, ['${p.display['count']}']);
        }
      }
    });

    test('two_groups: count up to 20 split across two frames (each <= 10)', () {
      final s = spec({'count_range': [2, 20], 'arrangement': 'two_groups'});
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final count = p.display['count'] as int;
          final split = (p.display['split'] as List).cast<int>();
          expect(count, inInclusiveRange(2, 20));
          expect(split, hasLength(2));
          expect(split[0] + split[1], count, reason: 'a + b == count');
          expect(split[0], inInclusiveRange(1, 10));
          expect(split[1], inInclusiveRange(1, 10));
          expect(p.expected, [count.toString()], reason: 'expected == count');
          expect(p.display['arrangement'], 'two_groups');
        }
      }
    });

    test('two_groups 17 splits as 10 + 7 (C1.2 range, each <= 10)', () {
      final s = spec({'count_range': [17, 17], 'arrangement': 'two_groups'});
      final p = generateProblems(spec: s, level: 2, seed: 1).first;
      expect(p.display['count'], 17);
      final split = (p.display['split'] as List).cast<int>();
      expect(split, [10, 7], reason: '17 = 10 + 7 across two frames');
      expect(split[0] + split[1], 17);
      expect(split[0], inInclusiveRange(1, 10));
      expect(split[1], inInclusiveRange(1, 10));
      expect(p.expected, ['17']);
    });

    test('two_groups count 20 splits as 10 + 10', () {
      final s = spec({'count_range': [20, 20], 'arrangement': 'two_groups'});
      for (final p in generateProblems(spec: s, level: 2, seed: 1)) {
        expect((p.display['split'] as List).cast<int>(), [10, 10]);
        expect(p.expected, ['20']);
      }
    });

    test('is deterministic and unique within a level', () {
      for (final s in [
        spec({'count_range': [1, 10], 'arrangement': 'five_pattern'}),
        spec({'count_range': [2, 20], 'arrangement': 'two_groups'}),
      ]) {
        for (var seed = 0; seed < 50; seed++) {
          final first = generateProblems(spec: s, level: 2, seed: seed);
          final second = generateProblems(spec: s, level: 2, seed: seed);
          expect(_signature(first), _signature(second));
          final keys = first.map((p) => jsonEncode(p.display)).toSet();
          expect(keys.length, first.length, reason: 'unique seed $seed');
        }
      }
    });
  });

  group('fingerbild_read generator', () {
    SkillSpec spec(Map<String, dynamic> params) => SkillSpec.fromJson(
      _baseSpec(_level(2, 'ikonisch', 'fingerbild_read', params, 7000)),
    );

    test('hands 2: count up to 10 (both hands may be used)', () {
      final s = spec({'count_range': [1, 10], 'hands': 2});
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final count = p.display['count'] as int;
          expect(count, inInclusiveRange(1, 10));
          expect(p.display['hands'], 2);
          expect(p.expected, [count.toString()]);
        }
      }
    });

    test('hands 1: count capped at 5 (single hand)', () {
      final s = spec({'count_range': [1, 10], 'hands': 1});
      for (var seed = 0; seed < 100; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          expect(p.display['count'] as int, inInclusiveRange(1, 5));
          expect(p.display['hands'], 1);
          expect(p.expected, ['${p.display['count']}']);
        }
      }
    });

    test('hands 2 with count 10 reproduces 10 (A2.2 L3)', () {
      final s = spec({'count_range': [10, 10], 'hands': 2});
      for (final p in generateProblems(spec: s, level: 2, seed: 1)) {
        expect(p.display['count'], 10);
        expect(p.expected, ['10']);
      }
    });

    test('is deterministic and unique within a level', () {
      final s = spec({'count_range': [1, 10], 'hands': 2});
      for (var seed = 0; seed < 50; seed++) {
        final first = generateProblems(spec: s, level: 2, seed: seed);
        final second = generateProblems(spec: s, level: 2, seed: seed);
        expect(_signature(first), _signature(second));
        final keys = first.map((p) => jsonEncode(p.display)).toSet();
        expect(keys.length, first.length, reason: 'unique seed $seed');
      }
    });
  });

  group('stellenwerttafel_read generator', () {
    SkillSpec spec(Map<String, dynamic> params) => SkillSpec.fromJson(
      _baseSpec(_level(2, 'ikonisch', 'stellenwerttafel_read', params, 7000)),
    );

    test('mode read: number in 11..99 with Z/E digit breakdown', () {
      final s = spec({
        'mode': 'read',
        'columns': ['Z', 'E'],
        'number_range': [11, 99],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final number = p.display['number'] as int;
          final tens = p.display['tens'] as int;
          final ones = p.display['ones'] as int;
          expect(number, inInclusiveRange(11, 99));
          expect(tens, number ~/ 10);
          expect(ones, number % 10);
          expect(tens, inInclusiveRange(1, 9));
          expect(ones, inInclusiveRange(0, 9));
          expect(p.display['mode'], 'read');
          expect(p.display['columns'], ['Z', 'E']);
          expect(p.expected, [number.toString()], reason: 'expected == number');
        }
      }
    });

    test('mode read 99 -> tens 9, ones 9', () {
      final s = spec({
        'mode': 'read',
        'columns': ['Z', 'E'],
        'number_range': [99, 99],
      });
      for (final p in generateProblems(spec: s, level: 2, seed: 1)) {
        expect(p.display['number'], 99);
        expect(p.display['tens'], 9);
        expect(p.display['ones'], 9);
        expect(p.expected, ['99']);
      }
    });

    test('mode sum_rows op +: expected == row1 + row2 column-wise <= 99', () {
      final s = spec({
        'mode': 'sum_rows',
        'columns': ['Z', 'E'],
        'rows': 'two_rows',
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final row1 = (p.display['row1'] as List).cast<int>();
          final row2 = (p.display['row2'] as List).cast<int>();
          final op = p.display['op'] as String;
          expect(op, '+');
          expect(row1, hasLength(2));
          expect(row2, hasLength(2));
          expect(row1[0], inInclusiveRange(1, 9));
          expect(row2[0], inInclusiveRange(1, 9));
          expect(row1[1], inInclusiveRange(0, 9));
          expect(row2[1], inInclusiveRange(0, 9));
          expect(row1[0] + row2[0], lessThanOrEqualTo(9),
              reason: 'no tens carry');
          expect(row1[1] + row2[1], lessThanOrEqualTo(9),
              reason: 'no ones carry');
          final value = (row1[0] + row2[0]) * 10 + (row1[1] + row2[1]);
          expect(value, lessThanOrEqualTo(99), reason: 'ZR100');
          expect(p.expected, [value.toString()]);
          expect(p.display['value'], value);
        }
      }
    });

    test('mode sum_rows op -: result >= 0, column-wise no borrow', () {
      final s = spec({
        'mode': 'sum_rows',
        'columns': ['Z', 'E'],
        'rows': 'two_rows',
        'op': '-',
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final row1 = (p.display['row1'] as List).cast<int>();
          final row2 = (p.display['row2'] as List).cast<int>();
          expect(p.display['op'], '-');
          expect(row1[0], greaterThan(row2[0]), reason: 'tens strictly larger');
          expect(row1[1], greaterThanOrEqualTo(row2[1]),
              reason: 'no borrow in the ones column');
          final value = (row1[0] - row2[0]) * 10 + (row1[1] - row2[1]);
          expect(value, greaterThanOrEqualTo(0), reason: 'result >= 0');
          expect(value, greaterThanOrEqualTo(10), reason: 'two-digit result');
          expect(p.expected, [value.toString()]);
          expect(p.display['value'], value);
        }
      }
    });

    test('sum_rows minus keeps row1 >= row2 as numbers', () {
      final s = spec({
        'mode': 'sum_rows',
        'columns': ['Z', 'E'],
        'rows': 'two_rows',
        'op': '-',
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final row1 = (p.display['row1'] as List).cast<int>();
          final row2 = (p.display['row2'] as List).cast<int>();
          final v1 = row1[0] * 10 + row1[1];
          final v2 = row2[0] * 10 + row2[1];
          expect(v1, greaterThan(v2), reason: 'row1 >= row2');
        }
      }
    });

    test('is deterministic and unique within a level', () {
      for (final s in [
        spec({
          'mode': 'read',
          'columns': ['Z', 'E'],
          'number_range': [11, 99],
        }),
        spec({
          'mode': 'sum_rows',
          'columns': ['Z', 'E'],
          'rows': 'two_rows',
        }),
        spec({
          'mode': 'sum_rows',
          'columns': ['Z', 'E'],
          'rows': 'two_rows',
          'op': '-',
        }),
      ]) {
        for (var seed = 0; seed < 50; seed++) {
          final first = generateProblems(spec: s, level: 2, seed: seed);
          final second = generateProblems(spec: s, level: 2, seed: seed);
          expect(_signature(first), _signature(second));
          final keys = first.map((p) => jsonEncode(p.display)).toSet();
          expect(keys.length, first.length, reason: 'unique seed $seed');
        }
      }
    });
  });

  group('numberline_locate generator', () {
    SkillSpec spec(Map<String, dynamic> params) => SkillSpec.fromJson(
      _baseSpec(_level(2, 'ikonisch', 'numberline_locate', params, 7000)),
    );

    test('value inside value_range and never an endpoint (B2.2 L2)', () {
      final s = spec({'range': [0, 20], 'value_range': [1, 19]});
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final value = p.display['value'] as int;
          expect(value, inInclusiveRange(1, 19));
          expect(value, greaterThan(0), reason: 'not the lo endpoint');
          expect(value, lessThan(20), reason: 'not the hi endpoint');
          expect(p.display['range'], [0, 20]);
          expect(p.expected, [value.toString()], reason: 'expected == value');
        }
      }
    });

    test('ZR100 locates within 1..99 (B2.2 L3)', () {
      final s = spec({'range': [0, 100], 'value_range': [1, 99]});
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final value = p.display['value'] as int;
          expect(value, inInclusiveRange(1, 99));
          expect(value, isNot(0));
          expect(value, isNot(100));
        }
      }
    });

    test('a degenerate value_range covering the endpoints is clamped', () {
      final s = spec({'range': [0, 20], 'value_range': [0, 20]});
      for (var seed = 0; seed < 100; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          expect(p.display['value'] as int, inInclusiveRange(1, 19));
        }
      }
    });

    test('is deterministic and unique within a level', () {
      final s = spec({'range': [0, 100], 'value_range': [1, 99]});
      for (var seed = 0; seed < 50; seed++) {
        final first = generateProblems(spec: s, level: 2, seed: seed);
        final second = generateProblems(spec: s, level: 2, seed: seed);
        expect(_signature(first), _signature(second));
        final keys = first.map((p) => jsonEncode(p.display)).toSet();
        expect(keys.length, first.length, reason: 'unique seed $seed');
      }
    });
  });

  group('picture_compare generator', () {
    SkillSpec spec(Map<String, dynamic> params) => SkillSpec.fromJson(
      _baseSpec(_level(2, 'ikonisch', 'picture_compare', params, 7000)),
    );

    test('more: |left-right| >= 1 and expected is the larger side', () {
      final s = spec({
        'left_range': [1, 10],
        'right_range': [1, 10],
        'question': 'more',
        'difference_min': 1,
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final left = p.display['left'] as int;
          final right = p.display['right'] as int;
          expect(left, inInclusiveRange(1, 10));
          expect(right, inInclusiveRange(1, 10));
          expect((left - right).abs(), greaterThanOrEqualTo(1),
              reason: 'never equal');
          final expected = left > right ? 'left' : 'right';
          expect(p.expected, [expected]);
          expect(p.display['question'], 'more');
        }
      }
    });

    test('less: expected is the smaller side', () {
      final s = spec({
        'left_range': [1, 10],
        'right_range': [1, 10],
        'question': 'less',
        'difference_min': 1,
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final left = p.display['left'] as int;
          final right = p.display['right'] as int;
          final expected = left < right ? 'left' : 'right';
          expect(p.expected, [expected]);
        }
      }
    });

    test('difference: expected == |left-right| >= 1', () {
      final s = spec({
        'left_range': [1, 10],
        'right_range': [1, 10],
        'question': 'difference',
        'difference_min': 1,
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final left = p.display['left'] as int;
          final right = p.display['right'] as int;
          final diff = (left - right).abs();
          expect(diff, greaterThanOrEqualTo(1));
          expect(p.expected, [diff.toString()]);
        }
      }
    });

    test('difference_min is honoured', () {
      final s = spec({
        'left_range': [1, 10],
        'right_range': [1, 10],
        'question': 'more',
        'difference_min': 3,
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final left = p.display['left'] as int;
          final right = p.display['right'] as int;
          expect((left - right).abs(), greaterThanOrEqualTo(3));
        }
      }
    });

    test('display carries left, right, question', () {
      final s = spec({
        'left_range': [3, 3],
        'right_range': [5, 5],
        'question': 'more',
        'difference_min': 1,
      });
      for (final p in generateProblems(spec: s, level: 2, seed: 1)) {
        expect(p.display['left'], 3);
        expect(p.display['right'], 5);
        expect(p.display['question'], 'more');
        expect(p.expected, ['right'], reason: '5 is more than 3');
      }
    });

    test('is deterministic and unique within a level', () {
      for (final s in [
        spec({
          'left_range': [1, 10],
          'right_range': [1, 10],
          'question': 'more',
          'difference_min': 1,
        }),
        spec({
          'left_range': [1, 10],
          'right_range': [1, 10],
          'question': 'difference',
          'difference_min': 1,
        }),
      ]) {
        for (var seed = 0; seed < 50; seed++) {
          final first = generateProblems(spec: s, level: 2, seed: seed);
          final second = generateProblems(spec: s, level: 2, seed: seed);
          expect(_signature(first), _signature(second));
          final keys = first.map((p) => jsonEncode(p.display)).toSet();
          expect(keys.length, first.length, reason: 'unique seed $seed');
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
