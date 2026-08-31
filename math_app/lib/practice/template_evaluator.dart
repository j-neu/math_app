/// Evaluates one submitted answer against a generated [Problem] under the
/// P2 plan §5 template semantics.
///
/// `evaluate` is the single decision point for "was this answer correct?",
/// used by [PracticeController] to build the attempt record. It is pure and
/// deterministic: the same (problem, submitted, spec) always yields the same
/// verdict, so a child's answer is graded identically on every device.
library;

import '../models/problem.dart';
import '../models/skill_spec.dart';
import '../services/answer_normalization.dart';

/// The verdict for one submitted answer: whether it is correct, the
/// error-taxonomy code when wrong (a code the spec actually carries, or
/// `"other"`), and the canonical DB answer string to store in the attempt
/// record (`practice_attempts.answer`).
class AnswerEvaluation {
  final bool isCorrect;
  final String? errorCode;
  final String canonicalAnswer;

  const AnswerEvaluation({
    required this.isCorrect,
    required this.canonicalAnswer,
    this.errorCode,
  });
}

/// Applies the P2 §5 correctness rules per template.
class TemplateEvaluator {
  /// Fallback taxonomy code every spec carries (P2 §4: every spec ships an
  /// "other" rule).
  static const String otherCode = 'other';

  AnswerEvaluation evaluate(
    Problem problem,
    String submitted, {
    required SkillSpec spec,
  }) {
    switch (problem.template) {
      case 'drag_partition':
        return _evaluateDragPartition(problem, submitted, spec);
      case 'place_counters':
        return _evaluatePlaceCounters(problem, submitted, spec);
      case 'bundle_sticks':
        return _evaluateBundles(problem, submitted, spec);
      case 'rekenrek_set':
        return _evaluateCountMatch(problem, submitted, spec);
      case 'numberline_step':
        return _evaluateJoined(problem, submitted, spec);
      case 'sequence_gap':
        return _evaluateJoined(problem, submitted, spec);
      case 'strategy_choice':
        return _evaluateStrategyChoice(problem, submitted, spec);
      case 'custom_widget':
        return _evaluateCustomWidget(problem, submitted, spec);
      case 'equation_gap':
        // `neighbor` shows TWO gaps ("_, n, _") whose expected values are
        // [n-1, n+1]; both must be filled, so it cannot use the plain
        // single-candidate string match below.
        if (problem.display['form'] == 'neighbor') {
          return _evaluateNeighbor(problem, submitted, spec);
        }
        return _evaluateStringMatch(problem, submitted, spec);
      default:
        // Every other template (equation_solve, sequence_gap,
        // compare_symbols, zehnerfeld_read, fingerbild_read,
        // stellenwerttafel_read, numberline_locate, picture_compare,
        // word_problem, flash_subitize, numberline_mark) is a plain string
        // match: correct iff the normalised submission equals one of the
        // expected answers.
        return _evaluateStringMatch(problem, submitted, spec);
    }
  }

  /// `equation_gap` form `neighbor`: correct iff BOTH expected neighbours
  /// ([n-1, n+1]) are present in the submission. The widget reports them as
  /// `"n-1,n+1"`; the check is set-based so the order does not matter, but a
  /// single filled gap (or a wrong second value) is rejected.
  AnswerEvaluation _evaluateNeighbor(
    Problem problem,
    String submitted,
    SkillSpec spec,
  ) {
    final normalized = normalizeAnswer(submitted);
    final parts = normalized.split(',').map((s) => s.trim()).toList();
    final expected = problem.expected.map(normalizeAnswer).toList();
    final isCorrect = expected.length == 2 &&
        parts.length == 2 &&
        parts.toSet().length == 2 &&
        expected.toSet().containsAll(parts.toSet());
    return AnswerEvaluation(
      isCorrect: isCorrect,
      errorCode: isCorrect ? null : _errorCodeFor(problem, submitted, spec),
      canonicalAnswer: isCorrect ? parts.join(',') : normalized,
    );
  }

  /// Correct iff the normalised submission equals one of `expected`.
  AnswerEvaluation _evaluateStringMatch(
    Problem problem,
    String submitted,
    SkillSpec spec,
  ) {
    final normalized = normalizeAnswer(submitted);
    for (final candidate in problem.expected) {
      if (normalized == normalizeAnswer(candidate)) {
        return AnswerEvaluation(
          isCorrect: true,
          canonicalAnswer: normalizeAnswer(candidate),
        );
      }
    }
    return AnswerEvaluation(
      isCorrect: false,
      errorCode: _errorCodeFor(problem, submitted, spec),
      canonicalAnswer: normalized,
    );
  }

