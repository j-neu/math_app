# 00 — Bewertung des Clean-Room-Durchlaufs v1 (`cleanroom-v1`)

| Feld | Wert |
|---|---|
| **Status** | ⛔ **v1 VERWORFEN** — Neuentwicklung (v2) beschlossen |
| **Datum** | 2026-09-07 |
| **Entscheider** | Jakob |
| **Betrifft** | `01-construct-map.md`, `02-blueprint.md`, `items/`, `skills/`, `foerderplan/mapping-rationale.md`, `math_app/Research/diagnostic_core_v1.csv` + `diagnostic_deepdive_v1.csv`, Live-Bank `cleanroom-v1` |

## Entscheidung

Der Clean-Room-Durchlauf v1 (`tasks.md` Phasen R1–R6, 2026-08-29 bis 2026-09-05) wird **inhaltlich verworfen und neu gemacht**. Das ausgelieferte Diagnostikum ist **in seiner jetzigen Form fachlich nicht brauchbar** und darf keiner Lehrkraft als Diagnoseinstrument vorgelegt werden, solange die Neuentwicklung nicht abgeschlossen ist.

Betroffen ist der **Inhalt** (Konstruktkarte, Blueprint, Itembank, Skill-Taxonomie, Förderplan-Zuordnung), **nicht** die Infrastruktur: App, Dashboard, Backend, Migrationsmechanik, Provenance-Werkzeuge und der Lernpfad-/Übungs-Runtime bleiben bestehen.

## Befunde (verifiziert am 2026-09-07 gegen die Runtime-CSVs und die Konstruktkarte)

1. **Verdoppeln/Halbieren ist grob unterbestimmt.**
   - **ZR10:** vorhanden (Kern-Items 32 `4+4`, 33 `5+5`, 34 „halb so groß wie 6", 35 „halb so groß wie 10"; dazu 18/19 als Zahlbeziehung).
   - **ZR20:** **kein einziges direktes Item.** Die beiden C2.2-Items (39 `8+7`, 40 `9+8`) sind Zehnerübergangs-Aufgaben, die die Verdopplung als *Stützstrategie voraussetzen*, aber nie prüfen, ob das Kind `7+7`, `8+8`, `9+9` überhaupt abrufen kann. Halbieren im ZR20 (Hälfte von 14/16/18) fehlt im Kerntest vollständig; ein einziges Deep-Dive-Item (DD 10) berührt es.
   - **ZR100:** **vollständig abwesend** — weder Konstrukt (C3 kennt kein Verdoppeln/Halbieren) noch Item. `25+25`, „Hälfte von 60/80", Verdopplung als Stützpunkt im Hunderterraum: nicht gemessen, nicht förderbar, im Förderplan nicht empfehlbar.
2. **Viele Items sind für die Zielgruppe zu komplex und diagnostisch verfehlt.** Die Kern-Items 44–53 (ZR100) sind mehrsätzige Anleitungstexte, die dem Kind das Verfahren vorschreiben, z. B. Item 44: „Rechne 34 + 28. In der Tabelle stehen Zehner und Einer. Die Zahl 34 hat 3 Zehner und 4 Einer …". Damit misst das Item **Anweisungsbefolgung statt Strategie** — das Gegenteil des Produktzwecks (prozessorientierte Diagnose, Ablösung vom zählenden Rechnen) — und erzeugt für ein Kind der 2. Klasse (erst recht im Förderkontext, erst recht mit ADHS) eine reine Leselast.
3. **Das Leitkonstrukt des Produkts wird nicht direkt erhoben.** Zählendes Rechnen wird nur indirekt über Reaktionszeiten weniger C2–C4-Items erschlossen; nach dem *Wie* wird nur in den vier C4-Items gefragt, alle im ZR100.
4. **Weitere Lücken in der Konstruktkarte** (nicht erschöpfend, Teil der v2-Analyse): Zahlvergleich/Ordnen zweistelliger Zahlen, Kraft der Fünf als eigenes Strukturmerkmal, Ergänzen zum vollen Zehner als eigenständiges Konstrukt.
5. **Prozessversagen, nicht nur Inhaltsversagen.** Sämtliche Gates (Provenance, Independence, Mapping, Specs, Skill-Descriptions) waren durchgehend grün, während das Instrument unbrauchbar war: **die Gates prüfen die Papierlage, nicht die fachliche Abdeckung, die Altersangemessenheit oder die Itemqualität.** Konstruktkarte und Blueprint entstanden in einem Zug, wurden freigegeben, und alles Nachgelagerte (Items, Skills, Mapping, Live-Bank) rechnete auf ihnen weiter. Es gab nie einen Abgleich gegen die tatsächlichen Lehrplaninhalte der Klassen 1–2 und nie eine Erprobung an einem Kind.

