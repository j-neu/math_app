# P2 Task 7 — Symbolic template widgets + shared answer pad

**Date:** 2026-08-31
**Branch:** `gauntlet/p2-p3-p4`
**Scope:** P2 plan §8 Task 7 — the six symbolic template widgets
(`equation_solve`, `equation_gap`, `sequence_gap`, `compare_symbols`,
`strategy_choice`, `word_problem`) plus the shared `BigAnswerField`
(`lib/widgets/templates/answer_pad.dart`), with widget tests. Each widget
follows the fixed contract consumed by the Task 9 `PracticeScreen`:
`StatefulWidget` with `({Key? key, required Problem problem, required
ValueChanged<String> onValueChanged})`, renders from `problem.display` /
`problem.promptDe`, reports `""` until an answer is present, and never submits
itself.

## Verification evidence

| Gate | Result |
|---|---|
| `cd math_app && flutter test test/template_widgets_test.dart` | **21/21 passed** |
| `cd math_app && flutter analyze` | **0 errors** (335 pre-existing warnings/infos; **0 issues in the new files**) |
| `cd math_app && flutter test` (full suite) | **All 356 tests passed** (335 baseline + 21 new) |
| Grep `imint\|pikas\|ExerciseService` on new files | clean (no retired-skill references) |

## Widgets (lib/widgets/templates/)

All six widgets render the problem from `problem.display` and report the value
matching exactly what `TemplateEvaluator.evaluate` accepts per template.

### `answer_pad.dart` — `BigAnswerField` (shared input)

Large centred numeric `TextField` (font 32, ≥44 px tap area) that stays
keyboard-usable, plus an optional on-screen keypad (0–9, delete `⌫`, optional
submit key; all keys ≥44 px) shown by default on touch platforms and hidden on
web. `enabled: false` freezes field + keypad while the host shows feedback;
`onSubmit` (optional) is a "done" affordance the host may wire — the field
never evaluates. Used by the typed-answer widgets.

- **Display fields consumed:** none (input only).
- **Value:** the raw digits in the field.

### `equation_solve_widget.dart` — `EquationSolveWidget`

- **Display fields consumed:** `op`, `unknown`, `mode`, `a`, `b`, `c`; for
  `mode: "place_value"` additionally `a_tens`, `a_ones`, `b_tens`, `b_ones`.
- **Rendering:** `unknown: result` → `a op b = ?`; `addend`/`minuend` →
  `? op b = c`; `subtrahend` → `a op ? = c`; `place_value` → decomposed
  operands, e.g. `4 Zehner 3 Einer + 2 Zehner 2 Einer = ?`.
- **Value:** the typed number.

### `equation_gap_widget.dart` — `EquationGapWidget`

- **Display fields consumed:** `form`, `op`, `gap_after`, plus per-form
  `a`/`b`/`c` (gap, missing_addend), `first` (helper, helper_double),
  `total` (any_split, half), `tens`/`ones` (place_value), `n` (neighbor).
- **Rendering:** one gap box at the position `gap_after` indicates
  (`result`/`middle`/`right`) or two (`both`: any_split/half → `? + ? = total`,
  neighbor → `? n ?`).
- **Value formats:** single typed number (gap, helper, missing_addend,
  place_value, double, helper_double); `"i+j"` for any_split only once both
  fields are filled; the number once both `half` fields agree; the first
  filled field for `neighbor`; `""` while incomplete.

### `sequence_gap_widget.dart` — `SequenceGapWidget`

- **Display fields consumed:** `values`, `gap_indices`.
- **Rendering:** the sequence with a blank box at every `gap_indices` slot.
- **Value:** filled values joined `","` in sequence order, `""` until all gaps
  are filled (matches the evaluator's `_evaluateJoined`).

### `compare_symbols_widget.dart` — `CompareSymbolsWidget`

- **Display fields consumed:** `a`, `b`.
- **Rendering:** the two numbers with three large `<` `>` `=` choice buttons.
- **Value:** the chosen operator (`"<"`, `">"`, `"="`), `""` until tapped;
  re-tapping re-picks.

### `strategy_choice_widget.dart` — `StrategyChoiceWidget`

- **Display fields consumed:** `op`, `a`, `b`, `strategies` (id + label_de).
- **Rendering:** `a op b = [result field]`, then a full-width button per
  strategy label; the chosen one is highlighted.
- **Value:** `"result|strategyId"` only once both parts are done (matches the
  evaluator's `_evaluateStrategyChoice`); clearing either part reports `""`.

### `word_problem_widget.dart` — `WordProblemWidget`

- **Display fields consumed:** `prompt_de` (the finished German sentence;
  `display` keeps `setting_de`/`object_de`/`a`/`b`/`op` for provenance only).
- **Rendering:** the story sentence in a readable card.
- **Value:** the typed result number.

## Behaviour shared by every widget

- `didUpdateWidget` resets internal answer state when `problem` changes and
  reports `""` (post-frame), so advancing to the next problem clears input.
- Fields stay editable after a wrong answer (retry): no locking, no submission
  inside the widget.

## Tests (test/template_widgets_test.dart, 21 tests)

**BigAnswerField**
- `reports keypad digit taps and the delete key`
- `reports keyboard typing and the optional submit key`
- `disabled field ignores taps`

**EquationSolveWidget**
- `renders equation and prompt, reports the typed result`
- `empty state reports "" and the field stays editable for retry`
- `place_value mode renders the decomposed operands`
- `a new problem resets the typed value`

**EquationGapWidget**
- `form gap renders the equation and reports the typed number`
- `form missing_addend places the gap in the middle`
- `form any_split reports "i+j" only once both fields are filled`
- `form helper renders the Stützpunkt equation`
- `form place_value renders Zehner and Einer`
- `form half reports the common value only when both gaps agree`

**SequenceGapWidget**
- `reports values joined by commas once every gap is filled`
- `a new problem resets all gap fields`

**CompareSymbolsWidget**
- `renders the numbers and reports the tapped operator`
- `re-picking the operator updates the value`

**StrategyChoiceWidget**
- `reports "result|strategyId" only when both parts are done`
- `re-picking the strategy allows a different choice`

**WordProblemWidget**
- `renders the story sentence and reports the typed result`
- `empty state reports "" and stays editable for retry`

Each group covers renders-without-throwing (asserted via the finds plus a
clean `takeException` path), interaction → expected value, empty/partial →
`""`, and wrong-then-retry editing / re-picking.
