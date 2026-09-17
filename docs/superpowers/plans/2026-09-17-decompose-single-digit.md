# decompose_single_digit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `decompose_single_digit` (BUILD_ORDER.md Batch 1.7, construct `decompose`) playable — pure spec-authoring, zero new Dart code. The existing generic `drag_partition` template (`math_app/lib/practice/problem_generators.dart:1069`, widget `math_app/lib/widgets/templates/drag_partition_widget.dart`, evaluator `_evaluateDragPartition`) already implements exactly "split a target number into two parts, tap counters into two labelled bowls, any valid split accepted" via its `split_constraint: "sum"` mode — this is a template that already exists but had no real spec using it yet this session (only test fixtures did).

**Architecture:** One skill spec, 3 levels, all `template: "drag_partition"` with `parts: 2`, `split_constraint: "sum"`, and a `total_range` that gets harder per level. `_generateDragPartition`/`_dragPartitionBoxes` (unmodified) sample a target `total` from `total_range` and a canonical example split, but the child's submission is judged semantically — `_evaluateDragPartition` accepts ANY two positive integers summing to `total`, not just the generator's own example split. `expected` is empty (`const []`), matching the existing `bundling` semantic-evaluation precedent.

**Tech Stack:** Flutter/Dart (`math_app/`), the existing, fully-built `drag_partition` generator/widget/evaluator (all unmodified), the v4 skill-spec JSON pipeline, Python sync/coverage scripts.

**Spec:** `docs/clean-room/v4/skills/BUILD_ORDER.md` Batch 1.7 (line 53) + `docs/superpowers/specs/2026-09-15-exercise-plan-design.md` lines 212-217 (verbatim: "Manipulative: Part-whole splitting tool (two-hand / two-bowl metaphor)"; "Levels: 1) Target 2-5 -> 2) Target 6-9"; "Example: Split 7 into two parts.") + `docs/skill_spec_authoring_guide.md`. Precedent: `docs/superpowers/plans/2026-09-17-count-forward-zr20-zr100.md` (the first "zero-new-code, existing generic template" plan this session) — this one is the first to reuse `drag_partition` specifically, and the first to reuse a template whose evaluation is semantic (any-valid-split) rather than exact-string-match.

## Global Constraints

- German UI only.
- `total_range` per level must keep every possible sampled `total` a genuine single digit (`[2, 9]`, per the skill's own name and the design doc's "Zerlegung einstelliger Zahlen (2-9)" title) — `_dragPartitionBoxes`'s `'sum'` branch only guarantees `totalHi >= parts` (2), not an upper single-digit bound, so the spec author must keep `total_range` within `[2, 9]` by construction.
- `error_taxonomy` is `other` alone: `drag_partition`'s `expected` is always empty (`problem.expected.length == 1` is false), so `miscount` can never fire; `wrong_direction` only fires for `numberline_step`; no other candidate code applies.
- Never hand-edit `math_app/assets/skill_specs/*.json`.
- `domain` is `"A"` (Zahlbegriff, "Decomposition and completion" subsection, `docs/superpowers/specs/2026-09-15-exercise-plan-design.md:76,210`).
- `problem_count: 8` / `mastery.correct_of: 8` per level.
- `box_labels` must have exactly `parts` entries (enforced by the existing generator, `problem_generators.dart:1083-1088`) — `["Schale 1", "Schale 2"]` for `parts: 2`.

---

## Task 1: decompose_single_digit spec JSON + tests

**Files:**
- Create: `docs/clean-room/v4/skills/specs/decompose_single_digit.json`
- Test: `math_app/test/skill_spec_store_test.dart`, `math_app/test/problem_generators_test.dart`

**Interfaces:**
- Consumes: `_generateDragPartition`/`_dragPartitionBoxes` (unchanged), `DragPartitionWidget` (unchanged), `_evaluateDragPartition` (unchanged).
- Produces: skill id `decompose_single_digit`, construct `decompose`, domain `A`; 3 levels whose `template` is `"drag_partition"`.

- [x] **Step 1: Write the spec JSON.** L1 `total_range: [2, 5]` ("Target 2-5," easy). L2 `total_range: [6, 9]` ("Target 6-9," harder). L3 `total_range: [2, 9]` (full single-digit range — the fluency/review tier the design doc's own 2-level split doesn't name but every prior batch this session has added to map onto the v4 schema's mandatory 3 EIS levels). All 3 levels: `parts: 2`, `box_labels: ["Schale 1", "Schale 2"]`, `split_constraint: "sum"`.
- [x] **Step 2: Add the store test** asserting `constructId == 'decompose'`, `domain == 'A'`, and all 3 levels' `template == 'drag_partition'`.
- [x] **Step 3: Add the generator test** using `_realSpec('decompose_single_digit')`, iterating all 3 levels x 100 seeds: `p.template == 'drag_partition'`, `total` within that level's expected range, `boxes` has exactly 2 positive entries summing to `total`, and `p.expected` is empty (semantic evaluation, matching the `bundling`/`unbundling` tests' existing assertion style for semantically-evaluated templates).
- [x] **Step 4: Run** `flutter test test/skill_spec_store_test.dart test/problem_generators_test.dart` — PASS. Store: 23/23 (up from 22). Generator: 206/206 (up from 205).
- [x] **Step 5: Commit** — `feat(decompose_single_digit): add v4 skill spec using the existing drag_partition template`.

---

## Task 2: Sync, coverage, BUILD_ORDER, full suite

**Files:**
- Modify: `math_app/assets/skill_specs/decompose_single_digit.json` (generated)
- Modify: `docs/clean-room/v4/skills/BUILD_ORDER.md`

- [x] **Step 1: Sync** — `synced 19 skill specs ... (1 copied, 18 unchanged)`.
- [x] **Step 2: Coverage check** — `covered: 19/93`.
- [x] **Step 3: Update BUILD_ORDER.md** — check off Batch 1.7's line, add to `## Done`, correct the trailing count to "these nineteen."
- [ ] **Step 4: Run the full Flutter test suite** — expect PASS.
- [ ] **Step 5: Run `flutter analyze`** — expect no new issues beyond the 341 baseline (this task touches only JSON and test files).
- [ ] **Step 6: Commit** — `chore(decompose_single_digit): sync spec assets, mark Batch 1.7 done in BUILD_ORDER`.

---

## Self-Review Notes

- **Spec coverage:** `decompose_single_digit` fully covered. Authoring guide step 2 (generic-template-first check) succeeded on the first candidate this time — `drag_partition` was already flagged as a strong match during the Batch 1.5 (`order_cards`) research pass, where it was correctly ruled out for *that* skill (decomposition, not ordering) but noted as "the right shape for a future decomposition skill" — this plan is that skill.
- **Placeholder scan:** none.
- **Type consistency:** `p.display['total']`/`['boxes']` read with the same `as int`/`(as List).cast<int>()` style the existing `bundling`/`unbundling` tests already use for `drag_partition`-adjacent semantic-evaluation templates.
- **First semantic-evaluation real spec:** every real spec shipped so far this session (`double_zr10` through `place_on_numberline_zr100`) used exact string-match evaluation (`expected` non-empty). This is the first to use `drag_partition`'s semantic (`expected: []`) evaluation path with a real spec, confirming that path works end-to-end, not just in test fixtures.
