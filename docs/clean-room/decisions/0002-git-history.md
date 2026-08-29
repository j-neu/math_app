# ADR 0002 — Leave the git history intact

**Status:** ✅ DECIDED (provisional — Jakob to confirm or overrule)
**Date:** 2026-08-29
**Task:** `tasks.md` R0.8

## Context

`tasks.md` R0.2 moved the protected source material (iMINT-Kartei and its page extractions, PIKAS FÖDIMA, the Wartha/Schulz Diagnosebogen, Fachbriefe, scanned diagnostic pictures) out of the tracked tree into a gitignored `_sources_private/`.

That removes them from the working tree and from all future clones' checkouts, but **not from history**. Every one of those files is still reachable in earlier commits. Anyone with the repository can `git checkout` a 2025 commit and get the full Kartei PDF back.

The alternative is rewriting history (`git filter-repo` or similar) to purge the blobs entirely.

## Decision

**Leave the history intact.**

## Reasoning

1. **The repository is private.** It is not published, and no third party has clone access. The exposure is theoretical, not actual distribution — and copyright infringement turns on distribution, not on possession of a study copy.

2. **Possession was always legitimate.** These are materials Jakob legitimately obtained and studied as a practising teacher. Having read them is not the problem; shipping derivations of them commercially is. Nothing about R0.2 implies the earlier possession was wrongful.

3. **History is evidence in our favour, not against us.** The clean-room defence rests on being able to show *when* and *how* each artifact was developed. A continuous, unrewritten history that shows the derivation phase, then the containment commit, then the independent rebuild, is exactly the audit trail `rewrite.md` §10 asks for. A rewritten history looks like concealment and destroys the timeline we would want to produce.

4. **Rewriting is disproportionate and risky.** ~790 files across years of commits; a filter-repo pass invalidates every existing clone and every commit SHA referenced in the docs (`STATUS.md` and `tasks.md` both cite commits and dates). The cost is real and the benefit is close to zero while the repo stays private.

## Consequences

- If the repository is ever **made public or transferred**, this decision must be revisited *before* that happens. Purging history at that point becomes mandatory, not optional. Add it as a precondition to any open-sourcing or acquisition-diligence step.
- `_sources_private/` must stay gitignored. Re-adding any of it would defeat R0.2 entirely.
- Anyone cloning the repo for development does **not** get the source material, which is the intended behaviour — see `_sources_private/README.md` for how the drafting firewall is meant to work.

## Overruling this

If Jakob prefers a purge, the work is: `git filter-repo --path _sources_private --path Research/Research --invert-paths`, force-push, and re-clone everywhere. Say so and it gets done — but note point 3 first.
