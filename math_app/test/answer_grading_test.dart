import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/diagnostic_question.dart';
import 'package:math_app/services/answer_grading.dart';
import 'package:math_app/services/diagnostic_service.dart';

DiagnosticQuestion q(List<DiagnosticQuestion> all, int listNumber) =>
    all.firstWhere((q) => q.listNumber == listNumber);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The clean-room `diagnostic_core_v1.csv` fixtures this file used to test
  // against (Q1/Q7/Q11/Q15/Q20/... sequence, labeledFields, pairRows, choice
  // modes) were retired with that file (2026-09-13) once every category had
  // full v3 coverage in `Research/diagnostic_v4_master.csv`. The generic
  // mode-mechanics coverage now lives in diagnostic_answer_widgets_test.dart
  // (synthetic fixtures for modes the master content doesn't currently use)
  // and diagnostic_answerability_test.dart (every master item is answerable).

  group('answer_grading — v4 master fixtures', () {
    final master = DiagnosticService.loadQuestionsFromCsv(
      File('Research/diagnostic_v4_master.csv').readAsStringSync(),
    );

    test('representation_bild_symbol (master LN29) is choice mode 5/6/7', () {
      final question = q(master, 29);
      expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.choice);
      expect(AnswerGrading.choiceOptionsOf(question), ['5', '6', '7']);
      expect(AnswerGrading.grade(userAnswer: '6', question: question), isTrue);
      expect(AnswerGrading.grade(userAnswer: '5', question: question), isFalse);
    });

    test(
        'representation_bild_symbol_wort (master LN30) offers the curated '
        'sechs/sechzehn/sechzig options', () {
      final question = q(master, 30);
      expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.choice);
      expect(AnswerGrading.choiceOptionsOf(question),
          ['sechzehn', 'sechs', 'sechzig']);
      expect(
          AnswerGrading.grade(userAnswer: 'sechs', question: question), isTrue);
    });

    test(
        'operation_sense_story (master LN68) grades the typed equation, '
        'not the numeric result', () {
      final question = q(master, 68);
      expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.choice);
      expect(
          AnswerGrading.grade(userAnswer: '5+4', question: question), isTrue);
      expect(
          AnswerGrading.grade(userAnswer: '9', question: question), isFalse);
    });
  });

  group('choiceOptionsOf — "Stimmt das?" ja/nein items get tap chips', () {
    final grundstrategien = DiagnosticService.loadQuestionsFromCsv(
      File('Research/diagnostic_v3_grundstrategien.csv').readAsStringSync(),
    );

    test('equation_equivalence_zr20 (correct answer "ja") offers ja/nein',
        () {
      final question = q(grundstrategien, 533);
      expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.choice);
      expect(AnswerGrading.choiceOptionsOf(question), ['ja', 'nein']);
      expect(
          AnswerGrading.grade(userAnswer: 'ja', question: question), isTrue);
      expect(AnswerGrading.grade(userAnswer: 'nein', question: question),
          isFalse);
    });

    test('equation_equivalence_zr20 (correct answer "nein") offers ja/nein',
        () {
      final question = q(grundstrategien, 534);
      expect(AnswerGrading.choiceOptionsOf(question), ['ja', 'nein']);
      expect(AnswerGrading.grade(userAnswer: 'nein', question: question),
          isTrue);
    });

    test('even_odd_recognition offers gerade/ungerade', () {
      final question = q(grundstrategien, 530);
      expect(
          AnswerGrading.choiceOptionsOf(question), ['gerade', 'ungerade']);
      expect(AnswerGrading.grade(userAnswer: 'gerade', question: question),
          isTrue);
    });
  });

  group('v3 PIKAS extras — curated choice and equation grading', () {
    final pikasExtras = DiagnosticService.loadQuestionsFromCsv(
      File('Research/diagnostic_v3_pikas_extras.csv').readAsStringSync(),
    );

    test(
        'representation_bild_symbol_wort offers the curated sechs/sechzehn/'
        'sechzig options', () {
      final question = q(pikasExtras, 703);
      expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.choice);
      expect(AnswerGrading.choiceOptionsOf(question),
          ['sechzehn', 'sechs', 'sechzig']);
      expect(
          AnswerGrading.grade(userAnswer: 'sechs', question: question),
          isTrue);
      expect(
          AnswerGrading.grade(userAnswer: 'sechzehn', question: question),
          isFalse);
    });

    test(
        'operation_sense_story grades the typed equation, not the numeric '
        'result', () {
      final question = q(pikasExtras, 707);
      expect(
          AnswerGrading.grade(userAnswer: '5+4', question: question), isTrue);
      expect(
          AnswerGrading.grade(userAnswer: '9', question: question), isFalse);
    });

    test(
        'representation_bild_symbol renders as tap buttons (5/6/7), not a '
        'number field', () {
      final question = q(pikasExtras, 702);
      expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.choice);
      expect(AnswerGrading.choiceOptionsOf(question), ['5', '6', '7']);
      expect(AnswerGrading.grade(userAnswer: '6', question: question),
          isTrue);
      expect(AnswerGrading.grade(userAnswer: '5', question: question),
          isFalse);
    });

    test(
        'operation_sense_story renders as tap buttons (5+4/5-4/5x4), not a '
        'free-text field', () {
      final question = q(pikasExtras, 707);
      expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.choice);
      expect(AnswerGrading.choiceOptionsOf(question), ['5+4', '5-4', '5x4']);
    });
  });

  group('choiceOptionsOf — magnitude estimate offers größer/kleiner', () {
    final kombinierte = DiagnosticService.loadQuestionsFromCsv(
      File('Research/diagnostic_v3_kombinierte_strategien.csv')
          .readAsStringSync(),
    );

    test('magnitude_estimate_zr100', () {
      final question = q(kombinierte, 614);
      expect(AnswerGrading.modeFor(question), DiagnosticAnswerMode.choice);
      expect(
          AnswerGrading.choiceOptionsOf(question), ['größer', 'kleiner']);
      expect(
          AnswerGrading.grade(userAnswer: 'kleiner', question: question),
          isTrue);
      expect(
          AnswerGrading.grade(userAnswer: 'größer', question: question),
          isFalse);
    });
  });
}
