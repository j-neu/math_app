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
| Primary sources | **Core bibliography ordered (2026-08-29).** Item writing proceeds in parallel; chapter/page citations are filled in as copies arrive (R1.1). Open/official sources (KMK, Rahmenlehrplan BE/BB) supplement, they do not replace. |
| Test size & shape | **Two-tier.** ~60-item core diagnostic + optional per-domain deep-dive blocks a teacher can add. Own blueprint, own item counts, own sequencing. |
| Authoring | **Claude drafts, Jakob reviews every item.** The review is both the pedagogical check and the independence check; sign-off is recorded per item in the provenance log. |
| Schulz (151 Q, CC BY-ND) | **Dropped from product scope.** Archived out of the shipped tree. Revisit only with a direct written licence from LISUM/Schulz. |
| Practice engine (8 skills) | Stays paused **and** out of commercial scope. Audit deferred to Phase R8; not a launch blocker. |
| Final deliverable | A **filled-in Förderplan form** (Ist / Soll / Lernweg / Absprachen / Reflexion), generated from a session, downloadable from the dashboard. Layout: pending ADR 0001 — until the SenBJF licence is verified we ship **our own five-column layout** with the standard headings (already the R6.2 implementation; "no protected title or authority name anywhere in the document" is part of the R6.2 test). |

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
  **Status note (2026-08-29):** The Schulz *diagnostic* is fully removed (archived to `_sources_private/`, zero references to it in shipped code). The R7.1 "Wissenschaftliche Grundlagen" work later added legitimate §51 UrhG *book* citations — "Wartha & Schulz (2019)" in the PDF footers and "Wartha 2019" (Eintrag A2) in `skip_rules.dart`'s doc comment — which post-date and supersede the blanket grep in this test; they reference the scientific book, not the dropped instrument.

- [ ] **R0.7 — Verify the Förderplan form's licence and record the basis** ⏳ ADR raised, verification outstanding
  **Description:** The target form is watermarked *SenBildJugFam 2017*. Confirm in writing that reuse and redistribution inside a third-party product is permitted — check the source publication's terms, and if unclear send one email to SenBJF asking explicitly. If permission is not obtainable, fall back to our own form built on the standard headings (Ist / Soll / Lernweg / Absprachen / Reflexion), which are generic pedagogical vocabulary — only the specific layout would be protected.
  **Test (manual):** `docs/clean-room/decisions/0001-foerderplan-form-licence.md` exists and contains either the permitting clause verbatim with its source URL, or the sent enquiry with date plus a stated fallback decision.

- [x] **R0.8 — Decide and record the git-history position**
  **Description:** R0.2 removes files from the working tree but not from history. Decide: leave history intact (repo is private; history is evidence of good-faith development) or rewrite it. Recommendation: leave intact, document the reasoning.
  **Test (manual):** `docs/clean-room/decisions/0002-git-history.md` exists and states the decision and its reasoning.

---

## Phase R1 — Foundation

**Status:** R1.1 ✅ ordered. R1.2–R1.8 drafted and verified 2026-08-29 by subagents; items marked ✅ have their code/manual tests passed. Items with a **⏳ sign-off** note are drafts awaiting Jakob's pedagogical sign-off in the document header — they are NOT final until that happens.

- [x] **R1.1 — Acquire the core bibliography** (gate removed 2026-08-29: all four books ordered; item writing proceeds in parallel)
  **Description:** Obtain, in a form we can cite by chapter and page: Padberg/Benz *Didaktik der Arithmetik*; Wartha/Schulz *Rechenproblemen vorbeugen*; Selter/Spiegel *Wie Kinder rechnen*; Schipper *Handbuch für den Mathematikunterricht an Grundschulen*. Download now as free supplements: KMK Bildungsstandards Mathematik Primarstufe, Rahmenlehrplan Berlin-Brandenburg Teil C Mathematik, and the available Krajewski / Moser Opitz / Gaidoschik papers.
  **Test (manual):** `docs/clean-room/03-bibliography.md` lists each title with edition, year, ISBN and acquisition URLs. Every entry marked "in hand" or "downloaded" once the ordered copies arrive; until then the bibliography still records `to order` with the order placed.

- [x] **R1.2 — Write the bibliography document**
  **Description:** `docs/clean-room/03-bibliography.md` — full citations plus a one-paragraph note per source on what we use it for (construct definitions / difficulty rationale / strategy taxonomy / break-off reasoning). This later becomes the "Wissenschaftliche Grundlagen" page content.
  **Status:** Document written (every source has a stated purpose). Jakob confirms "no source appears that has not actually been read" before this is truly final.
  **Test (manual):** Every source has a stated purpose; no source appears that has not actually been read.