  /// `drag_partition`: the submission is `"b1+b2+…"`. Correct iff the boxes
  /// sum to `display.total`, use exactly `display.parts` boxes, and honour
  /// `display.split_constraint`. The canonical DB answer is the joined
  /// `"b1+b2"` string.
  AnswerEvaluation _evaluateDragPartition(
    Problem problem,
    String submitted,
    SkillSpec spec,
  ) {
    final normalized = normalizeAnswer(submitted);
    final parts = _parseIntList(submitted.split('+'));
    final total = problem.display['total'];
    final expectedParts = problem.display['parts'];
    final constraint = problem.display['split_constraint'] as String? ?? 'sum';

    final isCorrect = parts != null &&
        total is int &&
        expectedParts is int &&
        parts.length == expectedParts &&
        parts.every((p) => p >= 1) &&
        parts.reduce((a, b) => a + b) == total &&
        _splitConstraintHolds(constraint, parts, total, problem.display);

    return AnswerEvaluation(
      isCorrect: isCorrect,
      errorCode: isCorrect ? null : _errorCodeFor(problem, submitted, spec),
      canonicalAnswer: isCorrect ? parts.join('+') : normalized,
    );
  }

  bool _splitConstraintHolds(
    String constraint,
    List<int> parts,
    int total,
    Map<String, dynamic> display,
  ) {
    switch (constraint) {
      case 'sum':
        return true;
      case 'equal':
        return parts.every((p) => p == parts.first);
      case 'make_ten':
        // One box is exactly 10 (the other then holds total - 10, since the
        // sum is already checked).
        return parts.contains(10);
      case 'near_double':
        // 7 + 7 + 1: two equal boxes, the third box is exactly 1.
        return parts.length == 3 && parts[0] == parts[1] && parts[2] == 1;
      case 'tens_ones':
        // 35 + 27 -> [35, 20, 7]: box1 == a, box2 == 10*floor(b/10),
        // box3 == b % 10.
        final a = display['a'];
        final b = display['b'];
        if (a is! int || b is! int || parts.length != 3) return false;
        return parts[0] == a && parts[1] == 10 * (b ~/ 10) && parts[2] == b % 10;
      default:
        return false;
    }
  }

  /// `place_counters`: the submission is the filled count. Correct iff it
  /// equals `display.count` (action `fill`), the remaining
  /// `display.total - display.count` (action `take_away`), or — for mode
  /// `nonstandard` (B2.3) — the count typed directly or as a `"Z E"` pair
  /// with `10*Z + E == count`.
  AnswerEvaluation _evaluatePlaceCounters(
    Problem problem,
    String submitted,
    SkillSpec spec,
  ) {
    final normalized = normalizeAnswer(submitted);
    final count = problem.display['count'];
    final action = problem.display['action'] as String? ?? 'fill';
    final mode = problem.display['mode'] as String? ?? 'standard';

    final int? target;
    if (mode == 'nonstandard') {
      target = count is int ? count : null;
    } else if (action == 'take_away') {
      final remaining = problem.display['remaining'];
      target = remaining is int
          ? remaining
          : (count is int && problem.display['total'] is int
              ? (problem.display['total'] as int) - count
              : null);
    } else {
      target = count is int ? count : null;
    }

    var correct = false;
    final submittedInt = int.tryParse(normalized);
    if (target != null && submittedInt != null) {
      correct = submittedInt == target;
    }
    if (mode == 'nonstandard' && !correct) {
      // Accept the Stellenwerttafel form "Z E" (e.g. "2 14"), not just the
      // composed number.
      final pair = _extractInts(normalized);
      if (pair != null && pair.length == 2 && count is int) {
        correct = 10 * pair[0] + pair[1] == count;
      }
    }

    return AnswerEvaluation(
      isCorrect: correct,
      errorCode: correct ? null : _errorCodeFor(problem, submitted, spec),
      canonicalAnswer: correct
          ? (mode == 'nonstandard' && submittedInt == null
              ? _extractInts(normalized)!.join(' ')
              : '$target')
          : normalized,
    );
  }

  /// `bundle_sticks` (and the `bundling` custom widget): the submission is
  /// `"Z Zehner, E Einer"` (or a bare `"Z E"` pair). Correct iff
  /// `10*Z + E == display.count` and, for counts >= 10, `Z >= 1`.
  AnswerEvaluation _evaluateBundles(
    Problem problem,
    String submitted,
    SkillSpec spec,
  ) {
    final normalized = normalizeAnswer(submitted);
    final count = problem.display['count'];
    final pair = _extractInts(normalized);
    var correct = false;
    if (count is int && pair != null && pair.length >= 2) {
      final zehner = pair[0];
      final einer = pair[1];
      correct = 10 * zehner + einer == count && (count >= 10 ? zehner >= 1 : true);
    }

    final String canonical;
    if (correct) {
      final zehner = pair![0];
      final einer = pair[1];
      canonical = '$zehner Zehner, $einer Einer';
    } else {
      canonical = normalized;
    }

    return AnswerEvaluation(
      isCorrect: correct,
      errorCode: correct ? null : _errorCodeFor(problem, submitted, spec),
      canonicalAnswer: canonical,
    );
  }

  /// `rekenrek_set`: the submission is the visible bead count.
  AnswerEvaluation _evaluateCountMatch(
    Problem problem,
    String submitted,
    SkillSpec spec,
  ) {
    final normalized = normalizeAnswer(submitted);
    final count = problem.display['count'];
    final target = count is int ? count : null;
    final submittedInt = int.tryParse(normalized);
    final correct = target != null && submittedInt != null && submittedInt == target;

    return AnswerEvaluation(
      isCorrect: correct,
      errorCode: correct ? null : _errorCodeFor(problem, submitted, spec),
      canonicalAnswer: correct ? '$target' : normalized,
    );
  }

