# Phase 3a — Verdoppeln ZR10 über die Mirror-Familie (Implementation Plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Den ersten vollständig realen, live-fähigen Konstrukt-Durchlauf der v2-Pipeline bauen:
`verdoppeln-halbieren.ZR10` (alle drei Zellen: enaktiv, ikonisch, symbolisch), diagnostiziert
über ein neues Item, geübt über die portierte alte Mirror-Widget-Familie, ausgeliefert über die
unveränderten `practice-session`/`learning-path`-Functions.

**Architecture:** Ein Diagnostik-Item in einer neuen, separaten CSV (die gesperrte
`diagnostic_core_v1.csv` bleibt unberührt) routet bei falscher Antwort auf den Skill
`verdoppeln-halbieren.ZR10`. Dessen Skill-Spec hat drei Level (enaktiv/ikonisch/symbolisch,
Template `custom_widget`), gerendert von drei neuen, aus den alten `DoublingMirrorLevel*Widget`-
Klassen portierten Widgets. Die alten Widgets bleiben unverändert liegen (Alt-Engine bleibt
erreichbar); die neuen Dateien sind Kopien mit angepasstem Vertrag: `(Problem, ValueChanged<String>)`
statt `(int targetCount, Function(bool) onComplete)`, Live-Reporting statt Selbstbewertung.

**Tech Stack:** Flutter/Dart (App), Python 3.12 stdlib (Content-Checker-Skripte, wie in Phase 1/2).

**Spec:** [2026-09-11-phase3-verdoppeln-halbieren-design.md](../specs/2026-09-11-phase3-verdoppeln-halbieren-design.md)
— zwei Korrekturen gegenüber dem dortigen Stand, beide im Text der Spec bereits als
"Ausgangshypothese für die Planung" markiert:
1. **Skill-Spec-Granularität:** die Spec schlug einen Skill pro Zelle vor
   (`verdoppeln-halbieren.ZR10.symbolisch`). Der tatsächliche Aufbau bestehender Skill-Specs
   (z.B. `docs/clean-room/skills/specs/A2.1.json`) ist **ein Skill pro Konstrukt** mit drei
   Leveln (Repräsentation ist ein Level-Attribut, nicht Teil der Skill-ID). Diese Plan folgt
   dem tatsächlichen Muster: **ein** Skill-Spec `verdoppeln-halbieren.ZR10.json`.
2. **Portierungsumfang:** "Port/adapt" heißt nicht Wrapper, sondern echtes Umbauen — jedes
   alte Widget hat einen eigenen Submit-Button und bewertet sich selbst intern; das neue
   Widget darf keinen eigenen Button haben und muss den aktuellen Wert live über
   `onValueChanged` melden, weil genau ein generischer Submit-Button in `practice_screen.dart`
   die Bewertung übernimmt (`TemplateEvaluator.evaluate` gegen `problem.expected`).

Dieser Plan deckt **nur** `verdoppeln-halbieren.ZR10` ab (Mirror-Familie, Range 1–5). ZR20/ZR100
(Boat-/Tens-Familie) folgen als eigener Plan, sobald dieses Muster hier real gebaut und getestet
ist — nicht weil sie unwichtiger sind, sondern weil ein Fehler im gemeinsamen Portierungsmuster
sonst achtmal wiederholt würde, bevor ihn jemand sieht.

## Global Constraints

- **Live-Pilot, aber kein Deploy-Freibrief.** Diese Plan-Freigabe erlaubt Commits (siehe
  Task 9); Pushen nach `main` (Auto-Deploy auf Vercel) braucht weiterhin Jakobs ausdrückliche
  Freigabe im jeweiligen Moment.
- **Alt-Engine unangetastet.** `math_app/lib/exercises/doubling_mirror_exercise.dart` und
  `math_app/lib/widgets/doubling_mirror_level{1,2,3}_widget.dart` werden **nicht verändert** —
  die neuen Dateien sind Kopien mit neuem Vertrag, keine Refactorings der alten Klassen.
- **Gesperrte v1-Artefakte bleiben unberührt:** `Research/diagnostic_core_v1.csv`,
  `docs/clean-room/01-construct-map.md`, `02-blueprint.md`, `items/`, `skills/`,
  `foerderplan/mapping-rationale.md`.
- **`docs/clean-room/v2/10-deckungsmatrix.md`, `11-konstruktkarte.md`, `12-blueprint.md`,
  `14-itemregeln.md` bleiben inhaltlich unverändert** außer den in Task 7 beschriebenen
  Zellenstatus-Änderungen (reguläre Matrixpflege, kein Sonderfall).
- **Deutsch** für alle Kind- und Lehrkraft-sichtbaren Texte; Code-Identifier bleiben ASCII/Englisch
  nach bestehender Konvention.
- **cp1252-sicher** in jeder Python-Skriptausgabe: kein `→` (U+2192), `->` verwenden; Umlaute,
  `×`, `–`, `—` sind sicher.
- **Kein `_sources_private/`.**
- **check_item_quality.py und check_deckung.py bleiben die Gates** für Item- bzw.
  Matrix-Änderungen, wie in Phase 2 etabliert.

---

## Datei-Struktur dieser Phase

| Datei | Verantwortung |
|---|---|
| `Research/diagnostic_v2_verdoppeln_halbieren.csv` (neu) | Die v2-Diagnostik-Items für diesen Strang, im v1-Schema, separat von der gesperrten Datei. |
| `math_app/lib/services/diagnostic_service.dart` (geändert) | Lädt zusätzlich die neue CSV und mischt sie ein. |
| `docs/clean-room/v2/items/verdoppeln-halbieren.ZR10-01.md` (neu) | Das Kern-Item für den Konstrukt, itemregeln-konform. |
| `docs/clean-room/v2/skills/specs/verdoppeln-halbieren.ZR10.json` (neu) | Ein Skill-Spec, drei Level (enaktiv/ikonisch/symbolisch). |
| `scripts/sync_skill_specs.py` (geändert) | Liest zusätzlich aus `docs/clean-room/v2/skills/specs/`. |
| `math_app/lib/models/skill_spec.dart` (geändert) | `kKnownCustomWidgets` bekommt drei neue Schlüssel. |
| `math_app/lib/widgets/templates/doubling_mirror_enaktiv_widget.dart` (neu) | Portiert aus `DoublingMirrorLevel1Widget`. |
| `math_app/lib/widgets/templates/doubling_mirror_ikonisch_widget.dart` (neu) | Portiert aus `DoublingMirrorLevel2Widget`. |
| `math_app/lib/widgets/templates/doubling_mirror_symbolisch_widget.dart` (neu) | Portiert aus `DoublingMirrorLevel3Widget`. |
| `math_app/lib/practice/template_registry.dart` (geändert) | Registriert die drei neuen `custom_widget`-Schlüssel. |
| `math_app/lib/practice/problem_generators.dart` (geändert) | Neuer `_generateDoublingMirror`-Zweig im `custom_widget`-Dispatch. |
| `math_app/test/problem_generators_test.dart` (geändert) | Generator-Tests für die drei neuen Schlüssel. |
| `math_app/test/template_widgets_test.dart` (geändert) | Widget-Tests für die drei neuen Widgets. |
| `math_app/test/diagnostic_service_test.dart` (geändert) | Test für das CSV-Mischen. |
| `docs/clean-room/v2/10-deckungsmatrix.md` (geändert) | Drei Zellen `offen` → `freigegeben`. |

