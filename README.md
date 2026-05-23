# Numeris — Math Diagnostic for German Primary School

A diagnostic and Förderplan tool for German Grundschule maths teachers, with a special focus on supporting children with ADHD. Built on iMINT and PIKAS pedagogical research; designed by a remedial maths teacher specialised in prozessorientierte Diagnose.

The product is two things glued together:

- **A teacher-facing web dashboard** ([dashboard/](dashboard/), Next.js, hosted EU) — teachers create classes, hand out QR-code session tickets, see per-student Förderpläne and class-level aggregates, export PDFs.
- **A child-facing Flutter Web client** ([math_app/](math_app/)) — kids open a URL or scan a QR, complete a German-language diagnostic, see "Fertig!".

Backed by a Supabase EU project (Frankfurt, RLS-multi-tenant). DSGVO-aware. Pilot schools free; pricing deferred until pilot validates value.

## Current focus

The diagnostic and the school-platform pilot. The practice-exercise engine is paused (eight skills exist in code; framework docs are flagged paused in [DOCS_INDEX.md](DOCS_INDEX.md)).

Two diagnostic instruments are supported in parallel and must never be mixed in reports:

- **iMINT** — `math_app/Research/MathApp_Diagnostic_with_skills.csv`, 98 questions.
- **Schulz/Wartha** — `math_app/Research/MathApp_Diagnostic_Schulz.csv`, 151 questions, 8 blocks.

For where things stand right now, see [STATUS.md](STATUS.md). For the active build plan (school-platform Phase D and pilot scheduling), see [phase1_school_platform.md](phase1_school_platform.md).

## Where to read next

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

- **iMINT-Kartei** — diagnostic-first approach, "Ablösung vom zählenden Rechnen", 76 skills across five categories (Zahlverständnis, Operationsverständnis, Stellenwertverständnis, Schnelles Kopfrechnen, Zahlenrechnen).
- **PIKAS FÖDIMA** — connecting representations (Handlung, Bild, Sprache, Mathesprache), conceptual understanding, 58 cards.

Source materials live in [math_app/Research/](math_app/Research/). The skill taxonomy (88 skills, `category_number` IDs) is in [math_app/Research/Research/skills_taxonomy.csv](math_app/Research/Research/skills_taxonomy.csv).
