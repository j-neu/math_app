# Batch 1.12 — Tens Arithmetic (`tens_add_tens`, `tens_sub_tens`, `tens_sub_crossing_hundred`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the 3 skills of `docs/clean-room/v4/skills/BUILD_ORDER.md` Batch 1.12 (construct `tens_add_sub`) — `tens_add_tens`, `tens_sub_tens`, `tens_sub_crossing_hundred` — completing Tier 1 (Reused) except Batch 1.13.

**Architecture:** Two new custom-widget families (`tens_add_*`, `tens_sub_*`), each with a shared stateless-composition "core" widget (mirroring the existing `quantity_compare_common.dart` pattern) plus 3 thin per-tier widgets (enaktiv/ikonisch/symbolisch). Two new generator functions in `problem_generators.dart` compute decade-number operands (`a`, `b` are the actual numbers, e.g. 30/40, never a raw "tens count"). `tens_sub_tens` and `tens_sub_crossing_hundred` share the *same* 3 widgets and the *same* generator, differing only in their `tens_a_range`/`tens_b_range` params — exactly like `double_zr10`/`double_zr10_to_zr20` already share `doubling_mirror_*` over disjoint ranges.

**Tech Stack:** Flutter/Dart, the v4 skill-spec pipeline (`SkillSpec`/`SkillSpecStore`/`template_registry`/`template_evaluator`/`problem_generators`), `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-09-15-exercise-plan-design.md` (§3 tier tally, §5 archetype details for `tens_add_tens`/`tens_sub_tens`/`tens_sub_crossing_hundred`), `docs/skill_spec_authoring_guide.md` (the authoring checklist), `math_app/Research/skills_taxonomy.csv` (lines 54-56, the 3 skill_ids' canonical German/English titles and descriptions).

## Global Constraints

- **Exactly 3 levels per spec**, `representation` values `"enaktiv"`, `"ikonisch"`, `"symbolisch"` in that order — `SkillSpec` parsing hard-rejects anything else (`math_app/lib/models/skill_spec.dart:344-351`).
- **Port, don't refactor** (`docs/skill_spec_authoring_guide.md`): the old exercise family (`math_app/lib/exercises/tens_calculation_exercise.dart`, `math_app/lib/widgets/tens_calculation_level{1,2,3,4}_widget.dart`) stays completely untouched. New widgets are fresh files with an adapted contract, not edits to the old ones. The one exception is `math_app/lib/widgets/common/ten_strip_widget.dart` — that is a *shared manipulative* (like `RechenschiffchenWidget`/`ZehnerfeldWidget`), imported directly and unmodified, not "ported".
- **Enter-key submission convention**: every new widget's final answer field wires `VoidCallback? onSubmit` through to `TextField`/`BigAnswerField`'s `onSubmitted`, exactly like every other custom widget shipped this project.
- **Centrally-graded architecture**: the final numeric answer is always reported live via `onValueChanged` and graded by `TemplateEvaluator` against `problem.expected` — no widget self-grades with its own button. `expected` is always the *actual arithmetic result* (e.g. `"70"`), never a raw "tens count" (e.g. `"7"`) — matching the `double_decade` precedent (`docs/superpowers/plans/2026-09-19-double-zr10-to-zr20-crossing10-decade.md`).
- **error_taxonomy**: every spec needs `{"code": "other", ...}` at minimum. This batch's generators are the *first* custom-widget generators in the project to put `op`/`a`/`b` (all ints) into `problem.display` — `TemplateEvaluator._candidateErrorCode` (`math_app/lib/practice/template_evaluator.dart:365-379`) already detects a flipped operation from exactly those 3 fields and returns `"sign_error"` (e.g. child answered `70` for `100 - 20`, i.e. `a + b` instead of `a - b`). Both new specs include `"sign_error"` in `error_taxonomy` alongside `"other"`. Do **not** invent a directional `off_by_one_low/high` code — `_candidateErrorCode` cannot emit one (documented past mistake in `double_zr10`/`halve_zr10`).
- **No deprecated Flutter APIs in new code**: use `Color.withValues(alpha: x)`, never `Color.withOpacity(x)`. (This batch's widgets don't need `DragTarget` at all, so the `onWillAccept`/`onAccept` deprecation doesn't come up — just don't introduce it.)
- **`SeededGenerator.nextIntInRange(int min, int max)`** (inclusive) and `LevelSpec.intParam`/`intListParam`/`stringParam` are the only allowed sources of randomness/params — no hand-rolled `Random()`, no reading params any other way.
- Every new generator function must validate its params and `throw SpecFormatException(...)` on an invalid range, matching every existing custom-widget generator's style (see `_generateDoublingBoat`, `math_app/lib/practice/problem_generators.dart:2351-2367`).

---

## Design Notes (read before Task 1)

**Why decade numbers, not tens-counts, in `display`:** the old widgets asked "wie viele Zehner?" (a tens-*count*, e.g. `7`). This project's established convention (set by `double_decade`) is that the *typed final answer* is always the real number the child would say out loud — `70`, not `7`. So `display['a']`/`display['b']`/`expected` all carry actual decade numbers (30, 40, 100, ...); each widget divides by 10 locally only where it needs to know *how many* rods/chips to draw.

**Why a shared "Core" widget per family:** `math_app/lib/widgets/templates/quantity_compare_common.dart` already established this exact pattern for a Tier-1-Reused, 3-tier-by-visual-fidelity skill: one `StatefulWidget` ("Core") owns the text field, the `didUpdateWidget` reset-on-new-problem logic, and layout; each of the 3 concrete widgets is a thin `StatelessWidget` that supplies a `buildX` callback rendering that tier's picture. This batch reuses that shape for both new families.

**Why `tens_sub_enaktiv` is a standalone widget, not built on a shared core:** its interaction (tap a rod to cross it out, mirroring the old `TensCalculationLevel2Widget`) is genuinely different in kind from the static pictures `tens_sub_ikonisch`/`tens_sub_symbolisch` show — it needs its own mutable "which rods are crossed" state. `tens_sub_ikonisch` and `tens_sub_symbolisch` share `TensSubCore` (both are pure, static views).

**Why `tens_add` needs no such standalone/interactive tier:** the old `TensCalculationLevel1Widget` (visual add) had no interaction beyond viewing two groups and typing a number — there is nothing to "act on" the way crossing out a rod acts on a subtraction. All 3 `tens_add_*` tiers share `TensAddCore`.

**Why one generator serves two skills for `tens_sub_*`:** `tens_sub_tens` (`tens_a_range: [2,9]`) and `tens_sub_crossing_hundred` (`tens_a_range: [10,10]`, i.e. `a` fixed at 100) are the same arithmetic shape over disjoint `a` ranges — exactly the `double_zr10`/`double_zr10_to_zr20` sharing pattern. `_generateTensSub` uses the already-existing `_clampedDraw` helper (`math_app/lib/practice/problem_generators.dart:366-369`, currently used by `equation_solve`'s `place_value` mode) so `tensB` never exceeds the drawn `tensA` — this guarantees a non-negative result for both skills with zero new helper code.

**Params reference (used verbatim in Task 1-3's specs):**
- `tens_add_*`: `{"tens_a_range": [loA, hiA], "sum_max": N}` → `tensA = nextIntInRange(loA, hiA)`, `tensB = nextIntInRange(1, N - tensA)`, `a = tensA*10`, `b = tensB*10`, `target = a + b`. Validity: `1 <= loA <= hiA <= sumMax - 1` and `2 <= sumMax <= 9`.
- `tens_sub_*`: `{"tens_a_range": [loA, hiA], "tens_b_range": [loB, hiB]}` → `tensA = nextIntInRange(loA, hiA)`, `tensB = clampedDraw(loB, hiB, outer: tensA)`, `a = tensA*10`, `b = tensB*10`, `target = a - b`. Validity: `1 <= loA <= hiA <= 10` and `1 <= loB <= hiB <= 10` (10 tens = 100, the family's ceiling).

---

### Task 1: `tens_add_tens` — widget family, generator, registry wiring, spec, tests

**Files:**
- Create: `math_app/lib/widgets/templates/tens_add_common.dart`
- Create: `math_app/lib/widgets/templates/tens_add_enaktiv_widget.dart`
- Create: `math_app/lib/widgets/templates/tens_add_ikonisch_widget.dart`
- Create: `math_app/lib/widgets/templates/tens_add_symbolisch_widget.dart`
- Create: `docs/clean-room/v4/skills/specs/tens_add_tens.json`
- Modify: `math_app/lib/models/skill_spec.dart` (add 3 keys to `kKnownCustomWidgets`)
- Modify: `math_app/lib/practice/template_registry.dart` (3 imports + 3 switch arms)
- Modify: `math_app/lib/practice/problem_generators.dart` (new `_generateTensAdd`, 3 switch cases)
- Modify: `math_app/test/problem_generators_test.dart` (2 tests)
- Modify: `math_app/test/skill_spec_store_test.dart` (1 test)
- Modify: `math_app/test/template_widgets_test.dart` (3 widget-test groups)

**Interfaces:**
- Consumes: `TenStripWidget({Color color, double width, double height, bool isMarked})` (`math_app/lib/widgets/common/ten_strip_widget.dart`, unmodified). `BigAnswerField({required TextEditingController controller, required ValueChanged<String> onChanged, VoidCallback? onSubmit, String? hintText})` (`math_app/lib/widgets/templates/answer_pad.dart`, unmodified). `SeededGenerator.nextIntInRange(int, int)`, `LevelSpec.intParam(String key, {required int fallback})`, `LevelSpec.intListParam(String key)` (`math_app/lib/models/skill_spec.dart`). `SpecFormatException` (`math_app/lib/models/skill_spec.dart`). `Problem` constructor (`math_app/lib/models/problem.dart`) with named params `template, skillId, level, seed, index, promptDe, display, expected` — see any existing generator (e.g. `_generateDoublingMirror`, `math_app/lib/practice/problem_generators.dart:2312-2340`) for exact usage.
- Produces: `TensAddCore` widget (`math_app/lib/widgets/templates/tens_add_common.dart`) with constructor `TensAddCore({required Problem problem, required ValueChanged<String> onValueChanged, required Widget Function(BuildContext, int tensCount) buildGroup, VoidCallback? onSubmit})` — Task 2 does **not** consume this (the `tens_sub` family has its own core), but Task 3 (which only adds a new spec, reusing Task 2's widgets) has no dependency on Task 1 either. Registry keys `'tens_add_enaktiv'`, `'tens_add_ikonisch'`, `'tens_add_symbolisch'` in `kKnownCustomWidgets` and `template_registry.dart`'s `custom_widget` switch. Generator function `_generateTensAdd(SkillSpec, LevelSpec, int, int, int, SeededGenerator) -> Problem`, dispatched from `_generateCustomWidget`'s switch for those same 3 keys.

- [ ] **Step 1: Write the shared `TensAddCore` widget**

Create `math_app/lib/widgets/templates/tens_add_common.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'answer_pad.dart';

/// Shared interaction core for the `tens_add_*` custom widgets
/// (tens_add_tens, BUILD_ORDER.md Batch 1.12): renders the two decade
/// addends via [buildGroup] (called once per addend with its *tens count*,
/// e.g. 3 for the addend 30), then a single field for the typed sum --
/// reported live via [onValueChanged], graded centrally like every other
/// custom_widget. Mirrors the `QuantityCompareCore` pattern
/// (quantity_compare_common.dart, BUILD_ORDER.md Batch 1.8).
class TensAddCore extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final Widget Function(BuildContext context, int tensCount) buildGroup;
  final VoidCallback? onSubmit;

  const TensAddCore({
    super.key,
    required this.problem,
    required this.onValueChanged,
    required this.buildGroup,
    this.onSubmit,
  });

  @override
  State<TensAddCore> createState() => _TensAddCoreState();
}

class _TensAddCoreState extends State<TensAddCore> {
  final TextEditingController _controller = TextEditingController();

  int get _a => (widget.problem.display['a'] as num).toInt();
  int get _b => (widget.problem.display['b'] as num).toInt();

  @override
  void didUpdateWidget(covariant TensAddCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$_a + $_b = ?',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.buildGroup(context, _a ~/ 10),
              const SizedBox(width: 20),
              const Icon(Icons.add, size: 32),
              const SizedBox(width: 20),
              widget.buildGroup(context, _b ~/ 10),
            ],
          ),
        ),
        const SizedBox(height: 24),
        BigAnswerField(
          controller: _controller,
          onChanged: widget.onValueChanged,
          onSubmit: widget.onSubmit,
          hintText: '?',
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Write the 3 `tens_add_*` tier widgets**

Create `math_app/lib/widgets/templates/tens_add_enaktiv_widget.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../common/ten_strip_widget.dart';
import 'tens_add_common.dart';

/// Enaktiv tier of `tens_add_tens` (BUILD_ORDER.md Batch 1.12): each decade
/// addend is rendered as that many actual ten-rods (`TenStripWidget`,
/// math_app/lib/widgets/common/ten_strip_widget.dart -- a shared
/// manipulative, imported unmodified). Visual layout ported from the old
/// engine's `TensCalculationLevel1Widget._buildGroup`
/// (math_app/lib/widgets/tens_calculation_level1_widget.dart, untouched) --
/// fresh copy, adapted contract, no self-grading.
class TensAddEnaktivWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const TensAddEnaktivWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  static Widget _rods(BuildContext context, int tensCount) {
    return Wrap(
      spacing: 4,
      children: [
        for (var i = 0; i < tensCount; i++)
          TenStripWidget(
            key: ValueKey('tens-add-rod-$tensCount-$i'),
            color: Colors.blue,
            width: 15,
            height: 100,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return TensAddCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildGroup: _rods,
      onSubmit: onSubmit,
    );
  }
}
```

Create `math_app/lib/widgets/templates/tens_add_ikonisch_widget.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'tens_add_common.dart';

/// Ikonisch tier of `tens_add_tens` (BUILD_ORDER.md Batch 1.12): each
/// decade addend is rendered as that many compact "10er" chips (a picture
/// standing for one ten, not an actual counted-out rod) -- less concrete
/// than the enaktiv tier's rods, more concrete than the symbolisch tier's
/// bare numeral.
class TensAddIkonischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const TensAddIkonischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  static Widget _chips(BuildContext context, int tensCount) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < tensCount; i++)
          Container(
            key: ValueKey('tens-add-chip-$tensCount-$i'),
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade400, width: 2),
            ),
            child: const Text('10', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return TensAddCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildGroup: _chips,
      onSubmit: onSubmit,
    );
  }
}
```

Create `math_app/lib/widgets/templates/tens_add_symbolisch_widget.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'tens_add_common.dart';

/// Symbolisch tier of `tens_add_tens` (BUILD_ORDER.md Batch 1.12): each
/// decade addend is shown as a bare boxed numeral (e.g. "30") -- no rods,
/// no chips -- the most abstract of the 3 representations.
class TensAddSymbolischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const TensAddSymbolischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  static Widget _numeral(BuildContext context, int tensCount) {
    final value = tensCount * 10;
    return Container(
      key: ValueKey('tens-add-numeral-$value'),
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value',
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TensAddCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildGroup: _numeral,
      onSubmit: onSubmit,
    );
  }
}
```

- [ ] **Step 3: Register the 3 new keys in `kKnownCustomWidgets`**

In `math_app/lib/models/skill_spec.dart`, find the `kKnownCustomWidgets` set (ends with `'doubling_tens_symbolisch',` followed by `};`). Add 3 lines right before the closing `};`:

```dart
  'doubling_tens_enaktiv',
  'doubling_tens_ikonisch',
  'doubling_tens_symbolisch',
  'tens_add_enaktiv',
  'tens_add_ikonisch',
  'tens_add_symbolisch',
};
```

- [ ] **Step 4: Wire the 3 new widgets into `template_registry.dart`**

In `math_app/lib/practice/template_registry.dart`, add 3 import lines after the existing `doubling_tens_symbolisch_widget.dart` import:

```dart
import '../widgets/templates/doubling_tens_symbolisch_widget.dart';
import '../widgets/templates/tens_add_enaktiv_widget.dart';
import '../widgets/templates/tens_add_ikonisch_widget.dart';
import '../widgets/templates/tens_add_symbolisch_widget.dart';
```

Then, in the `custom_widget` switch (the same one containing `'quantity_compare_symbolisch' => QuantityCompareSymbolischWidget(...)`), add 3 arms immediately before the final `_ => const _UnavailableTemplateWidget(),` line of that inner switch:

```dart
      'quantity_compare_symbolisch' => QuantityCompareSymbolischWidget(
          problem: problem,
          onValueChanged: onValueChanged,
          onSubmit: onSubmit,
        ),
      'tens_add_enaktiv' => TensAddEnaktivWidget(
          problem: problem,
          onValueChanged: onValueChanged,
          onSubmit: onSubmit,
        ),
      'tens_add_ikonisch' => TensAddIkonischWidget(
          problem: problem,
          onValueChanged: onValueChanged,
          onSubmit: onSubmit,
        ),
      'tens_add_symbolisch' => TensAddSymbolischWidget(
          problem: problem,
          onValueChanged: onValueChanged,
          onSubmit: onSubmit,
        ),
      _ => const _UnavailableTemplateWidget(),
