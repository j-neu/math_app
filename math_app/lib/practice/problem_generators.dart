/// Pure, deterministic problem generators driven by the skill specs.
///
/// Every generator draws from a single [SeededGenerator] rooted in the
/// server-provided seed, so the same (spec, level, seed) produces a
/// byte-identical problem list on every run and device. No wall-clock time
/// or platform randomness is used anywhere in this file.
library;

import 'dart:convert';
import 'dart:math';

import '../models/problem.dart';
import '../models/skill_spec.dart';

/// Deterministic random source for one problem set: wraps `Random(seed)` so
/// the exact same stream of values is produced for the same seed everywhere.
class SeededGenerator {
  final int seed;
  final Random _random;

  SeededGenerator(this.seed) : _random = Random(seed);

  /// Uniform int in `[min, max]` (inclusive).
  int nextIntInRange(int min, int max) {
    if (max < min) return min;
    return min + _random.nextInt(max - min + 1);
  }

  int nextInt(int max) => _random.nextInt(max);

  double nextDouble() => _random.nextDouble();
}

/// Upper bound every generated sequence value must respect. No spec goes
/// beyond ZR100, so this is a hard safety net rather than a tuning knob.
const int _maxZR = 100;

/// How many unique-problem sampling attempts run before the harness falls
/// back to filling the level with the remaining draws.
const int _maxUniquenessAttempts = 50;

/// Generates exactly `spec.levels[level - 1].problemCount` problems for the
/// given 1-based [level], deterministically from [seed].
///
/// Problems within one level are unique (sampled with retry up to
/// [_maxUniquenessAttempts]); if the spec's ranges cannot yield enough
/// distinct draws the count contract still wins and remaining problems are
/// filled from the generator.
List<Problem> generateProblems({
  required SkillSpec spec,
  required int level,
  required int seed,
}) {
  final levelSpec = spec.levelSpec(level);
  final gen = SeededGenerator(seed);
  final problems = <Problem>[];
  final seen = <String>{};
  var attempts = 0;

  while (problems.length < levelSpec.problemCount &&
      attempts < _maxUniquenessAttempts) {
    attempts++;
    final index = problems.length;
    final problem = _generateForTemplate(
      spec,
      levelSpec,
      level,
      seed,
      index,
      gen,
    );
    final key = jsonEncode(problem.display);
    if (seen.contains(key)) continue;
    seen.add(key);
    problems.add(problem);
  }

  while (problems.length < levelSpec.problemCount) {
    final index = problems.length;
    problems.add(
      _generateForTemplate(spec, levelSpec, level, seed, index, gen),
    );
  }

  return problems;
}

/// Dispatches to the per-template generator. Templates whose generators
/// arrive in P2 tasks 4-5 are declared here and throw [UnimplementedError]
/// until then.
Problem _generateForTemplate(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  switch (level.template) {
    case 'sequence_gap':
      return _generateSequenceGap(spec, level, levelNumber, seed, index, gen);
    case 'compare_symbols':
      return _generateCompareSymbols(
        spec,
        level,
        levelNumber,
        seed,
        index,
        gen,
      );
    case 'equation_solve':
      return _generateEquationSolve(
        spec,
        level,
        levelNumber,
        seed,
        index,
        gen,
      );
    case 'equation_gap':
      return _generateEquationGap(
        spec,
        level,
        levelNumber,
        seed,
        index,
        gen,
      );
    case 'word_problem':
      return _generateWordProblem(
        spec,
        level,
        levelNumber,
        seed,
        index,
        gen,
      );
    case 'strategy_choice':
      return _generateStrategyChoice(
        spec,
        level,
        levelNumber,
        seed,
        index,
        gen,
      );
    case 'drag_partition':
      return _generateDragPartition(
        spec,
        level,
        levelNumber,
        seed,
        index,
        gen,
      );
    case 'place_counters':
      return _generatePlaceCounters(
        spec,
        level,
        levelNumber,
        seed,
        index,
        gen,
      );
    case 'bundle_sticks':
      return _generateBundleSticks(
        spec,
        level,
        levelNumber,
        seed,
        index,
        gen,
      );
    case 'rekenrek_set':
      return _generateRekenrekSet(
        spec,
        level,
        levelNumber,
        seed,
        index,
        gen,
      );
    case 'numberline_step':
      return _generateNumberlineStep(
        spec,
        level,
        levelNumber,
        seed,
        index,
        gen,
      );
    case 'zehnerfeld_read':
      return _generateZehnerfeldRead(
        spec,
        level,
        levelNumber,
        seed,
        index,
        gen,
      );
    case 'fingerbild_read':
      return _generateFingerbildRead(
        spec,
        level,
        levelNumber,
        seed,
        index,
        gen,
      );
    case 'stellenwerttafel_read':
      return _generateStellenwerttafelRead(
        spec,
        level,
        levelNumber,
        seed,
        index,
        gen,
      );
    case 'numberline_locate':
      return _generateNumberlineLocate(
        spec,
        level,
        levelNumber,
        seed,
        index,
        gen,
      );
    case 'picture_compare':
      return _generatePictureCompare(
        spec,
        level,
        levelNumber,
        seed,
        index,
        gen,
      );
    case 'custom_widget':
      return _generateCustomWidget(
        spec,
        level,
        levelNumber,
        seed,
        index,
        gen,
      );
    default:
      throw UnimplementedError(
        'Generator for template "${level.template}" is declared but not yet '
        'implemented (implemented in P2 tasks 4-5).',
      );
  }
}

/// `sequence_gap` generator (P2 plan §5 rule 13, P3 §4.5b): an arithmetic
/// sequence of the given length in the given direction and step, with the
/// given gaps. With `progression: "double"` the sequence doubles
/// geometrically instead and `step` is ignored. `expected` holds the missing
/// values in `gap_indices` order.
Problem _generateSequenceGap(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final direction = level.stringParam('direction', fallback: 'up');
  final progression = level.stringParamOrNull('progression');
  final isDouble = progression == 'double';
  final step = level.intParam('step', fallback: 1);
  final length = level.intParam('length', fallback: 5);
  final startRange = level.intListParam('start_range');
  final gapIndices = level.intListParam('gap_indices');

  final startLo = startRange.isEmpty ? 1 : startRange[0];
  final startHi = startRange.isEmpty ? 9 : startRange[1];

  // Clamp the sampled start so every sequence value stays inside ZR100 and
  // a downward sequence never drops below 1. The spec's own ranges already
  // guarantee this; the clamps are a hard safety net.
  var minStart = startLo;
  var maxStart = startHi;
  if (isDouble) {
    // last value = start * 2^(length-1) <= 100
    final maxByBound = _maxZR >> (length - 1);
    maxStart = min(maxStart, maxByBound);
  } else if (direction == 'down') {
    // last value = start - (length-1)*step >= 1
    final minByBound = 1 + (length - 1) * step;
    minStart = max(minStart, minByBound);
  } else {
    // last value = start + (length-1)*step <= 100
    final maxByBound = _maxZR - (length - 1) * step;
    maxStart = min(maxStart, maxByBound);
  }
  if (maxStart < minStart) maxStart = minStart;

  final start = gen.nextIntInRange(minStart, maxStart);

  final values = <int>[];
  var current = start;
  for (var i = 0; i < length; i++) {
    values.add(current);
    current = isDouble
        ? current * 2
        : (direction == 'down' ? current - step : current + step);
  }

  final expected = gapIndices.map((i) => values[i].toString()).toList();

  return Problem(
    template: 'sequence_gap',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {
      'direction': direction,
      'step': step,
      'progression': isDouble ? 'double' : 'arithmetic',
      'values': values,
      'gap_indices': gapIndices,
    },
    expected: expected,
  );
}

