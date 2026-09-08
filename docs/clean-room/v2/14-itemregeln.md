# 14 — Itemregeln (v2)

| | |
|---|---|
| **Status** | ✅ FREIGEGEBEN — Jakob, 2026-09-08 (Gate 1) |
| **Stand** | 2026-09-08 |
| **Owner** | Jakob |
| **Grundlage** | [v2-Entwurf](../../superpowers/specs/2026-09-07-diagnostik-v2-design.md) §5.1; [00-v1-assessment.md](../00-v1-assessment.md) Anhang A |
| **Gate** | `python scripts/check_item_quality.py` |

Abnahmekriterien für ein Diagnostik-Item. Jede Regel trägt einen Vermerk, wer sie prüft:
**maschinell** heißt, `check_item_quality.py` entscheidet sie; **Gate 1** heißt, nur Jakobs
Urteil entscheidet sie. Der Checker ist ein Boden, kein Ersatz — v1 hatte fünf grüne Gates
bei unbrauchbarem Instrument.

Jede Regel nennt den Defekt, wegen dem es sie gibt.

## Gate 1 — Freigabe

Jakob hat die Sprachgrenze am **2026-09-08** als Förderlehrer geprüft und freigegeben.

| Prüffrage | Antwort |
|---|---|
| I2 deckelt den Prompt bei zwölf Wörtern, I1 bei einem Satz. Richtige Grenze für ein Klasse-2-Förderkind — oder wird damit eine sinnvolle Aufgabe unsagbar? | ein einfacher Satz |

**Das maßgebliche Kriterium ist damit: ein Prompt ist ein einfacher Satz.** I1, I2 und I4
sind zusammen seine maschinenlesbare Zerlegung — *ein* Satz (I1), kurz genug zum Lesen
(I2), ohne Nebensatz und ohne ausgeschriebene Zahlwörter (I4). Die zwölf Wörter bleiben als
Näherung stehen; sie sind der Stellvertreter der Regel, nicht die Regel. Stößt beim
Schreiben der Items ein sachlich einfacher Satz an die zwölf, ist das ein Befund über die
Zahl und gehört gemeldet — nicht durch einen komplizierteren Satz umgangen.

## I1 — Eine Anweisung, ein Satz *(maschinell)*

Der Prompt enthält höchstens einen Satz. Gezählt wird an `.`, `?` und `!`.

*Defekt:* v1 Item 44 hatte sechs Sätze und 45 Wörter und hat dem Kind das Verfahren
diktiert.

## I2 — Höchstens zwölf Wörter *(maschinell)*

*Defekt:* dieselbe Familie, Items 44–53. Ein Klasse-2-Förderkind trägt diese Leselast nicht.

## I3 — Kein verratenes Verfahren *(maschinell)*

Verbotene Wendungen am Satzanfang oder als Teilsatz: `Zerlege`, `Rechne zuerst`,
`In der Tabelle stehen`, `Trage ein`, `Schreib sie so auf`, `Und wenn du`, `Sieh dir`,
`Denk daran`, `Nimm zuerst`, `Zähl in`. Wer die Strategie nennt, misst Gehorsam.

*Defekt:* v1 Item 15 („Schreib sie so auf: 8 = ___ + ___"), Item 44, Item 22.

## I4 — Keine Nebensätze, keine Zahlwörter *(maschinell)*

Verboten als eigenes Wort: `weil`, `wenn`, `damit`, `dass`, `nachdem`, `obwohl`, `während`.
Zahlen stehen als Ziffern, nicht als Wort (`8`, nicht `acht`).

*Grund:* Ohne Lehrkraft, die vorliest, konfundiert Lesefähigkeit die Messung. Der Prompt
wird zusätzlich gesprochen (I9), aber er muss auch gelesen tragen.

## I5 — Ein Item, eine Antwort *(maschinell)*

Die Schlüsselmenge von `antwortfelder` und `erwartete-antwort` ist identisch, und jedes
Feld trägt ein eigenes Label. Zwei Antworten heißen zwei Items oder zwei beschriftete
Zeilen — nie zwei nackte Kästchen.

*Defekt:* v1 Q7 („welche Zahl kommt vor der 37, und welche danach?" — `AnswerFormat: Single`,
zwei erwartete Zahlen), Q20, Q22.

## I6 — Prompt und Darstellung sind ein Artefakt *(maschinell)*

`darstellung` ist ein Schlüssel aus [15-darstellungen.md](15-darstellungen.md) oder `keine`;
die dort genannte Widget-Klasse existiert im Flutter-Quelltext. Ist `darstellung` gleich
`keine`, ist `darstellung-konfiguration` gleich `—`; sonst nicht leer.

*Defekt:* v1 fragte nach Stäbchen, während der Bildschirm Würfel zeigte, weil Text und
Widget getrennt gepflegt wurden.

## I7 — Simultanerfassung ist bei 5 gedeckelt *(maschinell)*

Bei einem Item des Strangs `anzahl-simultan` ist jede Zahl in `erwartete-antwort` höchstens
5. Darüber misst das Item Zählen, was immer es behauptet.

*Defekt:* v1s Subitizing-Item zeigte acht Objekte.

## I8 — Jedes Item nennt sein Fehlerbild *(maschinell, Inhalt Gate 1)*

`fehlersignatur` hat mindestens zwei Einträge, jeder in der Form `` `Antwort` — Bedeutung ``.
Der Förderplan und die Fehlermusteranalyse lesen beide dieses Feld. Ob die Bedeutung
stimmt, entscheidet Gate 1.

## I9 — Gesprochener Prompt *(maschinell)*

`audio` ist gesetzt und lautet `audio/v2/<item-id>.mp3`. Die Datei selbst entsteht in
Phase 5 (TTS zur Bauzeit); geprüft wird hier der Vertrag, nicht die Existenz.

## I10 — Verankerung in Konstrukt und Zelle *(maschinell)*

`konstrukt` steht in [11-konstruktkarte.md](11-konstruktkarte.md); `zelle` steht in der
Deckungsmatrix und lebt; Strang und Zahlenraum der Zelle stimmen mit dem Konstrukt überein;
`item-id` ist gleich dem Dateinamen und beginnt mit `<konstrukt>-`.

*Defekt:* v1s Independence-Sidecar hing an der Zeilennummer, sodass das Löschen eines Items
Zuordnungen still verschoben hat. Hier hängt alles an IDs.

## I11 — Zwei Items derselben Zelle brauchen einen benannten Unterschied *(Gate 1)*

Kann die Item-Datei nicht sagen, was dieses Item misst und das Geschwisteritem nicht, fliegt
eines. Maschinell nicht entscheidbar.

*Defekt:* v1 Q15/Q17 und Q20/Q24/Q25.

## I12 — Monotoner Schwierigkeitsverlauf im Strang *(Gate 1)*

Ein schweres Item mit trivialem Nachbarn ist für sich ein Defekt. Die Zahlenraumleiter wird
in der Reihenfolge gegangen, nie direkt in den ZR100. Die Reihenfolge selbst erzeugt der
Blueprint; ob der Verlauf sich für ein Kind richtig anfühlt, entscheidet Gate 1 — und
endgültig Gate 2 am laufenden Bildschirm.

## Was der Checker nicht kann

Ob ein Item das Konstrukt misst, ob das Fehlerbild dem entspricht, was Kinder tatsächlich
tun, ob die Aufgabe für ein Förderkind zumutbar ist: alles Gate 1 und Gate 2. Die
maschinellen Regeln oben fangen genau die Defektklassen ab, die v1 tatsächlich ausgeliefert
hat — mehr behaupten sie nicht.
