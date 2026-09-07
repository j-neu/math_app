# 10 — Deckungsmatrix (v2)

| | |
|---|---|
| **Status** | ✅ FREIGEGEBEN — Jakob, 2026-09-07 (Gate 1) |
| **Stand** | 2026-09-07 |
| **Owner** | Jakob |
| **Grundlage** | [v2-Entwurf](../../superpowers/specs/2026-09-07-diagnostik-v2-design.md) §4, §8 |
| **Gate** | `python scripts/check_deckung.py` |

Dieses Dokument ist das **Wurzelartefakt** des Inhaltsneubaus. Konstruktkarte, Blueprint,
Itembank und Übungskatalog werden aus ihm abgeleitet, nie umgekehrt. Eine Zelle ist erst
`freigegeben`, wenn sie ein Diagnostik-Item **und** eine Übung nennt; eine bewusst nicht
abgedeckte Zelle trägt `–` und braucht eine Begründung unter `Ausnahmen:`.

Grün heißt *abgedeckt*, nicht *dokumentiert*. Genau daran ist v1 gescheitert
(siehe [00-v1-assessment.md](../00-v1-assessment.md)).

**Lesart der Achsen.** Die Repräsentation bezeichnet, **worin die Aufgabe dem Kind begegnet**,
nicht worin es antwortet: *enaktiv* = das Kind handelt an Material (legen, schieben, bündeln,
Finger), *ikonisch* = das Kind arbeitet an einer Abbildung (Zwanzigerfeld, Hunderterfeld,
Zahlenstrahl, Punktebild), *symbolisch* = die Aufgabe steht in Ziffern und Zeichen. Der
Zahlenraum bezeichnet den Raum, in dem die Aufgabe spielt, nicht die Klassenstufe.

Die Spalte `übung:` verweist auf `exercise_id` aus
[inventory_uebungen.csv](inventory_uebungen.csv) — dem Bestand der handgebauten Engine.
`—` heißt: noch nichts zugeordnet. Der Zusatz `[alt, Triage offen]` heißt: die Übung
existiert im Altbestand und ist **Kandidat** für diese Zelle, aber noch nicht didaktisch
geprüft (v2-Entwurf §6).

## Befunde zum Übungsbestand

Drei Lücken sind beim Einlesen des Altbestands sichtbar geworden. Es sind Lücken im
**Bestand**, nicht in der Dokumentation, und sie gehören in die Phase-2-Planung:

1. **Halbieren fehlt vollständig.** Sechs Übungen decken das Verdoppeln ab (`S3.1`–`S3.6`),
   keine einzige die Umkehrrichtung.
2. **Rückwärtszählen gibt es nur am Hunderterfeld** (`C6.3`). Für ZR10 und ZR20 — dort, wo
   das Rückwärtszählen zuerst bricht — existiert nichts.
3. **`S2.3` (Gegensinniges Verändern) ist eine Hülle:** null Level-Widgets im Inventar. Die
   Übung ist angelegt, aber nie gebaut worden.

**Und die Größenordnung:** alle 27 Übungen des Altbestands finden eine Zelle, aber sie decken
zusammen nur **27 der 152 lebenden Zellen** ab. Sieben Stränge haben überhaupt keinen
Kandidaten — `anzahl-strukturiert`, `buendeln-entbuendeln`, `stellenwerttafel`,
`subtraktion-ohne-uebergang`, `subtraktion-mit-uebergang`, `addition-mit-uebergang`,
`sachsituationen`. Der Altbestand ist ein Fundament, kein Katalog: die Subtraktion fehlt in
ihm vollständig.

## Vokabular

**Stränge:**
- `zaehlen-vorwaerts` — Vorwärtszählen von beliebigem Startpunkt, mit Dekadenwechsel
- `zaehlen-rueckwaerts` — Rückwärtszählen von beliebigem Startpunkt, mit Dekadenwechsel
- `zaehlen-schritte` — Zählen in Schritten (2er, 5er, 10er), vorwärts wie rückwärts
- `vorgaenger-nachfolger` — Vorgänger und Nachfolger einer Zahl nennen, ohne zu zählen
- `anzahl-simultan` — Anzahlen bis 5 auf einen Blick erfassen, ohne Zählhandlung
- `anzahl-strukturiert` — größere Anzahlen über Struktur erfassen (Fünfer, Zehner, Bündel)
- `anzahl-vergleich` — mehr, weniger, gleich viele an Mengen entscheiden
- `zahlvergleich-ordnen` — Zahlen vergleichen und der Größe nach ordnen
- `zerlegung` — Zahlen in Teilmengen zerlegen und aus Teilmengen zusammensetzen
- `verdoppeln-halbieren` — Verdoppeln und Halbieren als abrufbare Beziehung, nicht als Rechenweg
- `buendeln-entbuendeln` — zehn Einer zu einem Zehner bündeln und wieder entbündeln
- `stellenwerttafel` — Ziffernwert und Stellenwert unterscheiden, Zahlen in Z und E zerlegen
- `zahlenstrahl` — Zahlen am Strahl verorten, ablesen und Abstände deuten
- `addition-ohne-uebergang` — addieren ohne Überschreiten der Zehnergrenze
- `addition-mit-uebergang` — addieren über die Zehnergrenze
- `subtraktion-ohne-uebergang` — subtrahieren ohne Unterschreiten der Zehnergrenze
- `subtraktion-mit-uebergang` — subtrahieren über die Zehnergrenze
- `ergaenzen` — zu einem Zielwert ergänzen, Subtraktion als Ergänzung deuten
- `flexibles-rechnen` — zwischen Rechenwegen wählen und Aufgaben aus Nachbaraufgaben ableiten
- `sachsituationen` — aus einer Situation die passende Rechnung gewinnen und zurückdeuten

**Zahlenräume:** ZR10 · ZR20 · ZR100
**Repräsentationen:** enaktiv · ikonisch · symbolisch
**Status:** offen · entworfen · freigegeben · – (bewusst nicht abgedeckt)

## Strang: zaehlen-vorwaerts

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | offen |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

### zaehlen-vorwaerts × ZR10 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1 Zahlen und Operationen, Niveaustufe A; Krajewski, Zahlwortreihe als Vorläuferfertigkeit
- **fehlerbild:** Kind verletzt die Eins-zu-eins-Zuordnung — es tippt schneller als es zählt oder erfasst Objekte doppelt; oder es sagt die Zahlwortreihe korrekt auf, ohne sie mit dem Zeigen zu koppeln
- **diagnostik:** —
- **übung:** C1.2 [alt, Triage offen]

### zaehlen-vorwaerts × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; KMK Bildungsstandards Primarbereich (2022), Leitidee Zahlen und Operationen
- **fehlerbild:** Kind verliert im ungeordneten Punktebild die Übersicht, weil es keine Merkstrategie hat (kein Abhaken, kein systematischer Weg) — das Ergebnis schwankt bei Wiederholung derselben Abbildung
- **diagnostik:** —
- **übung:** C1.1 [alt, Triage offen]

### zaehlen-vorwaerts × ZR10 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Kind kann die Zahlwortreihe nur von 1 an aufsagen; ein Start bei 6 zwingt es zum stillen Neuanlauf — erkennbar an langer Latenz vor dem ersten Zahlwort
- **diagnostik:** —
- **übung:** —

### zaehlen-vorwaerts × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Schipper, Handbuch (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind zählt über die Zehn hinweg in Einern weiter, ohne die Zehn als erreichte Einheit zu markieren; beim Legen entsteht keine Fünfer- oder Zehnerstruktur
- **diagnostik:** —
- **übung:** —

### zaehlen-vorwaerts × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Kind zählt am Zwanzigerfeld jedes Feld einzeln ab, statt die volle erste Reihe als Zehn zu lesen — die Struktur des Feldes bleibt ungenutzt
- **diagnostik:** —
- **übung:** C1.1 [alt, Triage offen]

### zaehlen-vorwaerts × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Der Dekadenwechsel bricht: nach 19 folgt eine Neubildung wie „zwanzigeins" oder ein Rücksprung auf 10; die Zehnerstelle wird beim Weiterzählen nicht mitgeführt
- **diagnostik:** —
- **übung:** C3.1 [alt, Triage offen]

