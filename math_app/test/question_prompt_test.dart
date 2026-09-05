import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/diagnostic_question.dart';
import 'package:math_app/screens/diagnostic_screen.dart';

/// QuestionPrompt renders the German wording exactly once. Before the
/// diagnostic usability rework §4.1, diagnostic_screen.dart also rendered
/// `questionText` at 48px for every text item — identical text, printed
/// twice on screen.
void main() {
  DiagnosticQuestion textQuestion({
    required String questionText,
    required String german,
  }) =>
      DiagnosticQuestion(
        listNumber: 1,
        sourceType: QuestionType.text,
        questionText: questionText,
        answerFormat: AnswerFormat.single,
        correctAnswer: '1',
        german: german,
        english: 'Test',
        ifWrongPracticeSkills: const [],
      );

  testWidgets('renders the German wording once', (tester) async {
    final question = textQuestion(
      questionText: 'Zähle von der Zahl 12 weiter, bis zur Zahl 20.',
      german: 'Zähle von der Zahl 12 weiter, bis zur Zahl 20.',
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: QuestionPrompt(question: question)),
    ));

    expect(find.text(question.german), findsOneWidget);
  });

  testWidgets('renders German even when questionText is a visual item ID',
      (tester) async {
    final question =
        textQuestion(questionText: 'A2.1-01', german: 'Wie viele Perlen waren es?');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: QuestionPrompt(question: question)),
    ));

    expect(find.text('Wie viele Perlen waren es?'), findsOneWidget);
    expect(find.text('A2.1-01'), findsNothing);
  });
}