```

- [ ] **Step 5: Write the failing generator test**

In `math_app/test/problem_generators_test.dart`, inside `group('custom_widget generators (P2 §5 registry)', () { ... })` (the one whose local `spec(key, params)` helper builds a single-level `custom_widget` spec — see the existing `doubling_boat_enaktiv` test right above for the exact pattern), add:

```dart
    test('tens_add_enaktiv: a/b are decade numbers, expected == a+b, '
        'op == "+"', () {
      final s = spec('tens_add_enaktiv', {
        'tens_a_range': [1, 5],
        'sum_max': 9,
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          expect(a % 10, 0, reason: 'a is a decade number');
          expect(b % 10, 0, reason: 'b is a decade number');
          expect(a ~/ 10, inInclusiveRange(1, 5));
          expect(b ~/ 10, greaterThanOrEqualTo(1));
          expect(a ~/ 10 + b ~/ 10, lessThanOrEqualTo(9));
          expect(p.display['op'], '+');
          expect(p.expected, ['${a + b}']);
          expect(p.display['custom_widget'], 'tens_add_enaktiv');
        }
      }
    });

    test('tens_add: tens_a_range that cannot leave room under sum_max '
        'throws', () {
      final s = spec('tens_add_enaktiv', {
        'tens_a_range': [1, 9],
        'sum_max': 9,
      });
      expect(
        () => generateProblems(spec: s, level: 2, seed: 0),
        throwsA(isA<SpecFormatException>()),
      );
    });