/// `compare_symbols` generator (P2 plan §5 rule 14): two numbers from the
/// parameterised ranges; `expected` is the one operator that holds between
/// them (`<`, `>` or `=`).
Problem _generateCompareSymbols(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final aRange = level.intListParam('a_range');
  final bRange = level.intListParam('b_range');
  final a = gen.nextIntInRange(
    aRange.isEmpty ? 1 : aRange[0],
    aRange.isEmpty ? 9 : aRange[1],
  );
  final b = gen.nextIntInRange(
    bRange.isEmpty ? 1 : bRange[0],
    bRange.isEmpty ? 9 : bRange[1],
  );
  final op = a > b ? '>' : (a < b ? '<' : '=');

  return Problem(
    template: 'compare_symbols',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {'a': a, 'b': b},
    expected: [op],
  );
}

/// Draws `[lo..hi]` but never lets the sample exceed the outer bound, so a
/// caller can clamp a draw into the valid space instead of rejecting it.
int _clampedDraw(SeededGenerator gen, int lo, int hi, int outer) {
  final top = min(hi, outer);
  return top < lo ? lo : gen.nextIntInRange(lo, top);
}

/// `equation_solve` generator (P2 plan §5 rule 11, P3 §4.5b): the child
/// solves `a op b = c` with one of `a`/`b`/`c` unknown. `display` always
/// carries all three numbers plus `op`/`unknown`/`mode`; `expected` holds the
/// missing value. `mode: "place_value"` decomposes both addends into tens and
/// ones and `expected` is the column-wise result `tens*10 + ones`.
/// Subtraction is never negative (`a >= b`), `equal: true` forces `a == b`.
Problem _generateEquationSolve(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final op = level.stringParam('op', fallback: '+');
  final unknown = level.stringParam('unknown', fallback: 'result');
  final mode = level.stringParam('mode', fallback: 'standard');
  final zr = level.intParam('zr', fallback: _maxZR);

  if (mode == 'place_value') {
    final tensRange = level.intListParam('tens_range');
    final onesRange = level.intListParam('ones_range');
    final tLo = tensRange.isEmpty ? 1 : tensRange[0];
    final tHi = tensRange.isEmpty ? 9 : tensRange[1];
    final oLo = onesRange.isEmpty ? 1 : onesRange[0];
    final oHi = onesRange.isEmpty ? 9 : onesRange[1];

    int tensA, onesA, tensB, onesB, resultTens, resultOnes;
    if (op == '-') {
      tensA = gen.nextIntInRange(tLo, tHi);
      onesA = gen.nextIntInRange(oLo, oHi);
      tensB = _clampedDraw(gen, tLo, tHi, tensA);
      onesB = _clampedDraw(gen, oLo, oHi, onesA);
      resultTens = tensA - tensB;
      resultOnes = onesA - onesB;
    } else {
      tensA = _clampedDraw(gen, tLo, tHi, 9);
      onesA = _clampedDraw(gen, oLo, oHi, 9);
      tensB = _clampedDraw(gen, tLo, tHi, 9 - tensA);
      onesB = _clampedDraw(gen, oLo, oHi, 9 - onesA);
      resultTens = tensA + tensB;
      resultOnes = onesA + onesB;
    }
    final a = tensA * 10 + onesA;
    final b = tensB * 10 + onesB;
    final c = resultTens * 10 + resultOnes;

    return Problem(
      template: 'equation_solve',
      skillId: spec.skillId,
      level: levelNumber,
      seed: seed,
      index: index,
      promptDe: level.promptDe,
      display: {
        'op': op,
        'unknown': unknown,
        'mode': mode,
        'a': a,
        'b': b,
        'c': c,
        'a_tens': tensA,
        'a_ones': onesA,
        'b_tens': tensB,
        'b_ones': onesB,
        'tens': resultTens,
        'ones': resultOnes,
      },
      expected: [c.toString()],
    );
  }

  final aRange = level.intListParam('a_range');
  final bRange = level.intListParam('b_range');
  final aLo = aRange.isEmpty ? 1 : aRange[0];
  final aHi = aRange.isEmpty ? 9 : aRange[1];
  final bLo = bRange.isEmpty ? 1 : bRange[0];
  final bHi = bRange.isEmpty ? 9 : bRange[1];

  final equal = level.boolParam('equal');

  int a, b, c;
  if (equal) {
    // A3.3 / C1.2 doubling: a == b, result 2a within zr.
    a = gen.nextIntInRange(max(aLo, 1), min(aHi, zr ~/ 2));
    b = a;
    c = op == '-' ? 0 : a + b;
  } else {
    switch (unknown) {
      case 'result':
        if (op == '-') {
          a = gen.nextIntInRange(max(aLo, bLo), aHi);
          b = _clampedDraw(gen, bLo, bHi, a);
          c = a - b;
        } else {
          a = _clampedDraw(gen, aLo, aHi, zr - bLo);
          b = _clampedDraw(gen, bLo, bHi, zr - a);
          c = a + b;
        }
      case 'addend':
        // _ + b = c, missing a >= 1, c = a + b <= zr.
        b = _clampedDraw(gen, bLo, bHi, zr - max(aLo, 1));
        a = gen.nextIntInRange(max(aLo, 1), min(aHi, zr - b));
        c = a + b;
      case 'subtrahend':
        // a - _ = c with 1 <= missing b <= a - 1.
        a = gen.nextIntInRange(max(aLo, 2), aHi);
        c = gen.nextIntInRange(max(bLo, 1), min(bHi, a - 1));
        b = a - c;
      case 'minuend':
        // _ - b = c with missing a = c + b, result c >= 1.
        a = gen.nextIntInRange(max(aLo, 2), aHi);
        b = _clampedDraw(gen, bLo, bHi, a - 1);
        c = a - b;
      default:
        throw SpecFormatException(
          'equation_solve: unknown unknown mode "$unknown"',
        );
    }
  }

  return Problem(
    template: 'equation_solve',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {'op': op, 'unknown': unknown, 'mode': mode, 'a': a, 'b': b, 'c': c},
    expected: [(unknown == 'result' ? c : (unknown == 'addend' || unknown == 'minuend' ? a : b)).toString()],
  );
}

