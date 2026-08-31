import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/problem.dart';
import 'package:math_app/models/skill_spec.dart';
import 'package:math_app/practice/template_evaluator.dart';

SkillSpec _spec({
  List<Map<String, String>> taxonomy = const [
    {'code': 'miscount', 'label_de': 'verzählt', 'hint_de': 'Zähle noch einmal langsam.'},
    {'code': 'sign_error', 'label_de': 'Plus und Minus verwechselt', 'hint_de': 'Plus und Minus sind verschiedene Rechenzeichen.'},
    {'code': 'other', 'label_de': 'noch einmal probieren', 'hint_de': 'Schau noch einmal genau hin.'},
  ],
}) =>
    SkillSpec.fromJson({
      'spec_version': 1,
      'skill_id': 'G1',
      'construct_id': 'G1',
      'domain': 'A',
      'title_de': 'Evaluator-Test',
      'level_titles_de': ['Stufe 1', 'Stufe 2', 'Stufe 3'],
      'levels': [
        {
          'level': 1,
          'representation': 'enaktiv',
          'template': 'place_counters',
          'custom_widget': null,
          'params': {'count_range': [1, 5], 'frame': 'zehnerfeld', 'action': 'fill'},
          'problem_count': 8,
          'prompt_de': 'Lege die Plättchen.',
          'slow_band_ms': 9000,
        },
        {
          'level': 2,
          'representation': 'ikonisch',
          'template': 'zehnerfeld_read',
          'custom_widget': null,
          'params': {'count_range': [1, 10], 'arrangement': 'structured'},
          'problem_count': 8,
          'prompt_de': 'Tippe die Zahl ein.',
          'slow_band_ms': 7000,
        },
        {
          'level': 3,
          'representation': 'symbolisch',
          'template': 'equation_solve',
          'custom_widget': null,
          'params': {'op': '+', 'unknown': 'result', 'zr': 20, 'a_range': [2, 9], 'b_range': [2, 9], 'mode': 'standard'},
          'problem_count': 8,
          'prompt_de': 'Rechne im Kopf.',
          'slow_band_ms': 6000,
        },
      ],
      'mastery': {'correct_of': 8},
      'error_taxonomy': taxonomy,
      'provenance': {'sources': ['Testquelle 2026'], 'author': 'Test', 'reviewed_by': 'open'},
    });

Problem _problem({
  required String template,
  required Map<String, dynamic> display,
  List<String> expected = const [],
}) =>
    Problem(
      template: template,
      skillId: 'G1',
      level: 1,
      seed: 7,
      index: 0,
      promptDe: 'Test.',
      display: display,
      expected: expected,
    );