```

- [ ] **Step 6: Run the test to verify it fails**

Run: `cd math_app && flutter test test/problem_generators_test.dart --plain-name "tens_add"`
Expected: FAIL — `_generateTensAdd` and the `'tens_add_enaktiv'` case in `_generateCustomWidget`'s switch don't exist yet, so the default branch throws `SpecFormatException('custom_widget: unknown registry key "tens_add_enaktiv"')`. The *second* test (which expects exactly that exception) will actually pass already; the first will fail because `p.display['a']` etc. don't exist. Confirm the first test fails.

- [ ] **Step 7: Implement `_generateTensAdd` and wire it into the dispatch switch**

In `math_app/lib/practice/problem_generators.dart`, find `_generateCustomWidget`'s switch (the one with `case 'doubling_tens_enaktiv': case 'doubling_tens_ikonisch': case 'doubling_tens_symbolisch': return _generateDoublingTens(...);`). Add a new case group right after it, before `case 'halving_mirror_enaktiv':`:

```dart
    case 'doubling_tens_enaktiv':
    case 'doubling_tens_ikonisch':
    case 'doubling_tens_symbolisch':
      return _generateDoublingTens(spec, level, levelNumber, seed, index, gen);
    case 'tens_add_enaktiv':
    case 'tens_add_ikonisch':
    case 'tens_add_symbolisch':
      return _generateTensAdd(spec, level, levelNumber, seed, index, gen);
    case 'halving_mirror_enaktiv':
```

Then add the generator function itself anywhere among the other `_generateX` functions (e.g. right after `_generateDoublingTens`'s closing `}`):

```dart
/// Registry keys `"tens_add_enaktiv"`, `"tens_add_ikonisch"`,
/// `"tens_add_symbolisch"` (tens_add_tens, BUILD_ORDER.md Batch 1.12):
/// draws two decade addends `a`/`b` (each a multiple of 10) whose tens
/// digits sum to at most `sum_max`, so the total never reaches 3 digits.
/// `display` carries `op: "+"` plus the actual `a`/`b` numbers (not their
/// tens counts) so `TemplateEvaluator` can detect a `sign_error`; `expected`
/// holds the summed decade number as a plain string.
Problem _generateTensAdd(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final tensARange = level.intListParam('tens_a_range');
  final sumMax = level.intParam('sum_max', fallback: 9);
  if (tensARange.length != 2) {
    throw SpecFormatException(
      'tens_add: "tens_a_range" must be a 2-element [min, max] list',
    );
  }
  final loA = tensARange[0];
  final hiA = tensARange[1];
  if (loA < 1 || hiA > sumMax - 1 || loA > hiA || sumMax < 2 || sumMax > 9) {
    throw SpecFormatException(
      'tens_add: tens_a_range [$loA, $hiA] / sum_max $sumMax invalid -- '
      'tens_a_range must be within [1, sum_max - 1] and sum_max within '
      '[2, 9]',
    );
  }

  final tensA = gen.nextIntInRange(loA, hiA);
  final tensB = gen.nextIntInRange(1, sumMax - tensA);
  final a = tensA * 10;
  final b = tensB * 10;
  final target = a + b;

  return Problem(
    template: 'custom_widget',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {
      'custom_widget': level.customWidget,
      'op': '+',
      'a': a,
      'b': b,
      'target': target,
    },
    expected: [target.toString()],
  );
}
```

- [ ] **Step 8: Run the test to verify it passes**

Run: `cd math_app && flutter test test/problem_generators_test.dart --plain-name "tens_add"`
Expected: PASS (both tests).

- [ ] **Step 9: Write the spec JSON**

Create `docs/clean-room/v4/skills/specs/tens_add_tens.json`:

```json
{
  "spec_version": 1,
  "skill_id": "tens_add_tens",
  "construct_id": "tens_add_sub",
  "domain": "C",
  "title_de": "Zehnerzahl plus Zehnerzahl",
  "level_titles_de": [
    "Zehner zusammenlegen (Zehnerstreifen)",
    "Zehner zusammenlegen (Bildkarten)",
    "Zehner addieren (im Kopf)"
  ],
  "levels": [
    {
      "level": 1,
      "representation": "enaktiv",
      "template": "custom_widget",
      "custom_widget": "tens_add_enaktiv",
      "params": { "tens_a_range": [1, 5], "sum_max": 9 },
      "problem_count": 8,
      "prompt_de": "Wie viel sind die Zehnerstreifen zusammen?",
      "slow_band_ms": 12000
    },
    {
      "level": 2,
      "representation": "ikonisch",
      "template": "custom_widget",
      "custom_widget": "tens_add_ikonisch",
      "params": { "tens_a_range": [1, 5], "sum_max": 9 },
      "problem_count": 8,
      "prompt_de": "Wie viel sind die Zehner-Karten zusammen?",
      "slow_band_ms": 9000
    },
    {
      "level": 3,
      "representation": "symbolisch",
      "template": "custom_widget",
      "custom_widget": "tens_add_symbolisch",
      "params": { "tens_a_range": [1, 5], "sum_max": 9 },
      "problem_count": 8,
      "prompt_de": "Rechne im Kopf.",
      "slow_band_ms": 6000
    }
  ],
  "mastery": { "correct_of": 8 },
  "error_taxonomy": [
    { "code": "sign_error", "label_de": "Rechenzeichen vertauscht", "hint_de": "Schau genau hin: Sollst du zusammenzählen oder wegnehmen?" },
    { "code": "other", "label_de": "noch einmal probieren", "hint_de": "Zähl die Zehner noch einmal genau." }
  ],
  "provenance": {
    "sources": ["iMINT S3.7 Rechnen mit Zehnern", "Padberg/Benz, Analogie zum Einspluseins"],
    "author": "Claude (domain author)",
    "reviewed_by": "open"
  }
}
```

- [ ] **Step 10: Write the spec assertion test**

In `math_app/test/skill_spec_store_test.dart`, add a test right after the `double_decade` test (before `halve_zr10`'s test):

```dart
    test('tens_add_tens parses with the tens-add widgets', () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('tens_add_tens');
      expect(spec.constructId, 'tens_add_sub');
      expect(spec.domain, 'C');
      expect(spec.titleDe, 'Zehnerzahl plus Zehnerzahl');
      expect(spec.levels.map((l) => l.customWidget), [
        'tens_add_enaktiv',
        'tens_add_ikonisch',
        'tens_add_symbolisch',
      ]);
    });