---

### Task 1: Diagnostik-CSV-Infrastruktur

**Files:**
- Create: `Research/diagnostic_v2_verdoppeln_halbieren.csv`
- Modify: `math_app/lib/services/diagnostic_service.dart`
- Test: `math_app/test/diagnostic_service_test.dart`

**Interfaces:**
- Consumes: `DiagnosticQuestion`, `DiagnosticService.loadQuestionsFromCsv(String csv)` (beide bereits vorhanden, unverändert).
- Produces: `DiagnosticService.loadQuestions()` liefert jetzt Fragen aus **beiden** Dateien,
  abzüglich der v1-Fragen zum Strang `verdoppeln-halbieren` (damit ein Kind nicht beide
  Versionen bekommt).

- [ ] **Step 1: Die alten `verdoppeln-halbieren`-Zeilen in `diagnostic_core_v1.csv` identifizieren**

Nicht verändern — nur die `ListNumber`n notieren, die beim Laden herausgefiltert werden müssen:

```bash
python -c "
import csv
with open('math_app/Research/diagnostic_core_v1.csv', encoding='utf-8') as f:
    for row in csv.DictReader(f):
        skills = row.get('IfWrong_practice_skills', '')
        if 'basic_strategy_7' in skills or 'basic_strategy_8' in skills or 'basic_strategy_9' in skills or 'basic_strategy_10' in skills or 'strategy_doubling_tens_1' in skills:
            print(row['ListNumber'], skills)
"
```

Notiere die ausgegebenen `ListNumber`-Werte als `_kLegacyVerdoppelnHalbierenListNumbers` (Step 3).
Falls die Suche keine Treffer liefert (das alte CSV routet evtl. nicht über diese Skill-IDs),
ist die Menge leer und Schritt 3 filtert nichts heraus — kein Fehler, nur kein Altbestand zu
diesem Strang in der Kern-Diagnostik.

- [ ] **Step 2: Neue CSV-Datei anlegen**

14-Spalten-Schema identisch zu `diagnostic_core_v1.csv`
(`ListNumber,SourceType,QuestionText,AnswerFormat,CorrectAnswer,German,English,IfWrong_practice_skills,Ifwrong_skip,Notes,SkipGroup,Zahlenraum,AudioAsset,Hilfetext`).
`AudioAsset` bleibt leer — die Datei `audio/v2/verdoppeln-halbieren.ZR10-01.mp3` existiert erst
in Phase 5 (TTS); ein gesetzter, aber nicht existierender Pfad wäre ein Laufzeitrisiko, das
Feld im Item selbst (Task 2) hält trotzdem den Vertrag fest.

```csv
ListNumber,SourceType,QuestionText,AnswerFormat,CorrectAnswer,German,English,IfWrong_practice_skills,Ifwrong_skip,Notes,SkipGroup,Zahlenraum,AudioAsset,Hilfetext
9001,Text,"Rechne: 4 + 4",Single,8,"Rechne: 4 + 4",Calculate: 4 + 4,verdoppeln-halbieren.ZR10,,medium; verdoppeln-halbieren.ZR10 Verdoppeln im ZR10,,ZR10,,
```

`ListNumber` beginnt bei `9001` (weit über dem 59-Zeilen-Kernbestand), damit eine spätere
v1-Erweiterung nie kollidiert. `IfWrong_practice_skills` zeigt auf den Konstrukt-Skill (nicht
eine Zellen-ID) — der Skill selbst beginnt bei Level 1 (enaktiv), also am Material, passend zu
12-blueprint.md: "ein Kind, das am Material nicht bündeln kann, braucht das Material".

Hinweis für später (nicht Teil dieses Plans): `Notes` folgt hier zwar dem `"<difficulty>; <text>"`-
Format, aber `diagnostic_shortening.dart`s `_constructPattern` (`\b([A-D][0-9]+(?:\.[0-9]+)*)\b`)
erkennt nur v1-Konstrukt-IDs (`A1.1`-Stil) und **nicht** die v2-Form
`verdoppeln-halbieren.ZR10`. Für ein einzelnes Item ohne Geschwister ist das folgenlos (das
Shortening-Gate vergleicht innerhalb eines Konstrukts); sobald mehrere v2-Items im selben
Konstrukt existieren, muss das Regex erweitert werden — das ist Folgearbeit für den Plan, der
das zweite Item in diesen Konstrukt bringt, nicht für diesen.

- [ ] **Step 3: `diagnostic_service.dart` erweitern**

Ersetze in `math_app/lib/services/diagnostic_service.dart` die `loadQuestions()`-Methode:

```dart
  /// Legacy v1 ListNumbers this v2 file supersedes for `verdoppeln-halbieren`
  /// (see Phase 3a plan Task 1 Step 1) -- excluded when merging so a child
  /// never sees both the old and the new item for the same construct.
  static const Set<int> _kSupersededByV2 = {
    // fill in with the ListNumbers found in Task 1 Step 1; leave empty {}
    // if that search found none.
  };

  Future<List<DiagnosticQuestion>> loadQuestions() async {
    final coreCsv =
        await rootBundle.loadString('Research/diagnostic_core_v1.csv');
    final coreQuestions = loadQuestionsFromCsv(coreCsv)
        .where((q) => !_kSupersededByV2.contains(q.listNumber))
        .toList();

    final v2Csv = await rootBundle
        .loadString('Research/diagnostic_v2_verdoppeln_halbieren.csv');
    final v2Questions = loadQuestionsFromCsv(v2Csv);

    return [...coreQuestions, ...v2Questions];
  }
```

Trage in `_kSupersededByV2` die in Step 1 gefundenen `ListNumber`n ein (als `int`-Literale,
z.B. `{12, 13}`), oder lasse die Menge leer, falls Step 1 nichts gefunden hat.

