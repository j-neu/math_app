# place_on_numberline_zr20 + place_on_numberline_zr100 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `place_on_numberline_zr20` and `place_on_numberline_zr100` (BUILD_ORDER.md Batch 1.6, construct `place_on_numberline`) playable — a new custom widget, but one that needs zero new painting/geometry code: `ScaledNumberLinePainter` (already used by `numberline_step`/`numberline_locate`, `math_app/lib/widgets/templates/numberline_common.dart`) already supports a `highlighted: Set<int>` field for rendering multiple simultaneous marks, and `snappedValueForX`/`numberLineTicks`/`numberLineLabels` already exist. BUILD_ORDER names `ZahlenstrahlPainter` (`manipulatives/zahlenstrahl.dart`, diagnostic-only, hardcoded to a 0-100 scale) as the reuse target, but `ScaledNumberLinePainter` is the correct choice here: it's the practice engine's own generalized version of the same painter, already proven at both ZR20 and ZR100 scale, so using it (rather than adapting the diagnostic-only, fixed-scale painter) keeps this skill consistent with its siblings.

**Architecture:** A new `numberline_place` custom_widget, generic over `range`, `value_range`, and `values_count` (reused unchanged across both skills' 3 levels each — 6 level configs total, only the params differ). `_generateNumberlinePlace` samples `values_count` distinct interior points, using the exact same clamp-to-interior logic `numberline_locate`'s generator already established. `expected` is a single comma-joined string of the targets in generated order — correct because every chip's only correct position is its own value, so a fully-correct placement is literally `targets.join(',')`. `NumberlinePlaceWidget` shows the targets as tappable chips (auto-advancing through them in order, but any unplaced chip can be tapped to re-target the next placement) and a single number line; each tap on the line snaps to the nearest tick and adds that position to the `highlighted` set. Correctness reuses `_evaluateCustomWidget`'s existing default (`_evaluateStringMatch`) — no new evaluator code.

**Tech Stack:** Flutter/Dart (`math_app/`), `numberline_common.dart`'s existing `ScaledNumberLinePainter`/`snappedValueForX`/`numberLineTicks`/`numberLineLabels` (all reused, unmodified), the v4 skill-spec JSON pipeline, Python sync/coverage scripts.

**Spec:** `docs/clean-room/v4/skills/BUILD_ORDER.md` Batch 1.6 (lines 49-50) + `docs/superpowers/specs/2026-09-15-exercise-plan-design.md` lines 198-208 (verbatim: "Levels: 1) 3 numbers placed -> 2) 5 numbers placed" for zr20; "Levels: 1) 3 numbers -> 2) 5 numbers, closer together" for zr100; examples "Place 4, 11, 18 on a 0-20 line" / "Place 23, 67, 89 on a 0-100 line."). Precedent: `docs/superpowers/plans/2026-09-17-skip2-zr100.md` (the last "wrap existing infrastructure in a new custom_widget" plan) and the `numberline_locate` generator/widget this plan's generator and widget both closely mirror.

## Global Constraints

- German UI only.
- `place_on_numberline_zr20`: every target stays in the interior of `[0, 20]` (i.e. `[1, 19]`). `place_on_numberline_zr100`: interior of `[0, 100]` (`[1, 99]`) — matching `numberline_locate`'s existing "never an endpoint" rule (an edge target would be indistinguishable from the line's own boundary).
- `error_taxonomy` is `other` alone — `miscount`'s off-by-one check parses `expected.single` as an int, which fails for a comma-joined multi-value string (same reasoning as `order_cards`), and no other candidate code applies to a `custom_widget` problem here.
- Never hand-edit `math_app/assets/skill_specs/*.json`.
- `domain` is `"A"` (Zahlbegriff, "Ordering & placing numbers" subsection, same as `order_cards_zr20`).
- `problem_count: 8` / `mastery.correct_of: 8` per level. Difficulty progresses from 3 widely-spread targets -> 5 widely-spread targets -> 5 targets confined to a narrow band (the "closer together" tier both design-doc entries call for at their hardest level), not from range width.
- Chip touch targets are `48x48`, above the 44x44px floor.

