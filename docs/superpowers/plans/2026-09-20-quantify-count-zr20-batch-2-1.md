# Batch 2.1 — Counting Quantities to 20 (`quantify_count_zr20`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship `docs/clean-room/v4/skills/BUILD_ORDER.md` Batch 2.1 — the single skill `quantify_count_zr20` — the first Tier 2 (Extended) skill.

**Architecture:** One new custom-widget family (`count_field20_*`), ported from the shipped `count_field_*` family (Batch 1.1) but extended to ZR20 with **unstructured layouts only** (the BUILD_ORDER entry: "ZR20 becomes the always-unstructured half"). All three tiers share one stateful `CountField20Core` (tap-to-mark dots + a `BigAnswerField`), parameterised by dot sizes and whether a running tap tally is shown. Dot positions come from a pure, seeded, top-level layout function (`layoutCountField20`) that places every dot in its own grid cell with a jittered offset, so dots can **never overlap** and never leave the play area, at any count up to 20 (the old rejection-sampling scatter cannot guarantee that at 20 dots). One new generator `_generateCountField20`. The answer is a single integer string, graded by `_evaluateCustomWidget`'s default plain-string branch — no `TemplateEvaluator` change.

**Tech Stack:** Flutter/Dart, the v4 skill-spec pipeline (`SkillSpec`/`SkillSpecStore`/`template_registry`/`template_evaluator`/`problem_generators`), `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-09-15-exercise-plan-design.md` (§5, the `quantify_count_zr20` archetype entry), `docs/skill_spec_authoring_guide.md` (authoring checklist), `docs/clean-room/v4/skills/BUILD_ORDER.md` (Batch 2.1 line).

## Global Constraints

- **Exactly 3 levels per spec**, `representation` values `"enaktiv"`, `"ikonisch"`, `"symbolisch"` in that order — `SkillSpec` parsing hard-rejects anything else (`math_app/lib/models/skill_spec.dart:344-351`).
- **Port, don't refactor** (`docs/skill_spec_authoring_guide.md`): the shipped `count_field_enaktiv/ikonisch/symbolisch` widgets, `_generateCountField` and their existing tests stay **completely untouched** (in particular `_generateCountField`'s `[1, 10]` clamp and the existing test "an empty count_range after clamping is a spec error" must keep passing unchanged). New widgets are fresh files. `answer_pad.dart`'s `BigAnswerField` is a shared component — imported, not modified.
- **New registry keys are `count_field20_enaktiv`, `count_field20_ikonisch`, `count_field20_symbolisch`** — do not reuse the ZR10 keys (their generator caps at 10).
- **Enter-key submission convention**: the final answer field's `onSubmitted` calls `widget.onSubmit?.call()` — here that is `BigAnswerField(onSubmit: widget.onSubmit)`, exactly as the ZR10 widgets do.
- **Centrally-graded architecture**: the typed total is reported live via `onValueChanged` (every change, `""` while empty) and graded by `TemplateEvaluator` against `problem.expected` — no widget self-grades. The tap-to-mark state is a visual counting aid only and is never part of the answer.
- **error_taxonomy**: `"miscount"` and `"other"` only, identical to `quantify_count_zr10`. `expected` is a single integer string, so `_candidateErrorCode`'s off-by-one `miscount` branch is reachable; never add a code `_candidateErrorCode` cannot emit (no `off_by_one_low/high`).
- **No deprecated Flutter APIs in new code** (`Color.withOpacity` → `Color.withValues(alpha: x)`; it should not be needed here).
- **`SeededGenerator.nextIntInRange(int min, int max)`** (inclusive) and `LevelSpec.intListParam` are the only allowed sources of randomness/params in the *generator*. The widget's layout uses `dart:math`'s `Random(seed-derived-int)` exactly as the ZR10 widgets do (a deterministic function of `problem.seed`/`problem.index`/count, never wall-clock).
- **Flutter duplicate-key rule** (a Critical bug was found in Batch 1.12): every `Key` on a widget in a repeated group must be unique among its siblings *by construction*. Dot keys here are `ValueKey('cf20-dot-$index')` with `index` the loop index `0..count-1` — unique by construction.
- Every new generator function must validate its params and `throw SpecFormatException(...)` on an invalid range.

## Design Notes (read before Task 1)

**Why a new key family instead of raising the ZR10 cap:** `_generateCountField` clamps `count_range` to `[1, 10]` and an existing test pins that behaviour; `count_field_enaktiv` also lays dots out in *structured rows of 5*, which is the opposite of what the ZR20 skill wants. Porting into `count_field20_*` (with its own generator that validates `[1, 20]` and *throws* rather than clamps) leaves the shipped ZR10 skill byte-for-byte unchanged.

**Why a grid-cell jitter layout instead of the old rejection sampling:** the ZR10 widgets scatter dots by random rejection sampling with a fixed normalised min-distance and a 200-attempt cap, after which they place the dot anyway (overlapping). That is fine for ≤10 dots but at 20 dots of ≥44 px in a 320 px area it can fail, producing overlapping dots the child cannot count. `layoutCountField20` divides a 320×320 play area into a 5×5 grid of 64 px cells (25 cells ≥ 20 dots, so even count=20 leaves 5 cells empty and never looks like a full grid), picks `count` distinct cells by a seeded shuffle, and places each dot at a seeded jitter *inside its own cell* with a small inner margin. A dot can therefore never overlap another dot or leave the area — by construction, not by luck.

