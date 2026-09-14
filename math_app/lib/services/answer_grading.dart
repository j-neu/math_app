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

  /// Numbers dragged into order (e.g. "Zahlen der Größe nach ordnen").
  sort,

  /// Free text (equations, sentences) with tolerant normalization.
  freeText,

  /// Several numbers, each with its own full-sentence or short label (e.g.
  /// "Zahl davor" / "Zahl danach"), one field per label, stacked as rows.
  labeledFields,
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
  final List<String>? fieldLabels;
  final int? rangeMin;
  final int? rangeMax;

  const AnswerSpec.number(this.expectedNumbers)
      : mode = DiagnosticAnswerMode.number,
        target = null,
        rows = null,
        choiceOptions = null,
        choiceAnswer = null,
        anchor = null,
        fieldLabels = null,
        rangeMin = null,
        rangeMax = null;

  /// A single-number item graded as correct anywhere inside `[min, max]`
  /// (inclusive) rather than one exact value -- for items where the picture
  /// itself can't be read more precisely than that (e.g. a mark between two
  /// number-line ticks 5 apart).
  const AnswerSpec.numberRange(int min, int max)
      : mode = DiagnosticAnswerMode.number,
        expectedNumbers = const [],
        target = null,
        rows = null,
        choiceOptions = null,
        choiceAnswer = null,
        anchor = null,
        fieldLabels = null,
        rangeMin = min,
        rangeMax = max;

  const AnswerSpec.sequence(this.expectedNumbers, {this.anchor})
      : mode = DiagnosticAnswerMode.sequence,
        target = null,
        rows = null,
        choiceOptions = null,
        choiceAnswer = null,
        fieldLabels = null,
        rangeMin = null,
        rangeMax = null;

  const AnswerSpec.pairs(int this.target, int this.rows)
      : mode = DiagnosticAnswerMode.pairRows,
        expectedNumbers = const [],
        choiceOptions = null,
        choiceAnswer = null,
        anchor = null,
        fieldLabels = null,
        rangeMin = null,
        rangeMax = null;

  const AnswerSpec.choice(this.choiceOptions, this.choiceAnswer)
      : mode = DiagnosticAnswerMode.choice,
        expectedNumbers = const [],
        target = null,
        rows = null,
        anchor = null,
        fieldLabels = null,
        rangeMin = null,
        rangeMax = null;

  const AnswerSpec.freeText(this.expectedNumbers)
      : mode = DiagnosticAnswerMode.freeText,
        target = null,
        rows = null,
        choiceOptions = null,
        choiceAnswer = null,
        anchor = null,
        fieldLabels = null,
        rangeMin = null,
        rangeMax = null;

  const AnswerSpec.labeledFields(this.fieldLabels, this.expectedNumbers)
      : mode = DiagnosticAnswerMode.labeledFields,
        target = null,
        rows = null,
        choiceOptions = null,
        choiceAnswer = null,
        anchor = null,
        rangeMin = null,
        rangeMax = null;
}

