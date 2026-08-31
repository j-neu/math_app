/// Answer normalisation for practice input.
library;

/// Normalises a submitted answer for comparison: surrounding whitespace is
/// trimmed and every internal run of whitespace is collapsed to a single
/// space. German decimal commas are kept as-is — there is deliberately no
/// comma↔dot conversion, so `"7,5"` and `"7.5"` stay distinct.
String normalizeAnswer(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ');

/// True when [submitted] — normalised the same way as every candidate —
/// equals one of the accepted [expected] answers.
bool answersMatch(String submitted, Iterable<String> expected) {
  final normalized = normalizeAnswer(submitted);
  for (final candidate in expected) {
    if (normalized == normalizeAnswer(candidate)) return true;
  }
  return false;
}
