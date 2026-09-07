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
python scripts/extract_exercise_inventory.py   # Inventar neu erzeugen
python scripts/check_deckung.py                # Deckungsgate
python -m unittest discover -s scripts/tests -v # Tests der Prüfskripte
```

Grün heißt *abgedeckt*, nicht *dokumentiert*. Ein Fehlschlag ist ein echtes Loch in
der Matrix oder im Bestand — korrigiert wird das Artefakt, nie die Regel.
