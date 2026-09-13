import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import '../models/diagnostic_question.dart';
import 'diagnostic_shortening.dart'
    show constructIdFrom, difficultyFromZahlenraum;

/// Loads the diagnostic item bank.
///
/// The runtime serves a single file, `Research/diagnostic_v4_master.csv` --
/// the legacy (iMINT/PIKAS-derived) rebuild described in
/// `_sources_private/kartei-index/`, covering every category in
/// `_sources_private/skills_taxonomy_v3_diagnostic.csv` (Zählen, Zahlzerlegung
/// / Schnelles Sehen, Stellenwerte verstehen, Grundstrategien, Kombinierte
/// Strategien, and the small PIKAS-sourced categories). It replaces the
/// earlier incremental build: the abandoned clean-room `diagnostic_core_v1.csv`
/// + `diagnostic_v2_item_quality_fixes.csv` (both deleted 2026-09-13, once
/// every category had full v3 coverage), and the six per-category
/// `diagnostic_v3_*.csv` files, which were reviewed and approved one at a
/// time and then consolidated -- Jakob deleted a few items and reordered the
/// rest during that review, and this file is the result, sequentially
/// renumbered to match. `diagnostic_v2_verdoppeln_halbieren.csv` was retired
/// earlier still (2026-09-12) for the same reason (fully superseded by v3
/// Grundstrategien's `double_*` items); all of these retired files are left
/// on disk, unloaded, since some still serve as fixtures for unit tests that
/// exercise the grading/parsing mechanics rather than live content.
/// The schema is unchanged (ListNumber,SourceType,QuestionText,AnswerFormat,
/// CorrectAnswer,German,English,IfWrong_practice_skills,Ifwrong_skip,Notes,
/// SkipGroup,Zahlenraum,AudioAsset,Hilfetext); rows without the optional
/// Hilfetext (index 13) still parse via the `row.length > 13` guard.
class DiagnosticService {
  Future<List<DiagnosticQuestion>> loadQuestions() async {
    final masterCsv =
        await rootBundle.loadString('Research/diagnostic_v4_master.csv');
    return loadQuestionsFromCsv(masterCsv);
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
            constructId: constructIdFrom(
                skipGroupRaw.isEmpty ? null : skipGroupRaw, skillsList),
            difficulty: difficultyFromZahlenraum(
                zahlenraumRaw.isEmpty ? null : zahlenraumRaw),
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
