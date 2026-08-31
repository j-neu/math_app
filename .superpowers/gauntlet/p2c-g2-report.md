# P2 Task 4 — g2 report: `word_problem` + `strategy_choice` generators

**Date:** 2026-08-31
**Branch:** `gauntlet/p2-p3-p4`
**Commit:** `351c7d4`
**Status:** DONE — both templates fully implemented (pure, deterministic), math-edge tests green, analyzer 0 errors, full suite green.

## Scope

Implement the two remaining symbolic-template generators from P2 plan §5 items 15 (`strategy_choice`) and 16 (`word_problem`) in `math_app/lib/practice/problem_generators.dart`, following P3 plan §4.5 params and §4.5b obligations (`word_problem` `op: "+|-"` re-rolls the operation per problem).

## What changed

- `math_app/lib/practice/problem_generators.dart`
  - dispatch cases `word_problem` and `strategy_choice` in `_generateForTemplate`;
  - `_generateWordProblem` + `_wordSentence` (German sentence builder);
  - `_generateStrategyChoice` + `_strategyNumbers` (strategy-exemplifying number pairs).
- `math_app/test/problem_generators_test.dart` — new `word_problem` (9 tests) and `strategy_choice` (12 tests) groups incl. hand-computed pinned assertions; the old "unimplemented templates throw" test now uses `picture_compare` (strategy_choice is implemented).
- `math_app/test/all_specs_smoke_test.dart` — new group covering `word_problem`/`strategy_choice` levels of all 36 real specs: validity (`problemValid`), op-mixing for `+|-` levels, determinism.
- `docs/clean-room/skills/specs/C4.1.json` — L3 `correct_strategy` changed `"fast_verdoppeln"` → `"mixed"` so the real spec matches the P3 plan level mapping ("C4.1 | strategy_choice (mixed)") and the task's "vary the strategy" requirement.
- `scripts/check_specs.py` — `"mixed"` accepted as a `correct_strategy` directive (rotates through the strategy ids).
- `math_app/assets/skill_specs/C4.1.json` — re-mirrored via `scripts/sync_skill_specs.py` (1 copied, 35 unchanged).

## Generator semantics

### word_problem

- Context (`setting_de`, `object_de`) drawn from `contexts` (>= 2 entries required).
- Numbers derived from `zr` (specs carry no `a_range`/`b_range` for this template; optional ranges are read if ever present). Both numbers are always `>= 2` so the plural object nouns stay grammatical (`sind 4 Äpfel`, `3 kommen dazu`).
- `op: "+"` → `a + b <= zr`; `op: "-"` → `b <= a`, result `>= 0`; `op: "+|-"` → operation re-rolled per problem (D1.2, P3 §4.5b).
- `prompt_de` is the complete German sentence built by the generator:
  - plus: `Im Korb sind 4 Äpfel. 3 kommen dazu. Wie viele sind es?`
  - minus: `Im Korb sind 7 Äpfel. 3 werden weggenommen. Wie viele sind es?`
- `display` carries `setting_de`, `object_de`, `a`, `b`, `op`, `ask_operation`; `expected` == the numeric result.
- Uniqueness: the harness dedupes on `display`, i.e. on exactly the `(setting, object, a, b, op)` tuple.

### strategy_choice

