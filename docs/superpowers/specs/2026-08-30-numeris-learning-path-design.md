# Design — Lernpfad (Learning Path) und Übungsbetrieb

**Date:** 2026-08-30
**Owner:** Jakob
**Status:** DRAFT — awaiting review
**Supersedes as current build focus:** nothing. Runs alongside `tasks.md` R2.9 sign-off; does not touch the clean-room item bank.

---

## 1. Context

The diagnostic half of Numeris is shipped and live: 59 core + 32 deep-dive clean-room items, the Förderplan generator, the teacher dashboard, the Supabase EU backend, the Flutter Web student client. What does not exist is the second half of the product promise — the child completes a diagnostic, a Förderplan is generated, and then nothing happens in the app. The teacher gets a PDF; the child gets "Fertig!".

This design covers the missing half: a per-child learning path derived from the diagnostic, the practice runtime that delivers it, content for all 36 skills, and the teacher console to steer it.

### Current state that this builds on

| Asset | State | Reuse |
|---|---|---|
| `foerderplaene.recommended_skill_ids` | shipped | the raw material of a path |
| `skill_recommendation_order.dart` (R4.2) | shipped, 4/4 tests | path ordering, unchanged |
| `skills_taxonomy.csv` — 36 skills, Domains A–D | shipped | the path's vocabulary |
| Visual widget vocabulary (R5.2): Zehnerfeld, Rekenrek, Fingerbild, Stäbchen, Stellenwerttafel, Zahlenstrahl | shipped in `diagnostic_screen.dart` | extracted into shared widgets for practice |
| Short-URL school login (slug + short code) | shipped | extended to class-code + roster login |
| Bulk QR PDF per class | shipped | unchanged |
| RLS pattern: child JWT carries `student_id`, gated by `ticket_student_id()` | shipped | extended to all new child-written tables |

### Constraints

- **Commercial freeze holds.** `tasks.md` R7.5 is not lifted. Everything here ships under the free / school-internal / research-partnership posture. No pricing surface, no "kaufen", anywhere.
- **The retired practice skills stay retired.** Z1, C1.1, C1.2, C2.1, C3.1, C4.1, S1.1, S3.4 are iMINT/PIKAS-derived and frozen pending R8.1. No content in this design derives from them, and they are not revived. New content is authored clean-room from the construct map and bibliography.
- **German throughout.** Every user-facing string, teacher-facing and child-facing.
- **Provenance applies to practice content.** The charter rule ("every shipped artifact answers *why does this exist and where did it come from?*") covers skill specs exactly as it covers diagnostic items.

---

## 2. Locked decisions

| # | Decision | Rationale |
|---|---|---|
| 1 | Content for **all 36 skills**, not a starter subset | The path is the product; a path that runs out after 8 skills is a demo |
| 2 | Each skill = **E-I-S, 3 levels, ~8 problems**, procedurally generated from a parameter spec | Enaktiv → ikonisch → symbolisch is the standard German didactic progression and is citable in the clean-room trail. A signed spec beats 50 hand-written problems |
| 3 | Child login = **school slug → 4-char class code → name/avatar grid** | Reuses the shipped short-URL flow; no passwords; works on shared iPads; a six-year-old can do it unaided |
| 4 | Skills are **declarative specs + documented escape hatch** for bespoke interaction | One tested runtime, 36 reviewable specs. Jakob reviews pedagogy, not Dart |
| 5 | Mastery = **accuracy only**; slow responses raise a **teacher-visible flag**, never a block | Keeps a slow-but-secure child moving; leaves the zählendes-Rechnen judgment with the teacher, consistent with the existing `slow_response_flag` |
| 6 | Teacher has **full control** of a path: reorder, add, remove, skip, lock/unlock, reset, set unlock width | The generated path is a proposal, not a cage. A teacher who cannot overrule the machine will not trust it |
| 7 | **Optional picture-PIN** per child, default off, per-class setting | Friction most classrooms will not want, but its existence is the answer in a DSGVO conversation |

---

## 3. Decomposition

