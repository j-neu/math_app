# tasks.md — Clean-Room Rewrite: Immediate Task List

**Created:** 2026-08-29
**Status:** ACTIVE — highest priority. Blocks all commercial activity.
**Owner:** Jakob (solo, + Claude drafting)
**Supersedes as current focus:** `phase1_school_platform.md` Phase D/E (pilot continues as a *research partnership*, not as a sale)
**Strategy document:** `rewrite.md` (the why and the legal reasoning; this file is the what and the when)

---

## Guiding principle

> Stay as close to the source material as the **science** allows, and as far from it as the **expression** requires.

Constructs, didactic sequence and standard German vocabulary are unprotected and stay. Specific items, specific numbers, specific wording, specific selection and arrangement, specific card structures, and protected work titles all go.

For every artifact we ship we must be able to answer *"why does this exist and where did it come from?"* without naming iMINT, PIKAS or Schulz. See `rewrite.md` §16.

---

## Decisions locked (2026-08-29)

| Question | Decision |
|---|---|
| Primary sources | **Acquire the core bibliography first.** Item writing is blocked until the books are in hand (R1.1). Open/official sources (KMK, Rahmenlehrplan BE/BB) supplement, they do not replace. |
| Test size & shape | **Two-tier.** ~60-item core diagnostic + optional per-domain deep-dive blocks a teacher can add. Own blueprint, own item counts, own sequencing. |
| Authoring | **Claude drafts, Jakob reviews every item.** The review is both the pedagogical check and the independence check; sign-off is recorded per item in the provenance log. |
| Schulz (151 Q, CC BY-ND) | **Dropped from product scope.** Archived out of the shipped tree. Revisit only with a direct written licence from LISUM/Schulz. |
| Practice engine (8 skills) | Stays paused **and** out of commercial scope. Audit deferred to Phase R8; not a launch blocker. |
| Final deliverable | A **filled-in `Research/foerderplan-pdf_02a.pdf`** (Ist / Soll / Lernweg / Absprachen / Reflexion), generated from a session, downloadable from the dashboard. |

**Commercial posture until this list is complete:** free, school-internal, research-partnership use only. No pricing conversations, no invoices, no "kaufen" anywhere in the product.

---

## Phase R0 — Containment ✅ DONE 2026-08-29 (R0.7 open)

Cheap, fast, removes the most visible exposure. None of it depended on the bibliography.

**Verified:** `flutter analyze` → 0 errors (323 pre-existing style lints untouched); `npx tsc --noEmit` in `dashboard/` → clean.

**Four things were found during execution and fixed beyond the literal task text:**

1. **Scanned Kartei pictures were bundled into the shipped web build.** `math_app/pubspec.yaml` declared `Research/DiagnosticPictures/` as an asset directory, so ~18 scanned pages shipped in every Flutter web deploy. Every image the CSV references already had a Flutter widget override, so none of them *rendered* — but they shipped. Unbundled, moved to `_sources_private/`, and the dead `Image.asset` fallback replaced with a German placeholder so a missing asset cannot crash the diagnostic.
2. **`Karte N` references were printed in every Förderplan.** Not just the Werktitel: `foerderplan-pdf`, `foerderplan-kurz-pdf` and the docx route all wrote `- Karte ${card_number}: ...` into the output. Removed from all four output builders. (The `card_number` *column* still exists in the schema — R3.1 deletes it.)
3. **A user-facing claim in the app.** `settings_screen.dart` displayed "Basiert auf iMINT- und PIKAS-Forschung" to users. Replaced with "Auf Grundlage der mathematikdidaktischen Forschung zur Prävention von Rechenschwierigkeiten".
4. **Verbatim German card text quoted in ~14 source files.** Doc comments like `**From Card 1:** "Zuerst wird das gezählte Objekt zur Seite geschoben."` reproduced the card's own wording without ever naming iMINT — so the obvious grep missed them. All replaced with neutral paraphrases. `IMINT_TO_APP_FRAMEWORK.md` was archived to `_sources_private/legacy-notes/` per `rewrite.md` §2, which also satisfies R8.2's archive option.

