# 11 — Konstruktkarte (v2)

| | |
|---|---|
| **Status** | ✅ FREIGEGEBEN — Jakob, 2026-09-08 (Gate 1) |
| **Stand** | 2026-09-08 |
| **Owner** | Jakob |
| **Quelle** | [10-deckungsmatrix.md](10-deckungsmatrix.md) — freigegeben 2026-09-07 |
| **Erzeugt von** | `python scripts/derive_ableitungen.py` |
| **Gate** | `python scripts/derive_ableitungen.py --check` |

Dieses Dokument ist **abgeleitet**. Es wird nicht von Hand gepflegt: der Rumpf unten
entsteht aus der Deckungsmatrix, und `--check` schlägt fehl, sobald beide auseinanderlaufen.
Genau dieser Drift — ein abgeleitetes Artefakt, das seiner Quelle davonläuft, ohne dass
es jemand merkt — hat in v1 22 veraltete Fragetexte in die laufende CSV gebracht
(v2-Entwurf §7). Soll sich hier etwas ändern, ändert sich die Matrix.

**Was ein Konstrukt ist.** Ein Strang in einem Zahlenraum. Die Repräsentation ist keine
eigene Fähigkeit, sondern die Stufe, auf der wir eine Fähigkeit erheben; sie bleibt als
Evidenzstufe *innerhalb* des Konstrukts sichtbar. Ein Kind, das 50 nicht halbieren kann,
kann 50 nicht halbieren — ob es am Dienes-Material oder auf dem Papier scheitert, ist der
diagnostische Befund darin, nicht ein zweiter Befund.

Warum nicht der Strang allein: das war v1s Fehler. „Verdoppeln" war ein Konstrukt, und
der ZR100 ist darin verschwunden.

**Leitende und stützende Repräsentation.** Die *leitende* ist die symbolischste lebende —
dort zeigt sich die Strategie, und sie ist für ein Kind allein am Gerät am billigsten zu
erheben. Die *stützende* ist die enaktivste lebende — dort zeigt sich das zählende Rechnen.
Der Blueprint (12-blueprint.md) verteilt die Items entlang dieser beiden.

**Vorrang:** Deckungsmatrix > Konstruktkarte > Blueprint > Items/Übungen.

## Gate 1 — Freigabe

Jakob hat den Konstruktbegriff am **2026-09-08** als Förderlehrer geprüft und freigegeben.

| Prüffrage | Antwort |
|---|---|
| Ist ein Konstrukt ein Strang in einem Zahlenraum — 54 Konstrukte statt 152 Zellen oder 20 Strängen, die Repräsentation als Evidenzstufe darin? Trägt das als Einheit, über die du einer Kollegin einen Befund berichtest? | ja |

Damit ist der Zuschnitt **(Strang × Zahlenraum)** verbindlich. Die Zuteilung der Items auf
diese Konstrukte steht in [12-blueprint.md](12-blueprint.md) und ist dort eigens freigegeben.
Der Rumpf unten bleibt maschinell erzeugt: die Freigabe gilt dem Begriff, nicht den 54
einzelnen Textblöcken, die jederzeit aus der Matrix neu erzeugt werden.

<!-- AUTOGEN:START — erzeugt von scripts/derive_ableitungen.py, nicht von Hand bearbeiten -->

**54 Konstrukte** aus 20 Strängen. Ein Konstrukt ist ein Strang in einem Zahlenraum; die Repräsentationen sind die Evidenzstufen darin.

| Konstrukt | Strang | Zahlenraum | lebende Repräsentationen | leitend | stützend |
|---|---|---|---|---|---|
| `zaehlen-vorwaerts.ZR10` | zaehlen-vorwaerts | ZR10 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `zaehlen-vorwaerts.ZR20` | zaehlen-vorwaerts | ZR20 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `zaehlen-vorwaerts.ZR100` | zaehlen-vorwaerts | ZR100 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `zaehlen-rueckwaerts.ZR10` | zaehlen-rueckwaerts | ZR10 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `zaehlen-rueckwaerts.ZR20` | zaehlen-rueckwaerts | ZR20 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `zaehlen-rueckwaerts.ZR100` | zaehlen-rueckwaerts | ZR100 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `zaehlen-schritte.ZR10` | zaehlen-schritte | ZR10 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `zaehlen-schritte.ZR20` | zaehlen-schritte | ZR20 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `zaehlen-schritte.ZR100` | zaehlen-schritte | ZR100 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `vorgaenger-nachfolger.ZR10` | vorgaenger-nachfolger | ZR10 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `vorgaenger-nachfolger.ZR20` | vorgaenger-nachfolger | ZR20 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `vorgaenger-nachfolger.ZR100` | vorgaenger-nachfolger | ZR100 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `anzahl-simultan.ZR10` | anzahl-simultan | ZR10 | enaktiv, ikonisch | ikonisch | enaktiv |
| `anzahl-strukturiert.ZR10` | anzahl-strukturiert | ZR10 | enaktiv, ikonisch | ikonisch | enaktiv |
| `anzahl-strukturiert.ZR20` | anzahl-strukturiert | ZR20 | enaktiv, ikonisch | ikonisch | enaktiv |
| `anzahl-strukturiert.ZR100` | anzahl-strukturiert | ZR100 | enaktiv, ikonisch | ikonisch | enaktiv |
| `anzahl-vergleich.ZR10` | anzahl-vergleich | ZR10 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `anzahl-vergleich.ZR20` | anzahl-vergleich | ZR20 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `anzahl-vergleich.ZR100` | anzahl-vergleich | ZR100 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `zahlvergleich-ordnen.ZR10` | zahlvergleich-ordnen | ZR10 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `zahlvergleich-ordnen.ZR20` | zahlvergleich-ordnen | ZR20 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `zahlvergleich-ordnen.ZR100` | zahlvergleich-ordnen | ZR100 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `zerlegung.ZR10` | zerlegung | ZR10 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `zerlegung.ZR20` | zerlegung | ZR20 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `zerlegung.ZR100` | zerlegung | ZR100 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `verdoppeln-halbieren.ZR10` | verdoppeln-halbieren | ZR10 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `verdoppeln-halbieren.ZR20` | verdoppeln-halbieren | ZR20 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `verdoppeln-halbieren.ZR100` | verdoppeln-halbieren | ZR100 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `buendeln-entbuendeln.ZR10` | buendeln-entbuendeln | ZR10 | enaktiv, ikonisch | ikonisch | enaktiv |
| `buendeln-entbuendeln.ZR20` | buendeln-entbuendeln | ZR20 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `buendeln-entbuendeln.ZR100` | buendeln-entbuendeln | ZR100 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `stellenwerttafel.ZR20` | stellenwerttafel | ZR20 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `stellenwerttafel.ZR100` | stellenwerttafel | ZR100 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `zahlenstrahl.ZR10` | zahlenstrahl | ZR10 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `zahlenstrahl.ZR20` | zahlenstrahl | ZR20 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `zahlenstrahl.ZR100` | zahlenstrahl | ZR100 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `addition-ohne-uebergang.ZR10` | addition-ohne-uebergang | ZR10 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `addition-ohne-uebergang.ZR20` | addition-ohne-uebergang | ZR20 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `addition-ohne-uebergang.ZR100` | addition-ohne-uebergang | ZR100 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `addition-mit-uebergang.ZR20` | addition-mit-uebergang | ZR20 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `addition-mit-uebergang.ZR100` | addition-mit-uebergang | ZR100 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `subtraktion-ohne-uebergang.ZR10` | subtraktion-ohne-uebergang | ZR10 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `subtraktion-ohne-uebergang.ZR20` | subtraktion-ohne-uebergang | ZR20 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `subtraktion-ohne-uebergang.ZR100` | subtraktion-ohne-uebergang | ZR100 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `subtraktion-mit-uebergang.ZR20` | subtraktion-mit-uebergang | ZR20 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `subtraktion-mit-uebergang.ZR100` | subtraktion-mit-uebergang | ZR100 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `ergaenzen.ZR10` | ergaenzen | ZR10 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `ergaenzen.ZR20` | ergaenzen | ZR20 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `ergaenzen.ZR100` | ergaenzen | ZR100 | enaktiv, ikonisch, symbolisch | symbolisch | enaktiv |
| `flexibles-rechnen.ZR20` | flexibles-rechnen | ZR20 | ikonisch, symbolisch | symbolisch | ikonisch |
| `flexibles-rechnen.ZR100` | flexibles-rechnen | ZR100 | ikonisch, symbolisch | symbolisch | ikonisch |
| `sachsituationen.ZR10` | sachsituationen | ZR10 | ikonisch, symbolisch | symbolisch | ikonisch |
| `sachsituationen.ZR20` | sachsituationen | ZR20 | ikonisch, symbolisch | symbolisch | ikonisch |
| `sachsituationen.ZR100` | sachsituationen | ZR100 | ikonisch, symbolisch | symbolisch | ikonisch |

