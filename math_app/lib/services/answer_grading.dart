import '../models/diagnostic_question.dart';

/// Answer-entry/‑grading modes for diagnostic items.
///
/// The CSV's `AnswerFormat`/`CorrectAnswer` pair predates the clean-room bank:
/// many `Single` items actually expect a counting sequence, a multi-part place
/// value answer or a transcript, and several `CorrectAnswer` strings are
/// assessor transcripts ("Finale Antwort: 95."). Grading therefore decides the
/// intended signal from a curated per-item table plus generic shape rules, so
/// a child's typed answer is compared against what the item actually asks.
enum DiagnosticAnswerMode {
  /// One number (typed on a numeric field).
  number,

  /// Several numbers in order, one field per number (counting, Z/E answers).
  sequence,

  /// Decomposition items "8 = a + b" — rows of two numeric fields.
  pairRows,

  /// One of a small set of words (e.g. "rechts"/"links").
  choice,

  /// Free text (equations, sentences) with tolerant normalization.
  freeText,
}

/// Curated answer expectations for items whose `CorrectAnswer` transcript is
/// not machine-parseable by shape alone. Derived from the item files
/// (docs/clean-room/items/*.md) — the final result is the graded signal;
/// intermediate steps shown in the prompt stay visible but are not captured
/// (pilot scope, documented).
class AnswerSpec {
  final DiagnosticAnswerMode mode;
  final List<int> expectedNumbers;
  final int? target;
  final int? rows;
  final List<String>? choiceOptions;
  final String? choiceAnswer;
  final String? anchor;

  const AnswerSpec.number(this.expectedNumbers)
      : mode = DiagnosticAnswerMode.number,
        target = null,
        rows = null,
        choiceOptions = null,
        choiceAnswer = null,
        anchor = null;

  const AnswerSpec.sequence(this.expectedNumbers, {this.anchor})
      : mode = DiagnosticAnswerMode.sequence,
        target = null,
        rows = null,
        choiceOptions = null,
        choiceAnswer = null;

  const AnswerSpec.pairs(int this.target, int this.rows)
      : mode = DiagnosticAnswerMode.pairRows,
        expectedNumbers = const [],
        choiceOptions = null,
        choiceAnswer = null,
        anchor = null;

  const AnswerSpec.choice(this.choiceOptions, this.choiceAnswer)
      : mode = DiagnosticAnswerMode.choice,
        expectedNumbers = const [],
        target = null,
        rows = null,
        anchor = null;

  const AnswerSpec.freeText(this.expectedNumbers)
      : mode = DiagnosticAnswerMode.freeText,
        target = null,
        rows = null,
        choiceOptions = null,
        choiceAnswer = null,
        anchor = null;
}

/// Per-item expectations (keyed by CSV ListNumber). Every entry here is a
/// deliberate reduction of the item file's expected-answer prose to the
/// numeric result(s) the app can grade. Items NOT listed fall back to the
/// generic shape rules in [AnswerGrading.specFor].
const Map<int, AnswerSpec> kAnswerSpecs = {
  // A1.x counting sequences: the given start is shown as static text ahead
  // of the boxes (§4.3) so the child can't try to re-type it and run out of
  // boxes before the target (the A1.2-01 bug the usability rework fixes).
  1: AnswerSpec.sequence([13, 14, 15, 16, 17, 18, 19, 20], anchor: '12'),
  2: AnswerSpec.sequence(
      [49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63],
      anchor: '48'),
  3: AnswerSpec.sequence([20, 19, 18, 17, 16], anchor: '21'),
  4: AnswerSpec.sequence([58, 57, 56, 55, 54, 53, 52, 51], anchor: '59'),
  5: AnswerSpec.sequence([28, 30, 32, 34], anchor: '26'),
  6: AnswerSpec.sequence([40, 35, 30, 25, 20], anchor: '45'),
  // Place-value reads the child states in order: "5 Zehner, 8 Einer.",
  // "41 Stäbchen; 4 Zehner und 1 Einer", "Z-Spalte 4, E-Spalte 7".
  20: AnswerSpec.sequence([5, 8]),
  22: AnswerSpec.sequence([41, 4, 1]),
  24: AnswerSpec.sequence([4, 7]),
  // C3/C4 strategy items — the final result is the graded signal.
  44: AnswerSpec.sequence([5, 12, 62]),
  45: AnswerSpec.number([38]),
  46: AnswerSpec.number([58]),
  47: AnswerSpec.number([61]),
  48: AnswerSpec.sequence([43, 35]),
  49: AnswerSpec.number([95]),
  50: AnswerSpec.number([71]),
  51: AnswerSpec.number([83]),
  52: AnswerSpec.number([75]),
  53: AnswerSpec.number([35]),
  54: AnswerSpec.number([63]),
  55: AnswerSpec.number([33]),
  56: AnswerSpec.sequence([43, 29]),
  57: AnswerSpec.sequence([36, 36]),
  // Decompositions: "Finde drei verschiedene Wege 8 zu rechnen" /
  // "Finde alle Zerlegungen von 10".
  15: AnswerSpec.pairs(8, 3),
  17: AnswerSpec.pairs(10, 5),
  // Word problems: "Schreibe die passende Rechnung auf und rechne sie aus."
  58: AnswerSpec.freeText([13]),
  59: AnswerSpec.freeText([13]),
};

