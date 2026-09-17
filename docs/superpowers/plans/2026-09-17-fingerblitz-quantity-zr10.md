# fingerblitz_quantity_zr10 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `fingerblitz_quantity_zr10` (BUILD_ORDER.md Batch 1.9, construct `fingerblitz`) playable: instant recognition of a finger-pattern quantity, reused directly from `S1.1 Fingerblitz`'s "See (No limit) → See (Flash)" levels (`docs/superpowers/specs/2026-09-15-exercise-plan-design.md:370-374`).

**Architecture:** No new widget files. Level 1 (untimed) reuses the existing generic `fingerbild_read` template as-is (`math_app/lib/practice/problem_generators.dart:1671-1703`, `math_app/lib/widgets/templates/fingerbild_read_widget.dart`) — already supports up to 10 fingers across two hands with no flash. Levels 2/3 (flashed) extend the existing `flash_subitize` custom_widget with a third pattern option, `"fingers"`, alongside its current `"dots"`/`"rekenrek"` — a small, surgical addition to `_generateFlashSubitize` and `FlashSubitizeWidget._visual()` that reuses `FingerBildWidget` (`math_app/lib/widgets/manipulatives/fingerbild.dart`, already used by `fingerbild_read_widget.dart`) for the flashed rendering, and lifts `flash_subitize`'s hard 5-count cap to a hands-dependent cap (1 hand → 5, 2 hands → 10) matching `fingerbild_read`'s own `hands` convention exactly.

**Tech Stack:** Flutter/Dart (`math_app/`), the v4 skill-spec JSON pipeline, existing `FingerBildWidget`, existing `flash_subitize` timer/reshow mechanism, Python sync/coverage scripts.

**Spec:** `docs/clean-room/v4/skills/BUILD_ORDER.md` Batch 1.9 (line 58-59) + `docs/superpowers/specs/2026-09-15-exercise-plan-design.md:370-374` (verbatim: "Archetype: Reused — S1.1 Fingerblitz, 'See (No limit) → See (Flash)' levels directly"; "Manipulative: Finger-pattern flash display"; "Levels: 1) Untimed → 2) Flashed briefly"; "Example: Flash a finger pattern showing 7; child answers instantly.").

