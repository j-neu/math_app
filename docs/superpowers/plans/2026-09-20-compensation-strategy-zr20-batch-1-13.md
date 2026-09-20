# Batch 1.13 — Compensation Strategy (`compensation_strategy_zr20`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship `docs/clean-room/v4/skills/BUILD_ORDER.md` Batch 1.13 — the single skill `compensation_strategy_zr20` — closing out Tier 1 (Reused) entirely (30/30).

**Architecture:** One new custom-widget family (`compensation_*`), following the now-twice-used shape from Batches 1.11/1.12: a standalone, stateful `compensation_enaktiv` widget with its own interaction gating (cover-then-reveal), plus a shared `CompensationCore` used by `compensation_ikonisch`/`compensation_symbolisch` (both static views). One new generator function `_generateCompensation`. Unlike every skill shipped so far, the child's answer is *two* numbers (new red count, new blue count) reported together as a single joined string `"<red>,<blue>"` — this reuses the exact pattern `compare_quantity_difference`/`quantity_compare_common.dart` already established for compound answers (`"links,<n>"`), graded by the same default plain-string-match branch in `_evaluateCustomWidget`, so no `TemplateEvaluator` change is needed.

**Tech Stack:** Flutter/Dart, the v4 skill-spec pipeline (`SkillSpec`/`SkillSpecStore`/`template_registry`/`template_evaluator`/`problem_generators`), `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-09-15-exercise-plan-design.md` (§5, the `compensation_strategy_zr20` archetype entry: "Reused — `S2.3 Opposite Change`... Levels: 1) Covered manipulation → 2) Mental manipulation → 3) Numerical compensation... Example: 8+5 → move 2 from the 5-pile to the 8-pile → 10+3=13"), `docs/skill_spec_authoring_guide.md` (authoring checklist), `math_app/Research/skills_taxonomy.csv` (line 76, the skill's canonical German/English titles and description).

## Global Constraints

- **Exactly 3 levels per spec**, `representation` values `"enaktiv"`, `"ikonisch"`, `"symbolisch"` in that order — `SkillSpec` parsing hard-rejects anything else (`math_app/lib/models/skill_spec.dart:344-351`).
- **Port, don't refactor** (`docs/skill_spec_authoring_guide.md`): the old exercise family (`math_app/lib/exercises/opposite_change_exercise.dart`, `math_app/lib/widgets/opposite_change_level_widget.dart`) stays completely untouched. New widgets are fresh files with an adapted contract, not edits to the old ones. `math_app/lib/widgets/common/wendeplaettchen_widget.dart` is a *shared manipulative* (like `TenStripWidget`/`RechenschiffchenWidget`) — imported directly and unmodified, not "ported".
- **Judgment call, recorded here so it isn't re-litigated mid-task:** the design doc's own worked example ("8+5 → move 2 from the 5-pile to the 8-pile → 10+3=13", a *different* number moving between two piles to simplify an addition fact) does not match what `opposite_change_exercise.dart` actually implements (a single counter flipping color between two piles, sum invariant, child restates the new split). This plan follows the **actual old widget's mechanic** — a genuine "gegensinniges Verändern" (opposite/compensating change) task where the invariant (total stays constant) is the whole point — because "port, don't refactor" means porting real, working code, and the design doc's own Levels 1-3 labels ("Covered manipulation → Mental manipulation → Numerical compensation") map cleanly onto that mechanic's natural EIS progression (see Design Notes below). The `derive_via_10`/`derive_via_5` family (a different construct) already covers the "simplify an addition fact via a nice-number shift" idea the design doc's example illustrates, so nothing is lost.
- **Enter-key submission convention**: every text field's `onSubmitted` calls `widget.onSubmit?.call()` — this skill has *two* number fields per level, so both fields wire it (not just one), matching the project's stated rule ("every text-field-based template widget").
- **Centrally-graded architecture**: the final answer is always reported live via `onValueChanged` and graded by `TemplateEvaluator` against `problem.expected` — no widget self-grades with its own button.
- **Compound-answer convention** (established by `compare_quantity_difference`, BUILD_ORDER.md Batch 1.8): when an answer is naturally two numbers, report them as one joined string (here: `"<red>,<blue>"`, exactly matching the order and format of `expected`) via `onValueChanged` only once *both* fields parse to an integer; report `""` otherwise. This falls through `_evaluateCustomWidget`'s default branch (`_evaluateStringMatch`) with zero new evaluator code, exactly like `quantity_compare_common.dart`'s `"links,<n>"`/`"rechts,<n>"` strings already do.
- **error_taxonomy**: `"other"` only. Unlike Batch 1.12, this generator's `display` has no `op`/`a`/`b` triple of ints (the compound "red,blue" answer format means `_candidateErrorCode`'s numeric-parse checks never fire — same reasoning that already applies to `compare_quantity_difference`, whose `error_taxonomy` is also `"other"`-only). Do not invent a code `_candidateErrorCode` cannot actually emit.
- **No deprecated Flutter APIs in new code**: use `Color.withValues(alpha: x)` if opacity is ever needed (it isn't, in this plan's widgets).
- **`SeededGenerator.nextIntInRange(int min, int max)`** (inclusive), **`SeededGenerator.nextInt(int max)`** (exclusive upper bound, for the coin-flip) and `LevelSpec.intListParam` are the only allowed sources of randomness/params.
- Every new generator function must validate its params and `throw SpecFormatException(...)` on an invalid range.

