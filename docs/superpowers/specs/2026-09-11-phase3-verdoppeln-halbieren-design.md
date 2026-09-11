# Phase 3 — Erster Slice: Verdoppeln/Halbieren × ZR10·ZR20·ZR100 (Design)

**Status:** Entwurf — wartet auf Jakobs Review.

**Vorgänger:** [2026-09-07-diagnostik-v2-design.md](2026-09-07-diagnostik-v2-design.md) (§Phase 3,
Zeile 195); [10-deckungsmatrix.md](../../clean-room/v2/10-deckungsmatrix.md),
[11-konstruktkarte.md](../../clean-room/v2/11-konstruktkarte.md),
[12-blueprint.md](../../clean-room/v2/12-blueprint.md),
[14-itemregeln.md](../../clean-room/v2/14-itemregeln.md) — alle Gate-1-freigegeben.

## Ziel

Den ersten vollständigen vertikalen Schnitt durch die v2-Pipeline bauen und live schalten:
Diagnostik-Items → handgebaute Übungs-Level → Anschluss an `learning-path`/`practice-session`
→ sichtbar im Lehrer-Dashboard. Einzelner Strang: `verdoppeln-halbieren`, alle drei
Zahlenräume. Das beweist die Pipeline an echten Kindern, nicht nur an Dokumenten.

Gewählt laut Design-Spec, weil er die benannte Lücke ist (Halbieren hat im Altbestand
**keine einzige** Übung), alle drei Zahlenräume durchläuft (beweist die strangweise
Abkürzung), Altübungen zum Re-Derivieren hat (beweist Adapter und R8.1-Triage) und eine
leere Diagnostikseite hat (beweist die Itemregeln).

## Geltungsbereich dieser Entscheidung

Dies ist ein **Live-Pilot ab dem ersten Commit**, keine isolierte Sandbox: die neuen
Diagnostik-Items laufen in derselben Diagnostiksitzung, die echte Kinder heute nehmen; die
neuen Übungs-Level laufen über dieselben, unveränderten `practice-session`/`learning-path`-
Functions; das Dashboard zeigt sie ohne Sonderweg an.

**Das ist keine Deploy-Freigabe.** Committen ist mit dieser Spec-Freigabe erlaubt; Pushen
nach `main` (löst Auto-Deploy auf Vercel aus) und jede Schema-Änderung an einer
Produktionstabelle brauchen weiterhin Jakobs ausdrückliche Freigabe im jeweiligen Moment,
genau wie in Phase 1 und 2.

## Architektur

### Datenfluss

```
docs/clean-room/v2/items/verdoppeln-halbieren.*.md      (5 neue Diagnostik-Items,
  (12-blueprint.md Zeilen 40-44: 3 Kern symbolisch        Text/Fehlersignatur/Audio-Pfad
   ZR10/ZR20/ZR100, 2 Stütze enaktiv ZR20/ZR100)          nach 14-itemregeln.md)
        |
        v
Research/diagnostic_v2_verdoppeln_halbieren.csv          (NEU — dasselbe 14-Spalten-
  (dieselben 5 Items im v1-CSV-Schema, damit             Schema wie diagnostic_core_v1.csv,
   diagnostic_service.dart sie ohne Modellwechsel          aber eine eigene Datei: die
   parsen kann)                                            gesperrte v1-Datei bleibt unberührt)
        |
        v  (diagnostic_service.dart: loadQuestions() lädt und mischt beide Dateien;
        |   die 3 v1-Fragen zu diesem Strang werden beim Mischen ausgeschlossen)
        v
IfWrong_practice_skills  ->  neue v2-Skill-IDs, z.B. verdoppeln-halbieren.ZR10.symbolisch
        |
        v
docs/clean-room/v2/skills/specs/verdoppeln-halbieren.*.json   (NEU — ein Skill-Spec je
  (9 Dateien: 3 ZR x 3 Repräsentationen, feste            lebender Matrixzelle, siehe
   handgebaute Level statt Zufallsparameter des            "Zellen -> Level" unten)
   Generators)
        |
        v  scripts/sync_skill_specs.py (erweitert: liest zusätzlich aus
        |   docs/clean-room/v2/skills/specs/, schreibt weiterhin in denselben
        |   flachen math_app/assets/skill_specs/ — v1- und v2-IDs kollidieren
        |   nicht, siehe Namensschema unten)
        v
math_app/assets/skill_specs/*.json  (Flutter-Asset-Bundle, unverändert geladen)
        |
        v
neue custom_widget-Einträge in template_registry.dart / problem_generators.dart /
  template_evaluator.dart — portiert aus den Alt-Klassen (Verdoppeln) oder neu
  geschrieben (Halbieren); Vertrag: (Problem problem, ValueChanged onValueChanged),
  kein UserProfile (siehe "Alt-Engine-Adapter" unten)
        |
        v
practice-session / learning-path (Supabase Functions) — UNVERÄNDERT
        |
        v
dashboard (Next.js) — zeigt Skills generisch an, keine Hardcodierung gefunden;
  Änderungen hier nur, falls die Review etwas anderes zeigt (siehe Risiken)
```