```

- [ ] **Step 11: Run the test to verify it passes**

Run: `cd math_app && flutter test test/skill_spec_store_test.dart --plain-name "tens_add_tens"`
Expected: PASS.

- [ ] **Step 12: Write widget tests**

In `math_app/test/template_widgets_test.dart`, find the existing `_problem({required String template, required Map<String, dynamic> display, required List<String> expected})` helper used by the `DoublingBoatEnaktivWidget` tests, and add 3 new groups anywhere in the file (e.g. right after the `DoublingTensSymbolischWidget` group, if one exists, or after any `doubling_tens_*` group):

```dart
  group('TensAddEnaktivWidget', () {
    Problem addProblem(int a, int b) => _problem(
          template: 'custom_widget',
          display: {
            'custom_widget': 'tens_add_enaktiv',
            'op': '+',
            'a': a,
            'b': b,
            'target': a + b,
          },
          expected: ['${a + b}'],
        );

    testWidgets('typing the sum reports it live', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TensAddEnaktivWidget(
              problem: addProblem(30, 40),
              onValueChanged: values.add,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('30 + 40 = ?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '70');
      await tester.pump();

      expect(values.last, '70');
    });

    testWidgets('a new problem clears the field', (tester) async {
      final values = <String>[];
      Widget host(Problem p) => MaterialApp(
            home: Scaffold(
              body: TensAddEnaktivWidget(problem: p, onValueChanged: values.add),
            ),
          );

      await tester.pumpWidget(host(addProblem(10, 20)));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '30');
      await tester.pump();

      await tester.pumpWidget(host(addProblem(20, 30)));
      await tester.pump();

      expect(values.last, '');
      expect(find.text('20 + 30 = ?'), findsOneWidget);
    });
  });

  group('TensAddIkonischWidget', () {
    testWidgets('renders the equation and a chip per ten', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TensAddIkonischWidget(
              problem: _problem(
                template: 'custom_widget',
                display: {
                  'custom_widget': 'tens_add_ikonisch',
                  'op': '+',
                  'a': 20,
                  'b': 30,
                  'target': 50,
                },
                expected: ['50'],
              ),
              onValueChanged: values.add,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('20 + 30 = ?'), findsOneWidget);
      expect(find.text('10'), findsNWidgets(5)); // 2 chips + 3 chips
    });
  });

  group('TensAddSymbolischWidget', () {
    testWidgets('renders bare numeral boxes, no chips or rods', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TensAddSymbolischWidget(
              problem: _problem(
                template: 'custom_widget',
                display: {
                  'custom_widget': 'tens_add_symbolisch',
                  'op': '+',
                  'a': 10,
                  'b': 20,
                  'target': 30,
                },
                expected: ['30'],
              ),
              onValueChanged: values.add,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('10'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('10 + 20 = ?'), findsOneWidget);
    });
  });
```

Add the matching imports near the top of `math_app/test/template_widgets_test.dart`, alongside the existing `doubling_tens_*` imports:

```dart
import 'package:math_app/widgets/templates/tens_add_enaktiv_widget.dart';
import 'package:math_app/widgets/templates/tens_add_ikonisch_widget.dart';
import 'package:math_app/widgets/templates/tens_add_symbolisch_widget.dart';
```

- [ ] **Step 13: Run the widget tests to verify they pass**

Run: `cd math_app && flutter test test/template_widgets_test.dart --plain-name "TensAdd"`
Expected: PASS (all 4 tests across the 3 groups).

- [ ] **Step 14: Run the full test suite and `flutter analyze`**

Run: `cd math_app && flutter test && flutter analyze`
Expected: all tests pass (baseline count + the new ones added in this task); `flutter analyze` issue count stays at the pre-existing baseline (no new issues — new files must be clean).

- [ ] **Step 15: Commit**

```bash
git add math_app/lib/widgets/templates/tens_add_common.dart \
        math_app/lib/widgets/templates/tens_add_enaktiv_widget.dart \
        math_app/lib/widgets/templates/tens_add_ikonisch_widget.dart \
        math_app/lib/widgets/templates/tens_add_symbolisch_widget.dart \
        math_app/lib/models/skill_spec.dart \
        math_app/lib/practice/template_registry.dart \
        math_app/lib/practice/problem_generators.dart \
        docs/clean-room/v4/skills/specs/tens_add_tens.json \
        math_app/test/problem_generators_test.dart \
        math_app/test/skill_spec_store_test.dart \
        math_app/test/template_widgets_test.dart