  /// `numberline_step` / `sequence_gap`: the submission is the tapped/typed
  /// values joined `","`. Correct iff the collapsed submission equals
  /// `expected` joined `","` exactly (spaces around the commas tolerated).
  AnswerEvaluation _evaluateJoined(
    Problem problem,
    String submitted,
    SkillSpec spec,
  ) {
    final normalized = normalizeAnswer(submitted);
    final collapsed = normalized.replaceAll(' ', '');
    final joined = problem.expected.join(',');
    final correct = collapsed == joined;

    return AnswerEvaluation(
      isCorrect: correct,
      errorCode: correct ? null : _errorCodeFor(problem, submitted, spec),
      canonicalAnswer: correct ? joined : normalized,
    );
  }

  /// `strategy_choice`: the submission is `"value|strategyId"`. Correct iff
  /// the value is the arithmetic result AND the strategy is the displayed
  /// correct one.
  AnswerEvaluation _evaluateStrategyChoice(
    Problem problem,
    String submitted,
    SkillSpec spec,
  ) {
    final normalized = normalizeAnswer(submitted);
    final separator = normalized.indexOf('|');
    final value = separator < 0 ? null : normalized.substring(0, separator).trim();
    final strategy = separator < 0 ? null : normalized.substring(separator + 1).trim();
    final expectedValue = problem.expected.isEmpty ? null : problem.expected.first;
    final correctStrategy = problem.display['correct_strategy'] as String?;

    final valueCorrect = expectedValue != null &&
        value != null &&
        normalizeAnswer(value) == normalizeAnswer(expectedValue);
    final strategyCorrect = strategy != null && strategy == correctStrategy;
    final correct = valueCorrect && strategyCorrect;

    return AnswerEvaluation(
      isCorrect: correct,
      errorCode: correct ? null : _errorCodeFor(problem, submitted, spec),
      canonicalAnswer: correct ? '$expectedValue|$correctStrategy' : normalized,
    );
  }

  AnswerEvaluation _evaluateCustomWidget(
    Problem problem,
    String submitted,
    SkillSpec spec,
  ) {
    switch (problem.display['custom_widget']) {
      case 'bundling':
        // Semantic, like bundle_sticks: the child bundles sticks into tens.
        return _evaluateBundles(problem, submitted, spec);
      default:
        // unbundling, numberline_mark, flash_subitize all carry a concrete
        // expected value.
        return _evaluateStringMatch(problem, submitted, spec);
    }
  }

  /// Maps a wrong answer to a taxonomy code. Defaults to `"other"` with a
  /// small set of deterministic, explicit checks (sign flipped, count off by
  /// one, sequence reversed); the candidate code is used only when the
  /// spec's own error taxonomy actually carries it.
  String _errorCodeFor(Problem problem, String submitted, SkillSpec spec) {
    final candidate = _candidateErrorCode(problem, submitted);
    for (final rule in spec.errorTaxonomy) {
      if (rule.code == candidate) return candidate;
    }
    return otherCode;
  }

  String _candidateErrorCode(Problem problem, String submitted) {
    final normalized = normalizeAnswer(submitted);

    // Sign flipped: with a displayed operation, the child answered the
    // opposite operation (e.g. 10 - 4 answered as 14).
    final op = problem.display['op'];
    final a = problem.display['a'];
    final b = problem.display['b'];
    if (op is String && a is int && b is int) {
      final v = int.tryParse(normalized);
      if (v != null) {
        if (op == '-' && v == a + b) return 'sign_error';
        if (op == '+' && v == a - b && a - b >= 0) return 'sign_error';
      }
    }

    // Count off by one: numeric answers adjacent to the expected value.
    if (problem.expected.length == 1) {
      final expected = int.tryParse(problem.expected.single);
      final v = int.tryParse(normalized);
      if (expected != null && v != null && (v - expected).abs() == 1) {
        return 'miscount';
      }
    }

    // Sequence reversed: the number-line run tapped in the wrong direction.
    if (problem.template == 'numberline_step') {
      final collapsed = normalized.replaceAll(' ', '');
      final reversed = problem.expected.reversed.join(',');
      if (collapsed == reversed) return 'wrong_direction';
    }

    return otherCode;
  }

  /// Parses every token as an integer; null when any token is not a plain
  /// integer.
  List<int>? _parseIntList(List<String> tokens) {
    if (tokens.isEmpty) return null;
    final out = <int>[];
    for (final token in tokens) {
      final value = int.tryParse(token.trim());
      if (value == null) return null;
      out.add(value);
    }
    return out;
  }

  /// Extracts every integer that appears in the string, in order (used for
  /// the "Z Zehner, E Einer" / "Z E" forms).
  List<int>? _extractInts(String value) {
    final matches = RegExp(r'-?\d+').allMatches(value);
    if (matches.isEmpty) return null;
    return matches.map((m) => int.parse(m.group(0)!)).toList();
  }
}
