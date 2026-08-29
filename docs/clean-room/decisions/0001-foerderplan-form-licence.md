# ADR 0001 — Licence basis for the Förderplan form

**Status:** ⏳ OPEN — verification not yet obtained
**Date raised:** 2026-08-29
**Owner:** Jakob
**Task:** `tasks.md` R0.7 (checkbox stays unchecked until this ADR resolves)

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
| Source publication checked | *(not yet)* |
| Licence/terms found | *(not yet)* |
| Enquiry sent to SenBJF on | *(not yet)* |
| Reply received on | *(not yet)* |
| Outcome | *(open)* |