- `expected` == `a op b` (numeric result); `display` carries `op`, `a`, `b`, `strategies` (each with `id` + `label_de`), `correct_strategy` (one of the spec's strategy ids).
- Numbers genuinely exemplify the strategy (C4.1 ids):
  - `verdoppeln` → `a == b`
  - `fast_verdoppeln` → `|a - b| == 1`
  - `ueber_die_zehn` → `(a % 10) + (b % 10) >= 10` AND the pair is not a (near-)double, so the "Über die Zehn" strategy is the genuinely indicated one.
- `correct_strategy: "mixed"` (C4.1 L3) rotates through the spec's strategy ids by problem index, so the level's strategies vary; each problem's displayed `correct_strategy` is always one of the spec's ids.
- ZR respected: C4.1 L1 ZR20, L2/L3 ZR100; subtraction never negative.

## Hand-computed C4.1 problems (seed 7) proving the strategy constraint

**L1 — `verdoppeln`, ZR20** (`a == b`, result `2a <= 20`):

| i | a | b | result | constraint |
|---|---|---|---|---|
| 0 | 9 | 9 | 18 | 9 == 9 |
| 1 | 10 | 10 | 20 | 10 == 10 |
| 2 | 7 | 7 | 14 | 7 == 7 |
| 3 | 2 | 2 | 4 | 2 == 2 |

**L2 — `ueber_die_zehn`, ZR100** (ones cross a ten, not doubles):

| i | a | b | result | ones sum |
|---|---|---|---|---|
| 0 | 47 | 38 | 85 | 7 + 8 = 15 >= 10 |
| 1 | 35 | 39 | 74 | 5 + 9 = 14 >= 10 |
| 2 | 28 | 32 | 60 | 8 + 2 = 10 >= 10 |
| 3 | 44 | 38 | 82 | 4 + 8 = 12 >= 10 |

**L3 — `mixed`, ZR100** (rotation index % 3: 0 verdoppeln, 1 fast_verdoppeln, 2 ueber_die_zehn):

| i | a | b | strategy | result | constraint |
|---|---|---|---|---|---|
| 0 | 47 | 47 | verdoppeln | 94 | 47 == 47 |
| 1 | 29 | 30 | fast_verdoppeln | 59 | \|30 − 29\| == 1 |
| 2 | 19 | 27 | ueber_die_zehn | 46 | 9 + 7 = 16 >= 10 |
| 3 | 29 | 29 | verdoppeln | 58 | 29 == 29 |
| 4 | 31 | 32 | fast_verdoppeln | 63 | \|32 − 31\| == 1 |
| 5 | 14 | 47 | ueber_die_zehn | 61 | 4 + 7 = 11 >= 10 |

All 3 strategies appear; every problem's numbers fit its strategy. (Asserted verbatim in the hand-computed tests.)

## word_problem minus with result >= 0

D1.1 L2 (minus, ZR20), seed 5, i5:
> In der Pausentasche sind 17 Mandarinen. 17 werden weggenommen. Wie viele sind es?

`expected == ["0"]`, i.e. `17 − 17 = 0 >= 0`. (Pinned in a test.)

## word_problem with re-rolled op

D1.2 L1 (`op: "+|-"`, ask_operation true, ZR10), seed 7 — ops: `+ + − + − + + −`; minus problems all `a >= b` with results 7, 2, 2 (>= 0); plus problems all `a + b <= 10`. (Pinned in a test.)

## Verification

- `flutter test test/problem_generators_test.dart` → 63 pass.
- `flutter test test/all_specs_smoke_test.dart` → 5 pass (incl. new word_problem/strategy_choice group).
- `flutter analyze` → 0 errors (335 pre-existing info/warnings only; my files contribute 0).
- `flutter test` (full suite) → 217 pass.
- `python scripts/check_specs.py` → OK: 36 specs validated.

## Concerns

- The C4.1 L3 spec change (`correct_strategy: "fast_verdoppeln"` → `"mixed"`) makes the real spec match the P3 plan's mapping; `check_specs.py` treats `"mixed"` as a level directive rather than a strategy id. A P3 author/reviewer should re-confirm the wording, but the behaviour now matches the plan.
- `expected` for `strategy_choice` is the numeric result only; the composite DB answer `"8|verdoppeln"` (P2 §5 rule 15) is the evaluator's concern (P2 tasks 6/7) and is derivable from `display.correct_strategy`.
- word_problem numbers are derived from `zr` because the real specs (P3 §4.5) define no `a_range`/`b_range` for this template; the generator reads optional ranges if a future spec provides them.
- `word_problem` sentence verbs are generic ("kommen dazu" / "werden weggenommen") so the template is grammatical for every plural object noun in the specs; objects are all plural in D1.1/D1.2.