class AnswerGrading {
  AnswerGrading._();

  /// Extracts the meaningful whole numbers in [s]. Assessor transcripts store
  /// whole results in decimal form ("34.0", "24.0"), which parse as 34 / 24.
  static List<int> intsIn(String s) {
    final result = <int>[];
    for (final m in RegExp(r'-?\d+(?:\.\d+)?').allMatches(s)) {
      final token = m.group(0)!;
      if (token.contains('.')) {
        final parts = token.split('.');
        if (parts.length == 2 &&
            int.tryParse(parts[1]) == 0) {
          result.add(int.parse(parts[0]));
        }
      } else {
        result.add(int.parse(token));
      }
    }
    return result;
  }

  /// Result number an item expects, when it asks for exactly one number.
  static int? singleResultNumber(DiagnosticQuestion q) {
    final spec = kAnswerSpecs[q.listNumber];
    if (spec != null && spec.mode == DiagnosticAnswerMode.number) {
      return spec.expectedNumbers.isEmpty ? null : spec.expectedNumbers.first;
    }
    final correct = q.correctAnswer;
    final finale = RegExp(r'Finale Antwort:\s*(-?\d+)').firstMatch(correct);
    if (finale != null) return int.parse(finale.group(1)!);
    final ints = intsIn(correct);
    if (ints.isEmpty) return null;
    if (ints.length == 1) return ints.first;
    return null;
  }

  /// Input mode for [q]. Must stay in lockstep with [grade].
  static DiagnosticAnswerMode modeFor(DiagnosticQuestion q) {
    final spec = kAnswerSpecs[q.listNumber];
    if (spec != null) return spec.mode;
    return _modeByShape(q);
  }

  static DiagnosticAnswerMode _modeByShape(DiagnosticQuestion q) {
    final correct = q.correctAnswer.trim();
    final ints = intsIn(correct);
    // Sequence of several pure numbers, e.g. "13, 14, 15, …, 20".
    if (ints.length >= 2) {
      final allPureNumbers = correct.split(RegExp(r'[,;]\s*')).every(
          (part) => part.isNotEmpty && int.tryParse(part) != null);
      if (allPureNumbers) return DiagnosticAnswerMode.sequence;
    }
    // Exactly one meaningful number → a single numeric answer ("34.0",
    // "13 einzelne Stäbchen.", "71.").
    if (ints.length == 1) return DiagnosticAnswerMode.number;
    // Word answer ("rechts") vs. phrase/equation answer ("5 Zehner, 8 Einer.",
    // "8 + 5 = 13").
    if (ints.isEmpty) return DiagnosticAnswerMode.choice;
    return DiagnosticAnswerMode.freeText;
  }

  static bool grade({
    required String userAnswer,
    required DiagnosticQuestion question,
  }) {
    final input = userAnswer.trim();
    if (input.isEmpty) return false;
    final spec = kAnswerSpecs[question.listNumber];
    final mode = spec?.mode ?? _modeByShape(question);
    return switch (mode) {
      DiagnosticAnswerMode.number => _gradeNumber(input, spec, question),
      DiagnosticAnswerMode.sequence => _gradeSequence(input, spec, question),
      DiagnosticAnswerMode.pairRows =>
        _gradePairs(input, spec!.target!, spec.rows!),
      DiagnosticAnswerMode.choice => _gradeChoice(input, spec, question),
      DiagnosticAnswerMode.freeText =>
        spec != null ? _gradeFreeText(input, spec) : gradePhrase(input, question.correctAnswer),
    };
  }

  static bool _gradeNumber(
      String input, AnswerSpec? spec, DiagnosticQuestion question) {
    final userInts = intsIn(input);
    if (userInts.isEmpty) return false;
    int? expected = singleResultNumber(question);
    if (spec != null && spec.expectedNumbers.isNotEmpty) {
      expected = spec.expectedNumbers.first;
    }
    if (expected == null) return false;
    return userInts.first == expected;
  }