### zaehlen-vorwaerts.ZR10

- **Beschreibung:** Vorwärtszählen von beliebigem Startpunkt, mit Dekadenwechsel — im ZR10
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1 Zahlen und Operationen, Niveaustufe A; Krajewski, Zahlwortreihe als Vorläuferfertigkeit; RLP BE/BB Teil C, L1, Niveaustufe A; KMK Bildungsstandards Primarbereich (2022), Leitidee Zahlen und Operationen
- **Übungen im Bestand:** C1.2, C1.1
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind verletzt die Eins-zu-eins-Zuordnung — es tippt schneller als es zählt oder erfasst Objekte doppelt; oder es sagt die Zahlwortreihe korrekt auf, ohne sie mit dem Zeigen zu koppeln
  - *ikonisch* — Kind verliert im ungeordneten Punktebild die Übersicht, weil es keine Merkstrategie hat (kein Abhaken, kein systematischer Weg) — das Ergebnis schwankt bei Wiederholung derselben Abbildung
  - *symbolisch* — Kind kann die Zahlwortreihe nur von 1 an aufsagen; ein Start bei 6 zwingt es zum stillen Neuanlauf — erkennbar an langer Latenz vor dem ersten Zahlwort

### zaehlen-vorwaerts.ZR20

- **Beschreibung:** Vorwärtszählen von beliebigem Startpunkt, mit Dekadenwechsel — im ZR20
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A; Schipper, Handbuch (Kap. n.n. — Seitenbeleg folgt nach Ankunft); RLP BE/BB Teil C, L1, Niveaustufe A/B
- **Übungen im Bestand:** C1.1, C3.1
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind zählt über die Zehn hinweg in Einern weiter, ohne die Zehn als erreichte Einheit zu markieren; beim Legen entsteht keine Fünfer- oder Zehnerstruktur
  - *ikonisch* — Kind zählt am Zwanzigerfeld jedes Feld einzeln ab, statt die volle erste Reihe als Zehn zu lesen — die Struktur des Feldes bleibt ungenutzt
  - *symbolisch* — Der Dekadenwechsel bricht: nach 19 folgt eine Neubildung wie „zwanzigeins" oder ein Rücksprung auf 10; die Zehnerstelle wird beim Weiterzählen nicht mitgeführt

### zaehlen-vorwaerts.ZR100

- **Beschreibung:** Vorwärtszählen von beliebigem Startpunkt, mit Dekadenwechsel — im ZR100
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz, Bündelung bei rechenschwachen Kindern; KMK Bildungsstandards Primarbereich (2022)
- **Übungen im Bestand:** C6.0, C3.2, C3.3
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind legt beim Weiterzählen über die Dekade keine neue Zehnerstange, sondern häuft Einer an — die Bündelung wird beim Zählen nicht vollzogen
  - *ikonisch* — Am Hunderterfeld springt das Kind beim Zeilenwechsel (von 39 auf 40) in die falsche Zeile oder Spalte; die Zeilenstruktur wird nicht als Zehnerstruktur gelesen
  - *symbolisch* — Kind zählt innerhalb einer Dekade sicher, verliert aber den Dekadenwechsel (nach 59 folgt 50 oder 70); die Zehnerreihe selbst ist nicht abrufbar

### zaehlen-rueckwaerts.ZR10

- **Beschreibung:** Rückwärtszählen von beliebigem Startpunkt, mit Dekadenwechsel — im ZR10
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A; Wartha/Schulz, Rückwärtszählen als Voraussetzung der Subtraktion (Kap. n.n. — Seitenbeleg folgt nach Ankunft); Selter/Spiegel, zählendes Rechnen
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind nimmt Plättchen weg, muss aber nach jedem Wegnehmen den Rest neu von 1 an abzählen — die rückwärts laufende Zahlwortreihe trägt nicht
  - *ikonisch* — Kind liest die abgebildete Reihe nur vorwärts und zählt zur Bestimmung des vorangehenden Feldes jedes Mal von links neu an
  - *symbolisch* — Kind bildet die Rückwärtsreihe, indem es innerlich vorwärts zählt und den Vorgänger abliest — sehr lange Latenz pro Schritt, Abbrüche im Bereich 7 bis 5

### zaehlen-rueckwaerts.ZR20

- **Beschreibung:** Rückwärtszählen von beliebigem Startpunkt, mit Dekadenwechsel — im ZR20
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Beim Wegnehmen über die Zehn hinweg (von 12 auf 8) löst das Kind die Zehnerstruktur nicht auf, sondern legt die ganze Menge neu
  - *ikonisch* — Am Zwanzigerfeld wird rückwärts Feld für Feld abgezählt, statt die volle Zehnerreihe als einen Sprung zu nutzen
  - *symbolisch* — Der Dekadenwechsel abwärts bricht: nach 20 folgt 10 oder 21; die Zehnerstelle wird beim Rückwärtszählen nicht mitgeführt

