# Project Status

**⛔⛔ 2026-09-12 — Clean-room content strategy abandoned by decision (Jakob). Reverting to the
pre-rewrite iMINT/PIKAS-based diagnostic and skill catalog as the base.** Both the v1 clean-room
rewrite and the v2 Deckungsmatrix rebuild (banner below, "Active #1") produced diagnostics judged
worse than the original. New direction: `_sources_private/MathApp_Diagnostic_with_skills.csv` (92
questions) and `_sources_private/skills_taxonomy_legacy.csv` (88 skills) — both untouched since
they were archived out of the shipped tree in R0.2 — become the base again. Process: one skill per
diagnostic-card question (fine-grained — forward counting ≠ backward counting ≠ skip-counting
forward ≠ skip-counting backward, etc.) → cross-check against the exercise Kartei for skills
practiced but never diagnosed → complete skill list → fresh item wording per skill (different
numbers, one simple sentence, no revealed procedure, a real single-answer field — the same wording
bar already written up in `docs/clean-room/v2/wortlaut-review-core.md`, now retargeted at this
skill list instead of the v2 construct map). **Legal/copyright considerations are explicitly and
completely set aside for this work, on Jakob's direct instruction — `rewrite.md` is now a
historical record, not an active constraint** (see the banner at the top of that file). The
non-commercial posture is a separate, still-open question, not automatically resolved by this.
Superseded by this banner: everything below that describes the clean-room v1/v2 effort as the
active content plan (kept for history, not as current direction) — see `tasks.md` for the matching
banner on that side.

