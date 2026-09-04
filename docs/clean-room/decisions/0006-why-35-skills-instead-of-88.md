# ADR 0006 — Why ~35 skills instead of 88

**Status:** ✅ DECIDED — confirmed by Jakob, 2026-09-04
**Date:** 2026-08-29
**Owner:** Jakob
**Task:** `tasks.md` R1.8

## Context

The legacy skill taxonomy holds 88 skills with an ID scheme (`Z1`, `C1.1`, `S3.4`, `counting_3`, …) whose shape visibly tracks the numbering of a protected card deck, down to a `card_number` field on every skill. `rewrite.md` §7 records that 87 of those skills include imported entries that are largely redundant, and that the Z/C/S ID system mirrors the card-deck numbering convention; it estimates "maybe 30–40 distinct förderbare skills" and times the rewrite around 35. `tasks.md` R3.1 fixes the target: ~30–40 förderbare Skills with IDs from the construct map.

## Decision

The skill catalog is rebuilt from the construct map (`tasks.md` R1.3) as a set of **~30–40 förderbare Skills (target ~35)**. Skill IDs follow the construct map (`A3.1`, `C2.2`, …). The legacy Z/C/S ID scheme and the `card_number` field are deleted — the product ships no cards and nothing that references card numbering.

## Reasoning

1. **The construct map yields fewer distinct förderbare skills.** ~20 constructs plus their separable Förderaspekte produce roughly 30–40 genuinely distinct things a child can learn to do; the 88-skill taxonomy carries redundancy imported alongside the protected material (`rewrite.md` §7).
2. **Legacy IDs are a liability.** IDs like `Z1`/`C1.1`/`S3.4` and the `card_number` field visibly track a protected card deck. Replacing them with construct-map IDs disconnects us from that numbering and removes the "card" concept from the product entirely.
3. **Fewer, sharper skills make better Förderpläne.** Recommendation quality (R4.1/R4.2) depends on 1–3 clearly differentiated skills per failure pattern; a trimmed catalog produces sharper mappings than 88 overlapping ones.

## Consequences

- `tasks.md` R3.1: one `docs/clean-room/skills/<ID>.md` file per skill; every skill traces to at least one construct; no legacy ID appears anywhere.
- `tasks.md` R3.3: the new `skills_taxonomy.csv` (`skill_id, domain, construct_id, color, title_de, title_en, description_de, description_en`) has no `card_number` column.
- Any skill that ends up outside the 30–40 target needs a written rationale here.
