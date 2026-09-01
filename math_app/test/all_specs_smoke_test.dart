import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/problem.dart';
import 'package:math_app/models/skill_spec.dart';
import 'package:math_app/practice/problem_generators.dart';

const String _specsDir = '../docs/clean-room/skills/specs';

/// True when the equation a Problem shows is arithmetically true and its
/// `expected` values really fill the gaps. Covers every equation_solve /
/// equation_gap form the runtime currently generates.
bool equationHolds(Problem p) {
  if (p.expected.isEmpty) return false;
  switch (p.template) {
    case 'equation_solve':
      final op = p.display['op'] as String? ?? '+';
      final unknown = p.display['unknown'] as String? ?? 'result';
      final mode = p.display['mode'] as String? ?? 'standard';
      final a = p.display['a'] as int?;
      final b = p.display['b'] as int?;
      final c = p.display['c'] as int?;
      if (a == null || b == null || c == null) return false;
      if (p.display['equal'] == true && a != b) return false;
      if (mode == 'place_value') {
        final tens = p.display['tens'] as int?;
        final ones = p.display['ones'] as int?;
        if (tens == null || ones == null) return false;
        if (tens * 10 + ones != c) return false;
      }
      final lhs = op == '-' ? a - b : a + b;
      if (lhs != c) return false;
      final expected = int.tryParse(p.expected.single);
      if (expected == null) return false;
      switch (unknown) {
        case 'result':
          return expected == c;
        case 'addend':
        case 'minuend':
          return expected == a;
        case 'subtrahend':
          return expected == b;
      }
      return false;
    case 'equation_gap':
      final form = p.display['form'] as String? ?? '';
      final op = p.display['op'] as String? ?? '+';
      switch (form) {
        case 'gap':
          final a = p.display['a'] as int?;
          final b = p.display['b'] as int?;
          final expected = int.tryParse(p.expected.single);
          if (a == null || b == null || expected == null) return false;
          return (op == '-' ? a - b : a + b) == expected;
        case 'helper':
          final a = p.display['a'] as int?;
          final b = p.display['b'] as int?;
          final first = p.display['first'] as int?;
          final gap = int.tryParse(p.expected.single);
          if (a == null || b == null || first == null || gap == null) {
            return false;
          }
          final left = op == '-' ? a - b : a + b;
          final right = op == '-' ? first - gap : first + gap;
          return left == right;
        case 'missing_addend':
          final a = p.display['a'] as int?;
          final c = p.display['c'] as int?;
          final expected = int.tryParse(p.expected.single);
          if (a == null || c == null || expected == null) return false;
          return a + expected == c;
        case 'any_split':
          final total = p.display['total'] as int?;
          if (total == null) return false;
          for (final pair in p.expected) {
            final parts = pair.split('+');
            if (parts.length != 2) return false;
            final left = int.tryParse(parts[0]);
            final right = int.tryParse(parts[1]);
            if (left == null || right == null) return false;
            if (left + right != total) return false;
          }
          return true;
        case 'place_value':
          final tens = p.display['tens'] as int?;
          final ones = p.display['ones'] as int?;
          final expected = int.tryParse(p.expected.single);
          if (tens == null || ones == null || expected == null) return false;
          return tens * 10 + ones == expected;
        case 'half':
          final total = p.display['total'] as int?;
          final expected = int.tryParse(p.expected.single);
          if (total == null || expected == null) return false;
          return total.isEven && expected == total ~/ 2;
        case 'double':
          final a = p.display['a'] as int?;
          final expected = int.tryParse(p.expected.single);
          if (a == null || expected == null) return false;
          return expected == 2 * a;
        case 'neighbor':
          final n = p.display['n'] as int?;
          if (n == null) return false;
          return p.expected.length == 2 &&
              p.expected[0] == '${n - 1}' &&
              p.expected[1] == '${n + 1}';
        case 'helper_double':
          final a = p.display['a'] as int?;
          final b = p.display['b'] as int?;
          final first = p.display['first'] as int?;
          final gap = int.tryParse(p.expected.single);
          if (a == null || b == null || first == null || gap == null) {
            return false;
          }
          return a + b == first + gap;
      }
      return false;
  }
  return false;
}

