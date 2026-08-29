import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/models/foerderplan.dart';
import 'package:math_app/models/skill_recommendation.dart';
import 'package:math_app/services/kurz_foerderplan_service.dart';

// Ground truth: docs/clean-room/skills/skills_taxonomy.csv (new-taxonomy
// titles/descriptions) and docs/clean-room/01-construct-map.md (Domänen A–D).
// The generated text must not emit any legacy category name, card reference or
// protected work title (tasks.md R4.3).
const forbiddenInOutput = <String>[
  'Zählen',
  'Zahlzerlegung',
  'Stellenwerte',
  'Grundstrategien',
  'Kombinierte Strategien',
  'Karte',
  'denkenden Rechnen',
  'Erfolgreich rechnen lernen',
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
    // Placeholder legacy category — the service must not emit it into the
    // text for new-taxonomy skill IDs.
    category: 'Zählen',
    categoryColor: 'green',
    cardNumber: 0,
    triggeringQuestionIds: const [],
  );
}

Foerderplan plan({
  List<SkillRecommendation> recommendations = const [],
  Map<String, ({int failed, int total})> categoryStats = const {},
  bool slowResponseFlag = false,
}) {
  return Foerderplan(
    sessionDate: DateTime(2026, 8, 29),
    studentName: 'Testkind',
    recommendedSkills: recommendations,
    briefSkills: recommendations.take(3).toList(),
    categoryStats: categoryStats,
    slowResponseFlag: slowResponseFlag,
  );
}

void main() {
  test('groups new-taxonomy skills by Domäne A–D without legacy wording', () {
    final data = KurzFoerderplanService().generate(
      plan(recommendations: [
        rec(
          skillId: 'C2.1',
          skillNameDe: 'Addieren mit Zehnerübergang über Zerlegen',
          descriptionDe: 'Das Kind löst Additionsaufgaben mit Zehnerübergang, '
              'indem es einen Summanden zerlegt und über den Zwischenschritt zur '
              'vollen Zehn gelangt. Das Teilschrittverfahren wird dabei bewusst '
              'als Weg gewählt.',
        ),
        rec(
          skillId: 'A1.1a',
          skillNameDe: 'Vorwärtszählen bis 20',
          descriptionDe: 'Das Kind zählt von einem beliebigen Startpunkt im '
              'Zahlenraum bis 20 fehlerfrei vorwärts weiter und beendet die '
              'Zählfolge zuverlässig. Es verliert auch dann nicht den Faden, '
              'wenn es mitten in der Reihe beginnt.',
        ),
        rec(
          skillId: 'B2.2',
          skillNameDe: 'Zahlen am Zahlenstrahl verorten',
          descriptionDe: 'Das Kind trägt Zahlen auf dem Zahlenstrahl ein und '
              'entnimmt ihnen ihre Lage im Zahlenraum. Es nutzt den Strahl als '
              'strukturiertes Modell, um Abstände und Anordnungen von Zahlen '
              'abzulesen.',
        ),
        rec(
          skillId: 'D1.1',
          skillNameDe: 'Sachsituationen mathematisch erfassen',
          descriptionDe: 'Das Kind entnimmt einer Sachsituation die relevanten '
              'Zahlen und die passende Operation und stellt die Situation als '
              'Rechenaufgabe dar. Es erkennt, welcher Teil der Geschichte für '
              'die Rechnung entscheidend ist.',
        ),
      ]),
      const {},
    );

    // Rows are grouped and ordered by domain A, B, C, D.
    expect(
      data.rows.map((r) => r.category).toList(),
      [
        'Domäne A — Zahlbegriff',
        'Domäne B — Stellenwertverständnis',
        'Domäne C — Rechenstrategien',
        'Domäne D — Sachsituationen',
      ],
    );

    for (final row in data.rows) {
      final text = [row.ist, row.soll, row.lernweg].join('\n');
      for (final term in forbiddenInOutput) {
        expect(text, isNot(contains(term)));
      }
    }

    // Ist uses the neutral domain label, not the placeholder legacy category.
    final istA = data.rows.first.ist;
    expect(istA,
        contains('Im Bereich Domäne A — Zahlbegriff besteht Förderbedarf.'));
    expect(istA, contains('Beobachtete Schwierigkeiten:'));
    expect(istA, contains('- Vorwärtszählen bis 20'));
    expect(istA, isNot(contains('Im Bereich Zählen')));
  });

  test('orders skills within a domain by the recommendation order rule', () {
    final data = KurzFoerderplanService().generate(
      plan(recommendations: [
        rec(
          skillId: 'A1.1b',
          skillNameDe: 'Vorwärtszählen bis 100',
          descriptionDe: 'Das Kind setzt das Vorwärtszählen von beliebigen '
              'Startpunkten über die Zehnergrenzen hinweg bis in den '
              'Hunderterraum fort.',
        ),
        rec(
          skillId: 'A1.1a',
          skillNameDe: 'Vorwärtszählen bis 20',
          descriptionDe: 'Das Kind zählt von einem beliebigen Startpunkt im '
              'Zahlenraum bis 20 fehlerfrei vorwärts weiter.',
        ),
      ]),
      const {},
    );

    expect(data.rows, hasLength(1));
    expect(data.rows.single.category, 'Domäne A — Zahlbegriff');
    final bullets =
        data.rows.single.ist.split('\n').where((l) => l.startsWith('- ')).toList();
    expect(bullets, ['- Vorwärtszählen bis 20', '- Vorwärtszählen bis 100']);
  });

  test('falls back to the legacy category label for non-new-taxonomy IDs', () {
    final data = KurzFoerderplanService().generate(
      plan(
        recommendations: [
          rec(
            skillId: 'counting_1',
            skillNameDe: 'Zahlen bis 20 verstehen',
            descriptionDe: 'Das Kind versteht die Zahlenfolge bis 20.',
          ),
        ],
        categoryStats: {
          'Zählen': (failed: 2, total: 3),
        },
      ),
      const {},
    );

    expect(data.rows, hasLength(1));
    expect(data.rows.single.category, 'Zählen');
    expect(
      data.rows.single.ist,
      contains('Im Bereich Zählen wurden 2 von 3 Aufgaben nicht gelöst.'),
    );
    expect(data.rows.single.soll, contains('- Das Kind kann:'));
    expect(data.rows.single.lernweg, startsWith('Fördervorschläge:'));
  });

  test('keeps the slow-response note on the first row', () {
    final data = KurzFoerderplanService().generate(
      plan(
        recommendations: [
          rec(
            skillId: 'A1.1a',
            skillNameDe: 'Vorwärtszählen bis 20',
            descriptionDe: 'Das Kind zählt von einem beliebigen Startpunkt im '
                'Zahlenraum bis 20 fehlerfrei vorwärts weiter.',
          ),
        ],
        slowResponseFlag: true,
      ),
      const {},
    );

    expect(
      data.rows.single.ist,
      contains('Hinweis: Kind löst Aufgaben zählend statt denkend '
          '(verlangsamte Antwortzeiten).'),
    );
    expect(data.hasSlowResponseNote, isTrue);
  });
}
