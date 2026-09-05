import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/diagnostic_question.dart';
import 'package:math_app/services/answer_grading.dart';
import 'package:math_app/services/diagnostic_service.dart';

/// The full core bank must be answerable: for every item, the input mode the
/// app renders can express a canonical correct answer that the grader accepts.
/// This is the regression net for the "child cannot answer the question" class
/// of bugs (counting sequences, word answers, place-value phrases, C3/C4
/// transcripts).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final csv = File('Research/diagnostic_core_v1.csv').readAsStringSync();
  final questions = DiagnosticService.loadQuestionsFromCsv(csv);

  String canonicalAnswer(DiagnosticQuestion question, DiagnosticAnswerMode mode) {
    final spec = kAnswerSpecs[question.listNumber];
    switch (mode) {
      case DiagnosticAnswerMode.number:
        return AnswerGrading.singleResultNumber(question)?.toString() ?? '';
      case DiagnosticAnswerMode.sequence:
        final numbers = spec?.expectedNumbers.isNotEmpty == true
            ? spec!.expectedNumbers
            : AnswerGrading.intsIn(question.correctAnswer);
        return numbers.join(', ');
      case DiagnosticAnswerMode.pairRows:
        final pairs = <String>[];
        for (var i = 0; i < spec!.rows!; i++) {
          final a = i + 1;
          final b = spec.target! - a;
          pairs.add('$a + $b');
        }
        return pairs.join('; ');
      case DiagnosticAnswerMode.choice:
        return question.correctAnswer.trim();
      case DiagnosticAnswerMode.sort:
        return AnswerGrading.sortItems(question).join(', ');
      case DiagnosticAnswerMode.freeText:
        final expected = spec?.expectedNumbers;
        if (expected != null && expected.isNotEmpty) {
          return expected.last.toString();
        }
        return AnswerGrading.intsIn(question.correctAnswer).join(', ');
    }
  }

  test('every one of the 59 core items has a renderable, gradable answer', () {
    expect(questions.length, 59);
    final failures = <String>[];
    for (final question in questions) {
      final mode = AnswerGrading.modeFor(question);
      final typed = canonicalAnswer(question, mode);
      if (typed.trim().isEmpty) {
        failures.add('Q${question.listNumber}: no canonical answer for '
            '${mode.name} (correct="${question.correctAnswer}")');
        continue;
      }
      final ok = AnswerGrading.grade(userAnswer: typed, question: question);
      if (!ok) {
        failures.add('Q${question.listNumber}: graded WRONG '
            '(mode=${mode.name}, typed="$typed", '
            'correct="${question.correctAnswer}")');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('previously-broken items have their intended modes', () {
    DiagnosticAnswerMode modeOf(int n) =>
        AnswerGrading.modeFor(questions.firstWhere((q) => q.listNumber == n));

    expect(modeOf(1), DiagnosticAnswerMode.sequence);
    expect(modeOf(2), DiagnosticAnswerMode.sequence);
    expect(modeOf(11), DiagnosticAnswerMode.choice);
    expect(modeOf(15), DiagnosticAnswerMode.pairRows);
    expect(modeOf(17), DiagnosticAnswerMode.pairRows);
    expect(modeOf(20), DiagnosticAnswerMode.sequence);
    expect(modeOf(45), DiagnosticAnswerMode.number);
    expect(modeOf(58), DiagnosticAnswerMode.freeText);
    expect(modeOf(59), DiagnosticAnswerMode.freeText);
  });
}
