# 15 — Darstellungsregister (v2)

| | |
|---|---|
| **Status** | Entwurf — Gate 1 offen |
| **Stand** | 2026-09-08 |
| **Owner** | Jakob |
| **Gate** | `python scripts/check_item_quality.py` |

Ein Item nennt in `darstellung:` einen Schlüssel aus diesem Register. Der Schlüssel bindet
den Wortlaut an genau ein Widget. In v1 wurden Text und Widget getrennt gepflegt — die
Aufgabe fragte nach Stäbchen, der Bildschirm zeigte Würfel (00-v1-assessment.md, Anhang A).
Seitdem ist die Paarung eine geprüfte Tabelle: `check_item_quality.py` schlägt fehl, wenn ein
Item einen Schlüssel nennt, den es hier nicht gibt, oder wenn die Widget-Klasse im
Flutter-Quelltext fehlt.

Alle Manipulative hier sind gemeinfreie Fachdidaktik-Standards und tragen kein
Clean-Room-Risiko (ADR-Lage unverändert): Dienes, Rechenschiffchen, Zehnerfeld, Rekenrek,
Fingerbilder, Zahlenstrahl, Plättchen.

| key | Widget-Klasse | Manipulativ | Zahlenräume |
|---|---|---|---|
| `keine` | — | keine Darstellung, rein symbolisch | ZR10, ZR20, ZR100 |
| `zehnerfeld` | `ZehnerfeldWidget` | Zehnerfeld 5×2 | ZR10, ZR20 |
| `zehnerfeld-vergleich` | `VergleichZehnerfelderWidget` | zwei Zehnerfelder nebeneinander | ZR10, ZR20 |
| `rekenrek` | `RekenrekWidget` | Rechenrahmen, zwei Stangen | ZR10, ZR20 |
| `rekenrek-blitz` | `RekenrekFlashWidget` | Rechenrahmen, kurze Darbietung | ZR10 |
| `rekenrek-vergleich` | `VergleichRekenrekWidget` | zwei Rechenrahmen nebeneinander | ZR10, ZR20 |
| `fingerbild` | `FingerBildWidget` | Fingerbild, Fünferstruktur | ZR10, ZR20 |
| `dienes` | `DienesPlaceValueWidget` | Zehnerstangen und Einerwürfel | ZR100 |
| `dienes-oeffnen` | `DienesOeffnenWidget` | Zehnerstange antippen und entbündeln | ZR20, ZR100 |
| `staebchen` | `StaebchenWidget` | Stäbchen, lose | ZR10, ZR20 |
| `staebchen-buendel` | `StaebchenBundelWidget` | Stäbchen in Zehnerbündeln | ZR20, ZR100 |
| `staebchen-einzeln` | `StaebchenEinzelWidget` | Stäbchen einzeln | ZR10, ZR20 |
| `staebchen-oeffnen` | `StaebchenOeffnenWidget` | Zehnerbündel antippen und öffnen | ZR20, ZR100 |
| `stellenwerttafel` | `StellenwerttafelWidget` | Tafel mit Z- und E-Spalte | ZR100 |
| `zahlenstrahl-pfeil` | `ZahlenstrahlArrowWidget` | Zahlenstrahl, Pfeil zeigt auf einen Wert | ZR10, ZR20, ZR100 |
| `zahlenstrahl-markieren` | `ZahlenstrahlMarkWidget` | Zahlenstrahl, Kind setzt die Marke | ZR10, ZR20, ZR100 |
| `wuerfelbild` | `DiceWidget` | Würfelbild | ZR10 |

**Lücken, die Phase 3 füllen muss.** Für `zwanzigerfeld` und `hunderterfeld` gibt es im
Diagnostik-Bestand noch kein Widget; die Übungs-Engine hat mit `InteractiveTwentyFrameWidget`
und den `Count100Field…`-Widgets Kandidaten, die erst gesichtet werden müssen. Bis dahin
steht hier kein Schlüssel dafür — ein Item darf nichts nennen, was nicht gebaut ist.