**Tier design (all unstructured; representation axis carries the abstraction, number range carries the difficulty):**
- **Level 1 (enaktiv), `count_range [8, 12]`:** uniform 48 px dots; tapping marks a dot counted **and a live tally "Angetippt: n" is shown** (the physical counting aid is fully supported).
- **Level 2 (ikonisch), `count_range [12, 16]`:** uniform 48 px dots; tapping still marks a dot, but **the tally is hidden** (the child keeps the running count in their head).
- **Level 3 (symbolisch), `count_range [16, 20]`:** dots at three sizes `[44, 54, 62]`, tally hidden — the child cannot estimate the total from covered area and must actually count.

**Seed determinism:** the layout is a pure function of `(seed, index, count, sizes)`; the same problem always lays out identically (the ZR10 ikonisch widget has a test for this — this plan has one too).

---

### Task 1: `count_field20_*` widget family, generator, registry wiring, tests

**Files:**
- Create: `math_app/lib/widgets/templates/count_field20_common.dart`
- Create: `math_app/lib/widgets/templates/count_field20_enaktiv_widget.dart`
- Create: `math_app/lib/widgets/templates/count_field20_ikonisch_widget.dart`
- Create: `math_app/lib/widgets/templates/count_field20_symbolisch_widget.dart`
- Modify: `math_app/lib/models/skill_spec.dart` (add 3 keys to `kKnownCustomWidgets`)
- Modify: `math_app/lib/practice/template_registry.dart` (3 imports + 3 switch arms)
- Modify: `math_app/lib/practice/problem_generators.dart` (new `_generateCountField20`, 3 switch cases)
- Modify: `math_app/test/problem_generators_test.dart` (tests)
- Modify: `math_app/test/template_widgets_test.dart` (imports + widget/layout tests)

**Interfaces:**
- Consumes: `BigAnswerField({controller, onChanged, onSubmit, hintText})` from `math_app/lib/widgets/templates/answer_pad.dart` (unmodified — see how `count_field_enaktiv_widget.dart` calls it). `Problem` (`math_app/lib/models/problem.dart`) with `display`, `seed`, `index`. `SeededGenerator.nextIntInRange(int, int)`, `LevelSpec.intListParam(String)`, `SpecFormatException`.
- Produces: top-level `List<CountField20Dot> layoutCountField20({required int seed, required int index, required int count, required List<double> sizes})` and `class CountField20Dot { final double left; final double top; final double size; }` plus constants `kCountField20Area = 320.0` in `count_field20_common.dart`; widget `CountField20Core({required Problem problem, required ValueChanged<String> onValueChanged, VoidCallback? onSubmit, required List<double> dotSizes, required bool showTally})`; registry keys `'count_field20_enaktiv'`, `'count_field20_ikonisch'`, `'count_field20_symbolisch'`; generator `_generateCountField20(SkillSpec, LevelSpec, int, int, int, SeededGenerator) -> Problem`.

- [ ] **Step 1: Write `count_field20_common.dart`**

Create `math_app/lib/widgets/templates/count_field20_common.dart` with exactly:

```dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'answer_pad.dart';

/// Side length of the square play area every ZR20 count-field widget draws
/// its dots in.
const double kCountField20Area = 320.0;

const int _kGridSide = 5;
const double _kCell = kCountField20Area / _kGridSide;
const double _kInnerMargin = 2.0;

/// One dot's top-left corner and diameter inside the play area.
class CountField20Dot {
  final double left;
  final double top;
  final double size;

  const CountField20Dot(this.left, this.top, this.size);

  Rect get rect => Rect.fromLTWH(left, top, size, size);
}

/// Deterministic, overlap-free layout for `count` dots (1..25) in the
/// [kCountField20Area]-square play area. The area is a 5x5 grid of 64 px
/// cells; `count` distinct cells are chosen by a seeded shuffle and each dot
/// is jittered inside its own cell, keeping at least [_kInnerMargin] px to the
/// cell edge whenever the dot is small enough to leave room. Every dot lies
/// wholly inside its own cell, so no two dots can overlap and none can leave
/// the play area, by construction. Every entry of `sizes` must be <= 64.
List<CountField20Dot> layoutCountField20({
  required int seed,
  required int index,
  required int count,
  required List<double> sizes,
}) {
  final random = Random(seed * 173 + index * 59 + count);
  final cells = List<int>.generate(_kGridSide * _kGridSide, (i) => i)
    ..shuffle(random);
  final dots = <CountField20Dot>[];
  for (var i = 0; i < count; i++) {
    final cell = cells[i];
    final col = cell % _kGridSide;
    final row = cell ~/ _kGridSide;
    final size = sizes[random.nextInt(sizes.length)];
    final slack = _kCell - size;
    final range = max(0.0, slack - 2 * _kInnerMargin);
    final inset = (slack - range) / 2;
    final left = col * _kCell + inset + random.nextDouble() * range;
    final top = row * _kCell + inset + random.nextDouble() * range;
    dots.add(CountField20Dot(left, top, size));
  }
  return dots;
}

/// Shared body of the three `count_field20_*` registry keys
/// (quantify_count_zr20, BUILD_ORDER.md Batch 2.1): `display.count` dots laid
/// out by [layoutCountField20]; tapping a dot toggles it as counted (a visual
/// counting aid, never part of the graded answer); the child types the total
/// into [BigAnswerField] and [onValueChanged] reports every typed value, `""`
/// while the field is empty. [showTally] adds a live "Angetippt: n" line.
class CountField20Core extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;
  final List<double> dotSizes;
  final bool showTally;

  const CountField20Core({
    super.key,
    required this.problem,
    required this.onValueChanged,
    required this.dotSizes,
    required this.showTally,
    this.onSubmit,
  });

  @override
  State<CountField20Core> createState() => _CountField20CoreState();
}

class _CountField20CoreState extends State<CountField20Core> {
  final TextEditingController _controller = TextEditingController();
  final Set<int> _tapped = {};
  late List<CountField20Dot> _dots;

  int get _count => (widget.problem.display['count'] as int?) ?? 0;

  @override
  void initState() {
    super.initState();
    _dots = _layout();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CountField20Core oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _controller.clear();
      _tapped.clear();
      _dots = _layout();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  List<CountField20Dot> _layout() => layoutCountField20(
        seed: widget.problem.seed,
        index: widget.problem.index,
        count: _count,
        sizes: widget.dotSizes,
      );

  void _toggle(int index) {
    setState(() {
      if (!_tapped.remove(index)) _tapped.add(index);
    });
  }

  Widget _dot(int index) {
    final isTapped = _tapped.contains(index);
    final size = _dots[index].size;
    return Semantics(
      button: true,
      label: isTapped ? 'Punkt ${index + 1} gezählt' : 'Punkt ${index + 1}',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('cf20-dot-$index'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggle(index),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isTapped ? Colors.green : Colors.indigo,
            border: Border.all(
              color: isTapped ? Colors.green.shade700 : Colors.indigo.shade700,
              width: 2,
            ),
          ),
          child: isTapped
              ? Icon(Icons.check, color: Colors.white, size: size * 0.45)
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: kCountField20Area,
          height: kCountField20Area,
          child: Stack(
            children: [
              for (var i = 0; i < _dots.length; i++)
                Positioned(
                  left: _dots[i].left,
                  top: _dots[i].top,
                  child: _dot(i),
                ),
            ],
          ),
        ),
        if (widget.showTally) ...[
          const SizedBox(height: 8),
          Text(
            'Angetippt: ${_tapped.length}',
            key: const ValueKey('cf20-tapped-count'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
        const SizedBox(height: 12),
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

- [ ] **Step 2: Write the three thin tier widgets**

Create `math_app/lib/widgets/templates/count_field20_enaktiv_widget.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'count_field20_common.dart';

/// Custom-widget template for the registry key `"count_field20_enaktiv"`
/// (quantify_count_zr20 level 1, BUILD_ORDER.md Batch 2.1): uniform 48 px
/// dots scattered without row structure; tapping marks a dot counted and a
/// live "Angetippt: n" tally is shown.
class CountField20EnaktivWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const CountField20EnaktivWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return CountField20Core(
      problem: problem,
      onValueChanged: onValueChanged,
      onSubmit: onSubmit,
      dotSizes: const [48],
      showTally: true,
    );
  }
}
```

Create `math_app/lib/widgets/templates/count_field20_ikonisch_widget.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'count_field20_common.dart';

/// Custom-widget template for the registry key `"count_field20_ikonisch"`
/// (quantify_count_zr20 level 2, BUILD_ORDER.md Batch 2.1): uniform 48 px
/// dots scattered without row structure; tapping still marks a dot counted
/// but the tally is hidden, so the child keeps the running count in their
/// head.
class CountField20IkonischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const CountField20IkonischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return CountField20Core(
      problem: problem,
      onValueChanged: onValueChanged,
      onSubmit: onSubmit,
      dotSizes: const [48],
      showTally: false,
    );
  }
}
```

Create `math_app/lib/widgets/templates/count_field20_symbolisch_widget.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'count_field20_common.dart';