- [x] **R1.3 — Write the construct map** ⏳ sign-off
  **Description:** `docs/clean-room/01-construct-map.md` — Domains A–D with numbered constructs (A1.1 … D1.2), each with a definition in our own words and a citation to R1.2. Start from `rewrite.md` §4 as a draft, then verify each construct against the acquired literature and adjust. From here on, the map — not the old CSV — is the source of truth.
  **Status:** Draft complete (154 lines, 31 constructs, all cited, no forbidden names). `grep -i "imint\|pikas\|schulz"` → 0. Awaiting Jakob's sign-off in the header.
  **Test (manual):** Every construct has (a) a one-sentence definition, (b) at least one literature citation with chapter/page, (c) no citation to iMINT, PIKAS or Schulz. Jakob signs off in the document header.

- [x] **R1.4 — Write the two-tier blueprint** ⏳ sign-off
  **Description:** `docs/clean-room/02-blueprint.md` — the core 60-item test (items per construct with a rationale for each allocation) plus the optional deep-dive blocks (which domains get one, how many items each, when a teacher would add one). Include sequencing rules and difficulty-distribution targets. Item counts must be our editorial choice with stated reasoning, not a copy of any existing instrument's allocation.
  **Status:** Draft complete (103 lines). Core allocation sums to exactly 60; deep-dive blocks defined with entry criteria; §Break-off table written so an implementer can turn it into Dart. Awaiting Jakob's sign-off.
  **Test (manual):** Core item counts sum to 60; every allocation has a written rationale; an administration-time estimate is stated; deep-dive blocks are defined with entry criteria; cross-checked against R1.3 so no construct in the map is unmeasured in either tier.

- [x] **R1.5 — Derive the break-off / abbreviated rules independently**
  **Description:** The current skip-group logic lives in `math_app/lib/screens/diagnostic_screen.dart`. The mechanism is our code and stays; the *rules* get rederived from the published argument that failure at ZR20-with-Zehnerübergang predicts failure at ZR100. Document in `docs/clean-room/02-blueprint.md` §Break-off with citations.
  **Status:** Done. New `math_app/lib/services/skip_rules.dart` (5 rules keyed by construct IDs, Wartha 2019 rationale) + `math_app/test/skip_rules_test.dart`. `flutter test test/skip_rules_test.dart` → 4/4 passed. `diagnostic_screen.dart` untouched (wiring is R5.2).
  **Test (code):** A unit test in `math_app/test/` asserts the new skip table matches the documented rules for every construct, and that no skip rule references a legacy question number.

- [x] **R1.6 — Build the provenance infrastructure**
  **Description:** Create `docs/clean-room/` with `00-charter.md`, `items/`, `skills/`, `foerderplan/`, `decisions/`, plus `provenance.csv` (`artifact_id,type,author,created,sources_cited,reviewed_by,reviewed_on,independent_of`). Write `scripts/check_provenance.py`: fails if any item file lacks a required template field, or if any shipped item ID has no row in `provenance.csv`.
  **Status:** Done. `00-charter.md`, `provenance.csv` (header only), `items/TEMPLATE.md`, `skills/README.md`, `foerderplan/README.md`, `scripts/check_provenance.py` (+ `--all` and `<dir>` args). Real tree → `OK` exit 0; incomplete fixture → `FAIL` exit 1; complete fixture → `OK` exit 0. `provenance.csv` is empty by design until items exist.
  **Test (code):** `python scripts/check_provenance.py` exits non-zero on a deliberately incomplete fixture and zero on a complete one.

- [x] **R1.7 — Build the independence check**
  **Description:** `scripts/check_item_independence.py` — compares the new item bank against the archived legacy CSV (read from `_sources_private/`, never committed) and flags: identical operand pairs within the same construct, normalised prompt-wording overlap above a threshold, identical visual configurations (dot count *and* arrangement), and identical ordering runs. Output is a report, not a hard gate — Jakob adjudicates each flag.
  **Status:** Done. 329 flags for 92 items when run legacy-vs-itself (100% detection); 0 flags on a hand-made clean fixture; `--strict` exits 1 unadjudicated / 0 adjudicated. Note: the legacy CSV was copied to `_sources_private/` (gitignored) so the script's default `--legacy` path works; the `math_app/Research/` original is archived properly in R5.1.
  **Test (code):** Run with the current 92-item CSV as *both* inputs — must flag ~100% of items, proving detection works. Run against a hand-made clean fixture — must flag 0.