- [x] **R0.1 — Freeze the commercial posture in writing**
  **Description:** Add a "Rechtlicher Status" block to `STATUS.md` and `README.md` stating the product is in clean-room rewrite and non-commercial until this list completes. Add the same note at the top of `phase1_school_platform.md` so Phase G (Billing) cannot be picked up by accident.
  **Test (code):** `grep -c "Clean-Room" STATUS.md README.md phase1_school_platform.md` returns at least 1 for each file.

- [x] **R0.2 — Move protected source material out of the shipped tree**
  **Description:** Move `Research/Research/iMINT-Kartei_190529.pdf`, `Research/Research/iMINT_Kartei_extracted-pages/`, `Research/Research/PIKAS/`, `Research/Research/Erfolgreich_rechnen_lernen_WEB_2019_12_20_diagnose.docx`, `Research/Research/_diagnose_extracted/` and the Fachbrief PDFs into `_sources_private/` at repo root. Add `_sources_private/` to `.gitignore`. Add `_sources_private/README.md`: "Reference only. Never a basis for a shipped artifact. Nothing in here may be quoted, paraphrased, or parameter-copied into `docs/clean-room/`."
  **Test (code):** `git ls-files | grep -Ei "imint|pikas|erfolgreich_rechnen"` returns nothing, and `ls _sources_private/` shows the moved files.

- [x] **R0.3 — Remove the Werktitel from generated output**
  **Description:** `backend/supabase/functions/foerderplan-kurz-pdf/index.ts:118` and `dashboard/app/api/foerderplan-kurz-docx/route.ts:118` both write the literal string `"Auf dem Weg zum denkenden Rechnen:"` into the Lernweg column of every generated Förderplan. Same in `math_app/lib/services/kurz_foerderplan_service.dart` `_buildLernweg`. Replace with a neutral heading such as "Fördervorschläge:".
  **Test (code):** `grep -ri "denkenden Rechnen" backend dashboard math_app/lib` returns nothing. **Test (manual):** regenerate one Förderplan PDF from an existing session and confirm the Lernweg column renders with the new heading.

- [x] **R0.4 — Drop "nach SenBJF" from the product surface**
  **Description:** Rename the two dashboard buttons (`dashboard/app/dashboard/foerderplan/[sessionId]/page.tsx:172,178`) and the download filenames (`Foerderplan_SenBJF.pdf` / `.docx`) to neutral wording — "Förderplan (PDF)" / "Förderplan (Word)", `Foerderplan_<Name>.pdf`. Naming the authority implies endorsement (UWG §5) even if the form itself is free to reuse.
  **Test (code):** `grep -ri "SenBJF" dashboard backend math_app/lib` returns nothing. **Test (manual):** download both files from the dashboard and confirm the new filenames.

- [x] **R0.5 — Strip `sourceCard` attributions from shipped code**
  **Description:** ~20 files under `math_app/lib/exercises/` carry `sourceCard: 'iMINT Green Card 1: ...'` / `'PIKAS Card 9: ...'` strings plus matching doc comments. These ship in the web bundle and read as an admission of derivation. Remove the field and its values from the `Exercise` model and all call sites; move any genuinely useful design notes to `_sources_private/legacy-notes/`.
  **Test (code):** `grep -ri "sourceCard\|iMINT\|PIKAS" math_app/lib` returns nothing, and `flutter analyze` is clean.

- [x] **R0.6 — Remove Schulz from product scope**
  **Description:** Move `math_app/Research/MathApp_Diagnostic_Schulz.csv` to `_sources_private/`. Remove the Schulz line from `STATUS.md` "Active" item 6. Update the `two-diagnostics` memory file to record that Schulz is out of scope pending a direct licence.
  **Test (code):** `git ls-files | grep -i schulz` returns nothing; `grep -ri schulz dashboard backend math_app/lib` returns nothing.

- [ ] **R0.7 — Verify the Förderplan form's licence and record the basis** ⏳ ADR raised, verification outstanding
  **Description:** The target form is watermarked *SenBildJugFam 2017*. Confirm in writing that reuse and redistribution inside a third-party product is permitted — check the source publication's terms, and if unclear send one email to SenBJF asking explicitly. If permission is not obtainable, fall back to our own form built on the standard headings (Ist / Soll / Lernweg / Absprachen / Reflexion), which are generic pedagogical vocabulary — only the specific layout would be protected.
  **Test (manual):** `docs/clean-room/decisions/0001-foerderplan-form-licence.md` exists and contains either the permitting clause verbatim with its source URL, or the sent enquiry with date plus a stated fallback decision.

