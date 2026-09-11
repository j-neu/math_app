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
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('Hilfetext parses for curated items and stays null otherwise', () {
    DiagnosticQuestion byNumber(List<DiagnosticQuestion> qs, int n) =>
        qs.firstWhere((q) => q.listNumber == n);

    // A2.1-01 is core item 8 and has a written Hilfetext.
    expect(byNumber(coreQuestions, 8).hilfetext, isNotNull);
    expect(byNumber(coreQuestions, 8).hilfetext, contains('Rechenrahmen'));
    // A1.1-01 (item 1) has none.
    expect(byNumber(coreQuestions, 1).hilfetext, isNull);

    // DDA-04 is deep-dive item 4 and has a written Hilfetext.
    expect(byNumber(deepDiveQuestions, 4).hilfetext, isNotNull);
    // DDA-01 (deep-dive item 1) has none.
    expect(byNumber(deepDiveQuestions, 1).hilfetext, isNull);
  });

  test('loadQuestions merges the v2 CSV and excludes superseded v1 rows',
      () async {
    final service = DiagnosticService();
    final questions = await service.loadQuestions();

    final v2Item = questions.firstWhere(
      (q) => q.ifWrongPracticeSkills.contains('verdoppeln-halbieren.ZR10'),
      orElse: () => throw StateError('v2 item not found'),
    );
    expect(v2Item.correctAnswer, '8');
    expect(v2Item.zahlenraum, 'ZR10');

    expect(questions.every((q) => ![18, 22, 23].contains(q.listNumber)),
        isTrue,
        reason: 'superseded v1 items 18, 22, 23 must not be served');
  });

  test('loadQuestions merges the v2 item-quality-fix CSV', () async {
    final service = DiagnosticService();
    final questions = await service.loadQuestions();

    // A3.3 replacement: no "Kim" framing, correct answer 8.
    final a33Item = questions.firstWhere(
      (q) =>
          q.ifWrongPracticeSkills.contains('A3.3') &&
          q.german.contains('doppelt so groß wie die 4'),
      orElse: () => throw StateError('v2 A3.3 replacement not found'),
    );
    expect(a33Item.correctAnswer, '8');
    expect(a33Item.german, isNot(contains('Kim')));

    // B1.2 replacement: 41 as 3 tens + 11 ones.
    final b12Item = questions.firstWhere(
      (q) => q.questionText == 'B1.2-repl-01',
      orElse: () => throw StateError('v2 B1.2 replacement not found'),
    );
    expect(b12Item.ifWrongPracticeSkills, contains('B1.2'));
    expect(b12Item.correctAnswer, '41');

    // B2.2 ZR20 ladder rung is served with its ZR20 tag.
    final b22Item = questions.firstWhere(
      (q) => q.questionText == 'B2.2-repl-02',
      orElse: () => throw StateError('v2 B2.2 replacement not found'),
    );
    expect(b22Item.zahlenraum, 'ZR20');
  });
}
