# Batch 2.2 — Successor & Predecessor in ZR100 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship `docs/clean-room/v4/skills/BUILD_ORDER.md` Batch 2.2 — six skills: `successor_zr100_mid`, `predecessor_zr100_mid`, `successor_zr100_five`, `predecessor_zr100_five`, `successor_zr100_decade`, `predecessor_zr100_decade`.

**Architecture:** No new widget. Like their shipped ZR20 siblings (`successor_zr20_decade`/`predecessor_zr20_decade`, Batch 1.3) these skills use the generic `sequence_gap` template: a length-2 ascending run (step 1) with one gap — index 1 for a successor question ("what comes right after 47?"), index 0 for a predecessor question ("what comes right before 48?"). The one missing piece: `sequence_gap`'s `start_range` is a plain interval, but two of the three skill families are defined by the *ones digit* of the given number ("numbers ending in 5", "decade-boundary numbers", "ones digit 1–7 then 8"). So Task 1 adds ONE optional, backward-compatible generator param `start_ones_digits` (an int list; when present the start is drawn uniformly from the numbers in `[minStart, maxStart]` whose ones digit is in the list). Task 2 adds the six spec JSONs, tests and BUILD_ORDER updates.

**Tech Stack:** Flutter/Dart, the v4 skill-spec pipeline (`SkillSpec`/`SkillSpecStore`/`template_registry`/`problem_generators`), `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-09-15-exercise-plan-design.md` (§5, the successor/predecessor archetype entries), `docs/skill_spec_authoring_guide.md` (authoring checklist), `docs/clean-room/v4/skills/BUILD_ORDER.md` (Batch 2.2 lines), and the shipped precedent `docs/clean-room/v4/skills/specs/successor_zr20_decade.json` / `predecessor_zr20_decade.json`.

## Global Constraints

