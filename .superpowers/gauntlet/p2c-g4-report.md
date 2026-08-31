# P2 Task 5 (part C) — Number-line and picture-reading generators

**Date:** 2026-08-31
**Branch:** `gauntlet/p2-p3-p4`
**Scope:** `numberline_step`, `zehnerfeld_read`, `fingerbild_read`, `stellenwerttafel_read`, `numberline_locate`, `picture_compare` — pure Dart generators in `math_app/lib/practice/problem_generators.dart`, TDD, plus smoke-test coverage of every real spec level using these templates.

## Status

DONE — all six generators implemented, unit-tested per template, full suite green, analyzer 0 errors.

## One-line test summary

`flutter test` = 282 passing (was 87; +35 new generator tests, +3 new smoke-test groups covering 27 real-spec levels); `flutter analyze` = 0 errors (335 issues, none in touched files).

## What was implemented

Each generator is deterministic (single `SeededGenerator(seed)` stream, no wall-clock), returns `problem_count` problems via the existing uniqueness harness, and honours the P2 §5 / P3 §4.5 / §4.5b contracts:

- **numberline_step** — `start` sampled from `start_range` filtered to values congruent to `target mod step` (A1.3 step 2 keeps only even starts), strictly before the target (up) / after it (down) so the run is never empty; `expected` is the exact run `start+step … target` (or `start−step … target`); display carries `range, start, target, step, direction`; step restricted to {1, 2, 5, 10}. A1.5 L1's window crossing 30 is exercised.
- **zehnerfeld_read** — `structured`/`five_pattern` keep count ≤ 10; `two_groups` allows count up to 20 split across two frames with display `split` where `a + b == count` and each part in [1, 10] (hand-pinned 17 → [10, 7]); `expected == count`.
- **fingerbild_read** — `hands: 1` caps count at 5, `hands: 2` at 10 (both hands may be used); display carries `count, hands`; `expected == count`.
- **stellenwerttafel_read** — mode `read`: number in [11, 99] with `tens`/`ones` breakdown (99 → tens 9, ones 9); mode `sum_rows`: two rows of column counters each 0..9, `op` from params is authoritative; `expected == computed value`, and for `−` the generator draws `t1 > t2`, `o2 ≤ o1` so the result is non-negative (two-digit) with no borrow.
- **numberline_locate** — `value` drawn from `value_range` clamped to the interior of `range` (never an endpoint; degenerate `value_range [0,20]` clamps to [1, 19]); display carries `range, value`; `expected == value`.
- **picture_compare** — re-rolls until `|left − right| ≥ difference_min` (default 1); `more` → larger side id, `less` → smaller side id, `difference` → the difference; display carries `left, right, question`.

All generators throw `SpecFormatException` (not silent fallbacks) when the spec ranges cannot satisfy the template's math gate.

## Verification

- `flutter test test/problem_generators_test.dart` → 122 passing (groups per template).
- Included per the verify list: A1.3 step-2 congruence filtering (only even starts), A1.5 window crossing 30, numberline_locate endpoint exclusion (+ degenerate-range clamp), sum_rows minus result ≥ 0 (row1 > row2 as numbers), two_groups 17 = 10 + 7 (pinned, seed 1), picture_compare more/less/difference (+ difference_min 3), stellenwerttafel 99.
- `test/all_specs_smoke_test.dart` extended: `visualReadingValid` checks every numberline_step / zehnerfeld_read / fingerbild_read / stellenwerttafel_read / numberline_locate / picture_compare level across all 36 real specs (27 levels, 3 seeds each) plus determinism and per-skill template gates (A1.3, A1.5, A2.3, B2.2).
- `flutter test` (full) → 282 passing. `flutter analyze` → 0 errors; no warnings/infos in the touched files (repo-wide total 335 issues ≤ baseline + 20).
- No child-facing English strings; all prompts come from the specs' `prompt_de`. No `DateTime.now()` anywhere in the generators.

## Concerns

1. **C1.1b / C1.3 L2 semantics**: both specs use `zehnerfeld_read` `two_groups`, but their prompts ask for a *derived* quantity (C1.1b: total minus the grey group; C1.3: one group = the half). Per the task scope, the generator emits `expected == count` (the total) and the split; the difference/half semantics belong to the widget/evaluator work of P2 Task 8, which will need an arrangement-aware answer rule (or an added spec key) to distinguish these from the plain "count the total" skills (C1.1a, C1.2, C2.2).
2. **sum_rows `+` for B2.3 L2**: the generic two-row sum keeps column sums ≤ 9, so B2.3's "viele Einer" (ones > 9 in one row) is not yet representable; the widget/evaluator task may need a non-standard row mode. Current output is valid ZR100 addition.
3. **A1.5 L1 uniqueness**: start_range [28, 29] yields only two distinct problems; the harness's 50-attempt uniqueness budget exhausts and duplicates fill the remaining slots, as allowed by the plan ("the count contract still wins").
