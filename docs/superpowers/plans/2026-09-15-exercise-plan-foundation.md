# Exercise Plan Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the v4 diagnostic taxonomy (93 skills, `math_app/Research/skills_taxonomy.csv`) actually playable end-to-end — close the currently-live gap where every diagnosed skill routes the child to "Für diese Übung gibt es noch keine Aufgaben" — and leave a proven, documented authoring pattern plus a tracked build order for the remaining skills.

**Architecture:** The live practice pipeline (`student-auth` → `learning-path` → `practice-session`, rendered by `PracticeScreen`/`PracticeController`) is already fully built and multi-tenant; it drives off bundled `SkillSpec` JSON assets (`math_app/assets/skill_specs/*.json`, 3 E-I-S levels each, generated via `scripts/sync_skill_specs.py` from source trees under `docs/clean-room/*/skills/specs/`). The bundled specs today are all keyed to a *retired* pre-v4 id scheme (`A1.1a`, `C3.4a`, ...) that no diagnosed skill ever produces anymore, so `SkillSpecStore.byId(skillId)` throws for every real v4 skill. This plan: (1) establishes `docs/clean-room/v4/skills/specs/` as the v4 source tree and wires it into the sync pipeline, (2) builds a coverage checker that turns "which of the 93 skills are playable" into one command, (3) archives the orphaned pre-v4 specs and their now-obsolete validator, (4) proves the "port an old exercise's manipulative into a `custom_widget`" pattern by migrating one already-built widget family (doubling) onto its real v4 id, (5) proves the "build a brand-new manipulative" pattern by authoring halving from scratch (the one construct with zero old archetype), (6) writes down the authoring checklist those two pilots demonstrate, and (7) turns the approved design doc's remaining 91 skills into an ordered, trackable backlog for follow-on plans.

**Tech Stack:** Flutter/Dart (app, widget tests via `flutter_test`), Python 3 stdlib (repo scripts + `unittest`), JSON (skill specs), CSV (taxonomy source).

**Spec:** `docs/superpowers/specs/2026-09-15-exercise-plan-design.md`

## Global Constraints

- Real German umlauts (ü/ö/ä/ß) in every child/teacher-facing string (`title_de`, `prompt_de`, `label_de`, `hint_de`, level titles); ASCII-only in code identifiers, file paths, and registry keys.
- Every shipped `skill_id` must exactly match a `skill_id` row in `math_app/Research/skills_taxonomy.csv` (93 rows) — enforced by `scripts/check_skill_spec_coverage.py` (Task 2).
- `math_app/assets/skill_specs/*.json` is generated output. Never hand-edit a file there — edit the source under `docs/clean-room/*/skills/specs/` and run `python scripts/sync_skill_specs.py`.
- New v4 specs are governed by `DIFFICULTY_CURVE.md` and `EXERCISE_DESIGN_SYSTEM.md`, not by the retired v1 `check_specs.py` policy (which hard-coded `correct_of == 8` and a 3-value `slow_band_ms` enum). Validation for v4 specs is the generic Dart-side schema in `SkillSpec.fromJson`/`SkillSpecStore.validateAll` (problem_count ∈ [4, 12], `mastery.correct_of` ∈ [1, problem_count], non-empty `error_taxonomy` with unique codes) plus Task 2's coverage check.
- A new `custom_widget` touches, at minimum: `kKnownCustomWidgets` in `math_app/lib/models/skill_spec.dart`, a generator case in `math_app/lib/practice/problem_generators.dart`, and a widget-building case in `math_app/lib/practice/template_registry.dart`. `math_app/lib/practice/template_evaluator.dart` only needs a new case when the widget's correctness rule is not a plain string match against `problem.expected` (the default branch of `_evaluateCustomWidget` already covers a plain match).
- Every task ends green: `flutter test` for Dart changes, `python -m unittest discover scripts/tests` for Python changes.

---

## Task 1: Add the v4 skill-spec source directory and wire it into the sync script

**Files:**
- Create: `docs/clean-room/v4/skills/specs/README.md`
- Modify: `scripts/sync_skill_specs.py`
- Test: `scripts/tests/test_sync_skill_specs.py`

**Interfaces:**
- Consumes: `scripts/sync_skill_specs.py`'s existing `SRC_DIRS: list[Path]` / `DEST_DIR: Path` module constants and `main(argv=None) -> int` entry point (unchanged shape).
- Produces: `SRC_DIRS` now includes `REPO_ROOT / "docs" / "clean-room" / "v4" / "skills" / "specs"`, consumed by every later task that adds a file under that directory.

- [ ] **Step 1: Write the failing test**

Add to `scripts/tests/test_sync_skill_specs.py`, inside `class SyncSkillSpecsTest`:

```python
    def test_src_dirs_includes_the_v4_specs_directory(self):
        suffixes = [d.as_posix() for d in sync_skill_specs.SRC_DIRS]
        self.assertTrue(
            any(s.endswith("docs/clean-room/v4/skills/specs") for s in suffixes),
            f"SRC_DIRS does not include the v4 specs directory: {suffixes}",
        )
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python -m unittest scripts.tests.test_sync_skill_specs -v` (from the repo root)
Expected: FAIL — `AssertionError: False is not true`

- [ ] **Step 3: Create the v4 source directory with a real README (not a placeholder)**

Write `docs/clean-room/v4/skills/specs/README.md`:

```markdown
# v4 skill specs (source of truth)

Skill-spec JSON source files for the v4 iMINT/PIKAS taxonomy
(`math_app/Research/skills_taxonomy.csv`, 93 skills). Each file's
`skill_id` must match a `skill_id` in that CSV exactly — checked by
`scripts/check_skill_spec_coverage.py`.

Never edit `math_app/assets/skill_specs/*.json` directly — that
directory is generated output. Edit the source file here, then run:

    python scripts/sync_skill_specs.py

Authoring pattern and archetype-tier checklist:
`docs/superpowers/specs/2026-09-15-exercise-plan-design.md` (what to build)
and `docs/skill_spec_authoring_guide.md` (how to build it).

Build order for the remaining skills: `docs/clean-room/v4/skills/BUILD_ORDER.md`.
```

- [ ] **Step 4: Wire the directory into the sync script**

In `scripts/sync_skill_specs.py`, change:

```python
SRC_DIRS = [
    REPO_ROOT / "docs" / "clean-room" / "skills" / "specs",
    REPO_ROOT / "docs" / "clean-room" / "v2" / "skills" / "specs",
]
```

to:

```python
SRC_DIRS = [
    REPO_ROOT / "docs" / "clean-room" / "skills" / "specs",
    REPO_ROOT / "docs" / "clean-room" / "v2" / "skills" / "specs",
    REPO_ROOT / "docs" / "clean-room" / "v4" / "skills" / "specs",
]
```

- [ ] **Step 5: Run test to verify it passes**

Run: `python -m unittest scripts.tests.test_sync_skill_specs -v`
Expected: PASS (all tests, including the new one)

- [ ] **Step 6: Run the real sync script to confirm nothing broke**

Run: `python scripts/sync_skill_specs.py`
Expected: `synced 37 skill specs to .../math_app/assets/skill_specs (0 copied, 37 unchanged)` — the v4 directory is empty so far, so the count is unchanged from before this task.

- [ ] **Step 7: Commit**

```bash
git add docs/clean-room/v4/skills/specs/README.md scripts/sync_skill_specs.py scripts/tests/test_sync_skill_specs.py
git commit -m "feat: add v4 skill-spec source directory to the sync pipeline"
```

---

## Task 2: Build the v4 skill-spec coverage checker

**Files:**
- Create: `scripts/check_skill_spec_coverage.py`
- Test: `scripts/tests/test_check_skill_spec_coverage.py`

**Interfaces:**
- Consumes: `math_app/Research/skills_taxonomy.csv` (column `skill_id`), `math_app/assets/skill_specs/*.json` (field `skill_id`) — both read-only.
- Produces: `taxonomy_skill_ids(csv_path: Path) -> set[str]`, `spec_skill_ids(specs_dir: Path) -> set[str]`, `main(argv=None) -> int`, and module constants `TAXONOMY_CSV`/`SPECS_DIR` — the report every later task runs to check its own progress, and the mechanism Task 7's backlog tracking assumes exists.

- [ ] **Step 1: Write the failing test**

Create `scripts/tests/test_check_skill_spec_coverage.py`:

```python
import csv
import io
import json
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import check_skill_spec_coverage as coverage


class CheckSkillSpecCoverageTest(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        self.csv_path = self.root / "skills_taxonomy.csv"
        self.specs_dir = self.root / "skill_specs"
        self.specs_dir.mkdir()

    def _write_csv(self, skill_ids):
        with self.csv_path.open("w", encoding="utf-8", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["skill_id", "domain", "construct_id", "color",
                              "title_de", "title_en", "description_de", "description_en"])
            for skill_id in skill_ids:
                writer.writerow([skill_id, "A", "c", "amber", "t", "t", "d", "d"])

    def _write_spec(self, skill_id):
        (self.specs_dir / f"{skill_id}.json").write_text(
            json.dumps({"skill_id": skill_id}), encoding="utf-8"
        )

    def _run(self):
        buffer = io.StringIO()
        with (
            mock.patch.object(coverage, "TAXONOMY_CSV", self.csv_path),
            mock.patch.object(coverage, "SPECS_DIR", self.specs_dir),
            redirect_stdout(buffer),
        ):
            code = coverage.main()
        return code, buffer.getvalue()

    def test_full_coverage_exits_zero(self):
        self._write_csv(["double_zr10", "halve_zr10"])
        self._write_spec("double_zr10")
        self._write_spec("halve_zr10")

        code, out = self._run()

        self.assertEqual(code, 0)
        self.assertIn("OK: every taxonomy skill has exactly one spec", out)

    def test_missing_spec_is_reported_and_fails(self):
        self._write_csv(["double_zr10", "halve_zr10"])
        self._write_spec("double_zr10")

        code, out = self._run()

        self.assertEqual(code, 1)
        self.assertIn("missing (1)", out)
        self.assertIn("halve_zr10", out)

    def test_orphaned_spec_is_reported_and_fails(self):
        self._write_csv(["double_zr10"])
        self._write_spec("double_zr10")
        self._write_spec("A1.1a")

        code, out = self._run()

        self.assertEqual(code, 1)
        self.assertIn("extra (1)", out)
        self.assertIn("A1.1a", out)

    def test_missing_taxonomy_csv_fails_loudly(self):
        self.csv_path.unlink(missing_ok=True)

        code, out = self._run()

        self.assertEqual(code, 1)
        self.assertIn("ERROR: taxonomy CSV not found", out)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python -m unittest scripts.tests.test_check_skill_spec_coverage -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'check_skill_spec_coverage'`

- [ ] **Step 3: Write the implementation**

Create `scripts/check_skill_spec_coverage.py`:

```python
#!/usr/bin/env python3
"""Coverage report for the v4 skill-spec bundle.

Compares every skill_id in math_app/Research/skills_taxonomy.csv (the v4
iMINT/PIKAS taxonomy) against every skill_id actually present in the
synced math_app/assets/skill_specs/*.json bundle (see
scripts/sync_skill_specs.py). Reports two kinds of drift:

  - missing: a taxonomy skill with no spec -- a diagnosed skill the child
    cannot yet practice (child_path_screen.dart falls back to "no exercises
    yet" for these).
  - extra: a spec whose skill_id is not in the taxonomy -- orphaned
    content, typically a retired id left behind by a taxonomy rename.

Exit 0 only when both lists are empty. Run after every
sync_skill_specs.py run to check progress against the 93-skill build
order (docs/clean-room/v4/skills/BUILD_ORDER.md).
"""

from __future__ import annotations

import csv
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TAXONOMY_CSV = REPO_ROOT / "math_app" / "Research" / "skills_taxonomy.csv"
SPECS_DIR = REPO_ROOT / "math_app" / "assets" / "skill_specs"


def taxonomy_skill_ids(csv_path: Path) -> set[str]:
    with csv_path.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        return {row["skill_id"] for row in reader if row.get("skill_id")}


def spec_skill_ids(specs_dir: Path) -> set[str]:
    ids: set[str] = set()
    for path in specs_dir.glob("*.json"):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            print(f"ERROR: {path.name} is not valid JSON: {exc}")
            continue
        skill_id = data.get("skill_id")
        if skill_id:
            ids.add(skill_id)
    return ids


def main(argv: list[str] | None = None) -> int:
    if not TAXONOMY_CSV.is_file():
        print(f"ERROR: taxonomy CSV not found: {TAXONOMY_CSV}")
        return 1
    if not SPECS_DIR.is_dir():
        print(f"ERROR: specs directory not found: {SPECS_DIR}")
        return 1

    taxonomy_ids = taxonomy_skill_ids(TAXONOMY_CSV)
    spec_ids = spec_skill_ids(SPECS_DIR)

    missing = sorted(taxonomy_ids - spec_ids)
    extra = sorted(spec_ids - taxonomy_ids)

    print(f"taxonomy: {len(taxonomy_ids)} skills, specs: {len(spec_ids)} skills")
    print(f"covered: {len(taxonomy_ids) - len(missing)}/{len(taxonomy_ids)}")

    if missing:
        print(f"\nmissing ({len(missing)}): no spec yet for these taxonomy skills:")
        for skill_id in missing:
            print(f"  - {skill_id}")
    if extra:
        print(f"\nextra ({len(extra)}): specs with no matching taxonomy skill:")
        for skill_id in extra:
            print(f"  - {skill_id}")

    if not missing and not extra:
        print("OK: every taxonomy skill has exactly one spec, no orphans")
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python -m unittest scripts.tests.test_check_skill_spec_coverage -v`
Expected: PASS (4/4)

- [ ] **Step 5: Run the real checker to see today's actual gap**

Run: `python scripts/check_skill_spec_coverage.py`
Expected: exit 1, `covered: 0/93`, all 93 taxonomy skills listed under `missing`, and all 37 files currently in `math_app/assets/skill_specs/` listed under `extra` (they're all pre-v4 ids). This confirms the live bug named in this plan's Goal: right now, zero diagnosed v4 skills are playable.

- [ ] **Step 6: Commit**

```bash
git add scripts/check_skill_spec_coverage.py scripts/tests/test_check_skill_spec_coverage.py
git commit -m "feat: add a coverage checker for v4 skill specs vs the taxonomy"
```

---

## Task 3: Archive the orphaned pre-v4 specs and retire their v1 validator

**Files:**
- Move: `docs/clean-room/skills/specs/*.json` (36 files) and `docs/clean-room/skills/specs/_provenance_specs_new.csv` → `docs/archive/skill_specs_pre_v4/v1/`
- Delete: `scripts/check_specs.py` (its target directory no longer exists; no test file references it)
- Modify: `scripts/sync_skill_specs.py`
- Modify: `math_app/test/skill_spec_store_test.dart`
- Test: `scripts/tests/test_sync_skill_specs.py` (existing tests must still pass unmodified — they pass explicit source dirs)

**Interfaces:**
- Consumes: Task 1's `SRC_DIRS` list, Task 2's `check_skill_spec_coverage.py` (used in Step 6 to confirm the 36 v1 orphans drop out of the `extra` report).
- Produces: `SRC_DIRS` now contains only the v4 entry going into Task 4; `math_app/test/skill_spec_store_test.dart` now validates whatever is present in `docs/clean-room/v4/skills/specs/` instead of a hard-coded 36-file v1 fixture.

- [ ] **Step 1: Archive the v1 spec tree**

```bash
mkdir -p docs/archive/skill_specs_pre_v4/v1
git mv docs/clean-room/skills/specs/*.json docs/archive/skill_specs_pre_v4/v1/
git mv docs/clean-room/skills/specs/_provenance_specs_new.csv docs/archive/skill_specs_pre_v4/v1/
```

(The v2 directory, `docs/clean-room/v2/skills/specs/verdoppeln-halbieren.ZR10.json`, is left in place — Task 4 moves it directly to its new v4 home rather than through the archive.)

- [ ] **Step 2: Retire the v1-only validator**

```bash
git rm scripts/check_specs.py
```

Its policy (exactly 8 problems/level, a 3-value `slow_band_ms` enum) was specific to the now-archived v1 tree; v4 specs are validated generically by `SkillSpec.fromJson`/`SkillSpecStore.validateAll` plus Task 2's coverage checker.

- [ ] **Step 3: Drop the archived directory from the sync pipeline and update its docstring**

In `scripts/sync_skill_specs.py`, change the module docstring from:

```python
"""Mirror the P3 skill specs into the Flutter bundle assets.

Copies docs/clean-room/skills/specs/*.json (v1) AND
docs/clean-room/v2/skills/specs/*.json (v2) into math_app/assets/skill_specs/,
creating the destination directory when needed. Idempotent: files that are
already present and byte-identical are left untouched. Prints a summary.
"""
```

to:

```python
"""Mirror the v4 skill specs into the Flutter bundle assets.

Copies docs/clean-room/v4/skills/specs/*.json into
math_app/assets/skill_specs/, creating the destination directory when
needed. Idempotent: files that are already present and byte-identical are
left untouched. Prints a summary.

The v1 (docs/clean-room/skills/specs) and v2 (docs/clean-room/v2/skills/specs)
trees this script used to also mirror are retired: their skill ids predate
the current taxonomy (math_app/Research/skills_taxonomy.csv) and are archived
under docs/archive/skill_specs_pre_v4/.
"""
```

and change `SRC_DIRS` from:

```python
SRC_DIRS = [
    REPO_ROOT / "docs" / "clean-room" / "skills" / "specs",
    REPO_ROOT / "docs" / "clean-room" / "v2" / "skills" / "specs",
    REPO_ROOT / "docs" / "clean-room" / "v4" / "skills" / "specs",
]
```

to:

```python
SRC_DIRS = [
    REPO_ROOT / "docs" / "clean-room" / "v4" / "skills" / "specs",
]
```

- [ ] **Step 4: Run the sync-script tests to confirm nothing broke**

Run: `python -m unittest scripts.tests.test_sync_skill_specs -v`
Expected: PASS — every existing test passes explicit `source_dirs` to `_run()`, so trimming the real `SRC_DIRS` doesn't affect them; the Task 1 wiring test still passes since the v4 entry remains.

- [ ] **Step 5: Re-sync and confirm the stale bundle files are gone**

```bash
rm math_app/assets/skill_specs/*.json
python scripts/sync_skill_specs.py
```

Expected: `synced 0 skill specs to .../math_app/assets/skill_specs (0 copied, 0 unchanged)`, and `math_app/assets/skill_specs/` is now empty — `SRC_DIRS` contains only the (still-empty) v4 directory after Step 3, and the leftover `docs/clean-room/v2/skills/specs/verdoppeln-halbieren.ZR10.json` is no longer synced (it stays on disk, untouched, for Task 4 to move directly into the v4 tree).

- [ ] **Step 6: Confirm the coverage checker now reports a clean, empty-but-honest gap**

Run: `python scripts/check_skill_spec_coverage.py`
Expected: exit 1, `covered: 0/93`, all 93 skills under `missing`, and an **empty** `extra` section (the 37 orphans are gone from the bundle, not just re-labelled).

- [ ] **Step 7: Rewrite the skill-spec store test to validate the v4 tree generically**

Replace the full contents of `math_app/test/skill_spec_store_test.dart` with:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/skill_spec.dart';
import 'package:math_app/services/skill_spec_store.dart';

const String _specsDir = '../docs/clean-room/v4/skills/specs';

/// Test-only loader: reads the real v4 spec JSONs straight from the source
/// tree, so the parser is verified against exactly what the sync script
/// ships into the app bundle. Grows as batches add specs -- unlike the
/// retired v1/v2 suite this replaces, it does not hard-code a total count.
Map<String, String> _loadRealSpecJsons() {
  final dir = Directory(_specsDir);
  expect(dir.existsSync(), isTrue, reason: 'v4 spec tree must exist');
  final jsons = <String, String>{};
  final files =
      dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    jsons[file.path.split(Platform.pathSeparator).last] = file
        .readAsStringSync();
  }
  return jsons;
}

void main() {
  group('SkillSpecStore.fromJsonMap (v4 specs)', () {
    test('every bundled v4 spec parses and validates', () {
      final jsons = _loadRealSpecJsons();
      final store = SkillSpecStore.fromJsonMap(jsons);
      expect(store.allIds(), hasLength(jsons.length));
      expect(store.allSpecs(), hasLength(jsons.length));
      expect(store.validateAll(), isEmpty);
    });

    test('every spec id matches its own file name', () {
      for (final entry in _loadRealSpecJsons().entries) {
        final decoded = jsonDecode(entry.value) as Map<String, dynamic>;
        expect('${decoded['skill_id']}.json', entry.key);
      }
    });

    test('byId throws for an unknown id', () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      expect(() => store.byId('nope'), throwsA(isA<ArgumentError>()));
    });

    test('a schema-invalid spec fails fast with SpecFormatException', () {
      final bad = jsonEncode({'skill_id': 'T1'});
      expect(
        () => SkillSpecStore.fromJsonMap({'T1': bad}),
        throwsA(isA<SpecFormatException>()),
      );
    });
  });
}
```

- [ ] **Step 8: Run the Dart test to verify it passes on an empty v4 tree**

Run: `cd math_app && flutter test test/skill_spec_store_test.dart`
Expected: PASS — `_loadRealSpecJsons()` returns an empty map (the v4 dir has only `README.md`, no `.json` files yet), so every assertion holds vacuously.

- [ ] **Step 9: Commit**

```bash
git add docs/archive/skill_specs_pre_v4 scripts/check_specs.py scripts/sync_skill_specs.py math_app/test/skill_spec_store_test.dart math_app/assets/skill_specs
git commit -m "chore: archive pre-v4 skill specs and their retired validator"
```

---

## Task 4: Pilot A (Reused) — retarget the doubling-mirror spec onto its real v4 id

**Files:**
- Move: `docs/clean-room/v2/skills/specs/verdoppeln-halbieren.ZR10.json` → `docs/clean-room/v4/skills/specs/double_zr10.json`
- Test: `math_app/test/skill_spec_store_test.dart` (extend)
- Test: `math_app/test/problem_generators_test.dart` (extend, real-spec check)

**Interfaces:**
- Consumes: the already-shipped `doubling_mirror_enaktiv`/`_ikonisch`/`_symbolisch` custom widgets, generator, and registry entries (all unchanged — this task only retargets the spec's ids, not the code that renders it).
- Produces: `docs/clean-room/v4/skills/specs/double_zr10.json` — the first real entry in the v4 tree, and the first skill the coverage checker will report as covered.

- [ ] **Step 1: Move and retarget the spec**

```bash
git mv docs/clean-room/v2/skills/specs/verdoppeln-halbieren.ZR10.json docs/clean-room/v4/skills/specs/double_zr10.json
```

Edit the moved file's top-level fields (leave `title_de`, `level_titles_de`, `levels`, `mastery`, `error_taxonomy`, and `provenance` exactly as they are — only the identity fields change, because they matched the CSV already):

```json
{
  "spec_version": 1,
  "skill_id": "double_zr10",
  "construct_id": "double",
  "domain": "C",
  "title_de": "Verdoppeln im ZR10",
```

(the rest of the file — `level_titles_de` through `provenance` — is unchanged).

- [ ] **Step 2: Sync and check coverage**

```bash
python scripts/sync_skill_specs.py
python scripts/check_skill_spec_coverage.py
```

Expected: sync reports `1 copied`; coverage reports `covered: 1/93`, `double_zr10` no longer in `missing`, `extra` stays empty.

- [ ] **Step 3: Extend the skill-spec store test with the pilot's specifics**

Add to the `group('SkillSpecStore.fromJsonMap (v4 specs)', ...)` block in `math_app/test/skill_spec_store_test.dart`:

```dart
    test('double_zr10 (Pilot A) parses with the doubling-mirror widgets', () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('double_zr10');
      expect(spec.constructId, 'double');
      expect(spec.domain, 'C');
      expect(spec.titleDe, 'Verdoppeln im ZR10');
      expect(spec.levels.map((l) => l.customWidget), [
        'doubling_mirror_enaktiv',
        'doubling_mirror_ikonisch',
        'doubling_mirror_symbolisch',
      ]);
    });
```

- [ ] **Step 4: Run test to verify it fails first, then passes**

Run: `cd math_app && flutter test test/skill_spec_store_test.dart`
Expected before Step 1/2: FAIL (`double_zr10` not found). After Steps 1–2: PASS.

- [ ] **Step 5: Add a real-spec check to the generator test suite**

In `math_app/test/problem_generators_test.dart`, inside `group('custom_widget generators (P2 §5 registry)', ...)`, add:

```dart
    test('real double_zr10 generates valid doubling-mirror problems', () {
      final s = _realSpec('double_zr10');
      for (var level = 1; level <= 3; level++) {
        for (var seed = 0; seed < 30; seed++) {
          for (final p in generateProblems(spec: s, level: level, seed: seed)) {
            final target = p.display['target'] as int;
            expect(target, inInclusiveRange(1, 5));
            expect(p.expected, ['${target * 2}']);
          }
        }
      }
    });
```

(This reuses the existing `_realSpec` helper already used by the `A2.1`/`B1.3` real-spec tests earlier in the same file — it loads by skill id from the synced `docs/clean-room/v4/skills/specs` tree the same way `_loadRealSpecJsons` does above.)

- [ ] **Step 6: Run test to verify it passes**

Run: `cd math_app && flutter test test/problem_generators_test.dart test/skill_spec_store_test.dart`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add docs/clean-room/v4/skills/specs/double_zr10.json math_app/assets/skill_specs math_app/test/skill_spec_store_test.dart math_app/test/problem_generators_test.dart
git commit -m "feat: retarget the doubling-mirror spec onto its v4 id (double_zr10)"
```

---

## Task 5: Pilot B (New — from scratch) — author `halve_zr10` with new halving-mirror widgets

**Files:**
- Create: `docs/clean-room/v4/skills/specs/halve_zr10.json`
- Create: `math_app/lib/widgets/templates/halving_mirror_enaktiv_widget.dart`
- Create: `math_app/lib/widgets/templates/halving_mirror_ikonisch_widget.dart`
- Create: `math_app/lib/widgets/templates/halving_mirror_symbolisch_widget.dart`
- Modify: `math_app/lib/models/skill_spec.dart` (`kKnownCustomWidgets`)
- Modify: `math_app/lib/practice/problem_generators.dart` (new generator + registry case)
- Modify: `math_app/lib/practice/template_registry.dart` (3 new widget-building cases)
- Test: `math_app/test/problem_generators_test.dart`
- Test: `math_app/test/skill_spec_store_test.dart`

**Interfaces:**
- Consumes: `Problem`/`LevelSpec`/`SeededGenerator` (unchanged, from `math_app/lib/models/problem.dart` and `problem_generators.dart`'s existing helpers), the exact widget-porting pattern demonstrated by `DoublingMirrorEnaktivWidget`/`Ikonisch`/`Symbolisch` (`math_app/lib/widgets/templates/doubling_mirror_*_widget.dart`, read but not modified).
- Produces: three new `kKnownCustomWidgets` registry keys (`halving_mirror_enaktiv`, `halving_mirror_ikonisch`, `halving_mirror_symbolisch`); `_generateHalvingMirror(spec, level, levelNumber, seed, index, gen) -> Problem`; three new widget classes (`HalvingMirrorEnaktivWidget`, `HalvingMirrorIkonischWidget`, `HalvingMirrorSymbolischWidget`) with the standard `({required Problem problem, required ValueChanged<String> onValueChanged})` constructor contract every template widget shares.

- [ ] **Step 1: Register the three new custom-widget keys**

In `math_app/lib/models/skill_spec.dart`, change:

```dart
const Set<String> kKnownCustomWidgets = {
  'bundling',
  'unbundling',
  'numberline_mark',
  'flash_subitize',
  'doubling_mirror_enaktiv',
  'doubling_mirror_ikonisch',
  'doubling_mirror_symbolisch',
};
```

to:

```dart
const Set<String> kKnownCustomWidgets = {
  'bundling',
  'unbundling',
  'numberline_mark',
  'flash_subitize',
  'doubling_mirror_enaktiv',
  'doubling_mirror_ikonisch',
  'doubling_mirror_symbolisch',
  'halving_mirror_enaktiv',
  'halving_mirror_ikonisch',
  'halving_mirror_symbolisch',
};
```

- [ ] **Step 2: Write the failing generator test**

In `math_app/test/problem_generators_test.dart`, inside `group('custom_widget generators (P2 §5 registry)', ...)`, add right after the existing `'doubling_mirror_enaktiv: target in [1,5], expected == target*2'` test:

```dart
    test('halving_mirror_enaktiv: half in [1,5], full == half*2, expected '
        '== half', () {
      final s = spec('halving_mirror_enaktiv', {'count_range': [1, 5]});
      for (var seed = 0; seed < 200; seed++) {
        for (final p in generateProblems(spec: s, level: 2, seed: seed)) {
          final half = int.parse(p.expected.single);
          final full = p.display['full'] as int;
          expect(half, inInclusiveRange(1, 5));
          expect(full, half * 2);
          expect(p.display['custom_widget'], 'halving_mirror_enaktiv');
        }
      }
    });
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd math_app && flutter test test/problem_generators_test.dart`
Expected: FAIL — `_generateCustomWidget` throws `SpecFormatException: custom_widget: unknown registry key "halving_mirror_enaktiv"`.

- [ ] **Step 4: Add the generator**

In `math_app/lib/practice/problem_generators.dart`, add a case to `_generateCustomWidget`'s switch:

```dart
    case 'halving_mirror_enaktiv':
    case 'halving_mirror_ikonisch':
    case 'halving_mirror_symbolisch':
      return _generateHalvingMirror(spec, level, levelNumber, seed, index, gen);
```

(placed alongside the existing `doubling_mirror_*` case, before `default`).

Then add the generator function itself, near `_generateDoublingMirror`:

```dart
/// Registry keys `"halving_mirror_enaktiv"`, `"halving_mirror_ikonisch"`,
/// `"halving_mirror_symbolisch"` (halve_zr10, alle drei Level derselben
/// Skill-Spec): mirrors `_generateDoublingMirror` in reverse. `count_range`
/// bounds the *half*, exactly like doubling's `count_range` bounds the
/// pre-doubled value -- so a [1, 5] range produces a full amount in [2, 10]
/// and the child reports the half.
Problem _generateHalvingMirror(
  SkillSpec spec,
  LevelSpec level,
  int levelNumber,
  int seed,
  int index,
  SeededGenerator gen,
) {
  final countRange = level.intListParam('count_range');
  final lo = countRange.isEmpty ? 1 : countRange[0];
  final hi = countRange.isEmpty ? 5 : countRange[1];
  if (lo < 1 || hi > 5 || lo > hi) {
    throw SpecFormatException(
      'halving_mirror: count_range [$lo, $hi] must be within [1, 5] for ZR10',
    );
  }
  final half = gen.nextIntInRange(lo, hi);
  final full = half * 2;

  return Problem(
    template: 'custom_widget',
    skillId: spec.skillId,
    level: levelNumber,
    seed: seed,
    index: index,
    promptDe: level.promptDe,
    display: {'custom_widget': level.customWidget, 'full': full},
    expected: ['$half'],
  );
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd math_app && flutter test test/problem_generators_test.dart`
Expected: PASS

- [ ] **Step 6: Create the enaktiv widget**

Create `math_app/lib/widgets/templates/halving_mirror_enaktiv_widget.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Custom-widget template for the registry key `"halving_mirror_enaktiv"`
/// (halve_zr10, Level 1/enaktiv). Mirrors `DoublingMirrorEnaktivWidget` in
/// reverse: the child starts with the full amount and splits it into two
/// equal piles instead of building up to a doubled total. Not a refactor of
/// the doubling widget -- a fresh copy with the loop bound and final
/// question inverted.
///
/// The child counts the blue dots on the left (the full amount), drags them
/// one at a time to the right pile, and stops once exactly half have moved
/// across. Steps 0 (verify the full count) and 1 (drag until half) stay
/// internally gated -- scaffolding, not the graded answer. Step 2 (how many
/// moved, i.e. the half) is reported live via [onValueChanged]; the practice
/// screen's generic submit button and [TemplateEvaluator] decide correctness
/// against `problem.expected`.
class HalvingMirrorEnaktivWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const HalvingMirrorEnaktivWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<HalvingMirrorEnaktivWidget> createState() =>
      _HalvingMirrorEnaktivWidgetState();
}

class _HalvingMirrorEnaktivWidgetState
    extends State<HalvingMirrorEnaktivWidget> {
  // Steps:
  // 0: Count Full (internally verified)
  // 1: Drag Right until half has moved (internally verified)
  // 2: Report Half (reported via onValueChanged, graded centrally)
  int _step = 0;

  int _rightCount = 0;
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _halfController = TextEditingController();
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.black;

  int get _fullCount => (widget.problem.display['full'] as num).toInt();
  int get _halfCount => _fullCount ~/ 2;

  @override
  void didUpdateWidget(covariant HalvingMirrorEnaktivWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _step = 0;
      _rightCount = 0;
      _leftController.clear();
      _halfController.clear();
      _feedbackMessage = '';
    });
    widget.onValueChanged('');
  }

  void _checkFullCount() {
    final input = int.tryParse(_leftController.text);
    if (input == null) return;

    if (input == _fullCount) {
      setState(() {
        _step = 1;
        _feedbackMessage = 'Richtig! Jetzt teile sie auf.';
        _feedbackColor = Colors.green;
        _leftController.clear();
      });
    } else {
      setState(() {
        _feedbackMessage = 'Fast! Zähl nochmal!';
        _feedbackColor = Colors.orange;
        _leftController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            _getInstructionText(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  _feedbackMessage.isNotEmpty ? _feedbackColor : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                  ),
                  child: Center(
                    child: _buildDotGrid(_fullCount, Colors.blue),
                  ),
                ),
              ),
              Container(width: 4, color: Colors.grey.shade400),
              Expanded(
                child: DragTarget<int>(
                  onWillAccept: (data) => _step == 1 && _rightCount < _halfCount,
                  onAccept: (data) {
                    setState(() {
                      _rightCount++;
                      if (_rightCount == _halfCount) {
                        _step = 2;
                        _feedbackMessage =
                            'Super! Wie viele hast du herübergezogen?';
                        _feedbackColor = Colors.green;
                      }
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              _step == 1 ? Colors.blue : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: _buildDotGrid(_rightCount, Colors.red),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: switch (_step) {
            0 => _buildFullCountInput(),
            1 => _buildDragSource(),
            _ => _buildFinalAnswerField(),
          },
        ),
      ],
    );
  }

  String _getInstructionText() {
    if (_feedbackMessage.isNotEmpty) return _feedbackMessage;
    switch (_step) {
      case 0:
        return 'Wie viele blaue Punkte siehst du?';
      case 1:
        return 'Zieh die Hälfte der Punkte nach rechts!';
      default:
        return 'Wie viele hast du herübergezogen?';
    }
  }

  Widget _buildDotGrid(int count, Color color) => Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: List.generate(count, (index) => _buildDot(color)),
      );

  Widget _buildDot(Color color) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      );

  Widget _buildDragSource() => Center(
        child: Draggable<int>(
          data: 1,
          feedback: _buildDot(Colors.red.withOpacity(0.8)),
          childWhenDragging: _buildDot(Colors.red),
          child: _buildDot(Colors.red),
        ),
      );

  Widget _buildFullCountInput() => Row(
        children: [
          Expanded(
            child: TextField(
              controller: _leftController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '?',
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              onSubmitted: (_) => _checkFullCount(),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _checkFullCount,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.green,
            ),
            child: const Text('OK', style: TextStyle(fontSize: 24)),
          ),
        ],
      );

  Widget _buildFinalAnswerField() => TextField(
        key: const ValueKey('final-answer'),
        controller: _halfController,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: '?',
          filled: true,
          fillColor: Colors.white,
        ),
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        onChanged: widget.onValueChanged,
      );
}
```

- [ ] **Step 7: Create the ikonisch widget**

Create `math_app/lib/widgets/templates/halving_mirror_ikonisch_widget.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Custom-widget template for the registry key `"halving_mirror_ikonisch"`
/// (halve_zr10, Level 2/ikonisch). Mirrors `DoublingMirrorIkonischWidget` in
/// reverse. The child counts the full amount, presses a split button that
/// reveals a group showing half that amount, then reports how many are in
/// it -- reported live via [onValueChanged], graded centrally like every
/// other custom_widget.
class HalvingMirrorIkonischWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const HalvingMirrorIkonischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<HalvingMirrorIkonischWidget> createState() =>
      _HalvingMirrorIkonischWidgetState();
}

class _HalvingMirrorIkonischWidgetState
    extends State<HalvingMirrorIkonischWidget>
    with SingleTickerProviderStateMixin {
  // Steps: 0 count full (internal), 1 press split (internal), 2 report half.
  int _step = 0;

  bool _isSplit = false;
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _halfController = TextEditingController();
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.black;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  int get _fullCount => (widget.problem.display['full'] as num).toInt();
  int get _halfCount => _fullCount ~/ 2;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HalvingMirrorIkonischWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _step = 0;
      _isSplit = false;
      _leftController.clear();
      _halfController.clear();
      _feedbackMessage = '';
      _animController.reset();
    });
    widget.onValueChanged('');
  }

  void _checkFullCount() {
    final input = int.tryParse(_leftController.text);
    if (input == null) return;

    if (input == _fullCount) {
      setState(() {
        _step = 1;
        _feedbackMessage = 'Richtig! Drücke den Teilen-Knopf.';
        _feedbackColor = Colors.green;
        _leftController.clear();
      });
    } else {
      setState(() {
        _feedbackMessage = 'Fast! Versuch es nochmal!';
        _feedbackColor = Colors.orange;
        _leftController.clear();
      });
    }
  }

  void _activateSplit() {
    setState(() {
      _isSplit = true;
      _step = 2;
      _feedbackMessage = 'Geteilt! Wie viele sind es in einer Gruppe?';
      _feedbackColor = Colors.green;
    });
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            _getInstructionText(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  _feedbackMessage.isNotEmpty ? _feedbackColor : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.blue.shade200, width: 2),
                      ),
                      child: Center(
                        child: _buildDotGrid(_fullCount, Colors.blue),
                      ),
                    ),
                  ),
                  Container(width: 4, color: Colors.transparent),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                      child: Center(
                        child: _isSplit
                            ? ScaleTransition(
                                scale: _scaleAnimation,
                                child: _buildDotGrid(_halfCount, Colors.red),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              Center(
                child: Container(
                  width: 4,
                  height: double.infinity,
                  color: Colors.grey.shade400,
                ),
              ),
              Center(
                child: _step == 1
                    ? ElevatedButton(
                        onPressed: _activateSplit,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(24),
                          backgroundColor: Colors.purple,
                        ),
                        child: const Icon(Icons.call_split,
                            size: 32, color: Colors.white),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call_split, color: Colors.grey),
                      ),
              ),
            ],
          ),
        ),
        Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: switch (_step) {
            0 => _buildFullCountInput(),
            1 => const Center(
                child: Text('Drücke den Teilen-Knopf in der Mitte!',
                    style: TextStyle(fontSize: 18)),
              ),
            _ => _buildFinalAnswerField(),
          },
        ),
      ],
    );
  }

  String _getInstructionText() {
    if (_feedbackMessage.isNotEmpty) return _feedbackMessage;
    switch (_step) {
      case 0:
        return 'Wie viele blaue Punkte siehst du?';
      case 1:
        return 'Drücke den Teilen-Knopf!';
      default:
        return 'Wie viele sind es in einer Gruppe?';
    }
  }

  Widget _buildDotGrid(int count, Color color) => Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: List.generate(count, (index) => _buildDot(color)),
      );

  Widget _buildDot(Color color) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      );

  Widget _buildFullCountInput() => Row(
        children: [
          Expanded(
            child: TextField(
              controller: _leftController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '?',
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              onSubmitted: (_) => _checkFullCount(),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _checkFullCount,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.green,
            ),
            child: const Text('OK', style: TextStyle(fontSize: 24)),
          ),
        ],
      );

  Widget _buildFinalAnswerField() => TextField(
        key: const ValueKey('final-answer'),
        controller: _halfController,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: '?',
          filled: true,
          fillColor: Colors.white,
        ),
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        onChanged: widget.onValueChanged,
      );
}
```

- [ ] **Step 8: Create the symbolisch widget**

Create `math_app/lib/widgets/templates/halving_mirror_symbolisch_widget.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Custom-widget template for the registry key
/// `"halving_mirror_symbolisch"` (halve_zr10, Level 3/symbolisch). Mirrors
/// `DoublingMirrorSymbolischWidget` in reverse. Shows a number card with the
/// full amount and asks for its half; the field reports live via
/// [onValueChanged], graded centrally by the practice screen's one generic
/// submit button.
class HalvingMirrorSymbolischWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const HalvingMirrorSymbolischWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<HalvingMirrorSymbolischWidget> createState() =>
      _HalvingMirrorSymbolischWidgetState();
}

class _HalvingMirrorSymbolischWidgetState
    extends State<HalvingMirrorSymbolischWidget> {
  final TextEditingController _controller = TextEditingController();

  int get _fullCount => (widget.problem.display['full'] as num).toInt();

  @override
  void didUpdateWidget(covariant HalvingMirrorSymbolischWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _controller.clear();
      widget.onValueChanged('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Stell dir vor:',
          style: TextStyle(fontSize: 24, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.blue.shade200, width: 2),
          ),
          child: Center(
            child: Text(
              '$_fullCount',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          'Was ist die Hälfte?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 200,
          child: TextField(
            key: const ValueKey('final-answer'),
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              hintText: '?',
            ),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            autofocus: true,
            onChanged: widget.onValueChanged,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 9: Wire the three widgets into the template registry**

In `math_app/lib/practice/template_registry.dart`, add three imports alongside the existing `doubling_mirror_*` ones:

```dart
import '../widgets/templates/halving_mirror_enaktiv_widget.dart';
import '../widgets/templates/halving_mirror_ikonisch_widget.dart';
import '../widgets/templates/halving_mirror_symbolisch_widget.dart';
```

and, inside the `'custom_widget' =>` switch, add three cases alongside the `doubling_mirror_*` ones:

```dart
      'halving_mirror_enaktiv' => HalvingMirrorEnaktivWidget(
          problem: problem,
          onValueChanged: onValueChanged,
        ),
      'halving_mirror_ikonisch' => HalvingMirrorIkonischWidget(
          problem: problem,
          onValueChanged: onValueChanged,
        ),
      'halving_mirror_symbolisch' => HalvingMirrorSymbolischWidget(
          problem: problem,
          onValueChanged: onValueChanged,
        ),
```

- [ ] **Step 10: Run flutter analyze to confirm the new widgets compile cleanly**

Run: `cd math_app && flutter analyze lib/widgets/templates/halving_mirror_enaktiv_widget.dart lib/widgets/templates/halving_mirror_ikonisch_widget.dart lib/widgets/templates/halving_mirror_symbolisch_widget.dart lib/practice/template_registry.dart lib/practice/problem_generators.dart lib/models/skill_spec.dart`
Expected: `No issues found!`

- [ ] **Step 11: Author the skill spec**

Create `docs/clean-room/v4/skills/specs/halve_zr10.json`:

```json
{
  "spec_version": 1,
  "skill_id": "halve_zr10",
  "construct_id": "halve",
  "domain": "C",
  "title_de": "Halbieren im ZR10",
  "level_titles_de": [
    "Halbieren mit Punkten",
    "Halbieren mit dem Spiegel",
    "Halbieren im Kopf"
  ],
  "levels": [
    {
      "level": 1,
      "representation": "enaktiv",
      "template": "custom_widget",
      "custom_widget": "halving_mirror_enaktiv",
      "params": { "count_range": [1, 5] },
      "problem_count": 8,
      "prompt_de": "Zähle die Punkte. Zieh die Hälfte auf die andere Seite.",
      "slow_band_ms": 12000
    },
    {
      "level": 2,
      "representation": "ikonisch",
      "template": "custom_widget",
      "custom_widget": "halving_mirror_ikonisch",
      "params": { "count_range": [1, 5] },
      "problem_count": 8,
      "prompt_de": "Zähle die Punkte. Drücke den Teilen-Knopf, um zu halbieren.",
      "slow_band_ms": 9000
    },
    {
      "level": 3,
      "representation": "symbolisch",
      "template": "custom_widget",
      "custom_widget": "halving_mirror_symbolisch",
      "params": { "count_range": [1, 5] },
      "problem_count": 8,
      "prompt_de": "Was ist die Hälfte?",
      "slow_band_ms": 6000
    }
  ],
  "mastery": { "correct_of": 8 },
  "error_taxonomy": [
    { "code": "off_by_one_low", "label_de": "eins zu wenig", "hint_de": "Ganz nah dran! Zähl noch einmal genau." },
    { "code": "off_by_one_high", "label_de": "eins zu viel", "hint_de": "Ganz nah dran! Zähl noch einmal genau." },
    { "code": "other", "label_de": "noch einmal probieren", "hint_de": "Schau dir die Punkte noch einmal an und probiere es noch einmal." }
  ],
  "provenance": {
    "sources": ["RLP BE/BB Teil C, L1, Niveaustufe A", "Padberg/Benz, Halbieren als Umkehrung des Verdoppelns", "Krajewski, Anzahlerfassung strukturierter Mengen", "Wartha/Schulz, Ablösung vom zählenden Rechnen"],
    "author": "Claude (domain author)",
    "reviewed_by": "open"
  }
}
```

- [ ] **Step 12: Sync and check coverage**

```bash
python scripts/sync_skill_specs.py
python scripts/check_skill_spec_coverage.py
```

Expected: sync reports `1 copied` (in addition to `double_zr10` from Task 4, now unchanged); coverage reports `covered: 2/93`, neither `double_zr10` nor `halve_zr10` in `missing`, `extra` stays empty.

- [ ] **Step 13: Extend the skill-spec store test**

Add to `math_app/test/skill_spec_store_test.dart`:

```dart
    test('halve_zr10 (Pilot B) parses with the new halving-mirror widgets',
        () {
      final store = SkillSpecStore.fromJsonMap(_loadRealSpecJsons());
      final spec = store.byId('halve_zr10');
      expect(spec.constructId, 'halve');
      expect(spec.domain, 'C');
      expect(spec.levels.map((l) => l.customWidget), [
        'halving_mirror_enaktiv',
        'halving_mirror_ikonisch',
        'halving_mirror_symbolisch',
      ]);
    });
```

- [ ] **Step 14: Run the full Dart test suite for this task**

Run: `cd math_app && flutter test test/skill_spec_store_test.dart test/problem_generators_test.dart`
Expected: PASS (all tests, including Pilot A's from Task 4)

- [ ] **Step 15: Commit**

```bash
git add docs/clean-room/v4/skills/specs/halve_zr10.json math_app/assets/skill_specs math_app/lib/models/skill_spec.dart math_app/lib/practice/problem_generators.dart math_app/lib/practice/template_registry.dart math_app/lib/widgets/templates/halving_mirror_enaktiv_widget.dart math_app/lib/widgets/templates/halving_mirror_ikonisch_widget.dart math_app/lib/widgets/templates/halving_mirror_symbolisch_widget.dart math_app/test/skill_spec_store_test.dart math_app/test/problem_generators_test.dart
git commit -m "feat: author halve_zr10 from scratch with new halving-mirror widgets"
```

---

## Task 6: Write the authoring guide the two pilots demonstrate

**Files:**
- Create: `docs/skill_spec_authoring_guide.md`

**Interfaces:**
- Consumes: nothing (documentation only).
- Produces: the checklist every follow-on plan (Task 7's batches) points to instead of re-deriving Tasks 1–5's discoveries.

- [ ] **Step 1: Write the guide**

Create `docs/skill_spec_authoring_guide.md`:

```markdown
# Authoring a v4 skill spec

How to turn one row of `math_app/Research/skills_taxonomy.csv` into a
playable exercise, following the pattern proven by `double_zr10` (Reused)
and `halve_zr10` (New — from scratch) in
`docs/superpowers/plans/2026-09-15-exercise-plan-foundation.md`.

Archetype tiers (from `docs/superpowers/specs/2026-09-15-exercise-plan-design.md`
§3) decide how much of this checklist you need:

- **Reused** / **Extended**: an old exercise or an already-shipped
  `custom_widget` covers the manipulative. Usually only steps 1 and 6 apply.
- **New — widget exists**: a non-exercise widget (e.g. `manipulatives/
  zahlenstrahl.dart`) needs wrapping as a `custom_widget`. Steps 1–6 apply,
  but step 3 ports from that widget instead of an old exercise.
- **New — from scratch**: nothing exists yet. All of steps 1–6 apply, as
  demonstrated end-to-end by `halve_zr10`.

## Steps

1. **Write the spec JSON** at
   `docs/clean-room/v4/skills/specs/<skill_id>.json`. `skill_id`,
   `construct_id`, `domain`, and `title_de` must exactly match the CSV row.
   Three levels (enaktiv, ikonisch, symbolisch), each with a `template` (one
   of the 16 known generic templates in `kKnownTemplates`,
   `math_app/lib/models/skill_spec.dart`) or `"custom_widget"` plus a
   `custom_widget` registry key. `error_taxonomy` needs at least the
   `"other"` fallback code every spec carries.

2. **Prefer a generic template over a new custom widget.** Check
   `kKnownTemplates` first — `equation_solve`, `equation_gap`,
   `sequence_gap`, `compare_symbols`, `numberline_locate`, `word_problem`
   and the rest cover a lot of ground without any new Dart code. `double_zr10`
   needed a custom widget only because the old `DoublingMirrorExercise`'s
   manipulative (a literal mirrored drag-and-drop) has no generic
   equivalent.

3. **If a custom widget is needed, port — don't refactor.** Copy the
   closest existing widget under `math_app/lib/widgets/templates/` (an old
   `custom_widget`, or — for "widget exists" tier — the reusable
   manipulative it's based on) into a fresh file with the adapted
   `({required Problem problem, required ValueChanged<String>
   onValueChanged})` contract. Leave the source untouched; this is a copy,
   not a shared refactor (see the doc comment on every
   `doubling_mirror_*_widget.dart` file for the reasoning: independent files
   are easier to reason about and to safely diverge later than a shared base
   class would be).

4. **Register the new widget in four places** (skip any that already exist
   for a Reused/Extended tier):
   - `kKnownCustomWidgets` in `math_app/lib/models/skill_spec.dart`.
   - A generator function in `math_app/lib/practice/problem_generators.dart`,
     wired into `_generateCustomWidget`'s switch. Reuse `SeededGenerator`'s
     existing helpers (`nextIntInRange`, etc.) — do not hand-roll randomness.
   - A widget-building case in
     `math_app/lib/practice/template_registry.dart`'s `'custom_widget' =>`
     switch.
   - Only if the answer is not a plain string match against
     `problem.expected`: a case in
     `math_app/lib/practice/template_evaluator.dart`'s
     `_evaluateCustomWidget`. Most manipulatives (including both
     doubling-mirror and halving-mirror) don't need this — the default
     branch already does a plain match.

5. **Write tests before syncing**, mirroring the existing `custom_widget
   generators` group in `math_app/test/problem_generators_test.dart`: one
   test per generator asserting the display/expected shape over many seeds,
   plus a `flutter analyze` pass on every new/changed file.

6. **Sync and check coverage**:

       python scripts/sync_skill_specs.py
       python scripts/check_skill_spec_coverage.py

   The skill must move from `missing` to covered, and `extra` must stay
   empty (a leftover file with a stale `skill_id` is a mistake, not
   progress).

## What NOT to do

- Never hand-edit a file under `math_app/assets/skill_specs/` — it's
  generated. Edit the source under `docs/clean-room/v4/skills/specs/` and
  re-sync.
- Never target the retired v1 policy in `scripts/check_specs.py` — that
  script and its `docs/clean-room/skills/specs` tree are archived
  (`docs/archive/skill_specs_pre_v4/`). v4 specs are validated by
  `SkillSpec.fromJson`/`SkillSpecStore.validateAll` plus the coverage
  checker.
- Don't invent a `problem_count` or `slow_band_ms` value ad hoc — follow
  `DIFFICULTY_CURVE.md`'s guidance for the skill's construct family.
```

- [ ] **Step 2: Commit**

```bash
git add docs/skill_spec_authoring_guide.md
git commit -m "docs: write the v4 skill-spec authoring guide"
```

---

## Task 7: Turn the remaining 91 skills into an ordered, trackable build order

**Files:**
- Create: `docs/clean-room/v4/skills/BUILD_ORDER.md`

**Interfaces:**
- Consumes: `docs/superpowers/specs/2026-09-15-exercise-plan-design.md` §5 (the per-skill archetype/manipulative/level detail for all 93 skills) and its §3 coverage tally (30 Reused / 31 Extended / 11 New-widget-exists / 21 New-from-scratch).
- Produces: the backlog each follow-on plan slices a batch from, and the checklist `scripts/check_skill_spec_coverage.py`'s `missing` output should be checked against after every batch.

- [ ] **Step 1: Write the build order**

Create `docs/clean-room/v4/skills/BUILD_ORDER.md` listing all 93 skills from
`math_app/Research/skills_taxonomy.csv`, grouped into batches in this order:
Reused first (cheapest — an id/field retarget like Task 4), then Extended,
then New-widget-exists, then New-from-scratch — and within each tier,
grouped by `construct_id` so sibling skills that share a manipulative (e.g.
all 6 `double_*` skills, all 6 `halve_*` skills) are built back-to-back by
the same follow-on plan instead of re-deriving the same widget twice. Mark
`double_zr10` and `halve_zr10` done, with a link back to this plan. Use
`docs/superpowers/specs/2026-09-15-exercise-plan-design.md` §5 as the source
for each skill's archetype status and manipulative — do not re-derive it.

Structure — the `double`/`halve` batch below is a fully worked example (not
a placeholder): it is every remaining skill in those two construct families,
pulled directly from `math_app/Research/skills_taxonomy.csv`, tagged with
its archetype tier from the design doc §5. Every other tier/batch in the
file must be filled in to the same level of completeness — one line per
skill, no family left as "...".

```markdown
# v4 skill-spec build order

91 of 93 skills remain (`double_zr10`, `halve_zr10` shipped —
`docs/superpowers/plans/2026-09-15-exercise-plan-foundation.md`). Run
`python scripts/check_skill_spec_coverage.py` for live status; this file is
the *order* to close the gap in, not the live status itself.

Each batch below is sized for one follow-on plan (`writing-plans`, using
`docs/skill_spec_authoring_guide.md`'s checklist). Batches are grouped by
`construct_id` within each archetype tier so sibling skills sharing a
manipulative are authored together.

## Tier 1: Reused (29 remaining of 30)

### Batch 1.1 — counting quantities (construct `quantify_count`)
- [ ] `quantify_count_zr10` — Reused from C1.1 `CountDotsExerciseV2` (shipped, see Done)
- [ ] `quantify_count_zr20` — Reused from C1.2 `CountObjectsExercise`
      (continue with every remaining Reused-tier skill in Domain A's
      counting families, per design doc §5, one line per skill)

### Batch 1.2 — [next Reused-tier construct family per design doc §5]
      (one line per skill, same shape as Batch 1.1)

      ... (continue until every Reused-tier skill from design doc §5 is
      placed in exactly one batch — 30 skills total across Tier 1)

## Tier 2: Extended (31)

### Batch 2.1 — doubling (construct `double`)
- [x] `double_zr10` — shipped, Task 4 of this plan (Extended tier per design
      doc §3, though this instance was a direct id retarget)
- [ ] `double_zr10_to_zr20` — Extended from S3.1/S3.2 `DoublingMirrorExercise`
      (widen `count_range` past today's [1,5]/[6,10] split)
- [ ] `double_crossing_10` — Extended from the same doubling-mirror widgets
      (range chosen so doubling crosses a ten)
- [ ] `double_decade` — Extended from S3.6 `DoublingTensExercise`
- [ ] `double_2digit_nocarry` — Extended from S3.6/S3.7 `TensCalculationExercise`
- [ ] `double_2digit_with_carry` — Extended from the same, plus a carry step

### Batch 2.2 — halving (construct `halve`)
- [x] `halve_zr10` — shipped, Task 5 of this plan (New — from scratch;
      the halving-mirror widgets this batch reuses)
- [ ] `halve_zr20_anchor` — Extended from the new halving-mirror widgets
      (Task 5), anchored at 10 (e.g. halve 12 via 10+2 -> 5+1)
- [ ] `halve_zr20_crossing` — Extended from the same widgets, values needing
      a Bündelwechsel
- [ ] `halve_decade` — Extended from the same widgets, decade values (20, 40, ...)
- [ ] `halve_2digit_clean` — Extended from the same widgets, even 2-digit values
- [ ] `halve_2digit_needs_decomposition` — Extended from the same widgets,
      values needing an explicit tens/ones split (this is the specific gap
      flagged in `docs/clean-room/00-v1-assessment.md`)

### Batch 2.3 — [next Extended-tier construct family per design doc §5]
      (one line per skill, same shape as Batch 2.1/2.2)

      ... (continue until every Extended-tier skill from design doc §5 is
      placed in exactly one batch — 31 skills total across Tier 2, minus
      `double_zr10` already shipped)

## Tier 3: New — widget exists (11)

### Batch 3.1 — [first New-widget-exists construct family per design doc §5,
      e.g. Domain B's number-line skills reusing `number_line_endpoints_widget.dart`]
      (one line per skill, same shape as Tier 1/2 batches)

      ... (continue until every New-widget-exists skill from design doc §5
      is placed in exactly one batch — 11 skills total across Tier 3)

## Tier 4: New — from scratch (19 remaining of 21)

### Batch 4.1 — cross-decade arithmetic (construct `cross_decade_add`,
      `cross_decade_sub`)
      (one line per skill — 4 skills per design doc §5 Domain C)

### Batch 4.2 — reasoning skills (equation equivalence, commutativity,
      even/odd, calculation triangle, per design doc §5 Domain C)
      (one line per skill)

### Batch 4.3 — word problems (construct `operation_sense`, Domain D)
      (one line per skill — 3 skills, all reusing `word_problem_widget.dart`
      per design doc §5, so arguably could move to Tier 3 — resolve this
      classification when writing the batch, and note the correction here)

      ... (continue until every New-from-scratch skill from design doc §5
      is placed in exactly one batch — 21 skills total across Tier 4, minus
      `halve_zr10` already shipped)

## Done
- [x] `double_zr10` — Task 4, `docs/superpowers/plans/2026-09-15-exercise-plan-foundation.md`
- [x] `halve_zr10` — Task 5, `docs/superpowers/plans/2026-09-15-exercise-plan-foundation.md`
```

Populate every remaining batch to the same level of completeness as Batch
2.1/2.2 above — walk `math_app/Research/skills_taxonomy.csv` alongside the
design doc's §5 domain-by-domain sections and place each of the remaining
91 skills into exactly one batch, grouped by `construct_id`, within its
correct tier. Every skill must appear exactly once across the whole file;
Step 2 below checks this mechanically.

- [ ] **Step 2: Verify completeness against the taxonomy**

Run this check (adapt to your shell) to confirm every one of the 93 CSV skill ids appears in the new file exactly once, and that the two shipped ones are marked done:

```bash
python3 - <<'PY'
import csv, re, pathlib

csv_path = pathlib.Path("math_app/Research/skills_taxonomy.csv")
build_order = pathlib.Path("docs/clean-room/v4/skills/BUILD_ORDER.md").read_text(encoding="utf-8")

with csv_path.open(encoding="utf-8", newline="") as f:
    ids = [row["skill_id"] for row in csv.DictReader(f)]

missing = [i for i in ids if not re.search(rf"`{re.escape(i)}`", build_order)]
dupes = [i for i in ids if len(re.findall(rf"`{re.escape(i)}`", build_order)) > 1]

print(f"{len(ids)} taxonomy skills, {len(missing)} missing from BUILD_ORDER.md, {len(dupes)} duplicated")
if missing:
    print("missing:", missing)
if dupes:
    print("duplicated:", dupes)
PY
```

Expected: `93 taxonomy skills, 0 missing from BUILD_ORDER.md, 0 duplicated`.

- [ ] **Step 3: Commit**

```bash
git add docs/clean-room/v4/skills/BUILD_ORDER.md
git commit -m "docs: order the remaining 91 skills into a trackable build backlog"
```

---

## Scope note: what this plan does not do

This plan makes the pipeline work end-to-end and proves the authoring
pattern on 2 of 93 skills. It deliberately does **not** write the remaining
91 skills' specs and widgets — at roughly the size of Tasks 4–5 each, that
would make this single plan document unreviewable. Each batch in Task 7's
`BUILD_ORDER.md` is scoped to become its own follow-on plan, written with
`writing-plans` against `docs/skill_spec_authoring_guide.md` and the design
doc's §5, and executed the same way this one is.