### Zellen → Level

Die Matrix hat für `verdoppeln-halbieren` neun lebende Zellen (3 Zahlenräume × 3
Repräsentationen, alle Status `offen`). Jede braucht laut Decision B (12-blueprint.md) eine
`übung:`, unabhängig von der Diagnostik-Zuteilung (die nur 5 Items über die Konstrukte
verteilt). Zuordnung der Altübungen als Ausgangspunkt der R8.1-Triage:

| Zelle | Richtung | Altübung (Kandidat) | Skill-Tag (alt) | Triage |
|---|---|---|---|---|
| ZR10 × enaktiv | Verdoppeln | `DoublingMirrorExercise` (S3.1, Input 1–5) | `basic_strategy_7` | portieren |
| ZR10 × ikonisch | Verdoppeln | keine (S3.1 ist bereits enaktiv am Spiegelbild) | — | neu |
| ZR10 × symbolisch | Verdoppeln | keine direkte | — | neu (Kern-Repräsentation) |
| ZR10 × * | Halbieren | keine | — | neu (alle drei) |
| ZR20 × enaktiv | Verdoppeln | `DoublingMirrorExercise` (S3.2, Input 6–10) | `basic_strategy_7` | portieren |
| ZR20 × ikonisch | Verdoppeln | `DoublingBoatExercise` (S3.4, Rechenschiffchen) | `basic_strategy_9/10` | portieren |
| ZR20 × symbolisch | Verdoppeln | `DoublingFingersExercise`/`...20` (S3.3/S3.5) | `basic_strategy_8` | prüfen (Finger sind eher enaktiv als symbolisch — evtl. umsortieren statt 1:1 übernehmen) |
| ZR20 × * | Halbieren | keine | — | neu (alle drei) |
| ZR100 × enaktiv/ikonisch | Verdoppeln | keine direkte | — | neu |
| ZR100 × symbolisch | Verdoppeln | `DoublingTensExercise` (S3.6, Zehner verdoppeln) | `strategy_doubling_tens_1` | portieren |
| ZR100 × * | Halbieren | keine | — | neu (alle drei) |

Diese Tabelle ist eine **Ausgangshypothese für die Planung**, keine endgültige
Freigabe — insbesondere ob `DoublingFingersExercise` wirklich `symbolisch` ist oder
eigentlich `enaktiv` gehört zur Content-Review, nicht zu dieser Architektur-Spec. Der
Implementierungsplan (`writing-plans`) macht daraus konkrete Tasks mit tatsächlichem
Zahlenmaterial. Klar ist bereits: von neun Zellen sind mindestens fünf (jede
Halbieren-Zelle plus ZR100-enaktiv/ikonisch) komplett neu zu bauen, nicht zu portieren.

### Alt-Engine-Adapter: Ersetzung, keine Brücke

Die Design-Spec (Zeile 215) lässt offen, ob `UserProfile` gebrückt oder ersetzt wird. Die
neue Engine beantwortet das bereits durch ihren bestehenden Vertrag: jedes `custom_widget`
(`BundlingWidget`, `UnbundlingWidget`, `NumberlineMarkWidget`, `FlashSubitizeWidget`) nimmt
ausschließlich `(Problem problem, ValueChanged<...> onValueChanged)` — zustandslos, über
`problem.display` konfiguriert. Portierte Widgets bekommen denselben Vertrag: ihre
interne Logik (Spiegel-Animation, Rechenschiffchen-Interaktion, Finger-Zählung) bleibt,
aber sie lesen ihre Parameter (Zahlenbereich, aktuelle Aufgabe, erwartete Antwort) aus
`problem.display`/`problem.expected` statt aus einem injizierten `UserProfile`. Das ist
eine **Ersetzung**, keine Brücke — die einzige Wahl, die mit jedem bereits gebauten
`custom_widget` konsistent ist.

### Namensschema

- **Item-IDs** (Diagnostik): `<konstrukt>-<laufnummer>`, bereits durch I10 und die
  Blueprint-Zeilen 40–44 festgelegt (z.B. `verdoppeln-halbieren.ZR10-01`).
- **Skill-IDs / Skill-Spec-Dateinamen** (Übung): `verdoppeln-halbieren.<ZR>.<repräsentation>`,
  z.B. `verdoppeln-halbieren.ZR20.enaktiv` — dieselbe Zelle-Vokabular wie die Matrix, damit
  eine Übung ihre Zelle ohne Zwischenschritt nennt (folgt demselben Ankerprinzip wie I10 für
  Items). Kollidiert nicht mit den alten `A1.1a`-Codes.
