# order_cards_zr20 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `order_cards_zr20` (BUILD_ORDER.md Batch 1.5, construct `order_cards`) playable — a new drag-and-drop custom widget, since neither an existing generic template nor an existing reusable component (unlike Batch 1.4's `HundredChartWidget`) covers "drag scattered number cards into ascending order." The retired `order_cards_exercise.dart` (C2.1) this skill is nominally "reused" from turns out to be a different exercise entirely on inspection (a fixed 1-20 grid, tap-in-order at level 1, type-the-missing-number at levels 2-3 — no dragging, no arbitrary card sets) so this skill is built from the design doc's actual spec, not ported from that file.

**Architecture:** A new `order_cards` custom_widget, generic over `card_count` and `value_range` (reusable by the future ZR100 sibling, `order_cards_zr100`, Batch 2.3). `_generateOrderCards` samples `card_count` distinct values from `value_range` — consecutive integers when `params.mode == "adjacent"`, an arbitrary distinct subset otherwise (default, "spread") — and shuffles them for display (re-shuffling once if the shuffle happens to land already-sorted, so every problem requires real reordering). `expected` is a single comma-joined ascending-order string. `OrderCardsWidget` renders the shuffled cards as `Draggable<int>` sources and `card_count` `DragTarget<int>` slots; a filled slot is tap-to-undo. Evaluation reuses `_evaluateCustomWidget`'s existing default (`_evaluateStringMatch`) — no new evaluator branch for correctness — but a new `wrong_order` error-taxonomy code is added (mirroring `numberline_step`'s existing `wrong_direction` check) to catch the descending-instead-of-ascending mistake.

