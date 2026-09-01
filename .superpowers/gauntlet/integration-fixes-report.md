# Integration-Critic Fixes Report

**Branch:** `gauntlet/p2-p3-p4`
**Date:** 2026-09-01
**Scope:** F1, F3, F4, F5, F6 (F2 already fixed + deployed — not touched beyond a comment-only edit that keeps `deno check` green)

---

## F1 (Critical) — Add-skill picker exposes legacy/retired skills → tappable dead-end

**Fix (dashboard only):**
- `dashboard/lib/lernpfad/types.ts`: added `SPEC_BACKED_SKILL_IDS` — a `ReadonlySet<string>` of the 36 skill-spec ids read from `docs/clean-room/skills/specs/*.json` filenames (A1.1a … D1.2).
- `dashboard/lib/lernpfad/queries.ts` (`getPathDetail`): `allSkills` now filters `SPEC_BACKED_SKILL_IDS.has(skill.id) && !onPath.has(skill.id)` — the only picker source. `PathConsole` consumes `allSkills` from `getPathDetail`; the class page (`klassen/[id]/page.tsx`) fetches `skills` rows only to resolve slow-flag titles, not as a picker, so no other filter site exists.

**Evidence:**
- `cd dashboard && npx tsc --noEmit` → clean.
- `cd dashboard && npm run build` → success (Next.js production build, 15 routes).
- Live console (dev server `http://localhost:3000`, e2e teacher `E2E Lehrkraft`, path `0fadca06-…`): the "Kompetenz aus dem Katalog" select lists exactly **32 options** = 36 spec-backed ids minus the 4 skills already on the path (A1.1a/A1.1b/A1.2a/A1.2b). Every listed title is a spec-backed skill ("Zählen in Schritten" … "Die passende Rechenoperation erkennen"); the legacy/retired titles ("Rechenschiffchen aus Erinnerung", "Kraft der 5", "Fingerblitz") are gone. No spec-less skill can be added → no dead-end tile.

---

## F3 (Important) — "Fast geschafft!" after a mastered session

**Fix:**
- `math_app/lib/practice/practice_controller.dart`: tracks `_firstAttemptCorrectCount` (incremented only on first-attempt-correct submissions) and exposes `bool get sessionMastered => _firstAttemptCorrectCount >= spec.mastery.correctOf` — the **session** verdict, distinct from the server's whole-skill `MasteryResult.mastered`.
- `math_app/lib/screens/practice_screen.dart` (`_buildSummary`/`_buildSummaryMessage`): the primary message is keyed to the session result. A mastered session shows "Geschafft!" + "Du hast alle 8 Aufgaben richtig." and, when the skill still has levels (`!result.mastered && remainingLevels > 0`), a secondary line "Noch N Stufen bis die Kompetenz ganz geschafft ist." (singular handled). "Fast geschafft!" now appears **only** when the session itself was not mastered. Skill-mastered sessions keep the unlocked-skill list.

**Evidence:**
- New widget test `mastered session with further skill levels: the summary is session-positive…` in `test/practice_screen_test.dart`: 8/8 first-attempt correct at level 1, server returns `skill_mastered: false` → asserts `controller.sessionMastered`, "Geschafft!", "Du hast alle 8 Aufgaben richtig.", "Noch 2 Stufen bis die Kompetenz ganz geschafft ist.", and `find.text('Fast geschafft!')` findsNothing.
- `flutter test test/practice_screen_test.dart` → 8/8 pass. Full `flutter test` → **455/455 pass**.

---

## F4 (Important) — Duplicate problems within one session

**Fix (spec range widening, ZR + ten-boundary constraints preserved):**

| Spec level | Template | Old range | New range | Distinct (was → now) |
|---|---|---|---|---|
| A1.1a L1 | numberline_step | start [10,12] | start [8,15] | 3 → 8 |
| A1.1b L1 | numberline_step | start [40,42] | start [45,52] | 3 → 8 |
| A1.1b L2 | sequence_gap (crosses 50) | start [47,48], len 5 | start [45,48], len 6 | 2 → 4 |
| A1.1b L3 | sequence_gap | start [47,48] | start [41,92] | 2 → 52 |
| A1.2a L1 | numberline_step | start [18,20] | start [14,20] | 3 → 7 |
| A1.2a L2 | sequence_gap | start [14,18] | start [11,18] | 5 → 8 |
| A1.2a L3 | sequence_gap | start [14,18] | start [11,18] | 5 → 8 |
| A1.2b L1 | numberline_step | start [91,95] | start [88,95] | 5 → 8 |
| A1.2b L2 | sequence_gap (crosses 50) | start [52,53] | start [51,54] | 2 → 4 |
| A1.2b L3 | sequence_gap | start [51,52] | start [41,52] | 2 → 12 |
| A1.5 L1 | numberline_step (crosses 30) | range [28,32], start [28,29] | range [20,32], start [20,29] | 2 → 10 |
| A1.5 L2 | sequence_gap (crosses 30) | start [28,29] | start [26,29] | 2 → 4 |
| A1.5 L3 | sequence_gap (crosses 50) | start [48,49] | start [46,49] | 2 → 4 |
| A3.3 L2 | sequence_gap (double) | start [2,3] | start [2,12] | 2 → 11 |
| B2.2 L1 | numberline_step | start [10,12] | start [8,15] | 3 → 8 |
| C3.2 L1 | numberline_step (step 5 → full ten) | start [25,35] | start [20,35] | 3 → 4 |