- [x] **R0.8 — Decide and record the git-history position**
  **Description:** R0.2 removes files from the working tree but not from history. Decide: leave history intact (repo is private; history is evidence of good-faith development) or rewrite it. Recommendation: leave intact, document the reasoning.
  **Test (manual):** `docs/clean-room/decisions/0002-git-history.md` exists and states the decision and its reasoning.

---

## Phase R1 — Foundation (blocks all item writing)

- [ ] **R1.1 — Acquire the core bibliography** ⛔ BLOCKING
  **Description:** Obtain, in a form we can cite by chapter and page: Padberg/Benz *Didaktik der Arithmetik*; Wartha/Schulz *Rechenproblemen vorbeugen*; Selter/Spiegel *Wie Kinder rechnen*; Schipper *Handbuch für den Mathematikunterricht an Grundschulen*. Download now as free supplements: KMK Bildungsstandards Mathematik Primarstufe, Rahmenlehrplan Berlin-Brandenburg Teil C Mathematik, and the available Krajewski / Moser Opitz / Gaidoschik papers.
  **Test (manual):** `docs/clean-room/03-bibliography.md` lists each title with edition, year, ISBN and where the copy is. Every entry marked "in hand" or "downloaded"; none marked "to order".

- [ ] **R1.2 — Write the bibliography document**
  **Description:** `docs/clean-room/03-bibliography.md` — full citations plus a one-paragraph note per source on what we use it for (construct definitions / difficulty rationale / strategy taxonomy / break-off reasoning). This later becomes the "Wissenschaftliche Grundlagen" page content.
  **Test (manual):** Every source has a stated purpose; no source appears that has not actually been read.

- [ ] **R1.3 — Write the construct map**
  **Description:** `docs/clean-room/01-construct-map.md` — Domains A–D with numbered constructs (A1.1 … D1.2), each with a definition in our own words and a citation to R1.2. Start from `rewrite.md` §4 as a draft, then verify each construct against the acquired literature and adjust. From here on, the map — not the old CSV — is the source of truth.
  **Test (manual):** Every construct has (a) a one-sentence definition, (b) at least one literature citation with chapter/page, (c) no citation to iMINT, PIKAS or Schulz. Jakob signs off in the document header.

- [ ] **R1.4 — Write the two-tier blueprint**
  **Description:** `docs/clean-room/02-blueprint.md` — the core 60-item test (items per construct with a rationale for each allocation) plus the optional deep-dive blocks (which domains get one, how many items each, when a teacher would add one). Include sequencing rules and difficulty-distribution targets. Item counts must be our editorial choice with stated reasoning, not a copy of any existing instrument's allocation.
  **Test (manual):** Core item counts sum to 60; every allocation has a written rationale; an administration-time estimate is stated; deep-dive blocks are defined with entry criteria; cross-checked against R1.3 so no construct in the map is unmeasured in either tier.

- [ ] **R1.5 — Derive the break-off / abbreviated rules independently**
  **Description:** The current skip-group logic lives in `math_app/lib/screens/diagnostic_screen.dart`. The mechanism is our code and stays; the *rules* get rederived from the published argument that failure at ZR20-with-Zehnerübergang predicts failure at ZR100. Document in `docs/clean-room/02-blueprint.md` §Break-off with citations.
  **Test (code):** A unit test in `math_app/test/` asserts the new skip table matches the documented rules for every construct, and that no skip rule references a legacy question number.

- [ ] **R1.6 — Build the provenance infrastructure**
  **Description:** Create `docs/clean-room/` with `00-charter.md`, `items/`, `skills/`, `foerderplan/`, `decisions/`, plus `provenance.csv` (`artifact_id,type,author,created,sources_cited,reviewed_by,reviewed_on,independent_of`). Write `scripts/check_provenance.py`: fails if any item file lacks a required template field, or if any shipped item ID has no row in `provenance.csv`.
  **Test (code):** `python scripts/check_provenance.py` exits non-zero on a deliberately incomplete fixture and zero on a complete one.