/// `equation_gap` generator (P2 plan §5 rule 12, P3 §3): a Stützpunkt-form
/// with one (or two) blanks whose value(s) `expected` lists. Every shown
/// equation is arithmetically true. Forms: `gap`, `helper`, `missing_addend`,
/// `any_split`, `place_value`, `half`, `double`, `neighbor`, `helper_double`.
Problem _generateEquationGap(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final op = level.stringParam('op', fallback: '+');
  final form = level.stringParam('form', fallback: 'gap');
  final zr = level.intParam('zr', fallback: _maxZR);
  final aRange = level.intListParam('a_range');
  final bRange = level.intListParam('b_range');
  final aLo = aRange.isEmpty ? 1 : aRange[0];
  final aHi = aRange.isEmpty ? 9 : aRange[1];
  final bLo = bRange.isEmpty ? 1 : bRange[0];
  final bHi = bRange.isEmpty ? 9 : bRange[1];

  switch (form) {
    case 'gap':
      // a op b = _  (C4.2 Umkehraufgabe).
      final a = gen.nextIntInRange(max(aLo, bLo), aHi);
      final b = _clampedDraw(gen, bLo, bHi, a);
      final c = op == '-' ? a - b : a + b;
      return Problem(
        template: 'equation_gap',
        skillId: spec.skillId,
        level: levelNumber,
        seed: seed,
        index: index,
        promptDe: level.promptDe,
        display: {'form': form, 'op': op, 'a': a, 'b': b, 'gap_after': 'result'},
        expected: [c.toString()],
      );

    case 'helper':
      // Stützpunkt: a op b = first op _. For single-digit b the split is
      // make_ten (C2.1 plus / C3.2 minus), for two-digit b it is tens_ones
      // (C3.4a plus / C3.4b minus).
      final isTensOnes = bHi >= 10;
      final split = isTensOnes ? 'tens_ones' : 'make_ten';
      int a, b, first, gap;
      if (op == '-') {
        if (isTensOnes) {
          // a - b = (a - tens) - _, gap = b % 10 (>= 1).
          a = gen.nextIntInRange(aLo, aHi);
          b = gen.nextIntInRange(bLo, bHi);
          var attempts = 0;
          while (b % 10 == 0 && attempts++ < 300) {
            b = gen.nextIntInRange(bLo, bHi);
          }
          first = a - 10 * (b ~/ 10);
          gap = b % 10;
        } else {
          // a - b = (a - ones) - _, gap = b - ones >= 1 (C3.2).
          a = gen.nextIntInRange(aLo, aHi);
          var attempts = 0;
          while ((a % 10 == 0 || a % 10 == 9) && attempts++ < 300) {
            a = gen.nextIntInRange(aLo, aHi);
          }
          b = gen.nextIntInRange(max(bLo, a % 10 + 1), bHi);
          first = a - a % 10;
          gap = b - a % 10;
        }
      } else {
        if (isTensOnes) {
          // a + b = (a + tens) + _, gap = b % 10 (>= 1) (C3.4a).
          a = gen.nextIntInRange(aLo, aHi);
          b = gen.nextIntInRange(bLo, bHi);
          var attempts = 0;
          while (b % 10 == 0 && attempts++ < 300) {
            b = gen.nextIntInRange(bLo, bHi);
          }
          first = a + 10 * (b ~/ 10);
          gap = b % 10;
        } else {
          // a + b = 10 + _, gap = a + b - 10 >= 1 (C2.1).
          a = gen.nextIntInRange(aLo, aHi);
          b = gen.nextIntInRange(max(bLo, 11 - a), min(bHi, zr - a));
          first = 10;
          gap = a + b - 10;
        }
      }
      return Problem(
        template: 'equation_gap',
        skillId: spec.skillId,
        level: levelNumber,
        seed: seed,
        index: index,
        promptDe: level.promptDe,
        display: {
          'form': form,
          'op': op,
          'a': a,
          'b': b,
          'first': first,
          'split': split,
          'gap_after': 'right',
        },
        expected: [gap.toString()],
      );

    case 'missing_addend':
      // a + _ = c with c = a + b <= zr (A3.1 L3, C2.3 L2).
      final a = gen.nextIntInRange(aLo, min(aHi, zr - bLo));
      final b = gen.nextIntInRange(bLo, min(bHi, zr - a));
      final c = a + b;
      return Problem(
        template: 'equation_gap',
        skillId: spec.skillId,
        level: levelNumber,
        seed: seed,
        index: index,
        promptDe: level.promptDe,
        display: {
          'form': form,
          'op': op,
          'a': a,
          'b': b,
          'c': c,
          'gap_after': 'middle',
        },
        expected: [b.toString()],
      );

    case 'any_split':
      // _ + _ = N; every pair i + (N-i) for i = 1..N-1 is accepted (A3.2 L3).
      final totalRange = level.intListParam('total_range');
      final totalLo = totalRange.isEmpty ? 6 : totalRange[0];
      final totalHi = totalRange.isEmpty ? 10 : totalRange[1];
      final total = gen.nextIntInRange(totalLo, totalHi);
      final pairs = <String>[
        for (var i = 1; i <= total - 1; i++) '$i+${total - i}',
      ];
      return Problem(
        template: 'equation_gap',
        skillId: spec.skillId,
        level: levelNumber,
        seed: seed,
        index: index,
        promptDe: level.promptDe,
        display: {'form': form, 'op': op, 'total': total, 'gap_after': 'both'},
        expected: pairs,
      );

    case 'place_value':
      // Z Zehner + E Einer = ? ; expected = Z*10 + E, E may be >= 10.
      final tensRange = level.intListParam('tens_range');
      final onesRange = level.intListParam('ones_range');
      final tLo = tensRange.isEmpty ? 1 : tensRange[0];
      final tHi = tensRange.isEmpty ? 9 : tensRange[1];
      final oLo = onesRange.isEmpty ? 1 : onesRange[0];
      final oHi = onesRange.isEmpty ? 9 : onesRange[1];
      var tens = gen.nextIntInRange(tLo, tHi);
      final ones = gen.nextIntInRange(oLo, oHi);
      var attempts = 0;
      while (tens * 10 + ones > zr && attempts++ < 300) {
        tens = gen.nextIntInRange(tLo, tHi);
      }
      return Problem(
        template: 'equation_gap',
        skillId: spec.skillId,
        level: levelNumber,
        seed: seed,
        index: index,
        promptDe: level.promptDe,
        display: {
          'form': form,
          'op': op,
          'tens': tens,
          'ones': ones,
          'gap_after': 'result',
        },
        expected: [(tens * 10 + ones).toString()],
      );

    case 'half':
      // _ + _ = 2a with expected = a = total/2 (C1.3 L3).
      final a = gen.nextIntInRange(aLo, min(aHi, zr ~/ 2));
      final total = 2 * a;
      return Problem(
        template: 'equation_gap',
        skillId: spec.skillId,
        level: levelNumber,
        seed: seed,
        index: index,
        promptDe: level.promptDe,
        display: {'form': form, 'op': op, 'total': total, 'gap_after': 'both'},
        expected: [a.toString()],
      );

    case 'double':
      // a + a = _ with expected = 2a <= zr.
      final a = gen.nextIntInRange(aLo, min(aHi, zr ~/ 2));
      return Problem(
        template: 'equation_gap',
        skillId: spec.skillId,
        level: levelNumber,
        seed: seed,
        index: index,
        promptDe: level.promptDe,
        display: {'form': form, 'op': op, 'a': a, 'gap_after': 'result'},
        expected: [(2 * a).toString()],
      );

    case 'neighbor':
      // Nachbarzahlen: n ± 1, both neighbours accepted.
      final startRange = level.intListParam('start_range');
      final sLo = startRange.isEmpty ? aLo : startRange[0];
      final sHi = startRange.isEmpty ? aHi : startRange[1];
      final n = gen.nextIntInRange(max(sLo, 2), min(sHi, zr - 1));
      return Problem(
        template: 'equation_gap',
        skillId: spec.skillId,
        level: levelNumber,
        seed: seed,
        index: index,
        promptDe: level.promptDe,
        display: {'form': form, 'op': op, 'n': n, 'gap_after': 'both'},
        expected: [(n - 1).toString(), (n + 1).toString()],
      );

    case 'helper_double':
      // a + b = 2*min(a,b) + _, gap = a + b - 2*min (C2.2 L3, C3.3 L2).
      var a = gen.nextIntInRange(aLo, aHi);
      var b = gen.nextIntInRange(bLo, bHi);
      var attempts = 0;
      while (a == b && attempts++ < 300) {
        a = gen.nextIntInRange(aLo, aHi);
        b = gen.nextIntInRange(bLo, bHi);
      }
      final min = a < b ? a : b;
      final first = 2 * min;
      final gap = a + b - 2 * min;
      return Problem(
        template: 'equation_gap',
        skillId: spec.skillId,
        level: levelNumber,
        seed: seed,
        index: index,
        promptDe: level.promptDe,
        display: {
          'form': form,
          'op': op,
          'a': a,
          'b': b,
          'first': first,
          'gap_after': 'right',
        },
        expected: [gap.toString()],
      );

    default:
      throw SpecFormatException('equation_gap: unknown form "$form"');
  }
}

