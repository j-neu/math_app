# Integration Critic Report — Numeris remedial-maths product (fresh context, live)

**Date:** 2026-09-01
**Critic:** fresh-context integration critic (no prior findings trusted; every claim re-exercised live)
**Stack exercised:** live Supabase `zzxqeqwffexythqzjkxr` (EU), dashboard `localhost:3000` (Next.js), child app `localhost:8080` (Flutter web), service-role REST, all edge functions as deployed.

---

## 1. THE SINGLE BIGGEST REMAINING GAP

**The teacher console's "Kompetenz hinzufügen" picker exposes all 123 `skills` rows — including the 87 legacy/retired skills that have no child-facing spec (e.g. "Rechenschiffchen aus Erinnerung", "Kraft der 5", "Fingerblitz") — and the backend `add_skill` PATCH accepts any of them, so a teacher can create a path item the child app cannot run: the child taps the tile and hits the dead-end "Für diese Übung gibt es noch keine Aufgaben. Bitte frage deine Lehrkraft."**

Evidence chain: `dashboard/lib/lernpfad/queries.ts:155-160` (`allSkills` = full `skills` catalog minus path ids, no spec filter) → picker snapshot shows the legacy titles → `learning-path/index.ts:331-343` (`add_skill` inserts any `skill_id`, verified live: PATCH with `basic_strategy_1` → 200 `{"ok":true}`) → child app bundles only the 36 taxonomy specs (`assets/skill_specs/` = 36 files, verified) → `child_path_screen.dart:134-149` (`store.byId(item.skillId)` throws → error dead-end). A teacher can manufacture a journey the child cannot complete, and the UI never warns. This also revives the retired practice skills the spec's legal gate forbids.

---

## 2. Findings table

| # | Finding | Severity | Evidence |
|---|---|---|---|
| F1 | Add-skill picker exposes 87 legacy/retired skills; backend accepts them; child app has no spec → tappable dead-end tile | **Critical** | `queries.ts:160` (no spec/domain filter); live picker shows "Rechenschiffchen…", "Kraft der 5", "Fingerblitz"; live PATCH `add_skill: basic_strategy_1` → 200; `assets/skill_specs/` = 36 files vs 123 `skills` rows; `child_path_screen.dart:134-149` dead-end message |
| F2 | Backend gate fails: `deno check` reports 5 TS errors in `diagnostic-sessions/index.ts:119-123` (resume path accesses `r.diagnostic_questions/was_correct/…` on a `GenericStringError` union) | **Important** | `deno check diagnostic-sessions/index.ts` → `Found 5 errors`, exit non-zero (all other functions check clean) |
| F3 | End-of-session summary is keyed to **whole-skill** mastery, not the level just mastered: a child who aces 8/8 and masters the level sees "Fast geschafft! … Übe bald weiter, dann schaffst du es ganz sicher!" | **Important** | Live A1.2a L2 session: 8/8 correct, `skill_progress.mastered_at` set, path pip "Stufe 2 geschafft" — but summary rendered "Fast geschafft!"; `learning_path_service.dart:259` maps only `skill_mastered` into `MasteryResult.mastered`; `practice_screen.dart:505-517` |
| F4 | Duplicate problems within one session: A1.2a L2 generated the identical problem ("15,14,_,12,11") 3× (idx 4, 5, 7) and "14,13,_,11,10" 2× (idx 2, 6) — including back-to-back repeats | **Important** | `practice_attempts` payloads for session `0ec5350e-…` (dumped verbatim); `problem_generators.dart:49-85` fallback fill loop + start_range [14,18] = only 5 unique sequences for 8 slots |
| F5 | Closing a practice session mid-way ("Übung beenden") leaves a permanent dangling `practice_sessions` row (`ended_at null`, 0 problems); recovery only covers `/end`-failure sessions, never abandoned ones | Minor | 3 dangling rows live (incl. `e867c350-…` created this run and `c8461119`, `4a84c65f` from earlier journeys); `practice_screen.dart:171-196` pops without `/end`; `recoverPendingSessions` handles only marked-pending sessions |
| F6 | Console labels a path "aus Diagnostik vom <date>" purely from `activated_at ?? created_at`, even when `source_session_id IS NULL` (fixture path A); a fresh draft path also inherits slow flags from *another* path's practice (skill_progress is student-scoped, not path-scoped) | Minor | `lernpfade/[pathId]/page.tsx:41-43`; live: path A (`source_session_id null`) shows "aus Diagnostik vom 1.9.2026"; new draft path `ce9fc762` shows "Langsames Bearbeiten" on A1.1a/A1.2a from prior-path sessions |

Verified NOT broken (no finding): CORS preflights for `practice-session/start`, `learning-path` GET (with `x-student-token`) and PATCH — all 200 with correct allow-headers; locked-skill start → 403 German "Diese Aufgabe ist noch nicht freigeschaltet"; auto-complete uses `question_count` (60, not 92) — session completed exactly on answer 60.