- [x] **R1.8 — Write decision records for the structural choices** ⏳ sign-off
  **Description:** `docs/clean-room/decisions/` — at minimum: why 60 core items, why the two-tier shape, why Domains A–D rather than the legacy five categories, why ~35 skills instead of 88, why Schulz is dropped.
  **Status:** Done. ADRs `0003`–`0007` written (provisional status), following the 0001/0002 layout, referencing the bibliography. Awaiting Jakob's confirmation.
  **Test (manual):** One ADR per decision, each stating context / decision / reasoning / date, referencing R1.2 sources where relevant.

---

## Phase R2 — Item bank (the bulk of the work)

Each drafting task: Claude writes the items **and** one `docs/clean-room/items/<ID>.md` provenance file per item using the `rewrite.md` §6 template. Each review task: Jakob approves, edits or rejects every item and signs its provenance row.

**Status (2026-08-29):** All 92 items drafted (60 core + 32 deep-dive) by parallel subagents and verified: `check_provenance.py` → OK/0; full-bank `check_item_independence.py` → 1 flag (A3.3-02, adjudicated via sidecar, strict OK/0); all 13 template fields present in every item file; core counts match the blueprint allocation (sum 60). **All drafting checkboxes below are marked done pending Jakob's R2.9 review — the items are DRAFTS, not signed off.**

- [x] **R2.1 — Draft Domain A1 items (Zählkompetenz)** ⏳ awaiting R2.9 sign-off
  **Description:** Items per the R1.4 allocation. Cover forward/backward counting from an arbitrary start, step-counting, Vorgänger/Nachfolger, Zehnerübergang. Numbers chosen deliberately away from the legacy set.
  **Status:** Done. 8 items (A1.1-01/02, A1.2-01/02, A1.3-01/02, A1.4-01, A1.5-01), starts spread across ZR20/ZR100 (12, 48, 21, 59, 26, 45, 37, 17). Independence → 0 flags.
  **Test (code):** `check_provenance.py` clean for all A1 IDs; `check_item_independence.py` reports zero unadjudicated flags for A1.

- [x] **R2.2 — Draft Domain A2 items (Anzahlerfassung)** ⏳ awaiting R2.9 sign-off
  **Description:** Subitizing and structured quantity recognition. Visual configurations must be newly designed and specified as explicit coordinates or a generation rule in the item file — not "like the old one but different". Prefer 10-frame / Rekenrek / finger patterns over the legacy dice configurations.
  **Status:** Done. 4 items (A2.1-01 Rekenrek-flash subitizing; A2.2-01/02 Zehnerfeld 5+1 + Fingerbild 5+3; A2.3-01 Zehnerfeld comparison 6 vs 8), explicit coordinate specs. Independence → 0 flags. No dice anywhere.
  **Test (code):** Provenance and independence clean for A2; every visual item file contains a complete specification of its arrangement.

- [x] **R2.3 — Draft Domain A3 items (Zahlzerlegung)** ⏳ awaiting R2.9 sign-off
  **Description:** Part-part-whole in ZR10, flexible decomposition, doubles and near-doubles relationships, tested in both directions (decompose and compose).
  **Status:** Done. 8 items (A3.1-01..03, A3.2-01..03, A3.3-01/02), both directions covered. Independence → 1 flag (A3.3-02: pair 4+5 forced by Nachbaraufgabe-to-double construct; adjudicated in sidecar with reasoning).
  **Test (code):** Provenance and independence clean for A3.

- [x] **R2.4 — Draft Domain B items (Stellenwertverständnis)** ⏳ awaiting R2.9 sign-off
  **Description:** B1 Bündelung/Entbündelung and B2 Zahldarstellung (Stellenwerttafel, Zahlenstrahl, non-standard forms). Replaces the legacy Stellenwerte block including its Zahlendiktat item — use a different auditory format, or drop audio from the core tier and place it in a deep-dive block.
  **Status:** Done. 8 items (B1.1-01, B1.2-01/02 Stäbchen 34/41, B1.3-01, B2.1-01/02 Tafel 47/60, B2.2-01 Zahlenstrahl 0–100, B2.3-01 "1 Z + 14 E"). No audio in the core tier — the auditory Zahlendiktat moved to Deep-Dive B (DDB-06). Independence → 0 flags.
  **Test (code):** Provenance and independence clean for B1 and B2.