/// `word_problem` generator (P2 plan §5 rule 16, P3 §4.5b): picks a context
/// and two numbers, then builds a complete German story sentence. `op: "+|-"`
/// re-rolls the operation per problem (D1.2). `display` carries
/// `setting_de`/`object_de`/`a`/`b`/`op` (plus `ask_operation`); `expected`
/// is the numeric result, which is never negative (minus stories keep
/// `a >= b`). Numbers are always `>= 2` so plural object nouns stay
/// grammatical ("sind 4 Äpfel", "3 kommen dazu").
Problem _generateWordProblem(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final rawContexts = level.params['contexts'];
  if (rawContexts is! List || rawContexts.isEmpty) {
    throw SpecFormatException(
      'word_problem: "contexts" must be a non-empty list',
    );
  }
  final contexts = <Map<String, String>>[];
  for (final raw in rawContexts) {
    if (raw is! Map) {
      throw SpecFormatException(
        'word_problem: each context must be an object with setting_de/object_de',
      );
    }
    final setting = raw['setting_de'];
    final object = raw['object_de'];
    if (setting is! String ||
        setting.isEmpty ||
        object is! String ||
        object.isEmpty) {
      throw SpecFormatException(
        'word_problem: each context needs non-empty "setting_de" and '
        '"object_de"',
      );
    }
    contexts.add({'setting_de': setting, 'object_de': object});
  }

  final opParam = level.stringParam('op', fallback: '+');
  final mixedOp = opParam.contains('|');
  final op = mixedOp ? (gen.nextInt(2) == 0 ? '+' : '-') : opParam;
  final zr = level.intParam('zr', fallback: _maxZR);
  final askOperation = level.boolParam('ask_operation');

  final aRange = level.intListParam('a_range');
  final bRange = level.intListParam('b_range');

  int a, b;
  if (op == '-') {
    final aLo = aRange.isEmpty ? 2 : max(aRange[0], 2);
    final aHi = aRange.isEmpty ? zr : aRange[1];
    final bLo = min(bRange.isEmpty ? 2 : max(bRange[0], 2), aHi);
    a = gen.nextIntInRange(aLo, aHi);
    final bHi = min(bRange.isEmpty ? a : bRange[1], a);
    b = gen.nextIntInRange(bLo, bHi);
  } else {
    final aLo = aRange.isEmpty ? 2 : max(aRange[0], 2);
    final aHi = aRange.isEmpty ? zr ~/ 2 : aRange[1];
    final bLo = bRange.isEmpty ? 2 : max(bRange[0], 2);
    final bHi = bRange.isEmpty ? zr ~/ 2 : bRange[1];
    a = gen.nextIntInRange(aLo, aHi);
    b = gen.nextIntInRange(bLo, bHi);
    var attempts = 0;
    while (a + b > zr && attempts++ < 100) {
      a = gen.nextIntInRange(aLo, aHi);
      b = gen.nextIntInRange(bLo, bHi);
    }
    if (a + b > zr) b = max(bLo, zr - a);
  }

  final context = contexts[gen.nextInt(contexts.length)];
  final settingDe = context['setting_de']!;
  final objectDe = context['object_de']!;
  final result = op == '-' ? a - b : a + b;

  return Problem(
    template: 'word_problem',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: _wordSentence(settingDe, objectDe, a, b, op),
    display: {
      'setting_de': settingDe,
      'object_de': objectDe,
      'a': a,
      'b': b,
      'op': op,
      'ask_operation': askOperation,
    },
    expected: [result.toString()],
  );
}

/// Builds the complete German story sentence (P2 §5 rule 16): a setting
/// sentence, a second sentence that adds or takes away, and the standard
/// question. Every object noun in the specs is plural, and the generator
/// keeps both numbers `>= 2`, so the plural forms always agree.
String _wordSentence(
  String settingDe,
  String objectDe,
  int a,
  int b,
  String op,
) {
  final setting =
      settingDe.isEmpty ? settingDe : settingDe[0].toUpperCase() + settingDe.substring(1);
  final second =
      op == '-' ? '$b werden weggenommen' : '$b kommen dazu';
  return '$setting sind $a $objectDe. $second. Wie viele sind es?';
}

/// `strategy_choice` generator (P2 plan §5 rule 15, P3 §3): the child solves
/// `a op b` and then picks the strategy that was used. `display` carries
/// `a`, `b`, `op`, the full `strategies` list (with `label_de`) and the
/// `correct_strategy` for this problem; `expected` is the numeric result.
///
/// The numbers are chosen so they genuinely exemplify the strategy:
/// `verdoppeln` -> `a == b`, `fast_verdoppeln` -> `|a - b| == 1`,
/// `ueber_die_zehn` -> the ones cross a tens boundary (and the pair is not a
/// double/near-double). `correct_strategy: "mixed"` (C4.1 L3) rotates through
/// the spec's strategies across the problems of the level, so a mixed level
/// varies its strategies.
Problem _generateStrategyChoice(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final op = level.stringParam('op', fallback: '+');
  final zr = level.intParam('zr', fallback: _maxZR);
  final aRange = level.intListParam('a_range');
  final bRange = level.intListParam('b_range');
  final aLo = aRange.isEmpty ? 1 : aRange[0];
  final aHi = aRange.isEmpty ? zr : aRange[1];
  final bLo = bRange.isEmpty ? 1 : bRange[0];
  final bHi = bRange.isEmpty ? zr : bRange[1];

  final rawStrategies = level.params['strategies'];
  if (rawStrategies is! List || rawStrategies.isEmpty) {
    throw SpecFormatException(
      'strategy_choice: "strategies" must be a non-empty list',
    );
  }
  final strategies = <Map<String, String>>[];
  for (final raw in rawStrategies) {
    if (raw is! Map) {
      throw SpecFormatException(
        'strategy_choice: each strategy must be an object with id/label_de',
      );
    }
    final id = raw['id'];
    final label = raw['label_de'];
    if (id is! String || id.isEmpty || label is! String || label.isEmpty) {
      throw SpecFormatException(
        'strategy_choice: each strategy needs a non-empty "id" and "label_de"',
      );
    }
    strategies.add({'id': id, 'label_de': label});
  }

  final correctDirective = level.stringParam('correct_strategy');
  final mixed = correctDirective == 'mixed';
  if (!mixed && strategies.every((s) => s['id'] != correctDirective)) {
    throw SpecFormatException(
      'strategy_choice: correct_strategy "$correctDirective" is not among '
      '[${strategies.map((s) => s['id']).join(', ')}]',
    );
  }

  final strategyId =
      mixed ? strategies[index % strategies.length]['id']! : correctDirective;

  final numbers = _strategyNumbers(
    gen,
    strategyId,
    aLo,
    aHi,
    bLo,
    bHi,
    zr,
    op,
  );
  final a = numbers.$1;
  final b = numbers.$2;
  final result = op == '-' ? a - b : a + b;

  return Problem(
    template: 'strategy_choice',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {
      'op': op,
      'a': a,
      'b': b,
      'strategies': strategies,
      'correct_strategy': strategyId,
    },
    expected: [result.toString()],
  );
}

/// Draws `(a, b)` that genuinely exemplify [strategy] within the parameterised
/// ranges and ZR. Subtraction stays non-negative. Unknown strategies are a
/// spec-authoring error and fail loudly rather than silently producing
/// numbers that do not exemplify anything.
(int, int) _strategyNumbers(
  SeededGenerator gen,
  String strategy,
  int aLo,
  int aHi,
  int bLo,
  int bHi,
  int zr,
  String op,
) {
  if (op == '-') {
    final a = gen.nextIntInRange(max(aLo, bLo), aHi);
    final b = _clampedDraw(gen, bLo, bHi, a);
    return (a, b);
  }

  switch (strategy) {
    case 'verdoppeln':
      final lo = max(max(aLo, bLo), 1);
      final hi = min(min(aHi, bHi), zr ~/ 2);
      if (hi < lo) {
        throw SpecFormatException(
          'strategy_choice: "verdoppeln" ranges cannot produce a == b inside '
          'zr $zr',
        );
      }
      final n = gen.nextIntInRange(lo, hi);
      return (n, n);

    case 'fast_verdoppeln':
      // Near-double (m, m+1) in either order, with 2m+1 <= zr.
      final m0Lo = max(max(aLo, bLo - 1), 1);
      final m0Hi = min(min(aHi, bHi - 1), (zr - 1) ~/ 2);
      final m1Lo = max(max(aLo - 1, bLo), 1);
      final m1Hi = min(min(aHi - 1, bHi), (zr - 1) ~/ 2);
      final can0 = m0Lo <= m0Hi;
      final can1 = m1Lo <= m1Hi;
      if (!can0 && !can1) {
        throw SpecFormatException(
          'strategy_choice: "fast_verdoppeln" ranges cannot produce a '
          'near-double inside zr $zr',
        );
      }
      final int m;
      final int orient;
      if (can0 && can1) {
        m = gen.nextIntInRange(min(m0Lo, m1Lo), max(m0Hi, m1Hi));
        final in0 = m >= m0Lo && m <= m0Hi;
        final in1 = m >= m1Lo && m <= m1Hi;
        orient = in0 && in1 ? gen.nextInt(2) : (in0 ? 0 : 1);
      } else if (can0) {
        m = gen.nextIntInRange(m0Lo, m0Hi);
        orient = 0;
      } else {
        m = gen.nextIntInRange(m1Lo, m1Hi);
        orient = 1;
      }
      return orient == 0 ? (m, m + 1) : (m + 1, m);

    case 'ueber_die_zehn':
      // Ones cross a tens boundary; exclude doubles/near-doubles so the
      // "Über die Zehn" strategy is the genuinely indicated one.
      for (var attempts = 0; attempts < 300; attempts++) {
        final a = gen.nextIntInRange(aLo, aHi);
        final b = gen.nextIntInRange(bLo, bHi);
        if (a + b <= zr &&
            (a % 10) + (b % 10) >= 10 &&
            a != b &&
            (a - b).abs() > 1) {
          return (a, b);
        }
      }
      final fallbackA = gen.nextIntInRange(aLo, aHi);
      final fallbackB = _clampedDraw(gen, bLo, bHi, zr - fallbackA);
      return (fallbackA, fallbackB);

    default:
      throw SpecFormatException(
        'strategy_choice: unsupported strategy "$strategy"',
      );
  }
}