### zaehlen-vorwaerts × ZR100 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz, Bündelung bei rechenschwachen Kindern
- **fehlerbild:** Kind legt beim Weiterzählen über die Dekade keine neue Zehnerstange, sondern häuft Einer an — die Bündelung wird beim Zählen nicht vollzogen
- **diagnostik:** —
- **übung:** —

### zaehlen-vorwaerts × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Am Hunderterfeld springt das Kind beim Zeilenwechsel (von 39 auf 40) in die falsche Zeile oder Spalte; die Zeilenstruktur wird nicht als Zehnerstruktur gelesen
- **diagnostik:** —
- **übung:** C6.0 [alt, Triage offen]

### zaehlen-vorwaerts × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; KMK Bildungsstandards Primarbereich (2022)
- **fehlerbild:** Kind zählt innerhalb einer Dekade sicher, verliert aber den Dekadenwechsel (nach 59 folgt 50 oder 70); die Zehnerreihe selbst ist nicht abrufbar
- **diagnostik:** —
- **übung:** C3.2, C3.3 [alt, Triage offen]

## Strang: zaehlen-rueckwaerts

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | offen |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

### zaehlen-rueckwaerts × ZR10 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Wartha/Schulz, Rückwärtszählen als Voraussetzung der Subtraktion (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind nimmt Plättchen weg, muss aber nach jedem Wegnehmen den Rest neu von 1 an abzählen — die rückwärts laufende Zahlwortreihe trägt nicht
- **diagnostik:** —
- **übung:** —

### zaehlen-rueckwaerts × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Kind liest die abgebildete Reihe nur vorwärts und zählt zur Bestimmung des vorangehenden Feldes jedes Mal von links neu an
- **diagnostik:** —
- **übung:** —

### zaehlen-rueckwaerts × ZR10 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Selter/Spiegel, zählendes Rechnen
- **fehlerbild:** Kind bildet die Rückwärtsreihe, indem es innerlich vorwärts zählt und den Vorgänger abliest — sehr lange Latenz pro Schritt, Abbrüche im Bereich 7 bis 5
- **diagnostik:** —
- **übung:** —

### zaehlen-rueckwaerts × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Beim Wegnehmen über die Zehn hinweg (von 12 auf 8) löst das Kind die Zehnerstruktur nicht auf, sondern legt die ganze Menge neu
- **diagnostik:** —
- **übung:** —

### zaehlen-rueckwaerts × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Am Zwanzigerfeld wird rückwärts Feld für Feld abgezählt, statt die volle Zehnerreihe als einen Sprung zu nutzen
- **diagnostik:** —
- **übung:** —

### zaehlen-rueckwaerts × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Der Dekadenwechsel abwärts bricht: nach 20 folgt 10 oder 21; die Zehnerstelle wird beim Rückwärtszählen nicht mitgeführt
- **diagnostik:** —
- **übung:** —

### zaehlen-rueckwaerts × ZR100 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz, Entbündeln
- **fehlerbild:** Kind entbündelt beim Rückwärtszählen über die Dekade nicht (von 40 auf 39 bleibt die Zehnerstange liegen), sondern nimmt einen ganzen Zehner weg
- **diagnostik:** —
- **übung:** —

### zaehlen-rueckwaerts × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Am Hunderterfeld läuft das Kind beim Rückwärtsgehen in die falsche Richtung der Zeile oder überspringt den Zeilenwechsel bei 30 auf 29
- **diagnostik:** —
- **übung:** C6.3 [alt, Triage offen]

### zaehlen-rueckwaerts × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Kind kann die Zehnerreihe abwärts (100, 90, 80 …) nicht abrufen und zählt in Einern zurück — die Aufgabe wird zur Zählstrecke statt zum Zehnerschritt
- **diagnostik:** —
- **übung:** —

## Strang: zaehlen-schritte

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | offen |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

### zaehlen-schritte × ZR10 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Padberg/Benz, Zählen in Schritten als Vorbereitung der Multiplikation (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind schiebt beim Zweierschritt einzeln statt paarweise und zählt dazwischen still in Einern weiter — der Schritt ist keine Einheit, sondern eine abgezählte Strecke
- **diagnostik:** —
- **übung:** —

### zaehlen-schritte × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Kind erkennt im Bild die Paarstruktur nicht und zählt alle Elemente einzeln; die Zweierreihe wird nicht als Muster gelesen
- **diagnostik:** —
- **übung:** —

### zaehlen-schritte × ZR10 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Kind kann 2, 4, 6, 8, 10 nur aufsagen, wenn es die ungeraden Zahlen still mitspricht — Latenz pro Schritt wie beim Einerzählen
- **diagnostik:** —
- **übung:** —

### zaehlen-schritte × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Schipper, Handbuch (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Beim Fünferschritt am Material nutzt das Kind die Fünferstruktur nicht, sondern legt fünfmal einen Einer — bei 15 bricht die Reihe
- **diagnostik:** —
- **übung:** —

### zaehlen-schritte × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Kind markiert im Zwanzigerfeld die Schritte, verliert aber beim Übergang von der ersten in die zweite Reihe die Schrittweite (nach 10 folgt 11 statt 12)
- **diagnostik:** —
- **übung:** —

### zaehlen-schritte × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Die Zweierreihe trägt bis 10 und bricht am Zehnerübergang; oder das Kind wechselt unbemerkt die Schrittweite, sobald die Zahlen zweistellig werden
- **diagnostik:** —
- **übung:** C6.1 [alt, Triage offen]

### zaehlen-schritte × ZR100 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz, Zehnerstruktur
- **fehlerbild:** Kind legt beim Zehnerschritt zehn Einer statt einer Zehnerstange — der Zehner ist noch keine handhabbare Einheit
- **diagnostik:** —
- **übung:** —

### zaehlen-schritte × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Am Hunderterfeld wird der Zehnerschritt nicht als Zeilensprung erkannt; das Kind zählt die zehn Felder der Zeile einzeln ab, um von 23 auf 33 zu kommen
- **diagnostik:** —
- **übung:** C6.0, C6.2 [alt, Triage offen]

### zaehlen-schritte × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; KMK Bildungsstandards Primarbereich (2022)
- **fehlerbild:** Zehnerschritte gelingen nur von einer glatten Zehnerzahl aus; von 23 aus in Zehnerschritten weiterzugehen misslingt, weil die Einerstelle nicht konstant gehalten wird
- **diagnostik:** —
- **übung:** —

## Strang: vorgaenger-nachfolger

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | offen |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

### vorgaenger-nachfolger × ZR10 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Krajewski, Zahl-Größen-Verknüpfung
- **fehlerbild:** Kind kann zu einer gelegten Menge nicht „einer mehr" legen, ohne die neue Menge vollständig neu abzuzählen
- **diagnostik:** —
- **übung:** —

### vorgaenger-nachfolger × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Kind bestimmt am Bild den Nachfolger richtig, den Vorgänger aber nicht — die Richtung „eins weniger" ist nicht verfügbar
- **diagnostik:** —
- **übung:** —

### vorgaenger-nachfolger × ZR10 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Wartha/Schulz (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind ermittelt Vorgänger und Nachfolger durch Aufsagen der Reihe ab 1 statt durch direkten Zugriff — lange Latenz, und der Vorgänger dauert deutlich länger als der Nachfolger
- **diagnostik:** —
- **übung:** —

### vorgaenger-nachfolger × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Am Material gelingt „einer mehr" innerhalb der Reihe, bricht aber genau am Zehnerübergang (von 10 auf 11, von 19 auf 20)
- **diagnostik:** —
- **übung:** —

### vorgaenger-nachfolger × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Kind verwechselt am abgebildeten Zahlenband Vorgänger und Nachfolger, weil es die Leserichtung nicht mit „mehr" und „weniger" koppelt
- **diagnostik:** —
- **übung:** —

### vorgaenger-nachfolger × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Vorgänger und Nachfolger werden zu 10 und 20 hin unsicher; Antworten wie „Vorgänger von 20 ist 10" zeigen, dass die Zehnerzahl als Block und nicht als Position gedacht wird
- **diagnostik:** —
- **übung:** C4.1, C5.1 [alt, Triage offen]