- [x] **R2.5 — Draft Domain C1+C2 items (Grundaufgaben ZR10, Strategien ZR20)** ⏳ awaiting R2.9 sign-off
  **Description:** Automatised facts, doubles, halving, complements to 10; then Zehnerübergang in both operations. Response-time capture is part of the item spec wherever strategy inference is intended (cite Selter).
  **Status:** Done. 16 items (C1.1-01..04: 3+4, 6−6, 2+8, 10−4; C1.2-01/02; C1.3-01/02; C2.1-01..03: 7+6, 8+5, 9+7; C2.2-01/02; C2.3-01..03: 13−8, 12−9, 15−6). Reaktionszeiterfassung + Selter & Spiegel 1997 cited on all C2 items. Independence → 0 flags.
  **Test (code):** Provenance and independence clean for C1 and C2. The independence check needs particular attention here — operand collisions are most likely in this range.

- [x] **R2.6 — Draft Domain C3+C4 items (ZR100, flexibles Rechnen)** ⏳ awaiting R2.9 sign-off
  **Description:** Stellenweise / schrittweise / Hilfsaufgaben / Zerlegung, plus items designed to reveal strategy choice rather than correctness alone.
  **Status:** Done. 14 items (C3.1-01..03, C3.2-01..03, C3.3-01/02, C3.4-01/02, C4.1-01/02, C4.2-01/02), varied ZR100 operands. C4 items all carry "Aufgabe + Strategieabfrage ('Wie hast du gerechnet?') + Reaktionszeiterfassung". Independence → 0 flags (one C3.3-01 anchor re-anchored from 30+40 to 20+50 to avoid a collision).
  **Test (code):** Provenance and independence clean for C3 and C4.

- [x] **R2.7 — Draft Domain D items (Sachsituationen)** ⏳ awaiting R2.9 sign-off
  **Description:** Per the R1.4 allocation. Contexts must be original — no reused story scenarios.
  **Status:** Done. 2 items (D1.1-01 Schwimmbad 8+5 Bahnen; D1.2-01 Schulgarten 9+4 Bohnenpflanzen), original contexts. Independence → 0 flags.
  **Test (code):** Provenance and independence clean for D.

- [x] **R2.8 — Draft the optional deep-dive blocks** ⏳ awaiting R2.9 sign-off
  **Description:** One block per domain that warrants it, per R1.4. Same item template and provenance requirements as the core tier.
  **Status:** Done. 32 items (DDA-01..10 Zahlbegriff, DDB-01..06 Stellenwert incl. DDB-06 auditory Zahlendiktat in eigener Form, DDC-01..10 Rechenstrategien, DDD-01..06 Sachsituationen — original contexts distinct from core D). Entry criteria referenced from the blueprint in each item's rationale. Independence → 0 flags.
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

**Status (2026-08-29):** Done by subagent, verified. 36 skills derived from the construct map (31 constructs + 5 didactic splits). `check_skill_descriptions.py` → 0 shared 6-word runs vs legacy, exit 0. `check_provenance.py` (now covering items + skills) → OK/0. New CSV `docs/clean-room/skills/skills_taxonomy.csv` parses at 36 rows, header exactly per spec. **All drafting done; Jakob's sign-off outstanding before the catalog ships (R5).**

- [x] **R3.1 — Define the new skill set and ID scheme** ⏳ sign-off
  **Description:** Derive ~30–40 förderbare Skills from the construct map (R1.3). IDs follow the construct map (`A3.1`, `C2.2`), not the legacy `Z1`/`C1.1`/`counting_3` schemes. Drop `card_number` entirely — we ship no cards.
  **Status:** Done. 36 skills (A: 13, B: 6, C: 15, D: 2). Splits (suffixed a/b): A1.1, A1.2, C1.1, C3.1, C3.4. One file per skill in `docs/clean-room/skills/`. No legacy ID anywhere (`counting_|basic_strategy_|card_number|^[ZPSO]\d` → 0 hits).
  **Test (manual):** `docs/clean-room/skills/` holds one file per skill; every skill traces to at least one construct in R1.3; no legacy ID appears anywhere.

- [x] **R3.2 — Write all skill titles and descriptions** ⏳ sign-off
  **Description:** German and English title plus a 1–2 sentence description per skill, stating what the child *can do* rather than what activity teaches it. This is the highest-risk text in the catalog — legacy phrasing leaks here most easily.
  **Status:** Done. New `scripts/check_skill_descriptions.py` diffs every `description_de` against the legacy CSV; result "OK: no shared 6-word runs", exit 0. Note: when R5.1 swapped the runtime `math_app/Research/skills_taxonomy.csv` to the new taxonomy, the legacy 88-skill catalog was archived to `_sources_private/skills_taxonomy_legacy.csv` (recovered from git) and the checker's `--legacy` default re-pointed there, so the independence diff still compares against the true legacy text.
  **Test (code):** A script diffs every new `description_de` against the archived `skills_taxonomy.csv`; zero descriptions share a 6-word run with any legacy description.

