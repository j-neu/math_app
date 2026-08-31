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
}
