enum QuestionType {
  image,
  text,
  cards,
  picture,
}

enum AnswerFormat {
  single,
  multiple,
  sort,
}

class DiagnosticQuestion {
  final int listNumber;
  final QuestionType sourceType;
  final String questionText;
  final AnswerFormat answerFormat;
  final String correctAnswer;
  final String german;
  final String english;
  final String ifWrongPractice; // Deprecated: old numeric system
  final List<String> ifWrongPracticeSkills; // New semantic skill IDs
  final String? ifWrongSkip;
  final String? skipGroup; // Card-oriented break-off group; if null, fall back to first-skill-prefix
  final String? zahlenraum; // Explicit ZR (e.g. "ZR20", "ZR100"); overrides number-magnitude heuristic
  final String? imagePath;
  final String? audioAsset; // Public URL for audio asset (e.g. Supabase Storage URL)

  DiagnosticQuestion({
    required this.listNumber,
    required this.sourceType,
    required this.questionText,
    required this.answerFormat,
    required this.correctAnswer,
    required this.german,
    required this.english,
    @Deprecated('Use ifWrongPracticeSkills instead') this.ifWrongPractice = '',
    required this.ifWrongPracticeSkills,
    this.ifWrongSkip,
    this.skipGroup,
    this.zahlenraum,
    this.imagePath,
    this.audioAsset,
  });
}