- [x] **R3.3 — Produce the new `skills_taxonomy.csv`** ⏳ sign-off
  **Description:** Columns `skill_id, domain, construct_id, color, title_de, title_en, description_de, description_en`. No `card_number`.
  **Status:** Done at `docs/clean-room/skills/skills_taxonomy.csv` (36 rows; legacy `math_app/Research/skills_taxonomy.csv` left untouched — runtime swap is R5). `check_provenance.py` finds a provenance row (type=skill) for every skill_id; 36 skill files ↔ CSV ↔ provenance 1:1.
  **Test (code):** CSV parses; row count matches R3.1; `check_provenance.py` finds a provenance row for every `skill_id`.

---

## Phase R4 — Förderplan mapping

**Status (2026-08-29):** R4.1, R4.2, R4.3 all done and verified. `check_mapping.py` → 92 entries, all skill IDs valid, exit 0. Ordering rule documented + Dart implementation, 4/4 unit tests. Text templates rewritten in Dart + 2 TS ports; snapshot test 4/4; `flutter analyze` no new issues; `npx tsc --noEmit` clean.

- [x] **R4.1 — Build the if-wrong → recommend mapping** ⏳ sign-off
  **Description:** For every item in the new bank, decide independently which 1–3 skills a failure implies, with a written reasoning chain per item (likely cause → skill gap → priority order). The source is our own construct map plus the bibliography.
  **Status:** Done. `docs/clean-room/foerderplan/mapping-rationale.md` has 92 entries (one per item ID) in cause → gap → priority-skills → reasoning format. 41 items needed a/b-suffix resolution (unsuffixed construct IDs in item Maps-to-skills fields mapped to taxonomy suffix IDs, e.g. A1.1→A1.1a/A1.1b). New `scripts/check_mapping.py` → "92 Einträge, 92 Items, 36 Skill-IDs", exit 0. `check_provenance.py` still OK.
  **Test (code):** `docs/clean-room/foerderplan/mapping-rationale.md` has an entry per item ID; a script asserts every item maps to at least one skill and every mapped skill ID exists in R3.3.

- [x] **R4.2 — Define the recommendation ordering rule** ⏳ sign-off
  **Description:** Replace the legacy "category order → card_number ASC" ordering (card_number no longer exists). Define our own pedagogical sequencing rule and document its basis.
  **Status:** Done. Rule documented in `docs/clean-room/foerderplan/ordering-rule.md` (canonical 31-construct order from the construct map/blueprint, suffix tie-break, deterministic fallback, priority overrides within a construct only). Dart implementation `math_app/lib/services/skill_recommendation_order.dart` (`canonicalConstructOrder`, `compareRecommendations`, `sortSkillIds`). `flutter test test/skill_recommendation_order_test.dart` → 4/4 passed; analyze clean. Integration into the edge functions/Dart service is R4.3/R5.4.
  **Test (code):** A unit test feeds a fixture result set and asserts the recommended-skill order matches the documented rule.

- [x] **R4.3 — Rewrite the Ist / Soll / Lernweg text generation** ⏳ sign-off
  **Description:** `kurz_foerderplan_service.dart` and its TypeScript ports build the three columns from templates. Rewrite those templates against the new taxonomy and neutral wording — this completes R0.3 properly rather than merely deleting one string.
  **Status:** Done. `kurz_foerderplan_service.dart` rewritten: groups by Domäne A–D (skill-ID prefix `^[A-D]\d`, labels "Domäne A — Zahlbegriff" etc.), sorts skills within a domain via `sortSkillIds`, neutral Ist/Soll/Lernweg wording, graceful legacy fallback (non-matching IDs group by their own `category`, no crash on null stats). Mirrored into `foerderplan-kurz-pdf/index.ts` (domain colors A emerald / B blue / C red / D purple + legacy color fallback) and `foerderplan-kurz-docx/route.ts`. Models and `foerderplan-generate` data logic untouched (R5.4). Snapshot test `math_app/test/kurz_foerderplan_service_test.dart` → 4/4 (no legacy category names, no Karte, no protected title; A–D order; legacy fallback). `flutter analyze` no new issues; `npx tsc --noEmit` clean.
  **Test (code):** A snapshot test renders a fixture Förderplan and asserts the Ist/Soll/Lernweg text contains no legacy category name, no card reference and no protected title.

