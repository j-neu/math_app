# ADR 0001 — Licence basis for the Förderplan form

**Status:** ✅ RESOLVED — outcome (b), fallback taken. Jakob, 2026-09-04
**Date raised:** 2026-08-29
**Date resolved:** 2026-09-04
**Owner:** Jakob
**Task:** `tasks.md` R0.7 — closed

## Resolution (2026-09-04)

**Outcome (b): we ship our own five-column layout. No SenBJF licence is needed, and no enquiry will be sent.**

The question this ADR raised — "may we reproduce SenBJF's specific form?" — became moot because R6.2 never reproduced it. What shipped is our own five-column layout built on the standard headings, and R6.2's own acceptance test requires "no protected title or authority name anywhere in the document" (verified: `grep -ri "SenBJF"` across `dashboard`, `backend`, `math_app/lib` → 0 hits).

Choosing (b) up front means the licence question never has to be answered. That is strictly safer than (a) and costs nothing functionally — the column headings are standard German pedagogical vocabulary, not SenBJF inventions.

**Consequence:** the Förderplan layout is now ours. Do not reintroduce a pixel-reproduction of the SenBJF form later without reopening this ADR.

## Context

The final deliverable of the clean-room rewrite is a **filled-in copy of `Research/foerderplan-pdf_02a.pdf`** — the five-column Förderplan form (Ist / Soll / Lernweg / Absprachen / Reflexion, plus a page 2 for Weitere Vereinbarungen and signatures).

The file carries a sidebar watermark reading **"SenBildJugFam 2017"** — the Berlin Senatsverwaltung für Bildung, Jugend und Familie. `rewrite.md` §8 flagged this as a separate copyright question from the Kartei: using an official form inside a school is one thing; redistributing it as part of a product sold to other schools is another.

The working assumption is that the form is free to use. That assumption has not yet been verified, and this ADR exists so the basis is on record rather than assumed.

## What has been decided already

The **naming** question is settled and shipped (`tasks.md` R0.4, done 2026-08-29): the product no longer says "Förderplan nach SenBJF" anywhere, and the downloads are no longer named `Foerderplan_SenBJF.pdf`. Naming the authority implies endorsement under UWG §5 regardless of how the form itself is licensed. The buttons now read "Förderplan (PDF)" / "Förderplan (Word)".

What remains open is the **layout** question: may we reproduce this specific form?

## What must be established

1. The terms under which SenBJF published the form. Check the source publication itself, not just a download page.
2. Whether those terms permit **redistribution by a third party as part of a product**, as opposed to use by a Berlin school.
3. Whether they permit use **outside Berlin** — pilot schools in Brandenburg or elsewhere would be receiving a Berlin form.

If the published terms are unclear, send one plain email to SenBJF asking explicitly, and record the sent date plus any reply here.

## Decision

**Pending.** One of:

- **(a) Permitted** — record the permitting clause verbatim with its source URL below, and keep the form as the deliverable. R6 proceeds unchanged.
- **(b) Not permitted / no answer** — fall back to our own form. This is a cheap fallback: the column headings (**Ist**, **Soll**, **Lernweg**, **Absprachen**, **Reflexion / Evaluation / Modifikation**, and the sub-labels Beobachtung/Bedarf, Ziele, Päd. Angebote/Maßnahmen/Lernarrangements) are standard German pedagogical vocabulary used across Bundesländer and are not SenBJF inventions. Only the specific visual layout would be protected. We would design our own five-column layout using the same standard headings and lose nothing functionally.

Because the fallback is cheap and safe, **this does not block R1 or R2**. It must be resolved before R6.2 renders the filled form.

## Consequences

- R6.1 (`form-mapping.md`) can be written now — it maps our data onto the five columns, which is the same work under either outcome.
- R6.2 must not ship a pixel-reproduction of the SenBJF form until this ADR reads (a).
- If (b), add a task to design the replacement form layout.

## Record

| Field | Value |
|---|---|
| Source publication checked | n/a — fallback taken before verification was needed |
| Licence/terms found | n/a |
| Enquiry sent to SenBJF on | never sent; made unnecessary by (b) |
| Reply received on | n/a |
| Outcome | **(b) — own five-column layout, shipped in R6.2** |