Six sub-projects. This document specifies **P1** to implementation depth and fixes the **contracts** P2 and P3 depend on. P2–P6 each get their own spec before implementation.

| | Sub-project | Delivers | Depends on |
|---|---|---|---|
| **P1** | Path engine + child identity | Schema, RLS, edge functions, login, path derivation, progress persistence, offline sync | — |
| **P2** | Practice runtime | Spec interpreter, 16 level templates, shared manipulative widgets, feedback loop | P1, §5 contract |
| **P3** | 36 skill specs | One spec + provenance file per skill, drafted by agents, queued for sign-off | P2, §5 contract |
| **P4** | Teacher console for paths | Assign/override, per-child and per-class progress, re-test scheduling, print view | P1 |
| **P5** | Art direction + engagement | Child visual system, rewards, animation, ADHD guidelines applied | P2 |
| **P6** | Publish hardening | iPad Safari, perf, error handling, load, DSGVO placeholders, deploy | all |

**Critical path:** P1 → P2 → P3. P4 parallelises with P2 (both depend only on P1). P5 parallelises with P3. P6 is continuous, closing last.

---

## 4. P1 — Path engine and child identity

### 4.1 Schema

Additive only. No existing table changes shape.

```sql
create table public.learning_paths (
  id                uuid primary key default gen_random_uuid(),
  student_id        uuid not null references public.students on delete cascade,
  source_session_id uuid references public.diagnostic_sessions on delete set null,
  status            text not null default 'draft'
                      check (status in ('draft','active','completed','archived')),
  unlock_width      int  not null default 3 check (unlock_width between 1 and 10),
  created_by        uuid references public.teachers on delete set null,
  created_at        timestamptz not null default now(),
  activated_at      timestamptz,
  completed_at      timestamptz
);

create table public.path_items (
  id         uuid primary key default gen_random_uuid(),
  path_id    uuid not null references public.learning_paths on delete cascade,
  skill_id   text not null references public.skills on delete restrict,
  position   int  not null,
  origin     text not null default 'diagnostic'
               check (origin in ('diagnostic','teacher_added')),
  state      text not null default 'locked'
               check (state in ('locked','available','in_progress','mastered','skipped')),
  updated_at timestamptz not null default now(),
  unique (path_id, skill_id),
  unique (path_id, position) deferrable initially deferred
);

create table public.skill_progress (
  id            uuid primary key default gen_random_uuid(),
  student_id    uuid not null references public.students on delete cascade,
  skill_id      text not null references public.skills on delete restrict,
  level         int  not null check (level between 1 and 3),
  attempts      int  not null default 0,
  correct       int  not null default 0,
  best_streak   int  not null default 0,
  slow_flag     bool not null default false,
  mastered_at   timestamptz,
  last_seen_at  timestamptz,
  unique (student_id, skill_id, level)
);

create table public.practice_sessions (
  id                 uuid primary key default gen_random_uuid(),
  student_id         uuid not null references public.students on delete cascade,
  path_item_id       uuid references public.path_items on delete set null,
  skill_id           text not null references public.skills on delete restrict,
  level              int  not null check (level between 1 and 3),
  started_at         timestamptz not null default now(),
  ended_at           timestamptz,
  problems_total     int not null default 0,
  problems_correct   int not null default 0,
  median_response_ms int
);

create table public.practice_attempts (
  id                  uuid primary key default gen_random_uuid(),
  practice_session_id uuid not null references public.practice_sessions on delete cascade,
  problem_index       int  not null,
  problem             jsonb not null,
  answer              text,
  was_correct         bool not null,
  response_ms         int,
  error_code          text,
  answered_at         timestamptz not null default now(),
  unique (practice_session_id, problem_index)
);

alter table public.classes
  add column if not exists class_code      text unique,
  add column if not exists code_rotated_at timestamptz,
  add column if not exists require_pin     bool not null default false;

alter table public.students
  add column if not exists avatar   text,
  add column if not exists pin_code text;

create index on public.learning_paths (student_id, status);
create index on public.path_items (path_id, position);
create index on public.skill_progress (student_id, skill_id);
create index on public.practice_sessions (student_id, started_at desc);
create index on public.practice_attempts (practice_session_id);
create index on public.classes (class_code);
```