/// True when a word_problem / strategy_choice Problem is well-formed: the
/// result is the arithmetic value shown in the story/equation, subtraction is
/// never negative, ZR is respected, and (for strategy_choice) the chosen
/// strategy genuinely fits the numbers.
bool problemValid(Problem p) {
  if (p.expected.isEmpty) return false;
  final expected = int.tryParse(p.expected.single);
  if (expected == null) return false;
  final a = p.display['a'] as int?;
  final b = p.display['b'] as int?;
  if (a == null || b == null) return false;
  if (a < 1 || b < 1) return false;

  if (p.template == 'word_problem') {
    final op = p.display['op'] as String?;
    final setting = p.display['setting_de'] as String?;
    final object = p.display['object_de'] as String?;
    if (op == null || setting == null || object == null) return false;
    if (setting.isEmpty || object.isEmpty) return false;
    if (!p.promptDe.contains('Wie viele sind es?')) return false;
    if (!p.promptDe.contains('$a $object')) return false;
    if (op == '-') {
      if (a < b) return false;
      return expected == a - b;
    }
    if (op == '+') {
      if (a + b > 100) return false;
      return expected == a + b;
    }
    return false;
  }

  if (p.template == 'strategy_choice') {
    final op = p.display['op'] as String?;
    final strategy = p.display['correct_strategy'] as String?;
    final strategies = p.display['strategies'] as List?;
    if (op == null || strategy == null || strategies == null) return false;
    final ids = strategies.map((e) => (e as Map)['id']).toSet();
    if (!ids.contains(strategy)) return false;
    final result = op == '-' ? a - b : a + b;
    if (result != expected) return false;
    if (result > 100 || result < 0) return false;
    if (op == '-') return true;
    switch (strategy) {
      case 'verdoppeln':
        return a == b;
      case 'fast_verdoppeln':
        return (a - b).abs() == 1;
      case 'ueber_die_zehn':
        return (a % 10) + (b % 10) >= 10 && (a - b).abs() > 1;
    }
    return false;
  }

  return false;
}

/// True when a manipulative-template Problem (drag_partition,
/// place_counters, bundle_sticks, rekenrek_set) is well-formed: every
/// emitted split honours its split_constraint, counts respect their frame
/// capacity, bundle answers are canonical and subtraction never leaves a
/// negative remainder.
bool manipulativeValid(Problem p) {
  switch (p.template) {
    case 'drag_partition':
      final total = p.display['total'];
      final parts = p.display['parts'];
      final rawBoxes = p.display['boxes'];
      final constraint = p.display['split_constraint'];
      final rawLabels = p.display['box_labels'];
      if (total is! int || parts is! int || rawBoxes is! List) return false;
      if (constraint is! String || rawLabels is! List) return false;
      final boxes = rawBoxes.cast<int>();
      if (boxes.length != parts) return false;
      if (rawLabels.length != parts) return false;
      if (boxes.any((b) => b < 1)) return false;
      if (boxes.reduce((a, b) => a + b) != total) return false;
      switch (constraint) {
        case 'sum':
          return true;
        case 'equal':
          return total % parts == 0 && boxes.every((b) => b == total ~/ parts);
        case 'make_ten':
          return parts == 2 &&
              boxes.contains(10) &&
              boxes.any((b) => b == total - 10);
        case 'near_double':
          if (parts != 3 || !total.isOdd) return false;
          final n = (total - 1) ~/ 2;
          return total == 2 * n + 1 &&
              boxes.where((b) => b == n).length == 2 &&
              boxes.where((b) => b == 1).length == 1;
        case 'tens_ones':
          if (parts != 3) return false;
          final a = p.display['a'];
          final b = p.display['b'];
          if (a is! int || b is! int) return false;
          return a + b == total &&
              boxes[0] == a &&
              boxes[1] == 10 * (b ~/ 10) &&
              boxes[2] == b % 10;
      }
      return false;

    case 'place_counters':
      final count = p.display['count'];
      final frame = p.display['frame'];
      final action = p.display['action'];
      if (count is! int || frame is! String || action is! String) return false;
      if (count < 1) return false;
      if (frame == 'zehnerfeld' && count > 10) return false;
      if (frame == 'rekenrek' && count > 20) return false;
      if (p.display['mode'] == 'nonstandard') {
        // B2.3 L1: the Einer column holds 10..19 and 10*tens + ones == count.
        final tens = p.display['tens'];
        final ones = p.display['ones'];
        if (tens is! int || ones is! int) return false;
        if (tens < 1 || ones < 10 || ones > 19) return false;
        if (10 * tens + ones != count) return false;
      }
      if (action == 'take_away') {
        final total = p.display['total'];
        final remaining = p.display['remaining'];
        if (total is! int || remaining is! int) return false;
        if (total < count || remaining != total - count || remaining < 0) {
          return false;
        }
        if (p.display['op'] != '-') return false;
        // The evaluator grades the REMAINING count (total − count), not the
        // number of cells removed, so `expected` must carry the remainder.
        return p.expected.length == 1 && p.expected.single == '$remaining';
      }
      return p.expected.length == 1 && p.expected.single == '$count';

    case 'bundle_sticks':
      final count = p.display['count'];
      if (count is! int || count < 10) return false;
      final bundles = count ~/ 10;
      final singles = count % 10;
      if (p.display['bundles'] != bundles) return false;
      if (p.display['singles'] != singles) return false;
      return bundles >= 1 &&
          p.expected.length == 1 &&
          p.expected.single == '$bundles Zehner, $singles Einer';

    case 'rekenrek_set':
      final count = p.display['count'];
      if (count is! int || count < 1 || count > 20) return false;
      return p.display['rows'] == 2 &&
          p.expected.length == 1 &&
          p.expected.single == '$count';
  }
  return false;
}

