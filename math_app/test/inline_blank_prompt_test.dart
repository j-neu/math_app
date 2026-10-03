import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/diagnostic_question.dart';
import 'package:math_app/services/answer_grading.dart';
import 'package:math_app/services/diagnostic_service.dart';
import 'package:math_app/widgets/diagnostic_answer_widgets.dart';

/// InlineBlankPrompt replaces a question's literal "__" placeholders with
/// live input boxes in place, instead of the separate prompt-then-input
/// layout that was confusing kids in the 2026-09-24 pilot test (they didn't
/// connect the blanks they read in the sentence to the disconnected boxes
/// rendered below it).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final csv = File('Research/diagnostic_v4_master.csv').readAsStringSync();
  final master = DiagnosticService.loadQuestionsFromCsv(csv);
  DiagnosticQuestion bySkill(String skillId) =>
      master.firstWhere((e) => e.ifWrongPracticeSkills.contains(skillId));

  Future<TextEditingController> pumpFor(
    WidgetTester tester,
    DiagnosticQuestion question,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: InlineBlankPrompt(question: question, controller: controller),
      ),
    ));
    return controller;
  }

  testWidgets(
      'single-blank completion item: the box sits inline between the '
      'surrounding text instead of in a separate field below it',
      (tester) async {
    final question = bySkill('complete_to_10');
    expect(InlineBlankPrompt.appliesTo(question), isTrue);
    final controller = await pumpFor(tester, question);

    // The text either side of the blank still renders as plain text.
    expect(find.textContaining('+'), findsWidgets);
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(1));

    await tester.enterText(fields.first, question.correctAnswer.trim());
    await tester.pump();

    expect(controller.text, question.correctAnswer.trim());
    expect(
        AnswerGrading.grade(userAnswer: controller.text, question: question),
        isTrue);
  });

  testWidgets(
      'count_forward_zr20: 4 boxes render inline after the given numbers, '
      'joining and grading like the previous separate layout did',
      (tester) async {
    final question = bySkill('count_forward_zr20');
    expect(InlineBlankPrompt.appliesTo(question), isTrue);
    final controller = await pumpFor(tester, question);

    // The given numbers from the sentence (11, 12, 13) still render as
    // text -- only the trailing blanks become boxes.
    expect(find.textContaining('11'), findsWidgets);
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(4));

    const answers = ['14', '15', '16', '17'];
    for (var i = 0; i < answers.length; i++) {
      await tester.enterText(fields.at(i), answers[i]);
    }
    await tester.pump();

    expect(controller.text, '14, 15, 16, 17');
    expect(
        AnswerGrading.grade(userAnswer: controller.text, question: question),
        isTrue);
  });

  testWidgets('a leading blank ("__ + 8 = 10") still renders one usable box',
      (tester) async {
    final question = master.firstWhere((q) =>
        q.ifWrongPracticeSkills.contains('complete_to_10') &&
        q.german.trim().startsWith('__'));
    expect(InlineBlankPrompt.appliesTo(question), isTrue);
    final controller = await pumpFor(tester, question);

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(1));
    await tester.enterText(fields.first, question.correctAnswer.trim());
    await tester.pump();
    expect(controller.text, question.correctAnswer.trim());
  });

  test('appliesTo is false for items with no "__" to substitute', () {
    final question = DiagnosticQuestion(
      listNumber: 9201,
      sourceType: QuestionType.text,
      questionText: 'Wie viele Punkte siehst du?',
      answerFormat: AnswerFormat.single,
      correctAnswer: '7',
      german: 'Wie viele Punkte siehst du?',
      english: 'Test',
      ifWrongPracticeSkills: const [],
    );
    expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.number);
    expect(InlineBlankPrompt.appliesTo(question), isFalse);
  });

  test(
      'appliesTo is false for modes other than number/sequence, even when '
      'the text contains "__"', () {
    final question = DiagnosticQuestion(
      listNumber: 9202,
      sourceType: QuestionType.text,
      questionText: 'Welche Rechnung passt?',
      answerFormat: AnswerFormat.single,
      correctAnswer: '5+4',
      german: 'Welche Rechnung passt: __ oder 5-4?',
      english: 'Test',
      ifWrongPracticeSkills: const [],
    );
    expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.freeText);
    expect(InlineBlankPrompt.appliesTo(question), isFalse);
  });
}
