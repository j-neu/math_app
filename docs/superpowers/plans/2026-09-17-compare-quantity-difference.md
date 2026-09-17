# compare_quantity_difference Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `compare_quantity_difference` (BUILD_ORDER.md Batch 1.8, construct `compare_quantity`) playable: a two-step "who has more, and by how much" quantity-comparison task, reused from the retired `S1.4 More or Less (Hamstern)` dice game (`math_app/lib/exercises/more_less_exercise.dart`, `math_app/lib/widgets/more_less_level1_widget.dart`), rebuilt against the v4 `Problem`/`SkillSpec` pipeline as a new `custom_widget` family.

**Architecture:** One new shared stateful core widget (`QuantityCompareCore` in `quantity_compare_common.dart`) implements the interaction once: render two quantities side by side, offer a 3-way "Links mehr / Gleich / Rechts mehr" choice, then (unless "Gleich") a typed-difference field. Three thin wrapper widgets (`quantity_compare_enaktiv/_ikonisch/_symbolisch`) each supply `QuantityCompareCore` a different `buildQuantity` renderer — concrete counter tokens, the existing `ZehnerfeldWidget` ten-frame, and a bare numeral — giving the mandatory 3 EIS levels without three separate copies of the interaction logic. One generator function `_generateQuantityCompare` (registry-dispatched by all three widget keys, following the `doubling_mirror_*`/`count_field_*` precedent of one generator serving a `_enaktiv/_ikonisch/_symbolisch` trio) samples `left`/`right` from `range`, forces a real ~1-in-6 tie rate (matching two six-sided dice), and builds `expected` as a single string — `"gleich"` or `"links,<n>"`/`"rechts,<n>"` — engineered to exactly equal what the widget reports, so the existing default `_evaluateStringMatch` (`_evaluateCustomWidget`'s `default` branch) grades it with zero new evaluator code, exactly like `order_cards`/`numberline_place` before it.

**Tech Stack:** Flutter/Dart (`math_app/`), the v4 skill-spec JSON pipeline, the existing `ZehnerfeldWidget` (`math_app/lib/widgets/manipulatives/zehnerfeld.dart`) and `BigAnswerField` (`math_app/lib/widgets/templates/answer_pad.dart`), Python sync/coverage scripts.

**Spec:** `docs/clean-room/v4/skills/BUILD_ORDER.md` Batch 1.8 (line 55-56) + `docs/superpowers/specs/2026-09-15-exercise-plan-design.md` lines 354-362 (verbatim: "Archetype: Reused — S1.4 More or Less (Hamstern) (more_less_exercise.dart)"; "Manipulative: Dice-roll comparison game (\"Hamstern\")"; "Levels: One level (matches the old exercise, which was intentionally single-level — 10 rounds)"; "Example: Roll two quantities (5 and 8); child states the difference (3) and which is more.") + `docs/skill_spec_authoring_guide.md`.

**Judgment call — single level vs. 3 levels (must be flagged, not silently resolved):** `SkillSpec.fromJson` hard-requires exactly 3 levels numbered 1/2/3 with 3 `level_titles_de` entries (`math_app/lib/models/skill_spec.dart:316-320`, `334-344`) — there is no size-1 escape hatch, and `docs/skill_spec_authoring_guide.md` gives no exception for "intentionally single-level" skills. Neither BUILD_ORDER.md nor the design doc resolves this tension; both simply assert "one level" as a fact about the old exercise without addressing the schema. Per every prior batch's precedent of remapping a design doc's fewer-tier description onto the mandatory 3 EIS levels (documented in-plan each time, e.g. `decompose_single_digit`'s 2-tier design doc split into 3), this plan does the same: it keeps the original mechanic and its `10`-round `problem_count` identical across all 3 levels, and instead scales *representational abstraction* — concrete counters → ten-frame → bare numeral — which is exactly what EIS levels are for. The `10 rounds` becomes `problem_count: 10` (allowed by the `4..12` bound, `skill_spec.dart:209-212`) at every level, and `mastery.correct_of` mirrors the old exercise's `>= 8` bar (`more_less_exercise.dart:100`, ` mastered = ... >= 8`).

**No existing generic template fits.** `compare_symbols` (bare `<`/`>`/`=` on two numbers, `problem_generators.dart:332-362`) has no quantity representation or difference step. `picture_compare` (`problem_generators.dart:1877-1934`) has a `question: 'difference'` mode (ten-frame pair → typed difference) but no "who has more" pick step, no tie handling, and no dice/enaktiv tier. Neither implements the combined two-step "pick winner, then quantify the gap" judgment the old exercise trained. Confirmed via direct code read, not assumption.

## Global Constraints

- German UI only: "Links mehr", "Gleich", "Rechts mehr" button labels; no English strings.
- `domain` is `"C"` (Rechenstrategien, "Comparison and the power of 5" subsection, `docs/superpowers/specs/2026-09-15-exercise-plan-design.md:354`).
- `problem_count: 10` / `mastery.correct_of: 8` at every level (matches the old exercise's own 10-round, 8-correct bar exactly).
- `error_taxonomy` is `other` alone: `expected` is always a single joined string via the default string-match path; none of the `_candidateErrorCode` special cases (`sign_error`, `miscount`, `wrong_direction`, `wrong_order`) apply to this shape.
- Never hand-edit `math_app/assets/skill_specs/*.json`.
- `kKnownCustomWidgets` (`math_app/lib/models/skill_spec.dart`) must gain `quantity_compare_enaktiv`, `quantity_compare_ikonisch`, `quantity_compare_symbolisch`.
- `ZehnerfeldWidget`'s frame is hard-capped at 10 cells (fixed 5x2 grid, indices 0-9, `math_app/lib/widgets/manipulatives/zehnerfeld.dart`) — the ikonisch level's `range` must stay within `[1, 10]` by construction; the generator does not clamp it.
- Widget report strings use lowercase `links`/`rechts`/`gleich` verbatim so they equality-match `normalizeAnswer`'s output (trim + whitespace-collapse only, no case-folding, `math_app/lib/services/answer_normalization.dart`).

---

## Task 1: Shared interaction core + 3 representation widgets

**Files:**
- Create: `math_app/lib/widgets/templates/quantity_compare_common.dart`
- Create: `math_app/lib/widgets/templates/quantity_compare_enaktiv_widget.dart`
- Create: `math_app/lib/widgets/templates/quantity_compare_ikonisch_widget.dart`
- Create: `math_app/lib/widgets/templates/quantity_compare_symbolisch_widget.dart`
- Test: `math_app/test/template_widgets_test.dart`

**Interfaces:**
- Consumes: `Problem` (`display['left']`, `display['right']` as `int`), `BigAnswerField` (`answer_pad.dart`), `ZehnerfeldWidget` (`zehnerfeld.dart`).
- Produces: `QuantityCompareCore({required Problem problem, required ValueChanged<String> onValueChanged, required Widget Function(BuildContext, int) buildQuantity})`; `QuantityCompareEnaktivWidget`, `QuantityCompareIkonischWidget`, `QuantityCompareSymbolischWidget`, each `({required Problem problem, required ValueChanged<String> onValueChanged})` — the standard template-widget constructor shape every other `templates/*_widget.dart` file uses.

- [ ] **Step 1: Write `quantity_compare_common.dart`.**

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'answer_pad.dart';

/// Shared interaction core for the `quantity_compare_*` custom widgets
/// (compare_quantity_difference, BUILD_ORDER.md Batch 1.8): renders two
/// quantities via [buildQuantity], offers a three-way "wer hat mehr"
/// choice, then -- unless the choice is "gleich" -- a typed-difference
/// field. Reports the joined answer string the generator's `expected` is
/// built to match exactly: `"gleich"`, or `"links,<n>"` / `"rechts,<n>"`.
class QuantityCompareCore extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final Widget Function(BuildContext context, int value) buildQuantity;

  const QuantityCompareCore({
    super.key,
    required this.problem,
    required this.onValueChanged,
    required this.buildQuantity,
  });

  @override
  State<QuantityCompareCore> createState() => _QuantityCompareCoreState();
}

class _QuantityCompareCoreState extends State<QuantityCompareCore> {
  String? _winner;
  final TextEditingController _controller = TextEditingController();

  int get _left => (widget.problem.display['left'] as int?) ?? 0;
  int get _right => (widget.problem.display['right'] as int?) ?? 0;

  @override
  void didUpdateWidget(covariant QuantityCompareCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _winner = null;
      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pick(String winner) {
    setState(() => _winner = winner);
    widget.onValueChanged(winner == 'gleich' ? 'gleich' : '');
  }

  void _submitDifference(String text) {
    if (_winner == null || _winner == 'gleich') return;
    widget.onValueChanged(text.isEmpty ? '' : '$_winner,$text');
  }

  Widget _choiceButton(String label, String value) {
    final isSelected = _winner == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        key: ValueKey('qc-choice-$value'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.indigo : null,
          foregroundColor: isSelected ? Colors.white : null,
        ),
        onPressed: () => _pick(value),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.buildQuantity(context, _left),
              const SizedBox(width: 28),
              widget.buildQuantity(context, _right),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _choiceButton('Links mehr', 'links'),
            _choiceButton('Gleich', 'gleich'),
            _choiceButton('Rechts mehr', 'rechts'),
          ],
        ),
        if (_winner != null && _winner != 'gleich') ...[
          const SizedBox(height: 16),
          BigAnswerField(
            key: const ValueKey('qc-diff-field'),
            controller: _controller,
            onChanged: _submitDifference,
            hintText: '?',
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 2: Write `quantity_compare_enaktiv_widget.dart`** — concrete tokens ("Plättchen"), one circle per unit, wrapped in a row, `key: ValueKey('qc-token-$value-$i')` per token:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'quantity_compare_common.dart';

/// Enaktiv tier of `compare_quantity_difference` (Batch 1.8): each quantity
/// is rendered as that many loose round counters ("Plättchen"), directly
/// countable one by one -- the most concrete of the 3 representations.
class QuantityCompareEnaktivWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const QuantityCompareEnaktivWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  static Widget _tokens(BuildContext context, int value) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < value; i++)
          Container(
            key: ValueKey('qc-token-$value-$i'),
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.indigo,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuantityCompareCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildQuantity: _tokens,
    );
  }
}
```

- [ ] **Step 3: Write `quantity_compare_ikonisch_widget.dart`** — reuses `ZehnerfeldWidget` (ten-frame, already used by `picture_compare_widget.dart`):

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../manipulatives/zehnerfeld.dart';
import 'quantity_compare_common.dart';

/// Ikonisch tier of `compare_quantity_difference` (Batch 1.8): each
/// quantity is rendered as a `ZehnerfeldWidget` ten-frame -- structured
/// (5+5), semi-abstract, capped at 10.
class QuantityCompareIkonischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const QuantityCompareIkonischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  static Widget _frame(BuildContext context, int value) {
    return ZehnerfeldWidget(filled: {for (var i = 0; i < value; i++) i});
  }

  @override
  Widget build(BuildContext context) {
    return QuantityCompareCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildQuantity: _frame,
    );
  }
}
```

- [ ] **Step 4: Write `quantity_compare_symbolisch_widget.dart`** — bare numeral, no visual aid:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'quantity_compare_common.dart';

/// Symbolisch tier of `compare_quantity_difference` (Batch 1.8): each
/// quantity is shown as a bare numeral -- no counters, no frame -- the
/// most abstract of the 3 representations.
class QuantityCompareSymbolischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const QuantityCompareSymbolischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  static Widget _numeral(BuildContext context, int value) {
    return Container(
      key: ValueKey('qc-numeral-$value'),
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$value', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuantityCompareCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildQuantity: _numeral,
    );
  }
}
```

- [ ] **Step 5: Add widget tests to `template_widgets_test.dart`** covering, per representation (enaktiv suffices for the interaction; ikonisch/symbolisch each get one smoke test for their renderer):
  - Tapping "Links mehr" then typing a difference reports `"links,<n>"`.
  - Tapping "Gleich" reports `"gleich"` immediately, no difference field shown.
  - A new problem (`didUpdateWidget` with a different `Problem`) resets the choice and reports `""`.
  - Ikonisch: `ZehnerfeldWidget` renders with the right number of filled cells for `left`/`right`.
  - Symbolisch: the numeral `Text` for `left`/`right` renders.

- [ ] **Step 6: Run** `flutter test test/template_widgets_test.dart` — PASS.
- [ ] **Step 7: Commit** — `feat(quantity_compare): add the shared interaction core and 3 representation widgets`.

---

## Task 2: Generator, registry wiring, kKnownCustomWidgets

**Files:**
- Modify: `math_app/lib/models/skill_spec.dart` (`kKnownCustomWidgets`)
- Modify: `math_app/lib/practice/problem_generators.dart` (`_generateCustomWidget` switch + new `_generateQuantityCompare`)
- Modify: `math_app/lib/practice/template_registry.dart` (widget dispatch)
- Test: `math_app/test/problem_generators_test.dart`

- [ ] **Step 1: Add the 3 keys to `kKnownCustomWidgets`** in `skill_spec.dart`: `quantity_compare_enaktiv`, `quantity_compare_ikonisch`, `quantity_compare_symbolisch`.

- [ ] **Step 2: Add `_generateQuantityCompare`** to `problem_generators.dart` and wire it into `_generateCustomWidget`'s switch (all 3 keys map to it, following the `doubling_mirror_*` precedent):

```dart
case 'quantity_compare_enaktiv':
case 'quantity_compare_ikonisch':
case 'quantity_compare_symbolisch':
  return _generateQuantityCompare(spec, level, levelNumber, seed, index, gen);
```

```dart
/// Registry keys `"quantity_compare_enaktiv"` / `"_ikonisch"` /
/// `"_symbolisch"` (compare_quantity_difference, BUILD_ORDER.md Batch 1.8):
/// reuses the retired `more_less_exercise.dart`'s two-step "who has more,
/// then by how much" dice-comparison judgment, rebuilt against the v4
/// pipeline as three EIS-scaled representations of the same task (the
/// source material was itself explicitly single-level, but the v4 schema
/// requires exactly 3 levels -- see the plan's judgment-call note).
/// `left`/`right` are sampled from `range`; a roughly 1-in-6 draw ties them
/// (matching two real d6 dice, P(tie) = 6/36), the rest are forced
/// distinct. `expected` is a single string exactly matching what the
/// widget reports -- `"gleich"`, or `"links,<n>"`/`"rechts,<n>"` -- so the
/// default `_evaluateStringMatch` grades it with no new evaluator code.
Problem _generateQuantityCompare(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final range = level.intListParam('range');
  final lo = range.isEmpty ? 1 : range[0];
  final hi = range.isEmpty ? 6 : range[1];
  if (lo > hi) {
    throw SpecFormatException('quantity_compare: range [$lo, $hi] is empty');
  }

  final left = gen.nextIntInRange(lo, hi);
  int right;
  if (lo == hi) {
    right = left;
  } else if (gen.nextIntInRange(1, 6) == 1) {
    right = left;
  } else {
    right = gen.nextIntInRange(lo, hi);
    while (right == left) {
      right = gen.nextIntInRange(lo, hi);
    }
  }

  final String expected;
  if (left == right) {
    expected = 'gleich';
  } else if (left > right) {
    expected = 'links,${left - right}';
  } else {
    expected = 'rechts,${right - left}';
  }

  return Problem(
    template: 'custom_widget',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {
      'custom_widget': level.customWidget,
      'left': left,
      'right': right,
    },
    expected: [expected],
  );
}
```

- [ ] **Step 3: Wire the 3 widgets into `template_registry.dart`'s `custom_widget` switch**, importing all 3 new widget files, following the existing `case 'count_field_enaktiv': return CountFieldEnaktivWidget(...)` pattern verbatim.

- [ ] **Step 4: Add generator unit tests to `problem_generators_test.dart`** (in the `custom_widget generators (P2 §5 registry)` group): for a synthetic spec/level with `range: [1, 6]`, run 200 seeds and assert: `left`/`right` in range; `expected.length == 1`; the single expected string is `'gleich'` iff `left == right`, else `'links,<diff>'`/`'rechts,<diff>'` with the correct side and a positive `diff`; across 200 seeds at least one tie and at least one non-tie occur (statistical sanity, not exact-probability).

- [ ] **Step 5: Run** `flutter test test/problem_generators_test.dart` — PASS.
- [ ] **Step 6: Commit** — `feat(quantity_compare): add the generator and wire the widget registry`.

---

## Task 3: compare_quantity_difference spec JSON + store test

**Files:**
- Create: `docs/clean-room/v4/skills/specs/compare_quantity_difference.json`
- Test: `math_app/test/skill_spec_store_test.dart`

- [ ] **Step 1: Write the spec JSON.**

```json
{
  "spec_version": 1,
  "skill_id": "compare_quantity_difference",
  "construct_id": "compare_quantity",
  "domain": "C",
  "title_de": "Mengen vergleichen und den Unterschied bestimmen",
  "level_titles_de": [
    "Plättchen vergleichen (ZR6)",
    "Zehnerfelder vergleichen (ZR10)",
    "Zahlen vergleichen (ZR10)"
  ],
  "levels": [
    {
      "level": 1,
      "representation": "enaktiv",
      "template": "custom_widget",
      "custom_widget": "quantity_compare_enaktiv",
      "params": { "range": [1, 6] },
      "problem_count": 10,
      "prompt_de": "Wer hat mehr? Wie viele mehr?",
      "slow_band_ms": 12000
    },
    {
      "level": 2,
      "representation": "ikonisch",
      "template": "custom_widget",
      "custom_widget": "quantity_compare_ikonisch",
      "params": { "range": [1, 10] },
      "problem_count": 10,
      "prompt_de": "Wer hat mehr? Wie viele mehr?",
      "slow_band_ms": 10000
    },
    {
      "level": 3,
      "representation": "symbolisch",
      "template": "custom_widget",
      "custom_widget": "quantity_compare_symbolisch",
      "params": { "range": [1, 10] },
      "problem_count": 10,
      "prompt_de": "Wer hat mehr? Wie viele mehr?",
      "slow_band_ms": 8000
    }
  ],
  "mastery": { "correct_of": 8 },
  "error_taxonomy": [
    { "code": "other", "label_de": "noch einmal probieren", "hint_de": "Vergleiche die beiden Mengen genau. Welche ist größer, und um wie viel?" }
  ],
  "provenance": {
    "sources": ["iMINT S1.4 More or Less (Hamstern)", "Padberg/Benz, Vergleichen und Ordnen von Anzahlen"],
    "author": "Claude (domain author)",
    "reviewed_by": "open"
  }
}
```

- [ ] **Step 2: Add the store test** asserting `constructId == 'compare_quantity'`, `domain == 'C'`, `problemCount == 10` for all 3 levels, and `customWidget` sequence `['quantity_compare_enaktiv', 'quantity_compare_ikonisch', 'quantity_compare_symbolisch']`.
- [ ] **Step 3: Add a generator test using `_realSpec('compare_quantity_difference')`** — 3 levels x 100 seeds: `left`/`right` within that level's range, `expected` well-formed per the rules above.
- [ ] **Step 4: Run** `flutter test test/skill_spec_store_test.dart test/problem_generators_test.dart` — PASS.
- [ ] **Step 5: Commit** — `feat(compare_quantity_difference): add v4 skill spec using the new quantity_compare widgets`.

---

## Task 4: Sync, coverage, BUILD_ORDER, full suite, flutter analyze

**Files:**
- Modify: `math_app/assets/skill_specs/compare_quantity_difference.json` (generated)
- Modify: `docs/clean-room/v4/skills/BUILD_ORDER.md`

- [ ] **Step 1: Sync** — `python scripts/sync_skill_specs.py`, expect `20 skill specs`.
- [ ] **Step 2: Coverage check** — `python scripts/check_skill_spec_coverage.py`, expect `20/93`.
- [ ] **Step 3: Update BUILD_ORDER.md`** — check off Batch 1.8's line with `shipped, docs/superpowers/plans/2026-09-17-compare-quantity-difference.md`, add to `## Done`, correct the trailing count to "these twenty."
- [ ] **Step 4: Run the full Flutter test suite** — expect PASS (~655+, up from 645).
- [ ] **Step 5: Run `flutter analyze`** — expect no new issues beyond the 341 baseline.
- [ ] **Step 6: Commit** — `chore(compare_quantity_difference): sync spec assets, mark Batch 1.8 done in BUILD_ORDER`.

---

## Self-Review Notes

- **Spec coverage:** `compare_quantity_difference` fully covered: interaction (Task 1), generation/evaluation (Task 2), spec authoring (Task 3), integration (Task 4).
- **Placeholder scan:** none.
- **Single-level-vs-3-level tension:** explicitly flagged and resolved by representational scaling rather than silently inventing a difficulty axis the source material never had — see the "Judgment call" section above. This is the first batch this session where the design doc's own stated level count (1) conflicts with the schema's hard requirement (3), as opposed to merely being coarser than 3 (2-tier docs remapped in prior batches).
- **Type consistency:** `QuantityCompareCore`'s constructor signature (`problem`, `onValueChanged`, `buildQuantity`) is used identically by all 3 wrapper widgets in Task 1 and referenced nowhere else; `_generateQuantityCompare`'s `Problem.display` keys (`left`, `right`) match exactly what `QuantityCompareCore` reads in Task 1's `_left`/`_right` getters.
- **Reused infrastructure confirmed by direct code read, not assumption:** `ZehnerfeldWidget` (10-cell cap confirmed), `BigAnswerField`, `SeededGenerator.nextIntInRange` (confirmed inclusive-inclusive), `normalizeAnswer` (confirmed no case-folding, so lowercase `links`/`rechts`/`gleich` round-trip exactly), the `_evaluateCustomWidget` default branch (confirmed unknown-widget-name fallthrough to `_evaluateStringMatch`).
