import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import '../models/diagnostic_question.dart';
import 'diagnostic_shortening.dart' show ConstructGates, difficultyFrom, constructFrom;

/// Loads the clean-room diagnostic item bank.
///
/// The runtime asset is `Research/diagnostic_core_v1.csv` (the 59-item core
/// test, tasks.md R5.1). The optional deep-dive blocks live in the sibling
/// `Research/diagnostic_deepdive_v1.csv` and are not loaded by the core
/// diagnostic flow. Both files use a 14-column schema
/// (ListNumber,SourceType,QuestionText,AnswerFormat,CorrectAnswer,German,
/// English,IfWrong_practice_skills,Ifwrong_skip,Notes,SkipGroup,Zahlenraum,
/// AudioAsset,Hilfetext), so the parser column indexes are unchanged for the
/// first 13 columns; Hilfetext (index 13) is new and optional — rows without
/// it (none, after this change regenerates both files) still parse via the
/// `row.length > 13` guard.
class DiagnosticService {
  /// Legacy v1 ListNumbers this v2 file supersedes for `verdoppeln-halbieren`
  /// (see Phase 3a plan Task 1 Step 1) -- excluded when merging so a child
  /// never sees both the old and the new item for the same construct.
  ///
  /// Task 1 Step 1 searched the v1 core file for rows routed via the v2 skill
  /// IDs (basic_strategy_7/8/9/10, strategy_doubling_tens_1) and found none, so
  /// the set is intentionally empty: there is no legacy item to filter out.
  static const Set<int> _kSupersededByV2 = {18, 22, 23};

  Future<List<DiagnosticQuestion>> loadQuestions() async {
    final coreCsv =
        await rootBundle.loadString('Research/diagnostic_core_v1.csv');
    final coreQuestions = loadQuestionsFromCsv(coreCsv)
        .where((q) => !_kSupersededByV2.contains(q.listNumber))
        .toList();

    final v2Csv = await rootBundle
        .loadString('Research/diagnostic_v2_verdoppeln_halbieren.csv');
    final v2Questions = loadQuestionsFromCsv(v2Csv);

    return [...coreQuestions, ...v2Questions];
  }

  /// Pure CSV variant of [loadQuestions] — used by tests and by callers that
  /// already hold the CSV text (e.g. deep-dive files), no asset bundle.
  static List<DiagnosticQuestion> loadQuestionsFromCsv(String csv) {
    final List<List<dynamic>> listData = const CsvToListConverter()
        .convert(csv.replaceAll('\r\n', '\n'), eol: '\n');

    final List<DiagnosticQuestion> questions = [];
    // Skip the header row
    for (var i = 1; i < listData.length; i++) {
      final row = listData[i];

      // Handle potential parsing errors or empty rows
      if (row.length < 8) continue;

      try {
        final listNumber = int.parse(row[0].toString());
        final sourceType = _parseQuestionType(row[1].toString());

        final questionText = row[2].toString();

        // Parse semantic skill IDs from IfWrong_practice_skills column (index 7)
        final skillsString = row[7].toString().trim();
        final skillsList = _parseSkillIds(skillsString);

        final skipGroupRaw = row.length > 10 ? row[10].toString().trim() : '';
        final zahlenraumRaw = row.length > 11 ? row[11].toString().trim() : '';
        final audioAssetRaw = row.length > 12 ? row[12].toString().trim() : '';
        final hilfetextRaw = row.length > 13 ? row[13].toString().trim() : '';
        final notes = row.length > 9 ? row[9].toString() : '';
        questions.add(
          DiagnosticQuestion(
            listNumber: listNumber,
            sourceType: sourceType,
            questionText: questionText,
            answerFormat: _parseAnswerFormat(row[3].toString()),
            correctAnswer: row[4].toString(),
            german: row[5].toString(),
            english: row[6].toString(),
            ifWrongPracticeSkills: skillsList,
            ifWrongSkip: row.length > 8 ? row[8].toString() : null,
            skipGroup: skipGroupRaw.isEmpty ? null : skipGroupRaw,
            zahlenraum: zahlenraumRaw.isEmpty ? null : zahlenraumRaw,
            imagePath: _getImagePath(questionText, sourceType),
            audioAsset: audioAssetRaw.isEmpty ? null : audioAssetRaw,
            constructId: constructFrom(notes),
            difficulty: difficultyFrom(notes),
            hilfetext: hilfetextRaw.isEmpty ? null : hilfetextRaw,
          ),
        );
      } catch (e) {
        // Log error for debugging, but continue processing other rows
        print('Error parsing row $i: $e');
      }
    }
    return questions;
  }

  /// Parses comma-separated skill IDs into a list
  /// Example: "counting_1, counting_2" → ["counting_1", "counting_2"]
  static List<String> _parseSkillIds(String skillsString) {
    if (skillsString.isEmpty) return [];

    return skillsString
        .split(',')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList();
  }

  static QuestionType _parseQuestionType(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return QuestionType.image;
      case 'text':
        return QuestionType.text;
      case 'cards':
        return QuestionType.cards;
      case 'picture':
        return QuestionType.picture;
      default:
        return QuestionType.text; // Default or throw error
    }
  }

  static AnswerFormat _parseAnswerFormat(String format) {
    switch (format.toLowerCase()) {
      case 'single':
        return AnswerFormat.single;
      case 'multiple':
        return AnswerFormat.multiple;
      case 'sort':
        return AnswerFormat.sort;
      default:
        return AnswerFormat.single; // Default or throw error
    }
  }

  static String? _getImagePath(String questionText, QuestionType sourceType) {
    // Only Image, Cards, and Picture types need images
    if (sourceType == QuestionType.image ||
        sourceType == QuestionType.cards ||
        sourceType == QuestionType.picture) {
      // Visual items carry an item ID (e.g. "A2.2-01") rather than a bundled
      // image filename; only legacy filename-style rows get an image path.
      if (questionText.toLowerCase().endsWith('.jpg') ||
          questionText.toLowerCase().endsWith('.png') ||
          questionText.toLowerCase().endsWith('.jpeg')) {
        return 'Research/DiagnosticPictures/$questionText';
      }
    }
    return null;
  }
}
