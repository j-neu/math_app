# P2 Tasks 2–3 Report — Spec model/store, problem harness, check+sync scripts

**Date:** 2026-08-31
**Branch:** `gauntlet/p2-p3-p4`
**Commit:** created by this task (see git log)

## Scope

P2 plan §8 Tasks 2 (spec model, store, validation) and 3 (problem model, seeded
generator harness, answer normalization), plus `sequence_gap` / `compare_symbols`
generators (pure and fully specified, validating the harness end-to-end) and the
`check_specs.py` / `sync_skill_specs.py` scripts.

## Files created / modified

| File | Kind | Purpose |
|---|---|---|
| `math_app/lib/models/skill_spec.dart` | new | `SkillSpec`, `LevelSpec`, `ErrorRule`, `Mastery`, `Provenance`, `SpecFormatException`, `kKnownTemplates`, `kKnownCustomWidgets` |
| `math_app/lib/models/problem.dart` | new | `Problem` (+ `toJson`/`fromJson`), `AnswerRecord` |
| `math_app/lib/services/answer_normalization.dart` | new | `normalizeAnswer`, `answersMatch` |
| `math_app/lib/practice/problem_generators.dart` | new | `SeededGenerator`, `generateProblems` harness, `sequence_gap` + `compare_symbols` generators |
| `math_app/lib/services/skill_spec_store.dart` | new | `SkillSpecStore` (`fromJsonMap` seam, `load` via asset manifest), `SkillSpecAssetException` |
| `scripts/check_specs.py` | new | strict validator over `docs/clean-room/skills/specs/*.json` + provenance CSV |
| `scripts/sync_skill_specs.py` | new | idempotent mirror of specs → `math_app/assets/skill_specs/` |
| `math_app/assets/skill_specs/*.json` | new | 36 bundled specs (produced by sync script) |
| `math_app/pubspec.yaml` | modified | added `- assets/skill_specs/` |
| `docs/clean-room/skills/specs/_provenance_specs_new.csv` | modified | added 6 missing skill_spec rows (A2.1, A2.2, A2.3, A3.1, A3.2, A3.3) |
| `math_app/test/fixtures/specs/c1_1a.json` | new | real C1.1a fixture copy |
| `math_app/test/skill_spec_test.dart` | new | parser tests, 20 injected violations |
| `math_app/test/problem_generators_test.dart` | new | determinism, math-correctness, uniqueness |
| `math_app/test/answer_normalization_test.dart` | new | normalisation table |
| `math_app/test/skill_spec_store_test.dart` | new | all 36 real specs via the `fromJsonMap` seam |
| `.superpowers/gauntlet/p2b-report.md` | new | this report |

## Key API signatures

```dart
// lib/models/skill_spec.dart
class SpecFormatException implements Exception { final String message; ... }
class ErrorRule { final String code, labelDe, hintDe; }
class Mastery { final int correctOf; }
class Provenance { final List<String> sources; final String? author, reviewedBy; }
class LevelSpec {
  final int level; final String representation, template; final String? customWidget;
  final Map<String, dynamic> params; final int problemCount, slowBandMs; final String promptDe;
  factory LevelSpec.fromJson(Map<String, dynamic> j, {required String specLabel});
  int intParam(String key, {required int fallback});
  List<int> intListParam(String key);
  String stringParam(String key, {String fallback = ''});
  String? stringParamOrNull(String key);
  bool boolParam(String key, {bool fallback = false});
}
class SkillSpec {
  final int specVersion; final String skillId, constructId, domain, titleDe;
  final List<String> levelTitlesDe; final List<LevelSpec> levels;
  final Mastery mastery; final List<ErrorRule> errorTaxonomy; final Provenance provenance;
  LevelSpec levelSpec(int level);                       // 1-based, throws ArgumentError
  factory SkillSpec.fromJson(Map<String, dynamic> j);   // strict
}
const Set<String> kKnownTemplates = {...16 templates + 'custom_widget'};
const Set<String> kKnownCustomWidgets = {'bundling','unbundling','numberline_mark','flash_subitize'};

// lib/models/problem.dart
class Problem {
  final String template, skillId, promptDe; final int level, seed, index;
  final Map<String, dynamic> display; final List<String> expected;
  Map<String, dynamic> toJson();  factory Problem.fromJson(Map<String, dynamic>);
}
class AnswerRecord {
  final String value; final bool wasCorrect; final int responseMs; final String? errorCode;
  Map<String, dynamic> toJson();  factory AnswerRecord.fromJson(Map<String, dynamic>);
}

// lib/services/answer_normalization.dart
String normalizeAnswer(String value);                       // trim + collapse whitespace, comma kept
bool answersMatch(String submitted, Iterable<String> expected);

// lib/practice/problem_generators.dart
class SeededGenerator { SeededGenerator(int seed); int nextIntInRange(int min, int max); ... }
List<Problem> generateProblems({required SkillSpec spec, required int level, required int seed});

// lib/services/skill_spec_store.dart
class SkillSpecAssetException implements Exception { final String message; }
class SkillSpecStore {
  factory SkillSpecStore.fromJsonMap(Map<String, String> jsonById);  // test seam, strict
  static Future<SkillSpecStore> load();                              // rootBundle + AssetManifest
  SkillSpec byId(String skillId);                                    // throws ArgumentError
  List<String> allIds();  List<SkillSpec> allSpecs();  List<String> validateAll();
}
```