Every widened sequence stays inside ZR100 (≥1 for downward) and every widened A1.1b L2 / A1.2b L2 / A1.5 L1–L3 sequence still crosses its ten-boundary. The four levels capped at exactly 4 (A1.5 L2/L3, A1.1b L2, A1.2b L2) are capped by the boundary-crossing constraint (only 4 starts keep the sequence crossing); C3.2 L1 is capped at 4 by the "reach the full ten and continue" step-5 constraint; A1.2a L1 at 7 by the run-length-to-12 cap.

**Smoke-test extension** (`test/all_specs_smoke_test.dart`): new test "no degenerate levels: >= 4 distinct problem signatures per level" — for every spec × level, across the 5 smoke-test seeds, the set of `jsonEncode(p.display)` signatures must have length ≥ 4. flash_subitize / the subitizable zehnerfeld levels (A2.1, counts [1,5]) are documented in the test as legitimately capped at 5 (≥ 4, so no exception is needed); no current template supports fewer than 4.

**Evidence:**
- `flutter test test/all_specs_smoke_test.dart` → 15/15 pass (incl. the new distinct-count test).
- Full-bank distinct scan before/after confirms the table above; every level now ≥ 4 distinct, and the headline F4 example A1.2a L2 (5 distinct, 3× repeat observed live) is now 8 distinct → no duplicates in an 8-problem session.
- `python scripts/check_specs.py` → `OK: 36 specs validated`.

---

## F5 (Minor) — Dangling abandoned sessions

**Finding (confirmed):** the app does **not** mark abandoned sessions. `diagnostic_sessions.status` allows `'abandoned'` (schema check in `20260517000000_initial_schema.sql`), but nothing ever writes it: the child closes mid-diagnostic by popping (`diagnostic_screen.dart` PopScope → "Diagnose beenden?" → `Navigator.pop`) with no server call, and the `diagnostic-sessions` edge function's only terminal action is `complete` → `status: "completed"`. The same applies to mid-practice closes (`practice_screen.dart` "Übung beenden" pops without `/end`, leaving `practice_sessions.ended_at` null).

**Action (document-only):** a safe fix needs a product decision — an inactivity timeout, or an explicit "abandon" action that still permits resume — because an `in_progress` diagnostic session is deliberately **resumable** ("Du kannst später dort weitermachen"), so auto-marking it abandoned on close would break resume. Notes added:
- `backend/supabase/functions/diagnostic-sessions/index.ts` (near the `complete` branch),
- `math_app/lib/screens/diagnostic_screen.dart` (PopScope exit branch),
- `math_app/lib/screens/practice_screen.dart` (`_confirmClose`).

`deno check diagnostic-sessions/index.ts` → clean (comment-only change, no F2 regression).

---

## F6 (Minor) — Misleading "aus Diagnostik vom <date>" label

**Fix:** `dashboard/app/dashboard/lernpfade/[pathId]/page.tsx` — the label now shows ` · aus Diagnostik vom <date>` only when `currentPath.source_session_id` is set; a path created without a source session shows ` · manuell erstellt`.

**Evidence (live):** path A (`0fadca06-…`, `source_session_id` null) now renders "3 Kompetenzen freigeschaltet · manuell erstellt" instead of the former misleading "aus Diagnostik vom …".

---

## Verification summary

| Gate | Command | Result |
|---|---|---|
| Dashboard types | `cd dashboard && npx tsc --noEmit` | PASS |
| Dashboard build | `cd dashboard && npm run build` | PASS |
| Flutter tests | `cd math_app && flutter test` | PASS — 455/455 |
| Flutter analyze | `cd math_app && flutter analyze` | 0 errors (only pre-existing warnings/infos in legacy files) |
| Spec validation | `python scripts/check_specs.py` | PASS — `OK: 36 specs validated` |
| Backend check (edited fn) | `deno check diagnostic-sessions/index.ts` | PASS |
| Live console (F1) | picker lists 32 spec-backed options only | PASS |
| Live console (F6) | neutral "manuell erstellt" label | PASS |
