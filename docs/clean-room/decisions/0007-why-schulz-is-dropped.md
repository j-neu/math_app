# ADR 0007 — Why the Schulz diagnostic is out of product scope

**Status:** ✅ DECIDED (provisional — Jakob to confirm)
**Date:** 2026-08-29
**Owner:** Jakob
**Task:** `tasks.md` R1.8

## Context

The project previously considered integrating the Schulz 151-question diagnostic (LISUM publication, CC BY-ND) as a second instrument. `tasks.md` (Decisions locked, 2026-08-29) records: "**Dropped from product scope.** Archived out of the shipped tree. Revisit only with a direct written licence from LISUM/Schulz." `tasks.md` R0.6 (done 2026-08-29) already moved the instrument out of the shipped tree.

`rewrite.md` §9 analyses the No-Derivatives licence in detail: verbatim, unmodified redistribution with attribution is permitted, but reordering, re-blocking, selecting items adaptively, restating items in our own words, or feeding individual items into our own Förderplan logic each constitute a derivative work that CC BY-ND forbids distributing.

## Decision

The Schulz diagnostic is **not part of the product** — not in v1 and not in any foreseeable integration. The only path to revisit is a **direct written licence from LISUM/Schulz** that overrides the No-Derivatives term for our specific integration, obtained before any engineering work begins.

## Reasoning

1. Everything we would actually want to do with the instrument — select items by our own blueprint, adapt which items are shown, wire results into our own diagnostic and Förderplan logic, present it alongside our own items — is exactly the derivative work the ND term forbids (`rewrite.md` §9). A "digital photocopy" of 151 questions has near-zero product value to us.
2. The scientific basis the instrument rests on is still available and citable: the Wartha/Schulz book *Rechenproblemen vorbeugen* remains in the bibliography (`03-bibliography.md`, A2) as a properly cited source. That book and the Schulz diagnostic instrument are different works; dropping the instrument loses nothing from the construct foundation.
3. The existing project rule that the two instruments must **never be mixed in a single report** stays in force regardless of this decision, so no integration path existed that kept reports clean.

## Consequences

- R0.6 stands: the instrument lives only in `_sources_private/`, is referenced by nothing in the shipped tree, and nothing in R1–R6 re-introduces it.
- A future revisit requires the written licence first; obtaining it is recorded as a new decision here before any integration work.
- The rule that Schulz material never appears in a report together with our own items is a hard constraint, not a soft preference.
