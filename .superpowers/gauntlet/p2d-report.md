# P2 Task 6 — PracticeController + TemplateEvaluator Report

**Date:** 2026-08-31
**Author:** Gauntlet implementer
**Scope:** P2 plan §5 template semantics evaluation, two-groups derived-quantity fix, session controller
**Branch:** `gauntlet/p2-p3-p4`

## Status

DONE. Evaluator + controller implemented test-first, generator fixed, all gates green.

## Deliverables

1. `math_app/lib/practice/template_evaluator.dart` — `AnswerEvaluation evaluate(Problem, String, {required SkillSpec spec})` returning `isCorrect`, `errorCode`, `canonicalAnswer` (the DB answer string).
2. Two-groups derived-quantity fix in `math_app/lib/practice/problem_generators.dart` + spec params in `docs/clean-room/skills/specs/{C1.1b,C1.3}.json` (synced to assets) + `scripts/check_specs.py` vocabulary.
3. `math_app/lib/practice/practice_controller.dart` — `PracticeController extends ChangeNotifier`.
4. Tests: `test/template_evaluator_test.dart`, `test/practice_controller_test.dart`; generator tests + `test/all_specs_smoke_test.dart` extended.

## Evaluator rule table

| Template | Correctness rule | DB answer |
|---|---|---|
| equation_solve, equation_gap, compare_symbols, zehnerfeld_read, fingerbild_read, stellenwerttafel_read, numberline_locate, picture_compare, word_problem, flash_subitize, numberline_mark (+ equation_solve place_value) | normalised submitted ∈ `expected` (answers_match via `answer_normalization.dart`) | matched expected / normalised submitted |
| sequence_gap | collapsed submitted (spaces stripped) == `expected.join(",")` | joined values |
| picture_compare more/less | submitted == side id in `expected` (`"left"`/`"right"`) | side id |
| drag_partition | parse `"b1+b2+…"`; boxes sum to `total`, count == `parts`, every part ≥ 1, AND `split_constraint` holds: `sum` any · `equal` all equal · `make_ten` contains 10 · `near_double` `[n,n,1]` · `tens_ones` `[a, 10·floor(b/10), b%10]` from display | `"b1+b2"` |
| place_counters fill | submitted int == `display.count` | count |
| place_counters take_away | submitted int == `display.total − display.count` (== `display.remaining`) | remaining |
| place_counters nonstandard (B2.3) | int == `count` OR `"Z E"` pair with `10·Z+E == count` | count / `"Z E"` |
| bundle_sticks (+ custom `bundling`) | `10·Z+E == count` AND (count ≥ 10 → Z ≥ 1), parsing `"Z Zehner, E Einer"` or `"Z E"` | `"Z Zehner, E Einer"` |
| rekenrek_set | submitted int == `display.count` | count |
| numberline_step | collapsed submitted == `expected.join(",")` (exact tap run) | joined run |
| strategy_choice | `"value\|strategyId"`: value == `expected` AND strategyId == `display.correct_strategy` | `"value\|strategyId"` |

Error codes: wrong answers default to `"other"`; explicit deterministic checks map to `sign_error` (sign flipped), `miscount` (numeric answer off by one), `wrong_direction` (numberline run reversed). A candidate is only used when the spec's own error taxonomy carries it; otherwise it falls back to `"other"` (present in every spec).

## Two-groups derived-quantity fix

`zehnerfeld_read` with `arrangement: "two_groups"` now reads `params.ask` (`total` default | `difference` | `part`) and emits it in `display.ask`, with `expected` equal to the asked quantity:

- `difference` (C1.1b L2, "Wie viele Punkte bleiben übrig?"): counts clamped to [3, 19] so the groups always differ; `expected == |a−b| ≥ 1`.
- `part` (C1.3 L2, "Wie viele Punkte sind in einer Gruppe?"): counts forced even, equal groups `[n, n]`, `expected == n == count/2`.
- `total` (default): unchanged, `expected == a+b`.

Spec files updated with the explicit `ask` param; `check_specs.py` whitelists `ask` with enum `{total, difference, part}`; assets re-synced.

## Controller state machine

