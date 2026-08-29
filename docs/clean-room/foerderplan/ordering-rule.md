# Reihenfolgeregel für Förderplan-Empfehlungen

| Feld | Wert |
|---|---|
| **Titel** | Reihenfolgeregel für Förderplan-Empfehlungen |
| **Status** | DRAFT — awaiting Jakob's sign-off |
| **Datum** | 2026-08-29 |
| **Owner** | Jakob |
| **Ersetzt** | die Alt-Sortierung „Kategorienreihenfolge → `card_number` ASC" (tasks.md, R4.2) |
| **Grundlagen** | `01-construct-map.md` (Konstrukte, Domänen A–D) · `02-blueprint.md` (§Sequenzregeln, §Break-off) · `03-bibliography.md` (Einträge A1–B5) |
| **Implementierung** | `math_app/lib/services/skill_recommendation_order.dart` |
| **Test** | `math_app/test/skill_recommendation_order_test.dart` |

## Zweck

Im Vorgänger-System wurde die Liste der empfohlenen Förder-Skills mit „Kategorienreihenfolge → `card_number` ASC" sortiert. Beide Bestandteile dieser Regel existieren im Clean-Room-Neubau nicht mehr: Die Kategorienstruktur ist vollständig durch die Domänen A–D mit den Konstrukten A1.1…D1.2 ersetzt (`01-construct-map.md`), und `card_number` ist ersatzlos gestrichen (tasks.md, R3.1). Diese Regel definiert die neue Sortierung eigenständig aus der Konstruktkarte und dem Blueprint und macht sie testbar (tasks.md, R4.2).

## Die Regel (Kurzfassung)

Empfohlene Skills werden nach der Position ihres Konstrukts in der didaktischen Sequenz des Blueprints sortiert:

1. **Primärschlüssel — Konstruktposition:** Position des Konstrukts in der kanonischen Konstruktreihenfolge (Tabelle unten). Diese ordnet die Konstrukte der Konstruktkarte in der Sequenz des Blueprints A1 → A2 → A3 → B1 → B2 → C1 → C2 → C3 → C4 → D1 (02-blueprint.md, §Sequenzregeln): Domäne A → B → C → D; innerhalb der Domäne die Konstruktreihenfolge der Karte; innerhalb eines Konstrukts (z. B. A1) die Teilkonstrukte in Kartenreihenfolge (A1.1 → A1.2 → …).
2. **Sekundärschlüssel — Suffix innerhalb desselben Konstrukts:** Empfehlen mehrere Skills dasselbe Konstrukt, entscheidet das ID-Suffix: ohne Suffix zuerst, dann alphabetisch (`a` vor `b` vor `c` …). Beispiel: `A1.1` → `A1.1a` → `A1.1b`.
3. **Deterministischer Gleichstand:** Führt auch der Suffixvergleich nicht weiter, entscheidet der vollständige Skill-ID-String lexikografisch. Damit hängt das Ergebnis für dieselbe Empfehlungsmenge nicht von der Reihenfolge der Eingabe ab.
4. **Priorität aus der Item→Skill-Zuordnung:** Trägt eine Empfehlung eine Priorität aus der Item→Skill-Zuordnung (1. = höchste Priorität, siehe `mapping-rationale.md`, R4.1), so darf diese Priorität die Reihenfolge **innerhalb desselben Konstrukts** übersteuern. Die Konstruktsequenz bleibt stets der Primärschlüssel: Eine höhere Priorität kann ein Konstrukt nie vor ein konstruktfrüheres ziehen. Die Dart-Implementierung bildet die konstruktbasierte Reihenfolge ab; die optionale Prioritätsübersteuerung innerhalb eines Konstrukts wendet die Integration (R4.3/R5.4) oberhalb davon an.

## Kanonische Konstruktreihenfolge

Vollständige Ordnung aller 31 Konstrukte der Konstruktkarte. „Pos." ist die Sortierposition (kleiner = früher im Förderplan).

