# 10 — Deckungsmatrix (v2)

| | |
|---|---|
| **Status** | 🚧 in Arbeit — nicht freigegeben |
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

Die Spalte `übung:` verweist auf `exercise_id` aus
[inventory_uebungen.csv](inventory_uebungen.csv) — dem Bestand der handgebauten Engine.
`—` heißt: noch nichts zugeordnet.

## Vokabular

**Stränge:**
- `verdoppeln-halbieren` — Verdoppeln und Halbieren als abrufbare Beziehung, nicht als Rechenweg

**Zahlenräume:** ZR10 · ZR20 · ZR100
**Repräsentationen:** enaktiv · ikonisch · symbolisch
**Status:** offen · entworfen · freigegeben · – (bewusst nicht abgedeckt)

> Die übrigen Stränge folgen in Task 5 des Phase-1-Plans. Dieses Dokument beginnt bewusst
> mit einem einzigen, vollständig durchgeschriebenen Strang: `verdoppeln-halbieren` ist
> genau der Konstruktbereich, den v1 in ZR20 nur indirekt und in ZR100 gar nicht erfasst hat.

## Strang: verdoppeln-halbieren

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | offen |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

**Befund zum Übungsbestand:** die alte Engine deckt das *Verdoppeln* über sechs Übungen
(`S3.1`–`S3.6`) breit ab, das *Halbieren* dagegen **an keiner einzigen Stelle**. Das ist eine
echte Lücke im Bestand, keine Lücke der Dokumentation: die Umkehrrichtung muss in Phase 2
neu gebaut werden. Bis dahin bleiben die Halbieren-Anteile der Zellen unbelegt.

### verdoppeln-halbieren × ZR10 × enaktiv

- **quelle:** RLP BE/BB Teil C, Zahlen und Operationen (Kl. 1, ZR bis 10); Padberg/Benz, Verdoppeln als Kernaufgabe (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind legt die zweite Menge nicht parallel zur ersten, sondern zählt die Gesamtmenge anschließend von 1 an ab; die Verdopplung wird als Zählaufgabe behandelt statt als Struktur (zählendes Rechnen)
- **diagnostik:** —
- **übung:** S3.3

### verdoppeln-halbieren × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, Zahlen und Operationen (Kl. 1); Krajewski, Anzahlerfassung strukturierter Mengen
- **fehlerbild:** Kind liest die gespiegelte Menge nicht als Kopie der ersten, sondern zählt alle abgebildeten Punkte einzeln; alternativ nennt es die Ausgangszahl statt des Doppelten (Verwechslung von Verdoppeln und Halbieren)
- **diagnostik:** —
- **übung:** S3.1

### verdoppeln-halbieren × ZR10 × symbolisch

- **quelle:** RLP BE/BB Teil C (Kernaufgaben Kl. 1); Wartha/Schulz, Ablösung vom zählenden Rechnen (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** 4+4 wird zählend gelöst — lange Latenz, gehäufte ±1-Fehler; die Kernaufgabe ist nicht abrufbar, sondern wird jedes Mal neu errechnet
- **diagnostik:** —
- **übung:** —

### verdoppeln-halbieren × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, Zahlen und Operationen (Kl. 1/2, ZR bis 20); Schipper, Handbuch (Rechenschiffchen/Zwanzigerfeld, Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind nutzt die Fünferstruktur des Rechenschiffchens nicht: bei 7+7 kein Zugriff auf 5+5 und 2+2, stattdessen Einzelbelegung und Abzählen der Gesamtmenge
- **diagnostik:** —
- **übung:** S3.4, S3.5

### verdoppeln-halbieren × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C (Kl. 1/2); Padberg/Benz, Zehnerübergang (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Kind zählt am abgebildeten Zwanzigerfeld weiter, statt die zweite Reihe als Kopie der ersten zu lesen; der Zehnerübergang beim Verdoppeln (8+8) wird zählend überbrückt statt über 8+2+6 strukturiert
- **diagnostik:** —
- **übung:** S3.2

### verdoppeln-halbieren × ZR20 × symbolisch

- **quelle:** RLP BE/BB Teil C (Kernaufgaben und Nachbaraufgaben, Kl. 2); Selter/Spiegel, denkendes vs. zählendes Rechnen
- **fehlerbild:** Verdopplungen bis 10+10 sind nicht automatisiert; Nachbaraufgaben werden nicht abgeleitet (7+8 wird neu gerechnet statt über 7+7+1) — erkennbar an gleich langer Latenz für Kern- und Nachbaraufgabe
- **diagnostik:** —
- **übung:** —

### verdoppeln-halbieren × ZR100 × enaktiv

- **quelle:** RLP BE/BB Teil C (Kl. 2, ZR bis 100); Moser Opitz, Bündelung und Stellenwert
- **fehlerbild:** Kind verdoppelt Zehnerstangen zählend statt bündelweise; beim Halbieren einer Zehnerzahl mit ungerader Zehnerziffer (50 → 25) wird nicht umgebündelt, das Ergebnis bleibt bei „zweieinhalb Stangen“ stehen oder wird auf 20 abgerundet
- **diagnostik:** —
- **übung:** —

### verdoppeln-halbieren × ZR100 × ikonisch

- **quelle:** RLP BE/BB Teil C (Kl. 2, Hunderterfeld und Zahlenstrahl); Schipper, Handbuch (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** Am Hunderterfeld oder am Zahlenstrahl wird die Verdopplung als Weiterzählen in Einerschritten dargestellt; dass der zweite Sprung genauso lang ist wie der erste, wird nicht erkannt
- **diagnostik:** —
- **übung:** —

### verdoppeln-halbieren × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C (Kl. 2, halbschriftliche Strategien); Padberg/Benz, Verdoppeln im Hunderterraum (Kap. n.n. — Seitenbeleg folgt nach Ankunft)
- **fehlerbild:** 25+25 wird stellenweise neu ausgerechnet, statt die Verdopplung abzurufen — lange Latenz, keine Verdopplungsnennung; bei 26+26 werden Zehner und Einer getrennt verdoppelt und der Übertrag geht verloren (Antwort 412 statt 52)
- **diagnostik:** —
- **übung:** S3.6