### vorgaenger-nachfolger × ZR100 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz, Entbündeln
- **fehlerbild:** Der Vorgänger einer glatten Zehnerzahl verlangt Entbündeln; das Kind nimmt stattdessen eine ganze Zehnerstange weg und landet bei 30 statt bei 39
- **diagnostik:** —
- **übung:** —

### vorgaenger-nachfolger × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Am Hunderterfeld wird der Nachfolger über den Zeilenwechsel hinweg falsch gegriffen — das Kind geht eine Zeile tiefer statt ein Feld weiter
- **diagnostik:** —
- **übung:** —

### vorgaenger-nachfolger × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Vorgänger und Nachfolger gelingen innerhalb der Dekade, brechen aber an ihren Rändern (69/70, 100); außerdem wird nur eine der beiden Richtungen abgefragt beantwortet, wenn beide verlangt sind
- **diagnostik:** —
- **übung:** C5.1 [alt, Triage offen]

## Strang: anzahl-simultan

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | – |
| ZR20 | – | – | – |
| ZR100 | – | – | – |

**Ausnahmen:**
- `anzahl-simultan × ZR10 × symbolisch` — Simultanerfassung ist eine Wahrnehmungsleistung an einer Menge; eine Ziffer wird gelesen, nicht auf einen Blick erfasst. Symbolisch existiert dieses Konstrukt nicht.
- `anzahl-simultan × ZR20 × enaktiv` — Simultanerfassung ist definitionsgemäß auf etwa vier bis fünf Elemente begrenzt; oberhalb davon wird strukturiert erfasst, nicht simultan. Dafür ist `anzahl-strukturiert` zuständig.
- `anzahl-simultan × ZR20 × ikonisch` — Simultanerfassung ist definitionsgemäß auf etwa vier bis fünf Elemente begrenzt; oberhalb davon wird strukturiert erfasst, nicht simultan. Dafür ist `anzahl-strukturiert` zuständig.
- `anzahl-simultan × ZR20 × symbolisch` — Simultanerfassung ist definitionsgemäß auf etwa vier bis fünf Elemente begrenzt, und eine Ziffer wird ohnehin gelesen statt erfasst.
- `anzahl-simultan × ZR100 × enaktiv` — Simultanerfassung ist definitionsgemäß auf etwa vier bis fünf Elemente begrenzt; im Hunderterraum ist sie ohne Struktur ausgeschlossen.
- `anzahl-simultan × ZR100 × ikonisch` — Simultanerfassung ist definitionsgemäß auf etwa vier bis fünf Elemente begrenzt; im Hunderterraum ist sie ohne Struktur ausgeschlossen.
- `anzahl-simultan × ZR100 × symbolisch` — Simultanerfassung ist definitionsgemäß auf etwa vier bis fünf Elemente begrenzt, und eine Ziffer wird ohnehin gelesen statt erfasst.

> Die Deckelung bei fünf ist eine direkte Konsequenz aus Anhang A des v1-Assessments (Q8):
> v1 hat Simultanerfassung mit Anzahlen weit über fünf und an strukturiertem Material geprüft
> und damit ein anderes Konstrukt gemessen als das benannte.

### anzahl-simultan × ZR10 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Krajewski, Anzahlerfassung als Vorläuferfertigkeit
- **fehlerbild:** Kind zählt auch bei drei oder vier Fingern einzeln ab (sichtbares Tippen oder Lippenbewegung) — die Anzahl wird nicht auf einen Blick, sondern zählend bestimmt
- **diagnostik:** —
- **übung:** S1.1 [alt, Triage offen]

### anzahl-simultan × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Krajewski (Blitzblick-Aufgaben)
- **fehlerbild:** Bei kurzer Darbietung nennt das Kind eine Zahl aus dem richtigen Bereich, aber nicht die richtige (rät); bei längerer Darbietung wird es sicher — der Unterschied zwischen beiden Bedingungen ist das eigentliche Signal
- **diagnostik:** —
- **übung:** —

## Strang: anzahl-strukturiert

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | – |
| ZR20 | offen | offen | – |
| ZR100 | offen | offen | – |

**Ausnahmen:**
- `anzahl-strukturiert × ZR10 × symbolisch` — Anzahlerfassung setzt eine wahrnehmbare Menge voraus; in Ziffern gibt es keine Struktur zu erfassen. Der symbolische Zugriff auf Zahlen liegt bei `stellenwerttafel` und `zahlvergleich-ordnen`.
- `anzahl-strukturiert × ZR20 × symbolisch` — Anzahlerfassung setzt eine wahrnehmbare Menge voraus; in Ziffern gibt es keine Struktur zu erfassen.
- `anzahl-strukturiert × ZR100 × symbolisch` — Anzahlerfassung setzt eine wahrnehmbare Menge voraus; in Ziffern gibt es keine Struktur zu erfassen.

### anzahl-strukturiert × ZR10 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Schipper, Handbuch (Fünferstruktur, Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind nutzt die Fünferstruktur des Materials nicht: bei sieben gelegten Plättchen zählt es alle sieben ab, statt fünf zu sehen und zwei dazuzuzählen
- **diagnostik:** —
- **übung:** —

### anzahl-strukturiert × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Im strukturierten Punktebild (Würfelbild, Fünferreihe) wird trotz Struktur einzeln gezählt; das Kind erkennt das Muster nicht wieder, wenn es gedreht dargeboten wird
- **diagnostik:** —
- **übung:** —

### anzahl-strukturiert × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Schipper, Handbuch (Rechenschiffchen/Rekenrek)
- **fehlerbild:** Kind schiebt am Rekenrek Perle für Perle, statt die Fünfer- und Zehnerblöcke in einem Zug zu bewegen — die Struktur des Geräts wird als Zählhilfe statt als Gliederung benutzt
- **diagnostik:** —
- **übung:** —

### anzahl-strukturiert × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Am abgebildeten Zwanzigerfeld wird die volle Zehnerreihe nicht als Zehn gelesen; das Kind zählt bis 20 durch und macht dabei Fehler in der zweiten Reihe
- **diagnostik:** —
- **übung:** —

### anzahl-strukturiert × ZR100 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz, Bündelung und Stellenwert
- **fehlerbild:** Kind bestimmt eine aus Stangen und Einern gelegte Zahl, indem es alle Einer der Stangen mitzählt — die Zehnerstange ist noch keine Einheit, sondern zehn nebeneinanderliegende Dinge
- **diagnostik:** —
- **übung:** —

### anzahl-strukturiert × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Am abgebildeten Hunderterfeld wird die Anzahl markierter Felder zeilenweise falsch aufsummiert, weil volle Zeilen nicht als Zehner verrechnet, sondern nachgezählt werden
- **diagnostik:** —
- **übung:** —

## Strang: anzahl-vergleich

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | offen |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

### anzahl-vergleich × ZR10 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Krajewski, Mengenvergleich
- **fehlerbild:** Kind entscheidet nach dem Platzbedarf statt nach der Anzahl — die weiter auseinandergelegte Menge gilt als die größere, auch wenn beide gleich viele sind
- **diagnostik:** —
- **übung:** —

### anzahl-vergleich × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Im Bild wird die längere Reihe als die größere Menge gelesen; eine Eins-zu-eins-Zuordnung zwischen den Reihen wird nicht gesucht
- **diagnostik:** —
- **übung:** —

### anzahl-vergleich × ZR10 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; KMK Bildungsstandards Primarbereich (2022)
- **fehlerbild:** Kind kann zwei gezeigte Mengen vergleichen, aber nicht zwei genannte Zahlen — die Zahl trägt noch keine Größenvorstellung
- **diagnostik:** —
- **übung:** —

### anzahl-vergleich × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Kind entscheidet „mehr" richtig, kann aber das „wie viel mehr" nicht am Material zeigen — der Unterschied ist keine eigene Menge
- **diagnostik:** —
- **übung:** S1.4 [alt, Triage offen]

### anzahl-vergleich × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Bei zwei belegten Zwanzigerfeldern zählt das Kind beide vollständig ab, statt die unterschiedlich weit gefüllten Reihen zu vergleichen
- **diagnostik:** —
- **übung:** —

### anzahl-vergleich × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Der Vergleich gelingt innerhalb der Zehn und bricht darüber (13 gilt als kleiner als 9, weil nur die Einerziffer verglichen wird)
- **diagnostik:** —
- **übung:** —