git commit -m "feat(tens_add_tens): add tens-add widget family, generator, and spec"
```

---

### Task 2: `tens_sub_tens` — widget family, generator, registry wiring, spec, tests

**Files:**
- Create: `math_app/lib/widgets/templates/tens_sub_common.dart`
- Create: `math_app/lib/widgets/templates/tens_sub_enaktiv_widget.dart`
- Create: `math_app/lib/widgets/templates/tens_sub_ikonisch_widget.dart`
- Create: `math_app/lib/widgets/templates/tens_sub_symbolisch_widget.dart`
- Create: `docs/clean-room/v4/skills/specs/tens_sub_tens.json`
- Modify: `math_app/lib/models/skill_spec.dart` (add 3 more keys to `kKnownCustomWidgets`)
- Modify: `math_app/lib/practice/template_registry.dart` (3 imports + 3 switch arms)
- Modify: `math_app/lib/practice/problem_generators.dart` (new `_generateTensSub`, 3 switch cases)
- Modify: `math_app/test/problem_generators_test.dart` (2 tests)
- Modify: `math_app/test/skill_spec_store_test.dart` (1 test)
- Modify: `math_app/test/template_widgets_test.dart` (3 widget-test groups)

**Interfaces:**
- Consumes: same shared helpers as Task 1 (`TenStripWidget`, `BigAnswerField`, `SeededGenerator.nextIntInRange`, `LevelSpec.intListParam`, `SpecFormatException`, `Problem`), plus the already-existing top-level helper `int _clampedDraw(SeededGenerator gen, int lo, int hi, int outer)` (`math_app/lib/practice/problem_generators.dart:366-369`) — do not redefine it, just call it.
- Produces: `TensSubCore` widget (`math_app/lib/widgets/templates/tens_sub_common.dart`) with constructor `TensSubCore({required Problem problem, required ValueChanged<String> onValueChanged, required Widget Function(BuildContext, int tensA, int tensB) buildVisual, VoidCallback? onSubmit})`. Registry keys `'tens_sub_enaktiv'`, `'tens_sub_ikonisch'`, `'tens_sub_symbolisch'`. Generator function `_generateTensSub(SkillSpec, LevelSpec, int, int, int, SeededGenerator) -> Problem` — **Task 3 reuses this generator and these 3 widgets verbatim, unmodified, only adding a new spec JSON with different params.**

- [ ] **Step 1: Write the standalone `TensSubEnaktivWidget`**

Create `math_app/lib/widgets/templates/tens_sub_enaktiv_widget.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../common/ten_strip_widget.dart';
import 'answer_pad.dart';

/// Enaktiv tier of `tens_sub_tens` / `tens_sub_crossing_hundred`
/// (BUILD_ORDER.md Batch 1.12): the total is shown as `tensA` actual
/// ten-rods (`TenStripWidget`, a shared manipulative, imported unmodified).
/// The child taps rods to cross them out, mirroring the old engine's
/// `TensCalculationLevel2Widget` tap-to-mark interaction
/// (math_app/lib/widgets/tens_calculation_level2_widget.dart, untouched) --
/// fresh copy, adapted contract. Crossing out is an optional manipulative
/// aid, not gated: the final answer is always typed freely and reported
/// live via [onValueChanged], graded centrally like every other
/// custom_widget.
class TensSubEnaktivWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const TensSubEnaktivWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  State<TensSubEnaktivWidget> createState() => _TensSubEnaktivWidgetState();
}

class _TensSubEnaktivWidgetState extends State<TensSubEnaktivWidget> {
  final TextEditingController _controller = TextEditingController();
  late List<bool> _crossed;

  int get _a => (widget.problem.display['a'] as num).toInt();
  int get _b => (widget.problem.display['b'] as num).toInt();
  int get _tensA => _a ~/ 10;

  @override
  void initState() {
    super.initState();
    _crossed = List.filled(_tensA, false);
  }