  static bool _gradeSequence(
      String input, AnswerSpec? spec, DiagnosticQuestion question) {
    final expected = spec != null
        ? spec.expectedNumbers
        : intsIn(question.correctAnswer);
    final user = intsIn(input);
    if (expected.isEmpty || user.length != expected.length) return false;
    for (var i = 0; i < expected.length; i++) {
      if (user[i] != expected[i]) return false;
    }
    return true;
  }

  static bool _gradePairs(String input, int target, int rows) {
    final values = intsIn(input);
    final used = <String>{};
    for (var i = 0; i + 1 < values.length; i += 2) {
      final a = values[i];
      final b = values[i + 1];
      if (a < 0 || b < 0 || a + b != target) return false;
      final lo = a <= b ? a : b;
      final hi = a <= b ? b : a;
      used.add('$lo+$hi');
    }
    return used.length >= rows;
  }

  static bool _gradeChoice(
      String input, AnswerSpec? spec, DiagnosticQuestion question) {
    final expected = spec?.choiceAnswer ?? question.correctAnswer.trim();
    return normalize(input) == normalize(expected);
  }

  static bool _gradeFreeText(String input, AnswerSpec? spec) {
    final userInts = intsIn(input);
    if (spec != null && spec.expectedNumbers.isNotEmpty) {
      final expected = spec.expectedNumbers;
      // Accept the full equation or just its result.
      if (_sameList(userInts, expected)) return true;
      if (userInts.isNotEmpty && userInts.last == expected.last) return true;
      return false;
    }
    return false;
  }

  /// Generic phrase/equation fallback used by callers that hold no spec:
  /// the typed numbers must equal the correct answer's numbers in order, or
  /// the loosened text must match.
  static bool gradePhrase(String userAnswer, String correctAnswer) {
    if (userAnswer.trim().isEmpty) return false;
    if (normalize(userAnswer) == normalize(correctAnswer)) return true;
    final userInts = intsIn(userAnswer);
    final correctInts = intsIn(correctAnswer);
    if (userInts.isEmpty || correctInts.isEmpty) return false;
    if (userInts.length != correctInts.length) return false;
    for (var i = 0; i < userInts.length; i++) {
      if (userInts[i] != correctInts[i]) return false;
    }
    return true;
  }

  static bool _sameList(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Lowercase, whitespace-collapsed, punctuation-free normalization.
  static String normalize(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s,;.:!?„“"»«()\-−–—]+'), '');

  /// Number of numeric fields for sequence-mode items.
  static int sequenceLength(DiagnosticQuestion q) {
    final spec = kAnswerSpecs[q.listNumber];
    if (spec != null && spec.expectedNumbers.isNotEmpty) {
      return spec.expectedNumbers.length;
    }
    final n = intsIn(q.correctAnswer).length;
    return n < 1 ? 1 : n;
  }

  /// Given start shown as static text ahead of the boxes, when the item
  /// carries one (diagnostic usability rework §4.3).
  static String? sequenceAnchor(DiagnosticQuestion q) =>
      kAnswerSpecs[q.listNumber]?.anchor;

  /// Sum target + row count for decomposition items.
  static int pairTarget(DiagnosticQuestion q) {
    final spec = kAnswerSpecs[q.listNumber];
    return spec?.target ?? 0;
  }

  static int pairRows(DiagnosticQuestion q) {
    final spec = kAnswerSpecs[q.listNumber];
    return spec?.rows ?? 0;
  }

  /// Tap options for choice-mode items. Options are not stored in the CSV; they
  /// are derived from the German prompt (e.g. "… links oder rechts?") or, when
  /// nothing can be derived, left empty (the caller then falls back to a text
  /// field so the item stays answerable).
  static List<String> choiceOptionsOf(DiagnosticQuestion q) {
    final spec = kAnswerSpecs[q.listNumber];
    if (spec?.choiceOptions != null) return spec!.choiceOptions!;
    final german = (q.german.isEmpty ? q.questionText : q.german).toLowerCase();
    final linksRechts =
        RegExp(r'links\s+oder\s+rechts|links/rechts').hasMatch(german);
    if (linksRechts) return const ['links', 'rechts'];
    return const [];
  }
}

/// Renders a label for [mode] shown above the input (German child-facing).
String answerFieldLabel(DiagnosticAnswerMode mode) => switch (mode) {
      DiagnosticAnswerMode.number => 'Deine Antwort',
      DiagnosticAnswerMode.sequence => 'Trage die Zahlen in der richtigen Reihenfolge ein.',
      DiagnosticAnswerMode.pairRows => 'Schreibe jede Zerlegung in eine eigene Zeile.',
      DiagnosticAnswerMode.choice => 'Tippe deine Antwort an.',
      DiagnosticAnswerMode.freeText => 'Schreibe deine Antwort auf.',
    };
