# v2 — Wurzelartefakt Deckungsmatrix

Dieses Verzeichnis hält das Wurzelartefakt des Inhaltsneubaus. Die Deckungsmatrix
ist die Quelle der Wahrheit für alle inhaltlichen Fragen: Konstruktkarte, Blueprint,
Itembank und Übungskatalog werden **aus ihr abgeleitet, nie umgekehrt**. Wo ein
späteres Artefakt ihr widerspricht, gilt die Matrix. Das gilt ausdrücklich auch
gegenüber der Konstruktkarte (v1: `01-construct-map.md`).

Freigegeben von Jakob am **2026-09-07** (Gate 1) — freigegeben ist damit die
**Deckung** (welche Zellen es gibt und warum), nicht der Zellstatus.

## Was liegt wo

- **10-deckungsmatrix.md** — das Wurzelartefakt: 20 Stränge × 3 Zahlenräume
  (ZR10, ZR20, ZR100) × 3 Repräsentationen (enaktiv, ikonisch, symbolisch).
  Je Zelle ein Detailblock mit Quelle, Fehlerbild, Diagnostik-Item und Übung;
  je bewusst nicht abgedeckter Zelle eine begründete Ausnahme. Handgeschrieben,
  hand-signiert, maschinengeprüft.
- **11-konstruktkarte.md** — die 54 Konstrukte (Strang × Zahlenraum), jede
  Repräsentation als Evidenzstufe darin. Präambel handgeschrieben; der Rumpf
  zwischen den AUTOGEN-Marken wird aus der Matrix erzeugt. Ersetzt
  `01-construct-map.md`.
- **12-blueprint.md** — die Item-Zuteilung: je Konstrukt ein Kern-Item, 86
  geplante Items, dazu Reihenfolge, Abkürzung und Blitz-Items. Regeln
  handgeschrieben, Zuteilungstabelle erzeugt. Ersetzt `02-blueprint.md`.
- **14-itemregeln.md** — die Abnahmekriterien I1–I12 für ein Item, je Regel
  der v1-Defekt dahinter; *maschinell* oder *Gate 1*.
- **15-darstellungen.md** — das Register `darstellung`-Schlüssel →
  Widget-Klasse → Manipulativ.
- **items/TEMPLATE.md** — das Itemdateiformat: jedes Feld, das
  `check_item_quality.py` parst, mit gefülltem Beispiel.
- **inventory_uebungen.csv** — erzeugtes Inventar des handgebauten
  Übungsbestands (aus `exercise_service.dart`). Die Spalte `übung:` der Matrix
  verweist auf `exercise_id` aus dieser Datei.
- **items/** — Diagnostik-Items. Noch leer (`.gitkeep`); Phase 2 füllt sie. Der
  Checker löst jede `diagnostik:`-Referenz gegen die Dateien hier auf.
- **uebungen/** — neue Übungen. Noch leer (`.gitkeep`); der Checker löst jede
  `übung:`-Referenz gegen Inventar **oder** gegen die Dateien hier auf.

Stand: **20 Stränge, 180 Zellen, 152 aktiv, 28 Ausnahmen, 0 Zellen freigegeben.**

## Zellstatus

`offen -> entworfen -> freigegeben`

Eine Zelle ist erst `freigegeben`, wenn sie ein Item **und** eine Übung nennt und
beide durch **beide Jakob-Gates** sind: Gate 1 auf Papier (die Zelle ist didaktisch
richtig) und Gate 2 im laufenden Kind-Screen (das Item dort gesehen und geprüft).

Eine Zelle mit `–` ist bewusst nicht abgedeckt. Sie braucht unter `Ausnahmen:`
eine schriftliche Begründung von mindestens 20 Zeichen — ein bloßes `–` ohne Text
lässt das Deckungsgate scheitern.

## Gates

In dieser Reihenfolge nach jeder Änderung an Matrix oder Übungsbestand:

```bash
python scripts/extract_exercise_inventory.py   # Inventar aus exercise_service.dart neu erzeugen
python scripts/check_deckung.py            # Matrix: Deckung, Ausnahmen, Detailblöcke, R1-R9
python scripts/derive_ableitungen.py --check   # Konstruktkarte + Blueprint gegen die Matrix
python scripts/check_item_quality.py       # Items gegen die Itemregeln I1-I12
python -m unittest discover -s scripts/tests -p "test_*.py"
```

Grün heißt *abgedeckt*, nicht *dokumentiert*. Ein Fehlschlag ist ein echtes Loch in
der Matrix oder im Bestand — korrigiert wird das Artefakt, nie die Regel.

## Was abgeleitet ist und was von Hand kommt

`10-deckungsmatrix.md` ist von Hand geschrieben und von Jakob unterschrieben. Alles
darunter fällt daraus:

Matrix -> Konstruktkarte -> Blueprint -> Items/Übungen

Der Rumpf von `11-konstruktkarte.md` und `12-blueprint.md` steht zwischen AUTOGEN-Marken
und wird erzeugt; `--check` schlägt fehl, sobald er von der Matrix abweicht. Die Regeln
oberhalb der Marken und die Dokumente 14/15 sind von Hand geschrieben.

Stand: 20 Stränge, 180 Zellen, 152 lebend, 28 begründete Ausnahmen, **54 Konstrukte,
86 geplante Items, 0 geschriebene Items** (Items sind Phase 3).