## Design Notes (read before Task 1)

**Why `red`/`blue` can never be 0 (no extra safety check needed):** `red = gen.nextIntInRange(1, total - 1)` draws from `[1, total-1]`, so `blue = total - red` is also always in `[1, total-1]` — both are guaranteed `>= 1` by construction. The old widget's `_generateProblem` has a redundant-looking `if (flipRedToBlue && _redCount == 0) ...` guard that can never actually fire given its own generation logic; this plan's generator does not port that dead code.

**Why the 3 levels' number ranges are exactly the old widget's 3 level ranges:** the old widget already had a 3-level *difficulty* curve (Level 1: totals 4–10, Level 2: 6–15, Level 3: 10–20) but used the *same* interaction (cover, animate, reveal-nothing, ask) at every level — only the numbers grew. This plan repurposes the level axis for *representation* (per the design doc's "Covered → Mental → Numerical" labels) while reusing the old widget's exact, curriculum-tuned number ranges per tier — difficulty and representation-abstraction grow together, which is how several other batches in this project already behave (e.g. `derive_via_10`'s ranges widen level-to-level too).

**Why `compensation_enaktiv` is standalone (mirrors the `tens_sub_enaktiv` precedent from Batch 1.12):** its interaction — show the pile, let the child press "Zudecken" to cover it, *then* reveal the two input fields — is a real state-gated flow (fields only appear after the cover button is pressed) that the static `ikonisch`/`symbolisch` tiers don't have. `compensation_ikonisch` and `compensation_symbolisch` share `CompensationCore`, which always shows both input fields immediately alongside whatever `buildScene` renders (a live picture, or bare text).

**Mapping the design doc's own level labels directly:**
- **Level 1 (enaktiv) — "Covered manipulation":** the counter pile is shown, then covered on button-press; the child reconstructs the new split from memory once the fields appear.
- **Level 2 (ikonisch) — "Mental manipulation":** the counter pile stays visible the whole time (never covered); the child reasons about the change from the static picture rather than acting on it.
- **Level 3 (symbolisch) — "Numerical compensation":** no picture at all — bare numbers and the change sentence only.

**Compound-answer format, concretely:** for a problem with `red=6`, `blue=3`, `flip="red_to_blue"` (one red becomes blue), `newRed = 5`, `newBlue = 4`, so `expected: ["5,4"]`, and the widget must report exactly `"5,4"` (in that order) once both fields are filled with `5` and `4` respectively.

---

### Task 1: `compensation_*` widget family, generator, registry wiring, tests

**Files:**
- Create: `math_app/lib/widgets/templates/compensation_common.dart`
- Create: `math_app/lib/widgets/templates/compensation_enaktiv_widget.dart`
- Create: `math_app/lib/widgets/templates/compensation_ikonisch_widget.dart`
- Create: `math_app/lib/widgets/templates/compensation_symbolisch_widget.dart`
- Modify: `math_app/lib/models/skill_spec.dart` (add 3 keys to `kKnownCustomWidgets`)
- Modify: `math_app/lib/practice/template_registry.dart` (3 imports + 3 switch arms)
- Modify: `math_app/lib/practice/problem_generators.dart` (new `_generateCompensation`, 3 switch cases)
- Modify: `math_app/test/problem_generators_test.dart` (2 tests)
- Modify: `math_app/test/template_widgets_test.dart` (3 widget-test groups)

**Interfaces:**
- Consumes: `WendeplaettchenWidget({Key? key, required Color color, double size = 40.0, VoidCallback? onTap, bool isFlipped = false})` (`math_app/lib/widgets/common/wendeplaettchen_widget.dart`, unmodified). `SeededGenerator.nextIntInRange(int, int)`, `SeededGenerator.nextInt(int)` (`math_app/lib/practice/problem_generators.dart:17-31`), `LevelSpec.intListParam(String key)` (`math_app/lib/models/skill_spec.dart`). `SpecFormatException`. `Problem` constructor with named params `template, skillId, level, seed, index, promptDe, display, expected` — see `_generateTensSub` (`math_app/lib/practice/problem_generators.dart`, Batch 1.12) for the exact usage pattern.
- Produces: `CompensationCore` widget (`math_app/lib/widgets/templates/compensation_common.dart`) with constructor `CompensationCore({required Problem problem, required ValueChanged<String> onValueChanged, required Widget Function(BuildContext, int total, int red, int blue, String flip) buildScene, VoidCallback? onSubmit})`. Registry keys `'compensation_enaktiv'`, `'compensation_ikonisch'`, `'compensation_symbolisch'` in `kKnownCustomWidgets` and `template_registry.dart`'s `custom_widget` switch. Generator function `_generateCompensation(SkillSpec, LevelSpec, int, int, int, SeededGenerator) -> Problem`, dispatched from `_generateCustomWidget`'s switch for those same 3 keys.

- [ ] **Step 1: Write the standalone `CompensationEnaktivWidget`**

Create `math_app/lib/widgets/templates/compensation_enaktiv_widget.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../common/wendeplaettchen_widget.dart';

/// Enaktiv tier of `compensation_strategy_zr20` (BUILD_ORDER.md Batch
/// 1.13): shows the two-colour counter pile, lets the child press a
/// button to cover it once they've studied the starting counts and the
/// change rule, then reveals two input fields and asks for the new
/// red/blue counts from memory -- mirroring the old engine's
/// `OppositeChangeLevelWidget` cover-then-reveal flow
/// (math_app/lib/widgets/opposite_change_level_widget.dart, untouched;
/// this is a fresh copy with a simplified, non-animated cover and an
/// adapted contract, not a refactor of the original). Both counts are
/// reported together as a single `"red,blue"` string via [onValueChanged]
/// once both fields parse -- graded centrally via a plain string match
/// against `problem.expected`, like every other custom_widget.
class CompensationEnaktivWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const CompensationEnaktivWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  @override
  State<CompensationEnaktivWidget> createState() =>
      _CompensationEnaktivWidgetState();
}

class _CompensationEnaktivWidgetState
    extends State<CompensationEnaktivWidget> {
  bool _covered = false;
  final TextEditingController _redController = TextEditingController();
  final TextEditingController _blueController = TextEditingController();

  int get _total => (widget.problem.display['total'] as num).toInt();
  int get _red => (widget.problem.display['red'] as num).toInt();
  int get _blue => (widget.problem.display['blue'] as num).toInt();
  String get _flip => widget.problem.display['flip'] as String;

  String get _changeText =>
      _flip == 'red_to_blue' ? 'Eine rote wird blau.' : 'Eine blaue wird rot.';

  @override
  void didUpdateWidget(covariant CompensationEnaktivWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      setState(() {
        _covered = false;
        _redController.clear();
        _blueController.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  @override
  void dispose() {
    _redController.dispose();
    _blueController.dispose();
    super.dispose();
  }

  void _reportIfComplete() {
    final red = int.tryParse(_redController.text);
    final blue = int.tryParse(_blueController.text);
    if (red != null && blue != null) {
      widget.onValueChanged('$red,$blue');
    } else {
      widget.onValueChanged('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Gesamt: $_total',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_changeText, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 16),
        if (!_covered)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < _red; i++)
                  WendeplaettchenWidget(
                    key: ValueKey('comp-red-$i'),
                    color: Colors.red,
                  ),
                for (var i = 0; i < _blue; i++)
                  WendeplaettchenWidget(
                    key: ValueKey('comp-blue-$i'),
                    color: Colors.blue,
                  ),
              ],
            ),
          )
        else
          Container(
            width: 200,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.help_outline, size: 48, color: Colors.grey.shade600),
          ),
        const SizedBox(height: 16),
        if (!_covered)
          ElevatedButton(
            key: const ValueKey('comp-cover-button'),
            onPressed: () => setState(() => _covered = true),
            child: const Text('Zudecken'),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInput('Rot', Colors.red, _redController),
              const SizedBox(width: 24),
              _buildInput('Blau', Colors.blue, _blueController),
            ],
          ),
      ],
    );
  }

  Widget _buildInput(
    String label,
    Color color,
    TextEditingController controller,
  ) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          width: 60,
          child: TextField(
            key: ValueKey('comp-input-$label'),
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onChanged: (_) => _reportIfComplete(),
            onSubmitted: (_) => widget.onSubmit?.call(),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Write the shared `CompensationCore` and its 2 static tiers**

Create `math_app/lib/widgets/templates/compensation_common.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Shared interaction core for the `compensation_ikonisch`/
/// `compensation_symbolisch` custom widgets (compensation_strategy_zr20,
/// BUILD_ORDER.md Batch 1.13): renders the scene via [buildScene], then
/// two number fields (red/blue) whose combined `"red,blue"` string is
/// reported live via [onValueChanged] once both parse -- graded centrally
/// like every other custom_widget. `compensation_enaktiv` (cover-then-
/// reveal) is a standalone widget and does not use this core.
class CompensationCore extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final Widget Function(BuildContext context, int total, int red, int blue, String flip)
      buildScene;
  final VoidCallback? onSubmit;

  const CompensationCore({
    super.key,
    required this.problem,
    required this.onValueChanged,
    required this.buildScene,
    this.onSubmit,
  });

  @override
  State<CompensationCore> createState() => _CompensationCoreState();
}

class _CompensationCoreState extends State<CompensationCore> {
  final TextEditingController _redController = TextEditingController();
  final TextEditingController _blueController = TextEditingController();

  int get _total => (widget.problem.display['total'] as num).toInt();
  int get _red => (widget.problem.display['red'] as num).toInt();
  int get _blue => (widget.problem.display['blue'] as num).toInt();
  String get _flip => widget.problem.display['flip'] as String;

  @override
  void didUpdateWidget(covariant CompensationCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _redController.clear();
      _blueController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  @override
  void dispose() {
    _redController.dispose();
    _blueController.dispose();
    super.dispose();
  }

  void _reportIfComplete() {
    final red = int.tryParse(_redController.text);
    final blue = int.tryParse(_blueController.text);
    if (red != null && blue != null) {
      widget.onValueChanged('$red,$blue');
    } else {
      widget.onValueChanged('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.buildScene(context, _total, _red, _blue, _flip),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInput('Rot', Colors.red, _redController),
            const SizedBox(width: 24),
            _buildInput('Blau', Colors.blue, _blueController),
          ],
        ),
      ],
    );
  }

  Widget _buildInput(
    String label,
    Color color,
    TextEditingController controller,
  ) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          width: 60,
          child: TextField(
            key: ValueKey('comp-input-$label'),
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onChanged: (_) => _reportIfComplete(),
            onSubmitted: (_) => widget.onSubmit?.call(),
          ),
        ),
      ],
    );
  }
}
```

Create `math_app/lib/widgets/templates/compensation_ikonisch_widget.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../common/wendeplaettchen_widget.dart';
import 'compensation_common.dart';