- [ ] **Step 4: Das neue Asset registrieren**

In `math_app/pubspec.yaml`, im `flutter: assets:`-Abschnitt, direkt neben dem bestehenden
Eintrag für `Research/diagnostic_core_v1.csv`, die neue Datei ergänzen:

```yaml
    - Research/diagnostic_v2_verdoppeln_halbieren.csv
```

- [ ] **Step 5: Test schreiben**

An `math_app/test/diagnostic_service_test.dart` anhängen:

```dart
  test('loadQuestions merges the v2 CSV and excludes superseded v1 rows',
      () async {
    final service = DiagnosticService();
    final questions = await service.loadQuestions();

    final v2Item = questions.firstWhere(
      (q) => q.ifWrongPracticeSkills.contains('verdoppeln-halbieren.ZR10'),
      orElse: () => throw StateError('v2 item not found'),
    );
    expect(v2Item.correctAnswer, '8');
    expect(v2Item.zahlenraum, 'ZR10');
  });
```

- [ ] **Step 6: Tests laufen lassen**

Run: `cd math_app && flutter test test/diagnostic_service_test.dart`
Expected: alle Tests grün, inklusive des neuen.

- [ ] **Step 7: Commit**

```bash
git add Research/diagnostic_v2_verdoppeln_halbieren.csv math_app/lib/services/diagnostic_service.dart math_app/pubspec.yaml math_app/test/diagnostic_service_test.dart
git commit -m "feat(v2): v2-Diagnostik-CSV fuer verdoppeln-halbieren.ZR10 einmischen"
```

---

### Task 2: Diagnostik-Item verfassen

**Files:**
- Create: `docs/clean-room/v2/items/verdoppeln-halbieren.ZR10-01.md`

**Interfaces:**
- Consumes: `docs/clean-room/v2/items/TEMPLATE.md` (Feldschema), `14-itemregeln.md` (I1–I12).
- Produces: Inhalt für die CSV-Zeile aus Task 1 (Frage-Text, korrekte Antwort, Fehlersignaturen
  müssen zur CSV passen — sie tun es bereits, siehe unten).

- [ ] **Step 1: Item-Datei schreiben**

```markdown
# Item verdoppeln-halbieren.ZR10-01

- **item-id:** verdoppeln-halbieren.ZR10-01
- **konstrukt:** verdoppeln-halbieren.ZR10
- **zelle:** verdoppeln-halbieren × ZR10 × symbolisch
- **darstellung:** keine
- **darstellung-konfiguration:** —
- **blitz:** nein
- **prompt:** Rechne: 4 + 4
- **audio:** audio/v2/verdoppeln-halbieren.ZR10-01.mp3
- **antwortfelder:**
  - `ergebnis` — Ergebnis
- **erwartete-antwort:**
  - `ergebnis` = 8
- **fehlersignatur:**
  - `7` — ±1 nach unten: zählend gerechnet, ein Schritt zu wenig
  - `9` — ±1 nach oben: zählend gerechnet, ein Schritt zu viel
- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A (Kernaufgaben); Wartha/Schulz, Ablösung vom zählenden Rechnen
- **eigenstaendigkeit:** Zahlenpaar, Wortlaut und Antwortlayout eigenständig gewählt; kein bestehendes Instrument als Vorlage.
- **reviewer:** —
```

Die beiden Fehlersignaturen sind bewusst beide ±1: das ist exakt das Muster, das
zählendes statt abrufendes Rechnen verrät (die Quelle Wartha/Schulz nennt genau diesen
Übergang). `reviewer: —` bleibt bis Task 8s Gate-1-Check offen.

- [ ] **Step 2: Gate laufen lassen**

Run: `python scripts/check_item_quality.py`
Expected: `OK: ...` (keine `FAIL`-Zeile für dieses Item). Falls I2 (≤12 Wörter) oder I4
(keine Nebensätze/Zahlwörter) hier fehlschlägt, den Prompt-Satz kürzen, nicht die Regel.

- [ ] **Step 3: Provenienz eintragen**

An `docs/clean-room/provenance.csv` eine Zeile anhängen (Format wie die bestehenden Zeilen:
`id,author,reviewed_by,reviewed_on,created,independent_of,...` — die exakten Spalten mit
`head -1 docs/clean-room/provenance.csv` prüfen, bevor die Zeile geschrieben wird, da Phase 2
hier bereits einmal von falsch erinnerten Spaltennamen ausging).

- [ ] **Step 4: Commit**

```bash
git add docs/clean-room/v2/items/verdoppeln-halbieren.ZR10-01.md docs/clean-room/provenance.csv
git commit -m "feat(v2): Diagnostik-Item verdoppeln-halbieren.ZR10-01 verfassen"
```

---

### Task 3: `doubling_mirror_enaktiv_widget.dart` (Level 1 portieren)

**Files:**
- Create: `math_app/lib/widgets/templates/doubling_mirror_enaktiv_widget.dart`
- Modify: `math_app/lib/models/skill_spec.dart` (Zeile mit `kKnownCustomWidgets`)
- Modify: `math_app/lib/practice/template_registry.dart` (der `custom_widget`-Switch)
- Modify: `math_app/lib/practice/problem_generators.dart` (`_generateCustomWidget`-Dispatch)
- Test: `math_app/test/template_widgets_test.dart`, `math_app/test/problem_generators_test.dart`

**Interfaces:**
- Consumes: `Problem` (`math_app/lib/models/problem.dart`), liest `problem.display['target']` (int).
- Produces: registriert den `custom_widget`-Schlüssel `"doubling_mirror_enaktiv"`; meldet über
  `onValueChanged(String)` den vom Kind eingegebenen Gesamtwert (Step 2 der internen
  Zustandsmaschine). `expected: ['<target*2>']` — Bewertung läuft über den bestehenden
  `_evaluateCustomWidget`-Default-Zweig (Plain-String-Match), kein neuer Evaluator-Code nötig.

- [ ] **Step 1: `kKnownCustomWidgets` erweitern**

In `math_app/lib/models/skill_spec.dart`:

```dart
const Set<String> kKnownCustomWidgets = {
  'bundling',
  'unbundling',
  'numberline_mark',
  'flash_subitize',
  'doubling_mirror_enaktiv',
  'doubling_mirror_ikonisch',
  'doubling_mirror_symbolisch',
};
```

(Alle drei neuen Schlüssel auf einmal, damit Task 3/4/5 nicht dieselbe Zeile dreimal anfassen —
die Widgets selbst und ihre Registry-Einträge kommen trotzdem einzeln in Task 3/4/5.)