---

## 3. Journeys run and outcomes

**Journey 1 — Teacher console (COMPLETE).** Logged-in teacher → `E2E Klasse` → "Lernpfade" section (real `Stand:` timestamp, per-student rows with counts + slow-flag banner) → active path console → expanded A1.1a tile shows real level rows: "Stufe 1 · 8 Versuche, 7 richtig · Langsames Bearbeiten", "Stufe 2 · Noch nicht bearbeitet", "Stufe 3 · 5 Versuche, 4 richtig". Exercised `set_unlock_width` (3→2): server row updated, survived full reload, restored to 3. Exercised `reorder`: new order persisted server-side and after reload, then restored. All numbers traced to live `skill_progress`/`path_items`.

**Journey 2 — Child app → practice → teacher (COMPLETE).** `/lernen/e2e-d7e2ee94?sem=1` → typed `S4KA` → roster 200 ("E2E Kind") → keyboard login → `Los geht's` → `/lernpfad` renders the REAL path: "3 Übungen für dich bereit", 4 tiles with real titles/descriptions, 3 available + 1 locked, A1.2a pip "Stufe 1 geschafft". Enter on a tile → `practice-session/start` **200** → PracticeScreen "Aufgabe 1 von 8 · Lege · Tippe auf dem Zahlenstrahl …". Completed the A1.2a L2 session via keyboard: 8 problems, 8 correct, 8× `sync` 200 + `end` 200 → `mastered_at` set, `slow_flag` set (median ~25s), path tile updated live ("Stufe 2 geschafft"), teacher console shows "Stufe 2 · 8 Versuche, 8 richtig · Gemeistert · Langsames Bearbeiten". (Finding F3 captured on the same run.)

**Journey 3 — Diagnostic → Förderplan → draft path (COMPLETE, API-driven).** Created `session_tickets` row → `diagnostic-sessions` start → posted 60 answers via `diagnostic-results` (wrong on Q1-8, correct on the rest) → auto-complete fired exactly at answer 60 (`session_completed: True`; row `status=completed`, `completed_at` set). `foerderplan-generate` → recommendations `[A1.1a, A1.1b, A1.2a, A1.2b, A1.3, A1.4, A1.5]` (exact designed counting-weakness profile), category stats correct, **new draft path created** (`ce9fc762-…`, 7 items, 3 available/4 locked, `source_session_id` set). Opened that draft path in the teacher console: renders "Entwurf" banner, all 7 skill tiles, per-skill rows. Förderplan page renders the recommendations.

**Fresh gates (Journey 4):** see §4.

---

## 4. Fresh gate output

| Gate | Command | Result |
|---|---|---|
| Flutter tests | `cd math_app && flutter test` | **PASS — 453/453** (`00:12 +453: All tests passed!`) |
| Dashboard types | `cd dashboard && npx tsc --noEmit` | **PASS** (clean, no output) |
| Spec validation | `python scripts/check_specs.py` | **PASS** (`OK: 36 specs validated`) |
| Backend check | `deno check learning-path practice-session diagnostic-results diagnostic-sessions foerderplan-generate student-auth _shared/ordering.ts` | **FAIL** — `diagnostic-sessions/index.ts` 5× TS2339 (`GenericStringError`), exit 1 |

---

## 5. What I looked for and found absent

- Fake/mock/hardcoded progress: none — every dashboard number traced to live tables; the child screen shows real states from `learning-path` GET.
- Wrong German: none found in the exercised surfaces; child copy is non-blaming and age-appropriate.
- Colour-only signals: none — every state carries text + icon (lock/▶/✎ chips, "Langsames Bearbeiten" label, mastered pips with check glyphs).
- Missing empty/loading/error states: path console has draft/archived banners, "Kein Zugriff", German error/retry; child path screen has loading/no-token/no-path/error states.
- CORS/preflight breakage: none in any function exercised.
- Math/logic errors in generated problems: none — 8 real session problems hand-verified (sequence_gap arithmetic all correct); generator tests (453) cover tens-overstep, negatives, ZR bounds; only the duplicate-fill (F4) is a quality issue, not a correctness one.
- Dead ends: **one real one, F1** — the add-skill dead-end the teacher can create through normal UI.

---

## 6. Residual notes

- My live runs created real data: one abandoned session (`e867c350-…`, A1.1a L1, 0 problems), the A1.2a L2 mastered session + `skill_progress` L2 row, a new diagnostic session (`4f019629-…`, completed), its Förderplan (`0bc3c565-…`) and draft path (`ce9fc762-…`), and the ticket `997c87da-…`. The legacy `basic_strategy_1` add/remove on path B was round-tripped and left no residue (path B back to its original 2 items).
- F5's three dangling sessions predate this run in two of three cases, so the pattern is reproducible, not a one-off.