/// True when a visual/reading-template Problem (numberline_step,
/// zehnerfeld_read, fingerbild_read, stellenwerttafel_read,
/// numberline_locate, picture_compare) is well-formed: the tapped number-line
/// run is the exact congruent sequence to the target, counts respect their
/// frame, the Stellenwerttafel arithmetic holds with a non-negative minus
/// result, locate values are never endpoints, and comparison questions always
/// have a definite answer.
bool visualReadingValid(Problem p) {
  if (p.expected.isEmpty) return false;
  switch (p.template) {
    case 'numberline_step':
      final range = p.display['range'];
      final start = p.display['start'];
      final target = p.display['target'];
      final step = p.display['step'];
      final direction = p.display['direction'];
      if (range is! List || range.length != 2) return false;
      if (start is! int || target is! int || step is! int) return false;
      if (direction is! String) return false;
      final lo = (range[0] as num).toInt();
      final hi = (range[1] as num).toInt();
      if (start < lo || start > hi || target < lo || target > hi) return false;
      if (!const {1, 2, 5, 10}.contains(step)) return false;
      if (direction != 'up' && direction != 'down') return false;
      if (start % step != target % step) return false;
      if (direction == 'up' && start >= target) return false;
      if (direction == 'down' && start <= target) return false;
      final dir = direction == 'up' ? 1 : -1;
      final expectedRun = <int>[];
      for (var v = start + dir * step;
          direction == 'up' ? v <= target : v >= target;
          v += dir * step) {
        expectedRun.add(v);
      }
      final values = p.expected.map(int.tryParse).toList();
      if (values.any((v) => v == null)) return false;
      if (values.length != expectedRun.length) return false;
      for (var i = 0; i < values.length; i++) {
        if (values[i] != expectedRun[i]) return false;
        if (values[i]! < lo || values[i]! > hi) return false;
      }
      return true;

    case 'zehnerfeld_read':
      final count = p.display['count'];
      final arrangement = p.display['arrangement'];
      if (count is! int || arrangement is! String || count < 1) return false;
      if (arrangement == 'two_groups') {
        final split = p.display['split'];
        if (split is! List || split.length != 2) return false;
        final a = (split[0] as num).toInt();
        final b = (split[1] as num).toInt();
        if (count > 20) return false;
        if (a < 1 || b < 1 || a > 10 || b > 10) return false;
        if (a + b != count) return false;
        final ask = p.display['ask'];
        if (ask is! String) return false;
        switch (ask) {
          case 'total':
            return p.expected.length == 1 && p.expected.single == '$count';
          case 'difference':
            final diff = (a - b).abs();
            return diff >= 1 &&
                p.expected.length == 1 &&
                p.expected.single == '$diff';
          case 'part':
            return a == b &&
                p.expected.length == 1 &&
                p.expected.single == '${count ~/ 2}';
        }
        return false;
      }
      if (count > 10) return false;
      if (arrangement != 'structured' && arrangement != 'five_pattern') {
        return false;
      }
      return p.expected.length == 1 && p.expected.single == '$count';

    case 'fingerbild_read':
      final count = p.display['count'];
      final hands = p.display['hands'];
      if (count is! int || hands is! int || count < 1) return false;
      if (hands == 1 && count > 5) return false;
      if (hands == 2 && count > 10) return false;
      if (hands != 1 && hands != 2) return false;
      return p.expected.length == 1 && p.expected.single == '$count';

    case 'stellenwerttafel_read':
      final mode = p.display['mode'];
      if (mode == 'read') {
        final number = p.display['number'];
        final tens = p.display['tens'];
        final ones = p.display['ones'];
        if (number is! int || tens is! int || ones is! int) return false;
        if (number < 11 || number > 99) return false;
        if (tens != number ~/ 10 || ones != number % 10) return false;
        return p.expected.length == 1 && p.expected.single == '$number';
      }
      if (mode == 'sum_rows') {
        final op = p.display['op'];
        final row1 = p.display['row1'];
        final row2 = p.display['row2'];
        if (op is! String || row1 is! List || row2 is! List) return false;
        if (row1.length != 2 || row2.length != 2) return false;
        final t1 = (row1[0] as num).toInt();
        final o1 = (row1[1] as num).toInt();
        final t2 = (row2[0] as num).toInt();
        final o2 = (row2[1] as num).toInt();
        for (final d in [t1, o1, t2, o2]) {
          if (d < 0 || d > 9) return false;
        }
        final int value;
        if (op == '+') {
          value = (t1 + t2) * 10 + (o1 + o2);
          if (value > 99) return false;
        } else if (op == '-') {
          value = (t1 - t2) * 10 + (o1 - o2);
          if (value < 0) return false;
        } else {
          return false;
        }
        return p.expected.length == 1 && p.expected.single == '$value';
      }
      return false;

    case 'numberline_locate':
      final range = p.display['range'];
      final value = p.display['value'];
      if (range is! List || range.length != 2 || value is! int) return false;
      final lo = (range[0] as num).toInt();
      final hi = (range[1] as num).toInt();
      if (value <= lo || value >= hi) return false;
      return p.expected.length == 1 && p.expected.single == '$value';

    case 'picture_compare':
      final left = p.display['left'];
      final right = p.display['right'];
      final question = p.display['question'];
      if (left is! int || right is! int || question is! String) return false;
      if (left < 1 || right < 1) return false;
      final diff = (left - right).abs();
      if (diff < 1) return false;
      switch (question) {
        case 'more':
          return p.expected.length == 1 &&
              p.expected.single == (left > right ? 'left' : 'right');
        case 'less':
          return p.expected.length == 1 &&
              p.expected.single == (left < right ? 'left' : 'right');
        case 'difference':
          return p.expected.length == 1 && p.expected.single == '$diff';
      }
      return false;
  }
  return false;
}