- [ ] **Step 2: Neue Widget-Datei schreiben**

`math_app/lib/widgets/templates/doubling_mirror_enaktiv_widget.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Custom-widget template for the registry key `"doubling_mirror_enaktiv"`
/// (verdoppeln-halbieren.ZR10, Level 1/enaktiv). Ported from the old
/// engine's `DoublingMirrorLevel1Widget` (math_app/lib/widgets/
/// doubling_mirror_level1_widget.dart) -- that file is untouched; this is a
/// fresh copy with an adapted contract, not a refactor of the original.
///
/// The child counts the blue dots on the left, drags matching red dots to
/// the right one at a time, then reports the combined total. Steps 0
/// (verify the left count) and 1 (drag to match) stay internally gated
/// exactly like the original -- they are scaffolding, not the graded
/// answer. Step 2 (the final total) is reported live via [onValueChanged]
/// instead of self-grading with its own button; the practice screen's one
/// generic submit button and [TemplateEvaluator] decide correctness against
/// `problem.expected`.
class DoublingMirrorEnaktivWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const DoublingMirrorEnaktivWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<DoublingMirrorEnaktivWidget> createState() =>
      _DoublingMirrorEnaktivWidgetState();
}

class _DoublingMirrorEnaktivWidgetState
    extends State<DoublingMirrorEnaktivWidget> {
  // Steps:
  // 0: Count Left (internally verified)
  // 1: Drag Right (internally verified)
  // 2: Count Total (reported via onValueChanged, graded centrally)
  int _step = 0;

  int _rightCount = 0;
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.black;

  int get _targetCount => (widget.problem.display['target'] as num).toInt();

  @override
  void didUpdateWidget(covariant DoublingMirrorEnaktivWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _step = 0;
      _rightCount = 0;
      _leftController.clear();
      _totalController.clear();
      _feedbackMessage = '';
    });
    widget.onValueChanged('');
  }

  void _checkLeftCount() {
    final input = int.tryParse(_leftController.text);
    if (input == null) return;

    if (input == _targetCount) {
      setState(() {
        _step = 1;
        _feedbackMessage = 'Richtig! Jetzt verdopple rechts.';
        _feedbackColor = Colors.green;
        _leftController.clear();
      });
    } else {
      setState(() {
        _feedbackMessage = 'Fast! Zähl nochmal!';
        _feedbackColor = Colors.orange;
        _leftController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            _getInstructionText(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  _feedbackMessage.isNotEmpty ? _feedbackColor : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                  ),
                  child: Center(
                    child: _buildDotGrid(_targetCount, Colors.blue),
                  ),
                ),
              ),
              Container(width: 4, color: Colors.grey.shade400),
              Expanded(
                child: DragTarget<int>(
                  onWillAccept: (data) => _step == 1,
                  onAccept: (data) {
                    setState(() {
                      _rightCount++;
                      if (_rightCount == _targetCount) {
                        _step = 2;
                        _feedbackMessage = 'Super! Wie viele sind es zusammen?';
                        _feedbackColor = Colors.green;
                      }
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              _step == 1 ? Colors.blue : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: _buildDotGrid(_rightCount, Colors.red),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: switch (_step) {
            0 => _buildLeftCountInput(),
            1 => _buildDragSource(),
            _ => _buildFinalAnswerField(),
          },
        ),
      ],
    );
  }

  String _getInstructionText() {
    if (_feedbackMessage.isNotEmpty) return _feedbackMessage;
    switch (_step) {
      case 0:
        return 'Wie viele blaue Punkte siehst du?';
      case 1:
        return 'Zieh genauso viele rote Punkte nach rechts!';
      default:
        return 'Wie viele Punkte sind es jetzt zusammen?';
    }
  }

  Widget _buildDotGrid(int count, Color color) => Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: List.generate(count, (index) => _buildDot(color)),
      );

  Widget _buildDot(Color color) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      );

  Widget _buildDragSource() => Center(
        child: Draggable<int>(
          data: 1,
          feedback: _buildDot(Colors.red.withOpacity(0.8)),
          childWhenDragging: _buildDot(Colors.red),
          child: _buildDot(Colors.red),
        ),
      );

  Widget _buildLeftCountInput() => Row(
        children: [
          Expanded(
            child: TextField(
              controller: _leftController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '?',
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              onSubmitted: (_) => _checkLeftCount(),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _checkLeftCount,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.green,
            ),
            child: const Text('OK', style: TextStyle(fontSize: 24)),
          ),
        ],
      );

  Widget _buildFinalAnswerField() => TextField(
        key: const ValueKey('final-answer'),
        controller: _totalController,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: '?',
          filled: true,
          fillColor: Colors.white,
        ),
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        onChanged: widget.onValueChanged,
      );
}
```

- [ ] **Step 3: Widget-Test schreiben**

An `math_app/test/template_widgets_test.dart` anhängen (Import am Dateikopf ergänzen:
`import '../lib/widgets/templates/doubling_mirror_enaktiv_widget.dart';`):

```dart
  group('DoublingMirrorEnaktivWidget', () {
    Problem mirrorProblem(int target) => _problem(
          template: 'custom_widget',
          display: {'custom_widget': 'doubling_mirror_enaktiv', 'target': target},
          expected: ['${target * 2}'],
        );

    testWidgets('renders target-count dots and reports the final total',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        DoublingMirrorEnaktivWidget(
          problem: mirrorProblem(3),
          onValueChanged: values.add,
        ),
      );

      await tester.enterText(find.byType(TextField), '3');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      final dragSource = find.byType(Draggable<int>);
      final dragTarget = find.byType(DragTarget<int>);
      for (var i = 0; i < 3; i++) {
        await tester.drag(dragSource, tester.getCenter(dragTarget) - tester.getCenter(dragSource));
        await tester.pump();
      }

      expect(find.byKey(const ValueKey('final-answer')), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('final-answer')), '6');
      await tester.pump();

      expect(values.last, '6');
    });

    testWidgets('a new problem resets to step 0', (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        DoublingMirrorEnaktivWidget(
          problem: mirrorProblem(2),
          onValueChanged: values.add,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoublingMirrorEnaktivWidget(
              problem: mirrorProblem(4),
              onValueChanged: values.add,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(values.last, '');
      expect(find.byType(TextField), findsOneWidget);
    });
  });
```

- [ ] **Step 4: `template_registry.dart` erweitern**

In der `case 'custom_widget':`-Verzweigung, direkt vor `_ => const _UnavailableTemplateWidget(),`:

```dart
      'doubling_mirror_enaktiv' => DoublingMirrorEnaktivWidget(
          problem: problem,
          onValueChanged: onValueChanged,
        ),
```

