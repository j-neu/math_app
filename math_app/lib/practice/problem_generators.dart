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
