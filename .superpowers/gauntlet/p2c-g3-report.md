# P2 Task 5 — g3 report: `drag_partition`, `place_counters`, `bundle_sticks`, `rekenrek_set` generators

**Date:** 2026-08-31
**Branch:** `gauntlet/p2-p3-p4`
**Status:** DONE — all four manipulative-template generators implemented (pure, deterministic), math-edge tests green, analyzer 0 errors, full suite green.

## Scope

Implement the four enaktiv-template generators from P2 plan §5 items 1–4 in `math_app/lib/practice/problem_generators.dart`, per P3 plan §4.5 params and §4.5b obligations, honouring the task's current `split_constraint` semantics.

## What changed

- `math_app/lib/practice/problem_generators.dart`
  - dispatch cases `drag_partition`, `place_counters`, `bundle_sticks`, `rekenrek_set` in `_generateForTemplate`;
  - `_generateDragPartition` + `_dragPartitionBoxes` (split engine for all five constraints);
  - `_generatePlaceCounters` (fill / take_away, per-frame capacity caps);
  - `_generateBundleSticks` (canonical `"Z Zehner, E Einer"` answer);
  - `_generateRekenrekSet` (bead-count reproduction).
- `math_app/test/problem_generators_test.dart` — four new groups (24 tests) incl. hand-computed pins: C2.1 L1 full-ten splits, C3.4a `35 + 27 → [35, 20, 7]` (seed 369 i6), `39 → 3 Zehner, 9 Einer`, rekenrek 20, take_away remaining ≥ 0.
- `math_app/test/all_specs_smoke_test.dart` — `manipulativeValid` + a new group covering every drag_partition/place_counters/bundle_sticks/rekenrek_set level of all 36 real specs: validity, per-skill split-constraint gates (A3.1 sum, A3.3/C1.2/C1.3 equal, C2.1 make_ten, C3.3 near_double, C3.4a/b tens_ones, C4.2 sum), determinism.

## Generator semantics

### drag_partition

- `total ∈ total_range`, split into `parts` boxes, `box_labels` length == parts (mismatch → `SpecFormatException`).
- Constraint resolution: `split_constraint` param wins; legacy `equal: true` → `equal`; otherwise `sum` (the real specs A3.1/A3.2/C4.2 carry `equal: false`; A3.3/C1.2/C1.3 carry `equal: true`; C2.1/C3.3/C3.4a/b carry `split_constraint`).
  - `sum` — any split into positive boxes (`sum == total`); rejects ranges that cannot hold `parts` positive boxes.
  - `equal` — totals drawn only from values divisible by `parts` (even for parts 2), boxes all `total/parts`.
  - `make_ten` — totals 11..19, boxes exactly `[10, total-10]`; a wrong split (15 = 9+6) is never emitted.
  - `near_double` — parts 3, totals odd in 11..19, boxes `[n, n, 1]`, total `== 2n+1`.
  - `tens_ones` — parts 3, boxes `[a, 10·floor(b/10), b%10]` with `a+b == total`, `b ≥ 11`, `b%10 ≥ 1` (resampled; degenerate ranges fail loudly).
- `expected` is empty (the widget evaluates the split semantically); `display` carries `total`, `parts`, `split_constraint`, `box_labels`, the canonical `boxes`, and `a`/`b` for `tens_ones`.

### place_counters

- `count ∈ count_range`, `frame` zehnerfeld | rekenrek | stellenwerttafel, `action` fill | take_away.
- Capacity caps per frame: zehnerfeld ≤ 10, rekenrek ≤ 20, stellenwerttafel ≤ 99 — a single ten-frame never exceeds 10 (C1.2/C1.3 two-frame counts are a `zehnerfeld_read` concern, out of scope here).
- `fill`: child places exactly `count`; display carries `count`; `expected == [count]`.
- `take_away`: display carries `total` and `count` with `total ≥ count` and `remaining = total − count ≥ 0`; `expected == [count]` (the amount the child must remove).

### bundle_sticks

- `count ∈ count_range`, clamped to ≥ 12 so the canonical answer always needs ≥ 1 Zehner bundle (a range below 12 → `SpecFormatException`).
- `display` carries `count`, `bundles = count ~/ 10`, `singles = count % 10`; `expected == "Z Zehner, E Einer"` (e.g. 39 → `3 Zehner, 9 Einer`).

### rekenrek_set

- `count ∈ [1, 20]`, `rows` carried in display; `expected == [count]` (the number to reproduce).

## Hand-computed problems proving the math gates

| template | problem | assertion |
|---|---|---|
| drag_partition (make_ten) | C2.1 L1, seeds 0..19 | every split is `{10, total−10}`, totals 11..19 |
| drag_partition (tens_ones) | C3.4a L1, seed 369, i6 | total 62, a=35, b=27, boxes `[35, 20, 7]` |
| bundle_sticks | count_range [39,39] | `3 Zehner, 9 Einer` |
| rekenrek_set | count_range [20,20] | `20` |
| place_counters (take_away) | count 2..10, total ≥ count | remaining ≥ 0 for every seed |

## Verification

- `flutter test test/problem_generators_test.dart` → 87 pass (63 before).
- `flutter test test/all_specs_smoke_test.dart` → 8 pass (incl. new manipulative group).
- `flutter analyze` → 0 errors (335 pre-existing info/warnings only; the touched files contribute 0).
- `flutter test` (full suite) → 244 pass (217 before).

## Concerns

- `near_double` and `equal` levels on small ranges (C3.3: 5 odd totals; A3.3: 5 even totals) cannot yield 8 distinct problems; the harness's uniqueness contract allows the fill fallback, so a level may contain duplicate totals. Accepted per plan §5/`generateProblems` contract.
- `drag_partition.expected` stays empty by design (widget evaluates semantically); the DB answer string `"3+4"` (P2 §5 rule 1) is the evaluator's concern in P2 tasks 6/7 and is derivable from `display.boxes`.
- `place_counters` `mode: "nonstandard"` (B2.3 L1) is not yet handled — no referenced spec uses it; it can be added when B2.3 is wired.
