import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/models/diagnostic_question.dart';
import 'package:math_app/services/diagnostic_service.dart';

/// Verifies `Research/diagnostic_v4_master.csv` -- the single, consolidated
/// item bank that replaced the incremental clean-room v1 (abandoned)/v2/
/// per-category-v3 merge once every category in
/// `_sources_private/skills_taxonomy_v3_diagnostic.csv` had been reviewed and
/// approved. `DiagnosticService.loadQuestions()` now serves this file only.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<DiagnosticQuestion> master;

  setUpAll(() {
    master = DiagnosticService.loadQuestionsFromCsv(
      File('Research/diagnostic_v4_master.csv').readAsStringSync(),
    );
  });

  test('master CSV parses with sequential ListNumbers and no parse errors',
      () {
    expect(master, isNotEmpty);
    expect(master.map((q) => q.listNumber).toList(),
        List<int>.generate(master.length, (i) => i + 1));
  });

  test('every item has a non-empty Wording, CorrectAnswer and skill tag', () {
    for (final q in master) {
      expect(q.german.trim(), isNotEmpty, reason: 'ListNumber ${q.listNumber}');
      expect(q.correctAnswer.trim(), isNotEmpty,
          reason: 'ListNumber ${q.listNumber}');
      expect(q.ifWrongPracticeSkills, isNotEmpty,
          reason: 'ListNumber ${q.listNumber}');
    }
  });

  test('loadQuestions() serves exactly the master CSV, unmodified', () async {
    final service = DiagnosticService();
    final questions = await service.loadQuestions();
    expect(questions.length, master.length);
    expect(questions.map((q) => q.listNumber).toList(),
        master.map((q) => q.listNumber).toList());
  });

  test('visual items carry their item ID as QuestionText', () {
    final visualIds = master
        .where((q) => q.sourceType == QuestionType.image)
        .map((q) => q.questionText)
        .toSet();
    // V3D-04 and V3S-03 were dropped from the master list during Jakob's
    // review (2026-09-13); everything else survives.
    expect(visualIds, isNot(contains('V3D-04')));
    expect(visualIds, isNot(contains('V3S-03')));
    expect(
        visualIds,
        containsAll(<String>[
          'V3Z-01', 'V3Z-02',
          'V3D-01', 'V3D-05', 'V3D-06', 'V3D-10',
          'V3S-01', 'V3S-05',
          'V3G-01',
          'V3K-01', 'V3K-02',
          'V3M-01', 'V3M-02', 'V3M-03',
        ]));
  });

  DiagnosticQuestion bySkill(String skillId) => master
      .firstWhere((q) => q.ifWrongPracticeSkills.contains(skillId));

  test('complete_to_100 sits with the other completion items, not stranded '
      'after the Zahlzerlegung visual items (V3D-*)', () {
    final completeTo10First = master
        .indexWhere((q) => q.ifWrongPracticeSkills.contains('complete_to_10'));
    final completeTo100Index = master.indexOf(bySkill('complete_to_100'));
    final firstStructuredDotsVisual = master.indexWhere(
        (q) => q.sourceType == QuestionType.image && q.questionText.startsWith('V3D-'));
    expect(completeTo10First, greaterThanOrEqualTo(0));
    expect(completeTo100Index, lessThan(firstStructuredDotsVisual),
        reason: 'complete_to_100 should be grouped with the other gap-fill '
            'items, ahead of the structured-dots visual items');
  });

  test('"ohne zu zählen" was dropped from the structured-recognition prompts',
      () {
    for (final q in master.where((q) =>
        q.ifWrongPracticeSkills.contains('structured_quantity_recognition_zr10') ||
        q.ifWrongPracticeSkills.contains('structured_quantity_recognition_zr20'))) {
      expect(q.german, isNot(contains('ohne zu zählen')));
    }
  });

  test('bundling wording says Zehnerstangen/Einerwürfel, not Punkte', () {
    for (final q in master.where((q) => q.ifWrongPracticeSkills
        .contains('bundling_recognition_zr100'))) {
      expect(q.german, isNot(contains('Punkte')));
    }
  });

  test('bundling_recognition_overflow_zr100 (4 tens + 13 loose ones) asks '
      'for the grand total', () {
    expect(bySkill('bundling_recognition_overflow_zr100').correctAnswer, '53');
  });

  test('hundred_chart_structure_zr100: each direction resolves to the '
      'correct row/column-structure neighbor', () {
    final structureAnswers = {
      for (final q in master.where((q) => q.ifWrongPracticeSkills
          .contains('hundred_chart_structure_zr100')))
        q.questionText: q.correctAnswer
    };
    expect(structureAnswers, {
      'V3S-05': '37', // above 47
      'V3S-06': '73', // below 63
      'V3S-07': '57', // left of 58
      'V3S-08': '25', // right of 24
    });
  });

  test('double_zr10 and even_odd_recognition grade the expected values', () {
    expect(bySkill('double_zr10').correctAnswer, '6');
    final evenOdd = master.firstWhere(
        (q) => q.ifWrongPracticeSkills.contains('even_odd_recognition') &&
            q.german.contains('14'));
    expect(evenOdd.correctAnswer, 'gerade');
  });

  test('derive_via_near_double_add and the number-wall/triangle items grade '
      'the expected values', () {
    expect(bySkill('derive_via_near_double_add').correctAnswer, '15');
    expect(bySkill('number_wall_zr20').correctAnswer, '17');
    expect(bySkill('calculation_triangle_zr20').correctAnswer, '10');
  });

  test('ordinal_1 and operation_sense_story grade the expected values', () {
    expect(bySkill('ordinal_1').correctAnswer, '3');
    // The story-equation item grades the typed equation, not the result.
    expect(bySkill('operation_sense_story').correctAnswer, '5+4');
  });

  test('the Rechenstrich items render as their RechenstrichWidget visual IDs',
      () {
    expect(bySkill('number_line_rechenstrich').questionText, 'V3M-02');
    expect(bySkill('number_line_zahlenstrahl').questionText, 'V3M-03');
  });
}