/// True when a custom-widget Problem is well-formed (P2 plan §5 custom_widget
/// registry). `bundling` is semantic — the widget evaluates the child's
/// bundles — so its `expected` stays empty while `count`/`bundles`/`singles`
/// carry the canonical split. `unbundling`, `numberline_mark` and
/// `flash_subitize` carry a concrete expected value.
bool customWidgetValid(Problem p) {
  if (p.template != 'custom_widget') return false;
  switch (p.display['custom_widget']) {
    case 'bundling':
      final count = p.display['count'];
      final bundles = p.display['bundles'];
      final singles = p.display['singles'];
      if (count is! int || bundles is! int || singles is! int) return false;
      if (count < 12 || count > 39) return false;
      if (bundles != count ~/ 10 || singles != count % 10) return false;
      if (bundles < 1) return false;
      return p.expected.isEmpty;
    case 'unbundling':
      final tens = p.display['tens'];
      final ones = p.display['ones'];
      final count = p.display['count'];
      if (tens is! int || ones is! int || count is! int) return false;
      if (tens < 1 || ones < 1) return false;
      if (10 * tens + ones != count) return false;
      return p.expected.length == 1 && p.expected.single == '$count';
    case 'numberline_mark':
      final range = p.display['range'];
      final value = p.display['value'];
      if (range is! List || range.length != 2 || value is! int) return false;
      final lo = (range[0] as num).toInt();
      final hi = (range[1] as num).toInt();
      if (value <= lo || value >= hi) return false;
      return p.expected.length == 1 && p.expected.single == '$value';
    case 'flash_subitize':
      final count = p.display['count'];
      final flashMs = p.display['flash_ms'];
      final pattern = p.display['display'];
      if (count is! int || flashMs is! int || pattern is! String) return false;
      if (count < 1 || count > 5) return false;
      if (flashMs != 800) return false;
      if (pattern != 'dots' && pattern != 'rekenrek') return false;
      return p.expected.length == 1 && p.expected.single == '$count';
  }
  return false;
}

/// True when a sequence_gap Problem is well-formed: the values form an
/// arithmetic sequence with the parameterised direction/step (or a geometric
/// doubling for `progression: "double"`), stay inside ZR100 (and >= 1 for
/// downward sequences), and `expected` lists exactly the values at
/// `gap_indices` in order.
bool sequenceGapValid(Problem p) {
  if (p.expected.isEmpty) return false;
  final values = p.display['values'];
  final gapIndices = p.display['gap_indices'];
  if (values is! List || gapIndices is! List) return false;
  final seq = values.map((v) => v is num ? v.toInt() : null).toList();
  if (seq.any((v) => v == null)) return false;
  final nums = seq.cast<int>();
  if (nums.isEmpty || nums.any((v) => v < 1 || v > 100)) return false;
  final direction = p.display['direction'] as String? ?? 'up';
  final progression = p.display['progression'] as String? ?? 'arithmetic';
  if (direction != 'up' && direction != 'down') return false;
  if (progression == 'double') {
    for (var i = 0; i < nums.length - 1; i++) {
      if (nums[i + 1] != 2 * nums[i]) return false;
    }
  } else {
    final step = p.display['step'];
    if (step is! int || step < 1) return false;
    final dir = direction == 'up' ? 1 : -1;
    for (var i = 0; i < nums.length - 1; i++) {
      if (nums[i + 1] - nums[i] != dir * step) return false;
    }
  }
  final indices = gapIndices
      .map((g) => g is num ? g.toInt() : -1)
      .toList();
  if (indices.any((g) => g < 0 || g >= nums.length)) return false;
  if (p.expected.length != indices.length) return false;
  for (var i = 0; i < indices.length; i++) {
    if (p.expected[i] != '${nums[indices[i]]}') return false;
  }
  return true;
}

