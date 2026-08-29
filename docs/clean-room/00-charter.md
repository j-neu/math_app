# 00 — Clean-Room Charter

**Date:** 2026-08-29
**Owner:** Jakob
**Status:** DRAFT
**Applies to:** all artifacts of the Numeris/Prozedia primary-school math diagnostic produced from this date onward.

---

## What this rewrite is

This project rebuilds the pedagogical payload of the Numeris/Prozedia math diagnostic — its items, its selection and sequencing, its skill catalog and its Förderplan recommendation mappings — as an independently developed product whose content is ours.

Clean-room practice is adapted for a solo developer through a documentation firewall: for every artifact we ship we must be able to show, from the audit trail, that it was developed from cited, published, independently reviewable sources — scientific constructs and standard didactic vocabulary — and not from any protected legacy material. The rewrite therefore restates the scientific constructs the diagnostic measures (counting competence, quantity recognition, number decomposition, place value, calculation strategies), chooses its own items, numbers, wordings, counts and orderings, and derives its own skill catalog and recommendation rules from the published literature rather than from any existing instrument.

The scientific foundations are preserved and attributed. Constructs, didactic sequence and standard German didactic vocabulary are unprotected and stay. What changes is the specific expression: the numbers, the wording, the item forms, the grouping, the ordering. We go to the same published literature the legacy materials themselves drew from and derive a sibling work — our own.

## What this rewrite is not

- It is not a search-and-replace pass over old item files. Existing item text is not copied, lightly edited, rephrased, or parameter-swapped. Protected items are not used as a basis, even in rewritten form.
- It is not a preservation project. Legacy CSV files, card references, source attributions and framework notes are archived out of the shipped tree and are not consulted while drafting.
- It is not a license-compliance patch. Keeping one protected title, one distinctive item design, or one lifted skill description would defeat the purpose even if the license allowed it.
- It is not a claim that our science is new. The constructs are standard German Grundschulmathematik; we claim only that the specific expression of the product is independently ours.

## Commercial posture

Until the entire rewrite list (tasks.md R0–R7) is complete and closed, the product is **free, school-internal, research-partnership use only**. No pricing conversations, no invoices, no "kaufen" anywhere in the product. Pilots are research partnerships, not sales. The freeze is lifted only by the explicit step in R7.5.

## The governing rule

> For every artifact we ship, we must be able to answer: **"Why does this exist, and where did it come from?"** — and the answer must never be a protected source or instrument.

Valid answers are of the form:

- "It tests construct X as defined in [published, citable source], chapter/page."
- "It was developed by [author] from the published literature on [topic]."
- "It is the standard didactic vocabulary used across the German primary-math literature."
- "It came from expert review feedback by [person], with credentials, recorded in the item log."

The invalid answer — "we took this from [protected legacy source] and changed some details" — is a liability. If any artifact requires it, that artifact is rewritten before it ships.

## How the rule is enforced

Every shipped artifact (item, skill, mapping rule) gets:

1. A provenance file (item template per rewrite.md §6; per-skill and per-mapping documentation per the directory structure below), and
2. A row in `provenance.csv` recording who created it, when, what sources were cited, and who reviewed and signed it off — and
3. A checkable claim of independence from the legacy material, adjudicated by Jakob before sign-off.

The audit trail is built as we go, never reconstructed afterward. `scripts/check_provenance.py` verifies mechanically what can be verified: every item file complete, every item ID present in the provenance log, every signed row carrying a source and a reviewer. What cannot be verified mechanically — that the content actually came from the cited sources and not from memory of the legacy material — is Jakob's review, recorded per artifact in the log.

## Directory map (R1.6)

```
docs/clean-room/
  00-charter.md              this document
  01-construct-map.md        domains A–D with numbered constructs (R1.3)
  02-blueprint.md            two-tier item-count plan, sequencing, break-off (R1.4)
  03-bibliography.md         full scientific bibliography (R1.2)
  04-item-development-log.md chronological decision log (R2.10)
  provenance.csv             one row per shipped artifact
  items/                     one .md per item, §6 template
  skills/                    one .md per skill (R3)
  foerderplan/               per-item if-wrong → recommend reasoning (R4)
  decisions/                 ADR-style records for structural choices (R1.8)
scripts/check_provenance.py  mechanical completeness/consistency gate (R1.6)
```

Charter review will tighten this text as the construct map and blueprint (R1.3, R1.4) land. Status moves from DRAFT to LIVE once the first items are drafted and the first provenance rows are signed.