/// `drag_partition` generator (P2 plan §5 rule 1, P3 §4.5b): split `total`
/// into `parts` boxes under the parameterised `split_constraint` (or the
/// legacy `equal: true` flag). The widget evaluates the child's split
/// semantically, so `expected` stays empty while `display` carries
/// `total`, `parts`, `box_labels`, `split_constraint` and the canonical
/// `boxes` (plus the two operands `a`/`b` for `tens_ones`).
Problem _generateDragPartition(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final totalRange = level.intListParam('total_range');
  final totalLo = totalRange.isEmpty ? 6 : totalRange[0];
  final totalHi = totalRange.isEmpty ? 10 : totalRange[1];
  final parts = level.intParam('parts', fallback: 2);
  final boxLabels =
      ((level.params['box_labels'] as List?) ?? const []).cast<String>();
  if (boxLabels.length != parts) {
    throw SpecFormatException(
      'drag_partition: "box_labels" must have one entry per part ($parts), '
      'found ${boxLabels.length}',
    );
  }

  final constraintParam = level.stringParam('split_constraint');
  final splitConstraint = constraintParam.isNotEmpty
      ? constraintParam
      : (level.boolParam('equal') ? 'equal' : 'sum');

  final boxes =
      _dragPartitionBoxes(gen, splitConstraint, parts, totalLo, totalHi);
  final total = boxes.reduce((a, b) => a + b);

  final display = <String, dynamic>{
    'total': total,
    'parts': parts,
    'split_constraint': splitConstraint,
    'box_labels': boxLabels,
    'boxes': boxes,
  };
  if (splitConstraint == 'tens_ones') {
    display['a'] = boxes[0];
    display['b'] = boxes[1] + boxes[2];
  }

  return Problem(
    template: 'drag_partition',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: display,
    expected: const [],
  );
}

/// Picks the canonical `parts` box counts for one [drag_partition] problem
/// under [splitConstraint]. Every emitted split honours the constraint
/// (a wrong split like 15 = 9 + 6 is never produced for `make_ten`).
List<int> _dragPartitionBoxes(
  SeededGenerator gen,
  String splitConstraint,
  int parts,
  int totalLo,
  int totalHi,
) {
  switch (splitConstraint) {
    case 'sum':
      // Any split of `total` into `parts` positive integers.
      if (totalHi < parts) {
        throw SpecFormatException(
          'drag_partition: total_range max ($totalHi) < parts ($parts): no '
          'valid positive split exists',
        );
      }
      final lo = totalLo < parts ? parts : totalLo;
      final total = gen.nextIntInRange(lo, totalHi);
      final boxes = <int>[];
      var remaining = total;
      for (var i = 0; i < parts - 1; i++) {
        final maxForBox = remaining - (parts - 1 - i);
        final b = gen.nextIntInRange(1, maxForBox);
        boxes.add(b);
        remaining -= b;
      }
      boxes.add(remaining);
      return boxes;

    case 'equal':
      // All boxes equal and sum == total; total must be divisible by parts.
      final candidates = <int>[
        for (var t = totalLo < parts ? parts : totalLo; t <= totalHi; t++)
          if (t % parts == 0) t,
      ];
      if (candidates.isEmpty) {
        throw SpecFormatException(
          'drag_partition: no total in [$totalLo, $totalHi] divisible by '
          'parts $parts for split_constraint "equal"',
        );
      }
      final total = candidates[gen.nextInt(candidates.length)];
      final part = total ~/ parts;
      return List<int>.filled(parts, part);

    case 'make_ten':
      // One box exactly 10, the other total - 10; totals 11..19.
      if (parts != 2) {
        throw SpecFormatException(
          'drag_partition: "make_ten" requires parts == 2, got $parts',
        );
      }
      final total = gen.nextIntInRange(
        totalLo < 11 ? 11 : totalLo,
        totalHi > 19 ? 19 : totalHi,
      );
      return [10, total - 10];

    case 'near_double':
      // 3 boxes: two equal n, third == 1; total == 2n+1 (odd, 11..19).
      if (parts != 3) {
        throw SpecFormatException(
          'drag_partition: "near_double" requires parts == 3, got $parts',
        );
      }
      final odds = <int>[
        for (var t = totalLo < 11 ? 11 : totalLo; t <= (totalHi > 19 ? 19 : totalHi); t++)
          if (t.isOdd) t,
      ];
      if (odds.isEmpty) {
        throw SpecFormatException(
          'drag_partition: no odd total in [11, 19] for "near_double"',
        );
      }
      final total = odds[gen.nextInt(odds.length)];
      final n = (total - 1) ~/ 2;
      return [n, n, 1];

    case 'tens_ones':
      // 3 boxes: [a, 10*floor(b/10), b%10] with a + b == total.
      if (parts != 3) {
        throw SpecFormatException(
          'drag_partition: "tens_ones" requires parts == 3, got $parts',
        );
      }
      if (totalHi < 12) {
        throw SpecFormatException(
          'drag_partition: "tens_ones" needs totals >= 12 (a >= 1, b >= 11), '
          'got total_range max $totalHi',
        );
      }
      var total = gen.nextIntInRange(totalLo, totalHi);
      var a = 1;
      for (var attempts = 0; attempts < 300; attempts++) {
        final aMax = total - 11; // keep b = total - a >= 11
        if (aMax < 1) {
          total = gen.nextIntInRange(
            totalLo < 12 ? 12 : totalLo,
            totalHi,
          );
          continue;
        }
        a = gen.nextIntInRange(1, aMax);
        if ((total - a) % 10 >= 1) break; // Einer box must hold >= 1
      }
      final b = total - a;
      return [a, 10 * (b ~/ 10), b % 10];

    default:
      throw SpecFormatException(
        'drag_partition: unknown split_constraint "$splitConstraint"',
      );
  }
}