**Last updated:** 2026-09-17 (exercise-plan-foundation merged to `main`: the v4 practice pipeline
works end-to-end, 2/93 skills playable (`double_zr10`, `halve_zr10`), coverage checker + authoring
guide + 91-skill build-order backlog all in place — see Active #1)

**Previously:** 2026-09-13 (v4 content reversion executed: 108-item `diagnostic_v4_master.csv` and
93-skill taxonomy wired in, clean-room v1/v2 retired from the runtime — see the banner above)

**Superseded entries below**, kept for history only: 2026-09-08 (v2 Konstruktkarte/Blueprint) and
2026-09-07 (v2 Deckungsmatrix). The entire v2 Deckungsmatrix effort they describe was abandoned
2026-09-12 (top banner) and replaced by the v4 reversion (banner above this line) — nothing in the
two entries below is current.

**🔴 Historical: `cleanroom-v1` was rejected 2026-09-07** for real pedagogical gaps (Verdoppeln/Halbieren missing in ZR20/ZR100, procedure-revealing ZR100 items, "zählendes Rechnen" never directly measured — findings in [docs/clean-room/00-v1-assessment.md](docs/clean-room/00-v1-assessment.md)). The v2 Deckungsmatrix rebuild that followed is *also* dead (2026-09-12 top banner). Both are superseded by the v4 legacy reversion — see the "2026-09-13" section above for what's actually live.

**Gauntlet loop CLOSED by decision 2026-09-06.** The Numeris Gauntlet and its child-development (§3a) gate loop are closed; the project is back to human-in-the-loop development and **no automatic next round will run**. All §3a rounds, fixes, and the final gate numbers are recorded in the closing entry of [GAUNTLET_PROGRESS.md](Archive/GAUNTLET_PROGRESS.md) ("Gauntlet closed (decision) — handoff to human-in-the-loop development"). Standing handoff: every task starts from an explicit human request; no commit/push/deploy and no production data change (including throwaway fixtures) without explicit authorization; the open items listed in the P1–P4 bullet below (R6.4 device run, F5, P5 art nits, the unwired `bundling` widget) are ordinary product/QA tasks awaiting human instruction, not loop iterations.

One-screen view of what's shipped, what's active, and what's paused. For the doc map, see [DOCS_INDEX.md](DOCS_INDEX.md). For the active plan, see [phase1_school_platform.md](phase1_school_platform.md).

---

## ⚖️ Rechtlicher Status — Clean-Room Rewrite abandoned by decision (2026-09-12)

**The clean-room content strategy (`rewrite.md`, `tasks.md` R0–R9, and the v2 Deckungsmatrix
rebuild) is no longer being executed.** Jakob's decision, 2026-09-12: content is rebuilt on top of
the original iMINT/PIKAS-derived diagnostic and skill catalog again, with fresh item wording —
legal/copyright considerations explicitly and completely disregarded for that work, on direct
instruction. `rewrite.md` is kept as a historical record of the legal reasoning, not an active
constraint. See the banner at the top of this file for the new plan.

**The non-commercial posture (free, school-internal, research-partnership use only — no pricing
conversations, no invoices, no sales) stays in force by default**, because this decision was about
*where content comes from*, not about *whether/when to sell*. Nobody has decided to lift it; it
just no longer has the R7.5-Fachanwalt-opinion gate it used to have, since that gate belonged to a
plan that's no longer running. Treat "can we charge for this yet" as its own open question, to be
asked explicitly, not inferred from this decision.

Everything below is still accurate about the **infrastructure**. Content sections describing the
clean-room v1/v2 effort as the *active* plan are historical — see the top banner and `tasks.md`.

---

## ✅ 2026-09-13 — the v4 reversion above was actually executed, not just decided

The 2026-09-12 banner above describes a *decision*. It was carried out over the following days:

- **2026-09-13, `content(v4): wire full legacy-derived diagnostic bank, retire clean-room v1/v2`.**
  Every iMINT/PIKAS-derived category (Zählen, Zahlzerlegung, Stellenwerte, Grundstrategien,
  Kombinierte Strategien, plus the small PIKAS-only categories) reviewed and wired into
  `DiagnosticScreen`, consolidated into `math_app/Research/diagnostic_v4_master.csv` (108 items,
  Jakob-reviewed and reordered), which `DiagnosticService` now serves exclusively.
  `diagnostic_core_v1.csv` and the v2 item-quality-fix CSV are deleted; the six per-category v3 CSVs
  stay on disk as unit-test fixtures only. `skill_catalog` rebuilt from the same taxonomy (93 skills,
  `math_app/Research/skills_taxonomy.csv`), `ACTIVE_DIAG_ID` repointed, items reordered into their
  pedagogical families (`a2659d6`, 2026-09-14).
- **2026-09-15/17, `docs/superpowers/plans/2026-09-15-exercise-plan-foundation.md`.** The diagnostic
  above is content-complete, but every one of the 93 diagnosed skills routed a child to "keine
  Aufgaben vorhanden" — the practice/exercise layer behind it didn't exist yet for the new taxonomy.
  This plan built the pipeline and proved the authoring pattern on 2 skills: `double_zr10` (retarget
  an existing widget onto its v4 id) and `halve_zr10` (author 3 new interactive widgets from
  scratch). **Merged to `main` 2026-09-17** (`da4393b`, full suite 562/562 green). Ships:
  `scripts/check_skill_spec_coverage.py` (one command reports which of the 93 skills are playable —
  currently 2/93), `docs/skill_spec_authoring_guide.md` (the checklist for authoring the next one),
  and `docs/clean-room/v4/skills/BUILD_ORDER.md` (all 91 remaining skills classified and batched by
  archetype tier and shared manipulative, ready to slice into follow-on plans).
- **What this makes true now:** `tasks.md` (R0–R9), the v2 Deckungsmatrix tree under
  `docs/clean-room/v2/`, and `docs/clean-room/00-v1-assessment.md` are **fully historical** — nothing
  in them describes the live content anymore. The current content authority is
  `math_app/Research/diagnostic_v4_master.csv` (108 items) and `skills_taxonomy.csv` (93 skills); the
  current practice-authoring authority is `docs/skill_spec_authoring_guide.md` +
  `docs/superpowers/specs/2026-09-15-exercise-plan-design.md` §5 + `BUILD_ORDER.md`. See
  `DOCS_INDEX.md`'s "Start here" for the full current doc set.

---

## Shipped

- **Diagnostic + Förderplan flow** (Phase 0, 2026-05-15). `SkillCatalog`, `SkillRecommendation`/`Foerderplan` models, `DiagnosticReportGenerator`, native German `DiagnosticReportScreen`, German `PdfReportService`, diagnostic CSV fixes, full UI polish (Q21 dice / Q38 audio / Q46 dice / image zoom / autofocus / Enter-nav / digit-only / drag-anywhere reorder).
- **Full German UI** (Phase 0.5). Locale infra in `main.dart`, ~90 widget files translated, platform names switched to `Numeris`, `flutter analyze` clean.
- **Diagnostic instrument.** 92-question CSV, ordered Zählen → Zahlzerlegung → Stellenwerte → Grundstrategien → Kombinierte Strategien. **Replaced 2026-08-29 by the clean-room item bank** (`tasks.md` R5.1): 60 core + 32 deep-dive items in `math_app/Research/diagnostic_core_v1.csv` / `diagnostic_deepdive_v1.csv`, built from the construct map (Domains A–D), with the new 36-skill taxonomy. Legacy CSV archived to `_sources_private/`. The Schulz CSV was dropped from product scope on 2026-08-29 (`tasks.md` R0.6) and moved to `_sources_private/`; the two instruments must never be mixed in reports — see [memory: project-two-diagnostics](../../.claude/projects/c--Users-jakob-StudioProjects-Math-App/memory/project_two_diagnostics.md).
- **Clean-room rewrite foundation** (2026-08-29, `tasks.md` R1–R7). Construct map (`01-construct-map.md`, 31 constructs A1.1–D1.2), two-tier blueprint (`02-blueprint.md`, 60 core + deep-dive), bibliography (`03-bibliography.md`), ADRs `0001`–`0007`, item bank (92 items with provenance), skill catalog (36 skills), break-off rules (`skip_rules.dart`), ordering rule (`skill_recommendation_order.dart`), item→skill mapping (`mapping-rationale.md`), form mapping (`form-mapping.md`). Provenance/independence/mapping checker scripts in `scripts/`. **Migrated into the running system**: new diagnostic CSV, visual items regenerated by item ID, `cleanroom-v1` diagnostic row + 36 skills + 92 questions applied to the live Supabase project (`20260829000000_cleanroom_v1_bank.sql`), edge functions + dashboard on Domains A–D, "Wissenschaftliche Grundlagen" page, neutral `Foerderplan_<Name>.pdf` filenames. **All 38 Flutter tests, 4 Python checkers, and dashboard typecheck green.**
- **Supabase EU backend** (Phase A, 2026-05-17). Project ref `zzxqeqwffexythqzjkxr` (Frankfurt). 9-table schema with RLS, seeded with 87 skills + diagnostic questions. Edge functions: `diagnostic-sessions`, `diagnostic-results`, `foerderplan-generate`, `foerderplan-pdf`, `delete-school-data`. Storage bucket `pdf-cache`. Smoke-tested end-to-end.
- **Teacher dashboard** (Phase B, 2026-05-17). Next.js 14 + Supabase SSR + Tailwind at `dashboard/`. Login, Klassen-Übersicht, Klasse-Detail with QR ticket generation, Förderplan-Ansicht (brief + category + full + detail-table + PDF export), Aggregate class table.
- **Flutter Web student client** (Phase C, 2026-05-17). `go_router`, `ApiService`, `/s/:ticket` route, `WebDiagnosticEntryScreen`, `DiagnosticCompleteScreen` (no Förderplan on kid screen). Deployed to Vercel `fra1` as `prozedia-app`.
- **Pilot polish** (Phase D, ~80%). DSGVO pages (`/datenschutz`, `/impressum`), CookieBanner, footer in dashboard layout, `delete-school-data` edge function (right-to-erasure with cascade), audio moved to Supabase Storage.
- **Phase D.5 blockers fixed** (2026-05-20 → 2026-05-22). Diagnostic resume across browser close, Q47 audio, Förderplan lazy-generation on view, full 98-question web build, bulk QR PDF for a class, short-URL school login (slug + 4-char short code, no ticket expiry).
- **Phase 1.1 fixes** (2026-05-23). All 11 issues deployed: Q39/Q40 deleted, doubling/halving question content fixed, Q48 dice, Förderplan race condition, session force-complete, retry-wrong-questions ticket, abbreviated-mode toggle (server-driven), historical-sessions page per student, Kurzförderplan PDF + Word. Plus: `leer`/`übersprungen` status labels in detail table, `school_code_entry_screen` wired to full ticket flags. Deployed: 3 edge functions, Flutter web rebuild, dashboard via git push.
- **Vercel deployments.** `prozedia-portal` (git-connected to `main`) and `prozedia-app` (git-connected since 2026-09-05, auto-builds via a downloaded Flutter SDK). See [memory: reference-vercel](../../.claude/projects/c--Users-jakob-StudioProjects-Math-App/memory/reference_vercel.md). **2026-09-05 routing regression found + fixed:** git auto-deploys (project `rootDirectory = math_app`) ignored `math_app/web/vercel.json`, so every deep link on the child client (`/s/<ticket>` = QR-ticket destination, `/lernen/<slug>` = school login) returned a Vercel 404 from the first git build (~6h). Root-level `math_app/vercel.json` (commit `86646a9`) restores the catch-all rewrite; deep routes re-verified **200** on the production alias.
- **Adaptive learning path + practice runtime** (Gauntlet P1–P4, 2026-08-30 → 2026-09-01; verified 2026-09-05 — this was previously missing from this document entirely). A second major feature alongside the diagnostic: child login/roster (`student-auth`), a per-student adaptive **Lernpfad** generated from the Förderplan (`learning-path`), a **practice runtime** with 16 interactive problem templates (`practice-session`, `math_app/lib/practice/`), 36 skill specs with generated problems (`docs/clean-room/skills/specs/`), and a teacher console to activate/reorder/unlock/reset a student's path (`dashboard/app/dashboard/lernpfade/`). Routes are live: `/lernpfad`, `/lernen/:slug` (child), `/dashboard/lernpfade` (teacher). All 9 edge functions deployed and re-verified 2026-09-04/05.
  - Each workstream (P1 path engine, P2 practice runtime, P3 skill specs, P4 teacher console) went through an independent critic → fixes → re-review cycle, then a full integration critic ran three live end-to-end journeys and found **one Critical bug** (a teacher could add a skill to a path that has no child-facing content, handing the child a dead-end screen) — found and fixed same day (2026-09-01), verified live.
  - Re-verified fresh 2026-09-05: `flutter test` 496/496, `dashboard: npx tsc --noEmit` clean, `backend: deno check` clean on all 9 functions, no drift since the 2026-09-01 fixes.
  - **One spec bug found and fixed 2026-09-05**, missed by the original process: skill `A1.2b` level 2 ("Rückwärts über die Zehnergrenze") had a numeric range where one of its four possible starting numbers (54) never actually crossed the ten's-boundary the level claims to teach. A prior review round had already flagged this exact defect on a sibling skill and fixed it; a later, unrelated "reduce duplicate problems" pass silently re-widened the range and reintroduced it — nobody re-checked the interaction. Fixed by lengthening the sequence (5→6 numbers) so every valid start now crosses the boundary, matching the already-reviewed pattern used on `A1.1b`. **Committed (`ffe6a9a`) and deployed 2026-09-05:** the production `prozedia-app` asset now serves `length: 6` (curl-verified on the live alias).
  - **§3a child-development gate first run (2026-09-05, A1.2b Stufe 2):** age band stated (7–8, Klasse 2; remedial to ~10) and a fresh-context critic briefed as that child played the live practice flow at 390×844 and 800×1280 (vision-capable model, real app against the live backend on a throwaway fixture). Verdict: **playable alone; no Critical**; all tap targets ≥44px, sequence numbers large and countable. **Findings → shipped 2026-09-05:** the confirmed duplicate-instruction defect (instruction card + a second caption under the manipulatives) was fixed — each practice template now renders the instruction exactly once, in the PracticeScreen card (equation_solve, equation_gap, sequence_gap, compare_symbols, strategy_choice, word_problem) — and after a wrong answer "Nochmal" is now the emphasised filled button while "Weiter" (skip the recorded error) is a secondary TextButton, removing the equal-weight ambiguity. Both verified by widget tests and a live 390×844 re-run. The critic's two "Important" claims were verified against code/tests: praise on a correct answer **does** render (`_CorrectFeedback`, 1.2 s, asserted in `practice_screen_test.dart` — the live sampler missed transient canvas text), and wrong answers not gating progression is the deliberate one-attempt/low-pressure design. **Physical-device step NOT run (no Android tablet; skipped by decision) — the §3a gate is not fully closed at this round's end** *(the loop has since closed by decision 2026-09-06 — see header; this device run became R6.4, a human task)*; detail in `Archive/GAUNTLET_PROGRESS.md`.
  - **§3a child-development gate second run (2026-09-06, A1.2b Stufe 1 enaktiv Zahlenstrahl tap-line — never child-gated before):** a fresh-context child critic found the level unplayable alone (ticks 8.2 px apart at 390 vs the 44 px floor, the starting number never shown, wrong taps silent, "Weiter" enabling after one tick). **Fix ruled by Jakob (tap-anywhere stepping) and implemented locally** in the shared `numberline_step` template: a large current-number read-out + marker starting at the problem's start, one tap anywhere in the counting direction steps exactly one number (no precision needed), wrong-direction taps get an immediate non-punitive cue, and "Weiter" unlocks only when the full run reaches the target. Widget-tested (497/497, analyze 0/336) and re-reviewed by a second child-persona critic: **playable alone at 390×844 and 800×1280**, 8/8 runs server-correct. **PUSHED + LIVE-VERIFIED 2026-09-06** (`e84f92f`; auto-deploy `prozedia-q4knv271j` → production alias): a live 8-problem session on the deployed client recorded every answer as the exact expected run (`was_correct: true`); the redesign strings are in the served bundle. The **physical-device step still not run at this round's end** — the §3a gate stayed open *(loop since closed by decision 2026-09-06 — see header; this device run became R6.4, a human task)*; detail in `Archive/GAUNTLET_PROGRESS.md`.
  - **§3a child-development gate third run (2026-09-06, B1.1 Stufe 1 `bundle_sticks` — the Stäbchen family that already produced a confirmed §3a defect on the diagnostic, never child-gated in the practice runtime):** age band 7–8 (Klasse 2, ZR 12–39). **Confirmed finding (verified against code AND live server records, not just a critic claim):** the grader accepts *any* Z/E split with `10·Z + E == count`, and the widget reports the split live after every tap, so **one tap on any loose stick (e.g. "1 Zehner, 29 Einer" for 39 sticks) was recorded `was_correct: true`** on the live project — a child can "master" the level 8/8 by tapping once per problem, never bundling all tens (the skill the level exists to exercise). Same class as the tap-line's C4 finding but worse: partial work is *praised*, not merely submittable. **Fixed and shipped 2026-09-06** (mirror of the accepted numberline_step gate): `practice_screen._canSubmit` now also requires `bundle_sticks` to report the canonical fully-bundled split (`expected`); 2 new screen tests assert a single partial bundle keeps "Weiter" disabled and only the full split submits. Re-verified on a local build against the live backend: partial "1 Zehner, 15 Einer" (count 25) keeps "Weiter" disabled, canonical "2 Zehner, 5 Einer" unlocks it, and a full 8/8 session recorded every answer as the exact canonical split. **PUSHED + LIVE-VERIFIED 2026-09-06** (`52b9a9d`; auto-deploy `prozedia-of8nuyxg7` → production alias): on the deployed client a one-tap partial ("1 Zehner, 19 Einer" for 29 sticks) keeps "Weiter" disabled and only the canonical "2 Zehner, 9 Einer" submits (`was_correct: true`). The **physical-device step still not run at this round's end** — the §3a gate stayed open *(loop since closed by decision 2026-09-06 — see header; this device run became R6.4, a human task)*; detail in `Archive/GAUNTLET_PROGRESS.md`.
  - **Loop closed — the residuals below are now ordinary tasks, not an automatic round.** The §3a child-development gate loop is closed by decision 2026-09-06 (see header). What remains is human-in-the-loop work: **P5** (art direction/engagement — `adhd guidelines.md` applied to this feature specifically) and **P6** (publish hardening — perf, load, error handling) have not started. **No physical-device test has ever been run on this feature** — every §3a round used desktop-emulated browser viewports (390×844 / 800×1280), never a real Android tablet, unlike the diagnostic which at least has R6.4 scheduled for one. Three dedicated §3a child-development passes ran (2026-09-05 Stufe 2; 2026-09-06 Stufe 1; 2026-09-06 B1.1 Stufe 1) and are recorded in `Archive/GAUNTLET_PROGRESS.md`; their residual child-facing nits (tick/label legibility on dense lines, the target number not labelled on the line, the "Lege" representation pill; whether 5 px-wide loose Stäbchen are visually countable at 390; the unwired custom `bundling` widget's partial-bundle mechanic) sit in the P5 backlog and wait for an explicit human request — no loop will pick them up automatically.
  - **F5 (dangling sessions), decided 2026-09-05:** a diagnostic/practice session left open by a closed tab must stay resumable, so it can't be auto-marked abandoned on close. Jakob decided: timeout-based cleanup — a server-side job marks a session `abandoned` after N days of no activity. **Not yet implemented** — this is a queued backlog item (server-side scheduled job + migration), not a live deploy.

## Active

Work in flight or queued in priority order.

**1. Practice pipeline for the v4 taxonomy (since 2026-09-15, highest priority).** The v4 diagnostic
(93 skills, `math_app/Research/skills_taxonomy.csv`) has been content-complete and live since
2026-09-13, but until 2026-09-17 every diagnosed skill routed a child to "keine Aufgaben vorhanden"
— the practice/exercise layer behind the diagnostic didn't exist for the new taxonomy at all.
**`docs/superpowers/plans/2026-09-15-exercise-plan-foundation.md` closed that gap and merged to
`main` 2026-09-17** (`da4393b`, full suite 562/562 green): the v4 skill-spec source tree is wired
into the existing sync pipeline, `scripts/check_skill_spec_coverage.py` turns "which skills are
playable" into one command (currently **2/93**: `double_zr10`, `halve_zr10`), and two authoring
patterns are proven and documented in `docs/skill_spec_authoring_guide.md` — "port an old exercise's
widget onto its v4 id" (`double_zr10`, cheap) and "build new interactive widgets from scratch"
(`halve_zr10`, three new widgets, went through two real defect-and-fix rounds before merge — see the
plan's own ledger, since deleted, or the branch's commit history for the fix reasoning).

**As next:** `docs/clean-room/v4/skills/BUILD_ORDER.md` orders the remaining 91 skills into batches
by archetype tier (Reused → Extended → New-widget-exists → New-from-scratch) and shared manipulative,
sized so each batch becomes its own follow-on plan (`writing-plans`, against the authoring guide +
`docs/superpowers/specs/2026-09-15-exercise-plan-design.md` §5, executed via
`subagent-driven-development` the same way this one was). No batch has been picked yet.

**Diagnostic usability rework — CLOSED, superseded by the v4 content reversion.** This item (2026-09-05
onward) was interaction-layer fixes to the old `cleanroom-v1`/v2 diagnostic: Workstream A (prompt
rendering, quote-stripping, Rekenrek flash timing, sort widget wiring, box-scaled timeouts, Hilfetext
channel) shipped and merged 2026-09-05 and survives in the code today — `DiagnosticScreen` and its
interaction layer are content-agnostic, so those fixes apply equally to the v4 diagnostic that now
runs through them. Workstreams B/C/D (item revision, integrity gates, migration) targeted the v1/v2
item banks specifically and are moot now that `diagnostic_v4_master.csv` replaced them outright
(2026-09-13). No on-device smoke test of the interaction layer has ever been run (no Android tablet
available in any session to date) — that gap is real but now belongs to whichever pilot-readiness
task picks it up next, not to this closed item.

**Learning path / practice runtime (P5/P6, not started).** P1–P4 (see Shipped) are built, reviewed, and live — and this is the exact runtime (`SkillSpec`, `PracticeController`, `template_registry`, `template_evaluator`) that Active #1's exercise-plan-foundation work authors new v4 skill specs against; it's infrastructure, not something the content reversion replaced. P5 (art direction/engagement) and P6 (publish hardening: perf, load, error handling, physical-device testing) haven't been scheduled. F5 (dangling session rows) has a decision (timeout-based cleanup) but no implementation yet — queued backlog item, not urgent.

The items below are **manual sign-off / deploy / legal / pilot** backlog, independent of the content
workstream above (see `tasks.md` for the full status per checkbox — `tasks.md` itself is fully
historical for content, but Phase R9's legal items and the Impressum/Datenschutz placeholders are
still real open work, tracked there):

1. ~~**Jakob sign-offs**~~ — **DONE.** R2.9 completed 2026-08-30 (all 127 provenance rows carry `reviewed_by=Jakob`); R1.3/R1.4/R1.8, R3.1–R3.3, R4.1–R4.3, R6.1/R6.2, ordering-rule, form-mapping and ADRs 0003–0007/0009 signed off 2026-09-04. Mechanical gates R2.11 and R7.3 both pass. **59-vs-60 delta fully resolved 2026-09-05** — runtime CSV regenerated to 59 + independence sidecar re-keyed (`20`→`19`) on 2026-09-04, and the two live migrations were verified ALREADY APPLIED: live `cleanroom-v1` reports `question_count=59`, and a live REST query shows 59 core (gapless 1–59) + 32 deep-dive (gapless 60–91) + A1.5-01 retired at 900, with **0 content mismatches** against the runtime CSV (see the prompt-quote note below). (STATUS previously claimed the live row still said 60 and the migrations were pending — stale; corrected this session.)
2. ~~**Apply the 59-vs-60 migrations to live**~~ — **DONE, verified 2026-09-04/05.** `20260904000000_cleanroom_v1_core_59.sql` (retire A1.5-01, renumber core 1–59 / deep-dive 60–91) and `20260904000001_cleanroom_v1_sync_prompts.sql` (27 drifted `prompt_de` rows) are both listed as applied on the live project (`supabase migration list`), and the live data matches (see item 1). *Prompt-quote residual from Workstream-A Task 2:* the runtime CSV strips the item files' wrapping quote marks, but the live `prompt_de` column still carried them on all rows (quote-only drift, 0 content drift). **CLOSED 2026-09-05** — the live column was stripped (all 92 cleanroom rows; migration `20260905000000_cleanroom_v1_strip_prompt_quotes.sql` retained for repo/fresh-environment consistency), and a live REST diff now shows **0 mismatches** against the signed core and deep-dive CSVs. Child client and teacher dashboard now render identical prompt text.
3. **R6.4 full-flow acceptance test** — deploy the preview and run the whole teacher→student→Förderplan flow on an **Android tablet in Chrome** (device corrected 2026-09-04; the pilot is Android, not iPad); archive the reference PDF at `docs/clean-room/acceptance/foerderplan-example.pdf`. The 59-vs-60 delta is resolved, so the reference PDF will not be stale on arrival. **No device was available on 2026-09-05** — the §3a physical-device step was skipped by decision (Jakob) and remains the open part of that gate; R6.4 stays scheduled for when a tablet is at hand.
4. **R5.4/R6 manual deploy — deploy halves already live; only the acceptance smoke remains.** The deploy step itself is done: the three edge functions (`foerderplan-generate`, `foerderplan-kurz-pdf`, `foerderplan-pdf`) were batch-deployed 2026-09-04 20:44 UTC — *after* their last code change (`611e41d`, 20:33 UTC) — so the live binaries ship the R5.4 domain-taxonomy and row-colour fixes (all 9 functions ACTIVE, verified via `supabase functions list` 2026-09-05). The dashboard (`wissenschaftliche-grundlagen` page, domain-based category views) auto-deploys from `main` since 2026-09-04; `/wissenschaftliche-grundlagen` verified live (200, bibliography content) 2026-09-05. Remaining: re-run the Phase D verification smoke test (`phase1_school_platform.md` steps 1–12) — an acceptance run, not a deploy.
5. ~~R7.2 / R7.3 / R0.7~~ — **all closed 2026-09-04.** R7.2 both halves signed; R7.3 gate passes; R0.7 closed via ADR 0001 outcome (b) — we ship our own five-column layout, so no SenBJF licence is needed.
6. ~~R7.4 Fachanwalt / R7.5 lift the freeze~~ — **moved to `tasks.md` Phase R9**, deferred until the build is production-ready. Neither blocks build work. The non-commercial posture stays in force meanwhile.
7. **Fill legal placeholders** in `dashboard/app/impressum/page.tsx` and `dashboard/app/datenschutz/page.tsx` (`[NAME/ADRESSE/EMAIL]`).
10. **AVV/DPA signature** with Supabase (`supabase.com/legal/dpa`) and with each pilot school before data processing.
11. **One-page German teacher onboarding document.**
12. **Cross-browser smoke** of the Flutter web client — **Android Chrome is the primary target** (pilot devices); Firefox and iPad Safari best-effort. Deferred to pilot day-1 unless something specific surfaces sooner.
13. **Phase E pilot scheduling** — real classroom at one or two schools once items 2–4 land.
14. ~~Schulz diagnostic integration~~ — **dropped** 2026-08-29 (`tasks.md` R0.6). CC BY-ND; revisit only with a direct licence from LISUM/Schulz.

## Paused / retired

**Nicht mehr pausiert, jetzt real im Code:** die handgebaute Übungs-Engine. Die Rückkehr war zunächst
nur im (inzwischen verworfenen) v2-Entwurf §6 vorgesehen; `exercise-plan-foundation` (Active #1) hat
sie tatsächlich gebaut — mehrstufige, manipulativ-basierte `custom_widget`-Skills (bisher
`double_zr10`, `halve_zr10`), angebunden an die bestehende Server-Schicht des Lernpfads. Damit sind
auch ihre Steuerungsdokumente **wieder in Kraft**:

- `DIFFICULTY_CURVE.md`
- `COMPLETION_CRITERIA.md`
- `EXERCISE_DESIGN_SYSTEM.md`
- `COMMON_PITFALLS.md`
- `REWARDS_SYSTEM_QUICK_REF.md` / `math_app/Research/REWARDS_SYSTEM.md`
- `adhd guidelines.md`

**Stattdessen abgelöst:** das Inhaltsmodell des Gauntlets — 36 JSON-Specs × 3 Stufen × 8 generierte
Aufgaben aus 16 generischen Templates. Die Templates selbst überleben als wiederverwendbare Widgets in
handgebauten Stufen (insbesondere der tap-anywhere `numberline_step` und das `bundle_sticks`-Gate aus den
§3a-Runden); als Curriculum-Generator sind sie abgelöst.

**Weiterhin offen, aber ohne Priorität:** `practice_skill_plan.md` (Skill zur Automatisierung der
Übungserstellung, drei Blocker). Die alte Aufgabenliste der Übungs-Engine liegt in
`Archive/tasks_2026-05.md`.

## Quick start

```bash
# Flutter app (single-device dev mode)
cd math_app && flutter pub get && flutter run

# Flutter web build (then deploy from build/web/)
cd math_app && flutter build web --no-tree-shake-icons

# Teacher dashboard
cd dashboard && npm install && npm run dev   # http://localhost:3000

# Supabase backend
cd backend && supabase db push
cd backend && supabase functions deploy <name>
```

For credentials and deployment commands, see the memory references linked above.
