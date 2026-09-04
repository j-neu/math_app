# Gauntlet Loop — agent operating prompt

**Use:** paste as the standing instruction for an agent finishing Numeris, or point an agent at this file.
**Governs:** `GAUNTLET_PROGRESS.md` (the evidence log), workstreams P5/P6 and the remaining `tasks.md` items.
**Last revised:** 2026-09-04, after a round that found four stale-derivation bugs in one sitting.

---

## 0. Prime directive

> **Evidence beats claims. A thing is done when a command says so, not when a document says so.**

You are finishing a live product used by real children in German primary schools. Two audiences depend on it being coherent: a 7-year-old who cannot debug your mistake, and a teacher who will make a Förderplan decision from what you render. Neither can tell the difference between "the code is wrong" and "the child cannot count."

Every claim you record must name **a command that was run, an artifact inspected, or a journey executed.** "Should work", "looks right", "the ledger says" are not evidence.

---

## 1. Non-negotiable constraints

Violating any of these fails the iteration regardless of what else you accomplished.

| # | Constraint | Why |
|---|---|---|
| 1 | **Never open `_sources_private/` while authoring content.** | It holds the protected iMINT/PIKAS material. The clean-room firewall (`docs/clean-room/00-charter.md`) is the product's legal basis. Consult it *only* when an independence check flags something and you must see what you are distinguishing from. |
| 2 | **German for every user-facing string**, child- and teacher-facing. No English leaks into the UI. | Non-negotiable product requirement. |
| 3 | **No commercial surface.** No pricing, no "kaufen", no invoice, no equivalence claims ("gleichwertig", "validiert", "ersetzt"). | The freeze holds until `tasks.md` R9.3. Permitted register: "auf Grundlage der Forschung von …", "orientiert an …". |
| 4 | **Never fabricate a sign-off, a reviewer, or an adjudication.** | `provenance.csv` exists to be handed to a Fachanwalt. A row claiming a review that did not happen poisons the one document meant to protect this project. |
| 5 | **Never delete an unchecked gate to make a checklist pass.** | Other documents compute off `tasks.md`. R9.3's test is "every checkbox above is checked" — deleting the unchecked ones lifts the commercial freeze by accident. Defer, retarget, or close with reasoning. Never silently remove. |
| 6 | **Never edit signed pedagogical content** (item wording, numbers, skill descriptions) without flagging it. | Typography fixes are fine and should be reported. Meaning changes require Jakob. |
| 7 | **Do not `git push` to `main` or deploy to production** unless explicitly told to this session. | `prozedia-portal` is git-connected to `main`. Feature branches are safe; `main` is a production deploy. |

---

## 2. The loop

Repeat until the stop condition in §6. One pass = one iteration. Record each in `GAUNTLET_PROGRESS.md`.

### Step 1 — Verify the ledger before trusting it

**Start every iteration by checking that the status documents are true.** They are routinely wrong in both directions.

Real incidents: `tasks.md` R2.9 sat unchecked for five days after it was complete (all 127 provenance rows signed). R2.11 was marked ready but its strict gate exited 1. A P1 ledger said "NOTHING DEPLOYED" while four functions were live.

Run the gates in §4 **first**, then reconcile the docs to what they report. Do not begin new work on top of an unverified ledger.

### Step 2 — Pick one workstream slice

Smallest slice that produces independently verifiable evidence. Prefer finishing a started thread over opening a new one. Current open scope:

- **P5** — art direction + engagement: child visual system, rewards, animation, `adhd guidelines.md` applied
- **P6** — publish hardening: Android tablet + Chrome (**not** iPad — the pilot is Android), perf, error handling, load, DSGVO placeholders in `impressum`/`datenschutz`, deploy
- **R6.4** — full-flow acceptance run on a real Android tablet; archive `docs/clean-room/acceptance/foerderplan-example.pdf`
- **R8.1 / R8.2** — practice-skill audit and framework-doc triage

### Step 3 — Build

Match surrounding code: its naming, its comment density, its idiom. Read the neighbours before you write.

### Step 4 — Run the invariant sweep (§3) and the gates (§4)

Not optional, not "if the change looked risky". The bugs in this repo are overwhelmingly *coupling* bugs — a change that was locally correct and globally inconsistent.

### Step 5 — Critique with fresh context

Dispatch a critic that **has not seen your reasoning** and **runs the actual product**, not the diff. The critic's job is to find what you rationalised past. Every critic round in this project's history found real defects, including a Critical, on code its builder believed was finished.

The critic reports findings by severity. You fix all of them or record an explicit ruling with reasoning. Then re-review.

### Step 6 — Record evidence

Append to `GAUNTLET_PROGRESS.md`: commands run with their output, bugs found, decisions with reasoning, and what remains open. Write the entry so a stranger can tell truth from optimism.

---

## 3. The invariant sweep — this repo's dominant bug class

**Numeris is a chain of derived artifacts. Nearly every serious bug found so far is a derived artifact that did not get rebuilt after its source changed.** Check these every iteration that touches content, schema or config.

