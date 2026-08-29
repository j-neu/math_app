# Numeris — Math Diagnostic for German Primary School

A diagnostic and Förderplan tool for German Grundschule maths teachers, with a special focus on supporting children with ADHD. Designed by a remedial maths teacher specialised in prozessorientierte Diagnose, on the basis of the German mathematics-didactics research on preventing arithmetic difficulties.

> **⚖️ Clean-Room Rewrite in progress (since 2026-08-29).** The product is **non-commercial** until it completes — free, school-internal, research-partnership use only. The current diagnostic content is derived from the iMINT-Kartei and PIKAS and is being rebuilt from primary sources. Plan: [tasks.md](tasks.md). Reasoning: [rewrite.md](rewrite.md).

The product is two things glued together:

- **A teacher-facing web dashboard** ([dashboard/](dashboard/), Next.js, hosted EU) — teachers create classes, hand out QR-code session tickets, see per-student Förderpläne and class-level aggregates, export PDFs.
- **A child-facing Flutter Web client** ([math_app/](math_app/)) — kids open a URL or scan a QR, complete a German-language diagnostic, see "Fertig!".

Backed by a Supabase EU project (Frankfurt, RLS-multi-tenant). DSGVO-aware. Free for pilot schools; pricing cannot be discussed until the clean-room rewrite completes (`tasks.md` R7.5).

## Current focus

The diagnostic and the school-platform pilot. The practice-exercise engine is paused (eight skills exist in code; framework docs are flagged paused in [DOCS_INDEX.md](DOCS_INDEX.md)).

The diagnostic currently runs on `math_app/Research/MathApp_Diagnostic_with_skills.csv` (92 questions). That item bank is being replaced by an independently derived one — see [tasks.md](tasks.md) Phase R2. The Schulz/Wartha instrument was dropped from product scope on 2026-08-29 (CC BY-ND).

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

The diagnostic addresses the standard constructs of German Grundschulmathematik: counting competence, quantity recognition, number decomposition, place value, and addition/subtraction strategies — with the didactic goal of "Ablösung vom zählenden Rechnen".

The bibliography this is derived from is being assembled at `docs/clean-room/03-bibliography.md` ([tasks.md](tasks.md) R1.2) and will be published in the product as a "Wissenschaftliche Grundlagen" page (R7.1).

The skill taxonomy currently in use (88 skills) is in [math_app/Research/skills_taxonomy.csv](math_app/Research/skills_taxonomy.csv); it is replaced in R3.3.