### anzahl-vergleich × ZR100 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz
- **fehlerbild:** Zwei gelegte Zahlen werden über die Gesamtzahl der Teile verglichen statt über die Zehner: vier Einer plus zwei Stangen gelten als „mehr" als drei Stangen
- **diagnostik:** —
- **übung:** —

### anzahl-vergleich × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Am Hunderterfeld wird die dichter wirkende Markierung als die größere Anzahl gelesen; die Zeilenstruktur wird zum Vergleich nicht genutzt
- **diagnostik:** —
- **übung:** —

### anzahl-vergleich × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Kind vergleicht zweistellige Zahlen stellenweise von rechts (47 gilt als größer als 52, weil 7 größer als 2 ist) — der Stellenwert steuert den Vergleich noch nicht
- **diagnostik:** —
- **übung:** —

## Strang: zahlvergleich-ordnen

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | offen |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

> Dieser Strang existiert, weil v1 dafür **kein einziges Konstrukt** hatte (v1-Assessment,
> Anhang A). Ordnen ist mehr als paarweises Vergleichen: es verlangt, mehrere Zahlen
> zueinander in Beziehung zu setzen.

### zahlvergleich-ordnen × ZR10 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Kind legt Zahlkarten paarweise richtig, bringt aber vier Karten nicht in eine Reihe — jede neue Karte wird nur mit der zuletzt gelegten verglichen
- **diagnostik:** —
- **übung:** —

### zahlvergleich-ordnen × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Kind ordnet Mengenbilder nach Größe der Abbildung statt nach Anzahl der Elemente
- **diagnostik:** —
- **übung:** —

### zahlvergleich-ordnen × ZR10 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; KMK Bildungsstandards Primarbereich (2022)
- **fehlerbild:** Kind ordnet, indem es die Zahlwortreihe von 1 an durchgeht und die genannten Zahlen abhakt — richtig, aber zählend; sichtbar an der Latenz bei großen Zahlen der Auswahl
- **diagnostik:** —
- **übung:** —

### zahlvergleich-ordnen × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Beim Ordnen von Zahlkarten über die Zehn hinweg werden 12 und 21 vertauscht — die Ziffernfolge wird gelesen, nicht der Zahlwert
- **diagnostik:** —
- **übung:** C2.1 [alt, Triage offen]

### zahlvergleich-ordnen × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Kind ordnet abgebildete Mengen richtig, solange die Zehnerstruktur sichtbar bleibt, und scheitert bei unstrukturierter Darstellung derselben Anzahlen
- **diagnostik:** —
- **übung:** —

### zahlvergleich-ordnen × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Die Ordnung stimmt innerhalb der Zehner und bricht am Übergang; 20 wird ans Ende gestellt, weil es als „neue Reihe" und nicht als Zahl behandelt wird
- **diagnostik:** —
- **übung:** —

### zahlvergleich-ordnen × ZR100 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Beim Ordnen gelegter Zahlen zählt das Kind jede Zahl vollständig ab, statt zuerst die Zehnerstangen zu vergleichen
- **diagnostik:** —
- **übung:** —

### zahlvergleich-ordnen × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Am Zahlenstrahl oder Hunderterfeld ordnet das Kind nach der Position, die es zuerst findet, und korrigiert nicht, wenn die Reihenfolge dadurch widersprüchlich wird
- **diagnostik:** —
- **übung:** —

### zahlvergleich-ordnen × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz, Stellenwertverständnis
- **fehlerbild:** Zahlen mit gleicher Zehnerziffer werden nach der Einerziffer richtig geordnet, Zahlen mit vertauschten Ziffern (36 und 63) dagegen nicht — der Stellenwert steuert die Ordnung nicht
- **diagnostik:** —
- **übung:** —

## Strang: zerlegung

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | offen |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

> **Zwei Items in der Zelle `ZR10 × symbolisch`, mit benanntem Unterschied.** Anhang A hält
> zu Q15 und Q17 fest, dass Redundanz begründet werden muss. Der Unterschied ist: Q15 misst den
> **Abruf einer** Zerlegung, Q17 die **Systematik aller** Zerlegungen einer Zahl (findet das Kind
> sie vollständig und geordnet?). Das sind zwei Fähigkeiten, und beide gehören in diese Zelle.
> Ein drittes Item derselben Art fällt weg.

### zerlegung × ZR10 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Wartha/Schulz, Zahlzerlegung als Kern der Ablösung vom zählenden Rechnen (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind findet eine Zerlegung, aber keine zweite, ohne die Menge neu zu legen; die Zerlegungen einer Zahl bilden noch kein System
- **diagnostik:** —
- **übung:** S1.2 [alt, Triage offen]

### zerlegung × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Im Bild wird die verdeckte Teilmenge durch Abzählen der sichtbaren und Weiterzählen bestimmt statt durch Abruf der Zerlegung
- **diagnostik:** —
- **übung:** Z1 [alt, Triage offen]

### zerlegung × ZR10 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Selter/Spiegel
- **fehlerbild:** Die Zerlegungen der 10 sind nicht automatisiert: auf „7 und wie viel sind 10?" folgt zählendes Ergänzen mit langer Latenz statt sofortiger Nennung
- **diagnostik:** —
- **übung:** Z1 [alt, Triage offen]