/// Custom-widget template for the registry key `"count_field20_symbolisch"`
/// (quantify_count_zr20 level 3, BUILD_ORDER.md Batch 2.1): dots scattered
/// at three sizes (all >= the 44 px touch-target floor) with the tally
/// hidden, so the child cannot estimate the total from covered area and must
/// actually count.
class CountField20SymbolischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const CountField20SymbolischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return CountField20Core(
      problem: problem,
      onValueChanged: onValueChanged,
      onSubmit: onSubmit,
      dotSizes: const [44, 54, 62],
      showTally: false,
    );
  }
}
```

- [ ] **Step 3: Register the 3 new keys in `kKnownCustomWidgets`**

In `math_app/lib/models/skill_spec.dart`, find the `kKnownCustomWidgets` set (ends with `'compensation_symbolisch',` followed by `};`). Add 3 lines right before the closing `};`:

```dart
  'compensation_symbolisch',
  'count_field20_enaktiv',
  'count_field20_ikonisch',
  'count_field20_symbolisch',
};
```

- [ ] **Step 4: Wire the 3 new widgets into `template_registry.dart`**

Add 3 import lines after the existing `compensation_symbolisch_widget.dart` import:

```dart
import '../widgets/templates/compensation_symbolisch_widget.dart';
import '../widgets/templates/count_field20_enaktiv_widget.dart';
import '../widgets/templates/count_field20_ikonisch_widget.dart';
import '../widgets/templates/count_field20_symbolisch_widget.dart';
```

Add 3 switch arms right before the `_ => const _UnavailableTemplateWidget(),` line, after the `compensation_symbolisch` arm:

```dart
      'count_field20_enaktiv' => CountField20EnaktivWidget(
          problem: problem,
          onValueChanged: onValueChanged,
          onSubmit: onSubmit,
        ),
      'count_field20_ikonisch' => CountField20IkonischWidget(
          problem: problem,
          onValueChanged: onValueChanged,
          onSubmit: onSubmit,
        ),
      'count_field20_symbolisch' => CountField20SymbolischWidget(
          problem: problem,
          onValueChanged: onValueChanged,
          onSubmit: onSubmit,
        ),
      _ => const _UnavailableTemplateWidget(),
```

- [ ] **Step 5: Write the failing generator tests**

In `math_app/test/problem_generators_test.dart`, inside the same `group('custom_widget generators (P2 §5 registry)', () { ... })` that holds the `count_field_*` tests, add these tests right after the test named `'count_field: an empty count_range after clamping is a spec error'` (leave that test and all `count_field_*` tests untouched):

```dart
    test('count_field20_enaktiv: count in [8,12], expected == count', () {
      final s = spec('count_field20_enaktiv', {'count_range': [8, 12]});
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final count = p.display['count'] as int;
          expect(count, inInclusiveRange(8, 12));
          expect(p.expected, [count.toString()]);
          expect(p.display['custom_widget'], 'count_field20_enaktiv');
        }
      }
    });

    test('count_field20_ikonisch: count in [12,16], expected == count', () {
      final s = spec('count_field20_ikonisch', {'count_range': [12, 16]});
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final count = p.display['count'] as int;
          expect(count, inInclusiveRange(12, 16));
          expect(p.expected, [count.toString()]);
          expect(p.display['custom_widget'], 'count_field20_ikonisch');
        }
      }
    });

    test('count_field20_symbolisch: count in [16,20], expected == count', () {
      final s = spec('count_field20_symbolisch', {'count_range': [16, 20]});
      final seen = <int>{};
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final count = p.display['count'] as int;
          seen.add(count);
          expect(count, inInclusiveRange(16, 20));
          expect(p.expected, [count.toString()]);
          expect(p.display['custom_widget'], 'count_field20_symbolisch');
        }
      }
      expect(seen, contains(20), reason: 'the ZR20 upper bound is reachable');
    });

    test('count_field20: an invalid count_range throws instead of clamping',
        () {
      for (final bad in [
        [0, 10],
        [10, 21],
        [12, 8],
        [12],
      ]) {
        final s = spec('count_field20_enaktiv', {'count_range': bad});
        expect(
          () => generateProblems(spec: s, level: 2, seed: 1),
          throwsA(isA<SpecFormatException>()),
          reason: 'count_range $bad must be rejected',
        );
      }
    });
```

- [ ] **Step 6: Run the tests to verify they fail**

Run: `cd math_app && flutter test test/problem_generators_test.dart --plain-name "count_field20"`
Expected: FAIL — the `'count_field20_*'` dispatch cases don't exist yet, so `_generateCustomWidget`'s default branch throws `SpecFormatException('custom_widget: unknown registry key ...')` inside the first three tests. (The "invalid count_range throws" test may already pass for the wrong reason — the three range tests must fail.) Confirm they fail.

- [ ] **Step 7: Implement `_generateCountField20` and wire it into the dispatch switch**

In `math_app/lib/practice/problem_generators.dart`, find `_generateCustomWidget`'s switch. Directly after the `count_field_symbolisch` group:

```dart
    case 'count_field_enaktiv':
    case 'count_field_ikonisch':
    case 'count_field_symbolisch':
      return _generateCountField(spec, level, levelNumber, seed, index, gen);
```

add:

```dart
    case 'count_field20_enaktiv':
    case 'count_field20_ikonisch':
    case 'count_field20_symbolisch':
      return _generateCountField20(spec, level, levelNumber, seed, index, gen);