**Judgment call — 2 design-doc levels vs. 3 schema levels:** the design doc names only 2 tiers ("Untimed → Flashed briefly"), the same situation as `decompose_single_digit` (Batch 1.7). Per that precedent, this plan keeps the 2 named tiers as levels 1-2 and adds a 3rd fluency tier — a faster flash (800ms, `flash_subitize`'s own existing default for dots/rekenrek) after level 2's more generous 1500ms flash — rather than inventing an unrelated third axis. All 3 levels keep the same `count_range: [1, 10]`, `hands: 2` (the "quantity_zr10" in the skill's own name), consistent with the design doc's single worked example ("showing 7").

**No new widget files — a deliberate scope-minimising choice.** `fingerbild_read` (generic template) already renders untimed finger patterns up to 10 exactly as level 1 needs. `flash_subitize` already implements the flash-then-hide-then-optionally-reshow interaction level 2/3 need; it is missing only a third rendering pattern, which is additive (a new `if` branch, not a rewrite) and does not touch the `"dots"`/`"rekenrek"` behavior any existing spec or test depends on.

## Global Constraints

- German UI only.
- `domain` is `"C"` (Rechenstrategien, same subsection as `compare_quantity_difference` and the two `basic_fact_*_with_5`/`derive_via_5_*`/`derive_via_10_*` skills around it in the design doc, `docs/superpowers/specs/2026-09-15-exercise-plan-design.md:354-388`).
- `flash_subitize`'s existing `count_range` clamp to `[1, 5]` is true-subitizing-specific (dots/rekenrek) and must stay unchanged for those two patterns — the new `[1, 10]` cap applies only when `display == 'fingers'` and depends on the (new, optional) `hands` param exactly as `fingerbild_read` already does.
- `error_taxonomy` is `miscount` + `other` (both templates carry a single numeric `expected` value, so the existing `miscount` candidate code — off-by-one — is legitimately reachable; same precedent as `quantify_count_zr10.json`).
- Never hand-edit `math_app/assets/skill_specs/*.json`.
- `problem_count: 8` / `mastery.correct_of: 8` at every level (matches the sibling A2.1/subitizing-family specs' convention; no BUILD_ORDER-stated round count to match here, unlike `compare_quantity_difference`'s explicit "10 rounds").

---

## Task 1: Extend `flash_subitize` with a `"fingers"` pattern

**Files:**
- Modify: `math_app/lib/practice/problem_generators.dart` (`_generateFlashSubitize`)
- Modify: `math_app/lib/widgets/templates/flash_subitize_widget.dart` (`_visual`)
- Test: `math_app/test/problem_generators_test.dart`, `math_app/test/template_widgets_test.dart`

**Interfaces:**
- Consumes: `FingerBildWidget({required int leftCount, required int rightCount})` (`math_app/lib/widgets/manipulatives/fingerbild.dart`, unchanged).
- Produces: `_generateFlashSubitize` now accepts `display: "fingers"` in `params`, plus an optional `hands` param (`1` or `2`, default `2`) read only when `display == "fingers"`; `Problem.display` gains a `hands` key (only present for the `fingers` pattern) alongside the existing `count`/`flash_ms`/`display`.

- [ ] **Step 1: Update `_generateFlashSubitize`'s cap logic and validation.**

```dart
Problem _generateFlashSubitize(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final pattern = level.stringParam('display', fallback: 'dots');
  if (pattern != 'dots' && pattern != 'rekenrek' && pattern != 'fingers') {
    throw SpecFormatException(
      'flash_subitize: display must be "dots", "rekenrek" or "fingers", '
      'got "$pattern"',
    );
  }
  final hands = pattern == 'fingers' ? level.intParam('hands', fallback: 2) : null;
  final cap = pattern == 'fingers' ? (hands == 1 ? 5 : 10) : 5;

  final countRange = level.intListParam('count_range');
  final countLo = countRange.isEmpty ? 1 : max(countRange[0], 1);
  final countHi = countRange.isEmpty ? cap : min(countRange[1], cap);
  if (countHi < countLo) {
    throw SpecFormatException(
      'flash_subitize: count_range [$countLo, $countHi] has no valid count '
      'for pattern "$pattern" (capped at $cap)',
    );
  }
  final count = gen.nextIntInRange(countLo, countHi);
  final flashMs = level.intParam('flash_ms', fallback: 800);

  return Problem(
    template: 'custom_widget',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {
      'custom_widget': 'flash_subitize',
      'count': count,
      'flash_ms': flashMs,
      'display': pattern,
      if (hands != null) 'hands': hands,
    },
    expected: [count.toString()],
  );
}
```

Update the doc comment above it to mention the new `"fingers"` pattern and its hands-dependent cap, alongside the existing `"dots"`/`"rekenrek"` behavior (unchanged, still capped at 5).

- [ ] **Step 2: Add generator tests to `problem_generators_test.dart`** (in the `custom_widget generators (P2 §5 registry)` group, near the existing `flash_subitize` tests): `display: 'fingers', hands: 2, count_range: [1, 10]` — count reaches into `[6, 10]` across enough seeds (proving the cap actually lifted past 5); `display: 'fingers', hands: 1, count_range: [1, 10]` — count never exceeds 5 (the 1-hand cap still applies even though the requested range goes to 10); existing `dots`/`rekenrek` tests untouched and still passing (regression check).

- [ ] **Step 3: Run** `flutter test test/problem_generators_test.dart` — PASS, including the two new tests and every existing `flash_subitize` test unchanged.

- [ ] **Step 4: Update `FlashSubitizeWidget._visual()`** to render fingers:

```dart
Widget _visual() {
  if (_pattern == 'rekenrek') {
    return RekenrekWidget(topLeft: _count, bottomLeft: 0);
  }
  if (_pattern == 'fingers') {
    final hands = (widget.problem.display['hands'] as int?) ?? 2;
    final left = hands == 1 ? _count : (_count < 5 ? _count : 5);
    final right = _count - left;
    return FingerBildWidget(leftCount: left, rightCount: right);
  }
  return Wrap(
    // ... existing dots rendering, unchanged
  );
}
```

Add the `import '../manipulatives/fingerbild.dart';` import. Update the class doc comment to mention the third pattern.

- [ ] **Step 5: Add a widget test to `template_widgets_test.dart`** (in the existing `FlashSubitizeWidget` group): `display: 'fingers', count: 7, hands: 2` renders a `FingerBildWidget`; reduced-motion path (already tested generically) still applies since it is pattern-agnostic.

- [ ] **Step 6: Run** `flutter test test/template_widgets_test.dart` — PASS.
- [ ] **Step 7: Commit** — `feat(flash_subitize): add a fingers display pattern for fingerblitz_quantity_zr10`.

---

## Task 2: fingerblitz_quantity_zr10 spec JSON + tests

**Files:**
- Create: `docs/clean-room/v4/skills/specs/fingerblitz_quantity_zr10.json`
- Test: `math_app/test/skill_spec_store_test.dart`, `math_app/test/problem_generators_test.dart`

- [ ] **Step 1: Write the spec JSON.**

```json
{
  "spec_version": 1,
  "skill_id": "fingerblitz_quantity_zr10",
  "construct_id": "fingerblitz",
  "domain": "C",
  "title_de": "Fingerblitz: Mengen an Fingern erkennen",
  "level_titles_de": [
    "Finger in Ruhe erkennen",
    "Finger blitzen (langsam)",
    "Finger blitzen (schnell)"
  ],
  "levels": [
    {
      "level": 1,
      "representation": "enaktiv",
      "template": "fingerbild_read",
      "params": { "count_range": [1, 10], "hands": 2 },
      "problem_count": 8,
      "prompt_de": "Wie viele Finger siehst du?",
      "slow_band_ms": 10000
    },
    {
      "level": 2,
      "representation": "ikonisch",
      "template": "custom_widget",
      "custom_widget": "flash_subitize",
      "params": { "count_range": [1, 10], "hands": 2, "flash_ms": 1500, "display": "fingers" },
      "problem_count": 8,
      "prompt_de": "Wie viele Finger waren es?",
      "slow_band_ms": 8000
    },
    {
      "level": 3,
      "representation": "symbolisch",
      "template": "custom_widget",
      "custom_widget": "flash_subitize",
      "params": { "count_range": [1, 10], "hands": 2, "flash_ms": 800, "display": "fingers" },
      "problem_count": 8,
      "prompt_de": "Wie viele Finger waren es?",
      "slow_band_ms": 6000
    }
  ],
  "mastery": { "correct_of": 8 },
  "error_taxonomy": [
    { "code": "miscount", "label_de": "knapp daneben", "hint_de": "Ganz nah dran! Schau noch einmal genau hin." },
    { "code": "other", "label_de": "noch einmal probieren", "hint_de": "Schau dir das Fingerbild noch einmal an und probiere es noch einmal." }
  ],
  "provenance": {
    "sources": ["iMINT S1.1 Fingerblitz", "Krajewski, Anzahlerfassung und Zählkompetenz"],
    "author": "Claude (domain author)",
    "reviewed_by": "open"
  }
}
```

- [ ] **Step 2: Add the store test** asserting `constructId == 'fingerblitz'`, `domain == 'C'`, level 1 `template == 'fingerbild_read'`, levels 2-3 `template == 'custom_widget'` with `customWidget == 'flash_subitize'`.
- [ ] **Step 3: Add a generator test using `_realSpec('fingerblitz_quantity_zr10')`** — 3 levels x 100 seeds: `count` within `[1, 10]`, `expected == [count.toString()]`; levels 2-3 additionally assert `display['display'] == 'fingers'` and `display['flash_ms']` matches the level's own value (1500 / 800).
- [ ] **Step 4: Run** `flutter test test/skill_spec_store_test.dart test/problem_generators_test.dart` — PASS.
- [ ] **Step 5: Commit** — `feat(fingerblitz_quantity_zr10): add v4 skill spec using fingerbild_read and the extended flash_subitize`.

---

## Task 3: Sync, coverage, BUILD_ORDER, full suite, flutter analyze

**Files:**
- Modify: `math_app/assets/skill_specs/fingerblitz_quantity_zr10.json` (generated)
- Modify: `docs/clean-room/v4/skills/BUILD_ORDER.md`

- [ ] **Step 1: Sync** — `python scripts/sync_skill_specs.py`, expect `21 skill specs`.
- [ ] **Step 2: Coverage check** — `python scripts/check_skill_spec_coverage.py`, expect `21/93`.
- [ ] **Step 3: Update BUILD_ORDER.md`** — check off Batch 1.9's line with `shipped, docs/superpowers/plans/2026-09-17-fingerblitz-quantity-zr10.md`, add to `## Done`, correct the trailing count to "these twenty-one" and add Batch 1.9 to the batch list.
- [ ] **Step 4: Run the full Flutter test suite** — expect PASS (~660+, up from 653).
- [ ] **Step 5: Run `flutter analyze`** — expect no new issues beyond the 341 baseline.
- [ ] **Step 6: Commit** — `chore(fingerblitz_quantity_zr10): sync spec assets, mark Batch 1.9 done in BUILD_ORDER`.

---

## Self-Review Notes

- **Spec coverage:** interaction extension (Task 1), spec authoring (Task 2), integration (Task 3).
- **Placeholder scan:** none.
- **Regression risk:** Task 1's changes to `_generateFlashSubitize`/`FlashSubitizeWidget` are additive (new pattern branch, new optional param read only for that pattern) — every existing `dots`/`rekenrek` test must still pass unchanged, verified in Task 1 Step 3/6 before Task 2 begins.
- **Type consistency:** `Problem.display['hands']` is only ever present when `display['display'] == 'fingers'`; the widget reads it with `as int?` defaulting to 2, matching `fingerbild_read_widget.dart`'s own `(d['hands'] as num?)?.toInt() ?? 2` pattern in spirit (int vs num difference is intentional — `_generateFlashSubitize` always writes a Dart `int`, unlike `fingerbild_read`'s `display` map which can come from either code path).
