import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import '../models/diagnostic_question.dart';

class DiagnosticService {
  Future<List<DiagnosticQuestion>> loadQuestions() async {
    // Use new CSV file with semantic skill IDs
    final rawData = await rootBundle.loadString('Research/MathApp_Diagnostic_with_skills.csv');
    final List<List<dynamic>> listData = const CsvToListConverter().convert(rawData, eol: '\n');

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
            imagePath: _getImagePath(questionText, sourceType),
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
      // For Image type, questionText contains the filename (e.g., "img2113.jpg")
      if (questionText.toLowerCase().endsWith('.jpg') ||
          questionText.toLowerCase().endsWith('.png') ||
          questionText.toLowerCase().endsWith('.jpeg')) {
        return 'Research/DiagnosticPictures/$questionText';
      }
    }
    return null;
  }
}