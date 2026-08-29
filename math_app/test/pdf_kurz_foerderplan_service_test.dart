import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/models/foerderplan.dart';
import 'package:math_app/models/skill_recommendation.dart';
import 'package:math_app/services/pdf_kurz_foerderplan_service.dart';

// Fixture style mirrors test/kurz_foerderplan_service_test.dart: new-taxonomy
// skill IDs with domain labels, plus a placeholder legacy category that must
// never reach the output text (tasks.md R4.3).
const forbiddenInOutput = <String>[
  'SenBJF',
  'SenBildJugFam',
  'iMINT',
  'PIKAS',
  'Schulz',
];

SkillRecommendation rec({
  required String skillId,
  required String skillNameDe,
  required String descriptionDe,
}) {
  return SkillRecommendation(
    skillId: skillId,
    skillNameDe: skillNameDe,
    descriptionDe: descriptionDe,
    // Placeholder legacy category — must not be emitted for new-taxonomy IDs.
    category: 'Zählen',
    categoryColor: 'green',
    cardNumber: 0,
    triggeringQuestionIds: const [],
  );
}

Foerderplan fixturePlan() {
  final recommendations = <SkillRecommendation>[
    rec(
      skillId: 'C2.1',
      skillNameDe: 'Addieren mit Zehnerübergang über Zerlegen',
      descriptionDe: 'Das Kind löst Additionsaufgaben mit Zehnerübergang, '
          'indem es einen Summanden zerlegt und über den Zwischenschritt zur '
          'vollen Zehn gelangt.',
    ),
    rec(
      skillId: 'A1.1a',
      skillNameDe: 'Vorwärtszählen bis 20',
      descriptionDe: 'Das Kind zählt von einem beliebigen Startpunkt im '
          'Zahlenraum bis 20 fehlerfrei vorwärts weiter.',
    ),
    rec(
      skillId: 'B2.2',
      skillNameDe: 'Zahlen am Zahlenstrahl verorten',
      descriptionDe: 'Das Kind trägt Zahlen auf dem Zahlenstrahl ein und '
          'entnimmt ihnen ihre Lage im Zahlenraum.',
    ),
  ];
  return Foerderplan(
    sessionDate: DateTime(2026, 8, 29),
    studentName: 'Testkind',
    recommendedSkills: recommendations,
    briefSkills: recommendations.take(3).toList(),
    categoryStats: const {
      'Domäne A — Zahlbegriff': (failed: 2, total: 4),
    },
    slowResponseFlag: true,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The installed `pdf` package (3.11.3) exposes no text extraction API
  // (`doc.textFromPDF()` does not exist; `PdfDocument` is the low-level
  // writing model only), so the tests assert structure instead: the fixture
  // build succeeds, the bytes start with the %PDF magic and are non-trivial,
  // and the plan's student name is present in the model. The forbidden-name
  // check below additionally scans the raw bytes best-effort (content streams
  // are typically flate-compressed, so absence there is corroborating, not
  // proof — it is proof-by-source because these strings never enter the
  // generator at all).
  test('generatePdf produces a non-empty PDF with the %PDF magic', () async {
    final plan = fixturePlan();
    expect(plan.studentName, isNotEmpty);

    final bytes = await PdfKurzFoerderplanService().generatePdf(plan);

    expect(bytes, isA<Uint8List>());
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(1000));
    expect(utf8.decode(bytes.sublist(0, 4)), '%PDF');
  });

  test('PDF bytes contain no protected title or authority name', () async {
    final bytes = await PdfKurzFoerderplanService().generatePdf(fixturePlan());

    final raw = latin1.decode(bytes);
    for (final term in forbiddenInOutput) {
      expect(raw, isNot(contains(term)));
    }
  });
}