/// Ikonisch tier of `compensation_strategy_zr20` (BUILD_ORDER.md Batch
/// 1.13): the counter pile stays visible the whole time (never covered) --
/// "mental manipulation": the child reasons about the change from a
/// static picture rather than reconstructing it from memory.
class CompensationIkonischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const CompensationIkonischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  static String _changeText(String flip) =>
      flip == 'red_to_blue' ? 'Eine rote wird blau.' : 'Eine blaue wird rot.';

  static Widget _scene(
    BuildContext context,
    int total,
    int red,
    int blue,
    String flip,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Gesamt: $total',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_changeText(flip), style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 16),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < red; i++)
                WendeplaettchenWidget(
                  key: ValueKey('comp-ik-red-$i'),
                  color: Colors.red,
                ),
              for (var i = 0; i < blue; i++)
                WendeplaettchenWidget(
                  key: ValueKey('comp-ik-blue-$i'),
                  color: Colors.blue,
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompensationCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildScene: _scene,
      onSubmit: onSubmit,
    );
  }
}
```

Create `math_app/lib/widgets/templates/compensation_symbolisch_widget.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'compensation_common.dart';

/// Symbolisch tier of `compensation_strategy_zr20` (BUILD_ORDER.md Batch
/// 1.13): no counters at all -- bare numbers and text only, the most
/// abstract of the 3 representations ("numerical compensation").
class CompensationSymbolischWidget extends StatelessWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;

  const CompensationSymbolischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
    this.onSubmit,
  });

  static String _changeText(String flip) =>
      flip == 'red_to_blue' ? 'Eine rote wird blau.' : 'Eine blaue wird rot.';

  static Widget _scene(
    BuildContext context,
    int total,
    int red,
    int blue,
    String flip,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$red rot, $blue blau (zusammen $total)',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(_changeText(flip), style: const TextStyle(fontSize: 18)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompensationCore(
      problem: problem,
      onValueChanged: onValueChanged,
      buildScene: _scene,
      onSubmit: onSubmit,
    );
  }
}
```

- [ ] **Step 3: Register the 3 new keys in `kKnownCustomWidgets`**

In `math_app/lib/models/skill_spec.dart`, find the `kKnownCustomWidgets` set (ends with `'tens_sub_symbolisch',` followed by `};`). Add 3 lines right before the closing `};`:

```dart
  'tens_sub_enaktiv',
  'tens_sub_ikonisch',
  'tens_sub_symbolisch',
  'compensation_enaktiv',
  'compensation_ikonisch',
  'compensation_symbolisch',
};
```

- [ ] **Step 4: Wire the 3 new widgets into `template_registry.dart`**

Add 3 import lines after the existing `tens_sub_symbolisch_widget.dart` import:

```dart
import '../widgets/templates/tens_sub_symbolisch_widget.dart';
import '../widgets/templates/compensation_enaktiv_widget.dart';
import '../widgets/templates/compensation_ikonisch_widget.dart';
import '../widgets/templates/compensation_symbolisch_widget.dart';
```

Add 3 switch arms right before the `_ => const _UnavailableTemplateWidget(),` line, after the `tens_sub_symbolisch` arm:

```dart
      'tens_sub_symbolisch' => TensSubSymbolischWidget(
          problem: problem,
          onValueChanged: onValueChanged,
          onSubmit: onSubmit,
        ),
      'compensation_enaktiv' => CompensationEnaktivWidget(
          problem: problem,
          onValueChanged: onValueChanged,
          onSubmit: onSubmit,
        ),
      'compensation_ikonisch' => CompensationIkonischWidget(
          problem: problem,
          onValueChanged: onValueChanged,
          onSubmit: onSubmit,
        ),
      'compensation_symbolisch' => CompensationSymbolischWidget(
          problem: problem,
          onValueChanged: onValueChanged,
          onSubmit: onSubmit,
        ),
      _ => const _UnavailableTemplateWidget(),
