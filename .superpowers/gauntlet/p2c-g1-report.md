# P2 Task 4 (part) — `equation_solve` + `equation_gap` generators

**Date:** 2026-08-31
**Branch:** `gauntlet/p2-p3-p4`
**Scope:** pure Dart generators for `equation_solve` and `equation_gap` (forms: `gap`, `helper`, `missing_addend`, `any_split`, `place_value`, `half`, `double`, `neighbor`, `helper_double`).

## Implemented rules

### `equation_solve` (`lib/practice/problem_generators.dart` → `_generateEquationSolve`)
- `unknown=result`: `display` carries `a, b, c`; `expected == a op b`; **zr is the result bound** (`a+b ≤ zr` for `+`, enforced by clamping the draws). Subtraction is never negative: `a ≥ b` (a clamped to `≥ bLo`, b clamped to `≤ a`).
- `unknown=addend` (`_ + b = c`): missing `a = c−b ≥ 1`, `c = a+b ≤ zr`. Serves C2.3 L3 / C4.2 L3 (missing addend sampled from `a_range`).
- `unknown=subtrahend` (`a − _ = c`): `1 ≤ a−c ≤ a−1`, `c ∈ [bLo, a−1]`.
- `unknown=minuend` (`_ − b = c`): `a = c+b`, `c ≥ 1`, minuend can sit at zr (boundary test `a_range [20,20] → expected ["20"]`).
- `equal:true` (A3.3 L3, C1.2 L3): forces `a == b`, `expected == 2a ≤ zr`.
- `mode:place_value` (C3.1a/b L3): both addends decomposed into tens/ones; `expected == (tensA±tensB)*10 + (onesA±onesB)` with no column overstep/borrow (`tens/ones` result fields in `display`, so `expected == tens*10 + ones` holds literally). `+` caps each column sum ≤ 9; `−` requires `tensA ≥ tensB`, `onesA ≥ onesB`.
- Determinism (same seed → identical list) and in-level uniqueness via the harness (display-keyed).

### `equation_gap` (`_generateEquationGap`)
- `gap` (C4.2 L2): `a − b = _`, `gap_after:'result'`, `expected == a−b`, `a ≥ b`.
- `helper` (`gap_after:'right'`, equation `a op b = first op _`):
  - `+` single-digit `b` (C2.1 L2, make_ten): `first == 10`, **`gap == a+b−10 ≥ 1`** (boundary test 9+2 → 1).
  - `+` two-digit `b` (C3.4a L2, tens_ones): `first == a + 10·(b~/10)`, `gap == b%10 ≥ 1`.
  - `−` single-digit `b` (C3.2 L2, make_ten): `first == a − a%10`, `gap == b − a%10 ≥ 1` (a%10 ∉ {0,9} rejected).
  - `−` two-digit `b` (C3.4b L2, tens_ones): `first == a − 10·(b~/10)`, `gap == b%10 ≥ 1`.
  - Split style inferred deterministically from `b_range` (max < 10 → make_ten, else tens_ones). Both sides always equal `a op b`.
- `missing_addend` (A3.1 L3, C2.3 L2): `a + _ = c`, `c = a+b ≤ zr`, `expected == c−a`.
- `any_split` (A3.2 L3): `_ + _ = N`; `expected` lists **all** pairs `"i+(N−i)"` for `i = 1..N−1` (tested for total 6 and 10).
- `place_value` (B1.1/B2.1/B2.3 L3): `expected == tens*10 + ones`, **ones may be ≥ 10** (boundary test `2 Z 19 E → 39`), value ≤ zr (99).
- `half` (C1.3 L3): total even, `expected == total/2`.
- `double`: `expected == 2a ≤ zr`.
- `neighbor`: `expected == [n−1, n+1]`, n sampled from `start_range` (fallback `a_range`), clamped to zr.
- `helper_double` (C2.2 L3, C3.3 L2): `first == 2·min(a,b)`, **`gap == (a+b) − 2·min(a,b) ≥ 1`** (boundary test 6+7 → 1).

Every generated problem: `prompt_de` from the spec (non-empty German), `index` 0..count−1, non-empty `expected`, equation arithmetically true. Unknown forms/unknowns throw `SpecFormatException`.

## Test names (added)

`test/problem_generators_test.dart`:
- group `equation_solve generator` (11 tests): `unknown=result op +: expected == a+b, result respects zr`; `unknown=result op -: never negative, a >= b, a==b gives result 0`; `unknown=addend: _ + b = c with missing addend >= 1 and c <= zr`; `unknown=subtrahend: a - _ = c with 1 <= subtrahend <= a-1`; `unknown=minuend: _ - b = c with minuend c+b, boundary at zr`; `equal:true forces a == b and expected is the double`; `place_value mode op +: column-wise, expected == tens*10 + ones`; `place_value mode op -: column-wise subtraction, never negative`; `is deterministic and unique within a level`; `problems carry index, non-empty expected and prompt`.
- group `equation_gap generator` (16 tests): `form gap`; `form helper op + make_ten: a+b = 10+_, gap == a+b-10 >= 1` (incl. `a+b-10 == 1` boundary); `form helper op + tens_ones: a+b = (a+tens)+_, gap == b%10`; `form helper op - make_ten: a-b = (a-ones)-_, rest >= 1`; `form helper op - tens_ones: a-b = (a-tens)-_, gap == b%10`; `form missing_addend: a + _ = c with expected c-a and c <= zr`; `form any_split: expected lists all pairs i+(total-i)` (total 6 and 10); `form place_value: expected == tens*10 + ones, ones may be >= 10` (incl. ones 19 → 39); `form half: total even, expected == total/2`; `form double: expected == 2a and never exceeds zr`; `form neighbor: expected == [n-1, n+1]`; `form helper_double: gap == (a+b)-2*min(a,b), 6+7 -> 1`; `is deterministic and unique within a level`; `problems carry index, non-empty expected and prompt`.
- Updated `unimplemented templates throw UnimplementedError` to use `strategy_choice` (equation_solve is now implemented).

`test/all_specs_smoke_test.dart` (new): loads all 36 real specs, generates all 29 equation levels (13 `equation_solve` + 16 `equation_gap`) across 3 seeds each and asserts count, index, non-empty expected/prompt, and a generic `equationHolds` check (every shown equation arithmetically true, expected fills the gaps); plus determinism on the real specs.

## Verification results

- `cd math_app && flutter test test/problem_generators_test.dart` → **40 tests, all passed**.
- `cd math_app && flutter test test/all_specs_smoke_test.dart` → **2 tests, all passed**.
- `cd math_app && flutter test` (full suite) → **191 tests, all passed**.
- `cd math_app && flutter analyze` → **0 errors**; no issues reported in `problem_generators.dart` / new test files (pre-existing warnings/info in legacy widgets only).

## Notes / decisions
- Minus `helper` gap is placed as the last operand of the second expression (`a − b = first − _`, `gap_after:'right'`), matching the stepwise-decomposition prompts of C3.2/C3.4b; the plan's illustrative `18 - 9 = _ - 10` position is not reproduced verbatim, but the equation is arithmetically true and pedagogically the full-ten decomposition.
- `equation_solve` `place_value` renders two addends decomposed column-wise (C3.1a/b need real place-wise addition); the single-pair "Z Zehner + E Einer = Zahl" reading with ones ≥ 10 is served by `equation_gap` `place_value` (B2.3/B1.3).
- Helper split style (make_ten vs tens_ones) is inferred from `b_range`; no extra spec param needed.