/// Per-item expectations (keyed by CSV ListNumber). Every entry here is a
/// deliberate reduction of the item file's expected-answer prose to the
/// numeric result(s) the app can grade. Items NOT listed fall back to the
/// generic shape rules in [AnswerGrading.specFor].
///
/// Live content is `Research/diagnostic_v4_master.csv` (see
/// diagnostic_service.dart), numbered sequentially 1..N -- so every key below
/// is either a master ListNumber, or a synthetic 9000+ number used only by a
/// unit-test fixture (never loaded by the app), kept apart from the live
/// range on purpose so a test fixture can never collide with a real item.
/// The clean-room `diagnostic_core_v1.csv` curated entries that used to fill
/// keys 1-59 here were retired with that file (2026-09-13) -- reusing those
/// same integers for the master CSV's own items would have silently
/// re-applied a stale, unrelated grading rule to the new content.
const Map<int, AnswerSpec> kAnswerSpecs = {
  // place_on_numberline_zr100 (master LN20 as of the 2026-09-14 reorder,
  // was LN110): the mark sits at 68 but the 0-100 line only shows ticks
  // every 5 units, so the child can't read the position more precisely than
  // "somewhere around 68" -- accept the whole 66-69 band rather than
  // requiring the exact value (Jakob's 2026-09-14 feedback).
  20: AnswerSpec.numberRange(66, 69),
  // representation_bild_symbol_wort (PIKAS extras): "sechs" vs. the
  // sound-alike distractors "sechzehn"/"sechzig" -- choiceOptionsOf can't
  // derive an arbitrary three-word list from prose, so it's curated here.
  // Master ListNumber 30 (was 100 before the 2026-09-14 reorder); also kept
  // at the original per-file number 703 since answer_grading_test.dart
  // still exercises the standalone diagnostic_v3_pikas_extras.csv fixture
  // directly.
  30: AnswerSpec.choice(['sechzehn', 'sechs', 'sechzig'], 'sechs'),
  703: AnswerSpec.choice(['sechzehn', 'sechs', 'sechzig'], 'sechs'),
  // representation_bild_symbol: "Welches Symbol passt dazu: 5, 6 oder 7?"
  // is genuinely multiple-choice -- forced into choice mode (it would
  // otherwise infer plain number-entry, since "6" alone is one integer) so
  // it renders as tap buttons instead of a field (Jakob's 2026-09-13
  // feedback: multiple-choice items should always be buttons, not fields).
  // Master ListNumber 29 (was 3 before the 2026-09-14 reorder); also kept
  // at 702 for the standalone-fixture test.
  29: AnswerSpec.choice(['5', '6', '7'], '6'),
  702: AnswerSpec.choice(['5', '6', '7'], '6'),
  // operation_sense_story: "Welche Rechnung passt...? a) 5+4 b) 5-4 c) 5x4"
  // -- same fix; grades the chosen equation, not its result. Master
  // ListNumber 68 (was 105 before the 2026-09-14 reorder); also kept at 707
  // for the standalone-fixture test.
  68: AnswerSpec.choice(['5+4', '5-4', '5x4'], '5+4'),
  707: AnswerSpec.choice(['5+4', '5-4', '5x4'], '5+4'),
  // Test-only fixtures (diagnostic_answer_widgets_test.dart): the master
  // content has no live labeledFields or pairRows item right now, so the
  // widget-mechanics tests for those two modes use synthetic questions at
  // these numbers instead of real content.
  9101: AnswerSpec.labeledFields(['Zahl davor', 'Zahl danach'], [36, 38]),
  9102: AnswerSpec.labeledFields(['Zehner', 'Einer'], [5, 8]),
  9103: AnswerSpec.pairs(8, 3),
  // The master content shows a sequence's given numbers inline as part of
  // the question prompt text itself, so none of it needs the separate
  // "anchor" convenience (a given number redrawn as static text directly
  // beside the boxes). This fixture keeps that mechanism covered.
  9104: AnswerSpec.sequence([20, 19, 18, 17, 16], anchor: '21'),
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
    if (spec != null &&
        spec.mode == DiagnosticAnswerMode.number &&
        spec.expectedNumbers.isNotEmpty) {
      return spec.expectedNumbers.first;
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
    if (q.answerFormat == AnswerFormat.sort) return DiagnosticAnswerMode.sort;
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
    final mode = modeFor(question);
    return switch (mode) {
      DiagnosticAnswerMode.number => _gradeNumber(input, spec, question),
      DiagnosticAnswerMode.sequence => _gradeSequence(input, spec, question),
      DiagnosticAnswerMode.labeledFields =>
        _gradeSequence(input, spec, question),
      DiagnosticAnswerMode.pairRows =>
        _gradePairs(input, spec!.target!, spec.rows!),
      DiagnosticAnswerMode.choice => _gradeChoice(input, spec, question),
      DiagnosticAnswerMode.sort =>
        _sameList(intsIn(input), sortItems(question)),
      DiagnosticAnswerMode.freeText =>
        spec != null ? _gradeFreeText(input, spec) : gradePhrase(input, question.correctAnswer),
    };
  }

  static bool _gradeNumber(
      String input, AnswerSpec? spec, DiagnosticQuestion question) {
    final userInts = intsIn(input);
    if (userInts.isEmpty) return false;
    if (spec?.rangeMin != null) {
      return userInts.first >= spec!.rangeMin! &&
          userInts.first <= spec.rangeMax!;
    }
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

  /// Total answer boxes [q]'s input renders — used for the response-time
  /// budget `max(15, 5 × boxCount)` (diagnostic usability rework §4.6).
  static int boxCount(DiagnosticQuestion q) {
    final spec = kAnswerSpecs[q.listNumber];
    return switch (modeFor(q)) {
      DiagnosticAnswerMode.number => 1,
      DiagnosticAnswerMode.sequence => sequenceLength(q),
      DiagnosticAnswerMode.labeledFields =>
        spec != null && spec.fieldLabels != null ? spec.fieldLabels!.length : 1,
      DiagnosticAnswerMode.pairRows => pairRows(q) * 2,
      DiagnosticAnswerMode.choice => 1,
      DiagnosticAnswerMode.sort => sortItems(q).length,
      DiagnosticAnswerMode.freeText => 1,
    };
  }

  /// Given start shown as static text ahead of the boxes, when the item
  /// carries one (diagnostic usability rework §4.3).
  static String? sequenceAnchor(DiagnosticQuestion q) =>
      kAnswerSpecs[q.listNumber]?.anchor;

  /// Field labels for a `DiagnosticAnswerMode.labeledFields` item, in the
  /// same order as its expected numbers.
  static List<String> labeledFieldsLabels(DiagnosticQuestion q) =>
      kAnswerSpecs[q.listNumber]?.fieldLabels ?? const [];

  /// Sum target + row count for decomposition items.
  static int pairTarget(DiagnosticQuestion q) {
    final spec = kAnswerSpecs[q.listNumber];
    return spec?.target ?? 0;
  }

  static int pairRows(DiagnosticQuestion q) {
    final spec = kAnswerSpecs[q.listNumber];
    return spec?.rows ?? 0;
  }

  /// Numbers a `DiagnosticAnswerMode.sort` item expects in final order — the
  /// numbers found in [DiagnosticQuestion.correctAnswer], in that order.
  static List<int> sortItems(DiagnosticQuestion q) => intsIn(q.correctAnswer);

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
    if (RegExp(r'größer\s+oder\s+kleiner|kleiner\s+oder\s+größer')
        .hasMatch(german)) {
      return const ['größer', 'kleiner'];
    }
    if (RegExp(r'gerade\s+oder\s+ungerade').hasMatch(german)) {
      return const ['gerade', 'ungerade'];
    }
    // "Stimmt das? ..." equation-equivalence items expect exactly "ja"/"nein"
    // — detected from the correct answer itself, so it works regardless of
    // how the question is worded.
    final correctNormalized = normalize(q.correctAnswer);
    if (correctNormalized == 'ja' || correctNormalized == 'nein') {
      return const ['ja', 'nein'];
    }
    return const [];
  }
}

/// Renders a label for [mode] shown above the input (German child-facing).
String answerFieldLabel(DiagnosticAnswerMode mode) => switch (mode) {
      DiagnosticAnswerMode.number => 'Deine Antwort',
      DiagnosticAnswerMode.sequence => 'Trage die Zahlen in der richtigen Reihenfolge ein.',
      DiagnosticAnswerMode.labeledFields => 'Trage für jede Zeile die passende Zahl ein.',
      DiagnosticAnswerMode.pairRows => 'Schreibe jede Zerlegung in eine eigene Zeile.',
      DiagnosticAnswerMode.choice => 'Tippe deine Antwort an.',
      DiagnosticAnswerMode.sort => 'Ziehe die Zahlen in die richtige Reihenfolge.',
      DiagnosticAnswerMode.freeText => 'Schreibe deine Antwort auf.',
    };
