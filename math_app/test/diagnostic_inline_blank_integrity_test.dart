import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/services/answer_grading.dart';
import 'package:math_app/services/diagnostic_service.dart';
import 'package:math_app/widgets/diagnostic_answer_widgets.dart';

/// InlineBlankPrompt derives both the text segments AND the number of input
/// boxes from counting "__" in the German prompt — it has no fallback if
/// that count doesn't match what AnswerGrading expects. A future CSV edit
/// that adds/removes a blank without updating CorrectAnswer in lockstep (or
/// vice versa) would silently render too few/many boxes. This content-health
/// check catches that at test time instead of in front of a child.
void main() {
  test('every inline-blank item has exactly as many "__" as expected values',
      () {
    final csv = File('Research/diagnostic_v4_master.csv').readAsStringSync();
    final master = DiagnosticService.loadQuestionsFromCsv(csv);
    final mismatches = <String>[];
    for (final q in master) {
      if (!InlineBlankPrompt.appliesTo(q)) continue;
      final blanks = q.german.split('__').length - 1;
      final mode = AnswerGrading.modeFor(q);
      final expected = mode == DiagnosticAnswerMode.sequence
          ? AnswerGrading.sequenceLength(q)
          : 1;
      if (blanks != expected) {
        mismatches.add(
            'LN${q.listNumber} (${q.ifWrongPracticeSkills}): $blanks blanks '
            'in text vs $expected expected -- "${q.german}"');
      }
    }
    if (mismatches.isNotEmpty) {
      fail('${mismatches.length} mismatch(es):\n${mismatches.join('\n')}');
    }
  });
}
