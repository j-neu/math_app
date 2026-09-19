# tasks.md — Current Task List

**Last updated:** 2026-09-19
**Supersedes:** the Clean-Room Rewrite task list (R0–R9), archived unchanged to
[Archive/tasks_cleanroom_r0-r9.md](Archive/tasks_cleanroom_r0-r9.md). That plan is fully closed
for content purposes (`STATUS.md`'s 2026-09-12 banner) — its only real surviving work, the
Phase R9 legal items and the Impressum/Datenschutz placeholders, is carried forward into
Section B below.
**Owner:** Jakob (solo, + Claude drafting/building)

**Read first:** [STATUS.md](STATUS.md) (one-screen shipped/active/paused view) ·
[docs/clean-room/v4/skills/BUILD_ORDER.md](docs/clean-room/v4/skills/BUILD_ORDER.md) (skill
batch order) · [DOCS_INDEX.md](DOCS_INDEX.md) (full doc map, authority order on conflict).
This file tracks *what's next and who owns it*; it does not restate content that lives
elsewhere — on any conflict, the docs above win.

**Standing rules (unchanged since the Gauntlet loop closed 2026-09-06):** every task here starts
from an explicit human request, nothing runs automatically; no commit/push/deploy and no
production data change without explicit authorization; no commercial conversation until Section
B's freeze-lift item is checked.

---

## A. Practice-content build-out (highest priority)

24 of 93 v4 skills are playable — run `python scripts/check_skill_spec_coverage.py` for live
status, not this file. The remaining 69 are batched by archetype tier in `BUILD_ORDER.md`:
5 left in Tier 1 (Reused), 31 in Tier 2 (Extended), 11 in Tier 3 (New — widget exists), 20 in
Tier 4 (New — from scratch).

- [ ] Pick and execute the next batch from `BUILD_ORDER.md` via `writing-plans` →
      `subagent-driven-development`, the same pattern used for all 24 shipped skills. No batch
      is picked automatically. Cheapest next pick: the rest of Tier 1 (Batch 1.11 doubling,
      1.12 tens arithmetic, 1.13 compensation) — closes out the entire Reused tier.

## B. Legal / compliance / pilot-readiness backlog

- [ ] Fill legal placeholders in `dashboard/app/impressum/page.tsx` and
      `dashboard/app/datenschutz/page.tsx` (`[NAME/ADRESSE/EMAIL]`)
- [ ] AVV/DPA signature with Supabase (`supabase.com/legal/dpa`) and with each pilot school
      before data processing
- [ ] One-page German teacher onboarding document
- [ ] Full-flow acceptance test on a real **Android tablet in Chrome** — teacher creates a
      class → student ticket → child completes the diagnostic → teacher downloads the
      Förderplan. No device has been available in any session to date. Archive the reference
      PDF at `docs/clean-room/acceptance/foerderplan-example.pdf`.
- [ ] Re-run the Phase D verification smoke test (`phase1_school_platform.md` §Verification,
      steps 1–12) — the deploy halves are already live, only the acceptance run is outstanding
- [ ] Cross-browser smoke test of the Flutter web client — Android Chrome is the pilot's
      primary target; Firefox and iPad Safari best-effort
- [ ] Phase E pilot scheduling — a real classroom at one or two schools, once the items above
      land
- [ ] External expert review — 2–3 Grundschullehrer/Sonderpädagogen give a didactic review of
      the current (v4) item bank; log feedback and what it changed
- [ ] Fachanwalt für Urheberrecht review — now of the v4 content (rebuilt on the original
      iMINT/PIKAS-derived CSVs with reworded items; legal considerations were explicitly waived
      for *authoring* this content on 2026-09-12, but whether it's safe to *sell* is a separate,
      still-open question this review would answer)
- [ ] Lift the commercial freeze — depends on both reviews above; not a build gate, governs only
      the first invoice

## C. Practice runtime hardening (P5/P6 — not started)

- [ ] P5 — art direction/engagement pass (`adhd guidelines.md`) across the shipped skills
- [ ] P6 — publish hardening: performance, load, error handling
- [ ] Physical-device test — no child-development round, diagnostic or practice, has ever run
      on a real Android tablet, only emulated browser viewports
- [ ] F5 — dangling session cleanup: a server-side scheduled job marks a session `abandoned`
      after N days of inactivity (decision made 2026-09-05, not implemented)

## Paused / no active priority

- `practice_skill_plan.md` — a skill to automate exercise-spec authoring; three blockers,
  deprioritized behind the manual batch work in Section A.
- Audit of the 8 legacy hand-built practice skills (`Z1`, `C1.1`, `C1.2`, `C2.1`, `C3.1`, `C4.1`,
  `S1.1`, `S3.4`) against their source cards — originally Phase R8 in the archived clean-room
  list. Its premise (don't sell content that's too close to a specific card) predates the
  2026-09-12 decision to explicitly set legal considerations aside for content authoring: revisit
  only if this resurfaces as a live concern, not as a standing task.