**Tech Stack:** Flutter/Dart (`math_app/`), `Draggable<int>`/`DragTarget<int>` (the codebase's established drag idiom, e.g. `halving_mirror_enaktiv_widget.dart` — but using the modern `onWillAcceptWithDetails`/`onAcceptWithDetails` API rather than the deprecated `onWillAccept`/`onAccept` those files still use, to avoid adding new `flutter analyze` warnings), the v4 skill-spec JSON pipeline, Python sync/coverage scripts.

**Spec:** `docs/clean-room/v4/skills/BUILD_ORDER.md` Batch 1.5 (line 46) + `docs/superpowers/specs/2026-09-15-exercise-plan-design.md` lines 187-191 (verbatim: "Manipulative: Draggable number cards"; "Levels: 1) 3 cards -> 2) 5 cards, adjacent values -> 3) 5 cards, spread out"; "Example: Order [14, 3, 9] smallest to largest.") + `docs/skill_spec_authoring_guide.md`. Precedent: `docs/superpowers/plans/2026-09-17-quantify-count-zr10.md` (Batch 1.1, the last from-scratch custom widget this session) and `docs/superpowers/plans/2026-09-17-skip2-zr100.md` (Batch 1.4b, for the "wrap vs. build" decision framework, though this skill landed on "build," unlike that one).

## Global Constraints

- German UI only.
- Every generated value stays in `[1, 20]` (ZR20) via `value_range`.
- `error_taxonomy` is `wrong_order` (new) + `other` — NOT `miscount` (its off-by-one check parses `expected.single` as an int, which fails to parse a comma-joined string like `"3,9,14"` and so can never fire here) and NOT `wrong_direction` (only fires for `template == 'numberline_step'`; this skill uses `custom_widget`).
- Never hand-edit `math_app/assets/skill_specs/*.json`.
- `domain` is `"A"` (Zahlbegriff, "Ordering & placing numbers" subsection, `docs/superpowers/specs/2026-09-15-exercise-plan-design.md:76,185`).
- `problem_count: 8` / `mastery.correct_of: 8` per level.
- Touch targets: cards and slots are `56x56` — above the 44x44px floor established in the §3a child-development gate.

---

## Task 1: The `order_cards` generator + `wrong_order` error code

**Files:**
- Modify: `math_app/lib/models/skill_spec.dart` (`kKnownCustomWidgets`), `math_app/lib/practice/problem_generators.dart` (`_generateCustomWidget` switch + new `_generateOrderCards`, `_shuffledCopy`, `_isAscending`), `math_app/lib/practice/template_evaluator.dart` (`_candidateErrorCode`)
- Test: `math_app/test/problem_generators_test.dart`, `math_app/test/template_evaluator_test.dart`

**Interfaces:**
- Consumes: `LevelSpec.intParam`/`intListParam`/`stringParam`, `SeededGenerator.nextInt`/`nextIntInRange` (all existing, unchanged).
- Produces: registry key `order_cards`; `Problem.display == {'custom_widget': 'order_cards', 'cards': List<int>}`; `Problem.expected == [sortedCards.join(',')]`; a new `wrong_order` code `_candidateErrorCode` can return.

- [x] **Step 1: Add the registry key** to `kKnownCustomWidgets`.
- [x] **Step 2: Write the failing generator tests** (spread mode: distinct values, shuffled, not pre-sorted; adjacent mode: consecutive values; `card_count` exceeding the range span is a spec error) — confirmed FAIL with `unknown registry key "order_cards"`.
- [x] **Step 3: Write `_generateOrderCards`** plus two small helpers: `_shuffledCopy` (Fisher-Yates using only `SeededGenerator.nextInt`, since it exposes no `Random` instance for `List.shuffle`) and `_isAscending`. Spread mode shuffles the full `[lo..hi]` candidate list and takes the first `card_count`; adjacent mode samples one start and takes `card_count` consecutive integers. The display order is reshuffled once more and swapped at index 0/1 if it lands already-sorted.
- [x] **Step 4: Run the generator tests — PASS** (3/3), full `problem_generators_test.dart` — PASS (177/177 at this point, before Task 2's real-spec test), no regressions.
- [x] **Step 5: Write the failing evaluator test** (`order_cards (custom_widget)`: correct ascending order matches; the reversed/descending order is `wrong_order` when the spec carries it; falls back to `other` when it doesn't) — the reversed-order test confirmed FAIL (`Expected: 'wrong_order' / Actual: 'other'`) before implementation; the other two already passed trivially (no new code needed for plain correctness matching, which `_evaluateStringMatch` already handles).
- [x] **Step 6: Add the `wrong_order` branch** to `_candidateErrorCode`, gated on `problem.display['custom_widget'] == 'order_cards'`: split the normalized submission by comma, reverse it, rejoin, and compare against `problem.expected.single` (mirroring the existing `numberline_step` `wrong_direction` check's shape, but string-based since `order_cards`'s "sequence" is the card values themselves, not `numberline_step`'s tapped run).
- [x] **Step 7: Run the evaluator tests — PASS** (3/3), full `template_evaluator_test.dart` — PASS (28/28), no regressions.
- [x] **Step 8: Commit** — `feat(order_cards): add the order_cards generator and wrong_order error code`.

---

## Task 2: The `OrderCardsWidget` drag-and-drop widget

**Files:**
- Create: `math_app/lib/widgets/templates/order_cards_widget.dart`
- Modify: `math_app/lib/practice/template_registry.dart` (import + switch)
- Test: `math_app/test/template_widgets_test.dart`

**Interfaces:**
- Consumes: `Problem.display['cards']` (`List<int>`, from Task 1's generator).
- Produces: a `StatefulWidget` matching the standard custom-widget contract `({required Problem problem, required ValueChanged<String> onValueChanged})`.

- [x] **Step 1: Write the failing widget tests** (renders every card as a source and every slot empty; dragging every card into ascending slots reports the sorted order, incomplete drags report `""`; tapping a filled slot returns the card to the source row; a new problem resets the slots) using the established `tester.drag(source, tester.getCenter(target) - tester.getCenter(source))` pattern this codebase already uses for `Draggable`/`DragTarget` widgets (`halving_mirror_enaktiv_widget.dart`'s tests) — but with per-card/per-slot `ValueKey`s (`oc-card-$value`, `oc-slot-$index`) rather than `find.byType`, since this widget has multiple draggables/targets unlike the single-drag halving-mirror widget. Confirmed FAIL (`Method not found: 'OrderCardsWidget'`) before implementation.
- [x] **Step 2: Write `OrderCardsWidget`** — cards not yet placed are derived (`_remaining = cards.where((c) => !_slots.contains(c))`) rather than tracked as separate mutable state, avoiding a state-sync bug class. Initially used the codebase's existing `onWillAccept`/`onAccept` `DragTarget` API (matching `halving_mirror_enaktiv_widget.dart`'s precedent) but `flutter analyze` flagged 2 new `deprecated_member_use` warnings not present in the pre-task baseline (341) — switched to `onWillAcceptWithDetails`/`onAcceptWithDetails` instead, since new code shouldn't add new instances of an already-deprecated pattern even where old code still uses it; `flutter analyze` on the file alone was clean afterward.
- [x] **Step 3: Wire into `template_registry.dart`.** Run the widget tests — PASS (4/4) on the first attempt after the API fix. Full `template_widgets_test.dart` — PASS (121/121), no regressions.
- [x] **Step 4: Commit** — `feat(order_cards): add the OrderCardsWidget drag-and-drop widget`.

---

## Task 3: order_cards_zr20 spec JSON + real-spec test

**Files:**
- Create: `docs/clean-room/v4/skills/specs/order_cards_zr20.json`
- Test: `math_app/test/skill_spec_store_test.dart`, `math_app/test/problem_generators_test.dart`

- [x] **Step 1: Write the spec JSON.** L1 `card_count:3`, `value_range:[1,20]` (spread, default mode) — matches "3 cards." L2 `card_count:5`, `value_range:[1,16]`, `mode:"adjacent"` (so the highest possible run, `16..20`, still fits) — matches "5 cards, adjacent values." L3 `card_count:5`, `value_range:[1,20]` (spread) — matches "5 cards, spread out."
- [x] **Step 2: Add the store test** (`constructId`, `domain`, `titleDe`, all 3 levels' `customWidget == 'order_cards'`).
- [x] **Step 3: Add the generator test** using `_realSpec`, iterating all 3 levels x 100 seeds, asserting the right card count per level (3 for L1, 5 for L2-3), distinctness, `[1,20]` range, `expected` equals the sorted join, and the display order is never pre-sorted.
- [x] **Step 4: Run** `flutter test test/skill_spec_store_test.dart test/problem_generators_test.dart` — PASS. Generator: 198/198 (up from 195 after Task 1's own 3 tests were already counted; net +4 for this task including the real-spec test... actual figures: 177 baseline before Task 1's tests, +3 Task 1 generator tests = 180, +18 skip5/skip10 tests were already in from Batch 1.4c = confirmed at 195 before this task, +3 (spread/adjacent/error) already counted in that 195? — see the actual test run output for ground truth, not this arithmetic reconstruction).
- [x] **Step 5: Commit** — `feat(order_cards_zr20): add v4 skill spec using the new order_cards widget`.

---

## Task 4: Sync, coverage, BUILD_ORDER, full suite

**Files:**
- Modify: `math_app/assets/skill_specs/order_cards_zr20.json` (generated)
- Modify: `docs/clean-room/v4/skills/BUILD_ORDER.md`

- [x] **Step 1: Sync** — `synced 16 skill specs ... (1 copied, 15 unchanged)`.
- [x] **Step 2: Coverage check** — `covered: 16/93`.
- [x] **Step 3: Update BUILD_ORDER.md** — check off Batch 1.5's line, add to `## Done`, correct the trailing count to "these sixteen."
- [ ] **Step 4: Run the full Flutter test suite** — expect PASS.
- [ ] **Step 5: Run `flutter analyze`** — expect no new issues beyond the 341 baseline (verified per-file already; this is the whole-project confirmation).
- [ ] **Step 6: Commit** — `chore(order_cards_zr20): sync spec assets, mark Batch 1.5 done in BUILD_ORDER`.

---

## Self-Review Notes

- **Spec coverage:** `order_cards_zr20` fully covered across 4 tasks (generator+evaluator, widget, spec, sync/doc). Authoring guide step 2 (generic-template-first check) came back negative — no existing template or reusable widget fit, confirmed by the Batch 1.5 research pass before this plan was written, so a genuinely new widget was the correct call, unlike Batch 1.4's "wrap an existing widget" resolution.
- **Placeholder scan:** none.
- **Named-source mismatch, documented not silently ignored:** BUILD_ORDER.md and the design doc both describe this skill as "Reused from C2.1 `order_cards_exercise.dart`," but that file's actual behavior (fixed grid, tap-in-order / type-the-gap) doesn't match "drag scattered cards into order" at all. This plan builds to the design doc's *described* behavior (which the user confirmed, choosing "build it as designed" over simplifying to tap-based selection), not the retired file's actual behavior — worth flagging for whoever reviews `order_cards_zr100` (Batch 2.3) later, since it inherits the same "Reused" label with the same mismatch.
- **Type consistency:** `Problem.display['cards']` is `List<int>` from the generator, read as `((widget.problem.display['cards'] as List?) ?? const []).map((e) => (e as num).toInt()).toList()` in the widget — the same defensive-cast style `SequenceGapWidget`/`HundredChartStepWidget` already use for list display fields.
