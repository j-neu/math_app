import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/diagnostic_question.dart';
import 'package:math_app/services/answer_grading.dart';
import 'package:math_app/services/diagnostic_service.dart';

List<DiagnosticQuestion> loadCore() {
  final csv = File('Research/diagnostic_core_v1.csv').readAsStringSync();
  return DiagnosticService.loadQuestionsFromCsv(csv);
}

DiagnosticQuestion q(List<DiagnosticQuestion> all, int listNumber) =>
    all.firstWhere((q) => q.listNumber == listNumber);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('answer_grading — previously broken real items', () {
    final all = loadCore();

    test('counting sequence Q1 accepts typed sequence and rejects short one',
        () {
      final question = q(all, 1);
      expect(question.answerFormat, AnswerFormat.single);
      expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.sequence);
      expect(
        AnswerGrading.grade(
            userAnswer: '13, 14, 15, 16, 17, 18, 19, 20',
            question: question),
        isTrue,
      );
      expect(
        AnswerGrading.grade(
            userAnswer: '13, 14, 15, 16, 17, 18, 19', question: question),
        isFalse,
      );
    });

    test('counting sequence Q7 (Vorgänger/Nachfolger) accepts two numbers', () {
      final question = q(all, 7);
      expect(
          AnswerGrading.grade(userAnswer: '36, 38', question: question), isTrue);
      expect(
          AnswerGrading.grade(userAnswer: '35, 38', question: question),
          isFalse);
    });

    test('word choice Q11 accepts "rechts"', () {
      final question = q(all, 11);
      expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.choice);
      expect(
          AnswerGrading.grade(userAnswer: 'rechts', question: question),
          isTrue);
      expect(
          AnswerGrading.grade(userAnswer: 'links', question: question),
          isFalse);
    });

    test('place-value Q20 accepts "5 Zehner, 8 Einer." equivalents', () {
      final question = q(all, 20);
      expect(
          AnswerGrading.grade(userAnswer: '5, 8', question: question), isTrue);
      expect(
          AnswerGrading.grade(
              userAnswer: '5 Zehner und 8 Einer', question: question),
          isTrue);
      expect(AnswerGrading.grade(userAnswer: '58', question: question), isFalse);
    });

    test('bundles Q22 needs the three stated numbers', () {
      final question = q(all, 22);
      expect(
          AnswerGrading.grade(userAnswer: '41, 4, 1', question: question),
          isTrue);
      expect(AnswerGrading.grade(userAnswer: '41', question: question), isFalse);
    });

    test('Q21 "34." and Q27 "24." accept the typed number', () {
      expect(
          AnswerGrading.grade(userAnswer: '34', question: q(all, 21)), isTrue);
      expect(
          AnswerGrading.grade(userAnswer: '24', question: q(all, 27)), isTrue);
      expect(
          AnswerGrading.grade(userAnswer: '35', question: q(all, 27)), isFalse);
    });

    test('C3/C4 final-result items grade by the result', () {
      expect(
          AnswerGrading.grade(userAnswer: '38', question: q(all, 45)), isTrue);
      expect(
          AnswerGrading.grade(userAnswer: '95', question: q(all, 49)), isTrue);
      expect(
          AnswerGrading.grade(userAnswer: '75', question: q(all, 52)), isTrue);
      expect(
          AnswerGrading.grade(userAnswer: '63', question: q(all, 54)), isTrue);
    });

    test('multi-result C items grade the sequence', () {
      expect(
          AnswerGrading.grade(userAnswer: '43, 35', question: q(all, 48)),
          isTrue);
      expect(
          AnswerGrading.grade(userAnswer: '43, 29', question: q(all, 56)),
          isTrue);
      expect(
          AnswerGrading.grade(userAnswer: '36, 36', question: q(all, 57)),
          isTrue);
    });

    test('word problem Q58 accepts equation or result', () {
      expect(
          AnswerGrading.grade(userAnswer: '8 + 5 = 13', question: q(all, 58)),
          isTrue);
      expect(AnswerGrading.grade(userAnswer: '13', question: q(all, 58)),
          isTrue);
      expect(AnswerGrading.grade(userAnswer: '12', question: q(all, 58)),
          isFalse);
    });

    test('Q59 accepts equation typing or result 13', () {
      expect(
          AnswerGrading.grade(userAnswer: '9 + 4 = 13', question: q(all, 59)),
          isTrue);
      expect(AnswerGrading.grade(userAnswer: '13', question: q(all, 59)),
          isTrue);
      expect(AnswerGrading.grade(userAnswer: '5', question: q(all, 59)),
          isFalse);
    });

    test('decompositions Q15 accept three valid distinct pairs', () {
      final question = q(all, 15);
      expect(
          AnswerGrading.grade(
              userAnswer: '1 + 7; 2 + 6; 3 + 5', question: question),
          isTrue);
      expect(
          AnswerGrading.grade(
              userAnswer: '3 + 5; 4 + 4; 2 + 6; 1 + 7', question: question),
          isTrue);
      expect(
          AnswerGrading.grade(
              userAnswer: '1 + 7; 1 + 7; 2 + 6', question: question),
          isFalse);
      expect(
          AnswerGrading.grade(
              userAnswer: '1 + 1; 2 + 2; 3 + 3', question: question),
          isFalse);
    });

    test('pure arithmetic Q28..Q43 keep numeric grading', () {
      expect(
          AnswerGrading.grade(userAnswer: '13', question: q(all, 36)), isTrue);
      expect(
          AnswerGrading.grade(userAnswer: '12', question: q(all, 36)), isFalse);
      expect(AnswerGrading.grade(userAnswer: '0', question: q(all, 29)),
          isTrue);
    });
  });
}