```

Then add this function directly after `_generateCountField`:

```dart
/// Registry keys `"count_field20_enaktiv"`, `"count_field20_ikonisch"`,
/// `"count_field20_symbolisch"` (quantify_count_zr20, alle drei Level
/// derselben Skill-Spec, BUILD_ORDER.md Batch 2.1): the ZR20 sibling of
/// [_generateCountField]. `display.count` is the number of dots the widget
/// scatters; the typed total is a plain string match against `expected`,
/// handled by `_evaluateCustomWidget`'s default branch. Unlike the ZR10
/// generator this one does not clamp: a `count_range` outside `[1, 20]` (or
/// not a 2-element `[min, max]` list) is a spec-authoring mistake and throws.
Problem _generateCountField20(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final countRange = level.intListParam('count_range');
  if (countRange.length != 2) {
    throw SpecFormatException(
      'count_field20: "count_range" must be a 2-element [min, max] list',
    );
  }
  final lo = countRange[0];
  final hi = countRange[1];
  if (lo < 1 || hi > 20 || lo > hi) {
    throw SpecFormatException(
      'count_field20: count_range [$lo, $hi] must be within [1, 20]',
    );
  }
  final count = gen.nextIntInRange(lo, hi);

  return Problem(
    template: 'custom_widget',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {
      'custom_widget': level.customWidget,
      'count': count,
    },
    expected: [count.toString()],
  );
}
```

- [ ] **Step 8: Run the generator tests to verify they pass**

Run: `cd math_app && flutter test test/problem_generators_test.dart --plain-name "count_field"`
Expected: PASS — the 4 new `count_field20` tests **and** all 6 pre-existing `count_field_*` tests (proving the ZR10 generator is untouched).

- [ ] **Step 9: Write the widget and layout tests**

In `math_app/test/template_widgets_test.dart`:

(a) Add these three imports next to the existing `count_field_symbolisch_widget.dart` import (keep alphabetical order among the `package:math_app/widgets/templates/` imports):

```dart
import 'package:math_app/widgets/templates/count_field20_common.dart';
import 'package:math_app/widgets/templates/count_field20_enaktiv_widget.dart';
import 'package:math_app/widgets/templates/count_field20_ikonisch_widget.dart';
import 'package:math_app/widgets/templates/count_field20_symbolisch_widget.dart';
```

(b) Add this block right after the closing `});` of the `group('CountFieldSymbolischWidget', ...)` (find it by searching for that group name; it is the last of the three `CountField*` groups):

```dart
  group('layoutCountField20', () {
    for (final sizes in <List<double>>[
      [48],
      [44, 54, 62],
    ]) {
      test('no two dots overlap and every dot stays inside the play area '
          '(sizes $sizes, counts 1..20, many seeds)', () {
        for (var count = 1; count <= 20; count++) {
          for (var seed = 0; seed < 60; seed++) {
            for (var index = 0; index < 4; index++) {
              final dots = layoutCountField20(
                seed: seed,
                index: index,
                count: count,
                sizes: sizes,
              );
              expect(dots, hasLength(count));
              const area = Rect.fromLTWH(
                0,
                0,
                kCountField20Area,
                kCountField20Area,
              );
              for (var i = 0; i < dots.length; i++) {
                final r = dots[i].rect;
                expect(area.contains(r.topLeft), isTrue);
                expect(area.contains(r.bottomRight), isTrue);
                expect(sizes, contains(dots[i].size));
                for (var j = i + 1; j < dots.length; j++) {
                  expect(
                    r.overlaps(dots[j].rect),
                    isFalse,
                    reason: 'dots $i and $j overlap '
                        '(seed $seed, index $index, count $count)',
                  );
                }
              }
            }
          }
        }
      });
    }

    test('the layout is a pure function of seed, index, count and sizes', () {
      final a = layoutCountField20(
          seed: 42, index: 3, count: 18, sizes: const [44, 54, 62]);
      final b = layoutCountField20(
          seed: 42, index: 3, count: 18, sizes: const [44, 54, 62]);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].left, b[i].left);
        expect(a[i].top, b[i].top);
        expect(a[i].size, b[i].size);
      }
    });
  });

  for (final tier in <({
    String name,
    String key,
    bool tally,
    Widget Function(Problem, ValueChanged<String>, VoidCallback?) build,
  })>[
    (
      name: 'CountField20EnaktivWidget',
      key: 'count_field20_enaktiv',
      tally: true,
      build: (p, cb, submit) => CountField20EnaktivWidget(
            problem: p,
            onValueChanged: cb,
            onSubmit: submit,
          ),
    ),
    (
      name: 'CountField20IkonischWidget',
      key: 'count_field20_ikonisch',
      tally: false,
      build: (p, cb, submit) => CountField20IkonischWidget(
            problem: p,
            onValueChanged: cb,
            onSubmit: submit,
          ),
    ),
    (
      name: 'CountField20SymbolischWidget',
      key: 'count_field20_symbolisch',
      tally: false,
      build: (p, cb, submit) => CountField20SymbolischWidget(
            problem: p,
            onValueChanged: cb,
            onSubmit: submit,
          ),
    ),
  ]) {
    group(tier.name, () {
      Problem countProblem(int count, {int seed = 7, int index = 0}) => Problem(
            template: 'custom_widget',
            skillId: 'G1',
            level: 1,
            seed: seed,
            index: index,
            promptDe: '',
            display: {'custom_widget': tier.key, 'count': count},
            expected: [count.toString()],
          );

      testWidgets('renders exactly count dots, up to the ZR20 maximum of 20',
          (tester) async {
        await _pumpApp(tester, tier.build(countProblem(20), (_) {}, null));
        for (var i = 0; i < 20; i++) {
          expect(find.byKey(ValueKey('cf20-dot-$i')), findsOneWidget);
        }
        expect(find.byKey(const ValueKey('cf20-dot-20')), findsNothing);
      });

      testWidgets('tapping a dot marks it counted, tapping again unmarks it',
          (tester) async {
        await _pumpApp(tester, tier.build(countProblem(15), (_) {}, null));
        expect(find.byIcon(Icons.check), findsNothing);
        await tester.tap(find.byKey(const ValueKey('cf20-dot-0')));
        await tester.pump();
        expect(find.byIcon(Icons.check), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('cf20-dot-0')));
        await tester.pump();
        expect(find.byIcon(Icons.check), findsNothing);
      });

      testWidgets(
          tier.tally
              ? 'shows a live "Angetippt" tally'
              : 'hides the "Angetippt" tally', (tester) async {
        await _pumpApp(tester, tier.build(countProblem(15), (_) {}, null));
        await tester.tap(find.byKey(const ValueKey('cf20-dot-0')));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('cf20-tapped-count')),
          tier.tally ? findsOneWidget : findsNothing,
        );
        if (tier.tally) expect(find.text('Angetippt: 1'), findsOneWidget);
      });

      testWidgets('typing the total reports it via onValueChanged and Enter '
          'submits', (tester) async {
        final values = <String>[];
        var submitted = false;
        await _pumpApp(
          tester,
          tier.build(countProblem(17), values.add, () => submitted = true),
        );
        await tester.enterText(find.byType(TextField), '17');
        expect(values.last, '17');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        expect(submitted, isTrue);
      });

      testWidgets('a new problem resets the marks and the field, reports ""',
          (tester) async {
        final values = <String>[];
        await _pumpApp(tester, tier.build(countProblem(12), values.add, null));
        await tester.tap(find.byKey(const ValueKey('cf20-dot-0')));
        await tester.enterText(find.byType(TextField), '12');
        await tester.pump();
        expect(find.byIcon(Icons.check), findsOneWidget);

        await _pumpApp(tester, tier.build(countProblem(19), values.add, null));
        expect(values.last, '');
        expect(find.byIcon(Icons.check), findsNothing);
        expect(find.byKey(const ValueKey('cf20-dot-18')), findsOneWidget);
        expect(find.byKey(const ValueKey('cf20-dot-19')), findsNothing);
      });
    });
  }

  testWidgets('CountField20SymbolischWidget draws dots at varying sizes',
      (tester) async {
    await _pumpApp(
      tester,
      CountField20SymbolischWidget(
        problem: Problem(
          template: 'custom_widget',
          skillId: 'G1',
          level: 3,
          seed: 1,
          index: 0,
          promptDe: '',
          display: {'custom_widget': 'count_field20_symbolisch', 'count': 20},
          expected: const ['20'],
        ),
        onValueChanged: (_) {},
      ),
    );
    final sizes = <double>{
      for (var i = 0; i < 20; i++)
        tester.getSize(find.byKey(ValueKey('cf20-dot-$i'))).width,
    };
    expect(sizes.length, greaterThan(1));
    expect(sizes.every((s) => s >= 44), isTrue);
  });