`practice_attempts.problem` stores the generated problem verbatim. Without it a wrong answer six weeks later is unreadable — the generator is seeded and the problem no longer reproducible from the spec alone.

### 4.2 RLS

Follows the shipped pattern exactly: teacher reads everything within `teacher_school_id()`, child reads and writes only rows where `student_id = ticket_student_id()`.

Explicitly tested denials, because these are the ones that would matter:

1. Child token **cannot** read another child's `skill_progress`, `practice_sessions`, or `practice_attempts` — including a child in the same class whose name they saw on the roster.
2. Child token **cannot** write `path_items` (only the teacher and the service role order a path).
3. Child token **cannot** read `students` rows beyond their own, so the roster endpoint is the *only* route to classmate names, and it returns `display_name` and `avatar` and nothing else.
4. Teacher token from school X **cannot** read any row belonging to school Y, through any of the five new tables.

Tests live in `backend/supabase/tests/rls_learning_path.sql`, run against a seeded two-school fixture.

### 4.3 Child login flow

```
/s/<slug>                    school landing (shipped)
  → Klassencode: [7K2M]      resolves classes.class_code within that school
  → roster grid              display_name + avatar, that class only
  → tap your name
  → [optional picture PIN]   only when classes.require_pin
  → student JWT              student_id claim, as the diagnostic flow already mints
```

**Roster exposure and its mitigations.** A slug plus a 4-char code reveals that class's first names. This is a deliberate, documented tradeoff — the alternative is a login a Klasse-1 child cannot perform. Mitigations, all in P1 scope:

- Teacher rotates the class code in one click; the old code dies immediately. `code_rotated_at` records it.
- Rate limit per IP on the roster endpoint; a wrong code costs an increasing delay, so the 1.6M code space is not brute-forceable in a lesson.
- Roster returns `display_name` and `avatar` only — never age, `external_ref`, results, or progress.
- Per-class picture PIN, default off, for schools that want the second factor.
- The tradeoff and its mitigations are written into `/datenschutz` and the DSGVO documentation, not left implicit.

### 4.4 Path derivation

```
diagnostic session completed
  → foerderplan-generate (shipped) produces recommended_skill_ids
  → learning-path/generate:
      order skill_ids by sortSkillIds          (R4.2 canonical construct order)
      create learning_paths row, status=draft
      create path_items, position = rank
      state: first `unlock_width` (default 3) → available, rest → locked
  → teacher reviews in the dashboard, edits freely, activates
  → status=active; the child sees it at next login
```

A path stays `draft` until the teacher activates it. Nothing reaches a child without a teacher's decision.

When a `path_item` reaches `mastered`, the next `locked` item by position flips to `available`, holding the window at `unlock_width`. Only three things to choose from at a time is a direct application of the ADHD guidelines already in force.

### 4.5 Mastery and the slow-response flag

- A **level** is mastered at **≥7 of 8 correct** in a single practice session. Accuracy only.
- A **skill** is mastered when levels 1, 2 and 3 are each mastered.
- Response time is recorded on every attempt and the median per session. When the median exceeds the level's reference band, `skill_progress.slow_flag` is set and the teacher sees it — the child is never blocked, slowed, or told.
- The reference bands are a pedagogical parameter, documented and signed like any other, in a new ADR `docs/clean-room/decisions/0009-mastery-and-slow-response.md` (0008 stays reserved for the R8.1 practice-skill triage ADR). They are a *flag* threshold, not a *gate* threshold, which makes them low-risk to set and easy to tune from pilot data.

### 4.6 Edge functions