void main() {
  final evaluator = TemplateEvaluator();
  final spec = _spec();

  group('string-match templates', () {
    test('equation_solve: correct answer matches, whitespace normalised', () {
      final p = _problem(
        template: 'equation_solve',
        display: {'op': '+', 'a': 4, 'b': 3, 'c': 7},
        expected: ['7'],
      );
      expect(evaluator.evaluate(p, '7', spec: spec).isCorrect, isTrue);
      expect(evaluator.evaluate(p, '  7 ', spec: spec).isCorrect, isTrue);
      final wrong = evaluator.evaluate(p, '8', spec: spec);
      expect(wrong.isCorrect, isFalse);
      expect(wrong.canonicalAnswer, '8');
    });

    test('sign_error: a minus task answered with the plus result', () {
      final p = _problem(
        template: 'equation_solve',
        display: {'op': '-', 'a': 10, 'b': 4, 'c': 6},
        expected: ['6'],
      );
      final result = evaluator.evaluate(p, '14', spec: spec);
      expect(result.isCorrect, isFalse);
      expect(result.errorCode, 'sign_error');
    });

    test('miscount: an answer one away from the expected value', () {
      final p = _problem(
        template: 'equation_solve',
        display: {'op': '+', 'a': 4, 'b': 3, 'c': 7},
        expected: ['7'],
      );
      final result = evaluator.evaluate(p, '8', spec: spec);
      expect(result.isCorrect, isFalse);
      expect(result.errorCode, 'miscount');
    });

    test('unknown wrong answers fall back to other', () {
      final p = _problem(
        template: 'equation_solve',
        display: {'op': '+', 'a': 4, 'b': 3, 'c': 7},
        expected: ['7'],
      );
      final result = evaluator.evaluate(p, '12', spec: spec);
      expect(result.isCorrect, isFalse);
      expect(result.errorCode, 'other');
    });

    test('compare_symbols: the operator string must match', () {
      final p = _problem(
        template: 'compare_symbols',
        display: {'a': 3, 'b': 5},
        expected: ['<'],
      );
      expect(evaluator.evaluate(p, '<', spec: spec).isCorrect, isTrue);
      expect(evaluator.evaluate(p, '>', spec: spec).isCorrect, isFalse);
    });

    test('picture_compare difference and more/less side ids', () {
      final diff = _problem(
        template: 'picture_compare',
        display: {'left': 3, 'right': 5, 'question': 'difference'},
        expected: ['2'],
      );
      expect(evaluator.evaluate(diff, '2', spec: spec).isCorrect, isTrue);
      expect(evaluator.evaluate(diff, '8', spec: spec).isCorrect, isFalse);

      final more = _problem(
        template: 'picture_compare',
        display: {'left': 3, 'right': 5, 'question': 'more'},
        expected: ['right'],
      );
      expect(evaluator.evaluate(more, 'right', spec: spec).isCorrect, isTrue);
      expect(evaluator.evaluate(more, 'left', spec: spec).isCorrect, isFalse);
    });

    test('word_problem and flash_subitize are plain number matches', () {
      final word = _problem(
        template: 'word_problem',
        display: {'a': 3, 'b': 2, 'op': '+'},
        expected: ['5'],
      );
      expect(evaluator.evaluate(word, '5', spec: spec).isCorrect, isTrue);

      final flash = _problem(
        template: 'custom_widget',
        display: {'custom_widget': 'flash_subitize', 'count': 4, 'flash_ms': 800, 'display': 'dots'},
        expected: ['4'],
      );
      expect(evaluator.evaluate(flash, '4', spec: spec).isCorrect, isTrue);
      expect(evaluator.evaluate(flash, '3', spec: spec).isCorrect, isFalse);
    });
  });

  group('sequence_gap', () {
    test('joined values are accepted in the exact gap order', () {
      final p = _problem(
        template: 'sequence_gap',
        display: {'values': [3, 4, 5], 'gap_indices': [1]},
        expected: ['4'],
      );
      expect(evaluator.evaluate(p, '4', spec: spec).isCorrect, isTrue);

      final multi = _problem(
        template: 'sequence_gap',
        display: {'values': [5, 6, 7, 8, 9], 'gap_indices': [1, 3]},
        expected: ['6', '8'],
      );
      expect(evaluator.evaluate(multi, '6,8', spec: spec).isCorrect, isTrue);
      expect(evaluator.evaluate(multi, '6, 8', spec: spec).isCorrect, isTrue,
          reason: 'spaces around the comma are tolerated');
      expect(evaluator.evaluate(multi, '8,6', spec: spec).isCorrect, isFalse);
      expect(evaluator.evaluate(multi, '6', spec: spec).isCorrect, isFalse);
    });
  });

  group('drag_partition', () {
    test('sum: any split that totals the target is correct', () {
      final p = _problem(
        template: 'drag_partition',
        display: {'total': 9, 'parts': 2, 'split_constraint': 'sum'},
        expected: const [],
      );
      expect(evaluator.evaluate(p, '4+5', spec: spec).isCorrect, isTrue);
      expect(evaluator.evaluate(p, '1+8', spec: spec).isCorrect, isTrue);
      expect(evaluator.evaluate(p, '5+4', spec: spec).isCorrect, isTrue);
      expect(evaluator.evaluate(p, '4+6', spec: spec).isCorrect, isFalse,
          reason: 'sum is 10, not 9');
      expect(evaluator.evaluate(p, '9', spec: spec).isCorrect, isFalse,
          reason: 'two boxes are required');
      final canonical = evaluator.evaluate(p, '4 + 5', spec: spec);
      expect(canonical.isCorrect, isTrue);
      expect(canonical.canonicalAnswer, '4+5');
    });

    test('make_ten: a wrong split like 11 = 9+2 is incorrect', () {
      final p = _problem(
        template: 'drag_partition',
        display: {'total': 11, 'parts': 2, 'split_constraint': 'make_ten'},
        expected: const [],
      );
      expect(evaluator.evaluate(p, '10+1', spec: spec).isCorrect, isTrue);
      expect(evaluator.evaluate(p, '9+2', spec: spec).isCorrect, isFalse,
          reason: 'no box holds exactly 10');
      expect(evaluator.evaluate(p, '8+3', spec: spec).isCorrect, isFalse);
    });

    test('equal: all boxes must be equal', () {
      final p = _problem(
        template: 'drag_partition',
        display: {'total': 10, 'parts': 2, 'split_constraint': 'equal'},
        expected: const [],
      );
      expect(evaluator.evaluate(p, '5+5', spec: spec).isCorrect, isTrue);
      expect(evaluator.evaluate(p, '4+6', spec: spec).isCorrect, isFalse);
    });

    test('near_double: two equal boxes plus exactly one', () {
      final p = _problem(
        template: 'drag_partition',
        display: {'total': 15, 'parts': 3, 'split_constraint': 'near_double'},
        expected: const [],
      );
      expect(evaluator.evaluate(p, '7+7+1', spec: spec).isCorrect, isTrue);
      expect(evaluator.evaluate(p, '7+8+0', spec: spec).isCorrect, isFalse);
      expect(evaluator.evaluate(p, '1+7+7', spec: spec).isCorrect, isFalse,
          reason: 'the extra 1 must sit in the third box');
    });

    test('tens_ones: exactly [a, 10*floor(b/10), b%10]', () {
      final p = _problem(
        template: 'drag_partition',
        display: {
          'total': 62,
          'parts': 3,
          'split_constraint': 'tens_ones',
          'a': 35,
          'b': 27,
        },
        expected: const [],
      );
      expect(evaluator.evaluate(p, '35+20+7', spec: spec).isCorrect, isTrue);
      expect(evaluator.evaluate(p, '35+27+0', spec: spec).isCorrect, isFalse);
      expect(evaluator.evaluate(p, '20+35+7', spec: spec).isCorrect, isFalse);
    });
  });

  group('place_counters', () {
    test('fill: the filled count is the answer', () {
      final p = _problem(
        template: 'place_counters',
        display: {'count': 7, 'frame': 'zehnerfeld', 'action': 'fill'},
        expected: ['7'],
      );
      expect(evaluator.evaluate(p, '7', spec: spec).isCorrect, isTrue);
      final wrong = evaluator.evaluate(p, '8', spec: spec);
      expect(wrong.isCorrect, isFalse);
      expect(wrong.errorCode, 'miscount', reason: 'off by one');
    });

    test('take_away: the answer is the remaining total - count', () {
      final p = _problem(
        template: 'place_counters',
        display: {'count': 3, 'total': 10, 'remaining': 7, 'frame': 'zehnerfeld', 'action': 'take_away'},
        expected: ['3'],
      );
      expect(evaluator.evaluate(p, '7', spec: spec).isCorrect, isTrue,
          reason: '10 - 3 leaves 7');
      expect(evaluator.evaluate(p, '3', spec: spec).isCorrect, isFalse,
          reason: '3 is the taken-away amount, not the remainder');
    });

    test('nonstandard (B2.3): count typed directly or as "Z E"', () {
      final p = _problem(
        template: 'place_counters',
        display: {
          'count': 34,
          'frame': 'stellenwerttafel',
          'action': 'fill',
          'mode': 'nonstandard',
          'tens': 2,
          'ones': 14,
        },
        expected: ['34'],
      );
      expect(evaluator.evaluate(p, '34', spec: spec).isCorrect, isTrue);
      expect(evaluator.evaluate(p, '2 14', spec: spec).isCorrect, isTrue);
      expect(evaluator.evaluate(p, '214', spec: spec).isCorrect, isFalse);
      expect(evaluator.evaluate(p, '2 4', spec: spec).isCorrect, isFalse);
    });
  });

  group('bundle_sticks', () {
    test('Z Zehner, E Einer recomposes to the count', () {
      final p = _problem(
        template: 'bundle_sticks',
        display: {'count': 23, 'bundles': 2, 'singles': 3},
        expected: ['2 Zehner, 3 Einer'],
      );
      final ok = evaluator.evaluate(p, '2 Zehner, 3 Einer', spec: spec);
      expect(ok.isCorrect, isTrue);
      expect(ok.canonicalAnswer, '2 Zehner, 3 Einer');
      expect(evaluator.evaluate(p, '2 3', spec: spec).isCorrect, isTrue);
      expect(evaluator.evaluate(p, '2 Zehner, 4 Einer', spec: spec).isCorrect, isFalse);
      expect(evaluator.evaluate(p, '23', spec: spec).isCorrect, isFalse);
    });

    test('a count >= 10 needs at least one Zehner bundle', () {
      final p = _problem(
        template: 'bundle_sticks',
        display: {'count': 13, 'bundles': 1, 'singles': 3},
        expected: ['1 Zehner, 3 Einer'],
      );
      expect(evaluator.evaluate(p, '0 Zehner, 13 Einer', spec: spec).isCorrect, isFalse,
          reason: '13 ungrouped sticks is not a bundled answer');
    });
  });

  group('rekenrek_set', () {
    test('submitted count matches the target', () {
      final p = _problem(
        template: 'rekenrek_set',
        display: {'count': 15, 'rows': 2},
        expected: ['15'],
      );
      expect(evaluator.evaluate(p, '15', spec: spec).isCorrect, isTrue);
      expect(evaluator.evaluate(p, '14', spec: spec).isCorrect, isFalse);
    });
  });

  group('numberline_step', () {
    test('the exact tapped run joined by commas', () {
      final p = _problem(
        template: 'numberline_step',
        display: {'start': 11, 'target': 20, 'step': 1, 'direction': 'up'},
        expected: [for (var v = 12; v <= 20; v++) '$v'],
      );
      final run = [for (var v = 12; v <= 20; v++) '$v'].join(',');
      final ok = evaluator.evaluate(p, run, spec: spec);
      expect(ok.isCorrect, isTrue);
      expect(ok.canonicalAnswer, run);
      expect(evaluator.evaluate(p, '12,13,14', spec: spec).isCorrect, isFalse,
          reason: 'the run is incomplete');
    });

    test('the reversed run is wrong (wrong_direction when the spec carries it)', () {
      final reversedSpec = _spec(taxonomy: [
        {'code': 'miscount', 'label_de': 'verzählt', 'hint_de': 'Zähle noch einmal.'},
        {'code': 'wrong_direction', 'label_de': 'falsche Richtung', 'hint_de': 'Zähle in die Richtung der Aufgabe.'},
        {'code': 'other', 'label_de': 'noch einmal probieren', 'hint_de': 'Schau noch einmal genau hin.'},
      ]);
      final p = _problem(
        template: 'numberline_step',
        display: {'start': 11, 'target': 20, 'step': 1, 'direction': 'up'},
        expected: [for (var v = 12; v <= 20; v++) '$v'],
      );
      final reversed = [for (var v = 20; v >= 12; v--) '$v'].join(',');
      final result = evaluator.evaluate(p, reversed, spec: reversedSpec);
      expect(result.isCorrect, isFalse);
      expect(result.errorCode, 'wrong_direction');
    });
  });

  group('strategy_choice', () {
    final p = _problem(
      template: 'strategy_choice',
      display: {
        'op': '+',
        'a': 4,
        'b': 4,
        'correct_strategy': 'verdoppeln',
        'strategies': [
          {'id': 'verdoppeln', 'label_de': 'Verdoppeln'},
          {'id': 'fast_verdoppeln', 'label_de': 'Fast verdoppeln'},
        ],
      },
      expected: ['8'],
    );

    test('both the value and the strategy must be right', () {
      expect(evaluator.evaluate(p, '8|verdoppeln', spec: spec).isCorrect, isTrue);
      expect(evaluator.evaluate(p, '8|fast_verdoppeln', spec: spec).isCorrect, isFalse,
          reason: 'right value, wrong strategy');
      expect(evaluator.evaluate(p, '7|verdoppeln', spec: spec).isCorrect, isFalse,
          reason: 'wrong value, right strategy');
      expect(evaluator.evaluate(p, '8', spec: spec).isCorrect, isFalse,
          reason: 'the strategy part is missing');
      final ok = evaluator.evaluate(p, '8|verdoppeln', spec: spec);
      expect(ok.canonicalAnswer, '8|verdoppeln');
    });
  });

  group('error code resolution', () {
    test('a candidate the spec does not carry falls back to other', () {
      final minimalSpec = _spec(taxonomy: [
        {'code': 'other', 'label_de': 'noch einmal probieren', 'hint_de': 'Schau noch einmal genau hin.'},
      ]);
      final p = _problem(
        template: 'equation_solve',
        display: {'op': '+', 'a': 4, 'b': 3, 'c': 7},
        expected: ['7'],
      );
      expect(evaluator.evaluate(p, '8', spec: minimalSpec).errorCode, 'other');
      expect(evaluator.evaluate(p, '14', spec: minimalSpec).errorCode, 'other');
    });
  });
}