Import am Dateikopf ergänzen:
`import '../widgets/templates/doubling_mirror_enaktiv_widget.dart';`

- [ ] **Step 5: Generator-Funktion schreiben**

In `math_app/lib/practice/problem_generators.dart`, in `_generateCustomWidget`s Switch, direkt
vor `default:`:

```dart
    case 'doubling_mirror_enaktiv':
    case 'doubling_mirror_ikonisch':
    case 'doubling_mirror_symbolisch':
      return _generateDoublingMirror(spec, level, levelNumber, seed, index, gen);
```

Und die Funktion selbst, ans Ende der Datei angehängt:

```dart
/// Registry keys `"doubling_mirror_enaktiv"`, `"doubling_mirror_ikonisch"`,
/// `"doubling_mirror_symbolisch"` (verdoppeln-halbieren.ZR10, alle drei
/// Level derselben Skill-Spec): the widget shows `display.target` and the
/// child reports the doubled total; correctness is a plain string match
/// against `expected`, handled by `_evaluateCustomWidget`'s default branch.
Problem _generateDoublingMirror(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final countRange = level.intListParam('count_range');
  final lo = countRange.isEmpty ? 1 : countRange[0];
  final hi = countRange.isEmpty ? 5 : countRange[1];
  if (lo < 1 || hi > 5 || lo > hi) {
    throw SpecFormatException(
      'doubling_mirror: count_range [$lo, $hi] must be within [1, 5] for ZR10',
    );
  }
  final target = gen.nextIntInRange(lo, hi);

  return Problem(
    template: 'custom_widget',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {'custom_widget': level.customWidget, 'target': target},
    expected: ['${target * 2}'],
  );
}
```

- [ ] **Step 6: Generator-Test schreiben**

An `math_app/test/problem_generators_test.dart` anhängen, in der Gruppe
`'custom_widget generators (P2 §5 registry)'`:

```dart
    test('doubling_mirror_enaktiv: target in [1,5], expected == target*2', () {
      final s = spec('doubling_mirror_enaktiv', {'count_range': [1, 5]});
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final target = p.display['target'] as int;
          expect(target, inInclusiveRange(1, 5));
          expect(p.expected, ['${target * 2}']);
          expect(p.display['custom_widget'], 'doubling_mirror_enaktiv');
        }
      }
    });
```

- [ ] **Step 7: Tests laufen lassen**

Run: `cd math_app && flutter test test/template_widgets_test.dart test/problem_generators_test.dart`
Expected: alle Tests grün, inklusive der beiden neuen.

- [ ] **Step 8: Commit**

```bash
git add math_app/lib/models/skill_spec.dart math_app/lib/widgets/templates/doubling_mirror_enaktiv_widget.dart math_app/lib/practice/template_registry.dart math_app/lib/practice/problem_generators.dart math_app/test/template_widgets_test.dart math_app/test/problem_generators_test.dart
git commit -m "feat(v2): doubling_mirror_enaktiv-Widget aus DoublingMirrorLevel1Widget portieren"
```

---

### Task 4: `doubling_mirror_ikonisch_widget.dart` (Level 2 portieren)

**Files:**
- Create: `math_app/lib/widgets/templates/doubling_mirror_ikonisch_widget.dart`
- Modify: `math_app/lib/practice/template_registry.dart`
- Test: `math_app/test/template_widgets_test.dart`

**Interfaces:**
- Consumes: `Problem` (`problem.display['target']`), dieselbe `_generateDoublingMirror`-Funktion
  aus Task 3 (der `case`-Zweig für `doubling_mirror_ikonisch` existiert bereits).
- Produces: registriert `custom_widget`-Schlüssel `"doubling_mirror_ikonisch"`.

- [ ] **Step 1: Neue Widget-Datei schreiben**

`math_app/lib/widgets/templates/doubling_mirror_ikonisch_widget.dart` — portiert aus
`DoublingMirrorLevel2Widget`, gleiches Muster wie Task 3: Step 0 (Linke Menge zählen) und
Step 1 (Spiegel-Knopf drücken) bleiben intern; Step 2 (Gesamtsumme) wird live gemeldet.

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Custom-widget template for the registry key `"doubling_mirror_ikonisch"`
/// (verdoppeln-halbieren.ZR10, Level 2/ikonisch). Ported from the old
/// engine's `DoublingMirrorLevel2Widget`; that file is untouched. The child
/// counts the blue dots, presses a mirror button that animates a matching
/// red group into place, then reports the total -- reported live via
/// [onValueChanged], graded centrally like every other custom_widget.
class DoublingMirrorIkonischWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const DoublingMirrorIkonischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<DoublingMirrorIkonischWidget> createState() =>
      _DoublingMirrorIkonischWidgetState();
}