- [ ] **R1.7 — Build the independence check**
  **Description:** `scripts/check_item_independence.py` — compares the new item bank against the archived legacy CSV (read from `_sources_private/`, never committed) and flags: identical operand pairs within the same construct, normalised prompt-wording overlap above a threshold, identical visual configurations (dot count *and* arrangement), and identical ordering runs. Output is a report, not a hard gate — Jakob adjudicates each flag.
  **Test (code):** Run with the current 92-item CSV as *both* inputs — must flag ~100% of items, proving detection works. Run against a hand-made clean fixture — must flag 0.

- [ ] **R1.8 — Write decision records for the structural choices**
  **Description:** `docs/clean-room/decisions/` — at minimum: why 60 core items, why the two-tier shape, why Domains A–D rather than the legacy five categories, why ~35 skills instead of 88, why Schulz is dropped.
  **Test (manual):** One ADR per decision, each stating context / decision / reasoning / date, referencing R1.2 sources where relevant.

---

## Phase R2 — Item bank (the bulk of the work)

Each drafting task: Claude writes the items **and** one `docs/clean-room/items/<ID>.md` provenance file per item using the `rewrite.md` §6 template. Each review task: Jakob approves, edits or rejects every item and signs its provenance row.

- [ ] **R2.1 — Draft Domain A1 items (Zählkompetenz)**
  **Description:** Items per the R1.4 allocation. Cover forward/backward counting from an arbitrary start, step-counting, Vorgänger/Nachfolger, Zehnerübergang. Numbers chosen deliberately away from the legacy set.
  **Test (code):** `check_provenance.py` clean for all A1 IDs; `check_item_independence.py` reports zero unadjudicated flags for A1.

- [ ] **R2.2 — Draft Domain A2 items (Anzahlerfassung)**
  **Description:** Subitizing and structured quantity recognition. Visual configurations must be newly designed and specified as explicit coordinates or a generation rule in the item file — not "like the old one but different". Prefer 10-frame / Rekenrek / finger patterns over the legacy dice configurations.
  **Test (code):** Provenance and independence clean for A2; every visual item file contains a complete specification of its arrangement.

- [ ] **R2.3 — Draft Domain A3 items (Zahlzerlegung)**
  **Description:** Part-part-whole in ZR10, flexible decomposition, doubles and near-doubles relationships, tested in both directions (decompose and compose).
  **Test (code):** Provenance and independence clean for A3.

- [ ] **R2.4 — Draft Domain B items (Stellenwertverständnis)**
  **Description:** B1 Bündelung/Entbündelung and B2 Zahldarstellung (Stellenwerttafel, Zahlenstrahl, non-standard forms). Replaces the legacy Stellenwerte block including its Zahlendiktat item — use a different auditory format, or drop audio from the core tier and place it in a deep-dive block.
  **Test (code):** Provenance and independence clean for B1 and B2.

- [ ] **R2.5 — Draft Domain C1+C2 items (Grundaufgaben ZR10, Strategien ZR20)**
  **Description:** Automatised facts, doubles, halving, complements to 10; then Zehnerübergang in both operations. Response-time capture is part of the item spec wherever strategy inference is intended (cite Selter).
  **Test (code):** Provenance and independence clean for C1 and C2. The independence check needs particular attention here — operand collisions are most likely in this range.

- [ ] **R2.6 — Draft Domain C3+C4 items (ZR100, flexibles Rechnen)**
  **Description:** Stellenweise / schrittweise / Hilfsaufgaben / Zerlegung, plus items designed to reveal strategy choice rather than correctness alone.
  **Test (code):** Provenance and independence clean for C3 and C4.

- [ ] **R2.7 — Draft Domain D items (Sachsituationen)**
  **Description:** Per the R1.4 allocation. Contexts must be original — no reused story scenarios.
  **Test (code):** Provenance and independence clean for D.

- [ ] **R2.8 — Draft the optional deep-dive blocks**
  **Description:** One block per domain that warrants it, per R1.4. Same item template and provenance requirements as the core tier.
  **Test (code):** Provenance and independence clean for all deep-dive IDs; each block documents its entry criterion ("add this block when the core tier shows X").

