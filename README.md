# Numeris — Math Diagnostic for German Primary School

A diagnostic and Förderplan tool for German Grundschule maths teachers, with a special focus on supporting children with ADHD. Designed by a remedial maths teacher specialised in prozessorientierte Diagnose, on the basis of the German mathematics-didactics research on preventing arithmetic difficulties.

> **⚖️ Clean-Room Rewrite läuft seit 2026-08-29 — erster Durchlauf am 2026-09-07 verworfen.**
> Das Produkt ist **nicht-kommerziell**, bis der Rewrite abgeschlossen ist: kostenlos, schulintern, nur im Rahmen von Forschungspartnerschaften.
>
> Der erste Durchlauf (`cleanroom-v1`) hat ein Diagnostikum produziert, das fachlich nicht trägt — fehlende Konstrukte (u. a. Verdoppeln/Halbieren im ZR20 und ZR100), zu komplexe Items, die dem Kind das Verfahren vorschreiben. Es wird neu gebaut.
> Befunde: [docs/clean-room/00-v1-assessment.md](docs/clean-room/00-v1-assessment.md) · Neuentwurf: [docs/superpowers/specs/2026-09-07-diagnostik-v2-design.md](docs/superpowers/specs/2026-09-07-diagnostik-v2-design.md) · Rechtliche Begründung: [rewrite.md](rewrite.md)

The product is two things glued together:

- **A teacher-facing web dashboard** ([dashboard/](dashboard/), Next.js, hosted EU) — teachers create classes, hand out QR-code session tickets, see per-student Förderpläne and class-level aggregates, export PDFs.
- **A child-facing Flutter Web client** ([math_app/](math_app/)) — kids open a URL or scan a QR, complete a German-language diagnostic, see "Fertig!".

Backed by a Supabase EU project (Frankfurt, RLS-multi-tenant). DSGVO-aware. Free for pilot schools; pricing cannot be discussed until the rewrite completes (`tasks.md` R9.3).

## Current focus

**Inhalte v2.** Diagnostik und Übungsinhalte werden neu abgeleitet — zuerst eine Deckungsmatrix (Inhaltsstrang × Zahlenraum × Repräsentation) aus Rahmenlehrplan BE/BB und KMK-Bildungsstandards, dann Konstrukt für Konstrukt Items und Übungen, jede Zelle von Jakob abgenommen: einmal auf Papier, einmal im laufenden Kind-Screen. Plan: [docs/superpowers/specs/2026-09-07-diagnostik-v2-design.md](docs/superpowers/specs/2026-09-07-diagnostik-v2-design.md).

Die Plattform selbst bleibt unverändert: Supabase-Backend, Lehrkraft-Dashboard, Kind-Login, Sitzungsaufzeichnung und Deployment laufen weiter. Die **handgebaute Übungs-Engine** (mehrstufige, manipulativ-basierte Skills mit Belohnungen) kommt als kindseitiges Modell zurück und ist nicht mehr pausiert; die Server-Schicht des Lernpfads (Kind-Login, Pfad, Übungssitzungen, Lehrkraft-Konsole) bleibt.

Die laufende Diagnostik `cleanroom-v1` (59 Kern-Items + 32 Deep-Dive in `math_app/Research/diagnostic_core_v1.csv`) bleibt technisch bestehen, gilt aber intern als unbrauchbar und wird von `cleanroom-v2` abgelöst. Das Schulz/Wartha-Instrument wurde am 2026-08-29 aus dem Produktumfang genommen (CC BY-ND).

## Where to read next

- [docs/superpowers/specs/2026-09-07-diagnostik-v2-design.md](docs/superpowers/specs/2026-09-07-diagnostik-v2-design.md) — **der aktuelle Plan.** Wie Diagnostik und Übungsinhalte neu gebaut werden.
- [docs/clean-room/00-v1-assessment.md](docs/clean-room/00-v1-assessment.md) — warum der erste Durchlauf verworfen wurde.
- [STATUS.md](STATUS.md) — what's shipped, what's active, what's paused.
- [DOCS_INDEX.md](DOCS_INDEX.md) — full annotated map of every `.md` in this repo.
- [phase1_school_platform.md](phase1_school_platform.md) — active plan: backend, dashboard, Flutter web, pilot.
- [TERMINOLOGY.md](TERMINOLOGY.md) — Skill / Level / Problem definitions used across the codebase.

## Quick start

```bash
# Flutter app (single-device dev mode)
cd math_app && flutter pub get && flutter run

# Flutter web build (deploy from build/web/)
cd math_app && flutter build web --no-tree-shake-icons

# Teacher dashboard
cd dashboard && npm install && npm run dev   # http://localhost:3000

# Supabase backend
cd backend && supabase db push
cd backend && supabase functions deploy <name>
```

## Research foundation

The diagnostic addresses the standard constructs of German Grundschulmathematik: counting competence, quantity recognition, number decomposition, place value, and addition/subtraction strategies — with the didactic goal of "Ablösung vom zählenden Rechnen".

The bibliography this is derived from is being assembled at `docs/clean-room/03-bibliography.md` ([tasks.md](tasks.md) R1.2) and will be published in the product as a "Wissenschaftliche Grundlagen" page (R7.1).

Die Skill-Taxonomie und die Item-Zuordnung werden im Rahmen von v2 neu abgeleitet; die 36 Skills des ersten Durchlaufs bleiben als Protokoll erhalten, sind aber keine Arbeitsgrundlage mehr.