---

## Phase R5 — Migration into the running system

**Status (2026-08-29):** R5.1 done and verified. R5.2 (visual items) in progress. R5.3/R5.4 queued.

- [x] **R5.1 — New diagnostic CSV**
  **Description:** Produce `math_app/Research/diagnostic_core_v1.csv` from the item bank, with deep-dive blocks either flagged by tier in the same file or in a sibling file. Archive the legacy `MathApp_Diagnostic_with_skills.csv` to `_sources_private/`.
  **Status:** Done. `scripts/generate_diagnostic_csv.py` (stdlib, idempotent, self-checking) produces `math_app/Research/diagnostic_core_v1.csv` (60 core, ListNumber 1–60 in blueprint order) + sibling `diagnostic_deepdive_v1.csv` (32). Legacy CSV archived to `_sources_private/`. `DiagnosticService` now loads the new core CSV (pure `loadQuestionsFromCsv` added); `SkillCatalog`/`SkillCatalogEntry` moved to the new taxonomy (domain/construct_id/color; `cardNumber` gone) with the runtime `math_app/Research/skills_taxonomy.csv` updated from the clean-room catalog; `diagnostic_report_generator.dart` uses `sortSkillIds` (R4.2) and domain labels. 17 visual items marked `Image` keyed by item ID for R5.2; DDB-06 auditory = Text (teacher-read, no audio). `flutter test` 18/18 green (new `diagnostic_service_test.dart` 5/5: 60 core / 32 deep-dive / all IfWrong skills resolve / non-empty fields / visual ID keys); `flutter analyze` at the pre-existing 323-lint baseline.
  **Test (code):** `DiagnosticService` loads the new CSV; a test asserts the parsed question count equals the blueprint count and that every `IfWrong` skill ID resolves in the new `SkillCatalog`.

- [x] **R5.2 — Regenerate the visual items in Flutter**
  **Description:** `diagnostic_screen.dart` hardcodes dot arrangements keyed by legacy filename (`case 'img1936.jpg': // 7 dots: 3 top, 3 middle, 1 centre bottom`). Replace with the arrangements specified in the R2.2/R2.4 item files, keyed by new item IDs. Delete `math_app/Research/DiagnosticPictures/` and the filename-based switch.
  **Status:** Done. New `buildVisualDisplay` in `diagnostic_screen.dart` keyed by item ID renders all 17 visual items per their item-file specs (Zehnerfeld, Rekenrek incl. 800 ms flash, Fingerbild, Stäbchen incl. interactive open-bundle, Stellenwerttafel, Zahlenstrahl via CustomPaint). Legacy `_buildQ21Display`/`_buildQ48Display`/`_widgetForImage`/`_buildImageWidget`/`_buildScatteredDienesDisplay`/`_showZoomedImage` and the `img*.jpg` switch deleted. `grep -r "img[0-9]" math_app/lib` → 0. `flutter test` 36/36 (incl. new `visual_display_test.dart` 18/18); analyze at baseline; `flutter build web` OK. `Research/DiagnosticPictures/` already absent.
  **Test (code):** `grep -r "img[0-9]" math_app/lib` returns nothing; `flutter analyze` clean. **Test (manual):** run the diagnostic and confirm every visual item renders the arrangement its item file specifies.

- [x] **R5.3 — Database migration and reseed**
  **Description:** A migration that inserts the new bank and taxonomy as a *new* `diagnostics` row (new slug, version 1) rather than editing the existing one, so old pilot sessions stay readable. Decide and document what happens to existing sessions.
  **Status:** Done. `backend/supabase/migrations/20260829000000_cleanroom_v1_bank.sql` — new diagnostic `cleanroom-v1` (uuid …002; legacy `imint-grundschule-zr20` …001 untouched, so old pilot sessions keep rendering). 36 new skills inserted (card_number=0, `domain`/`construct_id` columns added with backfill; legacy 87 untouched → 123 total). 60 core + 32 deep-dive questions (92 rows; `question_number` 1–60 core, 61–92 deep-dive, explicit `tier` column). `question_count=60`, version 1. **`supabase db push` APPLIED to the live project**; integrity query confirmed every `if_wrong_practice_skills` entry resolves in the new skills.
  **Test (code):** `supabase db push` succeeds; a query confirms the new diagnostic's question count and that every `if_wrong_practice_skills` entry exists in `skills`. **Test (manual):** an existing pilot session still renders its Förderplan without error.