| Function | Method | Auth | Contract |
|---|---|---|---|
| `student-auth` | POST `/roster` | none + rate limit | `{slug, class_code}` → `[{student_id, display_name, avatar}]` |
| `student-auth` | POST `/login` | none + rate limit | `{student_id, pin?}` → student JWT |
| `learning-path` | GET | child JWT | active path + item states + per-skill progress |
| `learning-path` | POST `/generate` | teacher | `{session_id}` → draft path |
| `learning-path` | PATCH | teacher | reorder, add, remove, skip, lock/unlock, set `unlock_width`, activate, reset |
| `practice-session` | POST `/start` | child JWT | `{skill_id, level}` → `{practice_session_id, seed}` |
| `practice-session` | POST `/sync` | child JWT | batch of attempts (idempotent on `problem_index`) |
| `practice-session` | POST `/end` | child JWT | totals → updates `skill_progress`, evaluates mastery, unlocks next |

`foerderplan-generate` gains one call: it creates the draft path alongside the Förderplan, so the teacher finds one waiting rather than having to ask for it.

### 4.7 Offline resilience

Problems are generated on the device from specs bundled in the Flutter build. School wifi drops; a child mid-exercise must not lose their work.

- Attempts are written to a local queue first, flushed to `/sync` in batches.
- `/sync` is idempotent on `(practice_session_id, problem_index)`, so a double flush is harmless.
- A dropped connection is invisible to the child; a persistent one shows a small, calm status to the teacher, never an error dialog to a seven-year-old.
- A session interrupted by a closed browser resumes, exactly as the diagnostic already resumes.

### 4.8 Testing

| Layer | What |
|---|---|
| SQL | RLS denials §4.2, all four, against a two-school fixture |
| Edge functions | Contract tests per endpoint incl. rate limiting, bad codes, replayed sync |
| Dart | Path derivation ordering, unlock-window transitions, mastery evaluation, offline queue flush and replay |
| Integration | Diagnostic → Förderplan → draft path → activate → child login → practice → progress visible to teacher |

---

## 5. Contract: the skill spec format

Fixed here because P2 (runtime) and P3 (36 specs) are written against it in parallel.

```jsonc
{
  "skill_id": "A3.1",
  "construct_id": "A3.1",
  "domain": "A",
  "title_de": "Teil-Teil-Ganzes bis 10",
  "levels": [
    { "level": 1, "representation": "enaktiv",
      "template": "drag_partition",
      "params": { "whole": [5, 10], "parts": 2, "allow_zero": false },
      "problem_count": 8,
      "prompt_de": "Lege {whole} Plättchen in die beiden Felder." },
    { "level": 2, "representation": "ikonisch",
      "template": "zehnerfeld_read",
      "params": { "whole": [5, 10], "show_structure": true },
      "problem_count": 8,
      "prompt_de": "Wie viele sind rot, wie viele blau?" },
    { "level": 3, "representation": "symbolisch",
      "template": "equation_gap",
      "params": { "form": "W = P + _", "whole": [5, 10] },
      "problem_count": 8,
      "prompt_de": "Welche Zahl fehlt?" }
  ],
  "error_taxonomy": [
    { "code": "off_by_one", "label_de": "Zählfehler (±1)",
      "hint_de": "Zähle die Plättchen noch einmal langsam." },
    { "code": "whole_as_part", "label_de": "Ganzes als Teil gesetzt",
      "hint_de": "Beide Felder zusammen ergeben die große Zahl." }
  ],
  "mastery": { "correct_of": [7, 8] },
  "slow_band_ms": { "1": 12000, "2": 9000, "3": 6000 },
  "provenance": {
    "sources": ["Padberg & Benz 2021", "Lenz & Wittmann 2023"],
    "author": "Claude (draft)",
    "reviewed_by": null
  }
}
```

**Template vocabulary** — the runtime's fixed verbs, 16 covering 36 skills × 3 levels:

- *enaktiv:* `drag_partition`, `place_counters`, `bundle_sticks`, `rekenrek_set`, `numberline_step`
- *ikonisch:* `zehnerfeld_read`, `fingerbild_read`, `stellenwerttafel_read`, `numberline_locate`, `picture_compare`
- *symbolisch:* `equation_solve`, `equation_gap`, `sequence_gap`, `compare_symbols`, `strategy_choice`
- *Sachsituation:* `word_problem`