| Pos. | Konstrukt | Kurzname | Domäne |
|---|---|---|---|
| 1 | A1.1 | Vorwärtszählen in ZR20/ZR100 vom beliebigen Startpunkt | A — Zahlbegriff |
| 2 | A1.2 | Rückwärtszählen in ZR20/ZR100 vom beliebigen Startpunkt | A — Zahlbegriff |
| 3 | A1.3 | Zählen in Schritten (2er, 5er, 10er) vor- und rückwärts | A — Zahlbegriff |
| 4 | A1.4 | Vorgänger/Nachfolger bestimmen | A — Zahlbegriff |
| 5 | A1.5 | Zählen über Zehnerübergang hinweg | A — Zahlbegriff |
| 6 | A2.1 | Simultanerfassung (Subitizing) bis 4–5 | A — Zahlbegriff |
| 7 | A2.2 | Strukturierte Anzahlerfassung bis 10 | A — Zahlbegriff |
| 8 | A2.3 | Anzahlvergleich / mehr-weniger | A — Zahlbegriff |
| 9 | A3.1 | Teil-Teil-Ganzes in ZR10 | A — Zahlbegriff |
| 10 | A3.2 | Zerlegungen einer Zahl flexibel finden | A — Zahlbegriff |
| 11 | A3.3 | Zahlbeziehungen (Verdopplungen, Nachbarzahlen) | A — Zahlbegriff |
| 12 | B1.1 | Zehner und Einer in zweistelliger Zahl erkennen | B — Stellenwertverständnis |
| 13 | B1.2 | Bündelung von Einzelobjekten zu Zehnern | B — Stellenwertverständnis |
| 14 | B1.3 | Entbündelung eines Zehners | B — Stellenwertverständnis |
| 15 | B2.1 | Standardform und Stellenwerttafel | B — Stellenwertverständnis |
| 16 | B2.2 | Zahlen am Zahlenstrahl verorten | B — Stellenwertverständnis |
| 17 | B2.3 | Zahlen in nicht-standardisierter Form | B — Stellenwertverständnis |
| 18 | C1.1 | Aufgaben ohne Zehnerübergang automatisiert abrufbar | C — Rechenstrategien |
| 19 | C1.2 | Verdopplungsaufgaben automatisiert | C — Rechenstrategien |
| 20 | C1.3 | Halbierungsaufgaben automatisiert | C — Rechenstrategien |
| 21 | C2.1 | Zerlegungsstrategien (Teilschritt-Verfahren) | C — Rechenstrategien |
| 22 | C2.2 | Verdopplung/Halbierung als Stützpunkt | C — Rechenstrategien |
| 23 | C2.3 | Ergänzen statt Abziehen bei Subtraktion | C — Rechenstrategien |
| 24 | C3.1 | Stellenweises Rechnen (Z ± Z, E ± E) | C — Rechenstrategien |
| 25 | C3.2 | Schrittweises Rechnen | C — Rechenstrategien |
| 26 | C3.3 | Hilfsaufgaben (Nachbaraufgaben, Ergänzen) | C — Rechenstrategien |
| 27 | C3.4 | Zerlegungsstrategien | C — Rechenstrategien |
| 28 | C4.1 | Strategieauswahl abhängig von Zahlen | C — Rechenstrategien |
| 29 | C4.2 | Inverse Beziehung Addition/Subtraktion nutzen | C — Rechenstrategien |
| 30 | D1.1 | Mathematisierung von Alltagskontexten | D — Sachsituationen |
| 31 | D1.2 | Erkennen der Rechenoperation | D — Sachsituationen |

## Begründung

1. **Die Diagnostik misst die Konstrukte in dieser Reihenfolge vom Leichten zum Schweren.** „Konstruktreihenfolge vom Leichten zum Schweren: A1 → A2 → A3 → B1 → B2 → C1 → C2 → C3 → C4 → D1. Dies folgt der üblichen didaktischen Abfolge der Grundschulmathematik (Zahlbegriff vor Operationen, ZR10 vor ZR20 vor ZR100) und steht im Einklang mit der Sequenz von Rahmenlehrplan BE/BB 2023 und Padberg/Benz 2021" (02-blueprint.md, §Sequenzregeln).
2. **Ein Förderplan soll grundlegende Skills vor abhängigen Skills empfehlen.** Die Diagnose misst Voraussetzungen früher als das, was darauf aufbaut; die Empfehlung folgt derselben Kausalrichtung. Das tragende Argument ist empirisch: Wer Aufgaben mit Zehnerübergang im ZR20 nicht bewältigt, wird Aufgaben im ZR100 nicht bewältigen — eine ZR100-Aufgabe bringt für ein Kind, das die ZR20-Grundaufgabe nicht löst, keinen Erkenntniswert (Wartha 2019, Eintrag A2 in `03-bibliography.md`; dieselbe Prädiktor-Logik trägt die Abkürzungsregel in 02-blueprint.md, §Break-off). Überträgt man diese Logik auf die Förderung, werden jene Skills zuerst empfohlen, deren Konstrukte in der Diagnostik zuerst gemessen und zuerst benötigt werden.
3. **Die kanonische Reihenfolge ist vollständig durch die Konstruktkarte festgelegt.** Auswahl, Gruppierung und Reihenfolge der Konstrukte sind die eigene redaktionelle Entscheidung auf Grundlage der zitierten Literatur; Konstruktnamen und didaktische Reihenfolge sind Standard der Grundschulmathematik (01-construct-map.md, „Geltung und Abgrenzung"). Die Karte ist die Quelle der Wahrheit für alle Förderplan-Regeln (tasks.md, R1.3).

## Durchgearbeitetes Beispiel

Angenommen, die Diagnostik löst für ein Kind folgende fünf Empfehlungen aus (in der Reihenfolge, in der sie gesammelt wurden):

| Skill-ID | Konstrukt | Pos. |
|---|---|---|
| C3.2 | C3.2 Schrittweises Rechnen | 25 |
| A1.5 | A1.5 Zählen über Zehnerübergang hinweg | 5 |
| B2.1 | B2.1 Standardform und Stellenwerttafel | 15 |
| D1.1 | D1.1 Mathematisierung von Alltagskontexten | 30 |
| A1.1 | A1.1 Vorwärtszählen in ZR20/ZR100 | 1 |

Sortiert nach Konstruktposition ergibt sich:

**A1.1 → A1.5 → B2.1 → C3.2 → D1.1**

Beispiel innerhalb eines Konstrukts (Sekundärschlüssel): `A1.1b`, `A1.1a`, `A1.1` → **`A1.1` → `A1.1a` → `A1.1b`** (ohne Suffix zuerst, dann `a` vor `b`). Genau diese beiden Ergebnisse prüft der Unit-Test als Bodengrundwahrheit („orders across constructs", „orders within a construct", „deterministic tie-break").

## Geltung

Diese Regel ersetzt die Alt-Sortierung vollständig für alle Empfehlungen, die aus dem Item→Skill-Mapping (R4.1) entstehen. Vor der Verwendung ist die Regel von Jakob freizugeben (Status oben).
