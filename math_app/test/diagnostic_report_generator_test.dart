import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/services/diagnostic_service.dart';
import 'package:math_app/services/skill_catalog.dart';

/// Regression guard for the 2026-09-13 finding: `DiagnosticReportGenerator`
/// silently drops any skill ID absent from `SkillCatalog` (`if (meta == null)
/// continue;`), so a taxonomy that doesn't cover the live diagnostic content
/// produces an empty or near-empty Förderplan with no error at all. This test
/// makes that failure loud instead of silent by asserting the invariant the
/// generator depends on directly, without needing the asset-bundle-backed
/// `DiagnosticReportGenerator.generate` itself.
void main() {
  final questions = DiagnosticService.loadQuestionsFromCsv(
    File('Research/diagnostic_v4_master.csv').readAsStringSync(),
  );
  final catalog = SkillCatalog.loadFromCsv(
    File('Research/skills_taxonomy.csv').readAsStringSync(),
  );

  test('every skill referenced by the master diagnostic has a catalog entry',
      () {
    final missing = <String>{};
    for (final question in questions) {
      for (final skillId in question.ifWrongPracticeSkills) {
        if (catalog.get(skillId) == null) missing.add(skillId);
      }
    }
    expect(missing, isEmpty,
        reason: 'these IfWrong_practice_skills IDs have no entry in '
            'Research/skills_taxonomy.csv, so any failed question referencing '
            'them is silently dropped from the Förderplan: $missing');
  });

  test('every catalog entry has a non-empty domain, title and description',
      () {
    for (final entry in catalog.all) {
      expect(entry.domain, isNotEmpty, reason: entry.skillId);
      expect(entry.constructId, isNotEmpty, reason: entry.skillId);
      expect(entry.color, isNotEmpty, reason: entry.skillId);
      expect(entry.nameDe, isNotEmpty, reason: entry.skillId);
      expect(entry.descriptionDe, isNotEmpty, reason: entry.skillId);
    }
  });
}