/// True when a compare_symbols Problem is well-formed: `expected` is the
/// operator that truly holds between the two displayed numbers.
bool compareSymbolsValid(Problem p) {
  if (p.expected.isEmpty) return false;
  final a = p.display['a'];
  final b = p.display['b'];
  if (a is! int || b is! int) return false;
  final op = a > b ? '>' : (a < b ? '<' : '=');
  return p.expected.length == 1 && p.expected.single == op;
}

/// Routes a generated Problem to its template's semantic validity check, so
/// the full-bank smoke test can assert every problem (not just the ones the
/// per-group tests cover) is arithmetically/pedagogically well-formed.
bool problemSemanticallyValid(Problem p) {
  switch (p.template) {
    case 'equation_solve':
    case 'equation_gap':
      return equationHolds(p);
    case 'word_problem':
    case 'strategy_choice':
      return problemValid(p);
    case 'drag_partition':
    case 'place_counters':
    case 'bundle_sticks':
    case 'rekenrek_set':
      return manipulativeValid(p);
    case 'numberline_step':
    case 'zehnerfeld_read':
    case 'fingerbild_read':
    case 'stellenwerttafel_read':
    case 'numberline_locate':
    case 'picture_compare':
      return visualReadingValid(p);
    case 'sequence_gap':
      return sequenceGapValid(p);
    case 'compare_symbols':
      return compareSymbolsValid(p);
    case 'custom_widget':
      return customWidgetValid(p);
  }
  return false;
}