```

- [ ] **Step 5: Write the failing generator test**

In `math_app/test/problem_generators_test.dart`, inside `group('custom_widget generators (P2 §5 registry)', () { ... })`, add:

```dart
    test('compensation_enaktiv: red/blue always >= 1, sum invariant after '
        'the flip, expected == "newRed,newBlue"', () {
      final s = spec('compensation_enaktiv', {
        'total_range': [4, 10],
      });
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final total = p.display['total'] as int;
          final red = p.display['red'] as int;
          final blue = p.display['blue'] as int;
          final flip = p.display['flip'] as String;
          expect(total, inInclusiveRange(4, 10));
          expect(red, greaterThanOrEqualTo(1));
          expect(blue, greaterThanOrEqualTo(1));
          expect(red + blue, total);
          expect(['red_to_blue', 'blue_to_red'], contains(flip));

          final newRed = flip == 'red_to_blue' ? red - 1 : red + 1;
          final newBlue = flip == 'red_to_blue' ? blue + 1 : blue - 1;
          expect(newRed + newBlue, total, reason: 'sum stays invariant');
          expect(p.expected, ['$newRed,$newBlue']);
          expect(p.display['custom_widget'], 'compensation_enaktiv');
        }
      }
    });

    test('compensation: total_range outside [2,20] throws', () {
      final s = spec('compensation_enaktiv', {
        'total_range': [1, 10],
      });
      expect(
        () => generateProblems(spec: s, level: 2, seed: 0),
        throwsA(isA<SpecFormatException>()),
      );
    });
