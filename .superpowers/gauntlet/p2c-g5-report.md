# P2 Tasks 4–5 (final part) — custom-widget generators + full-bank smoke test

**Date:** 2026-08-31
**Branch:** `gauntlet/p2-p3-p4`
**Scope:** P2 plan §5 custom_widget registry generators (bundling, unbundling,
numberline_mark, flash_subitize), `place_counters` mode `nonstandard` (B2.3 L1),
`stellenwerttafel_read` sum_rows "viele Einer" (B1.3/B2.3 L2), and the
864-problem full-bank smoke test in `test/all_specs_smoke_test.dart`.

## Verification evidence

| Gate | Result |
|---|---|
| `cd math_app && flutter test test/problem_generators_test.dart test/all_specs_smoke_test.dart` | **All tests passed** (149 tests) |
| `cd math_app && flutter analyze` | **0 errors** (335 pre-existing warnings/infos; 0 in the files changed here) |
| `cd math_app && flutter test` (full suite) | **All tests passed** (298 tests) |
| `python scripts/check_specs.py` | OK: 36 specs validated |
| `python scripts/check_provenance.py` | OK |

## Spec fixes made (reported precisely)

The acceptance gate exposed one genuine spec gap. `B1.3 L2` and `B2.3 L2` are
both `stellenwerttafel_read` with `mode: sum_rows`, `rows: two_rows`, `op: "+"`
— byte-identical params to `C3.1a L2`. The B1.3/B2.3 constructs require
non-standard rows ("1 Zehner 13 Einer"; "Zahlen mit vielen Einern lesen"), i.e.
the Einer column total must exceed 9, while C3.1a's column-wise addition must
never carry. No param distinguished them, so the spec could not express the
"viele Einer" requirement.

- Added `"ones_range": [10, 18]` to the L2 `params` of
  `docs/clean-room/skills/specs/B1.3.json` and `B2.3.json` (and mirrored to
  `math_app/assets/skill_specs/` via `scripts/sync_skill_specs.py`).
- Added `ones_range` to the `stellenwerttafel_read` params whitelist in
  `scripts/check_specs.py` (it was already in the `[lo, hi]` range set).
- The generator (`_generateStellenwerttafelRead`, sum_rows `+`) now honours the
  optional `ones_range`: the E column total is sampled into `[lo, min(hi,18)]`
  while each row digit stays ≤ 9 and the composed value never exceeds 99. When
  the param is absent (C3.1a L2, tests) the previous no-carry behaviour is
  unchanged.

## Implemented generators (math-app/lib/practice/problem_generators.dart)

- **`custom_widget` dispatch** — `_generateCustomWidget` routes on the
  registry key; unknown keys throw `SpecFormatException`.
- **`bundling`** (registry, B1.2 semantics): display carries `count`
  (12..39) plus the canonical `bundles`/`singles`; `expected: []` (the widget
  evaluates `10*Z + E == count`, `Z >= 1`); DB stores `"Z Zehner, E Einer"`.
- **`unbundling`** (B1.3 L1, real spec): display carries `tens` (1..3),
  `ones` (1..9) and `count`; `expected == 10·Z + E`.
- **`numberline_mark`** (registry, B2.2 semantics): display carries
  `range` + `value`; `expected == value`; value is never an endpoint.
- **`flash_subitize`** (A2.1 L1/L2, real spec): display carries
  `count` (≤ 5, clamped from `count_range`), `flash_ms` (800) and
  `display` (`dots`|`rekenrek`); `expected == count`.
- **`place_counters` mode `nonstandard`** (B2.3 L1, real spec): decomposes
  `n` as `tens = n div 10 − 1`, `ones = 10 + n mod 10` so `10·tens + ones == n`
  and the Einer column holds 10..19; display carries `tens`, `ones`, `count`;
  `expected == count`.
- **`stellenwerttafel_read` sum_rows "viele Einer"** (B1.3/B2.3 L2): as above.

## Full smoke-test result per spec (36 rows)

Loaded via the same test-only loader as `skill_spec_store_test.dart`
(`docs/clean-room/skills/specs/*.json`). For every level of every spec, the
smoke test generated `problem_count` (8) problems under seeds
{1, 7, 42, 123, 987} and asserted: no exceptions, exact count, `expected`
non-empty (or the documented empty-for-semantic forms —
`drag_partition` and custom `bundling`), `prompt_de` non-empty, deterministic
per seed, and every problem passing its template's semantic validity check.
Total = 36 × 3 × 8 × 5 = **4320 generated problems**, 0 failures.