- **Exactly 3 levels per spec**, `representation` values `"enaktiv"`, `"ikonisch"`, `"symbolisch"` in that order — `SkillSpec` parsing hard-rejects anything else (`math_app/lib/models/skill_spec.dart:344-351`). As in the shipped ZR20 siblings, all three levels use the `sequence_gap` template (the level axis carries number-range difficulty; there is no custom widget).
- **Backward compatibility of `_generateSequenceGap`:** when `start_ones_digits` is absent (every spec shipped before this batch), the start must still be drawn by exactly the original call `gen.nextIntInRange(minStart, maxStart)` so no existing spec's generated problems change. Only the new branch (param present) draws differently. Do not touch anything else in that function (the `progression: "double"` branch, the direction/step clamps, `expected`, the returned `Problem`).
- **error_taxonomy**: `"miscount"` and `"other"` only, identical to the ZR20 siblings. `expected` is a single integer string so `_candidateErrorCode`'s off-by-one `miscount` branch is reachable; never add a code `_candidateErrorCode` cannot emit.
- **All child-facing text in German.** Reuse the ZR20 siblings' prompt/hint wording where it fits (texts are given verbatim below).
- **`SeededGenerator.nextIntInRange(int min, int max)`** (inclusive) and **`nextInt(int max)`** (exclusive upper bound) are the only allowed sources of randomness; `LevelSpec.intListParam(String)` (returns an empty list when the param is absent) is the only allowed way to read the new param. Hand-rolled `Random()` is forbidden.
- Every new generator branch that can be given an unusable param must `throw SpecFormatException(...)` rather than silently fall back.
- **Process lessons from earlier batches (build them in, don't re-learn them):** the synced asset files under `math_app/assets/skill_specs/` MUST be created (via the sync script) and MUST be in the final `git add`; the plan file itself MUST be in the final commit (BUILD_ORDER cites it); BUILD_ORDER `## Done` entries use the plain format (id unbackticked, plan path in backticks).

## Design Notes (read before Task 1)

**Which number is "the given number", and what `start_ones_digits` constrains.** `sequence_gap` generates `values = [start, start+1]` (direction `up`, step 1, length 2). For a **successor** skill the gap is at index 1, so the child is *given* `values[0] = start` and answers `start+1`. For a **predecessor** skill the gap is at index 0, so the child is *given* `values[1] = start+1` and answers `start`. `start_ones_digits` always constrains the ones digit of `start` (= `values[0]`), so for predecessor skills the author must translate "the given number ends in X" into "start ends in X−1 (mod 10)". This translation is already done in the spec tables below — implementers copy them verbatim.

**Skill families (ones-digit rule of the GIVEN number, per BUILD_ORDER):**
- `*_mid` — "ZR100 mid-range (ones-digit 1–7, then 8–9 near-carry)". Levels 1–2: the given number has a "safe" ones digit (successor: given ones 1–7 → `start_ones_digits [1,2,3,4,5,6,7]`; predecessor: given ones 2–8 → start ones 1–7, so the answer never crosses a ten); level 1 uses small tens, level 2 larger tens. Level 3 is the near-carry step: successor given ones 8 (`[8]`, the answer ends in 9, the next step would carry); predecessor given ones 1 (`start_ones_digits [0]`, the answer lands exactly on a ten).
- `*_five` — the given number ends in 5 (successor: `start_ones_digits [5]`; predecessor: given ends in 5 → start ends in 4 → `[4]`). Levels grow the tens range.
- `*_decade` — decade-boundary numbers, the hardest tier (successor: given ends in 9, the answer is the next ten → `start_ones_digits [9]`; predecessor: given IS a ten (ends in 0) → start ends in 9 → `[9]`). Level 3 reaches 100 (`99 → 100`; the predecessor of `100` is `99`); `_generateSequenceGap`'s own ZR100 clamp allows values up to 100 and the answer field has no length cap.

**Ranges are copied, not derived.** Every `start_range` below is chosen so that *some* start in the range has each required ones digit and every value stays in `[1, 100]` (checked in Task 2's real-spec test).

---

### Task 1: optional `start_ones_digits` param for `sequence_gap` + generator tests

**Files:**
- Modify: `math_app/lib/practice/problem_generators.dart` (`_generateSequenceGap`, ~line 259-327)
- Modify: `math_app/test/problem_generators_test.dart` (`_sequenceSpec` helper ~line 65; 3 tests in `group('sequence_gap generator', ...)` ~line 249)

**Interfaces:**
- Consumes: `LevelSpec.intListParam(String key)` (returns `[]` when the param is absent), `SeededGenerator.nextInt(int)` / `nextIntInRange(int, int)` (`math_app/lib/practice/problem_generators.dart:17-31`), `SpecFormatException`.
- Produces: new optional level param `start_ones_digits` (list of ints 0–9) understood by the `sequence_gap` template. No new public API.

- [ ] **Step 1: Extend the `_sequenceSpec` test helper**

In `math_app/test/problem_generators_test.dart`, change `_sequenceSpec` (line ~65) to accept and forward an optional `startOnesDigits`:

```dart
SkillSpec _sequenceSpec({
  String direction = 'up',
  int step = 1,
  List<int> startRange = const [5, 14],
  int length = 5,
  List<int> gapIndices = const [2],
  String? progression,
  List<int>? startOnesDigits,
}) => SkillSpec.fromJson(
  _baseSpec(
    _level(2, 'symbolisch', 'sequence_gap', {
      'direction': direction,
      'step': step,
      'start_range': startRange,
      'length': length,
      'gap_indices': gapIndices,
      if (progression != null) 'progression': progression,
      if (startOnesDigits != null) 'start_ones_digits': startOnesDigits,
    }, 7000),
  ),
);
```

- [ ] **Step 2: Write the failing tests**

In `group('sequence_gap generator', () { ... })` (starts ~line 249), add these three tests as the first tests of the group:

```dart
    test('start_ones_digits restricts the start to the given ones digits', () {
      final spec = _sequenceSpec(
        startRange: [10, 60],
        length: 2,
        gapIndices: [1],
        startOnesDigits: [5],
      );
      final starts = <int>{};
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: spec, level: 2, seed: seed)) {
          final values = (p.display['values'] as List).cast<int>();
          expect(values[0] % 10, 5);
          expect(values[0], inInclusiveRange(10, 60));
          expect(values[1], values[0] + 1);
          expect(p.expected, [values[1].toString()]);
          starts.add(values[0]);
        }
      }
      expect(starts.length, greaterThan(2),
          reason: 'the start must actually vary among 15, 25, 35, 45, 55');
    });

    test('start_ones_digits accepts several digits', () {
      final spec = _sequenceSpec(
        startRange: [20, 49],
        length: 2,
        gapIndices: [0],
        startOnesDigits: [1, 2, 3],
      );
      final seen = <int>{};
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: spec, level: 2, seed: seed)) {
          final values = (p.display['values'] as List).cast<int>();
          expect([1, 2, 3], contains(values[0] % 10));
          seen.add(values[0] % 10);
        }
      }
      expect(seen, {1, 2, 3});
    });

    test('start_ones_digits with no matching start in range is a spec error',
        () {
      final spec = _sequenceSpec(
        startRange: [11, 14],
        length: 2,
        gapIndices: [1],
        startOnesDigits: [7],
      );
      expect(
        () => generateProblems(spec: spec, level: 2, seed: 1),
        throwsA(isA<SpecFormatException>()),
      );
    });
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `cd math_app && flutter test test/problem_generators_test.dart --plain-name "start_ones_digits"`
Expected: FAIL — the param is not implemented yet, so the first test's `values[0] % 10` is not always 5 (and the third test does not throw).

- [ ] **Step 4: Implement the param**

In `math_app/lib/practice/problem_generators.dart`, in `_generateSequenceGap`:

(a) Directly after the line `final gapIndices = level.intListParam('gap_indices');` add:

```dart
  final onesDigits = level.intListParam('start_ones_digits');
```

(b) Replace the single line

```dart
  final start = gen.nextIntInRange(minStart, maxStart);
```

with:

```dart
  final int start;
  if (onesDigits.isEmpty) {
    start = gen.nextIntInRange(minStart, maxStart);
  } else {
    final candidates = [
      for (var s = minStart; s <= maxStart; s++)
        if (onesDigits.contains(s % 10)) s,
    ];
    if (candidates.isEmpty) {
      throw SpecFormatException(
        'sequence_gap: no start in [$minStart, $maxStart] has a ones digit '
        'in $onesDigits',
      );
    }
    start = candidates[gen.nextInt(candidates.length)];
  }
```

(c) In the function's doc comment (the `///` block above `Problem _generateSequenceGap(`) append this sentence to the end of the block:

```dart
/// The optional `start_ones_digits` list restricts the start to numbers in the
/// (clamped) start range whose ones digit is in the list -- used by the ZR100
/// successor/predecessor skills (BUILD_ORDER.md Batch 2.2) for "numbers
/// ending in 5" and decade-boundary numbers. Absent: the start is drawn
/// uniformly from the whole range exactly as before.
```

Do not change anything else in the function.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `cd math_app && flutter test test/problem_generators_test.dart --plain-name "sequence_gap"`
Expected: PASS — the 3 new tests and every pre-existing `sequence_gap` test (including the real-spec tests for `count_forward_*`, `successor_zr20_decade`, `predecessor_zr20_decade`, `skip*`).

- [ ] **Step 6: Run the full test suite and `flutter analyze`**

Run: `cd math_app && flutter test && flutter analyze`
Expected: all tests pass (baseline 735 + 3); `flutter analyze` issue count stays at the pre-existing baseline (341) — verify with `flutter analyze 2>&1 | grep -i "problem_generators"` printing nothing new compared to before your change.

- [ ] **Step 7: Commit**

```bash
git add math_app/lib/practice/problem_generators.dart math_app/test/problem_generators_test.dart
git commit -m "feat(sequence_gap): add optional start_ones_digits param for ones-digit-constrained starts"
```

---

### Task 2: six spec JSONs, real-spec tests, asset sync, BUILD_ORDER close-out

**Files:**
- Create: `docs/clean-room/v4/skills/specs/successor_zr100_mid.json`
- Create: `docs/clean-room/v4/skills/specs/predecessor_zr100_mid.json`
- Create: `docs/clean-room/v4/skills/specs/successor_zr100_five.json`
- Create: `docs/clean-room/v4/skills/specs/predecessor_zr100_five.json`
- Create: `docs/clean-room/v4/skills/specs/successor_zr100_decade.json`
- Create: `docs/clean-room/v4/skills/specs/predecessor_zr100_decade.json`
- Create (via sync script): the 6 matching files in `math_app/assets/skill_specs/`
- Modify: `math_app/test/problem_generators_test.dart` (1 real-spec test)
- Modify: `math_app/test/skill_spec_store_test.dart` (1 parse test)
- Modify: `docs/clean-room/v4/skills/BUILD_ORDER.md`

**Interfaces:**
- Consumes: the `sequence_gap` template and Task 1's `start_ones_digits` param. No Dart production code changes in this task.
- Produces: nothing further downstream.

The six specs share this skeleton (only the fields listed per spec differ). Common fields for ALL six: `"spec_version": 1`, `"domain": "A"`, `"template": "sequence_gap"` on every level, `"problem_count": 8`, `"mastery": { "correct_of": 8 }`, params always `"direction": "up", "step": 1, "length": 2` plus the per-level `start_range`, `start_ones_digits` and (`gap_indices`: `[1]` for successor specs, `[0]` for predecessor specs), the `error_taxonomy` and `provenance` blocks exactly as in the first file below.

- [ ] **Step 1: Write `successor_zr100_mid.json`**

```json
{
  "spec_version": 1,
  "skill_id": "successor_zr100_mid",
  "construct_id": "successor",
  "domain": "A",
  "title_de": "Nachfolger im ZR100",
  "level_titles_de": [
    "Der Nachfolger",
    "Nachfolger bei größeren Zehnern",
    "Fast am nächsten Zehner"
  ],
  "levels": [
    {
      "level": 1,
      "representation": "enaktiv",
      "template": "sequence_gap",
      "params": {
        "direction": "up",
        "step": 1,
        "start_range": [11, 47],
        "start_ones_digits": [1, 2, 3, 4, 5, 6, 7],
        "length": 2,
        "gap_indices": [1]
      },
      "problem_count": 8,
      "prompt_de": "Welche Zahl kommt direkt danach?",
      "slow_band_ms": 12000
    },
    {
      "level": 2,
      "representation": "ikonisch",
      "template": "sequence_gap",
      "params": {
        "direction": "up",
        "step": 1,
        "start_range": [51, 87],
        "start_ones_digits": [1, 2, 3, 4, 5, 6, 7],
        "length": 2,
        "gap_indices": [1]
      },
      "problem_count": 8,
      "prompt_de": "Welche Zahl kommt direkt nach dieser Zahl?",
      "slow_band_ms": 10000
    },
    {
      "level": 3,
      "representation": "symbolisch",
      "template": "sequence_gap",
      "params": {
        "direction": "up",
        "step": 1,
        "start_range": [21, 88],
        "start_ones_digits": [8],
        "length": 2,
        "gap_indices": [1]
      },
      "problem_count": 8,
      "prompt_de": "Fast am nächsten Zehner! Welche Zahl kommt direkt danach?",
      "slow_band_ms": 8000
    }
  ],
  "mastery": { "correct_of": 8 },
  "error_taxonomy": [
    { "code": "miscount", "label_de": "knapp daneben", "hint_de": "Ganz nah dran! Zähl noch einmal genau." },
    { "code": "other", "label_de": "noch einmal probieren", "hint_de": "Schau dir die Zahl noch einmal an und probiere es noch einmal." }
  ],
  "provenance": {
    "sources": ["RLP BE/BB Teil C, L1, Niveaustufe A", "Padberg/Benz, Nachfolger-Vorgänger-Konzept und Zahlwortreihe", "Gaidoschik, Zehnerübergang und Stellenwertverständnis", "Wartha/Schulz, Ablösung vom zählenden Rechnen"],
    "author": "Claude (domain author)",
    "reviewed_by": "open"
  }
}
```

- [ ] **Step 2: Write `predecessor_zr100_mid.json`**

Same skeleton; differences:
- `skill_id` `predecessor_zr100_mid`, `construct_id` `predecessor`, `title_de` `"Vorgänger im ZR100"`, `level_titles_de` `["Der Vorgänger", "Vorgänger bei größeren Zehnern", "Vorgänger knapp nach dem Zehner"]`.
- Every level: `"gap_indices": [0]`.
- Level 1 (`enaktiv`): `"start_range": [11, 47]`, `"start_ones_digits": [1, 2, 3, 4, 5, 6, 7]`, `prompt_de` `"Welche Zahl kommt direkt davor?"`, `slow_band_ms` `12000`.
- Level 2 (`ikonisch`): `"start_range": [51, 87]`, `"start_ones_digits": [1, 2, 3, 4, 5, 6, 7]`, `prompt_de` `"Welche Zahl kommt direkt vor dieser Zahl?"`, `slow_band_ms` `10000`.
- Level 3 (`symbolisch`): `"start_range": [20, 80]`, `"start_ones_digits": [0]`, `prompt_de` `"Fast am Zehner! Welche Zahl kommt direkt davor?"`, `slow_band_ms` `8000`.
- Everything else (`error_taxonomy`, `provenance`, `mastery`, `problem_count`, `domain`, `template`, params `direction`/`step`/`length`) exactly as in Step 1.

- [ ] **Step 3: Write `successor_zr100_five.json`**

Same skeleton; differences:
- `skill_id` `successor_zr100_five`, `construct_id` `successor`, `title_de` `"Nachfolger von Zahlen auf 5 (ZR100)"`, `level_titles_de` `["Nachfolger einer Zahl auf 5", "Nachfolger bei größeren Zehnern", "Nachfolger bei den größten Zehnern"]`.
- Every level: `"gap_indices": [1]`, `"start_ones_digits": [5]`.
- Level 1: `"start_range": [15, 45]`, `prompt_de` `"Welche Zahl kommt direkt danach?"`, `slow_band_ms` `12000`.
- Level 2: `"start_range": [45, 75]`, `prompt_de` `"Welche Zahl kommt direkt nach dieser Zahl?"`, `slow_band_ms` `10000`.
- Level 3: `"start_range": [65, 95]`, `prompt_de` `"Achtung, große Zahl! Welche Zahl kommt direkt danach?"`, `slow_band_ms` `8000`.

- [ ] **Step 4: Write `predecessor_zr100_five.json`**

Same skeleton; differences:
- `skill_id` `predecessor_zr100_five`, `construct_id` `predecessor`, `title_de` `"Vorgänger von Zahlen auf 5 (ZR100)"`, `level_titles_de` `["Vorgänger einer Zahl auf 5", "Vorgänger bei größeren Zehnern", "Vorgänger bei den größten Zehnern"]`.
- Every level: `"gap_indices": [0]`, `"start_ones_digits": [4]` (the GIVEN number = start+1 ends in 5).
- Level 1: `"start_range": [14, 44]`, `prompt_de` `"Welche Zahl kommt direkt davor?"`, `slow_band_ms` `12000`.
- Level 2: `"start_range": [44, 74]`, `prompt_de` `"Welche Zahl kommt direkt vor dieser Zahl?"`, `slow_band_ms` `10000`.
- Level 3: `"start_range": [64, 94]`, `prompt_de` `"Achtung, große Zahl! Welche Zahl kommt direkt davor?"`, `slow_band_ms` `8000`.

- [ ] **Step 5: Write `successor_zr100_decade.json`**

Same skeleton; differences:
- `skill_id` `successor_zr100_decade`, `construct_id` `successor`, `title_de` `"Nachfolger über die Zehnergrenze (ZR100)"`, `level_titles_de` `["Nachfolger über die Zehnergrenze", "Zehnergrenze bei größeren Zahlen", "Zehnergrenze bis zur Hundert"]`.
- Every level: `"gap_indices": [1]`, `"start_ones_digits": [9]`, `prompt_de` `"Vorsicht, hier wechselt der Zehner! Welche Zahl kommt direkt danach?"`.
- Level 1: `"start_range": [19, 49]`, `slow_band_ms` `14000`.
- Level 2: `"start_range": [39, 79]`, `slow_band_ms` `12000`.
- Level 3: `"start_range": [69, 99]`, `slow_band_ms` `10000`.

- [ ] **Step 6: Write `predecessor_zr100_decade.json`**

Same skeleton; differences:
- `skill_id` `predecessor_zr100_decade`, `construct_id` `predecessor`, `title_de` `"Vorgänger über die Zehnergrenze (ZR100)"`, `level_titles_de` `["Vorgänger über die Zehnergrenze", "Zehnergrenze bei größeren Zahlen", "Zehnergrenze bis zur Hundert"]`.
- Every level: `"gap_indices": [0]`, `"start_ones_digits": [9]` (the GIVEN number = start+1 is a full ten), `prompt_de` `"Vorsicht, hier wechselt der Zehner! Welche Zahl kommt direkt davor?"`.
- Level 1: `"start_range": [19, 49]`, `slow_band_ms` `14000`.
- Level 2: `"start_range": [39, 79]`, `slow_band_ms` `12000`.
- Level 3: `"start_range": [69, 99]`, `slow_band_ms` `10000`.

- [ ] **Step 7: Write the real-spec generator test**

In `math_app/test/problem_generators_test.dart`, add this test directly after the existing test `'real predecessor_zr20_decade: gap at index 0, expected == given - 1, within [1, 20]'` (inside the same group):

```dart
    test(
        'real ZR100 successor/predecessor specs (Batch 2.2): gap position, '
        '+/-1, ZR100 bounds and each skill/level ones-digit rule of the '
        'given number', () {
      const successorGivenOnes = <String, List<Set<int>>>{
        'successor_zr100_mid': [
          {1, 2, 3, 4, 5, 6, 7},
          {1, 2, 3, 4, 5, 6, 7},
          {8},
        ],
        'successor_zr100_five': [
          {5},
          {5},
          {5},
        ],
        'successor_zr100_decade': [
          {9},
          {9},
          {9},
        ],
      };
      const predecessorGivenOnes = <String, List<Set<int>>>{
        'predecessor_zr100_mid': [
          {2, 3, 4, 5, 6, 7, 8},
          {2, 3, 4, 5, 6, 7, 8},
          {1},
        ],
        'predecessor_zr100_five': [
          {5},
          {5},
          {5},
        ],
        'predecessor_zr100_decade': [
          {0},
          {0},
          {0},
        ],
      };

      for (final entry in successorGivenOnes.entries) {
        final s = _realSpec(entry.key);
        for (var level = 1; level <= 3; level++) {
          for (var seed = 0; seed < 150; seed++) {
            for (final p in generateProblems(spec: s, level: level, seed: seed)) {
              final reason = '${entry.key} level $level seed $seed';
              expect(p.template, 'sequence_gap', reason: reason);
              final values = (p.display['values'] as List).cast<int>();
              expect(values, hasLength(2), reason: reason);
              expect(p.display['gap_indices'], [1], reason: reason);
              expect(values[1], values[0] + 1, reason: reason);
              expect(p.expected, [values[1].toString()], reason: reason);
              expect(values[0], inInclusiveRange(1, 99), reason: reason);
              expect(values[1], lessThanOrEqualTo(100), reason: reason);
              expect(entry.value[level - 1], contains(values[0] % 10),
                  reason: '$reason: given ${values[0]}');
            }
          }
        }
      }

      for (final entry in predecessorGivenOnes.entries) {
        final s = _realSpec(entry.key);
        for (var level = 1; level <= 3; level++) {
          for (var seed = 0; seed < 150; seed++) {
            for (final p in generateProblems(spec: s, level: level, seed: seed)) {
              final reason = '${entry.key} level $level seed $seed';
              expect(p.template, 'sequence_gap', reason: reason);
              final values = (p.display['values'] as List).cast<int>();
              expect(values, hasLength(2), reason: reason);
              expect(p.display['gap_indices'], [0], reason: reason);
              expect(values[0], values[1] - 1, reason: reason);
              expect(p.expected, [values[0].toString()], reason: reason);
              expect(values[0], inInclusiveRange(1, 99), reason: reason);
              expect(values[1], lessThanOrEqualTo(100), reason: reason);
              expect(entry.value[level - 1], contains(values[1] % 10),
                  reason: '$reason: given ${values[1]}');
            }
          }
        }
      }
    });
```

- [ ] **Step 8: Write the spec parse test**

In `math_app/test/skill_spec_store_test.dart`, add this test at the end of the same group, directly after the `predecessor_zr20_decade (Batch 1.3)` test:

```dart
    test('the six ZR100 successor/predecessor specs (Batch 2.2) parse with the '
        'sequence_gap template', () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      const expected = <String, ({String construct, String title})>{
        'successor_zr100_mid':
            (construct: 'successor', title: 'Nachfolger im ZR100'),
        'predecessor_zr100_mid':
            (construct: 'predecessor', title: 'Vorgänger im ZR100'),
        'successor_zr100_five': (
          construct: 'successor',
          title: 'Nachfolger von Zahlen auf 5 (ZR100)',
        ),
        'predecessor_zr100_five': (
          construct: 'predecessor',
          title: 'Vorgänger von Zahlen auf 5 (ZR100)',
        ),
        'successor_zr100_decade': (
          construct: 'successor',
          title: 'Nachfolger über die Zehnergrenze (ZR100)',
        ),
        'predecessor_zr100_decade': (
          construct: 'predecessor',
          title: 'Vorgänger über die Zehnergrenze (ZR100)',
        ),
      };
      for (final e in expected.entries) {
        final spec = store.byId(e.key);
        expect(spec.constructId, e.value.construct, reason: e.key);
        expect(spec.domain, 'A', reason: e.key);
        expect(spec.titleDe, e.value.title, reason: e.key);
        expect(spec.levels.map((l) => l.template),
            ['sequence_gap', 'sequence_gap', 'sequence_gap'],
            reason: e.key);
        expect(spec.levels.map((l) => l.representation),
            ['enaktiv', 'ikonisch', 'symbolisch'],
            reason: e.key);
      }
    });
```

(If `LevelSpec.representation` is not a plain string but an enum in this codebase, adapt the last assertion to compare against the enum values or `.name` — check `math_app/lib/models/skill_spec.dart` first.)

- [ ] **Step 9: Run the new tests**

Run: `cd math_app && flutter test test/problem_generators_test.dart --plain-name "Batch 2.2"` and `cd math_app && flutter test test/skill_spec_store_test.dart --plain-name "Batch 2.2"`
Expected: PASS. Then `cd math_app && flutter test test/skill_spec_store_test.dart --plain-name "every bundled v4 spec parses and validates"` — Expected: PASS.

- [ ] **Step 10: Sync specs and check coverage**

Run from the repo root (not `math_app/`):

```bash
python scripts/sync_skill_specs.py
python scripts/check_skill_spec_coverage.py
```

Expected: `sync_skill_specs.py` copies the six new JSONs into `math_app/assets/skill_specs/`; `check_skill_spec_coverage.py` reports `covered: 38/93` (it exits 1 because skills are still missing — that is normal), `extra` empty.

**Immediately verify the sync produced all six files on disk** (a prior batch shipped with its assets uncommitted):

```bash
ls math_app/assets/skill_specs/successor_zr100_mid.json math_app/assets/skill_specs/predecessor_zr100_mid.json math_app/assets/skill_specs/successor_zr100_five.json math_app/assets/skill_specs/predecessor_zr100_five.json math_app/assets/skill_specs/successor_zr100_decade.json math_app/assets/skill_specs/predecessor_zr100_decade.json
```

Expected: all six listed. If any is missing the sync failed — stop and investigate.

- [ ] **Step 11: Update `BUILD_ORDER.md`**

In `docs/clean-room/v4/skills/BUILD_ORDER.md`:

1. Top-of-file line: change `61 of 93 skills remain (32 shipped as of Batch 2.1 —` to `55 of 93 skills remain (38 shipped as of Batch 2.2 —` (keep the rest of that sentence exactly as is).

2. In the "Tier totals are the design doc §3 tally ..." paragraph change `minus the thirty-two shipped` to `minus the thirty-eight shipped` and `0 / 30 / 11 / 20 remaining` to `0 / 24 / 11 / 20 remaining` (keep the existing line breaks; only those words/numbers change).

3. Change the heading `## Tier 2: Extended (30 remaining of 31)` to `## Tier 2: Extended (24 remaining of 31)`, and replace the sentence `Batch 2.1 shipped.` beneath it with `See the checklists below for what has shipped.` (evergreen wording so it never goes stale).

4. Under `### Batch 2.2 — successor & predecessor in ZR100 ...`, check off all six lines, following the format of the Batch 2.1 line (`- [x] \`id\` — shipped, \`plan path\`; <original description>`). Use the plan path `docs/superpowers/plans/2026-09-20-successor-predecessor-zr100-batch-2-2.md` and keep each line's existing description text after the semicolon. E.g.:
   ```
   - [x] `successor_zr100_mid` — shipped, `docs/superpowers/plans/2026-09-20-successor-predecessor-zr100-batch-2-2.md`; Extended from C4.1's number-card widget, ZR100 mid-range (ones-digit 1–7, then 8–9 near-carry)
   ```
   (Do the same for `predecessor_zr100_mid`, `successor_zr100_five`, `predecessor_zr100_five`, `successor_zr100_decade`, `predecessor_zr100_decade`, each keeping its own existing description.)

5. Add six entries at the END of the `## Done` list (after the `quantify_count_zr20` line), in the plain format every other entry uses — id unbackticked, plan path in backticks:
   ```
   - [x] successor_zr100_mid — `docs/superpowers/plans/2026-09-20-successor-predecessor-zr100-batch-2-2.md`
   - [x] predecessor_zr100_mid — `docs/superpowers/plans/2026-09-20-successor-predecessor-zr100-batch-2-2.md`
   - [x] successor_zr100_five — `docs/superpowers/plans/2026-09-20-successor-predecessor-zr100-batch-2-2.md`
   - [x] predecessor_zr100_five — `docs/superpowers/plans/2026-09-20-successor-predecessor-zr100-batch-2-2.md`
   - [x] successor_zr100_decade — `docs/superpowers/plans/2026-09-20-successor-predecessor-zr100-batch-2-2.md`
   - [x] predecessor_zr100_decade — `docs/superpowers/plans/2026-09-20-successor-predecessor-zr100-batch-2-2.md`
   ```

6. Update the parenthetical note directly below the `## Done` list: change `thirty-two` to `thirty-eight` and `1.13, 2.1 and 4.3 above.` to `1.13, 2.1, 2.2 and 4.3 above.`

- [ ] **Step 12: Run the full test suite and `flutter analyze` one more time**

Run: `cd math_app && flutter test && flutter analyze`
Expected: all tests pass (baseline 735 + Task 1's 3 + the 2 tests from this task = 740); `flutter analyze` stays at the pre-existing baseline issue count.

- [ ] **Step 13: Commit (asset files and the plan file included)**

```bash
git add docs/clean-room/v4/skills/specs/successor_zr100_mid.json \
        docs/clean-room/v4/skills/specs/predecessor_zr100_mid.json \
        docs/clean-room/v4/skills/specs/successor_zr100_five.json \
        docs/clean-room/v4/skills/specs/predecessor_zr100_five.json \
        docs/clean-room/v4/skills/specs/successor_zr100_decade.json \
        docs/clean-room/v4/skills/specs/predecessor_zr100_decade.json \
        math_app/assets/skill_specs/successor_zr100_mid.json \
        math_app/assets/skill_specs/predecessor_zr100_mid.json \
        math_app/assets/skill_specs/successor_zr100_five.json \
        math_app/assets/skill_specs/predecessor_zr100_five.json \
        math_app/assets/skill_specs/successor_zr100_decade.json \
        math_app/assets/skill_specs/predecessor_zr100_decade.json \
        math_app/test/problem_generators_test.dart \
        math_app/test/skill_spec_store_test.dart \
        docs/clean-room/v4/skills/BUILD_ORDER.md \
        docs/superpowers/plans/2026-09-20-successor-predecessor-zr100-batch-2-2.md
git commit -m "feat(successor_predecessor_zr100): add six ZR100 successor/predecessor specs"
```

Run `git status --porcelain` afterwards and confirm none of the 16 paths above is still `??` or ` M`.

---

## Self-Review Notes

- **Spec coverage:** every BUILD_ORDER Batch 2.2 line (mid / five / decade × successor / predecessor) has exactly one spec (Steps 1–6) and one Done entry (Step 11.5); the ones-digit families from the BUILD_ORDER descriptions map to `start_ones_digits` (Design Notes) and are asserted per skill/level in Step 7.
- **Given-number arithmetic double-check:** successor given = `values[0]`; predecessor given = `values[1] = start+1`. Predecessor mid L1/L2: start ones 1–7 ⇒ given ones 2–8 ✓ (test table `{2..8}`); L3: start ones 0 ⇒ given ones 1 ✓ (`{1}`). Predecessor five: start ones 4 ⇒ given ones 5 ✓. Predecessor decade: start ones 9 ⇒ given ones 0 ✓ (start 99 ⇒ given 100, `100 % 10 == 0` ✓, `values[1] <= 100` ✓). Successor decade level 3 start 99 ⇒ answer 100 ✓ within the clamp `maxByBound = 100 - 1 = 99`.
- **Range feasibility:** each `start_range` contains at least one start with each required ones digit (e.g. mid L3 `[21,88]` ones 8 ⇒ 28…88; predecessor mid L3 `[20,80]` ones 0 ⇒ 20,30,…,80; decade L1 `[19,49]` ones 9 ⇒ 19,29,39,49) so the "no matching start" `SpecFormatException` can never fire for shipped specs.
- **Placeholder scan:** none — Steps 2–6 give the complete per-spec delta against the fully written Step 1 skeleton; every non-differing field is explicitly stated as identical.
- **Lessons built in:** plan file committed in Step 13 (Batch 1.12/1.13 miss); all six synced assets `ls`-checked in Step 10 and `git add`ed in Step 13 (Batch 1.12 miss); plain Done-entry format (Batch 1.12 miss); the Tier-2 "shipped" sentence made evergreen (Batch 2.1 minor).

## Post-review amendment

`successor_zr100_decade` was changed after the final review so that level 1 asks the successor of a full ten (start ones digit 0, range [20, 60]), level 2 mixes both (ones digits [0, 9], range [40, 80]) and level 3 keeps the hardest crossing case (ones digit 9, range [69, 99]). The design doc §5 entry and the diagnostic item routed to this skill ("nach 90 → 91") define it as "successor of a full ten". Level titles and the L1/L2 prompts were adjusted accordingly. The Task 2 Step 5 / Step 7 text above describes the pre-amendment values.