```

- [ ] **Step 6: Run the test to verify it fails**

Run: `cd math_app && flutter test test/problem_generators_test.dart --plain-name "compensation"`
Expected: FAIL — `_generateCompensation` and the `'compensation_enaktiv'` dispatch case don't exist yet, so the default branch throws `SpecFormatException('custom_widget: unknown registry key "compensation_enaktiv"')`. The second test (which expects exactly that exception, just for a different reason) may already pass; the first test must fail. Confirm the first test fails.

- [ ] **Step 7: Implement `_generateCompensation` and wire it into the dispatch switch**

In `math_app/lib/practice/problem_generators.dart`, find `_generateCustomWidget`'s switch (the one with the `tens_sub_*` case added in Batch 1.12). Add a new case group right after it, before `case 'halving_mirror_enaktiv':`:

```dart
    case 'tens_sub_enaktiv':
    case 'tens_sub_ikonisch':
    case 'tens_sub_symbolisch':
      return _generateTensSub(spec, level, levelNumber, seed, index, gen);
    case 'compensation_enaktiv':
    case 'compensation_ikonisch':
    case 'compensation_symbolisch':
      return _generateCompensation(spec, level, levelNumber, seed, index, gen);
    case 'halving_mirror_enaktiv':
```

Then add the generator function anywhere among the other `_generateX` functions (e.g. right after `_generateTensSub`):

```dart
/// Registry keys `"compensation_enaktiv"`, `"compensation_ikonisch"`,
/// `"compensation_symbolisch"` (compensation_strategy_zr20, BUILD_ORDER.md
/// Batch 1.13): splits a `total` into `red`/`blue` (both >= 1 by
/// construction -- `red` is drawn from `[1, total-1]`, so `blue = total -
/// red` is also in `[1, total-1]`), then coin-flips a direction for which
/// colour loses one unit to the other -- the sum stays invariant
/// ("gegensinniges Verändern"). `display` carries `total`/`red`/`blue`
/// plus `flip` (`"red_to_blue"` or `"blue_to_red"`); `expected` is the
/// single joined string `"<newRed>,<newBlue>"`, matching exactly what
/// every widget's two number fields report once both parse -- graded by
/// the default plain string match in `_evaluateCustomWidget`.
Problem _generateCompensation(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final totalRange = level.intListParam('total_range');
  if (totalRange.length != 2) {
    throw SpecFormatException(
      'compensation: "total_range" must be a 2-element [min, max] list',
    );
  }
  final lo = totalRange[0];
  final hi = totalRange[1];
  if (lo < 2 || hi > 20 || lo > hi) {
    throw SpecFormatException(
      'compensation: total_range [$lo, $hi] must be within [2, 20]',
    );
  }

  final total = gen.nextIntInRange(lo, hi);
  final red = gen.nextIntInRange(1, total - 1);
  final blue = total - red;
  final flipToBlue = gen.nextInt(2) == 0;
  final newRed = flipToBlue ? red - 1 : red + 1;
  final newBlue = flipToBlue ? blue + 1 : blue - 1;

  return Problem(
    template: 'custom_widget',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {
      'custom_widget': level.customWidget,
      'total': total,
      'red': red,
      'blue': blue,
      'flip': flipToBlue ? 'red_to_blue' : 'blue_to_red',
    },
    expected: ['$newRed,$newBlue'],
  );
}
```

- [ ] **Step 8: Run the test to verify it passes**

Run: `cd math_app && flutter test test/problem_generators_test.dart --plain-name "compensation"`
Expected: PASS (both tests).

- [ ] **Step 9: Write widget tests**

In `math_app/test/template_widgets_test.dart`, add imports alongside the existing `tens_sub_*` imports:

```dart
import 'package:math_app/widgets/templates/compensation_enaktiv_widget.dart';
import 'package:math_app/widgets/templates/compensation_ikonisch_widget.dart';
import 'package:math_app/widgets/templates/compensation_symbolisch_widget.dart';
```

Add 3 new groups anywhere in the file (e.g. after the last `tens_sub_*` group):

```dart
  group('CompensationEnaktivWidget', () {
    Problem compProblem({
      required int total,
      required int red,
      required int blue,
      required String flip,
    }) {
      final newRed = flip == 'red_to_blue' ? red - 1 : red + 1;
      final newBlue = flip == 'red_to_blue' ? blue + 1 : blue - 1;
      return _problem(
        template: 'custom_widget',
        display: {
          'custom_widget': 'compensation_enaktiv',
          'total': total,
          'red': red,
          'blue': blue,
          'flip': flip,
        },
        expected: ['$newRed,$newBlue'],
      );
    }

    testWidgets(
        'pressing Zudecken covers the pile and reveals the input fields; '
        'filling both reports the joined answer', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompensationEnaktivWidget(
              problem: compProblem(
                total: 8,
                red: 6,
                blue: 2,
                flip: 'red_to_blue',
              ),
              onValueChanged: values.add,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Gesamt: 8'), findsOneWidget);
      expect(find.text('Eine rote wird blau.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.byKey(const ValueKey('comp-cover-button')));
      await tester.pump();

      expect(find.byType(TextField), findsNWidgets(2));
      await tester.enterText(
        find.byKey(const ValueKey('comp-input-Rot')),
        '5',
      );
      await tester.pump();
      expect(values.last, '');
      await tester.enterText(
        find.byKey(const ValueKey('comp-input-Blau')),
        '3',
      );
      await tester.pump();

      expect(values.last, '5,3');
    });

    testWidgets('a new problem resets to uncovered with no fields',
        (tester) async {
      final values = <String>[];
      Widget host(Problem p) => MaterialApp(
            home: Scaffold(
              body: CompensationEnaktivWidget(
                problem: p,
                onValueChanged: values.add,
              ),
            ),
          );

      await tester.pumpWidget(
        host(compProblem(total: 8, red: 6, blue: 2, flip: 'red_to_blue')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('comp-cover-button')));
      await tester.pump();
      expect(find.byType(TextField), findsNWidgets(2));

      await tester.pumpWidget(
        host(compProblem(total: 9, red: 4, blue: 5, flip: 'blue_to_red')),
      );
      await tester.pump();

      expect(values.last, '');
      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(const ValueKey('comp-cover-button')), findsOneWidget);
    });
  });

  group('CompensationIkonischWidget', () {
    testWidgets('renders the pile and fields together, no cover step',
        (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompensationIkonischWidget(
              problem: _problem(
                template: 'custom_widget',
                display: {
                  'custom_widget': 'compensation_ikonisch',
                  'total': 10,
                  'red': 4,
                  'blue': 6,
                  'flip': 'blue_to_red',
                },
                expected: ['5,5'],
              ),
              onValueChanged: values.add,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Gesamt: 10'), findsOneWidget);
      expect(find.text('Eine blaue wird rot.'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));

      await tester.enterText(find.byKey(const ValueKey('comp-input-Rot')), '5');
      await tester.enterText(find.byKey(const ValueKey('comp-input-Blau')), '5');
      await tester.pump();

      expect(values.last, '5,5');
    });
  });

  group('CompensationSymbolischWidget', () {
    testWidgets('renders bare numbers and text, no counter pile',
        (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompensationSymbolischWidget(
              problem: _problem(
                template: 'custom_widget',
                display: {
                  'custom_widget': 'compensation_symbolisch',
                  'total': 15,
                  'red': 9,
                  'blue': 6,
                  'flip': 'red_to_blue',
                },
                expected: ['8,7'],
              ),
              onValueChanged: values.add,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('9 rot, 6 blau (zusammen 15)'), findsOneWidget);
      expect(find.text('Eine rote wird blau.'), findsOneWidget);
      expect(find.byType(WendeplaettchenWidget), findsNothing);
    });
  });
```

Note: `WendeplaettchenWidget` needs its own import in the test file if not already present — add `import 'package:math_app/widgets/common/wendeplaettchen_widget.dart';` alongside the other widget imports if it's missing.

- [ ] **Step 10: Run the widget tests to verify they pass**

Run: `cd math_app && flutter test test/template_widgets_test.dart --plain-name "Compensation"`
Expected: PASS (all 4 tests across the 3 groups).

- [ ] **Step 11: Run the full test suite and `flutter analyze`**

Run: `cd math_app && flutter test && flutter analyze`
Expected: all tests pass (baseline count + the new ones added in this task); `flutter analyze` issue count stays at the pre-existing baseline (no new issues).

- [ ] **Step 12: Commit**

```bash
git add math_app/lib/widgets/templates/compensation_common.dart \
        math_app/lib/widgets/templates/compensation_enaktiv_widget.dart \
        math_app/lib/widgets/templates/compensation_ikonisch_widget.dart \
        math_app/lib/widgets/templates/compensation_symbolisch_widget.dart \
        math_app/lib/models/skill_spec.dart \
        math_app/lib/practice/template_registry.dart \
        math_app/lib/practice/problem_generators.dart \
        math_app/test/problem_generators_test.dart \
        math_app/test/template_widgets_test.dart
git commit -m "feat(compensation_strategy_zr20): add compensation widget family and generator"
```

---

### Task 2: spec JSON, coverage, and BUILD_ORDER close-out (Tier 1 complete)

**Files:**
- Create: `docs/clean-room/v4/skills/specs/compensation_strategy_zr20.json`
- Modify: `math_app/test/skill_spec_store_test.dart` (1 test)
- Modify: `docs/clean-room/v4/skills/BUILD_ORDER.md` (check off the skill, add a `## Done` entry, correct the running counts — this closes out Tier 1 entirely)

**Interfaces:**
- Consumes: `compensation_enaktiv`/`compensation_ikonisch`/`compensation_symbolisch` (Task 1's widgets, registered already) and `_generateCompensation` (Task 1's generator, dispatched already) — no code changes to either, just a new spec JSON.
- Produces: nothing further downstream — this is the batch's last task.

- [ ] **Step 1: Write the spec JSON**

Create `docs/clean-room/v4/skills/specs/compensation_strategy_zr20.json`:

```json
{
  "spec_version": 1,
  "skill_id": "compensation_strategy_zr20",
  "construct_id": "compensation_strategy",
  "domain": "C",
  "title_de": "Gegensinniges Verändern",
  "level_titles_de": [
    "Zugedeckt merken (ZR10)",
    "Bild bleibt sichtbar (ZR15)",
    "Nur Zahlen (ZR20)"
  ],
  "levels": [
    {
      "level": 1,
      "representation": "enaktiv",
      "template": "custom_widget",
      "custom_widget": "compensation_enaktiv",
      "params": { "total_range": [4, 10] },
      "problem_count": 8,
      "prompt_de": "Merke dir Rot und Blau. Wie viele sind es nach der Veränderung?",
      "slow_band_ms": 14000
    },
    {
      "level": 2,
      "representation": "ikonisch",
      "template": "custom_widget",
      "custom_widget": "compensation_ikonisch",
      "params": { "total_range": [6, 15] },
      "problem_count": 8,
      "prompt_de": "Wie viele sind es nach der Veränderung?",
      "slow_band_ms": 11000
    },
    {
      "level": 3,
      "representation": "symbolisch",
      "template": "custom_widget",
      "custom_widget": "compensation_symbolisch",
      "params": { "total_range": [10, 20] },
      "problem_count": 8,
      "prompt_de": "Rechne im Kopf.",
      "slow_band_ms": 8000
    }
  ],
  "mastery": { "correct_of": 8 },
  "error_taxonomy": [
    { "code": "other", "label_de": "noch einmal probieren", "hint_de": "Eine Farbe wird zur anderen. Die Gesamtzahl bleibt gleich." }
  ],
  "provenance": {
    "sources": ["iMINT S2.3 Opposite Change", "Padberg/Benz, Gegensinniges Verändern"],
    "author": "Claude (domain author)",
    "reviewed_by": "open"
  }
}
```

- [ ] **Step 2: Write the spec assertion test**

In `math_app/test/skill_spec_store_test.dart`, add a test right after the `tens_sub_crossing_hundred` test:

```dart
    test('compensation_strategy_zr20 parses with the compensation widgets',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('compensation_strategy_zr20');
      expect(spec.constructId, 'compensation_strategy');
      expect(spec.domain, 'C');
      expect(spec.titleDe, 'Gegensinniges Verändern');
      expect(spec.levels.map((l) => l.customWidget), [
        'compensation_enaktiv',
        'compensation_ikonisch',
        'compensation_symbolisch',
      ]);
    });
```

- [ ] **Step 3: Run the test to verify it passes**

Run: `cd math_app && flutter test test/skill_spec_store_test.dart --plain-name "compensation_strategy_zr20"`
Expected: PASS.

- [ ] **Step 4: Confirm the project-wide spec smoke test still passes**

Run: `cd math_app && flutter test test/skill_spec_store_test.dart --plain-name "every bundled v4 spec parses and validates"`
Expected: PASS.

- [ ] **Step 5: Sync specs and check coverage**

Run from the repo root (not `math_app/`):

```bash
python scripts/sync_skill_specs.py && python scripts/check_skill_spec_coverage.py
```

Expected: `sync_skill_specs.py` copies `compensation_strategy_zr20.json` into `math_app/assets/skill_specs/`; `check_skill_spec_coverage.py` reports it moved from missing to covered, `extra` stays empty.

**Immediately verify the sync actually produced a tracked file, not just a working-tree file** — a prior batch (1.12) shipped with its synced assets left uncommitted until a final-review fix caught it:

```bash
git status --porcelain math_app/assets/skill_specs/compensation_strategy_zr20.json
```

Expected: `??` right now (it's not committed yet) — this step is just confirming the file exists on disk; Step 8's commit is what tracks it. If the file does not exist at all, the sync script failed — stop and investigate before continuing.

- [ ] **Step 6: Update `BUILD_ORDER.md`**

In `docs/clean-room/v4/skills/BUILD_ORDER.md`:

1. Change the top-of-file line:
   ```
   63 of 93 skills remain (30 shipped as of Batch 1.12 --
   ```
   to:
   ```
   62 of 93 skills remain (31 shipped as of Batch 1.13 --
   ```

2. Change `## Tier 1: Reused (1 remaining of 30)` to `## Tier 1: Reused (0 remaining of 30)`.

3. Check off the skill under `### Batch 1.13 — compensation (construct \`compensation_strategy\`)`:
   ```
   - [x] `compensation_strategy_zr20` — shipped, `docs/superpowers/plans/2026-09-20-compensation-strategy-zr20-batch-1-13.md`; Reused from S2.3 `Opposite Change` (`opposite_change_exercise.dart`); two-pile counters, simultaneous +1/−1 manipulation
   ```

4. Add one entry to the `## Done` list at the bottom, matching the **plain, unbackticked format** every other entry in that list uses (Batch 1.12's entries were briefly non-compliant with this and had to be fixed after the fact — do not repeat that mistake):
   ```
   - [x] compensation_strategy_zr20 — docs/superpowers/plans/2026-09-20-compensation-strategy-zr20-batch-1-13.md
   ```
   Also update the parenthetical note directly below the `## Done` list (the one starting "(Ids are left unbackticked here on purpose...)") — it currently ends with `"...these thirty are tracked in Batches 1.1, 1.2, ..., 1.12 and 4.3 above."`; change `thirty` to `thirty-one` and add `, 1.13` to the batch list (before "and 4.3").

- [ ] **Step 7: Run the full test suite and `flutter analyze` one more time**

Run: `cd math_app && flutter test && flutter analyze`
Expected: all tests pass (baseline + every test this plan added across both tasks); `flutter analyze` stays at the pre-existing baseline issue count.

- [ ] **Step 8: Commit**

```bash
git add docs/clean-room/v4/skills/specs/compensation_strategy_zr20.json \
        math_app/assets/skill_specs/compensation_strategy_zr20.json \
        math_app/test/skill_spec_store_test.dart \
        docs/clean-room/v4/skills/BUILD_ORDER.md
git commit -m "feat(compensation_strategy_zr20): add spec, close out Tier 1 (Reused, 30/30)"
```

---

## Self-Review Notes

- **Spec coverage:** the single taxonomy row (`math_app/Research/skills_taxonomy.csv:76`) has a task producing its spec (Task 1 → widgets/generator, Task 2 → spec JSON). The design doc's own Level 1-3 labels ("Covered manipulation → Mental manipulation → Numerical compensation") are mapped explicitly onto the 3 tiers in the Design Notes section, with the deviation from the design doc's specific worked example flagged as a recorded judgment call in Global Constraints, not silently substituted.
- **Placeholder scan:** every step has literal, runnable code — no "add validation"/"similar to Task N" placeholders.
- **Type consistency:** `CompensationCore.buildScene` is `Widget Function(BuildContext, int total, int red, int blue, String flip)` in both its Task-1 definition and both static tier widgets' usage. `_generateCompensation`'s signature matches every other `_generateX` function's `(SkillSpec, LevelSpec, int, int, int, SeededGenerator) -> Problem` shape used throughout `problem_generators.dart`. The compound-answer format (`"red,blue"`) is used identically in the generator's `expected`, both widgets' `onValueChanged` reports, and every test's assertions.
- **Batch-1.12 lesson applied:** Task 2 Step 5 explicitly calls out verifying the synced asset file actually gets created (the exact gap a final-review fix round had to catch in the prior batch), and Step 6.4 pre-empts the BUILD_ORDER.md backtick-format mistake by stating the correct plain format up front instead of leaving it to be caught later.
