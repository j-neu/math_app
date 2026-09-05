import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/diagnostic_question.dart';
import 'package:math_app/services/answer_grading.dart';
import 'package:math_app/services/diagnostic_service.dart';
import 'package:math_app/widgets/diagnostic_answer_widgets.dart';

/// Proves the child-facing interaction path for the input modes: what the
/// child types/taps lands in the shared controller and grades correct.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final csv = File('Research/diagnostic_core_v1.csv').readAsStringSync();
  final all = DiagnosticService.loadQuestionsFromCsv(csv);
  DiagnosticQuestion q(int n) => all.firstWhere((e) => e.listNumber == n);

  Future<TextEditingController> pumpFor(
    WidgetTester tester,
    DiagnosticQuestion question,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DiagnosticAnswerInput(
          question: question,
          controller: controller,
        ),
      ),
    ));
    return controller;
  }

  testWidgets('Q1 counting sequence: 8 numeric fields join and grade correct',
      (tester) async {
    final question = q(1);
    final controller = await pumpFor(tester, question);

    expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.sequence);
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(8));

    const answers = ['13', '14', '15', '16', '17', '18', '19', '20'];
    for (var i = 0; i < answers.length; i++) {
      await tester.enterText(fields.at(i), answers[i]);
    }
    await tester.pump();

    expect(controller.text, '13, 14, 15, 16, 17, 18, 19, 20');
    expect(AnswerGrading.grade(userAnswer: controller.text, question: question),
        isTrue);
  });

  testWidgets('Q11 compare: tapping "rechts" writes the word and grades true',
      (tester) async {
    final question = q(11);
    final controller = await pumpFor(tester, question);

    expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.choice);
    await tester.tap(find.text('rechts'));
    await tester.pump();

    expect(controller.text, 'rechts');
    expect(AnswerGrading.grade(userAnswer: controller.text, question: question),
        isTrue);
  });

  testWidgets('Q36 arithmetic: typing the number grades true', (tester) async {
    final question = q(36);
    final controller = await pumpFor(tester, question);
    expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.number);
    await tester.enterText(find.byType(TextField), '13');
    expect(AnswerGrading.grade(userAnswer: controller.text, question: question),
        isTrue);
  });

  testWidgets('Q15 decomposition: three rows of pairs grade correct',
      (tester) async {
    final question = q(15);
    final controller = await pumpFor(tester, question);
    expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.pairRows);

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(6));
    const answers = ['1', '7', '2', '6', '3', '5'];
    for (var i = 0; i < answers.length; i++) {
      await tester.enterText(fields.at(i), answers[i]);
    }
    await tester.pump();
    expect(AnswerGrading.grade(userAnswer: controller.text, question: question),
        isTrue);
  });

  testWidgets(
      'Q3 backward count shows the given start as static text ahead of the boxes',
      (tester) async {
    final question = q(3);
    final controller = await pumpFor(tester, question);

    expect(find.text('21,'), findsOneWidget);
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(5));

    const answers = ['20', '19', '18', '17', '16'];
    for (var i = 0; i < answers.length; i++) {
      await tester.enterText(fields.at(i), answers[i]);
    }
    await tester.pump();
    expect(
      AnswerGrading.grade(userAnswer: controller.text, question: question),
      isTrue,
    );
  });

  DiagnosticQuestion sortQuestion() => DiagnosticQuestion(
        listNumber: 9001,
        sourceType: QuestionType.text,
        questionText: 'Sortiere',
        answerFormat: AnswerFormat.sort,
        correctAnswer: '3, 12, 27',
        german: 'Bringe die Zahlen der Größe nach: klein zuerst.',
        english: 'Test',
        ifWrongPracticeSkills: const [],
      );

  testWidgets(
      'sort item: shuffles away from the solution and grades order-exact',
      (tester) async {
    final question = sortQuestion();
    final controller = await pumpFor(tester, question);

    expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.sort);
    expect(find.byType(Card), findsNWidgets(3));
    expect(controller.text, isNot('3, 12, 27'));
    expect(
      AnswerGrading.grade(userAnswer: '3, 12, 27', question: question),
      isTrue,
    );
    expect(
      AnswerGrading.grade(userAnswer: '12, 3, 27', question: question),
      isFalse,
    );
  });

  testWidgets('sequence input still renders exactly 6 boxes at the item cap',
      (tester) async {
    final question = DiagnosticQuestion(
      listNumber: 9002,
      sourceType: QuestionType.text,
      questionText: 'Test',
      answerFormat: AnswerFormat.single,
      correctAnswer: '1, 2, 3, 4, 5, 6',
      german: 'Test',
      english: 'Test',
      ifWrongPracticeSkills: const [],
    );
    await pumpFor(tester, question);
    expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.sequence);
    expect(find.byType(TextField), findsNWidgets(6));
  });
}