void main() {
  group('real specs: equation_solve / equation_gap levels generate', () {
    final dir = Directory(_specsDir);
    if (!dir.existsSync()) {
      fail('real spec tree must exist at $_specsDir');
    }
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final specs = [
      for (final file in files)
        SkillSpec.fromJson(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        ),
    ];

    test('every such level yields problem_count valid, true problems', () {
      var checkedLevels = 0;
      for (final spec in specs) {
        for (var level = 1; level <= 3; level++) {
          final levelSpec = spec.levelSpec(level);
          if (levelSpec.template != 'equation_solve' &&
              levelSpec.template != 'equation_gap') {
            continue;
          }
          checkedLevels++;
          for (var seed = 0; seed < 3; seed++) {
            final problems = generateProblems(
              spec: spec,
              level: level,
              seed: seed,
            );
            expect(
              problems,
              hasLength(levelSpec.problemCount),
              reason: '${spec.skillId} L$level seed $seed',
            );
            for (var i = 0; i < problems.length; i++) {
              final p = problems[i];
              expect(p.index, i, reason: '${spec.skillId} L$level');
              expect(p.expected, isNotEmpty);
              expect(p.promptDe, isNotEmpty);
              expect(
                equationHolds(p),
                isTrue,
                reason: '${spec.skillId} L$level seed $seed: '
                    '${jsonEncode(p.toJson())}',
              );
            }
          }
        }
      }
      expect(checkedLevels, greaterThan(0));
    });

    test('generation is deterministic on the real specs', () {
      for (final spec in specs) {
        for (var level = 1; level <= 3; level++) {
          final levelSpec = spec.levelSpec(level);
          if (levelSpec.template != 'equation_solve' &&
              levelSpec.template != 'equation_gap') {
            continue;
          }
          final a = generateProblems(spec: spec, level: level, seed: 7);
          final b = generateProblems(spec: spec, level: level, seed: 7);
          expect(
            jsonEncode(a.map((p) => p.toJson()).toList()),
            jsonEncode(b.map((p) => p.toJson()).toList()),
            reason: '${spec.skillId} L$level',
          );
        }
      }
    });
  });

  group('real specs: word_problem / strategy_choice levels generate', () {
    final dir = Directory(_specsDir);
    if (!dir.existsSync()) {
      fail('real spec tree must exist at $_specsDir');
    }
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final specs = [
      for (final file in files)
        SkillSpec.fromJson(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        ),
    ];

    test('every word_problem and strategy_choice level yields valid problems',
        () {
      var checkedLevels = 0;
      for (final spec in specs) {
        for (var level = 1; level <= 3; level++) {
          final levelSpec = spec.levelSpec(level);
          if (levelSpec.template != 'word_problem' &&
              levelSpec.template != 'strategy_choice') {
            continue;
          }
          checkedLevels++;
          for (var seed = 0; seed < 3; seed++) {
            final problems = generateProblems(
              spec: spec,
              level: level,
              seed: seed,
            );
            expect(
              problems,
              hasLength(levelSpec.problemCount),
              reason: '${spec.skillId} L$level seed $seed',
            );
            for (var i = 0; i < problems.length; i++) {
              final p = problems[i];
              expect(p.index, i, reason: '${spec.skillId} L$level');
              expect(p.expected, isNotEmpty);
              expect(p.promptDe, isNotEmpty);
              expect(
                problemValid(p),
                isTrue,
                reason: '${spec.skillId} L$level seed $seed: '
                    '${jsonEncode(p.toJson())}',
              );
            }
          }
        }
      }
      expect(checkedLevels, greaterThan(0));
    });

    test('word_problem op "+|-" levels really mix operations', () {
      var levelsChecked = 0;
      for (final spec in specs) {
        for (var level = 1; level <= 3; level++) {
          final levelSpec = spec.levelSpec(level);
          if (levelSpec.template != 'word_problem') continue;
          if (levelSpec.stringParam('op') != '+|-') continue;
          levelsChecked++;
          for (var seed = 0; seed < 10; seed++) {
            final ops = generateProblems(spec: spec, level: level, seed: seed)
                .map((p) => p.display['op'] as String)
                .toSet();
            expect(
              ops,
              {'+', '-'},
              reason: '${spec.skillId} L$level seed $seed must mix ops',
            );
          }
        }
      }
      expect(levelsChecked, greaterThan(0),
          reason: 'D1.2 levels must be covered');
    });

    test('generation is deterministic on these real specs too', () {
      for (final spec in specs) {
        for (var level = 1; level <= 3; level++) {
          final levelSpec = spec.levelSpec(level);
          if (levelSpec.template != 'word_problem' &&
              levelSpec.template != 'strategy_choice') {
            continue;
          }
          final a = generateProblems(spec: spec, level: level, seed: 7);
          final b = generateProblems(spec: spec, level: level, seed: 7);
          expect(
            jsonEncode(a.map((p) => p.toJson()).toList()),
            jsonEncode(b.map((p) => p.toJson()).toList()),
            reason: '${spec.skillId} L$level',
          );
        }
      }
    });
  });

  group('real specs: manipulative levels generate (P2 task 5)', () {
    final dir = Directory(_specsDir);
    if (!dir.existsSync()) {
      fail('real spec tree must exist at $_specsDir');
    }
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final specs = [
      for (final file in files)
        SkillSpec.fromJson(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        ),
    ];

    test('every drag_partition/place_counters/bundle_sticks/rekenrek_set '
        'level yields valid problems', () {
      var checkedLevels = 0;
      for (final spec in specs) {
        for (var level = 1; level <= 3; level++) {
          final levelSpec = spec.levelSpec(level);
          if (!const {
                'drag_partition',
                'place_counters',
                'bundle_sticks',
                'rekenrek_set',
              }.contains(levelSpec.template)) {
            continue;
          }
          checkedLevels++;
          for (var seed = 0; seed < 3; seed++) {
            final problems = generateProblems(
              spec: spec,
              level: level,
              seed: seed,
            );
            expect(
              problems,
              hasLength(levelSpec.problemCount),
              reason: '${spec.skillId} L$level seed $seed',
            );
            for (var i = 0; i < problems.length; i++) {
              final p = problems[i];
              expect(p.index, i, reason: '${spec.skillId} L$level');
              expect(p.promptDe, isNotEmpty);
              expect(
                manipulativeValid(p),
                isTrue,
                reason: '${spec.skillId} L$level seed $seed: '
                    '${jsonEncode(p.toJson())}',
              );
            }
          }
        }
      }
      expect(checkedLevels, greaterThan(0));
    });

    test('the construct-specific constraint gates hold per skill', () {
      final gate = <String, String>{
        'A3.1': 'sum',
        'A3.3': 'equal',
        'C1.2': 'equal',
        'C1.3': 'equal',
        'C2.1': 'make_ten',
        'C3.3': 'near_double',
        'C3.4a': 'tens_ones',
        'C3.4b': 'tens_ones',
        'C4.2': 'sum',
      };
      for (final spec in specs) {
        final expected = gate[spec.skillId];
        if (expected == null) continue;
        final levelSpec = spec.levelSpec(1);
        expect(levelSpec.template, 'drag_partition',
            reason: '${spec.skillId} L1 is drag_partition');
        for (var seed = 0; seed < 20; seed++) {
          for (final p in generateProblems(spec: spec, level: 1, seed: seed)) {
            expect(p.display['split_constraint'], expected,
                reason: '${spec.skillId} L1 seed $seed');
          }
        }
      }
    });

    test('generation is deterministic on the manipulative levels', () {
      for (final spec in specs) {
        for (var level = 1; level <= 3; level++) {
          final levelSpec = spec.levelSpec(level);
          if (!const {
                'drag_partition',
                'place_counters',
                'bundle_sticks',
                'rekenrek_set',
              }.contains(levelSpec.template)) {
            continue;
          }
          final a = generateProblems(spec: spec, level: level, seed: 7);
          final b = generateProblems(spec: spec, level: level, seed: 7);
          expect(
            jsonEncode(a.map((p) => p.toJson()).toList()),
            jsonEncode(b.map((p) => p.toJson()).toList()),
            reason: '${spec.skillId} L$level',
          );
        }
      }
    });
  });

  group('real specs: visual/reading levels generate (P2 task 5)', () {
    final dir = Directory(_specsDir);
    if (!dir.existsSync()) {
      fail('real spec tree must exist at $_specsDir');
    }
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final specs = [
      for (final file in files)
        SkillSpec.fromJson(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        ),
    ];

    test('every numberline_step/zehnerfeld_read/fingerbild_read/'
        'stellenwerttafel_read/numberline_locate/picture_compare level yields '
        'valid problems', () {
      var checkedLevels = 0;
      for (final spec in specs) {
        for (var level = 1; level <= 3; level++) {
          final levelSpec = spec.levelSpec(level);
          if (!const {
                'numberline_step',
                'zehnerfeld_read',
                'fingerbild_read',
                'stellenwerttafel_read',
                'numberline_locate',
                'picture_compare',
              }.contains(levelSpec.template)) {
            continue;
          }
          checkedLevels++;
          for (var seed = 0; seed < 3; seed++) {
            final problems = generateProblems(
              spec: spec,
              level: level,
              seed: seed,
            );
            expect(
              problems,
              hasLength(levelSpec.problemCount),
              reason: '${spec.skillId} L$level seed $seed',
            );
            for (var i = 0; i < problems.length; i++) {
              final p = problems[i];
              expect(p.index, i, reason: '${spec.skillId} L$level');
              expect(p.promptDe, isNotEmpty);
              expect(p.promptDe, isNotEmpty, reason: 'German prompt');
              expect(
                visualReadingValid(p),
                isTrue,
                reason: '${spec.skillId} L$level seed $seed: '
                    '${jsonEncode(p.toJson())}',
              );
            }
          }
        }
      }
      expect(checkedLevels, greaterThan(0));
    });

    test('the template-specific gates hold per skill', () {
      final gate = <String, (String, int)>{
        'A1.3': ('numberline_step', 1),
        'A1.5': ('numberline_step', 1),
        'A2.3': ('picture_compare', 2),
        'B2.2': ('numberline_locate', 3),
      };
      for (final spec in specs) {
        final (template, level) = gate[spec.skillId] ?? ('', 0);
        if (template.isEmpty) continue;
        final levelSpec = spec.levelSpec(level);
        expect(levelSpec.template, template,
            reason: '${spec.skillId} L$level template');
        for (var seed = 0; seed < 20; seed++) {
          for (final p in generateProblems(
            spec: spec,
            level: level,
            seed: seed,
          )) {
            expect(
              visualReadingValid(p),
              isTrue,
              reason: '${spec.skillId} L$level seed $seed',
            );
            if (template == 'numberline_step') {
              expect((p.display['direction'] as String), isNotEmpty);
              expect(p.expected.last, '${p.display['target']}',
                  reason: 'the run ends on the target');
            }
          }
        }
      }
    });

    test('generation is deterministic on the visual/reading levels', () {
      for (final spec in specs) {
        for (var level = 1; level <= 3; level++) {
          final levelSpec = spec.levelSpec(level);
          if (!const {
                'numberline_step',
                'zehnerfeld_read',
                'fingerbild_read',
                'stellenwerttafel_read',
                'numberline_locate',
                'picture_compare',
              }.contains(levelSpec.template)) {
            continue;
          }
          final a = generateProblems(spec: spec, level: level, seed: 7);
          final b = generateProblems(spec: spec, level: level, seed: 7);
          expect(
            jsonEncode(a.map((p) => p.toJson()).toList()),
            jsonEncode(b.map((p) => p.toJson()).toList()),
            reason: '${spec.skillId} L$level',
          );
        }
      }
    });
  });

  group('full-bank smoke test: every spec x level across 5 seeds', () {
    final dir = Directory(_specsDir);
    if (!dir.existsSync()) {
      fail('real spec tree must exist at $_specsDir');
    }
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final specs = [
      for (final file in files)
        SkillSpec.fromJson(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        ),
    ];
    const seeds = [1, 7, 42, 123, 987];

    test('all 36 specs: exact problem_count, no exceptions, non-empty '
        'expected/prompt, deterministic per seed', () {
      expect(specs, hasLength(36));
      var generated = 0;
      for (final spec in specs) {
        for (var level = 1; level <= 3; level++) {
          final levelSpec = spec.levelSpec(level);
          for (final seed in seeds) {
            final problems = generateProblems(
              spec: spec,
              level: level,
              seed: seed,
            );
            expect(
              problems,
              hasLength(levelSpec.problemCount),
              reason: '${spec.skillId} L$level seed $seed',
            );
            final regenerated = generateProblems(
              spec: spec,
              level: level,
              seed: seed,
            );
            expect(
              jsonEncode(problems.map((p) => p.toJson()).toList()),
              jsonEncode(regenerated.map((p) => p.toJson()).toList()),
              reason: '${spec.skillId} L$level seed $seed is deterministic',
            );
            for (var i = 0; i < problems.length; i++) {
              final p = problems[i];
              generated++;
              expect(p.index, i,
                  reason: '${spec.skillId} L$level seed $seed');
              expect(p.skillId, spec.skillId);
              expect(p.level, level);
              expect(p.seed, seed);
              expect(p.template, levelSpec.template,
                  reason: '${spec.skillId} L$level seed $seed');
              expect(
                p.promptDe,
                isNotEmpty,
                reason: '${spec.skillId} L$level seed $seed German prompt',
              );
              final allowedEmpty =
                  p.template == 'drag_partition' ||
                  (p.template == 'custom_widget' &&
                      p.display['custom_widget'] == 'bundling');
              if (!allowedEmpty) {
                expect(
                  p.expected,
                  isNotEmpty,
                  reason: '${spec.skillId} L$level seed $seed: '
                      '${jsonEncode(p.toJson())}',
                );
              }
            }
          }
        }
      }
      // 36 specs x 3 levels x problem_count (8) x 5 seeds = 864 x 5.
      expect(generated, 36 * 3 * 8 * 5);
    });

    test('every one of the 4320 problems passes its template validity check',
        () {
      var checked = 0;
      for (final spec in specs) {
        for (var level = 1; level <= 3; level++) {
          for (final seed in seeds) {
            for (final p in generateProblems(
              spec: spec,
              level: level,
              seed: seed,
            )) {
              expect(
                problemSemanticallyValid(p),
                isTrue,
                reason: '${spec.skillId} L$level seed $seed: '
                    '${jsonEncode(p.toJson())}',
              );
              checked++;
            }
          }
        }
      }
      expect(checked, 4320);
    });

    test('no degenerate levels: >= 4 distinct problem signatures per level',
        () {
      // A problem "signature" is the full display payload — exactly the key
      // generateProblems deduplicates on. A level whose parameter ranges can
      // only produce a handful of distinct problems fills the rest of the
      // session with repeats (integration-critic F4: A1.2a L2 served the same
      // sequence 3x in one session). Every level must be able to produce at
      // least 4 distinct signatures across the smoke-test seeds.
      //
      // Legitimately-capped templates: flash_subitize / the subitizable
      // zehnerfeld_read levels (A2.1) draw counts from [1, 5] — subitizing is
      // capped at 5, so these levels support exactly 5 distinct signatures,
      // still >= 4. No template supports fewer than 4 in the current specs.
      for (final spec in specs) {
        for (var level = 1; level <= 3; level++) {
          final levelSpec = spec.levelSpec(level);
          final signatures = <String>{};
          for (final seed in seeds) {
            for (final p in generateProblems(
              spec: spec,
              level: level,
              seed: seed,
            )) {
              signatures.add(jsonEncode(p.display));
            }
          }
          expect(
            signatures.length,
            greaterThanOrEqualTo(4),
            reason: '${spec.skillId} L$level must not be degenerate '
                '(template ${levelSpec.template}): only '
                '${signatures.length} distinct problem signatures in a '
                '${levelSpec.problemCount}-problem session',
          );
        }
      }
    });

    test('construct-specific gates: nonstandard place_counters, "viele Einer" '
        'sum_rows and flash_subitize params', () {
      for (final spec in specs) {
        for (var level = 1; level <= 3; level++) {
          final levelSpec = spec.levelSpec(level);
          for (final seed in seeds) {
            final problems = generateProblems(
              spec: spec,
              level: level,
              seed: seed,
            );
            for (final p in problems) {
              if (p.template == 'place_counters' &&
                  p.display['mode'] == 'nonstandard') {
                final count = p.display['count'] as int;
                final tens = p.display['tens'] as int;
                final ones = p.display['ones'] as int;
                expect(tens, count ~/ 10 - 1,
                    reason: '${spec.skillId} L$level: tens = n div 10 - 1');
                expect(ones, 10 + count % 10,
                    reason: '${spec.skillId} L$level: ones = 10 + n mod 10');
                expect(10 * tens + ones, count,
                    reason: '${spec.skillId} L$level nonstandard re-composes');
                expect(ones, inInclusiveRange(10, 19));
              }
              if (p.template == 'stellenwerttafel_read' &&
                  p.display['mode'] == 'sum_rows' &&
                  levelSpec.intListParam('ones_range').isNotEmpty) {
                final row1 = (p.display['row1'] as List).cast<int>();
                final row2 = (p.display['row2'] as List).cast<int>();
                final onesSum = row1[1] + row2[1];
                expect(onesSum, inInclusiveRange(10, 18),
                    reason: '${spec.skillId} L$level "viele Einer"');
                final value = p.display['value'] as int;
                expect(
                  (row1[0] + row2[0]) * 10 + onesSum,
                  value,
                  reason: '${spec.skillId} L$level composed value',
                );
              }
              if (p.template == 'custom_widget' &&
                  p.display['custom_widget'] == 'flash_subitize') {
                expect(p.display['count'] as int, inInclusiveRange(1, 5),
                    reason: '${spec.skillId} L$level subitizable range');
                expect(p.display['flash_ms'], 800);
                expect(
                  p.display['display'],
                  anyOf('dots', 'rekenrek'),
                  reason: '${spec.skillId} L$level flash pattern',
                );
              }
            }
          }
        }
      }
    });
  });
}