- [x] **R5.4 — Update edge functions and dashboard for the new taxonomy**
  **Description:** `foerderplan-generate`, `foerderplan-pdf`, `foerderplan-kurz-pdf`, the docx route and the dashboard's category displays all assume the five legacy categories. Move them to Domains A–D.
  **Status:** Done. `foerderplan-generate`: `CATEGORY_ORDER`/`card_number` sort replaced with a TS port of the R4.2 `canonicalConstructOrder` comparator; recommendations carry the domain label (A–D from the `domain` column, skill-id-prefix fallback, legacy `category` fallback); `category_stats` keyed by domain label. `foerderplan-kurz-pdf` + `foerderplan-pdf`: domain colors (A emerald / B blue / C red / D purple + gray fallback), "Kategorie-Übersicht" → "Domänen-Übersicht", `card_number` dropped. Dashboard Förderplan page + class legend moved to the domain scheme. `npx tsc --noEmit` clean. Grep for the five legacy category names + `Kategorie` → 0 (the only "Zählen" hits are the intended "zählend statt denkend" slow-response note from R0.3/R4.3).
  **Test (manual):** Deploy to a preview and run the Phase D verification smoke test (`phase1_school_platform.md` §Verification, steps 1–12) end to end.

---

## Phase R6 — The deliverable: a filled-in Förderplan

**Status (2026-08-29):** R6.1 + R6.2 done and verified. R6.3/R6.4 are manual/deploy steps queued. Note: R6.2's own acceptance test ("no protected title or authority name anywhere in the document") means we build OUR OWN five-column layout with standard headings — the ADR 0001 fallback, safe under either licence outcome.

- [x] **R6.1 — Map our output onto the form's five columns**
  **Description:** The form is Ist (Beobachtung/Bedarf) · Soll (Ziele) · Lernweg (Päd. Angebote/Maßnahmen) · Absprachen (Wer?, Wie?, Mit wem?, Bis wann?) · Reflexion/Evaluation/Modifikation. We currently generate three of these. Decide what fills Absprachen und Reflexion — generated defaults, teacher-editable fields, or deliberately blank for handwriting — and document it.
  **Status:** Done. `docs/clean-room/foerderplan/form-mapping.md`: Ist/Soll/Lernweg auto-filled (sources: `_buildIst/_buildSoll/_buildLernweg` + TS port); **Absprachen** deliberately blank for handwriting (context-dependent teacher agreements, not derivable from diagnostic data — generated defaults would be pedagogically indefensible); **Reflexion/Evaluation/Modifikation** deliberately blank for handwriting (post-Förderzeitraum classroom review); **page 2** blank (Weitere Vereinbarungen + signatures). Header: name from student display_name, "von" from session started_at, "bis" no schema field → blank. No protected title/authority in output.
  **Test (manual):** `docs/clean-room/foerderplan/form-mapping.md` states, per column, what fills it and from what data.

- [x] **R6.2 — Generate the filled form (page 1)**
  **Description:** Render the Förderplan into the form layout: header (`für ___ für die Zeit von ___ bis ___` filled from student and session dates), five columns populated per R6.1. Page 2 (Weitere Vereinbarungen plus signature lines) rendered blank for handwriting.
  **Status:** Done. Dart `pdf_kurz_foerderplan_service.dart`: header now pre-fills student name from `plan.studentName` and "von" from `plan.sessionDate` (dd.MM.yyyy), "bis" blank; five-column table (Ist/Soll/Lernweg filled, Absprachen/Reflexion fillable); page 2 with "Weitere Vereinbarungen" + signature lines labelled "Unterschrift Lehrkraft" / "Unterschrift Eltern/Erziehungsberechtigte". TS port `foerderplan-kurz-pdf/index.ts` mirrors (name from `students.display_name`, "von" from session `started_at`). Own five-column layout, no SenBJF/authority string. New `pdf_kurz_foerderplan_service_test.dart` 2/2 (PDF magic, structure; `pdf` 3.11.3 has no text-extraction API so no text-level assertion). `flutter test` 38/38; `flutter analyze` baseline; `npx tsc --noEmit` clean; grep for SenBJF/iMINT/PIKAS/Schulz → 0.
  **Test (manual):** Complete a diagnostic as a test student, download the Förderplan, and confirm: name and date range filled; all five columns populated or intentionally blank per R6.1; page 2 present with signature lines; text fits its cells without overflow at A4 landscape; no protected title or authority name anywhere in the document.