```
starting ──start() ok──▶ ready ──submit()──▶ submitting ──eval──▶ correct / incorrect
                                                                        │ advance() (last?)
   │                                                                   ▼
   └─start() fail──▶ failed ──(retry start())──▶ ready          ready (next problem)
                                                                        │ advance() (last)
                                                                        ▼
                                                              finished ──finish()──▶ masteryResult
                                                                        │ fail
                                                                        ▼
                                                                     failed ──(retry finish())──▶ finished
```

- `start()` → `startPractice` → `generateProblems(spec, level, seed)`; starts the per-problem Stopwatch.
- `submit(value)` → Stopwatch elapsed = `responseMs`, evaluate, `PracticeAttempt(problemIndex, problem.toJson(), canonicalAnswer, wasCorrect, responseMs, errorCode)`, `recordAttempt` (silent-fail; queue retains), state correct/incorrect, `hintDe` from the spec taxonomy.
- `advance()` → next problem (Stopwatch reset) or `finished`.
- `finish()` → `endPractice(token, sessionId, slowBandMs: spec.levelSpec(level).slowBandMs)` → `masteryResult`; any `LearningPathException` → `failed` with German message; idempotent (early-return once mastered).
- Timer-less: the screen drives feedback→advance delay.

## Test names

`test/template_evaluator_test.dart` (22):
- string-match templates: correct answer matches, whitespace normalised; sign_error; miscount; unknown wrong answers fall back to other; compare_symbols; picture_compare difference and more/less side ids; word_problem and flash_subitize
- sequence_gap: joined values in exact gap order (incl. spaces around commas, reversed/incomplete)
- drag_partition: sum any-split + canonical `4+5`; make_ten `11 = 9+2` wrong; equal; near_double `[n,n,1]`; tens_ones `[35,20,7]`
- place_counters: fill; take_away remaining; nonstandard `34` / `"2 14"`
- bundle_sticks: `"2 Zehner, 3 Einer"`, `"2 3"`, zero-bundle rejection
- rekenrek_set; numberline_step exact run + reversed → wrong_direction
- strategy_choice composite; error-code fallback when spec lacks the candidate

`test/practice_controller_test.dart` (8):
- full session: 8 problems recorded in order with problem_index / was_correct / response_ms / error_code / exact problem JSON; /end carries slow_band_ms; start body skill_id+level
- slow answer (> slow band) still evaluates and the record carries response_ms; /end gets the spec slow band
- network failure during recordAttempt: session continues, queue retains, later flush delivers 0,1,2 in order
- start() failure → failed + German message (no digits), retry → ready
- finish() failure → failed, retry succeeds, third finish makes no further /end call (idempotent)
- strategy_choice composite via controller (value+strategy); drag_partition make_ten wrong split; C1.1b L2 two_groups difference fixture

`test/problem_generators_test.dart` (+6): ask difference |a−b| ≥ 1; ask part equal groups expected == count/2; odd-only range spec error; real C1.1b L2 / real C1.3 L2; hand-computed C1.1b L2.

`test/all_specs_smoke_test.dart`: `visualReadingValid` now checks `display.ask` for two_groups (total/difference/part).

## Output

- `flutter test test/practice_controller_test.dart test/template_evaluator_test.dart test/problem_generators_test.dart` → 172 passed
- `flutter test` (full) → **335 passed, 0 failed**
- `flutter analyze` → **0 errors**; no issues in `lib/practice/*`; total lints 335 (pre-existing legacy-widget lints)
- `python scripts/check_specs.py` → OK: 36 specs validated
- Grep `imint|pikas` on new files → clean

## Concerns

1. `sequence_gap` multi-gap matching strips ALL spaces (so `"6, 8"` == `"6,8"`); this is intentional for the comma-joined DB form but means a German decimal comma in a future gap value would be ambiguous — not an issue while gaps are integers.
2. The `make_ten` drag_partition evaluator is order-insensitive (`contains(10)`), while `near_double`/`tens_ones` require exact box order — matches the generator's canonical box order and the plan's box-count semantics.
3. `difference` counts are clamped to [3, 19]; C1.1b's [2, 10] range yields effective [3, 10] (2 would force 1+1, difference 0). No spec is affected.