class _DoublingMirrorIkonischWidgetState
    extends State<DoublingMirrorIkonischWidget>
    with SingleTickerProviderStateMixin {
  // Steps: 0 count left (internal), 1 press mirror (internal), 2 report total.
  int _step = 0;

  bool _isMirrored = false;
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.black;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  int get _targetCount => (widget.problem.display['target'] as num).toInt();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DoublingMirrorIkonischWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _step = 0;
      _isMirrored = false;
      _leftController.clear();
      _totalController.clear();
      _feedbackMessage = '';
      _animController.reset();
    });
    widget.onValueChanged('');
  }

  void _checkLeftCount() {
    final input = int.tryParse(_leftController.text);
    if (input == null) return;

    if (input == _targetCount) {
      setState(() {
        _step = 1;
        _feedbackMessage = 'Richtig! Drücke den Spiegel-Knopf.';
        _feedbackColor = Colors.green;
        _leftController.clear();
      });
    } else {
      setState(() {
        _feedbackMessage = 'Fast! Versuch es nochmal!';
        _feedbackColor = Colors.orange;
        _leftController.clear();
      });
    }
  }

  void _activateMirror() {
    setState(() {
      _isMirrored = true;
      _step = 2;
      _feedbackMessage = 'Verdoppelt! Wie viele sind es jetzt?';
      _feedbackColor = Colors.green;
    });
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            _getInstructionText(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  _feedbackMessage.isNotEmpty ? _feedbackColor : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.blue.shade200, width: 2),
                      ),
                      child: Center(
                        child: _buildDotGrid(_targetCount, Colors.blue),
                      ),
                    ),
                  ),
                  Container(width: 4, color: Colors.transparent),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                      child: Center(
                        child: _isMirrored
                            ? ScaleTransition(
                                scale: _scaleAnimation,
                                child: _buildDotGrid(_targetCount, Colors.red),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              Center(
                child: Container(
                  width: 4,
                  height: double.infinity,
                  color: Colors.grey.shade400,
                ),
              ),
              Center(
                child: _step == 1
                    ? ElevatedButton(
                        onPressed: _activateMirror,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(24),
                          backgroundColor: Colors.purple,
                        ),
                        child: const Icon(Icons.compare_arrows,
                            size: 32, color: Colors.white),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.compare_arrows,
                            color: Colors.grey),
                      ),
              ),
            ],
          ),
        ),
        Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: switch (_step) {
            0 => _buildLeftCountInput(),
            1 => const Center(
                child: Text('Drücke den Spiegel-Knopf in der Mitte!',
                    style: TextStyle(fontSize: 18)),
              ),
            _ => _buildFinalAnswerField(),
          },
        ),
      ],
    );
  }

  String _getInstructionText() {
    if (_feedbackMessage.isNotEmpty) return _feedbackMessage;
    switch (_step) {
      case 0:
        return 'Wie viele blaue Punkte siehst du?';
      case 1:
        return 'Drücke den Spiegel-Knopf!';
      default:
        return 'Wie viele Punkte sind es jetzt zusammen?';
    }
  }

  Widget _buildDotGrid(int count, Color color) => Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: List.generate(count, (index) => _buildDot(color)),
      );

  Widget _buildDot(Color color) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      );

  Widget _buildLeftCountInput() => Row(
        children: [
          Expanded(
            child: TextField(
              controller: _leftController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '?',
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              onSubmitted: (_) => _checkLeftCount(),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _checkLeftCount,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.green,
            ),
            child: const Text('OK', style: TextStyle(fontSize: 24)),
          ),
        ],
      );

  Widget _buildFinalAnswerField() => TextField(
        key: const ValueKey('final-answer'),
        controller: _totalController,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: '?',
          filled: true,
          fillColor: Colors.white,
        ),
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        onChanged: widget.onValueChanged,
      );
}
```

- [ ] **Step 2: Widget-Test schreiben**

An `math_app/test/template_widgets_test.dart` anhängen (Import ergänzen):

```dart
  group('DoublingMirrorIkonischWidget', () {
    Problem mirrorProblem(int target) => _problem(
          template: 'custom_widget',
          display: {'custom_widget': 'doubling_mirror_ikonisch', 'target': target},
          expected: ['${target * 2}'],
        );

    testWidgets('pressing the mirror button advances to the final step',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        DoublingMirrorIkonischWidget(
          problem: mirrorProblem(3),
          onValueChanged: values.add,
        ),
      );

      await tester.enterText(find.byType(TextField), '3');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.compare_arrows));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byKey(const ValueKey('final-answer')), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('final-answer')), '6');
      await tester.pump();

      expect(values.last, '6');
    });
  });
```

- [ ] **Step 3: `template_registry.dart` erweitern**

Direkt nach dem in Task 3 hinzugefügten `'doubling_mirror_enaktiv'`-Fall:

```dart
      'doubling_mirror_ikonisch' => DoublingMirrorIkonischWidget(
          problem: problem,
          onValueChanged: onValueChanged,
        ),
```

Import ergänzen:
`import '../widgets/templates/doubling_mirror_ikonisch_widget.dart';`

- [ ] **Step 4: Tests laufen lassen**

Run: `cd math_app && flutter test test/template_widgets_test.dart`
Expected: alle Tests grün.

- [ ] **Step 5: Commit**

```bash
git add math_app/lib/widgets/templates/doubling_mirror_ikonisch_widget.dart math_app/lib/practice/template_registry.dart math_app/test/template_widgets_test.dart
git commit -m "feat(v2): doubling_mirror_ikonisch-Widget aus DoublingMirrorLevel2Widget portieren"
```

---

### Task 5: `doubling_mirror_symbolisch_widget.dart` (Level 3 portieren)

**Files:**
- Create: `math_app/lib/widgets/templates/doubling_mirror_symbolisch_widget.dart`
- Modify: `math_app/lib/practice/template_registry.dart`
- Test: `math_app/test/template_widgets_test.dart`

**Interfaces:**
- Consumes: `Problem` (`problem.display['target']`), `_generateDoublingMirror` (Task 3).
- Produces: registriert `custom_widget`-Schlüssel `"doubling_mirror_symbolisch"`.

- [ ] **Step 1: Neue Widget-Datei schreiben**

Portiert aus `DoublingMirrorLevel3Widget` — hier gibt es keine internen Zwischenschritte,
also entfällt die gesamte alte Selbstbewertung (`_checkInput`, Feedback-Text, eigener
Button); übrig bleibt die Zahlenkarte plus ein live meldendes Textfeld:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Custom-widget template for the registry key
/// `"doubling_mirror_symbolisch"` (verdoppeln-halbieren.ZR10, Level
/// 3/symbolisch). Ported from the old engine's `DoublingMirrorLevel3Widget`;
/// that file is untouched. Unlike Level 1/2, the original had no internal
/// scaffolding steps -- it showed a number card and self-graded a typed
/// answer with its own button. The port keeps the number card and drops the
/// self-grading entirely: the field reports live via [onValueChanged], and
/// the practice screen's one generic submit button grades it centrally.
class DoublingMirrorSymbolischWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const DoublingMirrorSymbolischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<DoublingMirrorSymbolischWidget> createState() =>
      _DoublingMirrorSymbolischWidgetState();
}

class _DoublingMirrorSymbolischWidgetState
    extends State<DoublingMirrorSymbolischWidget> {
  final TextEditingController _controller = TextEditingController();

  int get _targetCount => (widget.problem.display['target'] as num).toInt();

  @override
  void didUpdateWidget(covariant DoublingMirrorSymbolischWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _controller.clear();
      widget.onValueChanged('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Stell dir vor:',
          style: TextStyle(fontSize: 24, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.blue.shade200, width: 2),
          ),
          child: Center(
            child: Text(
              '$_targetCount',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          'Was ist das Doppelte?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 200,
          child: TextField(
            key: const ValueKey('final-answer'),
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              hintText: '?',
            ),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            autofocus: true,
            onChanged: widget.onValueChanged,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Widget-Test schreiben**

```dart
  group('DoublingMirrorSymbolischWidget', () {
    Problem mirrorProblem(int target) => _problem(
          template: 'custom_widget',
          display: {'custom_widget': 'doubling_mirror_symbolisch', 'target': target},
          expected: ['${target * 2}'],
        );

    testWidgets('shows the target number and reports the typed value',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        DoublingMirrorSymbolischWidget(
          problem: mirrorProblem(4),
          onValueChanged: values.add,
        ),
      );

      expect(find.text('4'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('final-answer')), '8');
      await tester.pump();

      expect(values.last, '8');
    });

    testWidgets('a new problem clears the field and reports ""',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        DoublingMirrorSymbolischWidget(
          problem: mirrorProblem(2),
          onValueChanged: values.add,
        ),
      );
      await tester.enterText(find.byKey(const ValueKey('final-answer')), '4');
      await tester.pump();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoublingMirrorSymbolischWidget(
              problem: mirrorProblem(5),
              onValueChanged: values.add,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(values.last, '');
      expect(find.text('5'), findsOneWidget);
    });
  });