/// `place_counters` generator (P2 plan §5 rule 2, P3 §3): the child taps
/// cells in a frame to fill a target count or to take away `count` from a
/// starting `total`. Per-frame capacity caps `count` (and `total`) so a
/// single ten-frame never holds more than 10 counters.
///
/// `mode: "nonstandard"` (B2.3 L1) shows the Stellenwerttafel in non-standard
/// form: the number `n` is decomposed as `tens = n div 10 - 1`,
/// `ones = 10 + n mod 10` (so the Einer column holds 10..19 and
/// `10*tens + ones == n` always — P3 §4.5). `display` carries `tens` and
/// `ones` so the widget can check `10*tens_placed + ones_placed == count`
/// where `ones_placed` may exceed 9.
Problem _generatePlaceCounters(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final countRange = level.intListParam('count_range');
  final countLo = countRange.isEmpty ? 1 : countRange[0];
  final countHi = countRange.isEmpty ? 10 : countRange[1];
  final frame = level.stringParam('frame', fallback: 'zehnerfeld');
  final action = level.stringParam('action', fallback: 'fill');
  final mode = level.stringParam('mode', fallback: 'standard');

  final int frameCap = switch (frame) {
    'rekenrek' => 20,
    'stellenwerttafel' => 99,
    _ => 10,
  };
  final top = countHi > frameCap ? frameCap : countHi;
  if (top < countLo) {
    throw SpecFormatException(
      'place_counters: frame "$frame" holds at most $frameCap counters but '
      'count_range starts at $countLo',
    );
  }

  if (mode == 'nonstandard') {
    // B2.3 L1: non-standard decomposition with the Einer column holding
    // 10..19. The tens digit is n div 10 - 1, which is >= 1 only for
    // n >= 20 — clamp the sample so the picture always shows a Zehner.
    final lo = countLo < 20 ? 20 : countLo;
    if (lo > top) {
      throw SpecFormatException(
        'place_counters: mode "nonstandard" needs counts >= 20 (so the '
        'non-standard decomposition has tens >= 1), got count_range '
        '[$countLo, $countHi]',
      );
    }
    final count = gen.nextIntInRange(lo, top);
    final tens = count ~/ 10 - 1;
    final ones = 10 + count % 10;
    return Problem(
      template: 'place_counters',
      skillId: spec.skillId,
      level: levelNumber,
      seed: seed,
      index: index,
      promptDe: level.promptDe,
      display: {
        'count': count,
        'frame': frame,
        'action': action,
        'mode': mode,
        'tens': tens,
        'ones': ones,
      },
      expected: [count.toString()],
    );
  }

  final count = gen.nextIntInRange(countLo, top);

  final display = <String, dynamic>{
    'count': count,
    'frame': frame,
    'action': action,
  };
  if (action == 'take_away') {
    final total = gen.nextIntInRange(count, top);
    display['total'] = total;
    display['remaining'] = total - count;
  }

  return Problem(
    template: 'place_counters',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: display,
    expected: [count.toString()],
  );
}

/// `bundle_sticks` generator (P2 plan §5 rule 3, P3 §4.5b): pick a stick
/// count (at least 12, so the canonical answer always needs >= 1 Zehner
/// bundle) and emit the canonical `"Z Zehner, E Einer"` string.
Problem _generateBundleSticks(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final countRange = level.intListParam('count_range');
  final countLo = countRange.isEmpty ? 12 : countRange[0];
  final countHi = countRange.isEmpty ? 39 : countRange[1];
  final lo = countLo < 12 ? 12 : countLo;
  if (lo > countHi) {
    throw SpecFormatException(
      'bundle_sticks: count_range must allow counts >= 12 (bundling), got '
      '[$countLo, $countHi]',
    );
  }
  final count = gen.nextIntInRange(lo, countHi);
  final bundles = count ~/ 10;
  final singles = count % 10;

  return Problem(
    template: 'bundle_sticks',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {'count': count, 'bundles': bundles, 'singles': singles},
    expected: ['$bundles Zehner, $singles Einer'],
  );
}

/// `rekenrek_set` generator (P2 plan §5 rule 4): the child slides beads on a
/// two-row Rekenrek to reproduce `count` (1..20); `expected` is the count.
Problem _generateRekenrekSet(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final countRange = level.intListParam('count_range');
  final countLo = countRange.isEmpty ? 1 : countRange[0];
  final countHi = countRange.isEmpty ? 20 : countRange[1];
  final rows = level.intParam('rows', fallback: 2);
  final lo = countLo < 1 ? 1 : countLo;
  final top = countHi > 20 ? 20 : countHi;
  if (lo > top) {
    throw SpecFormatException(
      'rekenrek_set: count_range must lie within [1, 20], got '
      '[$countLo, $countHi]',
    );
  }
  final count = gen.nextIntInRange(lo, top);

  return Problem(
    template: 'rekenrek_set',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {'count': count, 'rows': rows},
    expected: [count.toString()],
  );
}

/// `numberline_step` generator (P2 plan §5 rule 5, P3 §4.5b): the child taps
/// successive numbers from `start` to `target` in the given direction and
/// step. `start` is sampled from `start_range` filtered to values congruent
/// to `target` mod `step` (A1.3 L1 step 2 keeps only even starts), strictly
/// before the target (up) / after it (down) so the tapped run is never
/// empty. `expected` is the exact run `start+step … target` (or
/// `start−step … target` for down) that the widget must accept.
Problem _generateNumberlineStep(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final range = level.intListParam('range');
  final rangeLo = range.isEmpty ? 0 : range[0];
  final rangeHi = range.isEmpty ? 20 : range[1];
  final startRange = level.intListParam('start_range');
  final startLo = startRange.isEmpty ? rangeLo : startRange[0];
  final startHi = startRange.isEmpty ? rangeHi : startRange[1];
  final target = level.intParam('target', fallback: rangeHi);
  final step = level.intParam('step', fallback: 1);
  final direction = level.stringParam('direction', fallback: 'up');

  if (target < rangeLo || target > rangeHi) {
    throw SpecFormatException(
      'numberline_step: target $target lies outside the line range '
      '[$rangeLo, $rangeHi]',
    );
  }
  if (step < 1) {
    throw SpecFormatException(
      'numberline_step: step must be >= 1, got $step',
    );
  }
  if (!const {1, 2, 5, 10}.contains(step)) {
    throw SpecFormatException(
      'numberline_step: step must be one of 1, 2, 5, 10 (P3 §4.5), got $step',
    );
  }

  // Start candidates: inside start_range, on the same residue class as the
  // target mod step, ordered strictly before/after the target, and on the
  // line. A congruent start guarantees the stepped run lands exactly on the
  // target.
  final candidates = <int>[];
  for (var s = startLo; s <= startHi; s++) {
    final congruent = s % step == target % step;
    final ordered = direction == 'up' ? s < target : s > target;
    final onLine = s >= rangeLo && s <= rangeHi;
    if (congruent && ordered && onLine) candidates.add(s);
  }
  if (candidates.isEmpty) {
    throw SpecFormatException(
      'numberline_step: no start in [$startLo, $startHi] congruent to '
      '$target mod $step with direction $direction can reach the target',
    );
  }
  final start = candidates[gen.nextInt(candidates.length)];

  final dir = direction == 'up' ? 1 : -1;
  final tapped = <String>[];
  for (var v = start + dir * step;
      direction == 'up' ? v <= target : v >= target;
      v += dir * step) {
    tapped.add(v.toString());
  }
  if (tapped.isEmpty || tapped.last != target.toString()) {
    throw SpecFormatException(
      'numberline_step: congruence violation — start $start step $step '
      'cannot reach target $target',
    );
  }

  return Problem(
    template: 'numberline_step',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {
      'range': [rangeLo, rangeHi],
      'start': start,
      'target': target,
      'step': step,
      'direction': direction,
    },
    expected: tapped,
  );
}

/// `zehnerfeld_read` generator (P2 plan §5 rule 6, P3 §3): show a filled
/// ten-frame pattern and type the count. `two_groups` renders two groups of
/// counters (up to 20 across two frames) and the display carries the
/// `split` (a + b == count, each 1..10) the widget fills; `five_pattern`
/// keeps the count <= 10 so it fits one structured ten-frame.
Problem _generateZehnerfeldRead(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final countRange = level.intListParam('count_range');
  final arrangement = level.stringParam('arrangement', fallback: 'structured');
  final twoGroups = arrangement == 'two_groups';
  final cap = twoGroups ? 20 : 10;
  final countLo = countRange.isEmpty ? 1 : max(countRange[0], 1);
  final countHiRaw = countRange.isEmpty ? cap : countRange[1];
  final countHi = min(countHiRaw, cap);
  if (countHi < countLo) {
    throw SpecFormatException(
      'zehnerfeld_read: arrangement "$arrangement" holds at most $cap '
      'counters but count_range starts at $countLo',
    );
  }
  final count = gen.nextIntInRange(countLo, countHi);

  final display = <String, dynamic>{'count': count, 'arrangement': arrangement};
  if (twoGroups) {
    // Split into two frames: each part in [1, 10], both >= 1, summing to
    // count (e.g. 17 -> [10, 7]).
    final aLo = max(1, count - 10);
    final aHi = min(10, count - 1);
    final a = gen.nextIntInRange(aLo, aHi);
    display['split'] = [a, count - a];
  }

  return Problem(
    template: 'zehnerfeld_read',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: display,
    expected: [count.toString()],
  );
}