```

- [ ] **Step 10: Run the widget tests to verify they pass**

Run: `cd math_app && flutter test test/template_widgets_test.dart --plain-name "CountField20"` and `cd math_app && flutter test test/template_widgets_test.dart --plain-name "layoutCountField20"`
Expected: PASS. If a `tester.tap` on a dot near the bottom of the 320 px play area reports it is off-screen / hit-test warning, fix the *test harness* (not the widget) by calling `await tester.ensureVisible(find.byKey(...))` before tapping — `_pumpApp` wraps the child in a `SingleChildScrollView`, and dot 0 can sit anywhere in the area.

- [ ] **Step 11: Run the full test suite and `flutter analyze`**

Run: `cd math_app && flutter test && flutter analyze`
Expected: all tests pass (baseline 707 + the new ones); `flutter analyze` issue count stays at the pre-existing baseline (no new issues in the 4 new files — verify with `flutter analyze | grep -i count_field20`, which must print nothing).

- [ ] **Step 12: Commit**

```bash
git add math_app/lib/widgets/templates/count_field20_common.dart \
        math_app/lib/widgets/templates/count_field20_enaktiv_widget.dart \
        math_app/lib/widgets/templates/count_field20_ikonisch_widget.dart \
        math_app/lib/widgets/templates/count_field20_symbolisch_widget.dart \
        math_app/lib/models/skill_spec.dart \
        math_app/lib/practice/template_registry.dart \
        math_app/lib/practice/problem_generators.dart \
        math_app/test/problem_generators_test.dart \
        math_app/test/template_widgets_test.dart