## Konsequenzen bis zur v2

- Das Diagnostikum gilt **intern als unbrauchbar**; keine Pilotdurchführung, keine Förderplan-Empfehlung an eine Lehrkraft auf Basis von `cleanroom-v1`.
- Die nicht-kommerzielle Haltung (`tasks.md` R0.1 / R9.3) bleibt unverändert in Kraft — sie ist jetzt zusätzlich fachlich begründet, nicht nur rechtlich.
- Die Live-Daten und die Migrationsmechanik bleiben unangetastet; v2 wird wie v1 als **neue** Diagnostik-Zeile ausgeliefert, nicht als Änderung an `cleanroom-v1`.
- Der Neuaufbau wird als eigener Design-Durchlauf geplant (Spec unter `docs/superpowers/specs/`), bevor an Items gearbeitet wird.

## Offene Grundsatzfrage für v2 (noch nicht entschieden)

Wie die Quellenbasis für v2 gewonnen wird — insbesondere, ob und wie die **Quellen**, auf die sich die iMINT-Kartei stützt, als Wegweiser in die Primärliteratur genutzt werden. Konstrukte, didaktische Abfolge und Fachvokabular sind ungeschützt; **Auswahl, Anordnung, Kartenstruktur und Wortlaut der Kartei sind es nicht** und dürfen auch über den Umweg „aus ihren Quellen rekonstruiert" nicht zum Zielbild werden (siehe `rewrite.md` §1, §16). Diese Frage wird im v2-Design ausdrücklich beantwortet und als ADR festgehalten.

---

## Anhang A — Itemweise Befunde (Jakob, 2026-09-07, an der laufenden Diagnostik)

Durchgang durch den Kerntest am laufenden Client. Nummern = `ListNumber` in `diagnostic_core_v1.csv`.