- [ ] **R2.9 — Jakob reviews the full item bank**
  **Description:** Every core and deep-dive item read for didactic soundness, age-appropriateness, German wording, and — critically — whether it reads as a paraphrase of something he has seen. Anything that does gets rewritten, not tweaked.
  **Test (manual):** Every row in `provenance.csv` carries `reviewed_by=Jakob` and a date. Zero items left in "pending" state.

- [ ] **R2.10 — External expert review**
  **Description:** Send the item bank to 2–3 Grundschullehrer/Sonderpädagogen for didactic review. Record the feedback and the changes it caused.
  **Test (manual):** `docs/clean-room/04-item-development-log.md` names each reviewer (name, credentials, date) and logs what their feedback changed.

- [ ] **R2.11 — Final independence adjudication**
  **Description:** Run `check_item_independence.py` over the completed bank. Every flag is either resolved by rewriting the item, or adjudicated in writing with reasoning ("the construct forces this operand range; the specific pair, wording and format all differ").
  **Test (code):** `python scripts/check_item_independence.py --strict` exits zero, meaning every flag is either gone or carries an adjudication entry.

---

## Phase R3 — Skill catalog rewrite

- [ ] **R3.1 — Define the new skill set and ID scheme**
  **Description:** Derive ~30–40 förderbare Skills from the construct map (R1.3). IDs follow the construct map (`A3.1`, `C2.2`), not the legacy `Z1`/`C1.1`/`counting_3` schemes. Drop `card_number` entirely — we ship no cards.
  **Test (manual):** `docs/clean-room/skills/` holds one file per skill; every skill traces to at least one construct in R1.3; no legacy ID appears anywhere.

- [ ] **R3.2 — Write all skill titles and descriptions**
  **Description:** German and English title plus a 1–2 sentence description per skill, stating what the child *can do* rather than what activity teaches it. This is the highest-risk text in the catalog — legacy phrasing leaks here most easily.
  **Test (code):** A script diffs every new `description_de` against the archived `skills_taxonomy.csv`; zero descriptions share a 6-word run with any legacy description.

- [ ] **R3.3 — Produce the new `skills_taxonomy.csv`**
  **Description:** Columns `skill_id, domain, construct_id, color, title_de, title_en, description_de, description_en`. No `card_number`.
  **Test (code):** CSV parses; row count matches R3.1; `check_provenance.py` finds a provenance row for every `skill_id`.

---

## Phase R4 — Förderplan mapping

- [ ] **R4.1 — Build the if-wrong → recommend mapping**
  **Description:** For every item in the new bank, decide independently which 1–3 skills a failure implies, with a written reasoning chain per item (likely cause → skill gap → priority order). The source is our own construct map plus the bibliography.
  **Test (code):** `docs/clean-room/foerderplan/mapping-rationale.md` has an entry per item ID; a script asserts every item maps to at least one skill and every mapped skill ID exists in R3.3.

- [ ] **R4.2 — Define the recommendation ordering rule**
  **Description:** Replace the legacy "category order → card_number ASC" ordering (card_number no longer exists). Define our own pedagogical sequencing rule and document its basis.
  **Test (code):** A unit test feeds a fixture result set and asserts the recommended-skill order matches the documented rule.

- [ ] **R4.3 — Rewrite the Ist / Soll / Lernweg text generation**
  **Description:** `kurz_foerderplan_service.dart` and its TypeScript ports build the three columns from templates. Rewrite those templates against the new taxonomy and neutral wording — this completes R0.3 properly rather than merely deleting one string.
  **Test (code):** A snapshot test renders a fixture Förderplan and asserts the Ist/Soll/Lernweg text contains no legacy category name, no card reference and no protected title.

---

## Phase R5 — Migration into the running system

- [ ] **R5.1 — New diagnostic CSV**
  **Description:** Produce `math_app/Research/diagnostic_core_v1.csv` from the item bank, with deep-dive blocks either flagged by tier in the same file or in a sibling file. Archive the legacy `MathApp_Diagnostic_with_skills.csv` to `_sources_private/`.
  **Test (code):** `DiagnosticService` loads the new CSV; a test asserts the parsed question count equals the blueprint count and that every `IfWrong` skill ID resolves in the new `SkillCatalog`.