git commit -m "feat(quantify_count_zr20): add count_field20 widget family and generator"
```

---

### Task 2: spec JSON, coverage, and BUILD_ORDER update (first Tier 2 skill)

**Files:**
- Create: `docs/clean-room/v4/skills/specs/quantify_count_zr20.json`
- Create (via sync script): `math_app/assets/skill_specs/quantify_count_zr20.json`
- Modify: `math_app/test/skill_spec_store_test.dart` (1 test)
- Modify: `docs/clean-room/v4/skills/BUILD_ORDER.md` (check off the skill, counts, Tier 2 header, Done entry)

**Interfaces:**
- Consumes: `count_field20_enaktiv`/`count_field20_ikonisch`/`count_field20_symbolisch` (Task 1's widgets, registered already) and `_generateCountField20` (Task 1's generator, dispatched already) — no code changes to either, just a new spec JSON.
- Produces: nothing further downstream.

- [ ] **Step 1: Write the spec JSON**

Create `docs/clean-room/v4/skills/specs/quantify_count_zr20.json`:

```json
{
  "spec_version": 1,
  "skill_id": "quantify_count_zr20",
  "construct_id": "quantify_count",
  "domain": "A",
  "title_de": "Mengen zählen bis 20",
  "level_titles_de": [
    "Zählen mit Tipp-Zähler",
    "Zählen verstreut",
    "Zählen mit verschiedenen Größen"
  ],
  "levels": [
    {
      "level": 1,
      "representation": "enaktiv",
      "template": "custom_widget",
      "custom_widget": "count_field20_enaktiv",
      "params": { "count_range": [8, 12] },
      "problem_count": 8,
      "prompt_de": "Tippe jeden Punkt an und zähle. Wie viele sind es?",
      "slow_band_ms": 20000
    },
    {
      "level": 2,
      "representation": "ikonisch",
      "template": "custom_widget",
      "custom_widget": "count_field20_ikonisch",
      "params": { "count_range": [12, 16] },
      "problem_count": 8,
      "prompt_de": "Zähle die Punkte. Tippe sie an, damit du keinen doppelt zählst. Wie viele sind es?",
      "slow_band_ms": 18000
    },
    {
      "level": 3,
      "representation": "symbolisch",
      "template": "custom_widget",
      "custom_widget": "count_field20_symbolisch",
      "params": { "count_range": [16, 20] },
      "problem_count": 8,
      "prompt_de": "Zähle genau, auch wenn die Punkte unterschiedlich groß sind. Wie viele sind es?",
      "slow_band_ms": 16000
    }
  ],
  "mastery": { "correct_of": 8 },
  "error_taxonomy": [
    { "code": "miscount", "label_de": "knapp daneben", "hint_de": "Ganz nah dran! Zähl noch einmal genau." },
    { "code": "other", "label_de": "noch einmal probieren", "hint_de": "Schau dir die Punkte noch einmal an und probiere es noch einmal." }
  ],
  "provenance": {
    "sources": ["RLP BE/BB Teil C, L1, Niveaustufe A", "Padberg/Benz, Zählprinzipien nach Gelman & Gallistel", "Krajewski, Anzahlerfassung und Zählkompetenz", "Gaidoschik, Ablösung vom zählenden Rechnen als Zielperspektive"],
    "author": "Claude (domain author)",
    "reviewed_by": "open"
  }
}
```

- [ ] **Step 2: Write the spec assertion test**

In `math_app/test/skill_spec_store_test.dart`, add a test right after the `quantify_count_zr10 (Batch 1.1) parses with the count-field widgets` test:

```dart
    test(
        'quantify_count_zr20 (Batch 2.1) parses with the count-field20 widgets',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('quantify_count_zr20');
      expect(spec.constructId, 'quantify_count');
      expect(spec.domain, 'A');
      expect(spec.titleDe, 'Mengen zählen bis 20');
      expect(spec.levels.map((l) => l.customWidget), [
        'count_field20_enaktiv',
        'count_field20_ikonisch',
        'count_field20_symbolisch',
      ]);
    });
