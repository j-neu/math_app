import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/diagnostic_question.dart';
import 'package:math_app/services/diagnostic_service.dart';
import 'package:math_app/services/diagnostic_shortening.dart';

/// Weak-child / strong-child burden + coverage check for the shortened
/// ("verkürzte") diagnostic. The walk below mirrors the runtime exactly: it
/// consults ConstructGates.shouldSkip before every presentation and records
/// every presented answer into the same gate (diagnostic_screen.dart uses the
/// very same class), so this test is the spec for what a child experiences.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final csv = File('Research/diagnostic_core_v1.csv').readAsStringSync();
  final questions = DiagnosticService.loadQuestionsFromCsv(csv);

  ({int asked, int skipped, List<String> presentedConstructs,
      List<DiagnosticQuestion> presented}) walk(
    bool abbreviated,
    bool Function(DiagnosticQuestion question) profile,
  ) {
    final gates = ConstructGates(abbreviated: abbreviated);
    var asked = 0;
    var skipped = 0;
    final presented = <DiagnosticQuestion>[];
    for (final question in questions) {
      if (gates.shouldSkip(question)) {
        skipped++;
        continue;
      }
      asked++;
      presented.add(question);
      gates.noteAnswered(question, profile(question));
    }
    return (
      asked: asked,
      skipped: skipped,
      presentedConstructs: presented.map((q) => q.constructId!).toSet().toList(),
      presented: presented,
    );
  }

  final weakProfile = walk(true, (_) => false);
  final strongProfile = walk(true, (_) => true);
  final fullWeak = walk(false, (_) => false);

  test('every parsed item carries construct + difficulty metadata', () {
    for (final question in questions) {
      expect(question.constructId, isNotNull,
          reason: 'Q${question.listNumber} has no construct');
      expect(question.difficulty, isNotNull,
          reason: 'Q${question.listNumber} has no difficulty');
    }
  });

  test('full mode asks all 59 items regardless of performance', () {
    expect(fullWeak.asked, 59);
    expect(fullWeak.skipped, 0);
  });

  test('strong child is never shortened — full measurement in both modes', () {
    expect(strongProfile.asked, 59);
    expect(strongProfile.skipped, 0);
  });

  test('weak child is shortened but every construct and Domäne stays measured',
      () {
    expect(weakProfile.asked, lessThan(59));
    expect(weakProfile.skipped, greaterThan(0));
    expect(weakProfile.asked, greaterThan(20),
        reason: 'not over-shortened: ${weakProfile.asked} asked');

    final askedNumbers = weakProfile.presented.map((q) => q.listNumber).toSet();
    expect(askedNumbers.contains(1), isTrue, reason: 'Q1 always asked');
    expect(askedNumbers.contains(2), isFalse,
        reason: 'Q2 (A1.1 medium) skipped after Q1 easy failed');

    // Every construct of the bank keeps at least its easiest reachable item.
    final allConstructs = questions.map((q) => q.constructId!).toSet();
    final presentedConstructs = weakProfile.presentedConstructs.toSet();
    expect(presentedConstructs.containsAll(allConstructs), isTrue,
        reason: 'constructs lost entirely: '
            '${allConstructs.difference(presentedConstructs)}');

    // Every Domäne A–D remains represented for the weakest child.
    final presentedDomains = weakProfile.presented
        .map((q) => q.constructId![0])
        .toSet();
    expect(presentedDomains.containsAll(const {'A', 'B', 'C', 'D'}), isTrue,
        reason: 'Domänen lost: $presentedDomains');
  });

  test('same-difficulty later items are still asked (no over-shortening)', () {
    // C1.1 is Q28/Q29 (easy) then Q30/Q31 (medium). A weak child who fails the
    // easy items must still see BOTH easy items and only then skip the medium
    // ones — the "double 20 after a failed double 7" rule.
    final weak = walk(true, (_) => false);
    final asked = weak.presented.map((q) => q.listNumber).toSet();
    expect(asked.contains(28), isTrue);
    expect(asked.contains(29), isTrue);
    expect(asked.contains(30), isFalse);
    expect(asked.contains(31), isFalse);
  });

  test('a failure in one construct never skips items of another', () {
    // Fail everything in A1.1..A1.4 (Q1–Q7). Q8 (A2.1) and Q20 (B1.1) are
    // different constructs and must still be presented.
    final gates = ConstructGates(abbreviated: true);
    final asked = <int>[];
    for (final question in questions) {
      if (gates.shouldSkip(question)) continue;
      asked.add(question.listNumber);
      final wrong = question.listNumber <= 7;
      gates.noteAnswered(question, !wrong);
    }
    expect(asked, contains(8));
    expect(asked, contains(20));
  });

  test('burden stays stable — record the exact weak/strong counts', () {
    // If this number changes, the skip rule changed on purpose: update the
    // expectation with the new measured value in the test name/comment.
    expect(weakProfile.asked, 36);
    expect(weakProfile.skipped, 23);
    expect(strongProfile.asked, 59);
  });
}