### zaehlen-rueckwaerts.ZR100

- **Beschreibung:** Rückwärtszählen von beliebigem Startpunkt, mit Dekadenwechsel — im ZR100
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz, Entbündeln
- **Übungen im Bestand:** C6.3
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind entbündelt beim Rückwärtszählen über die Dekade nicht (von 40 auf 39 bleibt die Zehnerstange liegen), sondern nimmt einen ganzen Zehner weg
  - *ikonisch* — Am Hunderterfeld läuft das Kind beim Rückwärtsgehen in die falsche Richtung der Zeile oder überspringt den Zeilenwechsel bei 30 auf 29
  - *symbolisch* — Kind kann die Zehnerreihe abwärts (100, 90, 80 …) nicht abrufen und zählt in Einern zurück — die Aufgabe wird zur Zählstrecke statt zum Zehnerschritt

### zaehlen-schritte.ZR10

- **Beschreibung:** Zählen in Schritten (2er, 5er, 10er), vorwärts wie rückwärts — im ZR10
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A; Padberg/Benz, Zählen in Schritten als Vorbereitung der Multiplikation (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind schiebt beim Zweierschritt einzeln statt paarweise und zählt dazwischen still in Einern weiter — der Schritt ist keine Einheit, sondern eine abgezählte Strecke
  - *ikonisch* — Kind erkennt im Bild die Paarstruktur nicht und zählt alle Elemente einzeln; die Zweierreihe wird nicht als Muster gelesen
  - *symbolisch* — Kind kann 2, 4, 6, 8, 10 nur aufsagen, wenn es die ungeraden Zahlen still mitspricht — Latenz pro Schritt wie beim Einerzählen

### zaehlen-schritte.ZR20

- **Beschreibung:** Zählen in Schritten (2er, 5er, 10er), vorwärts wie rückwärts — im ZR20
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Schipper, Handbuch (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **Übungen im Bestand:** C6.1
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Beim Fünferschritt am Material nutzt das Kind die Fünferstruktur nicht, sondern legt fünfmal einen Einer — bei 15 bricht die Reihe
  - *ikonisch* — Kind markiert im Zwanzigerfeld die Schritte, verliert aber beim Übergang von der ersten in die zweite Reihe die Schrittweite (nach 10 folgt 11 statt 12)
  - *symbolisch* — Die Zweierreihe trägt bis 10 und bricht am Zehnerübergang; oder das Kind wechselt unbemerkt die Schrittweite, sobald die Zahlen zweistellig werden

### zaehlen-schritte.ZR100

- **Beschreibung:** Zählen in Schritten (2er, 5er, 10er), vorwärts wie rückwärts — im ZR100
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz, Zehnerstruktur; KMK Bildungsstandards Primarbereich (2022)
- **Übungen im Bestand:** C6.0, C6.2
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind legt beim Zehnerschritt zehn Einer statt einer Zehnerstange — der Zehner ist noch keine handhabbare Einheit
  - *ikonisch* — Am Hunderterfeld wird der Zehnerschritt nicht als Zeilensprung erkannt; das Kind zählt die zehn Felder der Zeile einzeln ab, um von 23 auf 33 zu kommen
  - *symbolisch* — Zehnerschritte gelingen nur von einer glatten Zehnerzahl aus; von 23 aus in Zehnerschritten weiterzugehen misslingt, weil die Einerstelle nicht konstant gehalten wird

### vorgaenger-nachfolger.ZR10

- **Beschreibung:** Vorgänger und Nachfolger einer Zahl nennen, ohne zu zählen — im ZR10
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A; Krajewski, Zahl-Größen-Verknüpfung; Wartha/Schulz (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind kann zu einer gelegten Menge nicht „einer mehr" legen, ohne die neue Menge vollständig neu abzuzählen
  - *ikonisch* — Kind bestimmt am Bild den Nachfolger richtig, den Vorgänger aber nicht — die Richtung „eins weniger" ist nicht verfügbar
  - *symbolisch* — Kind ermittelt Vorgänger und Nachfolger durch Aufsagen der Reihe ab 1 statt durch direkten Zugriff — lange Latenz, und der Vorgänger dauert deutlich länger als der Nachfolger

### vorgaenger-nachfolger.ZR20

- **Beschreibung:** Vorgänger und Nachfolger einer Zahl nennen, ohne zu zählen — im ZR20
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **Übungen im Bestand:** C4.1, C5.1
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Am Material gelingt „einer mehr" innerhalb der Reihe, bricht aber genau am Zehnerübergang (von 10 auf 11, von 19 auf 20)
  - *ikonisch* — Kind verwechselt am abgebildeten Zahlenband Vorgänger und Nachfolger, weil es die Leserichtung nicht mit „mehr" und „weniger" koppelt
  - *symbolisch* — Vorgänger und Nachfolger werden zu 10 und 20 hin unsicher; Antworten wie „Vorgänger von 20 ist 10" zeigen, dass die Zehnerzahl als Block und nicht als Position gedacht wird

### vorgaenger-nachfolger.ZR100

- **Beschreibung:** Vorgänger und Nachfolger einer Zahl nennen, ohne zu zählen — im ZR100
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz, Entbündeln
- **Übungen im Bestand:** C5.1
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Der Vorgänger einer glatten Zehnerzahl verlangt Entbündeln; das Kind nimmt stattdessen eine ganze Zehnerstange weg und landet bei 30 statt bei 39
  - *ikonisch* — Am Hunderterfeld wird der Nachfolger über den Zeilenwechsel hinweg falsch gegriffen — das Kind geht eine Zeile tiefer statt ein Feld weiter
  - *symbolisch* — Vorgänger und Nachfolger gelingen innerhalb der Dekade, brechen aber an ihren Rändern (69/70, 100); außerdem wird nur eine der beiden Richtungen abgefragt beantwortet, wenn beide verlangt sind

### anzahl-simultan.ZR10

- **Beschreibung:** Anzahlen bis 5 auf einen Blick erfassen, ohne Zählhandlung — im ZR10
- **lebende Repräsentation:** enaktiv, ikonisch
- **leitende Repräsentation:** ikonisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A; Krajewski, Anzahlerfassung als Vorläuferfertigkeit; Krajewski (Blitzblick-Aufgaben)
- **Übungen im Bestand:** S1.1
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind zählt auch bei drei oder vier Fingern einzeln ab (sichtbares Tippen oder Lippenbewegung) — die Anzahl wird nicht auf einen Blick, sondern zählend bestimmt
  - *ikonisch* — Bei kurzer Darbietung nennt das Kind eine Zahl aus dem richtigen Bereich, aber nicht die richtige (rät); bei längerer Darbietung wird es sicher — der Unterschied zwischen beiden Bedingungen ist das eigentliche Signal

### anzahl-strukturiert.ZR10

- **Beschreibung:** größere Anzahlen über Struktur erfassen (Fünfer, Zehner, Bündel) — im ZR10
- **lebende Repräsentation:** enaktiv, ikonisch
- **leitende Repräsentation:** ikonisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A; Schipper, Handbuch (Fünferstruktur, Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind nutzt die Fünferstruktur des Materials nicht: bei sieben gelegten Plättchen zählt es alle sieben ab, statt fünf zu sehen und zwei dazuzuzählen
  - *ikonisch* — Im strukturierten Punktebild (Würfelbild, Fünferreihe) wird trotz Struktur einzeln gezählt; das Kind erkennt das Muster nicht wieder, wenn es gedreht dargeboten wird

### anzahl-strukturiert.ZR20

- **Beschreibung:** größere Anzahlen über Struktur erfassen (Fünfer, Zehner, Bündel) — im ZR20
- **lebende Repräsentation:** enaktiv, ikonisch
- **leitende Repräsentation:** ikonisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Schipper, Handbuch (Rechenschiffchen/Rekenrek)
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind schiebt am Rekenrek Perle für Perle, statt die Fünfer- und Zehnerblöcke in einem Zug zu bewegen — die Struktur des Geräts wird als Zählhilfe statt als Gliederung benutzt
  - *ikonisch* — Am abgebildeten Zwanzigerfeld wird die volle Zehnerreihe nicht als Zehn gelesen; das Kind zählt bis 20 durch und macht dabei Fehler in der zweiten Reihe

### anzahl-strukturiert.ZR100

- **Beschreibung:** größere Anzahlen über Struktur erfassen (Fünfer, Zehner, Bündel) — im ZR100
- **lebende Repräsentation:** enaktiv, ikonisch
- **leitende Repräsentation:** ikonisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz, Bündelung und Stellenwert
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind bestimmt eine aus Stangen und Einern gelegte Zahl, indem es alle Einer der Stangen mitzählt — die Zehnerstange ist noch keine Einheit, sondern zehn nebeneinanderliegende Dinge
  - *ikonisch* — Am abgebildeten Hunderterfeld wird die Anzahl markierter Felder zeilenweise falsch aufsummiert, weil volle Zeilen nicht als Zehner verrechnet, sondern nachgezählt werden

### anzahl-vergleich.ZR10

- **Beschreibung:** mehr, weniger, gleich viele an Mengen entscheiden — im ZR10
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A; Krajewski, Mengenvergleich; KMK Bildungsstandards Primarbereich (2022)
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind entscheidet nach dem Platzbedarf statt nach der Anzahl — die weiter auseinandergelegte Menge gilt als die größere, auch wenn beide gleich viele sind
  - *ikonisch* — Im Bild wird die längere Reihe als die größere Menge gelesen; eine Eins-zu-eins-Zuordnung zwischen den Reihen wird nicht gesucht
  - *symbolisch* — Kind kann zwei gezeigte Mengen vergleichen, aber nicht zwei genannte Zahlen — die Zahl trägt noch keine Größenvorstellung

### anzahl-vergleich.ZR20

- **Beschreibung:** mehr, weniger, gleich viele an Mengen entscheiden — im ZR20
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **Übungen im Bestand:** S1.4
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind entscheidet „mehr" richtig, kann aber das „wie viel mehr" nicht am Material zeigen — der Unterschied ist keine eigene Menge
  - *ikonisch* — Bei zwei belegten Zwanzigerfeldern zählt das Kind beide vollständig ab, statt die unterschiedlich weit gefüllten Reihen zu vergleichen
  - *symbolisch* — Der Vergleich gelingt innerhalb der Zehn und bricht darüber (13 gilt als kleiner als 9, weil nur die Einerziffer verglichen wird)

### anzahl-vergleich.ZR100

- **Beschreibung:** mehr, weniger, gleich viele an Mengen entscheiden — im ZR100
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Zwei gelegte Zahlen werden über die Gesamtzahl der Teile verglichen statt über die Zehner: vier Einer plus zwei Stangen gelten als „mehr" als drei Stangen
  - *ikonisch* — Am Hunderterfeld wird die dichter wirkende Markierung als die größere Anzahl gelesen; die Zeilenstruktur wird zum Vergleich nicht genutzt
  - *symbolisch* — Kind vergleicht zweistellige Zahlen stellenweise von rechts (47 gilt als größer als 52, weil 7 größer als 2 ist) — der Stellenwert steuert den Vergleich noch nicht

### zahlvergleich-ordnen.ZR10

- **Beschreibung:** Zahlen vergleichen und der Größe nach ordnen — im ZR10
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A; KMK Bildungsstandards Primarbereich (2022)
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind legt Zahlkarten paarweise richtig, bringt aber vier Karten nicht in eine Reihe — jede neue Karte wird nur mit der zuletzt gelegten verglichen
  - *ikonisch* — Kind ordnet Mengenbilder nach Größe der Abbildung statt nach Anzahl der Elemente
  - *symbolisch* — Kind ordnet, indem es die Zahlwortreihe von 1 an durchgeht und die genannten Zahlen abhakt — richtig, aber zählend; sichtbar an der Latenz bei großen Zahlen der Auswahl

### zahlvergleich-ordnen.ZR20

- **Beschreibung:** Zahlen vergleichen und der Größe nach ordnen — im ZR20
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **Übungen im Bestand:** C2.1
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Beim Ordnen von Zahlkarten über die Zehn hinweg werden 12 und 21 vertauscht — die Ziffernfolge wird gelesen, nicht der Zahlwert
  - *ikonisch* — Kind ordnet abgebildete Mengen richtig, solange die Zehnerstruktur sichtbar bleibt, und scheitert bei unstrukturierter Darstellung derselben Anzahlen
  - *symbolisch* — Die Ordnung stimmt innerhalb der Zehner und bricht am Übergang; 20 wird ans Ende gestellt, weil es als „neue Reihe" und nicht als Zahl behandelt wird

### zahlvergleich-ordnen.ZR100

- **Beschreibung:** Zahlen vergleichen und der Größe nach ordnen — im ZR100
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz, Stellenwertverständnis
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Beim Ordnen gelegter Zahlen zählt das Kind jede Zahl vollständig ab, statt zuerst die Zehnerstangen zu vergleichen
  - *ikonisch* — Am Zahlenstrahl oder Hunderterfeld ordnet das Kind nach der Position, die es zuerst findet, und korrigiert nicht, wenn die Reihenfolge dadurch widersprüchlich wird
  - *symbolisch* — Zahlen mit gleicher Zehnerziffer werden nach der Einerziffer richtig geordnet, Zahlen mit vertauschten Ziffern (36 und 63) dagegen nicht — der Stellenwert steuert die Ordnung nicht

### zerlegung.ZR10

- **Beschreibung:** Zahlen in Teilmengen zerlegen und aus Teilmengen zusammensetzen — im ZR10
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A; Wartha/Schulz, Zahlzerlegung als Kern der Ablösung vom zählenden Rechnen (Kap. n.n. — Seitenbeleg folgt nach Ankunft); Selter/Spiegel
- **Übungen im Bestand:** S1.2, Z1
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind findet eine Zerlegung, aber keine zweite, ohne die Menge neu zu legen; die Zerlegungen einer Zahl bilden noch kein System
  - *ikonisch* — Im Bild wird die verdeckte Teilmenge durch Abzählen der sichtbaren und Weiterzählen bestimmt statt durch Abruf der Zerlegung
  - *symbolisch* — Die Zerlegungen der 10 sind nicht automatisiert: auf „7 und wie viel sind 10?" folgt zählendes Ergänzen mit langer Latenz statt sofortiger Nennung

### zerlegung.ZR20

- **Beschreibung:** Zahlen in Teilmengen zerlegen und aus Teilmengen zusammensetzen — im ZR20
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind zerlegt 14 nicht in 10 und 4, sondern in beliebige Teile, die es einzeln abzählt — die Zehn ist keine bevorzugte Teilmenge
  - *ikonisch* — Am Zwanzigerfeld wird die Zerlegung in volle Zehnerreihe und Rest nicht abgelesen; das Kind zählt beide Teile einzeln
  - *symbolisch* — Die Zerlegung in Zehner und Einer (14 = 10 + 4) gelingt, die nicht-dekadische (14 = 8 + 6) nicht — Zerlegen ist an die Stellenschreibweise gebunden statt an die Zahl

### zerlegung.ZR100

- **Beschreibung:** Zahlen in Teilmengen zerlegen und aus Teilmengen zusammensetzen — im ZR100
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz; Padberg/Benz (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind zerlegt 60 in Stangen nur als 60 = 60, findet aber 60 = 40 + 20 nicht, ohne alle Einer nachzuzählen
  - *ikonisch* — Am Hunderterfeld wird eine Zahl nicht in Zehner und Einer zerlegt gesehen; die Markierung wird als eine ungegliederte Fläche gelesen
  - *symbolisch* — Kind zerlegt 46 in 40 und 6, kann aber 46 nicht als 30 und 16 denken — die Zerlegung ist auf die Stellenschreibweise festgelegt und für das Rechnen nicht beweglich

### verdoppeln-halbieren.ZR10

- **Beschreibung:** Verdoppeln und Halbieren als abrufbare Beziehung, nicht als Rechenweg — im ZR10
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A; Padberg/Benz, Verdoppeln als Kernaufgabe (Kap. n.n. — Seitenbeleg folgt nach Ankunft); Krajewski, Anzahlerfassung strukturierter Mengen; RLP BE/BB Teil C, L1, Niveaustufe A (Kernaufgaben); Wartha/Schulz, Ablösung vom zählenden Rechnen (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **Übungen im Bestand:** S3.1
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind legt die zweite Menge nicht parallel zur ersten, sondern zählt die Gesamtmenge anschließend von 1 an ab; die Verdopplung wird als Zählaufgabe behandelt statt als Struktur
  - *ikonisch* — Kind liest die gespiegelte Menge nicht als Kopie der ersten, sondern zählt alle abgebildeten Punkte einzeln; alternativ nennt es die Ausgangszahl statt des Doppelten
  - *symbolisch* — 4+4 wird zählend gelöst — lange Latenz, gehäufte ±1-Fehler; die Kernaufgabe ist nicht abrufbar, sondern wird jedes Mal neu errechnet

### verdoppeln-halbieren.ZR20

- **Beschreibung:** Verdoppeln und Halbieren als abrufbare Beziehung, nicht als Rechenweg — im ZR20
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Schipper, Handbuch (Rechenschiffchen, Kap. n.n. — Seitenbeleg folgt nach Ankunft); Padberg/Benz, Zehnerübergang (Kap. n.n. — Seitenbeleg folgt nach Ankunft); Selter/Spiegel, denkendes gegen zählendes Rechnen
- **Übungen im Bestand:** S3.4, S3.5, S3.2
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind nutzt die Fünferstruktur des Rechenschiffchens nicht: bei 7+7 kein Zugriff auf 5+5 und 2+2, stattdessen Einzelbelegung und Abzählen der Gesamtmenge
  - *ikonisch* — Kind zählt am abgebildeten Zwanzigerfeld weiter, statt die zweite Reihe als Kopie der ersten zu lesen; der Zehnerübergang beim Verdoppeln (8+8) wird zählend überbrückt
  - *symbolisch* — Verdopplungen bis 10+10 sind nicht automatisiert; Nachbaraufgaben werden nicht abgeleitet (7+8 wird neu gerechnet statt über 7+7+1) — erkennbar an gleich langer Latenz für Kern- und Nachbaraufgabe

### verdoppeln-halbieren.ZR100

- **Beschreibung:** Verdoppeln und Halbieren als abrufbare Beziehung, nicht als Rechenweg — im ZR100
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz, Bündelung und Stellenwert; Schipper, Handbuch (Kap. n.n. — Seitenbeleg folgt nach Ankunft); RLP BE/BB Teil C, L1, Niveaustufe B (halbschriftliche Strategien); Padberg/Benz (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **Übungen im Bestand:** S3.6
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind verdoppelt Zehnerstangen zählend statt bündelweise; beim Halbieren einer Zehnerzahl mit ungerader Zehnerziffer (50 zu 25) wird nicht umgebündelt, das Ergebnis bleibt bei „zweieinhalb Stangen" stehen
  - *ikonisch* — Am Hunderterfeld oder am Zahlenstrahl wird die Verdopplung als Weiterzählen in Einerschritten dargestellt; dass der zweite Sprung genauso lang ist wie der erste, wird nicht erkannt
  - *symbolisch* — 25+25 wird stellenweise neu ausgerechnet, statt die Verdopplung abzurufen; bei 26+26 werden Zehner und Einer getrennt verdoppelt und der Übertrag geht verloren (Antwort 412 statt 52)

### buendeln-entbuendeln.ZR10

- **Beschreibung:** zehn Einer zu einem Zehner bündeln und wieder entbündeln — im ZR10
- **lebende Repräsentation:** enaktiv, ikonisch
- **leitende Repräsentation:** ikonisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A; Moser Opitz, Bündelung bei rechenschwachen Kindern
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind zählt zehn Einer richtig ab, tauscht sie aber nicht gegen eine Zehnerstange — der Tausch gilt als Verlust von neun Dingen statt als Umformung derselben Menge
  - *ikonisch* — Im Bild wird die eingekreiste Zehnergruppe als „eins" mitgezählt, so dass zehn Einer und ein Zehnerbündel zusammen als elf gelesen werden

### buendeln-entbuendeln.ZR20

- **Beschreibung:** zehn Einer zu einem Zehner bündeln und wieder entbündeln — im ZR20
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Beim Entbündeln (eine Stange gegen zehn Einer) verliert das Kind die Gesamtmenge aus dem Blick und zählt anschließend alles neu ab
  - *ikonisch* — Kind liest ein Bild aus einem Zehnerbündel und Einern nicht als zweistellige Zahl, sondern zählt die Einer des Bündels mit ab
  - *symbolisch* — „Wie viele Zehner sind in 17?" wird mit 17 oder mit 7 beantwortet — die Frage nach dem Bündel wird als Frage nach der Ziffer gelesen

### buendeln-entbuendeln.ZR100

- **Beschreibung:** zehn Einer zu einem Zehner bündeln und wieder entbündeln — im ZR100
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz; KMK Bildungsstandards Primarbereich (2022)
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind legt 43 als 43 Einer, statt vier Stangen und drei Einer zu nehmen; oder es bündelt beim Überschreiten der Zehn nicht nach und behält elf Einer liegen
  - *ikonisch* — Im Bild aus Stangen und Einern wird die Anzahl der Teile genannt (sieben) statt der dargestellten Zahl (43) — Bündel und Einzelding werden gleich gewertet
  - *symbolisch* — „Wie viele Zehner hat 43?" wird richtig beantwortet, „wie viele Einer hat 43?" dagegen mit 3 statt 43 — je nach Lesart der Frage; die Unterscheidung Ziffernwert/Gesamtzahl ist unklar

### stellenwerttafel.ZR20

- **Beschreibung:** Ziffernwert und Stellenwert unterscheiden, Zahlen in Z und E zerlegen — im ZR20
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Moser Opitz, Stellenwertverständnis
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind legt zu 17 sieben Einer in die Zehnerspalte und einen in die Einerspalte — die Spalte wird nach der Schreibrichtung der Ziffern belegt, nicht nach dem Wert
  - *ikonisch* — Kind liest eine abgebildete Tafel richtig, kann aber zu einem Bild aus Stange und Einern die Tafel nicht ausfüllen — die Übersetzung läuft nur in eine Richtung
  - *symbolisch* — Bei 1 Zehner und 3 Einern schreibt das Kind 31 — die Ziffern werden in der Reihenfolge der Nennung notiert statt nach Stellenwert

### stellenwerttafel.ZR100

- **Beschreibung:** Ziffernwert und Stellenwert unterscheiden, Zahlen in Z und E zerlegen — im ZR100
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz; KMK Bildungsstandards Primarbereich (2022)
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind legt zu 52 fünf Einer und zwei Stangen (Ziffern in der Lesereihenfolge auf die Spalten verteilt) — die Zahlendreher zeigen sich am Material genauso wie in der Schrift
  - *ikonisch* — Aus einer abgebildeten Tafel wird die Zahl gebildet, indem die Anzahl aller Plättchen genannt wird (7 für 5 Zehner und 2 Einer) statt der Stellenwert berücksichtigt
  - *symbolisch* — Zahlendreher: 41 wird als 14 geschrieben oder gelesen; oder die Rückrichtung fehlt — das Kind zerlegt 41 in 4 Zehner und 1 Einer, bildet aber aus „4 Zehner, 1 Einer" nicht wieder 41

### zahlenstrahl.ZR10

- **Beschreibung:** Zahlen am Strahl verorten, ablesen und Abstände deuten — im ZR10
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A; Schipper, Handbuch (Zahlenband, Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind legt die Zahlkarte an das Zahlenband, indem es von 0 an jeden Schritt abzählt; ohne beschriftete Zwischenmarken misslingt die Platzierung ganz
  - *ikonisch* — Kind trifft beim Zeigen die Zwischenräume statt der Marken oder verschiebt sich um eins, weil es die 0 als erste Marke mitzählt
  - *symbolisch* — Kind kann zu einer markierten Stelle keine Zahl nennen, ohne die Marken von 0 an abzuzählen — die Position trägt noch keine Zahlbedeutung

### zahlenstrahl.ZR20

- **Beschreibung:** Zahlen am Strahl verorten, ablesen und Abstände deuten — im ZR20
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **Übungen im Bestand:** C10.1
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Beim Gehen oder Schieben am Zahlenband verliert das Kind an der 10 die Orientierung und beginnt die zweite Hälfte neu bei 1
  - *ikonisch* — Zahlen werden nur an beschrifteten Marken gefunden; zwischen 10 und 20 platziert das Kind gleichmäßig verteilt statt nach Wert
  - *symbolisch* — Kind liest die markierte Stelle ab, indem es alle Marken zählt; der Abstand zwischen zwei Zahlen wird nicht als Differenz gedeutet

### zahlenstrahl.ZR100

- **Beschreibung:** Zahlen am Strahl verorten, ablesen und Abstände deuten — im ZR100
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; Padberg/Benz, Zahlenstrahl und Zahlvorstellung (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **Übungen im Bestand:** C10.2
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Am langen Zahlenband nutzt das Kind die Zehnermarken nicht als Ankerpunkte, sondern zählt von 0 an in Einern — bei 60 bricht der Versuch ab
  - *ikonisch* — Kind verortet 47 ohne Bezug zu 50 als Ankerpunkt; die Schätzung landet in der falschen Dekade oder klebt am linken Rand
  - *symbolisch* — Kind liest an einem Strahl mit unbeschrifteten Zwischenmarken ab, ohne die Schrittweite zu bestimmen — jede Marke gilt als ein Schritt von eins

### addition-ohne-uebergang.ZR10

- **Beschreibung:** addieren ohne Überschreiten der Zehnergrenze — im ZR10
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A; Wartha/Schulz (Kap. n.n. — Seitenbeleg folgt nach Ankunft); Selter/Spiegel, zählendes Rechnen
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind legt beide Mengen und zählt anschließend alles von 1 an ab (Alleszählen), statt von der ersten Menge aus weiterzuzählen oder die Summe abzurufen
  - *ikonisch* — Im Bild werden beide Teilmengen einzeln abgezählt; die zweite Menge wird nicht als Weiterzählschritt oder als bekannte Zerlegung genutzt
  - *symbolisch* — Aufgaben im Zehnerraum werden mit den Fingern zählend gelöst; die Latenz wächst mit dem zweiten Summanden — das sichere Kennzeichen des Weiterzählens

### addition-ohne-uebergang.ZR20

- **Beschreibung:** addieren ohne Überschreiten der Zehnergrenze — im ZR20
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Bei 13+4 baut das Kind die 13 vollständig aus Einern auf, statt die Zehnerstange zu nehmen und nur im Einerbereich zu rechnen
  - *ikonisch* — Am Zwanzigerfeld wird ab dem ersten Feld weitergezählt statt ab der vollen Zehnerreihe; die zweite Reihe wird nicht als „zehn und Rest" gelesen
  - *symbolisch* — 13+4 wird als 1+3+4 verarbeitet oder in Einerschritten hochgezählt; die Zehnerstelle wird beim Rechnen nicht konstant gehalten

### addition-ohne-uebergang.ZR100

- **Beschreibung:** addieren ohne Überschreiten der Zehnergrenze — im ZR100
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz; Padberg/Benz, halbschriftliche Addition (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **Übungen im Bestand:** S3.7
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Bei 42+30 legt das Kind dreißig Einer statt drei Stangen; oder es legt richtig, zählt zur Ergebnisbestimmung aber alle Einer der Stangen einzeln nach
  - *ikonisch* — Am Hunderterfeld wird der Zehnersprung als Weiterzählen in Einern ausgeführt; der Zeilensprung als Zehnerschritt ist nicht verfügbar
  - *symbolisch* — 42+30 wird zu 45 oder 72 — Zehner und Einer werden vermischt, weil der zweite Summand nicht als Zehnerzahl erkannt wird

### addition-mit-uebergang.ZR20

- **Beschreibung:** addieren über die Zehnergrenze — im ZR20
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Wartha/Schulz, Zehnerübergang (Kap. n.n. — Seitenbeleg folgt nach Ankunft); Selter/Spiegel
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind füllt die Zehnerreihe nicht zuerst auf, sondern legt den zweiten Summanden am Stück irgendwo an und zählt danach alles nach — der Schritt über die Zehn wird nicht als Zwischenziel genutzt
  - *ikonisch* — Am Zwanzigerfeld wird der zweite Summand nicht in „bis zur Zehn" und „Rest" zerlegt; das Kind zählt über den Reihenwechsel hinweg Feld für Feld und verzählt sich dort
  - *symbolisch* — 8+5 wird zählend gelöst statt über 8+2+3; typische Ergebnisse sind 12 oder 14 (Verzählen um eins am Übergang), bei langer Latenz

### addition-mit-uebergang.ZR100

- **Beschreibung:** addieren über die Zehnergrenze — im ZR100
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz, Bündeln beim Rechnen; Padberg/Benz, halbschriftliche Strategien (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Bei 47+8 entstehen fünfzehn Einer, die liegen bleiben — das Nachbündeln zu einer neuen Zehnerstange unterbleibt, die Zahl wird nicht wieder normalisiert
  - *ikonisch* — Am Hunderterfeld wird der Dekadenwechsel beim Weitergehen übersprungen oder verdoppelt; das Kind landet eine Zeile zu tief
  - *symbolisch* — 47+8 wird zu 45 oder 55: die Einer werden addiert und der Übertrag entweder vergessen oder zweimal gezählt; die Zehnerstelle wird nicht angepasst

### subtraktion-ohne-uebergang.ZR10

- **Beschreibung:** subtrahieren ohne Unterschreiten der Zehnergrenze — im ZR10
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A; Wartha/Schulz (Kap. n.n. — Seitenbeleg folgt nach Ankunft); Selter/Spiegel
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind nimmt weg und zählt den Rest vollständig neu ab; der Zusammenhang zwischen Ausgangsmenge, weggenommener Menge und Rest wird nicht genutzt
  - *ikonisch* — Im Bild werden durchgestrichene Elemente mitgezählt oder das Kind zählt die durchgestrichenen statt der verbliebenen — die Frage nach dem Rest wird als Frage nach dem Weggenommenen gelesen
  - *symbolisch* — 9−3 wird durch Rückwärtszählen in Einern gelöst; bei größerem Subtrahenden häufen sich ±1-Fehler, weil der Startwert mitgezählt wird

### subtraktion-ohne-uebergang.ZR20

- **Beschreibung:** subtrahieren ohne Unterschreiten der Zehnergrenze — im ZR20
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Bei 17−4 löst das Kind die Zehnerstange auf, obwohl im Einerbereich genug vorhanden ist — die Zahl wird zum Rechnen unnötig in Einer zerlegt
  - *ikonisch* — Am Zwanzigerfeld wird von 20 an rückwärts gezählt statt von der dargestellten Zahl aus; die Darstellung wird nicht als Ausgangswert gelesen
  - *symbolisch* — 17−4 wird zu 13 gerechnet, 14−3 aber zu 11 — die Zehnerstelle wird beim Rechnen nicht konstant gehalten, sondern in die Subtraktion einbezogen

### subtraktion-ohne-uebergang.ZR100

- **Beschreibung:** subtrahieren ohne Unterschreiten der Zehnergrenze — im ZR100
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz; Padberg/Benz (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Bei 68−30 nimmt das Kind dreißig Einer weg statt drei Stangen und verliert dabei den Überblick über den Rest
  - *ikonisch* — Am Hunderterfeld wird der Zehnerschritt rückwärts in Einern gegangen; die Zeile als Zehnereinheit wird beim Wegnehmen nicht genutzt
  - *symbolisch* — 68−30 wird zu 38 gerechnet, 68−3 aber ebenfalls zu 38 — Zehner und Einer des Subtrahenden werden nicht unterschieden

### subtraktion-mit-uebergang.ZR20

- **Beschreibung:** subtrahieren über die Zehnergrenze — im ZR20
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Wartha/Schulz (Kap. n.n. — Seitenbeleg folgt nach Ankunft); Selter/Spiegel
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Bei 13−5 nimmt das Kind erst die drei Einer weg und weiß dann nicht weiter; das Entbündeln der Zehnerstange als Fortsetzung des Schritts unterbleibt
  - *ikonisch* — Am Zwanzigerfeld wird beim Rückwärtsgehen der Reihenwechsel doppelt gezählt; typisch ist ein Ergebnis, das um eins zu groß oder zu klein ist
  - *symbolisch* — 13−5 wird zu 8 nur über zählendes Rückwärtsgehen erreicht, oder das Kind rechnet die kleinere Ziffer von der größeren ab und antwortet 12

### subtraktion-mit-uebergang.ZR100

- **Beschreibung:** subtrahieren über die Zehnergrenze — im ZR100
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz, Entbündeln; Padberg/Benz (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Bei 52−7 wird nicht entbündelt: das Kind nimmt eine ganze Zehnerstange weg und antwortet 42, oder es legt die Aufgabe gar nicht erst
  - *ikonisch* — Am Hunderterfeld wird der Dekadenwechsel rückwärts übersprungen; das Kind landet in der falschen Zeile und korrigiert nicht, weil es die Zeile nicht als Zehner liest
  - *symbolisch* — 52−7 wird zu 55: die kleinere Einerziffer wird von der größeren abgezogen, ohne den Zehner anzutasten — der klassische Stellenwertfehler der Subtraktion

### ergaenzen.ZR10

- **Beschreibung:** zu einem Zielwert ergänzen, Subtraktion als Ergänzung deuten — im ZR10
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A; Wartha/Schulz, Ergänzen als Subtraktionsdeutung (Kap. n.n. — Seitenbeleg folgt nach Ankunft); Selter/Spiegel
- **Übungen im Bestand:** Z2
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Kind legt zur Ergänzung auf zehn einzeln nach und zählt nach jedem Plättchen die Gesamtmenge neu; die Zerlegung der Zehn wird nicht genutzt
  - *ikonisch* — Im Bild werden die freien Felder einzeln abgezählt statt als Rest der Zehnerstruktur gelesen
  - *symbolisch* — „6 + ? = 10" wird zählend gelöst; bei der gleichwertigen Form „10 − 6" antwortet dasselbe Kind schneller — Ergänzen und Wegnehmen sind noch nicht dieselbe Aufgabe

### ergaenzen.ZR20

- **Beschreibung:** zu einem Zielwert ergänzen, Subtraktion als Ergänzung deuten — im ZR20
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A/B
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Beim Ergänzen von 13 auf 20 legt das Kind bis 20 einzeln nach, statt zuerst auf die volle Zehnerreihe und dann weiter zu ergänzen
  - *ikonisch* — Am Zwanzigerfeld wird die Lücke bis zur nächsten vollen Reihe nicht als Zwischenziel erkannt; das Kind zählt die freien Felder komplett durch
  - *symbolisch* — Kind löst „7 + ? = 15" durch Weiterzählen, oder es liest die Aufgabe als 7 + 15 und antwortet 22 — die Leerstelle wird nicht als gesuchte Größe verstanden

### ergaenzen.ZR100

- **Beschreibung:** zu einem Zielwert ergänzen, Subtraktion als Ergänzung deuten — im ZR100
- **lebende Repräsentation:** enaktiv, ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** enaktiv
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; Moser Opitz; Padberg/Benz (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *enaktiv* — Beim Ergänzen von 47 auf 100 legt das Kind Einer nach, statt zuerst auf 50 und dann in Zehnern weiterzugehen
  - *ikonisch* — Am Hunderterfeld wird der Rest bis 100 nicht über volle Zeilen bestimmt, sondern feldweise abgezählt — die Aufgabe wird zur Zählstrecke
  - *symbolisch* — „47 + ? = 60" wird stellenweise beantwortet (Antwort 23, aus 6−4 und 0−7 rückwärts gelesen); der Zehnerübergang beim Ergänzen wird nicht vollzogen

### flexibles-rechnen.ZR20

- **Beschreibung:** zwischen Rechenwegen wählen und Aufgaben aus Nachbaraufgaben ableiten — im ZR20
- **lebende Repräsentation:** ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** ikonisch
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Selter/Spiegel, Rechenwege von Kindern; Padberg/Benz, Nachbaraufgaben und Aufgabenbeziehungen (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **Übungen im Bestand:** S2.3
- **Fehlerbilder je Repräsentation:**
  - *ikonisch* — Kind kann zwei angebotene Lösungswege am Bild nicht unterscheiden oder hält den umständlicheren für den richtigen, weil er dem eingeübten Ablauf folgt
  - *symbolisch* — Kind rechnet 7+8 neu aus, obwohl 7+7 unmittelbar davor stand — Aufgabenbeziehungen werden nicht genutzt; Latenz und Weg sind bei Kern- und Nachbaraufgabe identisch

### flexibles-rechnen.ZR100

- **Beschreibung:** zwischen Rechenwegen wählen und Aufgaben aus Nachbaraufgaben ableiten — im ZR100
- **lebende Repräsentation:** ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** ikonisch
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; Selter/Spiegel; Padberg/Benz (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *ikonisch* — Am Hunderterfeld wählt das Kind immer denselben Weg (Einerschritte), auch wo ein Zehnersprung sichtbar kürzer wäre
  - *symbolisch* — Bei 49+26 rechnet das Kind stur stellenweise, statt über 50 zu gehen; auch nach richtigem Ergebnis bleibt der Weg bei jeder Aufgabe derselbe — Strategiewahl findet nicht statt

### sachsituationen.ZR10

- **Beschreibung:** aus einer Situation die passende Rechnung gewinnen und zurückdeuten — im ZR10
- **lebende Repräsentation:** ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** ikonisch
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A; KMK Bildungsstandards Primarbereich (2022), Modellieren
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *ikonisch* — Kind entnimmt dem Bild die Zahlen, aber nicht die Handlung, und addiert grundsätzlich — die Richtung der Situation (dazu oder weg) wird nicht gelesen
  - *symbolisch* — Kind rechnet mit den beiden genannten Zahlen, ohne die Frage zu beachten; das Ergebnis ist rechnerisch richtig und beantwortet die gestellte Frage nicht

### sachsituationen.ZR20

- **Beschreibung:** aus einer Situation die passende Rechnung gewinnen und zurückdeuten — im ZR20
- **lebende Repräsentation:** ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** ikonisch
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Schipper, Handbuch (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *ikonisch* — Bei Vergleichssituationen („wie viele mehr?") wird addiert statt die Differenz gebildet — der Unterschied wird nicht als eigene Größe erkannt
  - *symbolisch* — Signalwörter steuern die Rechnung statt der Situation: „mehr" führt immer zu Plus, auch wenn nach dem Ausgangswert gefragt ist

### sachsituationen.ZR100

- **Beschreibung:** aus einer Situation die passende Rechnung gewinnen und zurückdeuten — im ZR100
- **lebende Repräsentation:** ikonisch, symbolisch
- **leitende Repräsentation:** symbolisch
- **stützende Repräsentation:** ikonisch
- **Quellen:** RLP BE/BB Teil C, L1, Niveaustufe B; KMK Bildungsstandards Primarbereich (2022), Modellieren
- **Übungen im Bestand:** —
- **Fehlerbilder je Repräsentation:**
  - *ikonisch* — Kind übernimmt aus der Abbildung alle sichtbaren Zahlen in die Rechnung, auch die für die Frage unerheblichen
  - *symbolisch* — Kind rechnet richtig, deutet das Ergebnis aber nicht zurück auf die Situation — eine unplausible Antwort (mehr Kinder als in der Klasse) bleibt unbemerkt

<!-- AUTOGEN:ENDE -->