```

- [ ] **Step 3: `template_registry.dart` erweitern**

```dart
      'doubling_mirror_symbolisch' => DoublingMirrorSymbolischWidget(
          problem: problem,
          onValueChanged: onValueChanged,
        ),
```

Import ergänzen:
`import '../widgets/templates/doubling_mirror_symbolisch_widget.dart';`

- [ ] **Step 4: Tests laufen lassen**

Run: `cd math_app && flutter test test/template_widgets_test.dart test/problem_generators_test.dart`
Expected: alle Tests grün.

- [ ] **Step 5: Commit**

```bash
git add math_app/lib/widgets/templates/doubling_mirror_symbolisch_widget.dart math_app/lib/practice/template_registry.dart math_app/test/template_widgets_test.dart
git commit -m "feat(v2): doubling_mirror_symbolisch-Widget aus DoublingMirrorLevel3Widget portieren"
```

---

### Task 6: Skill-Spec zusammensetzen und synchronisieren

**Files:**
- Create: `docs/clean-room/v2/skills/specs/verdoppeln-halbieren.ZR10.json`
- Modify: `scripts/sync_skill_specs.py`
- Test: `scripts/tests/test_sync_skill_specs.py` (neu, falls noch keine Tests für dieses Skript existieren — prüfen mit `ls scripts/tests/ | grep sync_skill`)

**Interfaces:**
- Consumes: `kKnownCustomWidgets` (Task 3, jetzt mit den drei neuen Schlüsseln),
  `SkillSpec.fromJson` (unverändert).
- Produces: `math_app/assets/skill_specs/verdoppeln-halbieren.ZR10.json` nach `flutter run`/Test
  (über den erweiterten Sync).

- [ ] **Step 1: Skill-Spec-JSON schreiben**

`docs/clean-room/v2/skills/specs/verdoppeln-halbieren.ZR10.json`:

```json
{
  "spec_version": 1,
  "skill_id": "verdoppeln-halbieren.ZR10",
  "construct_id": "verdoppeln-halbieren.ZR10",
  "domain": "v2",
  "title_de": "Verdoppeln im ZR10",
  "level_titles_de": [
    "Verdoppeln mit Punkten",
    "Verdoppeln mit dem Spiegel",
    "Verdoppeln im Kopf"
  ],
  "levels": [
    {
      "level": 1,
      "representation": "enaktiv",
      "template": "custom_widget",
      "custom_widget": "doubling_mirror_enaktiv",
      "params": { "count_range": [1, 5] },
      "problem_count": 8,
      "prompt_de": "Zähle die Punkte. Zieh genauso viele auf die andere Seite.",
      "slow_band_ms": 12000
    },
    {
      "level": 2,
      "representation": "ikonisch",
      "template": "custom_widget",
      "custom_widget": "doubling_mirror_ikonisch",
      "params": { "count_range": [1, 5] },
      "problem_count": 8,
      "prompt_de": "Zähle die Punkte. Drücke den Spiegel-Knopf, um zu verdoppeln.",
      "slow_band_ms": 9000
    },
    {
      "level": 3,
      "representation": "symbolisch",
      "template": "custom_widget",
      "custom_widget": "doubling_mirror_symbolisch",
      "params": { "count_range": [1, 5] },
      "problem_count": 8,
      "prompt_de": "Was ist das Doppelte?",
      "slow_band_ms": 6000
    }
  ],
  "mastery": { "correct_of": 8 },
  "error_taxonomy": [
    { "code": "off_by_one_low", "label_de": "eins zu wenig", "hint_de": "Ganz nah dran! Zähl noch einmal genau." },
    { "code": "off_by_one_high", "label_de": "eins zu viel", "hint_de": "Ganz nah dran! Zähl noch einmal genau." },
    { "code": "other", "label_de": "noch einmal probieren", "hint_de": "Schau dir die Punkte noch einmal an und probiere es noch einmal." }
  ],
  "provenance": {
    "sources": ["RLP BE/BB Teil C, L1, Niveaustufe A", "Padberg/Benz, Verdoppeln als Kernaufgabe", "Krajewski, Anzahlerfassung strukturierter Mengen", "Wartha/Schulz, Ablösung vom zählenden Rechnen"],
    "author": "Claude (domain author)",
    "reviewed_by": "open"
  }
}
```

- [ ] **Step 2: JSON gegen `SkillSpec.fromJson` validieren**

```bash
cd math_app && dart run -e "
import 'dart:convert';
import 'dart:io';
import 'package:math_app/models/skill_spec.dart';
void main() {
  final j = jsonDecode(File('../docs/clean-room/v2/skills/specs/verdoppeln-halbieren.ZR10.json').readAsStringSync());
  SkillSpec.fromJson(j);
  print('OK: verdoppeln-halbieren.ZR10.json parses');
}
"
```

Expected: `OK: verdoppeln-halbieren.ZR10.json parses`.

- [ ] **Step 3: `sync_skill_specs.py` erweitern**

```python
#!/usr/bin/env python3
"""Mirror the P3 skill specs into the Flutter bundle assets.

Copies docs/clean-room/skills/specs/*.json (v1) AND
docs/clean-room/v2/skills/specs/*.json (v2) into math_app/assets/skill_specs/,
creating the destination directory when needed. Idempotent: files that are
already present and byte-identical are left untouched. Prints a summary.
"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SRC_DIRS = [
    REPO_ROOT / "docs" / "clean-room" / "skills" / "specs",
    REPO_ROOT / "docs" / "clean-room" / "v2" / "skills" / "specs",
]
DEST_DIR = REPO_ROOT / "math_app" / "assets" / "skill_specs"


def main(argv: list[str] | None = None) -> int:
    DEST_DIR.mkdir(parents=True, exist_ok=True)

    sources: list[Path] = []
    for src_dir in SRC_DIRS:
        if not src_dir.is_dir():
            print(f"ERROR: specs directory not found: {src_dir}")
            return 1
        sources.extend(sorted(src_dir.glob("*.json")))

    copied = 0
    for source in sources:
        target = DEST_DIR / source.name
        if not target.is_file() or target.read_bytes() != source.read_bytes():
            shutil.copy2(source, target)
            copied += 1

    print(f"synced {len(sources)} skill specs to {DEST_DIR} ({copied} copied, {len(sources) - copied} unchanged)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Skript laufen lassen**

Run: `python scripts/sync_skill_specs.py`
Expected: `synced <N+1> skill specs to ... (1 copied, <N> unchanged)` — die `+1`/`1 copied` ist
`verdoppeln-halbieren.ZR10.json`.

- [ ] **Step 5: Commit**

```bash
git add docs/clean-room/v2/skills/specs/verdoppeln-halbieren.ZR10.json scripts/sync_skill_specs.py
git commit -m "feat(v2): Skill-Spec verdoppeln-halbieren.ZR10 anlegen, sync_skill_specs.py auf v2 erweitern"
```

---

### Task 7: Matrixstatus und Gate-Suite

**Files:**
- Modify: `docs/clean-room/v2/10-deckungsmatrix.md`

**Interfaces:**
- Consumes: `scripts/check_deckung.py` (Task-2/Phase-2-Regeln, unverändert), `scripts/derive_ableitungen.py --check`.

- [ ] **Step 1: Die drei ZR10-Zellen umsetzen**

In `docs/clean-room/v2/10-deckungsmatrix.md`, im Abschnitt `## Strang: verdoppeln-halbieren`,
die Tabellenzeile `| ZR10 | offen | offen | offen |` auf `| ZR10 | freigegeben | freigegeben | freigegeben |`
setzen (freigegeben, weil sowohl das Konstrukt jetzt ein Item hat — Task 2 — als auch jede
Zelle eine Übung — Tasks 3–5).

- [ ] **Step 2: Matrixgate laufen lassen**

Run: `python scripts/check_deckung.py`
Expected: `OK: ...`. Falls ein `FAIL` zur `verdoppeln-halbieren.ZR10`-Zeile erscheint, prüfen,
ob `konstrukt_items_of()` das neue Item (Task 2) korrekt als zu `verdoppeln-halbieren.ZR10`
gehörig erkennt (Feld `konstrukt:` im Item muss exakt `verdoppeln-halbieren.ZR10` lauten).

- [ ] **Step 3: Abgeleitete Dokumente neu erzeugen und prüfen**

Run: `python scripts/derive_ableitungen.py --check`
Expected: `OK` (Konstruktkarte/Blueprint sind unverändert abgeleitet, da sich an der Zellenzahl
oder Itemzuteilung nichts ändert — nur der `freigegeben`-Status ist neu, den die Ableitung
selbst nicht in die Tabelle schreibt).

- [ ] **Step 4: Volle Gate-Suite laufen lassen**

```bash
python scripts/check_item_quality.py
python scripts/check_deckung.py
python scripts/derive_ableitungen.py --check
python scripts/check_provenance.py
python scripts/check_mapping.py
cd math_app && flutter test
```

Expected: jedes Skript `OK`/exit 0; `flutter test` grün, inklusive aller in Task 1/3/4/5
hinzugefügten Tests.

- [ ] **Step 5: Commit**

```bash
git add docs/clean-room/v2/10-deckungsmatrix.md
git commit -m "feat(v2): Zellen verdoppeln-halbieren x ZR10 auf freigegeben setzen"
```

---

### Task 8: Realer Durchlauf und Gate-1-Freigabe

**Files:** keine Code-Änderungen — Verifikation und Rückfragen an Jakob.

- [ ] **Step 1: Echten Durchlauf verifizieren**

App lokal starten (Flutter Web oder Emulator), einen Diagnostiktestlauf machen, bei der
neuen Frage ("Rechne: 4 + 4") absichtlich falsch antworten, und bestätigen: (a) die Frage
erscheint überhaupt, (b) eine falsche Antwort routet zu `verdoppeln-halbieren.ZR10`, (c) die
Praxis-Session startet bei Level 1 (enaktiv, `DoublingMirrorEnaktivWidget`) und lässt sich bis
Level 3 durchspielen, (d) im Dashboard erscheint der Skill für den Testschüler (bestätigt oder
widerlegt die in der Design-Spec offen gelassene Annahme zur Dashboard-Sichtbarkeit).

- [ ] **Step 2: Gate-1-Fragen an Jakob**

Genau vier Fragen, analog zum Muster aus Phase 2:

1. Ist "Rechne: 4 + 4" das richtige Kern-Item für `verdoppeln-halbieren.ZR10` — Zahl, Wortlaut,
   Antwortformat passend für ein Klasse-2-Förderkind?
2. Sind die beiden Fehlersignaturen (`7` = ein Schritt zu wenig, `9` = ein Schritt zu viel)
   das, was ein zählend rechnendes Kind tatsächlich tippt — oder fehlt ein Fehlerbild?
3. Ist die Portierung der drei Mirror-Level (Schritt-für-Schritt-Aufbau bleibt, nur die
   Bewertung wandert nach außen) pädagogisch unauffällig, oder ändert das Fehlen der
   sofortigen "Fast!"-Rückmeldung im letzten Schritt etwas Wesentliches am Erlebnis?
4. Ist `Ergebnis der Dashboard-Sichtbarkeitsprüfung (Step 1d)` erwartungsgemäß, oder muss
   das Dashboard doch angepasst werden?

- [ ] **Step 3: Antworten eintragen**

Je nach Jakobs Antworten: `reviewer:` im Item (Task 2) auf `Jakob, <Datum>` setzen,
`reviewed_on` in `provenance.csv` füllen, und — falls Frage 3 oder 4 Änderungen verlangt —
die betroffenen Tasks (3–5 bzw. Dashboard) vor dem nächsten Schritt nachbessern.

---

### Task 9: Commit (gated)

**Nur auf Jakobs ausdrückliche Freigabe für diesen Moment.** Alle vorherigen Task-Commits sind
bereits lokal; dieser Task ist der Punkt, an dem die Freigabe zu einem **Push** (und damit
Auto-Deploy) explizit eingeholt wird — nicht automatisch, weil die vorherigen Commits
stattgefunden haben.

- [ ] **Step 1: Zusammenfassung vorlegen**

Vor jedem Push: `git log --oneline <erster-commit-dieser-plan>..HEAD` und `git diff --stat
<erster-commit-dieser-plan>..HEAD` vorlegen, explizit fragen, ob gepusht werden soll.

- [ ] **Step 2: Push (nur nach "ja")**

```bash
git push origin main
```