  @override
  void didUpdateWidget(covariant TensSubEnaktivWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _controller.clear();
      _crossed = List.filled(_tensA, false);
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

  void _toggle(int index) {
    setState(() => _crossed[index] = !_crossed[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$_a - $_b = ?',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Streiche $_b Zehner durch!',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < _tensA; i++)
                GestureDetector(
                  key: ValueKey('tens-sub-rod-$_tensA-$i'),
                  onTap: () => _toggle(i),
                  child: TenStripWidget(
                    color: Colors.blue,
                    isMarked: _crossed[i],
                    width: 20,
                    height: 120,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        BigAnswerField(
          controller: _controller,
          onChanged: widget.onValueChanged,
          onSubmit: widget.onSubmit,
          hintText: '?',
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Write the shared `TensSubCore` and its 2 static tiers**

Create `math_app/lib/widgets/templates/tens_sub_common.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'answer_pad.dart';

/// Shared interaction core for the `tens_sub_ikonisch`/`tens_sub_symbolisch`
/// custom widgets (tens_sub_tens, tens_sub_crossing_hundred, BUILD_ORDER.md
/// Batch 1.12): renders the subtraction via [buildVisual] (called with the
/// *tens counts*, not the decade numbers), then a single field for the
/// typed result -- reported live via [onValueChanged], graded centrally
/// like every other custom_widget. `tens_sub_enaktiv` (tap-to-cross-out) is
/// a standalone widget and does not use this core.
class TensSubCore extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final Widget Function(BuildContext context, int tensA, int tensB) buildVisual;
  final VoidCallback? onSubmit;

  const TensSubCore({
    super.key,
    required this.problem,
    required this.onValueChanged,
    required this.buildVisual,
    this.onSubmit,
  });

  @override
  State<TensSubCore> createState() => _TensSubCoreState();
}

class _TensSubCoreState extends State<TensSubCore> {
  final TextEditingController _controller = TextEditingController();

  int get _a => (widget.problem.display['a'] as num).toInt();
  int get _b => (widget.problem.display['b'] as num).toInt();

  @override
  void didUpdateWidget(covariant TensSubCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: widget.buildVisual(context, _a ~/ 10, _b ~/ 10),
        ),
        const SizedBox(height: 24),
        BigAnswerField(
          controller: _controller,
          onChanged: widget.onValueChanged,
          onSubmit: widget.onSubmit,
          hintText: '?',
        ),
      ],
    );
  }
}
```

Create `math_app/lib/widgets/templates/tens_sub_ikonisch_widget.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'tens_sub_common.dart';

/// Ikonisch tier of `tens_sub_tens` / `tens_sub_crossing_hundred`
/// (BUILD_ORDER.md Batch 1.12): the total is shown as `tensA` compact
/// "10er" chips; the last `tensB` are struck through to depict the
/// subtraction as a static picture -- no tapping, unlike the enaktiv tier.
class TensSubIkonischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const TensSubIkonischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  static Widget _chips(BuildContext context, int tensA, int tensB) {
    final remaining = tensA - tensB;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${tensA * 10} - ${tensB * 10} = ?',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < tensA; i++)
              Container(
                key: ValueKey('tens-sub-chip-$tensA-$tensB-$i'),
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i < remaining ? Colors.blue.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: i < remaining ? Colors.blue.shade400 : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: i < remaining
                    ? const Text('10', style: TextStyle(fontWeight: FontWeight.bold))
                    : const Icon(Icons.close, color: Colors.redAccent),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return TensSubCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildVisual: _chips,
      onSubmit: onSubmit,
    );
  }
}
```

Create `math_app/lib/widgets/templates/tens_sub_symbolisch_widget.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'tens_sub_common.dart';

/// Symbolisch tier of `tens_sub_tens` / `tens_sub_crossing_hundred`
/// (BUILD_ORDER.md Batch 1.12): bare numerals only, no chips or rods --
/// the most abstract of the 3 representations.
class TensSubSymbolischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const TensSubSymbolischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  static Widget _equation(BuildContext context, int tensA, int tensB) {
    return Text(
      '${tensA * 10} - ${tensB * 10} = ?',
      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TensSubCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildVisual: _equation,
      onSubmit: onSubmit,
    );
  }
}
```

- [ ] **Step 3: Register the 3 new keys in `kKnownCustomWidgets`**

In `math_app/lib/models/skill_spec.dart`, add 3 more lines right before `kKnownCustomWidgets`'s closing `};` (after the `tens_add_*` lines Task 1 added):

```dart
  'tens_add_enaktiv',
  'tens_add_ikonisch',
  'tens_add_symbolisch',
  'tens_sub_enaktiv',
  'tens_sub_ikonisch',
  'tens_sub_symbolisch',
};
```

- [ ] **Step 4: Wire the 3 new widgets into `template_registry.dart`**

Add 3 import lines after the `tens_add_symbolisch_widget.dart` import Task 1 added:

```dart
import '../widgets/templates/tens_add_symbolisch_widget.dart';
import '../widgets/templates/tens_sub_enaktiv_widget.dart';
import '../widgets/templates/tens_sub_ikonisch_widget.dart';
import '../widgets/templates/tens_sub_symbolisch_widget.dart';
```

Add 3 switch arms right before the `_ => const _UnavailableTemplateWidget(),` line, after the `tens_add_symbolisch` arm Task 1 added:

```dart
      'tens_add_symbolisch' => TensAddSymbolischWidget(
          problem: problem,
          onValueChanged: onValueChanged,
          onSubmit: onSubmit,
        ),
      'tens_sub_enaktiv' => TensSubEnaktivWidget(
          problem: problem,
          onValueChanged: onValueChanged,
          onSubmit: onSubmit,
        ),
      'tens_sub_ikonisch' => TensSubIkonischWidget(
          problem: problem,
          onValueChanged: onValueChanged,
          onSubmit: onSubmit,
        ),
      'tens_sub_symbolisch' => TensSubSymbolischWidget(
          problem: problem,
          onValueChanged: onValueChanged,
          onSubmit: onSubmit,
        ),
      _ => const _UnavailableTemplateWidget(),
```

- [ ] **Step 5: Write the failing generator test**

In `math_app/test/problem_generators_test.dart`, in the same `custom_widget generators` group as Task 1's tests, add:

```dart
    test('tens_sub_enaktiv: a/b are decade numbers, b <= a, expected == '
        'a-b, op == "-"', () {
      final s = spec('tens_sub_enaktiv', {
        'tens_a_range': [2, 9],
        'tens_b_range': [1, 9],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final a = p.display['a'] as int;
          final b = p.display['b'] as int;
          expect(a % 10, 0, reason: 'a is a decade number');
          expect(b % 10, 0, reason: 'b is a decade number');
          expect(a ~/ 10, inInclusiveRange(2, 9));
          expect(b, lessThanOrEqualTo(a), reason: 'never a negative result');
          expect(p.display['op'], '-');
          expect(p.expected, ['${a - b}']);
          expect(p.display['custom_widget'], 'tens_sub_enaktiv');
        }
      }
    });

    test('tens_sub_enaktiv: tens_a_range fixed at 10 models the '
        'crossing-hundred case (a == 100 always)', () {
      final s = spec('tens_sub_enaktiv', {
        'tens_a_range': [10, 10],
        'tens_b_range': [1, 9],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          expect(p.display['a'], 100);
          final b = p.display['b'] as int;
          expect(b, inInclusiveRange(10, 90));
          expect(p.expected, ['${100 - b}']);
        }
      }
    });
```

- [ ] **Step 6: Run the test to verify it fails**

Run: `cd math_app && flutter test test/problem_generators_test.dart --plain-name "tens_sub"`
Expected: FAIL — `_generateTensSub` and the `'tens_sub_enaktiv'` dispatch case don't exist yet.

- [ ] **Step 7: Implement `_generateTensSub` and wire it into the dispatch switch**

In `math_app/lib/practice/problem_generators.dart`, add a case group right after the `tens_add_*` case Task 1 added, before `case 'halving_mirror_enaktiv':`:

```dart
    case 'tens_add_enaktiv':
    case 'tens_add_ikonisch':
    case 'tens_add_symbolisch':
      return _generateTensAdd(spec, level, levelNumber, seed, index, gen);
    case 'tens_sub_enaktiv':
    case 'tens_sub_ikonisch':
    case 'tens_sub_symbolisch':
      return _generateTensSub(spec, level, levelNumber, seed, index, gen);
    case 'halving_mirror_enaktiv':
```

Add the generator function anywhere among the other `_generateX` functions (e.g. right after `_generateTensAdd`):

```dart
/// Registry keys `"tens_sub_enaktiv"`, `"tens_sub_ikonisch"`,
/// `"tens_sub_symbolisch"` -- shared by two skills, BUILD_ORDER.md Batch
/// 1.12: `tens_sub_tens` (`tens_a_range: [2,9]`) and
/// `tens_sub_crossing_hundred` (`tens_a_range: [10,10]`, i.e. `a` fixed at
/// 100), exactly like `double_zr10`/`double_zr10_to_zr20` share the
/// doubling-mirror widgets over disjoint ranges. `tensB` is drawn via the
/// existing [_clampedDraw] helper so it never exceeds the drawn `tensA`,
/// guaranteeing a non-negative result for both skills. `display` carries
/// `op: "-"` plus the actual `a`/`b` decade numbers (not tens counts) so
/// `TemplateEvaluator` can detect a `sign_error`; `expected` holds the
/// subtracted decade number as a plain string.
Problem _generateTensSub(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final tensARange = level.intListParam('tens_a_range');
  final tensBRange = level.intListParam('tens_b_range');
  if (tensARange.length != 2 || tensBRange.length != 2) {
    throw SpecFormatException(
      'tens_sub: "tens_a_range" and "tens_b_range" must each be a '
      '2-element [min, max] list',
    );
  }
  final loA = tensARange[0];
  final hiA = tensARange[1];
  final loB = tensBRange[0];
  final hiB = tensBRange[1];
  if (loA < 1 || hiA > 10 || loA > hiA || loB < 1 || hiB > 10 || loB > hiB) {
    throw SpecFormatException(
      'tens_sub: tens_a_range [$loA, $hiA] / tens_b_range [$loB, $hiB] '
      'invalid -- both must be within [1, 10] (10 tens == 100)',
    );
  }

  final tensA = gen.nextIntInRange(loA, hiA);
  final tensB = _clampedDraw(gen, loB, hiB, tensA);
  final a = tensA * 10;
  final b = tensB * 10;
  final target = a - b;

  return Problem(
    template: 'custom_widget',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {
      'custom_widget': level.customWidget,
      'op': '-',
      'a': a,
      'b': b,
      'target': target,
    },
    expected: [target.toString()],
  );
}
```

- [ ] **Step 8: Run the test to verify it passes**

Run: `cd math_app && flutter test test/problem_generators_test.dart --plain-name "tens_sub"`
Expected: PASS.

- [ ] **Step 9: Write the spec JSON**

Create `docs/clean-room/v4/skills/specs/tens_sub_tens.json`:

```json
{
  "spec_version": 1,
  "skill_id": "tens_sub_tens",
  "construct_id": "tens_add_sub",
  "domain": "C",
  "title_de": "Zehnerzahl minus Zehnerzahl",
  "level_titles_de": [
    "Zehner wegstreichen (Zehnerstreifen)",
    "Zehner wegnehmen (Bildkarten)",
    "Zehner subtrahieren (im Kopf)"
  ],
  "levels": [
    {
      "level": 1,
      "representation": "enaktiv",
      "template": "custom_widget",
      "custom_widget": "tens_sub_enaktiv",
      "params": { "tens_a_range": [2, 9], "tens_b_range": [1, 9] },
      "problem_count": 8,
      "prompt_de": "Streiche Zehnerstreifen durch. Wie viele bleiben übrig?",
      "slow_band_ms": 12000
    },
    {
      "level": 2,
      "representation": "ikonisch",
      "template": "custom_widget",
      "custom_widget": "tens_sub_ikonisch",
      "params": { "tens_a_range": [2, 9], "tens_b_range": [1, 9] },
      "problem_count": 8,
      "prompt_de": "Wie viele Zehner bleiben übrig?",
      "slow_band_ms": 9000
    },
    {
      "level": 3,
      "representation": "symbolisch",
      "template": "custom_widget",
      "custom_widget": "tens_sub_symbolisch",
      "params": { "tens_a_range": [2, 9], "tens_b_range": [1, 9] },
      "problem_count": 8,
      "prompt_de": "Rechne im Kopf.",
      "slow_band_ms": 6000
    }
  ],
  "mastery": { "correct_of": 8 },
  "error_taxonomy": [
    { "code": "sign_error", "label_de": "Rechenzeichen vertauscht", "hint_de": "Schau genau hin: Sollst du zusammenzählen oder wegnehmen?" },
    { "code": "other", "label_de": "noch einmal probieren", "hint_de": "Zähl die Zehner noch einmal genau." }
  ],
  "provenance": {
    "sources": ["iMINT S3.7 Rechnen mit Zehnern", "Padberg/Benz, Analogie zum Einspluseins"],
    "author": "Claude (domain author)",
    "reviewed_by": "open"
  }
}
```

- [ ] **Step 10: Write the spec assertion test**

In `math_app/test/skill_spec_store_test.dart`, add a test right after Task 1's `tens_add_tens` test:

```dart
    test('tens_sub_tens parses with the tens-sub widgets', () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('tens_sub_tens');
      expect(spec.constructId, 'tens_add_sub');
      expect(spec.domain, 'C');
      expect(spec.titleDe, 'Zehnerzahl minus Zehnerzahl');
      expect(spec.levels.map((l) => l.customWidget), [
        'tens_sub_enaktiv',
        'tens_sub_ikonisch',
        'tens_sub_symbolisch',
      ]);
    });
```

- [ ] **Step 11: Run the test to verify it passes**

Run: `cd math_app && flutter test test/skill_spec_store_test.dart --plain-name "tens_sub_tens"`
Expected: PASS.

- [ ] **Step 12: Write widget tests**

In `math_app/test/template_widgets_test.dart`, add imports alongside Task 1's `tens_add_*` imports:

```dart
import 'package:math_app/widgets/templates/tens_sub_enaktiv_widget.dart';
import 'package:math_app/widgets/templates/tens_sub_ikonisch_widget.dart';
import 'package:math_app/widgets/templates/tens_sub_symbolisch_widget.dart';
```

Add 3 new groups (after the `TensAddSymbolischWidget` group Task 1 added):

```dart
  group('TensSubEnaktivWidget', () {
    Problem subProblem(int a, int b) => _problem(
          template: 'custom_widget',
          display: {
            'custom_widget': 'tens_sub_enaktiv',
            'op': '-',
            'a': a,
            'b': b,
            'target': a - b,
          },
          expected: ['${a - b}'],
        );

    testWidgets('tapping rods crosses them out; typing the result reports '
        'it live', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TensSubEnaktivWidget(
              problem: subProblem(90, 20),
              onValueChanged: values.add,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('90 - 20 = ?'), findsOneWidget);
      // 9 rods rendered for a == 90.
      expect(find.byKey(const ValueKey('tens-sub-rod-9-0')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tens-sub-rod-9-0')));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '70');
      await tester.pump();

      expect(values.last, '70');
    });

    testWidgets('a == 100 renders 10 rods (crossing-hundred case)',
        (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TensSubEnaktivWidget(
              problem: subProblem(100, 30),
              onValueChanged: values.add,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('100 - 30 = ?'), findsOneWidget);
      expect(find.byKey(const ValueKey('tens-sub-rod-10-9')), findsOneWidget);
    });
  });

  group('TensSubIkonischWidget', () {
    testWidgets('renders the equation and a chip per ten', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TensSubIkonischWidget(
              problem: _problem(
                template: 'custom_widget',
                display: {
                  'custom_widget': 'tens_sub_ikonisch',
                  'op': '-',
                  'a': 90,
                  'b': 20,
                  'target': 70,
                },
                expected: ['70'],
              ),
              onValueChanged: values.add,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('90 - 20 = ?'), findsOneWidget);
      expect(find.byKey(const ValueKey('tens-sub-chip-9-2-0')), findsOneWidget);
    });
  });

  group('TensSubSymbolischWidget', () {
    testWidgets('renders bare equation text, no chips or rods', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TensSubSymbolischWidget(
              problem: _problem(
                template: 'custom_widget',
                display: {
                  'custom_widget': 'tens_sub_symbolisch',
                  'op': '-',
                  'a': 100,
                  'b': 20,
                  'target': 80,
                },
                expected: ['80'],
              ),
              onValueChanged: values.add,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('100 - 20 = ?'), findsOneWidget);
    });
  });
```

- [ ] **Step 13: Run the widget tests to verify they pass**

Run: `cd math_app && flutter test test/template_widgets_test.dart --plain-name "TensSub"`
Expected: PASS (all 4 tests across the 3 groups).

- [ ] **Step 14: Run the full test suite and `flutter analyze`**

Run: `cd math_app && flutter test && flutter analyze`
Expected: all tests pass; `flutter analyze` stays at baseline.

- [ ] **Step 15: Commit**

```bash
git add math_app/lib/widgets/templates/tens_sub_common.dart \
        math_app/lib/widgets/templates/tens_sub_enaktiv_widget.dart \
        math_app/lib/widgets/templates/tens_sub_ikonisch_widget.dart \
        math_app/lib/widgets/templates/tens_sub_symbolisch_widget.dart \
        math_app/lib/models/skill_spec.dart \
        math_app/lib/practice/template_registry.dart \
        math_app/lib/practice/problem_generators.dart \
        docs/clean-room/v4/skills/specs/tens_sub_tens.json \
        math_app/test/problem_generators_test.dart \
        math_app/test/skill_spec_store_test.dart \
        math_app/test/template_widgets_test.dart
git commit -m "feat(tens_sub_tens): add tens-sub widget family, generator, and spec"
```

---

### Task 3: `tens_sub_crossing_hundred` — new spec reusing Task 2's widgets, coverage, and BUILD_ORDER close-out

**Files:**
- Create: `docs/clean-room/v4/skills/specs/tens_sub_crossing_hundred.json`
- Modify: `math_app/test/skill_spec_store_test.dart` (1 test)
- Modify: `docs/clean-room/v4/skills/BUILD_ORDER.md` (check off all 3 skills, add `## Done` entries, correct the running counts)

**Interfaces:**
- Consumes: `tens_sub_enaktiv`/`tens_sub_ikonisch`/`tens_sub_symbolisch` (Task 2's widgets, registered already) and `_generateTensSub` (Task 2's generator, dispatched already) — **no code changes to either**, just a new spec JSON with `tens_a_range: [10, 10]`.
- Produces: nothing further downstream — this is the batch's last task.

- [ ] **Step 1: Write the spec JSON**

Create `docs/clean-room/v4/skills/specs/tens_sub_crossing_hundred.json`:

```json
{
  "spec_version": 1,
  "skill_id": "tens_sub_crossing_hundred",
  "construct_id": "tens_add_sub",
  "domain": "C",
  "title_de": "Zehnerzahl minus Zehnerzahl (Sprung über die 100)",
  "level_titles_de": [
    "Hundert wegstreichen (Zehnerstreifen)",
    "Hundert wegnehmen (Bildkarten)",
    "Hundert minus Zehner (im Kopf)"
  ],
  "levels": [
    {
      "level": 1,
      "representation": "enaktiv",
      "template": "custom_widget",
      "custom_widget": "tens_sub_enaktiv",
      "params": { "tens_a_range": [10, 10], "tens_b_range": [1, 9] },
      "problem_count": 8,
      "prompt_de": "Streiche Zehnerstreifen durch. Wie viele bleiben übrig?",
      "slow_band_ms": 12000
    },
    {
      "level": 2,
      "representation": "ikonisch",
      "template": "custom_widget",
      "custom_widget": "tens_sub_ikonisch",
      "params": { "tens_a_range": [10, 10], "tens_b_range": [1, 9] },
      "problem_count": 8,
      "prompt_de": "Wie viele Zehner bleiben übrig?",
      "slow_band_ms": 9000
    },
    {
      "level": 3,
      "representation": "symbolisch",
      "template": "custom_widget",
      "custom_widget": "tens_sub_symbolisch",
      "params": { "tens_a_range": [10, 10], "tens_b_range": [1, 9] },
      "problem_count": 8,
      "prompt_de": "Rechne im Kopf.",
      "slow_band_ms": 6000
    }
  ],
  "mastery": { "correct_of": 8 },
  "error_taxonomy": [
    { "code": "sign_error", "label_de": "Rechenzeichen vertauscht", "hint_de": "Schau genau hin: Sollst du zusammenzählen oder wegnehmen?" },
    { "code": "other", "label_de": "noch einmal probieren", "hint_de": "Zähl die Zehner noch einmal genau." }
  ],
  "provenance": {
    "sources": ["iMINT S3.7 Rechnen mit Zehnern (100-Grenze)", "Padberg/Benz, Rechnen an der Hundertergrenze"],
    "author": "Claude (domain author)",
    "reviewed_by": "open"
  }
}
```

- [ ] **Step 2: Write the failing spec assertion test**

In `math_app/test/skill_spec_store_test.dart`, add a test right after Task 2's `tens_sub_tens` test:

```dart
    test('tens_sub_crossing_hundred parses, sharing the tens-sub widgets '
        'with tens_sub_tens', () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('tens_sub_crossing_hundred');
      expect(spec.constructId, 'tens_add_sub');
      expect(spec.domain, 'C');
      expect(spec.titleDe, 'Zehnerzahl minus Zehnerzahl (Sprung über die 100)');
      expect(spec.levels.map((l) => l.customWidget), [
        'tens_sub_enaktiv',
        'tens_sub_ikonisch',
        'tens_sub_symbolisch',
      ]);
      expect(
        spec.levels.map((l) => (l.params['tens_a_range'] as List)),
        everyElement(equals([10, 10])),
        reason: 'a is fixed at 100 (the "Sprung über die 100" landmark)',
      );
    });
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `cd math_app && flutter test test/skill_spec_store_test.dart --plain-name "tens_sub_crossing_hundred"`
Expected: FAIL — `store.byId('tens_sub_crossing_hundred')` throws `ArgumentError` because the spec JSON doesn't exist as a *bundled* spec yet from the test's point of view... actually the test loader reads straight from `docs/clean-room/v4/skills/specs/`, so once Step 1's file exists, this test should already pass. Run it anyway to confirm Step 1 was done correctly before moving on — if it fails, the file wasn't saved correctly; re-check Step 1.

- [ ] **Step 4: Confirm the test passes**

Run: `cd math_app && flutter test test/skill_spec_store_test.dart --plain-name "tens_sub_crossing_hundred"`
Expected: PASS.

- [ ] **Step 5: Also confirm the generator's crossing-hundred behavior end to end**

Run: `cd math_app && flutter test test/skill_spec_store_test.dart --plain-name "every bundled v4 spec parses and validates"`
Expected: PASS — this is the project-wide smoke test that every spec under `docs/clean-room/v4/skills/specs/` (now including all 3 of this batch's new files) parses and validates with zero errors.

- [ ] **Step 6: Sync specs and check coverage**

Run: `cd .. && python scripts/sync_skill_specs.py && python scripts/check_skill_spec_coverage.py`

(Run from the repo root, not `math_app/` — adjust the `cd ..` if your shell is already at the repo root.)

Expected: `sync_skill_specs.py` copies the 3 new JSON files into the app's bundled assets; `check_skill_spec_coverage.py` reports `tens_add_tens`, `tens_sub_tens`, `tens_sub_crossing_hundred` as covered (moved out of "missing"), and `extra` stays empty.

- [ ] **Step 7: Update `BUILD_ORDER.md`**

In `docs/clean-room/v4/skills/BUILD_ORDER.md`:

1. Change the top-of-file line:
   ```
   66 of 93 skills remain (27 shipped as of Batch 1.11 --
   ```
   to:
   ```
   63 of 93 skills remain (30 shipped as of Batch 1.12 --
   ```

2. Change `## Tier 1: Reused (4 remaining of 30)` to `## Tier 1: Reused (1 remaining of 30)`.

3. Check off the 3 skills under `### Batch 1.12 — tens arithmetic (construct `tens_add_sub`)`:
   ```
   - [x] `tens_add_tens` — shipped, `docs/superpowers/plans/2026-09-20-tens-add-sub-batch-1-12.md`; Reused from S3.7 `Rechnen mit Zehnern` (`tens_calculation_exercise.dart`); Visual Add → Symbolic + levels
   - [x] `tens_sub_tens` — shipped, `docs/superpowers/plans/2026-09-20-tens-add-sub-batch-1-12.md`; Reused from the same S3.7 file; Visual Sub → Symbolic − levels
   - [x] `tens_sub_crossing_hundred` — shipped, `docs/superpowers/plans/2026-09-20-tens-add-sub-batch-1-12.md`; Reused from the same S3.7 file, plus its 100-crossing level (e.g. 100−20)
   ```

4. Add 3 entries to the `## Done` list at the bottom, matching the existing entries' format (each has a link to its plan file plus a short description):
   ```
   - [x] `tens_add_tens` — shipped, `docs/superpowers/plans/2026-09-20-tens-add-sub-batch-1-12.md`; Reused from S3.7 `Rechnen mit Zehnern` (`tens_calculation_exercise.dart`); tens-rod visual → decade-chip icon → bare numeral, all 3 tiers sharing `TensAddCore`
   - [x] `tens_sub_tens` — shipped, `docs/superpowers/plans/2026-09-20-tens-add-sub-batch-1-12.md`; Reused from the same S3.7 file; tap-to-cross-out ten-rods (enaktiv) → static crossed chips (ikonisch) → bare equation (symbolisch)
   - [x] `tens_sub_crossing_hundred` — shipped, `docs/superpowers/plans/2026-09-20-tens-add-sub-batch-1-12.md`; Reused from the same S3.7 file's 100-crossing level; shares all 3 `tens_sub_*` widgets and the generator with `tens_sub_tens` over `tens_a_range: [10,10]` (a fixed at 100)
   ```

- [ ] **Step 8: Run the full test suite and `flutter analyze` one more time**

Run: `cd math_app && flutter test && flutter analyze`
Expected: all tests pass (baseline + every test this plan added across all 3 tasks); `flutter analyze` stays at the pre-existing baseline issue count.

- [ ] **Step 9: Commit**

```bash
git add docs/clean-room/v4/skills/specs/tens_sub_crossing_hundred.json \
        math_app/test/skill_spec_store_test.dart \
        docs/clean-room/v4/skills/BUILD_ORDER.md
git commit -m "feat(tens_sub_crossing_hundred): add spec, close out Batch 1.12"
```

---

## Self-Review Notes

- **Spec coverage:** all 3 taxonomy rows (`math_app/Research/skills_taxonomy.csv:54-56`) have a task producing their spec (Task 1 → `tens_add_tens`, Task 2 → `tens_sub_tens`, Task 3 → `tens_sub_crossing_hundred`). The design doc's §5 archetype description ("Visual (rods) → Symbolic", crossing-hundred as a third level) is honored by mapping the mandatory 3-tier EIS schema onto rods → chips → numerals (Task 1/2) and reusing the same shape with `a` fixed at 100 (Task 3).
- **Placeholder scan:** every step has literal, runnable code — no "add validation"/"similar to Task N" placeholders.
- **Type consistency:** `TensAddCore.buildGroup` is `Widget Function(BuildContext, int tensCount)` in both its Task-1 definition and all 3 Task-1 widgets' usage. `TensSubCore.buildVisual` is `Widget Function(BuildContext, int tensA, int tensB)` in both its Task-2 definition and both static Task-2 widgets' usage (`tens_sub_enaktiv` doesn't use the core at all, by design). `_generateTensAdd`/`_generateTensSub` signatures match every other `_generateX` function's `(SkillSpec, LevelSpec, int, int, int, SeededGenerator) -> Problem` shape used throughout `problem_generators.dart`.