- [ ] **R5.2 — Regenerate the visual items in Flutter**
  **Description:** `diagnostic_screen.dart` hardcodes dot arrangements keyed by legacy filename (`case 'img1936.jpg': // 7 dots: 3 top, 3 middle, 1 centre bottom`). Replace with the arrangements specified in the R2.2/R2.4 item files, keyed by new item IDs. Delete `math_app/Research/DiagnosticPictures/` and the filename-based switch.
  **Test (code):** `grep -r "img[0-9]" math_app/lib` returns nothing; `flutter analyze` clean. **Test (manual):** run the diagnostic and confirm every visual item renders the arrangement its item file specifies.

- [ ] **R5.3 — Database migration and reseed**
  **Description:** A migration that inserts the new bank and taxonomy as a *new* `diagnostics` row (new slug, version 1) rather than editing the existing one, so old pilot sessions stay readable. Decide and document what happens to existing sessions.
  **Test (code):** `supabase db push` succeeds; a query confirms the new diagnostic's question count and that every `if_wrong_practice_skills` entry exists in `skills`. **Test (manual):** an existing pilot session still renders its Förderplan without error.

- [ ] **R5.4 — Update edge functions and dashboard for the new taxonomy**
  **Description:** `foerderplan-generate`, `foerderplan-pdf`, `foerderplan-kurz-pdf`, the docx route and the dashboard's category displays all assume the five legacy categories. Move them to Domains A–D.
  **Test (manual):** Deploy to a preview and run the Phase D verification smoke test (`phase1_school_platform.md` §Verification, steps 1–12) end to end.

---

## Phase R6 — The deliverable: a filled-in Förderplan

- [ ] **R6.1 — Map our output onto the form's five columns**
  **Description:** The form is Ist (Beobachtung/Bedarf) · Soll (Ziele) · Lernweg (Päd. Angebote/Maßnahmen) · Absprachen (Wer?, Wie?, Mit wem?, Bis wann?) · Reflexion/Evaluation/Modifikation. We currently generate three of these. Decide what fills Absprachen and Reflexion — generated defaults, teacher-editable fields, or deliberately blank for handwriting — and document it.
  **Test (manual):** `docs/clean-room/foerderplan/form-mapping.md` states, per column, what fills it and from what data.

- [ ] **R6.2 — Generate the filled form (page 1)**
  **Description:** Render the Förderplan into the form layout: header (`für ___ für die Zeit von ___ bis ___` filled from student and session dates), five columns populated per R6.1. Page 2 (Weitere Vereinbarungen plus signature lines) rendered blank for handwriting.
  **Test (manual):** Complete a diagnostic as a test student, download the Förderplan, and confirm: name and date range filled; all five columns populated or intentionally blank per R6.1; page 2 present with signature lines; text fits its cells without overflow at A4 landscape; no protected title or authority name anywhere in the document.

- [ ] **R6.3 — Dashboard download wired and labelled**
  **Description:** One clear German button on the Förderplan page producing the filled form, with the neutral filename from R0.4.
  **Test (manual):** From a fresh teacher login: open a completed session → one click → the correct PDF downloads with the expected filename. Same for the Word variant if kept.

- [ ] **R6.4 — Full-flow acceptance test**
  **Description:** The end-to-end proof: teacher creates a class → student ticket → child completes the new 60-item diagnostic in the browser → teacher opens the Förderplan → downloads the filled form.
  **Test (manual):** Complete the whole flow on the deployed preview on a real device (iPad Safari), and archive the resulting PDF as `docs/clean-room/acceptance/foerderplan-example.pdf` as the reference output.

---

## Phase R7 — Legal and marketing close-out

- [ ] **R7.1 — "Wissenschaftliche Grundlagen" page**
  **Description:** A page in the dashboard, plus a line in the PDF footer, listing the bibliography from R1.2. Standard academic citation, protective under §51 UrhG.
  **Test (manual):** Page reachable from the dashboard footer; content matches `03-bibliography.md`; German throughout.