---

## Task 1: The `numberline_place` generator

**Files:**
- Modify: `math_app/lib/models/skill_spec.dart` (`kKnownCustomWidgets`), `math_app/lib/practice/problem_generators.dart` (`_generateCustomWidget` switch + new `_generateNumberlinePlace`)
- Test: `math_app/test/problem_generators_test.dart`

**Interfaces:**
- Consumes: `LevelSpec.intParam`/`intListParam`, `SeededGenerator.nextInt` via the existing `_shuffledCopy` helper (added for `order_cards`, reused here unchanged).
- Produces: registry key `numberline_place`; `Problem.display == {'custom_widget': 'numberline_place', 'range': [lo, hi], 'targets': List<int>}`; `Problem.expected == [targets.join(',')]`.

- [x] **Step 1: Add the registry key.**
- [x] **Step 2: Write the failing generator tests** (distinct interior targets matching `value_range`, `expected == targets.join(',')`; `values_count` exceeding the interior span is a spec error) — confirmed FAIL with `unknown registry key "numberline_place"`.
- [x] **Step 3: Write `_generateNumberlinePlace`** — same `range`/`value_range` clamp-to-interior shape as `_generateNumberlineLocate` (`lo = max(vLo, rangeLo+1)`, `hi = min(vHi, rangeHi-1)`), but samples `values_count` distinct values via `_shuffledCopy(candidates, gen).sublist(0, valuesCount)` instead of `numberline_locate`'s single `nextIntInRange`.
- [x] **Step 4: Run the generator tests — PASS** (2/2), full `problem_generators_test.dart` — PASS (180/180 at this point), no regressions.
- [x] **Step 5: Commit** — `feat(numberline_place): add the numberline_place generator`.

---

## Task 2: The `NumberlinePlaceWidget`

**Files:**
- Create: `math_app/lib/widgets/templates/numberline_place_widget.dart`
- Modify: `math_app/lib/practice/template_registry.dart` (import + switch)
- Test: `math_app/test/template_widgets_test.dart`

**Interfaces:**
- Consumes: `Problem.display['range']`/`['targets']` (from Task 1), `ScaledNumberLinePainter`/`snappedValueForX`/`numberLineTicks`/`numberLineLabels` (`numberline_common.dart`, unmodified).
- Produces: the standard custom-widget contract.

