# Formular-Zuordnung: Ist / Soll / Lernweg / Absprachen / Reflexion

| Feld | Wert |
|---|---|
| **Titel** | Formular-Zuordnung: Ist / Soll / Lernweg / Absprachen / Reflexion |
| **Status** | ✅ FREIGEGEBEN — Jakob, 2026-09-04 |
| **Datum** | 2026-08-29 |
| **Owner** | Jakob |
| **Bezug** | tasks.md R6.1 · ADR 0001 (`docs/clean-room/decisions/0001-foerderplan-form-licence.md`) |

## Ausgangslage und Lizenzfrage

ADR 0001 regelt, ob wir die konkrete SenBJF-Vorlage (`foerderplan-pdf_02a.pdf`, Wasserzeichen „SenBildJugFam 2017") als Produktbestandteil reproduzieren dürfen. Die Prüfung ist **offen** (R0.7 unerledigt): Es liegt weder eine zitielfähige Freigabeklausel noch eine Antwort auf die angefragte Klärung vor.

Die Zuordnungsarbeit (R6.1) ist **unter beiden Ausgängen identisch**: Die fünf Spalten und ihre Untertitel (Beobachtung/Bedarf, Ziele, Päd. Angebote/Maßnahmen, Wer?/Wie?/Mit wem?/Bis wann?, Reflexion/Evaluation/Modifikation) sind standarddeutsches pädagogisches Vokabular, das in mehreren Bundesländern für Förderpläne verwendet wird — keine SenBJF-Erfindung. Geschützt wäre allenfalls die konkrete Layout-Anordnung der Vorlage.

Sollte die SenBJF-Vorlage nicht freigegeben werden (oder keine Antwort eingehen), **baut die Fallback-Option eine eigene Fünf-Spalten-Anordnung mit denselben Standardüberschriften** — funktional geht dabei nichts verloren. R6.1 ist daher jetzt abschließbar; die Layout-Entscheidung ist erst für R6.2 (Rendern) relevant.

## Zuordnung der Formularfelder (Spalte → Datenquelle)

| Formularspalte | Datenquelle | Gefüllter Inhalt |
|---|---|---|
| **1 — Ist (Beobachtung/Bedarf)** | `foerderplaene.category_stats` (failed/total je Domäne), `foerderplaene.recommended_skill_ids`, `foerderplaene.slow_response_flag`; `skills.title_de`; `KurzFoerderplanService._buildIst` (`math_app/lib/services/kurz_foerderplan_service.dart:114–136`) bzw. Port `buildKurzRows` (`backend/supabase/functions/foerderplan-kurz-pdf/index.ts:126–137`) | „Im Bereich \<Domäne\> wurden X von Y Aufgaben nicht gelöst." (sofern `stats.failed > 0`), sonst „Im Bereich \<Domäne\> besteht Förderbedarf."; darunter „Beobachtete Schwierigkeiten:" mit einem Bullet je empfohlenem Skill (Skill-Titel `title_de`); in der ersten Zeile zusätzlich bei `slow_response_flag`: „Hinweis: Kind löst Aufgaben zählend statt denkend (verlangsamte Antwortzeiten)." |
| **2 — Soll (Ziele)** | `skills.description_de` je empfohlenem Skill; `_buildSoll` (`kurz_foerderplan_service.dart:138–140`) bzw. Port (`index.ts:140`) | Je Skill ein Bullet „- Das Kind kann: \<description_de\>" |
| **3 — Lernweg (Päd. Angebote/Maßnahmen)** | `skills.title_de` + `skills.description_de`; `_buildLernweg` (`kurz_foerderplan_service.dart:142–149`) bzw. Port (`index.ts:143–147`) | Überschrift „Fördervorschläge:"; je Skill „- \<Skill-Titel\>" mit eingerückter Kurzbeschreibung darunter |
| **4 — Absprachen (Wer? Wie? Mit wem? Bis wann?)** | **Entscheidung R6.1:** keine Datenquelle — v1 bewusst leer, ausfüllbar für Handschrift (siehe Abschnitt unten) | graue Zelle „Hier eintragen …" |
| **5 — Reflexion / Evaluation / Modifikation** | **Entscheidung R6.1:** keine Datenquelle — v1 bewusst leer, ausfüllbar für Handschrift (siehe Abschnitt unten) | graue Zelle „Hier eintragen …" |
| **Seite 2 — Weitere Vereinbarungen + Unterschriften** | **Entscheidung R6.1:** keine Datenquelle — bewusst leer für Handschrift (siehe Abschnitt unten) | Leerflächen: „Weitere Vereinbarungen", „Gesprächsdokumentation" (Gespräch durchgeführt am / mit), „Unterschrift der Anwesenden", „Information der Erziehungsberechtigten" (Datum + Unterschriftszeile) |

## Entscheidung: Absprachen (Spalte 4) — bewusst leer

**Entscheidung:** In v1 bleibt die Spalte leer und wird als sichtbares Eingabefeld („Hier eintragen …") für die Handschrift gerendert.

**Begründung:** Die Absprachen (Wer? Wie? Mit wem? Bis wann?) sind konkrete Vereinbarungen zwischen Lehrkraft, Kind und ggf. Erziehungsberechtigten. Sie hängen vom schulischen Kontext ab (Förderunterricht im Klassenverband, Elternabsprachen, Stundenplan) und sind aus den Diagnosedaten **nicht ableitbar**. Automatisch erzeugte Standardwerte wären pädagogisch nicht vertretbar und würden eine Absprache suggerieren, die nie stattgefunden hat. Die Lehrkraft kennt den Kontext und füllt die Spalte aus. Eine künftige, lehrkräftespeicherbare Texteingabe im Dashboard ist denkbar, aber kein v1-Ziel.

## Entscheidung: Reflexion / Evaluation / Modifikation (Spalte 5) — bewusst leer

**Entscheidung:** In v1 bleibt die Spalte bewusst leer und wird als Schreibfeld für die Handschrift gerendert.

**Begründung:** Die Reflexion ist eine Nachbesprechung im Klassenraum **nach** dem Förderzeitraum — sie findet zeitlich nach der Erzeugung des Formulars statt (im Zweifel Wochen später) und kann zum Generierungszeitpunkt von keinem Datenfeld sinnvoll vorbefüllt werden. Eine vorbefüllte Bewertung wäre spekulativ und würde die spätere, datengestützte Einschätzung der Lehrkraft vorwegnehmen.

## Entscheidung: Seite 2 — bewusst leer für Handschrift

**Entscheidung:** Seite 2 wird leer für die Handschrift gerendert: Leerfläche für „Weitere Vereinbarungen", Felder für die Gesprächsdokumentation, die Unterschriftszeilen der Anwesenden und die Information der Erziehungsberechtigten inkl. Datums-/Unterschriftszeile.

**Begründung:** Weitere Vereinbarungen, Gesprächs- und Unterschriftsdaten entstehen erst im Fördergespräch selbst; sie liegen zum Generierungszeitpunkt nicht vor.

## Kopfzeile: „für ___ für die Zeit von ___ bis ___"

| Feld | Datenquelle |
|---|---|
| „für ___" (Name der Schülerin / des Schülers) | `students.display_name` — Anzeigename aus der Klassenliste (Pseudonym, siehe unten). |
| „von ___" (Beginn) | Datum aus `diagnostic_sessions.started_at` (Sitzungsbeginn, `timestamptz` → Datum). |
| „bis ___" (Ende des Förderzeitraums) | **Kein Datenfeld im Schema vorhanden** (keine Planungsspalte in `diagnostic_sessions`/`foerderplaene`). v1-Entscheidung: Feld bleibt ausfüllbar/leer bzw. mit Vorschlagswert (Sitzungsdatum); die konkrete Vorbefüllung legt R6.2 fest, sobald die Datenquelle definiert ist. |

## Umsetzungsstand

**Heute bereits umgesetzt (Stand 2026-08-29):**

- **Ist / Soll / Lernweg automatisch befüllt** je Domänenzeile — in `math_app/lib/services/pdf_kurz_foerderplan_service.dart` (Spalten 2–4 als `_contentCell`) und in `backend/supabase/functions/foerderplan-kurz-pdf/index.ts` (durch `buildKurzRows`). Beide rendern die Spalten **Absprachen** und **Reflexion** als graue, leere Eingabefelder („Hier eintragen …").
- **Seite 2 ist in beiden Implementierungen vorhanden und leer** (Weitere Vereinbarungen, Gesprächsdokumentation, Unterschrift der Anwesenden, Information der Erziehungsberechtigten inkl. Unterschriftszeilen).
- **Kopfzeile:** Die Edge-Funktion befüllt den Namen bereits aus `display_name` (`index.ts:276–279`); die von-/bis-Boxen sind leer. Die Dart-Variante rendert die Kopfzeile noch mit leeren Eingabeboxen.

**R6.2 ergänzt:**

- Befüllte Kopfzeile („von" aus `started_at`, „bis" gemäß obiger Festlegung).
- Sicherstellung der Unterschriftszeilen auf Seite 2.
- Layout-Entscheidung (SenBJF-Vorlage vs. eigene Fünf-Spalten-Anordnung), sobald ADR 0001 entschieden ist.

## Pseudonymisierung und R0.4

- Der im Formular erscheinende Name ist `students.display_name` — der Anzeigename aus der Klassenliste. Das Kind kann unter einem Pseudonym (Ticket-basiert) arbeiten; ein echter Name ist nicht erforderlich.
- Das Formular trägt **keinen geschützten Werktitel und keinen Behördennamen**: Die Spaltenüberschriften sind standarddeutsches pädagogisches Vokabular (ADR 0001), die Fußzeile nennt nur das Produkt („Erstellt mit Numeris" / „Erstellt mit Math App"). Damit gilt R0.4 („nach SenBJF" entfernt) auch im Ausgabedokument.

## Quellen

- `tasks.md` — R6.1, R6.2, R0.4, R4.3
- `docs/clean-room/decisions/0001-foerderplan-form-licence.md` (ADR 0001)
- `docs/clean-room/foerderplan/mapping-rationale.md`, `ordering-rule.md`
- `docs/clean-room/skills/skills_taxonomy.csv`
- `math_app/lib/services/kurz_foerderplan_service.dart`, `math_app/lib/services/pdf_kurz_foerderplan_service.dart`
- `backend/supabase/functions/foerderplan-kurz-pdf/index.ts`
- Schema: `diagnostic_sessions` (`started_at`), `students` (`display_name`), `foerderplaene` (`recommended_skill_ids`, `category_stats`, `slow_response_flag`)
