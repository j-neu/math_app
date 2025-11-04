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
  final String? imagePath;

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
    this.imagePath,
  });
}