- [x] **Step 1: Write the failing widget tests** (renders a chip per target; tapping the line places the auto-selected chip in generated order, reporting `""` until every chip is placed then the joined result; tapping a specific unplaced chip re-targets the next placement; a new problem resets) using the same `pointFor(tester, value, lo, hi)` tap-coordinate helper `NumberlineLocateWidget`'s existing tests use, with a new key `numberline-place-line` (mirroring `numberline-locate-line`) and per-chip keys `np-chip-$value`. Confirmed FAIL (`Method not found: 'NumberlinePlaceWidget'`) before implementation.
- [x] **Step 2: Write `NumberlinePlaceWidget`** — `_placed` is a `List<int?>` index-aligned to `display.targets` (not to placement order), so the reported string (`_placed.join(',')`) equals `targets.join(',')` exactly when every chip lands on its own value, regardless of which order the child placed them in. Placed chips are removed from the selectable row (mirroring `order_cards`' "cards leave the source row" precedent) and shown only as highlighted dots on the line via `ScaledNumberLinePainter`'s existing `highlighted` set — no per-mark `CustomPaint` stacking needed.
- [x] **Step 3: Wire into `template_registry.dart`.** Run the widget tests — PASS (4/4) on the first attempt. `flutter analyze` on the 4 touched files — no issues. Full `template_widgets_test.dart` — PASS (125/125), no regressions.
- [x] **Step 4: Commit** — `feat(numberline_place): add the NumberlinePlaceWidget`.

---

## Task 3: Both spec JSONs + real-spec tests

**Files:**
- Create: `docs/clean-room/v4/skills/specs/place_on_numberline_zr20.json`, `place_on_numberline_zr100.json`
- Test: `math_app/test/skill_spec_store_test.dart`, `math_app/test/problem_generators_test.dart`

- [x] **Step 1: Write both spec JSONs.** Both skills share the same 3-level shape: L1 `values_count:3`, `value_range` spanning nearly the whole line (`[1,19]` / `[1,99]`); L2 `values_count:5`, same wide `value_range`; L3 `values_count:5`, `value_range` narrowed to a band (`[7,15]` for ZR20 — 9 interior candidates for 5 distinct targets; `[40,60]` for ZR100 — 21 candidates) so the "5 numbers, closer together" hardest tier both design-doc entries specify is real, not just nominal.
- [x] **Step 2: Add store tests** for both, asserting `constructId`, `domain`, and all 3 levels' `customWidget == 'numberline_place'`.
- [x] **Step 3: Add a parametrized generator test** (`for (final id in [...])`) covering both real specs at all 3 levels x 100 seeds: correct target count per level, distinctness, interior-of-range bounds (read from each level's own `params['range']`, not hardcoded, so the same test body correctly checks both `[0,20]` and `[0,100]`), and `expected == targets.join(',')`.
- [x] **Step 4: Run** `flutter test test/skill_spec_store_test.dart test/problem_generators_test.dart` — PASS. Store: 22/22 (up from 18... actually 20, +2 for this task). Generator: 182/182 (up from 180).
- [x] **Step 5: Commit** — `feat(place_on_numberline_zr20,place_on_numberline_zr100): add v4 skill specs using the new numberline_place widget`.

---

## Task 4: Sync, coverage, BUILD_ORDER, full suite

**Files:**
- Modify: `math_app/assets/skill_specs/place_on_numberline_zr20.json`, `place_on_numberline_zr100.json` (generated)
- Modify: `docs/clean-room/v4/skills/BUILD_ORDER.md`

- [x] **Step 1: Sync** — `synced 18 skill specs ... (2 copied, 16 unchanged)`.
- [x] **Step 2: Coverage check** — `covered: 18/93`.
- [x] **Step 3: Update BUILD_ORDER.md** — check off both Batch 1.6 lines, add both to `## Done`, correct the trailing count to "these eighteen."
- [ ] **Step 4: Run the full Flutter test suite** — expect PASS.
- [ ] **Step 5: Run `flutter analyze`** — expect no new issues beyond the 341 baseline.
- [ ] **Step 6: Commit** — `chore(place_on_numberline): sync spec assets, mark Batch 1.6 done in BUILD_ORDER`.

---

## Self-Review Notes

- **Spec coverage:** both Batch 1.6 skills fully covered across 4 tasks. Authoring guide step 2 (generic-template-first check) surfaced that the *named* manipulative (`ZahlenstrahlPainter`) wasn't actually the right reuse target — its practice-engine-generalized sibling (`ScaledNumberLinePainter`) was, a more subtle version of the same "check what actually exists" discipline than a flat "does a template already cover this" yes/no.
- **Placeholder scan:** none.
- **Type consistency:** `Problem.display['targets']` is `List<int>`, read as `((widget.problem.display['targets'] as List?) ?? const []).map((e) => (e as num).toInt()).toList()` — the same defensive-cast style every prior custom widget's list display field uses.
- **Reuse note:** this is the third time this session a custom_widget has been built by wrapping/reusing existing rendering infrastructure rather than writing new painting code (`hundred_chart_skip` wrapped `HundredChartWidget`; this wraps `ScaledNumberLinePainter`) — `order_cards` (Batch 1.5) was the exception, needing genuinely new `Draggable`/`DragTarget` interaction code because no reusable component existed for it.
