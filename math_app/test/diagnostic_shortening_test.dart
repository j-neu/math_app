import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/diagnostic_question.dart';
import 'package:math_app/services/diagnostic_service.dart';
import 'package:math_app/services/diagnostic_shortening.dart';

/// Weak-child / strong-child burden + coverage check for the shortened
/// ("verkürzte") diagnostic, now driven by the master CSV's `SkipGroup` +
/// `Zahlenraum` columns instead of the retired core_v1 `Notes` convention.
/// The walk below mirrors the runtime exactly: it consults
/// ConstructGates.shouldSkip before every presentation and records every
/// presented answer into the same gate (diagnostic_screen.dart uses the very
/// same class), so this test is the spec for what a child experiences.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final csv = File('Research/diagnostic_v4_master.csv').readAsStringSync();
  final questions = DiagnosticService.loadQuestionsFromCsv(csv);

  DiagnosticQuestion bySkill(String skillId) =>
      questions.firstWhere((q) => q.ifWrongPracticeSkills.contains(skillId));

  ({int asked, int skipped, List<DiagnosticQuestion> presented}) walk(
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
    return (asked: asked, skipped: skipped, presented: presented);
  }

  test('every parsed item carries construct + difficulty metadata', () {
    for (final question in questions) {
      expect(question.constructId, isNotNull,
          reason: 'Q${question.listNumber} has no construct');
      expect(question.difficulty, isNotNull,
          reason: 'Q${question.listNumber} has no difficulty');
    }
  });

  test('full mode asks every item regardless of performance', () {
    final full = walk(false, (_) => false);
    expect(full.asked, questions.length);
    expect(full.skipped, 0);
  });

  test('strong child is never shortened — full measurement in both modes',
      () {
    final strong = walk(true, (_) => true);
    expect(strong.asked, questions.length);
    expect(strong.skipped, 0);
  });

  group('per-construct ladder (fail an easy level, skip the harder ones)',
      () {
    test('failing quantify_count_zr10 skips quantify_count_zr20', () {
      final gates = ConstructGates(abbreviated: true);
      gates.noteAnswered(bySkill('quantify_count_zr10'), false);
      expect(gates.shouldSkip(bySkill('quantify_count_zr20')), isTrue);
    });

    test('failing complete_to_10 skips complete_to_20 and complete_to_100',
        () {
      final gates = ConstructGates(abbreviated: true);
      gates.noteAnswered(bySkill('complete_to_10'), false);
      expect(gates.shouldSkip(bySkill('complete_to_20')), isTrue);
      expect(gates.shouldSkip(bySkill('complete_to_100')), isTrue);
    });

    test('same-difficulty siblings are still asked after a fail', () {
      final gates = ConstructGates(abbreviated: true);
      // complete_to_10 has three ZR10 items (25/26/27); failing the first
      // must not skip the other two — only strictly harder levels are gated.
      final tens = questions
          .where((q) => q.ifWrongPracticeSkills.contains('complete_to_10'))
          .toList();
      expect(tens.length, 3);
      gates.noteAnswered(tens.first, false);
      for (final q in tens) {
        expect(gates.shouldSkip(q), isFalse,
            reason: 'ListNumber ${q.listNumber} is same difficulty, must '
                'still be asked');
      }
    });

    test('a failure in one construct never skips an unrelated construct', () {
      final gates = ConstructGates(abbreviated: true);
      gates.noteAnswered(bySkill('quantify_count_zr10'), false);
      expect(gates.shouldSkip(bySkill('ordinal_1')), isFalse);
      expect(gates.shouldSkip(bySkill('double_zr10')), isFalse);
    });
  });

  group('block rules (failing one construct fully skips a dependent one)',
      () {
    test('failing count_forward anywhere blocks all step-counting', () {
      final gates = ConstructGates(abbreviated: true);
      gates.noteAnswered(bySkill('count_forward_zr20'), false);
      for (final skill in [
        'skip2_forward_zr20',
        'skip2_forward_zr100',
        'skip2_backward_zr20',
        'skip2_backward_zr100',
        'skip5_forward_zr100',
        'skip5_backward_zr100',
        'skip10_forward_zr100',
        'skip10_backward_zr100',
      ]) {
        expect(gates.shouldSkip(bySkill(skill)), isTrue, reason: skill);
      }
    });

    test('failing double or halve blocks the near-double derive items', () {
      final gatesDouble = ConstructGates(abbreviated: true);
      gatesDouble.noteAnswered(bySkill('double_2digit_with_carry'), false);
      expect(gatesDouble.shouldSkip(bySkill('derive_via_near_double_add')),
          isTrue);
      expect(gatesDouble.shouldSkip(bySkill('derive_via_near_double_sub')),
          isTrue);
      // Unrelated derive-via strategies are unaffected.
      expect(gatesDouble.shouldSkip(bySkill('derive_via_5_add')), isFalse);

      final gatesHalve = ConstructGates(abbreviated: true);
      gatesHalve.noteAnswered(bySkill('halve_zr10'), false);
      expect(
          gatesHalve.shouldSkip(bySkill('derive_via_near_double_sub')),
          isTrue);
    });

    test('failing complete_to blocks the derive-via-10 items', () {
      final gates = ConstructGates(abbreviated: true);
      gates.noteAnswered(bySkill('complete_to_20'), false);
      expect(gates.shouldSkip(bySkill('derive_via_10_add_minus1')), isTrue);
      expect(gates.shouldSkip(bySkill('derive_via_10_add_plus1')), isTrue);
      expect(gates.shouldSkip(bySkill('derive_via_10_sub')), isTrue);
    });
  });

  group('mirror rule (count_forward failure gates count_backward)', () {
    test('failing forward at ZR20 skips backward at ZR20 and ZR100', () {
      final gates = ConstructGates(abbreviated: true);
      gates.noteAnswered(bySkill('count_forward_zr20'), false);
      expect(gates.shouldSkip(bySkill('count_backward_zr20')), isTrue);
      expect(gates.shouldSkip(bySkill('count_backward_zr100')), isTrue);
      // Forward's own ladder also gates its own harder level.
      expect(gates.shouldSkip(bySkill('count_forward_zr100')), isTrue);
    });

    test(
        'passing forward at ZR20 but failing at ZR100 tests backward ZR20 '
        'normally, then gates backward ZR100', () {
      final gates = ConstructGates(abbreviated: true);
      gates.noteAnswered(bySkill('count_forward_zr20'), true);
      gates.noteAnswered(bySkill('count_forward_zr100'), false);
      expect(gates.shouldSkip(bySkill('count_backward_zr20')), isFalse);
      expect(gates.shouldSkip(bySkill('count_backward_zr100')), isTrue);
    });

    test('backward failing on its own still gates its own harder level', () {
      final gates = ConstructGates(abbreviated: true);
      gates.noteAnswered(bySkill('count_forward_zr20'), true);
      gates.noteAnswered(bySkill('count_backward_zr20'), false);
      expect(gates.shouldSkip(bySkill('count_backward_zr100')), isTrue);
      // Forward is unaffected by backward's failure — the dependency is
      // one-directional.
      expect(gates.shouldSkip(bySkill('count_forward_zr100')), isFalse);
    });
  });

  test('a weak child is shortened but the burden stays bounded', () {
    final weak = walk(true, (_) => false);
    expect(weak.asked, lessThan(questions.length));
    expect(weak.skipped, greaterThan(0));
    // Not over-shortened: every construct family keeps at least its easiest
    // reachable item, so the weakest child still sees a broad sample.
    expect(weak.asked, greaterThan(30),
        reason: 'not over-shortened: ${weak.asked} asked');
  });
}