- [ ] **R7.2 — Marketing copy review against UWG §5**
  **Description:** Sweep every user-facing string, the landing page and any pilot-school communication for named authorities implying endorsement, protected work titles, and equivalence claims ("gleichwertig", "validiert", "ersetzt"). The permitted register is "auf Grundlage der Forschung von …", "orientiert an …".
  **Test (code):** `grep -rniE "imint|pikas|senbjf|lisum|denkenden rechnen|gleichwertig|validiert" dashboard math_app/lib` returns nothing. **Test (manual):** Jakob reads the landing page and confirms no equivalence claim remains.

- [ ] **R7.3 — Provenance completeness gate**
  **Description:** Final run of the audit trail across the entire shipped artifact set — every item, every skill, every mapping rule.
  **Test (code):** `python scripts/check_provenance.py --all` exits zero: every shipped artifact has a provenance row with a source citation and a reviewer signature.

- [ ] **R7.4 — Fachanwalt review**
  **Description:** Send `rewrite.md`, the charter, the construct map, the blueprint, a sample of item files and the provenance log to a Fachanwalt für Urheberrecht. Ask specifically about the construct-map overlap with the legacy category structure, the form reuse (R0.7), and the marketing register.
  **Test (manual):** Written opinion received and filed at `docs/clean-room/decisions/legal-opinion.md`. Any required changes are tracked as new checkboxes here before launch.

- [ ] **R7.5 — Lift the commercial freeze**
  **Description:** Only once R0–R7 are all checked: remove the freeze note from R0.1 and record the date the product became sellable.
  **Test (manual):** Every checkbox above is checked; `docs/clean-room/00-charter.md` records the completion date and what shipped.

---

## Phase R8 — Deferred (not a launch blocker)

- [ ] **R8.1 — Audit the 8 shipped practice skills**
  **Description:** Per `rewrite.md` §13, triage Z1, C1.1, C1.2, C2.1, C3.1, C4.1, S1.1, S3.4 into keep / rewrite / drop based on how closely their level structure follows a specific card. Commercial v1 ships diagnostic-only, so this is not blocking — but the skills must not be sold until audited.
  **Test (manual):** One triage entry per skill in `docs/clean-room/decisions/0003-practice-skill-triage.md`, each with a verdict and reasoning.

- [ ] **R8.2 — Rewrite or archive the practice framework docs**
  **Description:** `IMINT_TO_APP_FRAMEWORK.md` is explicitly a "how to translate iMINT/PIKAS cards" document. Rewrite it against our own construct map, or archive it.
  **Test (code):** `grep -ril "imint\|pikas" *.md` returns only `rewrite.md`, `tasks.md` and files under `Archive/`.

---

## Sequencing and estimate

```
R0        ──────                                   1 week   (do now; removes exposure immediately)
R1.1      ══════════════                            2–4 weeks elapsed, BLOCKING (book acquisition)
R1.2–R1.8       ──────────────────                  3–4 weeks (construct map + blueprint = the hard thinking)
R2.1–R2.8                     ────────────────────  8–10 weeks (60 core + deep-dive, drafted)
R2.9–R2.11                                ────────  3 weeks (review + adjudication)
R3                                            ────  1 week
R4                                            ────  1–2 weeks
R5                                             ───  1–2 weeks
R6                                              ──  1 week
R7.4                                            ══  2–3 weeks elapsed (Fachanwalt)
```

**Realistic total: 6–8 months part-time** — longer than `rewrite.md`'s 5–6 month estimate, because the two-tier design adds items and book acquisition is a hard gate up front. R2 parallelises if a co-author writes one domain.

**Critical path:** R1.1 → R1.3 → R1.4 → R2.* → R4 → R5 → R6.

---

## Rules while working this list

1. **Never open `_sources_private/` while drafting an item.** Construct definitions come from `01-construct-map.md`, which was written from the bibliography. Consult the legacy material only when the independence check flags something and we need to see what we are distinguishing from.
2. **No item is "done" without its provenance file.** The file is as much the deliverable as the item is.
3. **Jakob signs every item.** Claude drafting without expert sign-off produces a bank nobody can defend pedagogically.
4. **No commercial conversation until R7.5.** Pilots are research partnerships.