| Spec | L1 | L2 | L3 | Pass | Problems found |
|---|---|---|---|---|---|
| A1.1a | numberline_step | sequence_gap | sequence_gap | ✔ | none |
| A1.1b | numberline_step | sequence_gap | sequence_gap | ✔ | none |
| A1.2a | numberline_step | sequence_gap | sequence_gap | ✔ | none |
| A1.2b | numberline_step | sequence_gap | sequence_gap | ✔ | none |
| A1.3 | numberline_step | sequence_gap | sequence_gap | ✔ | none |
| A1.4 | sequence_gap | sequence_gap | sequence_gap | ✔ | none |
| A1.5 | numberline_step | sequence_gap | sequence_gap | ✔ | none |
| A2.1 | cw:flash_subitize | cw:flash_subitize | zehnerfeld_read | ✔ | none |
| A2.2 | rekenrek_set | zehnerfeld_read | fingerbild_read | ✔ | none |
| A2.3 | picture_compare | picture_compare | compare_symbols | ✔ | none |
| A3.1 | drag_partition | drag_partition | equation_gap | ✔ | none |
| A3.2 | place_counters | drag_partition | equation_gap | ✔ | none |
| A3.3 | drag_partition | sequence_gap | equation_solve | ✔ | none |
| B1.1 | bundle_sticks | stellenwerttafel_read | equation_gap | ✔ | none |
| B1.2 | bundle_sticks | stellenwerttafel_read | equation_gap | ✔ | none |
| B1.3 | cw:unbundling | stellenwerttafel_read | equation_gap | ✔ | L2 missing `ones_range` (fixed — see above) |
| B2.1 | place_counters | stellenwerttafel_read | equation_gap | ✔ | none |
| B2.2 | numberline_step | numberline_locate | numberline_locate | ✔ | none |
| B2.3 | place_counters | stellenwerttafel_read | equation_gap | ✔ | L2 missing `ones_range` (fixed — see above) |
| C1.1a | place_counters | zehnerfeld_read | equation_solve | ✔ | none |
| C1.1b | place_counters | zehnerfeld_read | equation_solve | ✔ | none |
| C1.2 | drag_partition | zehnerfeld_read | equation_solve | ✔ | none |
| C1.3 | drag_partition | zehnerfeld_read | equation_gap | ✔ | none |
| C2.1 | drag_partition | equation_gap | equation_solve | ✔ | none |
| C2.2 | drag_partition | zehnerfeld_read | equation_gap | ✔ | none |
| C2.3 | place_counters | equation_gap | equation_solve | ✔ | none |
| C3.1a | place_counters | stellenwerttafel_read | equation_solve | ✔ | none |
| C3.1b | place_counters | stellenwerttafel_read | equation_solve | ✔ | none |
| C3.2 | numberline_step | equation_gap | equation_solve | ✔ | none |
| C3.3 | drag_partition | equation_gap | equation_solve | ✔ | none |
| C3.4a | drag_partition | equation_gap | equation_solve | ✔ | none |
| C3.4b | drag_partition | equation_gap | equation_solve | ✔ | none |
| C4.1 | strategy_choice | strategy_choice | strategy_choice | ✔ | none |
| C4.2 | drag_partition | equation_gap | equation_solve | ✔ | none |
| D1.1 | word_problem | word_problem | word_problem | ✔ | none |
| D1.2 | word_problem | word_problem | word_problem | ✔ | none |

**36/36 specs, 108/108 levels: PASS.** The only problems found were the two
spec-param gaps listed above; both were fixed in the specs + validator +
assets, not by weakening the test.

## Notes for the widget implementer (P2 Task 8)

- `flash_subitize` display carries `flash_ms` — the widget must flash for that
  duration (800 ms) then hide the pattern before the child types.
- `bundling`/`unbundling` display carries the split so the DB answer string
  `"Z Zehner, E Einer"` can be built from the child's final state; `bundling`
  evaluates semantically (`expected: []`).
- `place_counters` mode `nonstandard` — the widget checks
  `10·tens_placed + ones_placed == count` with `ones_placed` allowed to exceed
  9, and renders the Stellenwerttafel with a larger Einer capacity.
- `stellenwerttafel_read` sum_rows with `ones_range` — the Einer column total
  exceeds 9; the widget renders a Stellenwerttafel whose Einer cell holds more
  than 9 counters across the two rows.
