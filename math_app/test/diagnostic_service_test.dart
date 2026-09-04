import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/models/diagnostic_question.dart';
import 'package:math_app/services/diagnostic_service.dart';
import 'package:math_app/services/skill_catalog.dart';

// Verifies the R5.1 clean-room item bank: the generated core/deep-dive CSVs
// (scripts/generate_diagnostic_csv.py) parse through DiagnosticService with
// the legacy column schema, every IfWrong skill ID resolves in the new
// 36-skill taxonomy, and no core item ships without a Wording/CorrectAnswer.
void main() {
  late List<DiagnosticQuestion> coreQuestions;
  late List<DiagnosticQuestion> deepDiveQuestions;
  late SkillCatalog catalog;

  setUpAll(() {
    coreQuestions = DiagnosticService.loadQuestionsFromCsv(
      File('Research/diagnostic_core_v1.csv').readAsStringSync(),
    );
    deepDiveQuestions = DiagnosticService.loadQuestionsFromCsv(
      File('Research/diagnostic_deepdive_v1.csv').readAsStringSync(),
    );
    catalog = SkillCatalog.loadFromCsv(
      File('Research/skills_taxonomy.csv').readAsStringSync(),
    );
  });

  test('core tier parses exactly the 59 blueprint items', () {
    // 59, not 60: the R2.9 review (2026-08-30) struck A1.5-01 as redundant
    // against A1.1-02. See docs/clean-room/02-blueprint.md.
    expect(coreQuestions, hasLength(59));
    // ListNumbers are sequential 1..59.
    expect(coreQuestions.map((q) => q.listNumber).toList(),
        List<int>.generate(59, (i) => i + 1));
  });

  test('deep-dive sibling file parses exactly the 32 block items', () {
    expect(deepDiveQuestions, hasLength(32));
    expect(deepDiveQuestions.map((q) => q.listNumber).toList(),
        List<int>.generate(32, (i) => i + 1));
  });

  test('every IfWrong skill ID resolves in the new taxonomy', () {
    final unresolved = <String>[];
    for (final q in [...coreQuestions, ...deepDiveQuestions]) {
      for (final skillId in q.ifWrongPracticeSkills) {
        if (catalog.get(skillId) == null) {
          unresolved.add('${q.listNumber}: $skillId');
        }
      }
    }
    expect(unresolved, isEmpty,
        reason: 'Unresolved IfWrong_practice_skills: $unresolved');
  });

  test('every core item has a non-empty Wording and CorrectAnswer', () {
    for (final q in coreQuestions) {
      expect(q.german.trim(), isNotEmpty, reason: 'ListNumber ${q.listNumber}');
      expect(q.correctAnswer.trim(), isNotEmpty,
          reason: 'ListNumber ${q.listNumber}');
    }
  });

  test('visual items carry their item ID as QuestionText for R5.2', () {
    final visualIds = coreQuestions
        .where((q) => q.sourceType == QuestionType.image)
        .map((q) => q.questionText)
        .toSet();
    expect(visualIds, containsAll(<String>[
      'A2.1-01',
      'A2.2-01',
      'A2.2-02',
      'A2.3-01',
      'B1.2-01',
      'B2.1-01',
      'B2.2-01',
    ]));
    expect(visualIds, isNot(contains('img2113.jpg')));
  });
}