- **CSV-Datei:** `Research/diagnostic_v2_verdoppeln_halbieren.csv`, 14-Spalten-Schema
  identisch zu `diagnostic_core_v1.csv`.

## Nötige Code-Änderungen (Übersicht, kein Ersatz für den Plan)

1. **`diagnostic_service.dart`**: `loadQuestions()` lädt heute genau einen Asset-Pfad fest
   verdrahtet. Muss so erweitert werden, dass es zusätzlich
   `Research/diagnostic_v2_verdoppeln_halbieren.csv` lädt, dessen Zeilen einmischt und die
   drei alten `verdoppeln-halbieren`-Fragen aus `diagnostic_core_v1.csv` beim Zusammenstellen
   der Sitzung ausschließt (die CSV-Datei selbst bleibt Byte-für-Byte unverändert — das
   Ausschließen passiert beim Laden, nicht durch Löschen einer Zeile).
2. **`scripts/sync_skill_specs.py`**: zusätzliche Quelle
   `docs/clean-room/v2/skills/specs/*.json`, gleiche Zielverzeichnis-Logik, gleiche
   Idempotenz-Garantie. Ein Skript, zwei Quellverzeichnisse — kein Duplikat.
3. **`template_registry.dart`, `problem_generators.dart`, `template_evaluator.dart`**: neue
   `custom_widget`-Registry-Einträge für jede portierte/neue Übung (siehe Zellen-Tabelle).
4. **Neue/portierte Widget-Dateien** unter `math_app/lib/widgets/` bzw. `math_app/lib/exercises/`
   (genaue Aufteilung entscheidet der Plan anhand der bestehenden Datei-pro-Übung-Konvention).
5. **`docs/clean-room/v2/items/verdoppeln-halbieren.*.md`**: 5 neue Diagnostik-Item-Dateien,
   `check_item_quality.py`-konform.
6. **`docs/clean-room/v2/skills/specs/verdoppeln-halbieren.*.json`**: 9 neue Skill-Specs.
7. **`docs/clean-room/v2/10-deckungsmatrix.md`**: die neun Zellen wechseln von `offen` auf
   `entworfen`/`freigegeben`, sobald Item und Übung stehen — reguläre Matrixpflege, kein
   Sonderfall.

## Was unverändert bleibt

- `practice-session`, `learning-path` (Supabase Functions): kein Schema- oder Logikwechsel.
  Neue Skill-IDs sind für sie nur Daten.
- Dashboard-Code: nach aktueller Durchsicht keine Hardcodierung von Skill-IDs gefunden: neue
  Skills sollten ohne Codeänderung erscheinen. Bestätigt wird das im Plan durch einen realen
  Durchlauf, nicht durch diese Vermutung allein (siehe Risiken).
- `Research/diagnostic_core_v1.csv`, `docs/clean-room/01-construct-map.md`,
  `docs/clean-room/02-blueprint.md`, `docs/clean-room/items/`, `docs/clean-room/skills/`,
  `docs/clean-room/foerderplan/mapping-rationale.md` — weiterhin gesperrte v1-Artefakte.

## Risiken / offene Fragen für den Plan

- **Dashboard-Sichtbarkeit ist eine Vermutung.** Muss früh im Plan an einem echten Klick
  durch das Dashboard verifiziert werden, nicht erst am Ende.
- **`DoublingFingersExercise`-Einordnung** (symbolisch vs. enaktiv) ist eine fachliche
  Content-Frage, keine Architekturfrage — geht an Jakob als Gate-1-Entscheidung während der
  Content-Tasks, nicht hier.
- **TTS-Audio** (`audio/v2/<item-id>.mp3`, I9) wird laut Design-Spec erst in Phase 5 gebaut.
  Für den Live-Piloten heißt das: der Vertrag (Feldname, Pfad) wird erfüllt, aber die Datei
  fehlt zunächst — der Plan muss festlegen, was die App tut, wenn `audio` gesetzt ist, aber
  die Datei nicht existiert (stummer Fallback vermutlich, aber das ist eine
  Laufzeitentscheidung, keine Dokumentationsfrage, und gehört als eigener Plan-Task
  entschieden).
- **Rollout-Reihenfolge**: Diagnostik-CSV-Änderung und Übungs-Level sind voneinander
  abhängig (ein Kind, das durchfällt, muss sofort eine Übung vorfinden). Der Plan sollte
  beide zusammen in derselben Freigabe-Einheit halten, nicht die Diagnostik vorzeitig live
  schalten, während die Übungen noch fehlen.

## Out of Scope (Phase 4–6)

Migration weiterer Stränge (Phase 4); Bulk-Generator/-Migration und TTS-Audio (Phase 5);
iMINT-Deckungsaudit und Rechtsprüfung (Phase 6); `check_item_independence.py` (weiterhin
außerhalb des Gates, siehe Phase-2-Begründung — Grund entfällt erst, wenn `--new` echte
Items dieser Phase vorliegen).