| Source of truth | Derived artifact | Rebuild with | Verify with |
|---|---|---|---|
| `docs/clean-room/items/*.md` | `math_app/Research/diagnostic_{core,deepdive}_v1.csv` | `python scripts/generate_diagnostic_csv.py` | script self-checks; counts match `02-blueprint.md` |
| Those CSVs | live `diagnostic_questions` rows | a migration | REST query the live table and diff against the CSV |
| `docs/clean-room/skills/skills_taxonomy.csv` | `math_app/Research/skills_taxonomy.csv` | copy per R5.1 | `check_provenance.py --all` |
| `docs/clean-room/skills/specs/*.json` | `math_app/assets/skill_specs/` | `python scripts/sync_skill_specs.py` | `python scripts/check_specs.py` |
| item + skill files | `docs/clean-room/provenance.csv` | manual | `python scripts/check_provenance.py --all` |
| CSV row order | `*.adjudicated` sidecars | manual re-key | `check_item_independence.py --strict` |
| CSV as bundled asset | **deployed** `prozedia-app` bundle | `flutter build web --no-tree-shake-icons` + deploy | load the deployed URL, not localhost |
| `backend/supabase/functions/*` | **deployed** edge functions | `supabase functions deploy <name>` | `curl` the live function |

### Three rules that would have caught every one of these

1. **When you change a source, name its derived artifacts out loud and rebuild every one.** Do not stop at the first.
2. **A sidecar or reference keyed by position is a latent bug.** The A3.3-02 adjudication keyed on row index; removing an earlier row moved it 20 → 19 and the gate silently stopped covering the right item. Prefer stable IDs; if you cannot, document the re-key procedure *in the file*.
3. **The same datum rendered to two audiences from two stores will drift.** The child reads `prompt_de` from the bundled CSV; the teacher reads it from Postgres. 27 rows had drifted apart unnoticed. After any content change, diff every store that serves it.

### Deployment is part of the invariant, not a follow-up

A migration that renumbers questions while the deployed client still bundles the old numbering **actively corrupts data** — the client posts `question_number` and `diagnostic-results` resolves the UUID by it, so answers file against the wrong question. Schema and client ship together or the system is broken between them. If you cannot deploy both, say so loudly and state that the diagnostic must not be used until you can.

---

## 4. Gates

Green means every line passes. Record the actual numbers, not "all green".

```bash
# Flutter
cd math_app && flutter test          # expect: all pass (455+ at time of writing)
cd math_app && flutter analyze       # expect: 0 ERRORS (style lints are a moving baseline — count errors, not issues)

# Dashboard
cd dashboard && npx tsc --noEmit     # expect: exit 0

# Backend
cd backend && deno check supabase/functions/**/*.ts   # also: deno task check
# ✅ GREEN since 2026-09-04. The four errors recorded below were fixed in
# behavior-preserving fashion: the two `new Response(Uint8Array)` sites now copy
# into a plain ArrayBuffer (`new Uint8Array(bytes).buffer`), and the two loose
# casts in foerderplan-pdf were replaced by one typed boundary (SkillRow
# interface + type-guard filter). The error report also surfaced a real
# rendering defect — foerderplan-pdf recommendation rows always rendered gray
# because they coloured on the short category while DOMAIN_LABELS holds the full
# labels; they now colour by the skill's `domain` letter. Legacy rows (domain
# NULL) are unchanged. `backend/deno.json` (+ deno.lock) added so the gate is a
# canonical, reproducible command. History: d23d0ad recorded this gate clean on
# 2026-09-01; Deno 2.9.6 / TypeScript 6.0.3 then flagged 4 errors (two genuine
# TS lib drift, two loose casts). Deploy of the two fixed edge functions is
# Jakob's step (deployed binaries still ship the old code until redeployed).

# Clean-room integrity
python scripts/check_provenance.py --all
python scripts/check_item_independence.py --new math_app/Research/diagnostic_core_v1.csv --strict
python scripts/check_item_independence.py --new math_app/Research/diagnostic_deepdive_v1.csv --strict
python scripts/check_mapping.py
python scripts/check_specs.py
python scripts/check_skill_descriptions.py
```

**Verify independently of the tool that did the work.** A migration's own `RAISE NOTICE` is the migration's opinion. Query the live table afterwards and compare against the source file. A test suite that passes proves the tests pass.

---

## 5. Anti-patterns, each drawn from a real incident here

| Anti-pattern | What actually happened |
|---|---|
| Trusting a status doc | Ledger said "NOTHING DEPLOYED"; four functions were live and two migrations already applied. |
| Regenerating one derived artifact | CSV rebuilt for a count change; 27 prompts in it had *also* drifted, unnoticed for days. |
| Counting rows instead of reading the declared count | `diagnostic-results` counted all 92 question rows against a 59-item run, so sessions never auto-completed. |
| Assuming a comment is true | A code generator's comment said it excluded `L` from the alphabet. It did not. A pilot class got a code with a confusable and children could not log in. |
| Hardcoding an ID | Dashboard minted QR tickets against the retired legacy diagnostic for weeks. |
| Testing the wrong device | Acceptance spec said iPad Safari; the pilot runs Android tablets. |
| Shipping unreviewed generated text | Nine item files carried doubled spaces and mismatched quote marks from an edit pass, headed for children's screens. |
| Declaring done from the diff | Every fresh-context critic round that ran the real product found defects the builder believed were fixed. |

---

## 6. Stop conditions

**Stop and hand back when any of these is true:**

- The slice is complete, all gates green, a fresh-context critic found nothing, and evidence is recorded.
- You need a decision only Jakob can make: pedagogy, item meaning, commercial posture, or anything requiring a person outside this repo (external reviewers, the Fachanwalt).
- A production deploy is required and you were not authorised for it this session.
- You have looped three times on the same defect. Stop and write up what you tried and what you now believe is true — do not keep cycling.

**Never stop by:** lowering a threshold, deleting a failing test, marking an unfinished item complete, or removing a gate so a checklist passes.

---

## 7. Reporting

Report faithfully. If tests fail, show the output. If you skipped something, say so. If something is done and verified, state it plainly without hedging.

Lead with anything that makes the live system inconsistent — that outranks whatever you were asked to build.
