/// Number of help stages per diagnostic question.
const int kMaxHelpLevel = 3;

/// An answer only counts as mastered if the child got it right without the
/// last, direct-instruction hint (spec 2026-10-22, Jakob's decision).
bool gradeWithHelp({required bool textCorrect, required int helpLevel}) =>
    textCorrect && helpLevel < kMaxHelpLevel;