- [x] **R6.3 — Dashboard download wired and labelled**
  **Description:** One clear German button on the Förderplan page producing the filled form, with the neutral filename from R0.4.
  **Status:** Done. Buttons already present ("Förderplan (PDF)" / "Förderplan (Word)" + "Als PDF exportieren"). Fixed the download filenames: `foerderplan-kurz-pdf/route.ts` and `foerderplan-pdf/route.ts` now resolve the student display_name (session → students lookup) and send `Foerderplan_<Name>.pdf` / `.docx` with whitespace/illegal-char sanitization and a `Foerderplan.pdf` fallback. `npx tsc --noEmit` clean; grep `filename="Foerderplan.pdf"` (generic) → 0; `SenBJF` in dashboard → 0.
  **Test (manual):** From a fresh teacher login: open a completed session → one click → the correct PDF downloads with the expected filename. Same for the Word variant if kept.

- [ ] **R6.4 — Full-flow acceptance test**
  **Description:** The end-to-end proof: teacher creates a class → student ticket → child completes the new 60-item diagnostic in the browser → teacher opens the Förderplan → downloads the filled form.
  **Test (manual):** Complete the whole flow on the deployed preview on a real device (iPad Safari), and archive the resulting PDF as `docs/clean-room/acceptance/foerderplan-example.pdf` as the reference output.

---

## Phase R7 — Legal and marketing close-out

**Status (2026-08-29):** R7.1 done + verified. R7.2 code-test half done (grep clean) — manual landing-page read pending. R7.3–R7.5 gated on Jakob's sign-offs and the Fachanwalt (manual).

- [x] **R7.1 — "Wissenschaftliche Grundlagen" page**
  **Description:** A page in the dashboard, plus a line in the PDF footer, listing the bibliography from R1.2. Standard academic citation, protective under §51 UrhG.
  **Status:** Done. New `dashboard/app/wissenschaftliche-grundlagen/page.tsx` (sections A/B/C per `03-bibliography.md`, `Author (Year). Title. Place: Publisher.` format, links for online sources), footer link added in `dashboard/app/layout.tsx`. PDF footers: `foerderplan-pdf/index.ts` (last page) and `foerderplan-kurz-pdf/index.ts` (pages 1–2) carry "Wissenschaftliche Grundlagen: Padberg & Benz (2021); Wartha & Schulz (2019)" at 7 pt. `npx tsc --noEmit` clean; `next build` succeeded (15/15 pages). Grep iMINT/PIKAS/SenBJF/LISUM in page+layout+edge functions → 0 (Wartha & Schulz appear only as bibliographic authors of the A2 book — a §51 citation, not the dropped diagnostic).
  **Test (manual):** Page reachable from the dashboard footer; content matches `03-bibliography.md`; German throughout.

- [ ] **R7.2 — Marketing copy review against UWG §5**
  **Description:** Sweep every user-facing string, the landing page and any pilot-school communication for named authorities implying endorsement, protected work titles, and equivalence claims ("gleichwertig", "validiert", "ersetzt"). The permitted register is "auf Grundlage der Forschung von …", "orientiert an …".
  **Status:** Code-test half done 2026-08-29: `grep -rniE "imint|pikas|senbjf|lisum|denkenden rechnen|gleichwertig|validiert" dashboard math_app/lib` → 0 hits. **Manual half pending:** Jakob reads the landing page and confirms no equivalence claim remains.
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
R1.1      ──────────────                            ordered 2026-08-29; arrival does not block R1.2+
R1.2–R1.8       ──────────────────                  3–4 weeks (construct map + blueprint = the hard thinking)
R2.1–R2.8                     ────────────────────  8–10 weeks (60 core + deep-dive, drafted)
R2.9–R2.11                                ────────  3 weeks (review + adjudication)
R3                                            ────  1 week
R4                                            ────  1–2 weeks
R5                                             ───  1–2 weeks
R6                                              ──  1 week
R7.4                                            ══  2–3 weeks elapsed (Fachanwalt)
```

**Realistic total: 6–8 months part-time** — longer than `rewrite.md`'s 5–6 month estimate, because the two-tier design adds items. R2 parallelises if a co-author writes one domain.

**Critical path:** R1.3 → R1.4 → R2.* → R4 → R5 → R6.

---

## Rules while working this list

1. **Never open `_sources_private/` while drafting an item.** Construct definitions come from `01-construct-map.md`, which was written from the bibliography. Consult the legacy material only when the independence check flags something and we need to see what we are distinguishing from.
2. **No item is "done" without its provenance file.** The file is as much the deliverable as the item is.
3. **Jakob signs every item.** Claude drafting without expert sign-off produces a bank nobody can defend pedagogically.
4. **No commercial conversation until R7.5.** Pilots are research partnerships.