**Escape hatch:** a skill may declare `"custom_widget": "<name>"` on a level instead of a template, when a construct genuinely needs bespoke interaction (B1.2 Bündeln, B2.2 Zahlenstrahl are the expected cases). Every use requires a one-line written justification in the spec and is reviewed as an exception, not a default.

**Provenance:** each spec ships with `docs/clean-room/skills/specs/<skill_id>.md` and a `provenance.csv` row of `type=skill_spec`. Jakob signs the spec once; the generated problems inherit that signature, which is the entire reason for choosing generated problems over 1,800 hand-authored ones.

---

## 6. Build protocol — how the agent loop terminates

Every unit of work (one sub-project task, or one skill spec) passes through the same three roles. **Sonnet** for building and criticism, **haiku** for mechanical checks. No opus.

1. **Builder** implements against the task's stated acceptance criteria.
2. **Visual reviewer** renders the result at 768×1024 (iPad portrait), 1024×768 (iPad landscape) and 390×844 (phone), in light and dark, and reports: overflow, clipped or truncated German text, tap targets under 44px, contrast failures, anything that reads as unfinished.
3. **Critic** judges against the teacher-usability rubric below and returns findings or a sign-off.

Findings return to the builder. The unit exits only when a full cycle produces **no findings from either reviewer**, twice consecutively.

### Definition of done (all five gates)

| Gate | Check |
|---|---|
| **Build** | `flutter analyze` at or below the 323-lint baseline · `flutter test` green · `npx tsc --noEmit` clean · `next build` succeeds |
| **Backend** | migration applies · RLS denial tests pass · edge-function contract tests pass |
| **Visual** | no overflow, clipping, or sub-44px targets at all three widths, both themes |
| **Critic** | teacher-usability rubric passes, no open findings |
| **Legal** | zero hits for iMINT/PIKAS/SenBJF/Schulz/LISUM · zero pricing strings · provenance row exists for every content artifact |

### Teacher-usability rubric (the critic's checklist)

1. Every string is German. No English leaks into any surface, including errors and empty states.
2. A teacher who has never seen the app can complete the core loop — class → diagnostic → path → activate → watch progress — without a manual.
3. Every action states its outcome before it happens, and every destructive one is recoverable.
4. Usable one-handed on a tablet while supervising a class; nothing needs a mouse or a steady two-handed grip.
5. Legible at arm's length: no critical information below 14px, no colour-only signals.
6. No dead ends. Every screen offers a way onward or back.
7. Vocabulary a Grundschullehrer already uses. No internal jargon — no "construct", no "skill_id", no "path_item".
8. Child screens demand no reading beyond first-grade level; instructions carry an icon or spoken support.
9. Nothing implies a purchase, a licence, or a validated equivalence to another instrument.

---

## 7. Risks

| Risk | Mitigation |
|---|---|
| 36 specs drafted by agents drift in quality or duplicate phrasing | Independence checker extended to specs; every spec reviewed against the construct map before it queues for sign-off |
| Sign-off becomes the bottleneck (36 specs on top of the R2.9 item review) | Specs queue in dashboard-reviewable form; the app runs drafted content in a pilot flagged as `Entwurf` internally, and nothing is presented as final until signed |
| Template vocabulary proves too narrow mid-P3 | Escape hatch exists by design; a third or more of skills needing it is the signal to stop and revise the vocabulary rather than accumulate exceptions |
| Roster exposure challenged by a school's DSGVO officer | Rotatable codes, rate limiting, minimal payload, optional PIN, all documented before pilot |
| Practice content is mistaken for the frozen legacy content | New specs cite the construct map and bibliography only; the retired 8 skills stay out of the build and out of the path |

---

## 8. Non-goals

- Reviving the 8 retired practice skills, in any form.
- Lifting the commercial freeze, or building any pricing, billing, or purchase surface.
- Changing the diagnostic item bank, its ordering, or the Förderplan generator's existing output.
- Native iOS/Android builds. Web only, as instructed.
- Adaptive difficulty beyond the diagnostic-seeded path and the E-I-S progression.
