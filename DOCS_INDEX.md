# Documentation Index

One stop for every `.md` file in this repo. Read this first; jump from here.

**Legend:** ⭐ start here · 🟢 current & reliable · 🟡 paused or partly stale (verify before trusting) · 🔴 historical / archived · ⚪ boilerplate, skip

---

## ⭐ Start here

- [README.md](README.md) — 🟢 One-page project overview + pointers. The elevator pitch.
- [STATUS.md](STATUS.md) — 🟢 What's shipped / active / paused right now. The headline status doc.
- [phase1_school_platform.md](phase1_school_platform.md) — 🟢 Active build plan: backend, dashboard, Flutter web, pilot.
- [phase1.1_fixes.md](phase1.1_fixes.md) — 🟢 Phase 1.1: 11 diagnostic & dashboard fixes — all deployed 2026-05-23.
- [TERMINOLOGY.md](TERMINOLOGY.md) — 🟢 Defines Skill / Level / Problem hierarchy. Read once and "exercise" vs "skill" stops being confusing.

## Diagnostic / Förderplan

- [math_app/Research/MathApp_Diagnostic_with_skills.csv](math_app/Research/MathApp_Diagnostic_with_skills.csv) — 🟢 (CSV) iMINT diagnostic, 98 questions, with `IfWrong_practice_skills` mappings. Source of truth.
- [math_app/Research/MathApp_Diagnostic_Schulz.csv](math_app/Research/MathApp_Diagnostic_Schulz.csv) — 🟢 (CSV) Schulz/Wartha diagnostic, 151 questions, 8 blocks. Source of truth.
- (Two diagnostics must never be mixed in reports. The platform stores the diagnostic source on the session.)

## Skill taxonomy & research source material

- [math_app/Research/Research/SKILLS_README.md](math_app/Research/Research/SKILLS_README.md) — 🟢 Explains the 88-skill `category_number` ID system (76 iMINT + 12 PIKAS).
- [math_app/Research/Research/skills_taxonomy.csv](math_app/Research/Research/skills_taxonomy.csv) — 🟢 (CSV) Full skill catalog: id, category, color, card #, German title, English title, German one-line description, English one-line description.
- [math_app/Research/Research/PIKAS_Analysis.md](math_app/Research/Research/PIKAS_Analysis.md) — 🟡 Card-by-card analysis of PIKAS FÖDIMA cards (36/58 done). Reference for later PIKAS integration.

## Paused — practice-exercise engine

The eight practice skills already in code stay shipped. No new skills planned until pilot ships. These framework docs are kept in case practice work resumes:

- [IMINT_TO_APP_FRAMEWORK.md](IMINT_TO_APP_FRAMEWORK.md) — 🟡 How to translate an iMINT/PIKAS card into app levels. "Cards define the scaffolding, not a 3-level template."
- [DIFFICULTY_CURVE.md](DIFFICULTY_CURVE.md) — 🟡 Easy→Hard→Easy progression spec.
- [COMPLETION_CRITERIA.md](COMPLETION_CRITERIA.md) — 🟡 "Finished" vs "Completed" status definitions, time limits per skill type, scoring rules.
- [EXERCISE_DESIGN_SYSTEM.md](EXERCISE_DESIGN_SYSTEM.md) — 🟡 Visual design spec for skill screens. (Body still uses "exercise" — `TERMINOLOGY.md` is authoritative.)
- [COMMON_PITFALLS.md](COMMON_PITFALLS.md) — 🟡 Concrete bug recipes seen during practice-skill development.
- [adhd guidelines.md](adhd%20guidelines.md) — 🟢 Seven design principles from ADHD research. Underpins both diagnostic and practice UI decisions — still in force.
- [REWARDS_SYSTEM_QUICK_REF.md](REWARDS_SYSTEM_QUICK_REF.md) — 🟡 One-page summary of the three reward triggers.
- [math_app/Research/REWARDS_SYSTEM.md](math_app/Research/REWARDS_SYSTEM.md) — 🟡 Full reward-system spec.
- [practice_skill_plan.md](practice_skill_plan.md) — 🟡 Deferred plan for a Claude Code Skill that automates practice-exercise creation. Three blockers listed.

## Archive (historical, do not edit, may contradict current state)

- [Archive/phase0_tasks.md](Archive/phase0_tasks.md) — 🔴 Phase 0 (Diagnostic → Förderplan MVP) plan. Shipped 2026-05-15.
- [Archive/phase0.5_german_pivot.md](Archive/phase0.5_german_pivot.md) — 🔴 Full German UI pivot. Shipped.
- [Archive/replace_diagnostic_images.md](Archive/replace_diagnostic_images.md) — 🔴 One-off task list: replace diagnostic photos with generated Flutter widgets. Done.
- [Archive/tasks_2026-05.md](Archive/tasks_2026-05.md) — 🔴 Pre-cleanup `tasks.md` snapshot — Phase 2 widget library, Phase 2.5 QA, Phase 4 Diagnostic status (now in STATUS.md).
- [Archive/COMPLETED_TASKS.md](Archive/COMPLETED_TASKS.md) — 🔴 Brief history of Phase 1 & 1.5 work.
- [Archive/COMPLETED_TASKS_PHASE2.md](Archive/COMPLETED_TASKS_PHASE2.md) — 🔴 Phase 2 (skill engine) progress snapshot.
- [Archive/ARCHIVE_IMPLEMENTATIONS.md](Archive/ARCHIVE_IMPLEMENTATIONS.md) — 🔴 Implementation notes for Z1 (Decompose 10) as a reference example.
- [Archive/C1.1_FINALE_PATTERN.md](Archive/C1.1_FINALE_PATTERN.md) — 🔴 Mixed-review finale pattern from skill C1.1. **Note:** newer guidance in IMINT_TO_APP_FRAMEWORK.md now says *no* artificial finale level — this archive doc contradicts current direction.
- [Archive/LEVEL5_COMPLETION_FIX.md](Archive/LEVEL5_COMPLETION_FIX.md) — 🔴 Postmortem of a specific bug in C1.1 Level 5.
- [Archive/tasks_full.md](Archive/tasks_full.md) — 🔴 Older long-form task list (2025-11-01).
- [Archive/tasks_old.md](Archive/tasks_old.md) — 🔴 Earlier task list snapshot (2025-11-19).

## Boilerplate / generated

- [math_app/README.md](math_app/README.md) — ⚪ Default Flutter project README. Skip.
- [math_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md](math_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md) — ⚪ Xcode launch-image asset readme. Skip.
- [dashboard/README.md](dashboard/README.md) — ⚪ Default Next.js project README. Skip.

---

## Known contradictions to be aware of

- `Archive/C1.1_FINALE_PATTERN.md` prescribes a finale level; `IMINT_TO_APP_FRAMEWORK.md` (current) says no finale. New practice skills, if/when work resumes, follow the framework, not the archive doc.
- `EXERCISE_DESIGN_SYSTEM.md` uses "exercise" while `TERMINOLOGY.md` says use "skill" — `EXERCISE_DESIGN_SYSTEM.md` calls this out at the top but the body still uses the old word.

When in doubt, prefer in this order: `STATUS.md` > `phase1_school_platform.md` > `TERMINOLOGY.md` > `IMINT_TO_APP_FRAMEWORK.md` > rest.