/// `fingerbild_read` generator (P2 plan §5 rule 7): show a
/// [FingerDisplayWidget] and type the count. `hands: 1` caps the count at 5
/// (one hand); `hands: 2` allows up to 10 (both hands may be used).
Problem _generateFingerbildRead(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final countRange = level.intListParam('count_range');
  final hands = level.intParam('hands', fallback: 2);
  final cap = hands == 1 ? 5 : 10;
  final countLo = countRange.isEmpty ? 1 : max(countRange[0], 1);
  final countHiRaw = countRange.isEmpty ? cap : countRange[1];
  final countHi = min(countHiRaw, cap);
  if (countHi < countLo) {
    throw SpecFormatException(
      'fingerbild_read: $hands hand(s) show at most $cap fingers but '
      'count_range starts at $countLo',
    );
  }
  final count = gen.nextIntInRange(countLo, countHi);

  return Problem(
    template: 'fingerbild_read',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {'count': count, 'hands': hands},
    expected: [count.toString()],
  );
}

/// `stellenwerttafel_read` generator (P2 plan §5 rule 8, P3 §3): read a
/// Stellenwerttafel. Mode `read` shows counters in the Z/E columns of a
/// number in [11, 99]; mode `sum_rows` shows two rows of column counters
/// (each 0..9) that the child adds (or subtracts column-wise) — the `op`
/// param is authoritative and the generator guarantees a non-negative
/// result (`row1 >= row2`; for `-` the columns never need a borrow and the
/// result stays two-digit).
Problem _generateStellenwerttafelRead(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final mode = level.stringParam('mode', fallback: 'read');
  final columns =
      ((level.params['columns'] as List?) ?? const ['Z', 'E']).cast<String>();
  if (columns.isEmpty) {
    throw SpecFormatException('stellenwerttafel_read: "columns" is empty');
  }

  if (mode == 'sum_rows') {
    final op = level.stringParam('op', fallback: '+');
    if (op != '+' && op != '-') {
      throw SpecFormatException(
        'stellenwerttafel_read: sum_rows op must be "+" or "-", got "$op"',
      );
    }
    final int t1, o1, t2, o2, value;
    if (op == '+') {
      final onesRange = level.intListParam('ones_range');
      if (onesRange.isNotEmpty) {
        // "viele Einer" (B1.3 L2, B2.3 L2): the E column holds 10..19
        // counters across the two rows. Each row digit stays <= 9; the
        // composed value = (t1+t2)*10 + (o1+o2). The tens are capped so the
        // result never exceeds ZR100 even with ones up to 18.
        final oLo = onesRange[0];
        final oHi = onesRange[1];
        if (oLo < 10) {
          throw SpecFormatException(
            'stellenwerttafel_read: sum_rows ones_range must start >= 10 for '
            'the "viele Einer" form, got $oLo',
          );
        }
        if (oLo > min(oHi, 18)) {
          throw SpecFormatException(
            'stellenwerttafel_read: sum_rows ones_range [$oLo, $oHi] has no '
            'ones total in [10, 18]',
          );
        }
        final totalOnes = gen.nextIntInRange(oLo, min(oHi, 18));
        o1 = gen.nextIntInRange(max(0, totalOnes - 9), min(9, totalOnes));
        o2 = totalOnes - o1;
        t1 = gen.nextIntInRange(1, 7);
        t2 = gen.nextIntInRange(1, 8 - t1);
        value = (t1 + t2) * 10 + totalOnes;
      } else {
        // Standard sum_rows: column sums stay <= 9 so the result never
        // exceeds ZR100 and no carry is needed.
        t1 = gen.nextIntInRange(1, 8);
        t2 = gen.nextIntInRange(1, 9 - t1);
        o1 = gen.nextIntInRange(0, 9);
        o2 = gen.nextIntInRange(0, 9 - o1);
        value = (t1 + t2) * 10 + (o1 + o2);
      }
    } else {
      // row1 > row2 (two-digit result, never negative); each subtrahend
      // column <= the minuend column so the child never has to borrow.
      t1 = gen.nextIntInRange(2, 9);
      t2 = gen.nextIntInRange(1, t1 - 1);
      o1 = gen.nextIntInRange(0, 9);
      o2 = gen.nextIntInRange(0, o1);
      value = (t1 - t2) * 10 + (o1 - o2);
    }
    return Problem(
      template: 'stellenwerttafel_read',
      skillId: spec.skillId,
      level: levelNumber,
      seed: seed,
      index: index,
      promptDe: level.promptDe,
      display: {
        'mode': 'sum_rows',
        'op': op,
        'columns': columns,
        'row1': [t1, o1],
        'row2': [t2, o2],
        'value': value,
      },
      expected: [value.toString()],
    );
  }

  final numberRange = level.intListParam('number_range');
  final nLo = numberRange.isEmpty ? 11 : numberRange[0];
  final nHi = numberRange.isEmpty ? 99 : numberRange[1];
  final lo = max(nLo, 11);
  final hi = min(nHi, 99);
  if (hi < lo) {
    throw SpecFormatException(
      'stellenwerttafel_read: number_range [$nLo, $nHi] has no value in '
      '[11, 99] for mode read',
    );
  }
  final number = gen.nextIntInRange(lo, hi);
  final tens = number ~/ 10;
  final ones = number % 10;

  return Problem(
    template: 'stellenwerttafel_read',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {
      'mode': 'read',
      'columns': columns,
      'number': number,
      'tens': tens,
      'ones': ones,
    },
    expected: [number.toString()],
  );
}

/// `numberline_locate` generator (P2 plan §5 rule 9): tap where `value`
/// sits on the line. `value` is drawn from `value_range` clamped inside
/// `range` and never equals an endpoint (the endpoints would be
/// indistinguishable from the boundary of the widget).
Problem _generateNumberlineLocate(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final range = level.intListParam('range');
  final rangeLo = range.isEmpty ? 0 : range[0];
  final rangeHi = range.isEmpty ? 20 : range[1];
  final valueRange = level.intListParam('value_range');
  final vLo = valueRange.isEmpty ? rangeLo + 1 : valueRange[0];
  final vHi = valueRange.isEmpty ? rangeHi - 1 : valueRange[1];
  final lo = max(vLo, rangeLo + 1);
  final hi = min(vHi, rangeHi - 1);
  if (hi < lo) {
    throw SpecFormatException(
      'numberline_locate: value_range [$vLo, $vHi] leaves no interior point '
      'in [$rangeLo, $rangeHi]',
    );
  }
  final value = gen.nextIntInRange(lo, hi);

  return Problem(
    template: 'numberline_locate',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {'range': [rangeLo, rangeHi], 'value': value},
    expected: [value.toString()],
  );
}

