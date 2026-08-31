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