### zerlegung × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Kind zerlegt 14 nicht in 10 und 4, sondern in beliebige Teile, die es einzeln abzählt — die Zehn ist keine bevorzugte Teilmenge
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Am Zwanzigerfeld wird die Zerlegung in volle Zehnerreihe und Rest nicht abgelesen; das Kind zählt beide Teile einzeln
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Die Zerlegung in Zehner und Einer (14 = 10 + 4) gelingt, die nicht-dekadische (14 = 8 + 6) nicht — Zerlegen ist an die Stellenschreibweise gebunden statt an die Zahl
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR100 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz
- **fehlerbild:** Kind zerlegt 60 in Stangen nur als 60 = 60, findet aber 60 = 40 + 20 nicht, ohne alle Einer nachzuzählen
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Am Hunderterfeld wird eine Zahl nicht in Zehner und Einer zerlegt gesehen; die Markierung wird als eine ungegliederte Fläche gelesen
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Padberg/Benz (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind zerlegt 46 in 40 und 6, kann aber 46 nicht als 30 und 16 denken — die Zerlegung ist auf die Stellenschreibweise festgelegt und für das Rechnen nicht beweglich
- **diagnostik:** —
- **übung:** —

## Strang: verdoppeln-halbieren

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | offen |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

> Der Bereich, den v1 in ZR20 nur indirekt und in ZR100 gar nicht erfasst hat. Das Halbieren
> hat im Altbestand **keine einzige** Übung (siehe Befunde oben); die `übung:`-Felder decken
> deshalb nur die Verdopplungsrichtung ab.

### verdoppeln-halbieren × ZR10 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Padberg/Benz, Verdoppeln als Kernaufgabe (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind legt die zweite Menge nicht parallel zur ersten, sondern zählt die Gesamtmenge anschließend von 1 an ab; die Verdopplung wird als Zählaufgabe behandelt statt als Struktur
- **diagnostik:** —
- **übung:** S3.3 [alt, Triage offen]

### verdoppeln-halbieren × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Krajewski, Anzahlerfassung strukturierter Mengen
- **fehlerbild:** Kind liest die gespiegelte Menge nicht als Kopie der ersten, sondern zählt alle abgebildeten Punkte einzeln; alternativ nennt es die Ausgangszahl statt des Doppelten
- **diagnostik:** —
- **übung:** S3.1 [alt, Triage offen]

### verdoppeln-halbieren × ZR10 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A (Kernaufgaben); Wartha/Schulz, Ablösung vom zählenden Rechnen (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** 4+4 wird zählend gelöst — lange Latenz, gehäufte ±1-Fehler; die Kernaufgabe ist nicht abrufbar, sondern wird jedes Mal neu errechnet
- **diagnostik:** —
- **übung:** —

### verdoppeln-halbieren × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Schipper, Handbuch (Rechenschiffchen, Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind nutzt die Fünferstruktur des Rechenschiffchens nicht: bei 7+7 kein Zugriff auf 5+5 und 2+2, stattdessen Einzelbelegung und Abzählen der Gesamtmenge
- **diagnostik:** —
- **übung:** S3.4, S3.5 [alt, Triage offen]

### verdoppeln-halbieren × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Padberg/Benz, Zehnerübergang (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind zählt am abgebildeten Zwanzigerfeld weiter, statt die zweite Reihe als Kopie der ersten zu lesen; der Zehnerübergang beim Verdoppeln (8+8) wird zählend überbrückt
- **diagnostik:** —
- **übung:** S3.2 [alt, Triage offen]

### verdoppeln-halbieren × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Selter/Spiegel, denkendes gegen zählendes Rechnen
- **fehlerbild:** Verdopplungen bis 10+10 sind nicht automatisiert; Nachbaraufgaben werden nicht abgeleitet (7+8 wird neu gerechnet statt über 7+7+1) — erkennbar an gleich langer Latenz für Kern- und Nachbaraufgabe
- **diagnostik:** —
- **übung:** —

### verdoppeln-halbieren × ZR100 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz, Bündelung und Stellenwert
- **fehlerbild:** Kind verdoppelt Zehnerstangen zählend statt bündelweise; beim Halbieren einer Zehnerzahl mit ungerader Zehnerziffer (50 zu 25) wird nicht umgebündelt, das Ergebnis bleibt bei „zweieinhalb Stangen" stehen
- **diagnostik:** —
- **übung:** —

### verdoppeln-halbieren × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Schipper, Handbuch (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Am Hunderterfeld oder am Zahlenstrahl wird die Verdopplung als Weiterzählen in Einerschritten dargestellt; dass der zweite Sprung genauso lang ist wie der erste, wird nicht erkannt
- **diagnostik:** —
- **übung:** —

### verdoppeln-halbieren × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B (halbschriftliche Strategien); Padberg/Benz (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** 25+25 wird stellenweise neu ausgerechnet, statt die Verdopplung abzurufen; bei 26+26 werden Zehner und Einer getrennt verdoppelt und der Übertrag geht verloren (Antwort 412 statt 52)
- **diagnostik:** —
- **übung:** S3.6 [alt, Triage offen]

## Strang: buendeln-entbuendeln

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | – |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

**Ausnahmen:**
- `buendeln-entbuendeln × ZR10 × symbolisch` — Im Zehnerraum gibt es genau eine Bündelung, und ihre Schreibweise (10 = 1 Zehner, 0 Einer) trägt keine Unterscheidung. Symbolisch wird das Bündeln erst ab ZR20 prüfbar.

### buendeln-entbuendeln × ZR10 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Moser Opitz, Bündelung bei rechenschwachen Kindern
- **fehlerbild:** Kind zählt zehn Einer richtig ab, tauscht sie aber nicht gegen eine Zehnerstange — der Tausch gilt als Verlust von neun Dingen statt als Umformung derselben Menge
- **diagnostik:** —
- **übung:** —

### buendeln-entbuendeln × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Im Bild wird die eingekreiste Zehnergruppe als „eins" mitgezählt, so dass zehn Einer und ein Zehnerbündel zusammen als elf gelesen werden
- **diagnostik:** —
- **übung:** —

### buendeln-entbuendeln × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Beim Entbündeln (eine Stange gegen zehn Einer) verliert das Kind die Gesamtmenge aus dem Blick und zählt anschließend alles neu ab
- **diagnostik:** —
- **übung:** —

### buendeln-entbuendeln × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Kind liest ein Bild aus einem Zehnerbündel und Einern nicht als zweistellige Zahl, sondern zählt die Einer des Bündels mit ab
- **diagnostik:** —
- **übung:** —

### buendeln-entbuendeln × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** „Wie viele Zehner sind in 17?" wird mit 17 oder mit 7 beantwortet — die Frage nach dem Bündel wird als Frage nach der Ziffer gelesen
- **diagnostik:** —
- **übung:** —

### buendeln-entbuendeln × ZR100 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz
- **fehlerbild:** Kind legt 43 als 43 Einer, statt vier Stangen und drei Einer zu nehmen; oder es bündelt beim Überschreiten der Zehn nicht nach und behält elf Einer liegen
- **diagnostik:** —
- **übung:** —

### buendeln-entbuendeln × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Im Bild aus Stangen und Einern wird die Anzahl der Teile genannt (sieben) statt der dargestellten Zahl (43) — Bündel und Einzelding werden gleich gewertet
- **diagnostik:** —
- **übung:** —

### buendeln-entbuendeln × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; KMK Bildungsstandards Primarbereich (2022)
- **fehlerbild:** „Wie viele Zehner hat 43?" wird richtig beantwortet, „wie viele Einer hat 43?" dagegen mit 3 statt 43 — je nach Lesart der Frage; die Unterscheidung Ziffernwert/Gesamtzahl ist unklar
- **diagnostik:** —
- **übung:** —

## Strang: stellenwerttafel

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | – | – | – |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

**Ausnahmen:**
- `stellenwerttafel × ZR10 × enaktiv` — Eine Stellenwerttafel verlangt mindestens zwei zu unterscheidende Stellen; im Zehnerraum gibt es außer der 10 selbst keine zweistellige Zahl zu legen.
- `stellenwerttafel × ZR10 × ikonisch` — Eine Stellenwerttafel verlangt mindestens zwei zu unterscheidende Stellen; im Zehnerraum gibt es dafür keine Beispiele außer der 10.
- `stellenwerttafel × ZR10 × symbolisch` — Eine Stellenwerttafel verlangt mindestens zwei zu unterscheidende Stellen; im Zehnerraum gibt es dafür keine Beispiele außer der 10.

> Hier liegen die v1-Items Q20, Q22, Q24 und Q25 (Anhang A). Der dortige Befund — vier
> Items für dieselbe Sache, davon eines mit drei Antwortfeldern für eine Antwort — ist eine
> Frage der Itemkonstruktion; abgedeckt werden muss die Zelle trotzdem, und zwar in beiden
> Richtungen: Zahl zu Stellen und Stellen zu Zahl.

### stellenwerttafel × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Moser Opitz, Stellenwertverständnis
- **fehlerbild:** Kind legt zu 17 sieben Einer in die Zehnerspalte und einen in die Einerspalte — die Spalte wird nach der Schreibrichtung der Ziffern belegt, nicht nach dem Wert
- **diagnostik:** —
- **übung:** —

### stellenwerttafel × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Kind liest eine abgebildete Tafel richtig, kann aber zu einem Bild aus Stange und Einern die Tafel nicht ausfüllen — die Übersetzung läuft nur in eine Richtung
- **diagnostik:** —
- **übung:** —

### stellenwerttafel × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Bei 1 Zehner und 3 Einern schreibt das Kind 31 — die Ziffern werden in der Reihenfolge der Nennung notiert statt nach Stellenwert
- **diagnostik:** —
- **übung:** —

### stellenwerttafel × ZR100 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz
- **fehlerbild:** Kind legt zu 52 fünf Einer und zwei Stangen (Ziffern in der Lesereihenfolge auf die Spalten verteilt) — die Zahlendreher zeigen sich am Material genauso wie in der Schrift
- **diagnostik:** —
- **übung:** —

### stellenwerttafel × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Aus einer abgebildeten Tafel wird die Zahl gebildet, indem die Anzahl aller Plättchen genannt wird (7 für 5 Zehner und 2 Einer) statt der Stellenwert berücksichtigt
- **diagnostik:** —
- **übung:** —

### stellenwerttafel × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; KMK Bildungsstandards Primarbereich (2022)
- **fehlerbild:** Zahlendreher: 41 wird als 14 geschrieben oder gelesen; oder die Rückrichtung fehlt — das Kind zerlegt 41 in 4 Zehner und 1 Einer, bildet aber aus „4 Zehner, 1 Einer" nicht wieder 41
- **diagnostik:** —
- **übung:** —

## Strang: zahlenstrahl

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | offen |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

> Eigener Strang, damit die Leiter 0–10 → 0–20 → 0–100 als drei Zellen sichtbar wird. v1
> hatte dafür ein einziges Item, das direkt im Hunderterraum ansetzte (Anhang A, Q26).

### zahlenstrahl × ZR10 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Schipper, Handbuch (Zahlenband, Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind legt die Zahlkarte an das Zahlenband, indem es von 0 an jeden Schritt abzählt; ohne beschriftete Zwischenmarken misslingt die Platzierung ganz
- **diagnostik:** —
- **übung:** —

### zahlenstrahl × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Kind trifft beim Zeigen die Zwischenräume statt der Marken oder verschiebt sich um eins, weil es die 0 als erste Marke mitzählt
- **diagnostik:** —
- **übung:** —

### zahlenstrahl × ZR10 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Kind kann zu einer markierten Stelle keine Zahl nennen, ohne die Marken von 0 an abzuzählen — die Position trägt noch keine Zahlbedeutung
- **diagnostik:** —
- **übung:** —

### zahlenstrahl × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Beim Gehen oder Schieben am Zahlenband verliert das Kind an der 10 die Orientierung und beginnt die zweite Hälfte neu bei 1
- **diagnostik:** —
- **übung:** —

### zahlenstrahl × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Zahlen werden nur an beschrifteten Marken gefunden; zwischen 10 und 20 platziert das Kind gleichmäßig verteilt statt nach Wert
- **diagnostik:** —
- **übung:** C10.1 [alt, Triage offen]

### zahlenstrahl × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Kind liest die markierte Stelle ab, indem es alle Marken zählt; der Abstand zwischen zwei Zahlen wird nicht als Differenz gedeutet
- **diagnostik:** —
- **übung:** —

### zahlenstrahl × ZR100 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Am langen Zahlenband nutzt das Kind die Zehnermarken nicht als Ankerpunkte, sondern zählt von 0 an in Einern — bei 60 bricht der Versuch ab
- **diagnostik:** —
- **übung:** —

### zahlenstrahl × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Padberg/Benz, Zahlenstrahl und Zahlvorstellung (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind verortet 47 ohne Bezug zu 50 als Ankerpunkt; die Schätzung landet in der falschen Dekade oder klebt am linken Rand
- **diagnostik:** —
- **übung:** C10.2 [alt, Triage offen]

### zahlenstrahl × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Kind liest an einem Strahl mit unbeschrifteten Zwischenmarken ab, ohne die Schrittweite zu bestimmen — jede Marke gilt als ein Schritt von eins
- **diagnostik:** —
- **übung:** —

## Strang: addition-ohne-uebergang

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | offen |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

### addition-ohne-uebergang × ZR10 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Wartha/Schulz (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind legt beide Mengen und zählt anschließend alles von 1 an ab (Alleszählen), statt von der ersten Menge aus weiterzuzählen oder die Summe abzurufen
- **diagnostik:** —
- **übung:** —

### addition-ohne-uebergang × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Im Bild werden beide Teilmengen einzeln abgezählt; die zweite Menge wird nicht als Weiterzählschritt oder als bekannte Zerlegung genutzt
- **diagnostik:** —
- **übung:** —

### addition-ohne-uebergang × ZR10 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Selter/Spiegel, zählendes Rechnen
- **fehlerbild:** Aufgaben im Zehnerraum werden mit den Fingern zählend gelöst; die Latenz wächst mit dem zweiten Summanden — das sichere Kennzeichen des Weiterzählens
- **diagnostik:** —
- **übung:** —

### addition-ohne-uebergang × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Bei 13+4 baut das Kind die 13 vollständig aus Einern auf, statt die Zehnerstange zu nehmen und nur im Einerbereich zu rechnen
- **diagnostik:** —
- **übung:** —

### addition-ohne-uebergang × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Am Zwanzigerfeld wird ab dem ersten Feld weitergezählt statt ab der vollen Zehnerreihe; die zweite Reihe wird nicht als „zehn und Rest" gelesen
- **diagnostik:** —
- **übung:** —

### addition-ohne-uebergang × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** 13+4 wird als 1+3+4 verarbeitet oder in Einerschritten hochgezählt; die Zehnerstelle wird beim Rechnen nicht konstant gehalten
- **diagnostik:** —
- **übung:** —

### addition-ohne-uebergang × ZR100 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz
- **fehlerbild:** Bei 42+30 legt das Kind dreißig Einer statt drei Stangen; oder es legt richtig, zählt zur Ergebnisbestimmung aber alle Einer der Stangen einzeln nach
- **diagnostik:** —
- **übung:** —

### addition-ohne-uebergang × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Am Hunderterfeld wird der Zehnersprung als Weiterzählen in Einern ausgeführt; der Zeilensprung als Zehnerschritt ist nicht verfügbar
- **diagnostik:** —
- **übung:** —

### addition-ohne-uebergang × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Padberg/Benz, halbschriftliche Addition (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** 42+30 wird zu 45 oder 72 — Zehner und Einer werden vermischt, weil der zweite Summand nicht als Zehnerzahl erkannt wird
- **diagnostik:** —
- **übung:** S3.7 [alt, Triage offen]

## Strang: addition-mit-uebergang

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | – | – | – |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

**Ausnahmen:**
- `addition-mit-uebergang × ZR10 × enaktiv` — Im Zehnerraum bleibt jede Summe unter oder gleich zehn; einen Zehnerübergang gibt es dort definitionsgemäß nicht.
- `addition-mit-uebergang × ZR10 × ikonisch` — Im Zehnerraum bleibt jede Summe unter oder gleich zehn; einen Zehnerübergang gibt es dort definitionsgemäß nicht.
- `addition-mit-uebergang × ZR10 × symbolisch` — Im Zehnerraum bleibt jede Summe unter oder gleich zehn; einen Zehnerübergang gibt es dort definitionsgemäß nicht.

### addition-mit-uebergang × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Wartha/Schulz, Zehnerübergang (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind füllt die Zehnerreihe nicht zuerst auf, sondern legt den zweiten Summanden am Stück irgendwo an und zählt danach alles nach — der Schritt über die Zehn wird nicht als Zwischenziel genutzt
- **diagnostik:** —
- **übung:** —

### addition-mit-uebergang × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Am Zwanzigerfeld wird der zweite Summand nicht in „bis zur Zehn" und „Rest" zerlegt; das Kind zählt über den Reihenwechsel hinweg Feld für Feld und verzählt sich dort
- **diagnostik:** —
- **übung:** —

### addition-mit-uebergang × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Selter/Spiegel
- **fehlerbild:** 8+5 wird zählend gelöst statt über 8+2+3; typische Ergebnisse sind 12 oder 14 (Verzählen um eins am Übergang), bei langer Latenz
- **diagnostik:** —
- **übung:** —

### addition-mit-uebergang × ZR100 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz, Bündeln beim Rechnen
- **fehlerbild:** Bei 47+8 entstehen fünfzehn Einer, die liegen bleiben — das Nachbündeln zu einer neuen Zehnerstange unterbleibt, die Zahl wird nicht wieder normalisiert
- **diagnostik:** —
- **übung:** —

### addition-mit-uebergang × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Am Hunderterfeld wird der Dekadenwechsel beim Weitergehen übersprungen oder verdoppelt; das Kind landet eine Zeile zu tief
- **diagnostik:** —
- **übung:** —

### addition-mit-uebergang × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Padberg/Benz, halbschriftliche Strategien (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** 47+8 wird zu 45 oder 55: die Einer werden addiert und der Übertrag entweder vergessen oder zweimal gezählt; die Zehnerstelle wird nicht angepasst
- **diagnostik:** —
- **übung:** —

## Strang: subtraktion-ohne-uebergang

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | offen |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

### subtraktion-ohne-uebergang × ZR10 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Wartha/Schulz (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind nimmt weg und zählt den Rest vollständig neu ab; der Zusammenhang zwischen Ausgangsmenge, weggenommener Menge und Rest wird nicht genutzt
- **diagnostik:** —
- **übung:** —

### subtraktion-ohne-uebergang × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Im Bild werden durchgestrichene Elemente mitgezählt oder das Kind zählt die durchgestrichenen statt der verbliebenen — die Frage nach dem Rest wird als Frage nach dem Weggenommenen gelesen
- **diagnostik:** —
- **übung:** —

### subtraktion-ohne-uebergang × ZR10 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Selter/Spiegel
- **fehlerbild:** 9−3 wird durch Rückwärtszählen in Einern gelöst; bei größerem Subtrahenden häufen sich ±1-Fehler, weil der Startwert mitgezählt wird
- **diagnostik:** —
- **übung:** —

### subtraktion-ohne-uebergang × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Bei 17−4 löst das Kind die Zehnerstange auf, obwohl im Einerbereich genug vorhanden ist — die Zahl wird zum Rechnen unnötig in Einer zerlegt
- **diagnostik:** —
- **übung:** —

### subtraktion-ohne-uebergang × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Am Zwanzigerfeld wird von 20 an rückwärts gezählt statt von der dargestellten Zahl aus; die Darstellung wird nicht als Ausgangswert gelesen
- **diagnostik:** —
- **übung:** —

### subtraktion-ohne-uebergang × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** 17−4 wird zu 13 gerechnet, 14−3 aber zu 11 — die Zehnerstelle wird beim Rechnen nicht konstant gehalten, sondern in die Subtraktion einbezogen
- **diagnostik:** —
- **übung:** —

### subtraktion-ohne-uebergang × ZR100 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz
- **fehlerbild:** Bei 68−30 nimmt das Kind dreißig Einer weg statt drei Stangen und verliert dabei den Überblick über den Rest
- **diagnostik:** —
- **übung:** —

### subtraktion-ohne-uebergang × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Am Hunderterfeld wird der Zehnerschritt rückwärts in Einern gegangen; die Zeile als Zehnereinheit wird beim Wegnehmen nicht genutzt
- **diagnostik:** —
- **übung:** —

### subtraktion-ohne-uebergang × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Padberg/Benz (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** 68−30 wird zu 38 gerechnet, 68−3 aber ebenfalls zu 38 — Zehner und Einer des Subtrahenden werden nicht unterschieden
- **diagnostik:** —
- **übung:** —

## Strang: subtraktion-mit-uebergang

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | – | – | – |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

**Ausnahmen:**
- `subtraktion-mit-uebergang × ZR10 × enaktiv` — Im Zehnerraum bleibt jede Differenz innerhalb der ersten Zehn; ein Unterschreiten der Zehnergrenze gibt es dort definitionsgemäß nicht.
- `subtraktion-mit-uebergang × ZR10 × ikonisch` — Im Zehnerraum bleibt jede Differenz innerhalb der ersten Zehn; ein Unterschreiten der Zehnergrenze gibt es dort definitionsgemäß nicht.
- `subtraktion-mit-uebergang × ZR10 × symbolisch` — Im Zehnerraum bleibt jede Differenz innerhalb der ersten Zehn; ein Unterschreiten der Zehnergrenze gibt es dort definitionsgemäß nicht.

### subtraktion-mit-uebergang × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Wartha/Schulz (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Bei 13−5 nimmt das Kind erst die drei Einer weg und weiß dann nicht weiter; das Entbündeln der Zehnerstange als Fortsetzung des Schritts unterbleibt
- **diagnostik:** —
- **übung:** —

### subtraktion-mit-uebergang × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Am Zwanzigerfeld wird beim Rückwärtsgehen der Reihenwechsel doppelt gezählt; typisch ist ein Ergebnis, das um eins zu groß oder zu klein ist
- **diagnostik:** —
- **übung:** —

### subtraktion-mit-uebergang × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Selter/Spiegel
- **fehlerbild:** 13−5 wird zu 8 nur über zählendes Rückwärtsgehen erreicht, oder das Kind rechnet die kleinere Ziffer von der größeren ab und antwortet 12
- **diagnostik:** —
- **übung:** —

### subtraktion-mit-uebergang × ZR100 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz, Entbündeln
- **fehlerbild:** Bei 52−7 wird nicht entbündelt: das Kind nimmt eine ganze Zehnerstange weg und antwortet 42, oder es legt die Aufgabe gar nicht erst
- **diagnostik:** —
- **übung:** —

### subtraktion-mit-uebergang × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Am Hunderterfeld wird der Dekadenwechsel rückwärts übersprungen; das Kind landet in der falschen Zeile und korrigiert nicht, weil es die Zeile nicht als Zehner liest
- **diagnostik:** —
- **übung:** —

### subtraktion-mit-uebergang × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Padberg/Benz (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** 52−7 wird zu 55: die kleinere Einerziffer wird von der größeren abgezogen, ohne den Zehner anzutasten — der klassische Stellenwertfehler der Subtraktion
- **diagnostik:** —
- **übung:** —

## Strang: ergaenzen

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | offen |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

### ergaenzen × ZR10 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Wartha/Schulz, Ergänzen als Subtraktionsdeutung (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind legt zur Ergänzung auf zehn einzeln nach und zählt nach jedem Plättchen die Gesamtmenge neu; die Zerlegung der Zehn wird nicht genutzt
- **diagnostik:** —
- **übung:** —

### ergaenzen × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Im Bild werden die freien Felder einzeln abgezählt statt als Rest der Zehnerstruktur gelesen
- **diagnostik:** —
- **übung:** —

### ergaenzen × ZR10 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; Selter/Spiegel
- **fehlerbild:** „6 + ? = 10" wird zählend gelöst; bei der gleichwertigen Form „10 − 6" antwortet dasselbe Kind schneller — Ergänzen und Wegnehmen sind noch nicht dieselbe Aufgabe
- **diagnostik:** —
- **übung:** Z2 [alt, Triage offen]

### ergaenzen × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Beim Ergänzen von 13 auf 20 legt das Kind bis 20 einzeln nach, statt zuerst auf die volle Zehnerreihe und dann weiter zu ergänzen
- **diagnostik:** —
- **übung:** —

### ergaenzen × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Am Zwanzigerfeld wird die Lücke bis zur nächsten vollen Reihe nicht als Zwischenziel erkannt; das Kind zählt die freien Felder komplett durch
- **diagnostik:** —
- **übung:** —

### ergaenzen × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Kind löst „7 + ? = 15" durch Weiterzählen, oder es liest die Aufgabe als 7 + 15 und antwortet 22 — die Leerstelle wird nicht als gesuchte Größe verstanden
- **diagnostik:** —
- **übung:** —

### ergaenzen × ZR100 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz
- **fehlerbild:** Beim Ergänzen von 47 auf 100 legt das Kind Einer nach, statt zuerst auf 50 und dann in Zehnern weiterzugehen
- **diagnostik:** —
- **übung:** —

### ergaenzen × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Am Hunderterfeld wird der Rest bis 100 nicht über volle Zeilen bestimmt, sondern feldweise abgezählt — die Aufgabe wird zur Zählstrecke
- **diagnostik:** —
- **übung:** —

### ergaenzen × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Padberg/Benz (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** „47 + ? = 60" wird stellenweise beantwortet (Antwort 23, aus 6−4 und 0−7 rückwärts gelesen); der Zehnerübergang beim Ergänzen wird nicht vollzogen
- **diagnostik:** —
- **übung:** —

## Strang: flexibles-rechnen

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | – | – | – |
| ZR20 | – | offen | offen |
| ZR100 | – | offen | offen |

**Ausnahmen:**
- `flexibles-rechnen × ZR10 × enaktiv` — Flexibles Rechnen setzt konkurrierende Rechenwege voraus; im Zehnerraum gibt es zu einer Aufgabe faktisch nur einen Weg, so dass keine Wahl beobachtbar wird.
- `flexibles-rechnen × ZR10 × ikonisch` — Flexibles Rechnen setzt konkurrierende Rechenwege voraus; im Zehnerraum gibt es zu einer Aufgabe faktisch nur einen Weg, so dass keine Wahl beobachtbar wird.
- `flexibles-rechnen × ZR10 × symbolisch` — Flexibles Rechnen setzt konkurrierende Rechenwege voraus; im Zehnerraum gibt es zu einer Aufgabe faktisch nur einen Weg, so dass keine Wahl beobachtbar wird.
- `flexibles-rechnen × ZR20 × enaktiv` — Am Material wird ein Weg gelegt, nicht zwischen Wegen gewählt; die Strategiewahl zeigt sich erst, wenn die Aufgabe ohne Materialvorgabe gestellt wird. Die Handlungsebene der Einzelstrategien liegt bei den Rechensträngen selbst.
- `flexibles-rechnen × ZR100 × enaktiv` — Am Material wird ein Weg gelegt, nicht zwischen Wegen gewählt; die Strategiewahl zeigt sich erst, wenn die Aufgabe ohne Materialvorgabe gestellt wird.

### flexibles-rechnen × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Selter/Spiegel, Rechenwege von Kindern
- **fehlerbild:** Kind kann zwei angebotene Lösungswege am Bild nicht unterscheiden oder hält den umständlicheren für den richtigen, weil er dem eingeübten Ablauf folgt
- **diagnostik:** —
- **übung:** —

### flexibles-rechnen × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Padberg/Benz, Nachbaraufgaben und Aufgabenbeziehungen (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind rechnet 7+8 neu aus, obwohl 7+7 unmittelbar davor stand — Aufgabenbeziehungen werden nicht genutzt; Latenz und Weg sind bei Kern- und Nachbaraufgabe identisch
- **diagnostik:** —
- **übung:** S2.3 [alt, Triage offen]

### flexibles-rechnen × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Am Hunderterfeld wählt das Kind immer denselben Weg (Einerschritte), auch wo ein Zehnersprung sichtbar kürzer wäre
- **diagnostik:** —
- **übung:** —

### flexibles-rechnen × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; Selter/Spiegel; Padberg/Benz (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Bei 49+26 rechnet das Kind stur stellenweise, statt über 50 zu gehen; auch nach richtigem Ergebnis bleibt der Weg bei jeder Aufgabe derselbe — Strategiewahl findet nicht statt
- **diagnostik:** —
- **übung:** —

## Strang: sachsituationen

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | – | offen | offen |
| ZR20 | – | offen | offen |
| ZR100 | – | offen | offen |

**Ausnahmen:**
- `sachsituationen × ZR10 × enaktiv` — Eine Sachsituation begegnet dem Kind als Erzählung oder Bild; sobald sie mit Material gelegt wird, ist die Übersetzungsleistung bereits erbracht und es wird nur noch gerechnet.
- `sachsituationen × ZR20 × enaktiv` — Eine Sachsituation begegnet dem Kind als Erzählung oder Bild; sobald sie mit Material gelegt wird, ist die Übersetzungsleistung bereits erbracht und es wird nur noch gerechnet.
- `sachsituationen × ZR100 × enaktiv` — Eine Sachsituation begegnet dem Kind als Erzählung oder Bild; sobald sie mit Material gelegt wird, ist die Übersetzungsleistung bereits erbracht und es wird nur noch gerechnet.

> Bei kindsolo-Administration wird der Aufgabentext vorgelesen (TTS, v2-Entwurf §7). Was hier
> geprüft wird, ist die Übersetzung Situation zu Rechnung — nicht die Lesefähigkeit.

### sachsituationen × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A; KMK Bildungsstandards Primarbereich (2022), Modellieren
- **fehlerbild:** Kind entnimmt dem Bild die Zahlen, aber nicht die Handlung, und addiert grundsätzlich — die Richtung der Situation (dazu oder weg) wird nicht gelesen
- **diagnostik:** —
- **übung:** —

### sachsituationen × ZR10 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Kind rechnet mit den beiden genannten Zahlen, ohne die Frage zu beachten; das Ergebnis ist rechnerisch richtig und beantwortet die gestellte Frage nicht
- **diagnostik:** —
- **übung:** —

### sachsituationen × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **fehlerbild:** Bei Vergleichssituationen („wie viele mehr?") wird addiert statt die Differenz gebildet — der Unterschied wird nicht als eigene Größe erkannt
- **diagnostik:** —
- **übung:** —

### sachsituationen × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Schipper, Handbuch (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Signalwörter steuern die Rechnung statt der Situation: „mehr" führt immer zu Plus, auch wenn nach dem Ausgangswert gefragt ist
- **diagnostik:** —
- **übung:** —

### sachsituationen × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Kind übernimmt aus der Abbildung alle sichtbaren Zahlen in die Rechnung, auch die für die Frage unerheblichen
- **diagnostik:** —
- **übung:** —

### sachsituationen × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B; KMK Bildungsstandards Primarbereich (2022), Modellieren
- **fehlerbild:** Kind rechnet richtig, deutet das Ergebnis aber nicht zurück auf die Situation — eine unplausible Antwort (mehr Kinder als in der Klasse) bleibt unbemerkt
- **diagnostik:** —
- **übung:** —

## Rückbindung an Anhang A

Jeder itemweise Befund aus [00-v1-assessment.md](../00-v1-assessment.md), Anhang A, muss in
dieser Matrix eine Adresse haben. Wo er keine hat, ist er kein Deckungsproblem, sondern eine
Regel für den Blueprint, die Itemschreibung oder Gate 2 — auch das steht hier, damit nichts
zwischen den Artefakten verloren geht.

| Befund | Adresse in v2 |
|---|---|
| **Q7** Vorgänger/Nachfolger 37 | Zelle `vorgaenger-nachfolger ZR100 symbolisch`. Die Zwei-Antworten-Frage ist dort im Fehlerbild benannt; die Aufteilung in zwei Felder ist Itemregel, nicht Deckung. |
| **Q8** Simultanerfassung am Rekenrek | Gedeckelt: `anzahl-simultan` lebt nur in ZR10, und dort nur enaktiv und ikonisch. Der Rekenrek ist ein **strukturiertes** Gerät und gehört nach `anzahl-strukturiert ZR20 enaktiv`. |
| **Q8 → Q9** Schwierigkeitssprung | Keine Zelle. Eigenschaft der Itemreihenfolge, gehört in den Blueprint (Phase 2). |
| **Q11** mehr/weniger nur ikonisch | Beide Zellen leben: `anzahl-vergleich ZR10 ikonisch` **und** `ZR10 symbolisch`. Genau dafür ist die Repräsentationsachse da. |
| **Q15 / Q17** Zerlegungen, Redundanz | Beide in `zerlegung ZR10 symbolisch`, mit benanntem Unterschied (Abruf gegen Systematik) — siehe Notiz am Strang. Das fehlende „+" ist Layoutregel. |
| **Q18** dekoratives Beiwerk | Keine Zelle. Itemregel „kein Satz, der nicht gemessen wird". |
| **Q20 / Q24 / Q25** Stellenwert dreifach | Zellen `stellenwerttafel ZR100 symbolisch` und `buendeln-entbuendeln ZR100 symbolisch`. Beide Richtungen (Zahl zu Stellen, Stellen zu Zahl) sind gefordert; drei Items für eine Richtung sind zwei zu viel. |
| **Q22** drei Felder für eine Antwort | Zelle `anzahl-strukturiert ZR100 ikonisch`. Die Feld-Arität ist Itemregel. |
| **Q23** Bündel öffnen, Stäbchen gegen Würfel | Zelle `buendeln-entbuendeln ZR100 enaktiv`. Der Prompt-Darstellungs-Drift ist Gate 2. |
| **Q26** Zahlenstrahl direkt 0–100 | Eigener Strang `zahlenstrahl` mit drei Zahlenräumen — die Leiter ist jetzt als drei Zellen sichtbar statt als ein Item. Die Pfeilrichtung ist Gate 2. |
| **ab Q44** zu kompliziert formuliert | Keine Zelle. Die dort gemessenen Konstrukte leben in `flexibles-rechnen` und `sachsituationen`; die Formulierung ist Itemregel und Gate 2. |

## Gate 1 — Freigabe

Jakob hat die Matrix am **2026-09-07** als Förderlehrer geprüft und freigegeben.

| Prüffrage | Antwort |
|---|---|
| Fehlt ein Strang, den ein Kind der Klassen 1/2 können muss? | nein |
| Steht ein Strang hier, der nicht hierher gehört? | nein |
| Sind die 28 Ausnahmen pädagogisch begründet — oder ist eine davon nur bequem? | sie sind begründet |
| Sind die Fehlerbilder das, was du bei Kindern tatsächlich siehst? | Fehlerbilder sind gut |

Damit ist dieses Dokument die **Quelle der Wahrheit für alle inhaltlichen Fragen**. Konstruktkarte
und Blueprint (Phase 2) werden aus ihm abgeleitet; wo ein späteres Artefakt ihm widerspricht,
gilt die Matrix. Änderungen an einem freigegebenen Strang brauchen eine neue Freigabe.

Die Zellstatus bleiben davon unberührt: freigegeben ist die **Deckung** — welche Zellen es gibt
und warum. Eine einzelne Zelle wird erst `freigegeben`, wenn sie ein Item und eine Übung nennt
und beide durch Gate 1 (Papier) und Gate 2 (laufender Kind-Screen) gegangen sind.