```

- [ ] **Step 3: Run the test to verify it passes**

Run: `cd math_app && flutter test test/skill_spec_store_test.dart --plain-name "quantify_count_zr20"`
Expected: PASS.

- [ ] **Step 4: Confirm the project-wide spec smoke test still passes**

Run: `cd math_app && flutter test test/skill_spec_store_test.dart --plain-name "every bundled v4 spec parses and validates"`
Expected: PASS.

- [ ] **Step 5: Sync specs and check coverage**

Run from the repo root (not `math_app/`):

```bash
python scripts/sync_skill_specs.py && python scripts/check_skill_spec_coverage.py
```

Expected: `sync_skill_specs.py` copies `quantify_count_zr20.json` into `math_app/assets/skill_specs/`; `check_skill_spec_coverage.py` reports it moved from missing to covered (`32/93`), `extra` stays empty.

**Immediately verify the sync actually produced the file** — Batch 1.12 shipped with its synced assets uncommitted until a final-review fix caught it:

```bash
ls math_app/assets/skill_specs/quantify_count_zr20.json
```

Expected: the file exists (it is untracked until Step 8's commit, which explicitly lists it). If it does not exist, the sync script failed — stop and investigate.

- [ ] **Step 6: Update `BUILD_ORDER.md`**

In `docs/clean-room/v4/skills/BUILD_ORDER.md`:

1. Change the top-of-file line `62 of 93 skills remain (31 shipped as of Batch 1.13 —` to `61 of 93 skills remain (32 shipped as of Batch 2.1 —` (keep the rest of that sentence exactly as it is).

2. In the "Tier totals are the design doc §3 tally ..." paragraph, change `minus the thirty-one shipped\nskills: 0 / 31 / 11 / 20 remaining.` to `minus the thirty-two shipped\nskills: 0 / 30 / 11 / 20 remaining.` (mind the existing line break; only the words `thirty-one`→`thirty-two` and `0 / 31 / 11 / 20`→`0 / 30 / 11 / 20` change).

3. Change the heading `## Tier 2: Extended (31)` to `## Tier 2: Extended (30 remaining of 31)` and, in the paragraph beneath it, replace `None shipped yet.` with `Batch 2.1 shipped.`

4. Check off the skill under `### Batch 2.1 — counting quantities, unstructured (construct \`quantify_count\`)`, following the format the Tier 1 shipped lines use (`- [x] \`id\` — shipped, \`plan path\`; <original description>`):
   ```
   - [x] `quantify_count_zr20` — shipped, `docs/superpowers/plans/2026-09-20-quantify-count-zr20-batch-2-1.md`; Extended from C1.1's dot field, range raised to 20 with unstructured layouts only (ZR20 becomes the always-unstructured half); seeded grid-cell scatter (no overlap by construction), tally aid at level 1 only, mixed dot sizes at level 3
   ```

5. Add one entry at the END of the `## Done` list (after the `compensation_strategy_zr20` line), in the **plain format every other entry uses — id unbackticked, plan path in backticks**:
   ```
   - [x] quantify_count_zr20 — `docs/superpowers/plans/2026-09-20-quantify-count-zr20-batch-2-1.md`
   ```
   **Also fix the immediately preceding entry**, which was committed without backticks around its plan path (an inconsistency with all 28 entries above it): change
   `- [x] compensation_strategy_zr20 — docs/superpowers/plans/2026-09-20-compensation-strategy-zr20-batch-1-13.md`
   to
   `- [x] compensation_strategy_zr20 — \`docs/superpowers/plans/2026-09-20-compensation-strategy-zr20-batch-1-13.md\``.

6. Update the parenthetical note directly below the `## Done` list (the one starting "(Ids are left unbackticked here on purpose ..."): change `thirty-one` to `thirty-two` and change `1.12, 1.13 and 4.3 above.` to `1.12, 1.13, 2.1 and 4.3 above.`

- [ ] **Step 7: Run the full test suite and `flutter analyze` one more time**

Run: `cd math_app && flutter test && flutter analyze`
Expected: all tests pass (baseline + every test this plan added across both tasks); `flutter analyze` stays at the pre-existing baseline issue count.

- [ ] **Step 8: Commit (the plan file itself included — BUILD_ORDER cites it as provenance)**

```bash
git add docs/clean-room/v4/skills/specs/quantify_count_zr20.json \
        math_app/assets/skill_specs/quantify_count_zr20.json \
        math_app/test/skill_spec_store_test.dart \
        docs/clean-room/v4/skills/BUILD_ORDER.md \
        docs/superpowers/plans/2026-09-20-quantify-count-zr20-batch-2-1.md
git commit -m "feat(quantify_count_zr20): add spec, first Tier 2 (Extended) skill"
```

Run `git status --porcelain` afterwards and confirm none of the five paths above is still `??` or ` M`.

---

## Self-Review Notes

- **Spec coverage:** the BUILD_ORDER line ("range raised to 20 with unstructured layouts only") → Task 1 (grid-cell scatter, no row-structured tier, count up to 20) + Task 2 (`count_range` `[8,12]`/`[12,16]`/`[16,20]`, top of range = 20).
- **Type consistency:** `CountField20Core`'s constructor (`problem`, `onValueChanged`, `onSubmit`, `dotSizes`, `showTally`) is used identically by the 3 tier widgets; `layoutCountField20`'s named params (`seed`, `index`, `count`, `sizes`) match between `common.dart` and the tests; dot keys `cf20-dot-$i` and tally key `cf20-tapped-count` match between widget and tests; registry keys `count_field20_*` match between `kKnownCustomWidgets`, `template_registry`, the generator dispatch, the spec JSON and the tests.
- **Placeholder scan:** none — every step has full code or exact edits.
- **Lessons from earlier batches built in:** plan file committed in Task 2 Step 8 (Batch 1.12/1.13 miss); synced asset explicitly `git add`ed (Batch 1.12 miss); Done entry in the plain format plus a fix for the 1.13 entry's inconsistent formatting; dot keys unique by construction (Batch 1.12 duplicate-key crash); layout overlap is proven by a property test rather than assumed.