| Item | Befund | Klasse |
|---|---|---|
| **Q7** (Vorgänger/Nachfolger 37) | Zwei Antworten in einem Item, ohne dass das Antwortfeld das abbildet. Muss in zwei Items geteilt oder visuell getrennt werden: `__ , 37` in einer Zeile, darunter `37 , __`. | Ein Item, eine Antwort |
| **Q8** (Rekenrek-Blitz) | Konstruktfehler: Simultanerfassung geht **höchstens bis 5**, darüber ist sie nicht möglich. Zusätzlich ist die Darstellung unklar, weil die Reihen horizontal gegeneinander verschoben sind. | Konstrukt + Darstellung |
| **Q8 → Q9** | Harter Schwierigkeitssprung zwischen Nachbaritems (Q8 sehr schwer, Q9 sehr leicht). *(Nummern wie notiert; gemeint ist der Sprung zwischen aufeinanderfolgenden Items.)* | Schwierigkeitsverlauf |
| **Q11** (mehr/weniger, ikonisch) | Sehr leicht und rein ikonisch. Es fehlt die symbolische Entsprechung — der Strang endet auf der Bildebene. | Repräsentationsleiter |
| **Q15** (`8 = ___ + ___`) | Zwischen den Feldern fehlt das **„+"**. Das Antwortlayout bildet die Aufgabe nicht ab. | Layout |
| **Q17** (alle Zerlegungen der 10) | Ebenfalls ohne „+". Zusätzlich offen: Was misst Q17, das Q15 nicht misst? Redundanz muss begründet oder das Item gestrichen werden. | Redundanz |
| **Q18** (Verdopplung von 4) | „Kim kennt die Zahl 4." ist dekoratives Beiwerk und gehört gestrichen. | Beiwerk |
| **Q20** (Zehner/Einer der 58) | Zwei unbeschriftete Kästchen — für ein Kind ist nicht erkennbar, was wohin gehört. Muss je Antwort eine eigene beschriftete Zeile sein: „Wie viele Zehner hat die Zahl [ ]" / „Wie viele Einer hat die Zahl [ ]". | Ein Item, eine Antwort |
| **Q22** (Stäbchen zusammen) | **Drei** Antwortfelder, obwohl die Antwort **41** ist. Es darf genau ein Feld geben. | Antwortfeld-Arität |
| **Q23** (Bündel öffnen) | Der Prompt spricht von „Stäbchen", die Darstellung zeigt seit der Umstellung **Würfel**. Außerdem soll sich die Zehnerstange sichtbar in **blaue Würfel** öffnen, idealerweise mit kleiner Lücke zu den bereits vorhandenen grünen. | Prompt ↔ Darstellung |
| **Q24** (Stellenwerttafel 47) | Weitgehend eine Dublette zu Q20 — nur besser umgesetzt. | Redundanz |
| **Q25** (Zahl aus der Tafel lesen) | Wieder sehr ähnlich. Der diagnostische Mehrwert der drei Stellenwert-Items ist nicht ausgewiesen. | Redundanz |
| **Q26** (Zahlenstrahl 0–100) | Der Pfeil zeigt **nach oben statt nach unten**. Und der Sprung direkt auf 0–100 ist für diese Altersgruppe zu groß: es braucht erst 0–10, dann 0–20, dann 0–100. | Darstellung + Zahlenraumleiter |
| **ab Q44** | „Wild zu kompliziert" — praktisch alle Items ab hier sind durch ihre Formulierung unbrauchbar. Deckt sich mit dem oben unabhängig erhobenen Befund zu den Items 44–53. | Itemformulierung |

### Was daraus systematisch folgt

1. **Ein Item, eine Antwort.** Q7, Q20 und Q22 zeigen dasselbe Muster: die Zahl der Antwortfelder und ihre Beschriftung passen nicht zur Frage. Für v2 gilt: eine Frage, ein beschriftetes Feld — oder zwei getrennte, je eigens beschriftete Zeilen.
2. **Prompt und Darstellung driften auseinander.** Q23 (Stäbchen/Würfel), Q15/Q17 (fehlendes „+"), Q26 (Pfeilrichtung): Itemtext und gerendertes Widget wurden getrennt gepflegt, und nichts hat sie gegeneinander geprüft.
3. **Konstrukttreue.** Simultanerfassung über 5 ist keine Simultanerfassung mehr (Q8) — und eine unstrukturierte, verschobene Anordnung misst ohnehin etwas anderes.
4. **Repräsentations- und Zahlenraumleiter fehlen.** Q11 bleibt ikonisch ohne symbolisches Gegenstück; Q26 springt ohne Zwischenstufen auf 0–100. Genau dafür hat die Deckungsmatrix eine Repräsentations- und eine Zahlenraumachse.
5. **Redundanz ohne ausgewiesenen Unterschied** (Q15/Q17, Q20/Q24/Q25): zwei Items derselben Zelle brauchen einen benannten diagnostischen Unterschied, sonst fällt eines weg.
6. **Kein Beiwerk** (Q18): jeder Satz, der nicht gemessen wird, ist Leselast.
7. **Der Schwierigkeitsverlauf** muss innerhalb eines Strangs monoton sein; Sprünge zwischen Nachbaritems sind ein eigener Befund.

Die Punkte 1, 2, 3 und 6 sind **maschinell prüfbar** und gehen als Regeln in `check_item_quality.py`
(v2-Entwurf §8). Die Punkte 4 und 5 sind Eigenschaften der Deckungsmatrix. Alle Darstellungsfehler
(Pfeilrichtung, Würfelfarbe beim Entbündeln, verschobene Reihen) wären von **Gate 2** — Jakob sieht das
Item im laufenden Kind-Screen — gefunden worden; v1 hatte dieses Gate nicht.
