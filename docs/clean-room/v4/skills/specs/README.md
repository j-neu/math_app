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
