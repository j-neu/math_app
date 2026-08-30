# ADR 0009 — Mastery threshold and the slow-response flag

**Status:** 🟡 DRAFT — awaiting Jakob's sign-off
**Date:** 2026-08-30
**Owner:** Jakob
**Task:** `2026-08-30-p1-path-engine` Task 15

## Context

The learning-path engine advances a child through skill levels and must decide, per level, when a child has demonstrated enough to move on, and whether anything about *how* they answered is worth surfacing to the teacher. `backend/supabase/functions/_shared/mastery.ts` implements both pieces today: `isLevelMastered(correct, total)` compares against a fixed `MASTERY_RATIO = 7 / 8`, and `isSlow(median, bandMs)` compares a level's median response time against a per-level band and sets `skill_progress.slow_flag` — a value the engine reads nowhere in its own progression logic. Both numbers are pedagogical judgment calls, not implementation details, so the charter (`rewrite.md`) requires a written rationale for each, argued from the literature rather than carried over from any existing instrument.

## Decision

- A level is **mastered at ≥7 of 8 correct (87.5%)**. This is the only gate on progression; response time plays no part in it.
- Response time never gates progression. Instead, once a level closes, its median response time against the level's slow-response band sets `skill_progress.slow_flag` — a signal shown to the teacher, never to the child, and never fed back into the engine's own advancement decision.

## Reasoning

1. **7 of 8 is the right height for a mastery bar.** It must sit high enough that a child who is guessing does not clear it, and low enough that a single slip on an otherwise secure skill does not block progress. 8 attempts is few enough to keep a level short; 7 of 8 tolerates exactly one miss while still requiring near-total accuracy — a guessing pattern (roughly even odds per item) clears it only by chance many standard deviations out.
2. **Timing measures *how* a child computes, not *whether* they can.** Response time is a strategy indicator, not a competence gate — a child can be correct while still counting on fingers, and a fast-but-wrong answer is still wrong (Selter & Spiegel 1997). Gating progression on speed would conflate strategy maturity with correctness and could stall a child who is accurate but still transitioning strategies.
3. **The didactic target here is Ablösung vom zählenden Rechnen** (moving from counting-based to fact-based/derived strategies), and judging *when* to intervene on that transition is the teacher's professional call, not the software's (Wartha 2019). `slow_flag` exists to hand the teacher that signal — it deliberately carries no automated consequence in the engine.

## Consequences

- The slow-response bands (`bandMs` per level) are tunable from pilot data at any time without touching progression behaviour, because they gate nothing — only `MASTERY_RATIO` requires this level of scrutiny to change.
- `skill_progress.slow_flag` is teacher-facing only; no dashboard or child-facing surface may present it as a pass/fail signal or use it to alter the path.
- Any future change to `MASTERY_RATIO` needs its own written rationale here or in a follow-up ADR, per the same charter requirement.