## Validation implemented

`SkillSpec.fromJson` (strict, throws `SpecFormatException`): unknown template;
`custom_widget` required non-null (and whitelisted) when template is
`custom_widget`, and must be null otherwise; level count == 3 numbered 1..3;
`problem_count` in [4,12]; `slow_band_ms` present; non-empty `prompt_de`;
`mastery.correct_of` ≥ 1 and ≤ every level's `problem_count`; error-taxonomy
rules non-empty `code`/`label_de`/`hint_de` and unique codes; `params` kept as a
raw map (params vocabulary is `check_specs.py`'s job, per plan §8 Task 2).

`scripts/check_specs.py` additionally enforces: top-level key presence; the
template whitelist; the per-template params whitelist (P3 §4.5 + §4.5b
extensions — `form` incl. `any_split`, `op` +/−/+|-, `arrangement`,
`mode` read/sum_rows (+ `standard`/`place_value` for equation_solve),
`progression: double`, `equal`/`multi_valid` booleans, `action`, `question`,
`unknown`, plus `op` on `stellenwerttafel_read` as authored in C3.1b);
`[lo,hi]` int-pair range shapes; gap indices within `[0, length)`; word_problem
`contexts` ≥ 2; strategy_choice `correct_strategy` ∈ strategies;
`slow_band_ms ∈ {9000,7000,6000}`; `mastery.correct_of == 8`; error taxonomy
rules non-empty + unique codes; provenance row per skill_id in
`_provenance_specs_new.csv`; non-empty `provenance.sources`.

## Verification output (exact lines)

```
$ cd math_app && flutter test test/skill_spec_test.dart test/problem_generators_test.dart test/answer_normalization_test.dart test/skill_spec_store_test.dart
00:00 +56: All tests passed!

$ cd math_app && flutter analyze
analyzer errors: 0
335 issues found. (ran in 1.9s)          <- baseline was 335; new code adds 0

$ python scripts/check_specs.py
OK: 36 specs validated
exit=0

$ python scripts/sync_skill_specs.py      <- first run
synced 36 skill specs to C:\Users\jakob\StudioProjects\Math_App\math_app\assets\skill_specs (36 copied, 0 unchanged)
exit=0
$ python scripts/sync_skill_specs.py      <- re-run (idempotent)
synced 36 skill specs to ... (0 copied, 36 unchanged)
exit=0

$ cd math_app && flutter test
00:07 +165: All tests passed!             <- 109 baseline + 56 new
```

## Specs that failed the validator and why

`check_specs.py` initially failed for exactly **6 specs**: `A2.1, A2.2, A2.3,
A3.1, A3.2, A3.3` with `no skill_spec row in _provenance_specs_new.csv`. The
validator was right (P3 §7 requires one provenance row per spec, `type=skill_spec`);
the CSV only had 30 of the 36 rows. Fixed the CSV by adding the 6 missing
`skill_spec` rows with sources taken from each spec's own `provenance.sources`.

No other spec failed: all 36 pass the schema + params/enum/range checks and
both Dart and Python validators agree.

## Notes / deviations

- `SkillSpecStore.load()` discovers bundled spec ids via `AssetManifest`
  (`assets/skill_specs/*.json`), so no hard-coded id list needs maintenance and
  a missing asset raises the typed `SkillSpecAssetException`.
- `generateProblems` samples with retry (up to 50 attempts) for uniqueness
  within a level and falls back to filling the remaining count — the
  `problem_count` contract always wins on narrow ranges.
- `sequence_gap` clamps the sampled start so every value stays within ZR100 and
  downward sequences never drop below 1 (spec ranges already guarantee this;
  the clamps are a hard safety net). `progression: "double"` ignores `step`
  (verified in tests).
- One Dart gotcha fixed during TDD: `List` equality in Dart is identity-based,
  so the levels-numbered check compares `levels[0..2].level` element-wise.