/// `picture_compare` generator (P2 plan §5 rule 10): two ten-frame counts,
/// re-rolled until |left − right| >= `difference_min` (default 1) so a
/// `more`/`less` question always has a definite larger/smaller side and a
/// `difference` question always has a positive answer. `expected` is the
/// tapped side id (`"left"`/`"right"`) or the difference.
Problem _generatePictureCompare(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final leftRange = level.intListParam('left_range');
  final rightRange = level.intListParam('right_range');
  final leftLo = leftRange.isEmpty ? 1 : leftRange[0];
  final leftHi = leftRange.isEmpty ? 10 : leftRange[1];
  final rightLo = rightRange.isEmpty ? 1 : rightRange[0];
  final rightHi = rightRange.isEmpty ? 10 : rightRange[1];
  final question = level.stringParam('question', fallback: 'more');
  final differenceMin = level.intParam('difference_min', fallback: 1);
  if (differenceMin < 1) {
    throw SpecFormatException(
      'picture_compare: difference_min must be >= 1, got $differenceMin',
    );
  }

  var left = gen.nextIntInRange(leftLo, leftHi);
  var right = gen.nextIntInRange(rightLo, rightHi);
  var attempts = 0;
  while ((left - right).abs() < differenceMin && attempts++ < 300) {
    left = gen.nextIntInRange(leftLo, leftHi);
    right = gen.nextIntInRange(rightLo, rightHi);
  }
  if ((left - right).abs() < differenceMin) {
    throw SpecFormatException(
      'picture_compare: left_range [$leftLo, $leftHi] and right_range '
      '[$rightLo, $rightHi] cannot differ by $differenceMin',
    );
  }

  final diff = (left - right).abs();
  final expected = switch (question) {
    'more' => left > right ? 'left' : 'right',
    'less' => left < right ? 'left' : 'right',
    'difference' => diff.toString(),
    _ => throw SpecFormatException(
      'picture_compare: unknown question "$question" '
      '(expected more, less or difference)',
    ),
  };

  return Problem(
    template: 'picture_compare',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {'left': left, 'right': right, 'question': question},
    expected: [expected],
  );
}

/// Dispatches to the per-registry-key custom-widget generator (P2 plan §5
/// custom_widget registry). Unknown keys are rejected by [SkillSpec] parsing
/// (`kKnownCustomWidgets`); this throws rather than silently generating so a
/// spec that slips through still fails loudly.
Problem _generateCustomWidget(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  switch (level.customWidget) {
    case 'bundling':
      return _generateBundling(spec, level, levelNumber, seed, index, gen);
    case 'unbundling':
      return _generateUnbundling(spec, level, levelNumber, seed, index, gen);
    case 'numberline_mark':
      return _generateNumberlineMark(spec, level, levelNumber, seed, index, gen);
    case 'flash_subitize':
      return _generateFlashSubitize(spec, level, levelNumber, seed, index, gen);
    default:
      throw SpecFormatException(
        'custom_widget: unknown registry key "${level.customWidget}"',
      );
  }
}

/// Registry key `"bundling"` (B1.2 Bündeln): the widget renders ungrouped
/// sticks and the child bundles them into tens. The widget evaluates
/// semantically — correct iff `10*bundles + singles == count` and, since
/// counts are always >= 12, `bundles >= 1` — so `expected` stays empty while
/// `display` carries `count` plus the canonical `bundles`/`singles` split
/// (the DB stores the canonical `"Z Zehner, E Einer"` string built from
/// them).
Problem _generateBundling(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final numberRange = level.intListParam('number_range');
  final countLo = numberRange.isEmpty ? 12 : numberRange[0];
  final countHi = numberRange.isEmpty ? 39 : numberRange[1];
  final lo = countLo < 12 ? 12 : countLo;
  final hi = countHi > 39 ? 39 : countHi;
  if (lo > hi) {
    throw SpecFormatException(
      'bundling: number_range [$countLo, $countHi] must allow counts >= 12 '
      '(at least one Zehner bundle), got max $countHi',
    );
  }
  final count = gen.nextIntInRange(lo, hi);
  final bundles = count ~/ 10;
  final singles = count % 10;

  return Problem(
    template: 'custom_widget',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {
      'custom_widget': 'bundling',
      'count': count,
      'bundles': bundles,
      'singles': singles,
    },
    expected: const [],
  );
}

/// Registry key `"unbundling"` (B1.3 Entbündeln): the widget shows a bundled
/// picture `"Z Zehner, E Einer"` (bundles + loose singles) and asks
/// "wie viele Einer insgesamt?" — opening a bundle turns `Z` bundles into
/// `Z*10` single sticks, so the answer is `expected == Z*10 + E`. `display`
/// carries `tens`, `ones` and the total `count`. Both digits are kept >= 1 so
/// the picture always shows a Zehner bundle and loose Einer.
Problem _generateUnbundling(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final numberRange = level.intListParam('number_range');
  final countLo = numberRange.isEmpty ? 12 : numberRange[0];
  final countHi = numberRange.isEmpty ? 39 : numberRange[1];
  final totalLo = countLo < 12 ? 12 : countLo;
  final totalHi = countHi > 39 ? 39 : countHi;
  if (totalLo > totalHi) {
    throw SpecFormatException(
      'unbundling: number_range [$countLo, $countHi] must allow a bundled '
      'count >= 12 with at least one Zehner bundle',
    );
  }
  final combos = <(int, int)>[
    for (var tens = 1; tens <= 3; tens++)
      for (var ones = 1; ones <= 9; ones++)
        if (10 * tens + ones >= totalLo && 10 * tens + ones <= totalHi)
          (tens, ones),
  ];
  if (combos.isEmpty) {
    throw SpecFormatException(
      'unbundling: number_range [$countLo, $countHi] admits no bundled '
      'picture (tens 1..3, ones 1..9)',
    );
  }
  final (tens, ones) = combos[gen.nextInt(combos.length)];
  final count = 10 * tens + ones;

  return Problem(
    template: 'custom_widget',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {
      'custom_widget': 'unbundling',
      'tens': tens,
      'ones': ones,
      'count': count,
    },
    expected: [count.toString()],
  );
}

/// Registry key `"numberline_mark"` (B2.2): the child taps where `value`
/// sits on the line. `value` is drawn from `value_range` clamped strictly
/// inside `range` so it is never an endpoint (endpoints are
/// indistinguishable from the boundary of the widget). `expected == value`.
Problem _generateNumberlineMark(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final range = level.intListParam('range');
  final rangeLo = range.isEmpty ? 0 : range[0];
  final rangeHi = range.isEmpty ? 100 : range[1];
  final valueRange = level.intListParam('value_range');
  final vLo = valueRange.isEmpty ? rangeLo + 1 : valueRange[0];
  final vHi = valueRange.isEmpty ? rangeHi - 1 : valueRange[1];
  final lo = max(vLo, rangeLo + 1);
  final hi = min(vHi, rangeHi - 1);
  if (hi < lo) {
    throw SpecFormatException(
      'numberline_mark: value_range [$vLo, $vHi] leaves no interior point in '
      '[$rangeLo, $rangeHi]',
    );
  }
  final value = gen.nextIntInRange(lo, hi);

  return Problem(
    template: 'custom_widget',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {
      'custom_widget': 'numberline_mark',
      'range': [rangeLo, rangeHi],
      'value': value,
    },
    expected: [value.toString()],
  );
}

/// Registry key `"flash_subitize"` (A2.1): a dot/Rekenrek pattern flashes for
/// `flash_ms` (800 ms) and the child types the count. `count` is drawn from
/// `count_range` clamped to the subitizable range 1..5 (P3 §4.5: max <= 5);
/// `display` carries `count`, `flash_ms` and the pattern `display`
/// (`"dots"` or `"rekenrek"`). `expected == count`.
Problem _generateFlashSubitize(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final countRange = level.intListParam('count_range');
  final countLo = countRange.isEmpty ? 1 : max(countRange[0], 1);
  final countHi = countRange.isEmpty ? 5 : min(countRange[1], 5);
  if (countHi < countLo) {
    throw SpecFormatException(
      'flash_subitize: count_range [$countLo, $countHi] has no subitizable '
      'count (subitizing is capped at 5)',
    );
  }
  final count = gen.nextIntInRange(countLo, countHi);
  final flashMs = level.intParam('flash_ms', fallback: 800);
  final pattern = level.stringParam('display', fallback: 'dots');
  if (pattern != 'dots' && pattern != 'rekenrek') {
    throw SpecFormatException(
      'flash_subitize: display must be "dots" or "rekenrek", got "$pattern"',
    );
  }

  return Problem(
    template: 'custom_widget',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {
      'custom_widget': 'flash_subitize',
      'count': count,
      'flash_ms': flashMs,
      'display': pattern,
    },
    expected: [count.toString()],
  );
}
