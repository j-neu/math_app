import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/diagnostic_question.dart';
import 'package:math_app/services/answer_grading.dart';
import 'package:math_app/services/diagnostic_service.dart';
import 'package:math_app/widgets/diagnostic_answer_widgets.dart';

/// Proves the child-facing interaction path for the input modes: what the
/// child types/taps lands in the shared controller and grades correct.
///
/// Where the live `Research/diagnostic_v4_master.csv` content demonstrates a
/// mode (number, sequence, choice), the fixture is a real master item so the
/// test doubles as content coverage. Two modes (labeledFields, pairRows) and
/// the sequence "anchor" convenience have no live master item right now, so
/// those use synthetic fixtures (kAnswerSpecs 9101-9104) purely to keep the
/// widget mechanics covered.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final csv = File('Research/diagnostic_v4_master.csv').readAsStringSync();
  final master = DiagnosticService.loadQuestionsFromCsv(csv);
  DiagnosticQuestion bySkill(String skillId) => master
      .firstWhere((e) => e.ifWrongPracticeSkills.contains(skillId));

  DiagnosticQuestion labeledFieldsFixture1() => DiagnosticQuestion(
        listNumber: 9101,
        sourceType: QuestionType.text,
        questionText: 'Welche Zahl kommt vor und nach 37?',
        answerFormat: AnswerFormat.single,
        correctAnswer: '36, 38',
        german: 'Welche Zahl kommt vor und nach 37?',
        english: 'Test',
        ifWrongPracticeSkills: const [],
      );

  DiagnosticQuestion labeledFieldsFixture2() => DiagnosticQuestion(
        listNumber: 9102,
        sourceType: QuestionType.text,
        questionText: 'Aus wie vielen Zehnern und Einern besteht 58?',
        answerFormat: AnswerFormat.single,
        correctAnswer: '5, 8',
        german: 'Aus wie vielen Zehnern und Einern besteht 58?',
        english: 'Test',
        ifWrongPracticeSkills: const [],
      );

  DiagnosticQuestion pairRowsFixture() => DiagnosticQuestion(
        listNumber: 9103,
        sourceType: QuestionType.text,
        questionText: 'Finde drei verschiedene Wege, 8 zu rechnen.',
        answerFormat: AnswerFormat.single,
        correctAnswer: '1 + 7; 2 + 6; 3 + 5',
        german: 'Finde drei verschiedene Wege, 8 zu rechnen.',
        english: 'Test',
        ifWrongPracticeSkills: const [],
      );

  DiagnosticQuestion anchorSequenceFixture() => DiagnosticQuestion(
        listNumber: 9104,
        sourceType: QuestionType.text,
        questionText: 'Zähle rückwärts weiter.',
        answerFormat: AnswerFormat.single,
        correctAnswer: '20, 19, 18, 17, 16',
        german: 'Zähle rückwärts weiter: 21, __, __, __, __, __',
        english: 'Test',
        ifWrongPracticeSkills: const [],
      );

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

  testWidgets(
      'count_forward_zr20: 4 numeric fields join and grade correct',
      (tester) async {
    final question = bySkill('count_forward_zr20');
    final controller = await pumpFor(tester, question);

    expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.sequence);
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(4));

    const answers = ['14', '15', '16', '17'];
    for (var i = 0; i < answers.length; i++) {
      await tester.enterText(fields.at(i), answers[i]);
    }
    await tester.pump();

    expect(controller.text, '14, 15, 16, 17');
    expect(AnswerGrading.grade(userAnswer: controller.text, question: question),
        isTrue);
  });

  testWidgets(
      'even_odd_recognition: tapping "gerade" writes the word and grades true',
      (tester) async {
    final question = master.firstWhere(
        (q) => q.ifWrongPracticeSkills.contains('even_odd_recognition') &&
            q.german.contains('14'));
    final controller = await pumpFor(tester, question);

    expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.choice);
    await tester.tap(find.text('gerade'));
    await tester.pump();

    expect(controller.text, 'gerade');
    expect(AnswerGrading.grade(userAnswer: controller.text, question: question),
        isTrue);
  });

  testWidgets('basic_fact_add_with_5: typing the number grades true',
      (tester) async {
    final question = bySkill('basic_fact_add_with_5');
    final controller = await pumpFor(tester, question);
    expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.number);
    await tester.enterText(find.byType(TextField), question.correctAnswer);
    expect(AnswerGrading.grade(userAnswer: controller.text, question: question),
        isTrue);
  });

  testWidgets(
      'Vorgänger/Nachfolger fixture renders two labeled fields that join and '
      'grade', (tester) async {
    final question = labeledFieldsFixture1();
    final controller = await pumpFor(tester, question);

    expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.labeledFields);
    expect(find.text('Zahl davor:'), findsOneWidget);
    expect(find.text('Zahl danach:'), findsOneWidget);
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));

    await tester.enterText(fields.at(0), '36');
    await tester.enterText(fields.at(1), '38');
    await tester.pump();

    expect(controller.text, '36, 38');
    expect(AnswerGrading.grade(userAnswer: controller.text, question: question),
        isTrue);
  });

  testWidgets(
      'place-value fixture renders Zehner/Einer fields that join and grade',
      (tester) async {
    final question = labeledFieldsFixture2();
    final controller = await pumpFor(tester, question);

    expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.labeledFields);
    expect(find.text('Zehner:'), findsOneWidget);
    expect(find.text('Einer:'), findsOneWidget);
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));

    await tester.enterText(fields.at(0), '5');
    await tester.enterText(fields.at(1), '8');
    await tester.pump();

    expect(controller.text, '5, 8');
    expect(AnswerGrading.grade(userAnswer: controller.text, question: question),
        isTrue);
  });

  testWidgets('decomposition fixture renders a visible "+" between fields',
      (tester) async {
    final question = pairRowsFixture();
    final controller = await pumpFor(tester, question);
    expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.pairRows);

    expect(find.text(' + '), findsNWidgets(3));
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(6));
    const answers = ['1', '7', '2', '6', '3', '5'];
    for (var i = 0; i < answers.length; i++) {
      await tester.enterText(fields.at(i), answers[i]);
    }
    await tester.pump();
    expect(controller.text, '1 + 7; 2 + 6; 3 + 5');
    expect(AnswerGrading.grade(userAnswer: controller.text, question: question),
        isTrue);
  });

  testWidgets('decomposition fixture: three rows of pairs grade correct',
      (tester) async {
    final question = pairRowsFixture();
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
      'anchor fixture shows the given start as static text ahead of the boxes',
      (tester) async {
    final question = anchorSequenceFixture();
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
