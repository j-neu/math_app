# ADR 0003 — Why the core diagnostic has exactly 60 items

**Status:** ✅ DECIDED (provisional — Jakob to confirm)
**Date:** 2026-08-29
**Owner:** Jakob
**Task:** `tasks.md` R1.8

## Context

The legacy item bank contains 92 items (98 originally, reduced by deletions). It was derived from a protected source instrument whose own count stood at 98. Any count sitting close to that number invites a look at whether our selection and arrangement are truly independent — `rewrite.md` §5 makes exactly this point ("92 is suspiciously close to iMINT's 98").

`rewrite.md` §5 defines the defensible range as **50–80 items** for a 20–30 minute administration time with children aged 6–10, and recommends 60. `tasks.md` (Decisions locked, 2026-08-29) records that the test shape is "own blueprint, own item counts, own sequencing".

Count history:

| Stage | Count | Note |
|---|---|---|
| Protected source instrument | 98 | not ours to replicate |
| Legacy bank (after deletions) | 92 | derived from the above; retired |
| **Our core diagnostic** | **60** | this ADR |

## Decision

The core diagnostic contains exactly **60 items**, allocated per construct in the blueprint (`docs/clean-room/02-blueprint.md`, `tasks.md` R1.4). The per-construct allocation is our editorial choice, documented there with rationale from the bibliography, not a copy of any existing instrument's allocation.

## Reasoning

1. 60 is inside the 50–80 range that a 20–30 minute administration budget for ages 6–10 supports (`rewrite.md` §5). It sits at the shorter end — appropriate for a screening instrument administered in school time.
2. 60 is clearly distinct from both 92 (legacy) and 98 (the protected source), removing the coincidence that "a look" would otherwise target.
3. Extra coverage is not lost: the two-tier shape (ADR 0004) moves additional measurement into optional per-domain deep-dive blocks, so the core can stay short without narrowing the diagnosis.
4. Coverage weighting is grounded in the literature: counting gets the largest share (the highest-leverage diagnostic per Wartha/Schulz 2019), subitizing gets a focused share (Krajewski), and each construct's allocation is argued in the blueprint.

## Consequences

- R1.4 must allocate counts that sum to 60, each with a written rationale; the blueprint is re-checked against the construct map so no construct is unmeasured.
- R2.1–R2.7 draft exactly 60 core items plus the deep-dive blocks.
- Any future change to the core count must be recorded as a new decision here.
