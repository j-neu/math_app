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
   `"other"` fallback code every spec carries. Only use codes
   `TemplateEvaluator._candidateErrorCode`
   (`math_app/lib/practice/template_evaluator.dart`) can actually emit —
   for an off-by-one numeric answer that is the single undirected
   `"miscount"`, not a directional code like `"off_by_one_low"` /
   `"off_by_one_high"`, which no spec's answer can ever trigger
   (`double_zr10`/`halve_zr10` shipped with exactly this mistake and had
   to be fixed after the fact).

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
