import '../models/diagnostic_question.dart';

/// Abbreviated-diagnostic break-off, construct-keyed (blueprint
/// `02-blueprint.md` §Sequenzregeln 2–3 + §Break-off).
///
/// The core test orders every construct's items easy → medium → hard. The
/// shortened mode uses that order as its gate: once a child has answered an
/// item of a construct WRONG, the remaining items of the SAME construct that
/// are strictly harder carry no new diagnostic information and are skipped.
/// Items of equal difficulty are still presented even when the numbers get
/// larger — a "double 20" after a failed "double 7" tests the same level at a
/// round number and may well be solved, so skipping it would remove signal.
///
/// A failure never gates items of OTHER constructs: insight is preserved in
/// every Aufgabenbereich (Domänen A–D) down to the level the child demonstrably
/// cannot exceed (cautious against over-shortening; the blueprint's wider
/// cross-construct table stays documented in `skip_rules.dart`).
class ConstructGates {
  /// Whether shortening is active for this run (abbreviated_mode ticket).
  final bool abbreviated;

  /// Per construct: highest difficulty rank the child has answered wrong.
  final Map<String, int> _failedRank = {};

  ConstructGates({required this.abbreviated});

  /// Records an answered (presented) question. Skipped questions are never
  /// passed here — they carry no signal and must not raise a gate.
  void noteAnswered(DiagnosticQuestion question, bool wasCorrect) {
    if (!abbreviated || wasCorrect) return;
    final construct = question.constructId;
    final rank = question.difficulty?.rank;
    if (construct == null || rank == null) return;
    final previous = _failedRank[construct] ?? -1;
    if (rank > previous) _failedRank[construct] = rank;
  }

  /// Decides whether [question] is skipped because an EASIER item of the same
  /// construct has already been failed.
  bool shouldSkip(DiagnosticQuestion question) {
    if (!abbreviated) return false;
    final construct = question.constructId;
    final rank = question.difficulty?.rank;
    if (construct == null || rank == null) return false;
    final failed = _failedRank[construct];
    if (failed == null) return false;
    return rank > failed;
  }

  /// Difficulty of the hardest wrong answer so far in [construct], or null.
  int? failedRankOf(String construct) => _failedRank[construct];

  void clear() => _failedRank.clear();
}

/// Item rows carry `Notes = "<difficulty>; <construct-code> <label>"`
/// (written by `scripts/generate_diagnostic_csv.py` from the item files).
final RegExp _difficultyPattern =
    RegExp(r'^(easy|medium|hard)\b', caseSensitive: false);
final RegExp _constructPattern = RegExp(r'\b([A-D][0-9]+(?:\.[0-9]+)*)\b');

QuestionDifficulty? difficultyFrom(String? notes) {
  if (notes == null) return null;
  final m = _difficultyPattern.firstMatch(notes.trim());
  if (m == null) return null;
  return switch (m.group(1)!.toLowerCase()) {
    'easy' => QuestionDifficulty.easy,
    'medium' => QuestionDifficulty.medium,
    'hard' => QuestionDifficulty.hard,
    _ => null,
  };
}

String? constructFrom(String? notes) {
  if (notes == null) return null;
  final m = _constructPattern.firstMatch(notes);
  return m?.group(1);
}
