# ADR 0004 — Why the test has a two-tier shape (core + deep-dive blocks)

**Status:** ✅ DECIDED (provisional — Jakob to confirm)
**Date:** 2026-08-29
**Owner:** Jakob
**Task:** `tasks.md` R1.8

## Context

`tasks.md` (Decisions locked, 2026-08-29) fixes the shape: "**Two-tier.** ~60-item core diagnostic + optional per-domain deep-dive blocks a teacher can add. Own blueprint, own item counts, own sequencing."

`rewrite.md` §5 bounds a single administration at 50–80 items for a 20–30 minute session with children aged 6–10. The construct map (`rewrite.md` §4) also marks Domain D (Sachsituationen) as light/optional coverage in v1, which the two-tier shape accommodates naturally.

## Decision

The diagnostic ships as a **core tier of ~60 items** covering all domains, plus **optional per-domain deep-dive blocks** that a teacher deliberately adds on top. Each block has a documented entry criterion ("add this block when the core tier shows X") per `tasks.md` R2.8.

## Reasoning

1. **Administration-time bound.** Ages 6–10 span four years of development. A single fixed-size instrument either over-runs for the youngest children or under-measures the oldest. The two tiers let the core stay within the 20–30 minute budget for everyone.
2. **Teacher control over length.** Adding a block is an informed professional choice driven by core results, not an automatic full battery. The teacher keeps control of how much classroom time the diagnosis takes.
3. **Core stays short, diagnosis stays deep.** The short core is defensible and cheap to administer for all children; when a specific weakness surfaces, the matching block preserves deep diagnosis where it is actually needed.
4. The two-tier structure is a design decision we make from our own blueprint — it is not a property inherited from any existing instrument, and the entry criteria and item counts are ours.

## Consequences

- R1.4 (blueprint) states which domains get a block, how many items each, and the entry criteria for adding one; core counts sum to 60 per ADR 0003.
- R2.8 drafts the blocks under the same item-template and provenance requirements as the core.
- R5.1 flags each item by tier in the data files; the running diagnostic must support administering a block on top of an existing core result.
