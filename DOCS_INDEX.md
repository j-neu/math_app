# Documentation Index

One stop for every `.md` file in this repo. Read this first; jump from here.

**Legend:** ⭐ start here · 🟢 current & reliable · 🟡 paused or partly stale (verify before trusting) · 🔴 historical / archived · ⚪ boilerplate, skip

---

## ⭐ Start here

- [tasks.md](tasks.md) — 🟢 **ACTIVE, highest priority.** Clean-room rewrite task list. Blocks all commercial activity.
- [rewrite.md](rewrite.md) — 🟢 The legal reasoning behind the clean-room rewrite. `tasks.md` is the execution plan for it.
- [README.md](README.md) — 🟢 One-page project overview + pointers. The elevator pitch.
- [STATUS.md](STATUS.md) — 🟢 What's shipped / active / paused right now. The headline status doc.
- [phase1_school_platform.md](phase1_school_platform.md) — 🟢 Active build plan: backend, dashboard, Flutter web, pilot.
- [phase1.1_fixes.md](phase1.1_fixes.md) — 🟢 Phase 1.1: 11 diagnostic & dashboard fixes — all deployed 2026-05-23.
- [TERMINOLOGY.md](TERMINOLOGY.md) — 🟢 Defines Skill / Level / Problem hierarchy. Read once and "exercise" vs "skill" stops being confusing.

## Diagnostic / Förderplan

- [math_app/Research/MathApp_Diagnostic_with_skills.csv](math_app/Research/MathApp_Diagnostic_with_skills.csv) — 🟡 (CSV) The 92-question diagnostic the app currently runs on. iMINT-derived — **being replaced** by the clean-room item bank (`tasks.md` R5.1). Still the runtime source of truth until then.
- The Schulz/Wartha CSV (151 questions, CC BY-ND) was **dropped from product scope** 2026-08-29 and moved to `_sources_private/` — see `tasks.md` R0.6.

## Skill taxonomy & research source material

- [math_app/Research/skills_taxonomy.csv](math_app/Research/skills_taxonomy.csv) — 🟡 (CSV) The 88-skill catalog currently in use. iMINT/PIKAS-derived — **being replaced** by ~35 skills on a new ID scheme (`tasks.md` R3).
- `SKILLS_README.md` (the `category_number` ID system) and `PIKAS_Analysis.md` (card-by-card FÖDIMA analysis) were moved to `_sources_private/legacy-notes/` on 2026-08-29 — they document the old derivation approach and must not seed the new one.

## Paused — practice-exercise engine

The eight practice skills already in code stay shipped. No new skills planned until pilot ships. These framework docs are kept in case practice work resumes:

- `IMINT_TO_APP_FRAMEWORK.md` — 🔴 **Archived** to `_sources_private/legacy-notes/` on 2026-08-29. It described translating protected cards into app levels; `rewrite.md` §2 lists it as coming out. Replaced by the construct map (`tasks.md` R1.3).
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
- [Archive/C1.1_FINALE_PATTERN.md](Archive/C1.1_FINALE_PATTERN.md) — 🔴 Mixed-review finale pattern from skill C1.1. Moot: the practice engine is paused and out of commercial scope pending `tasks.md` R8.1.
- [Archive/LEVEL5_COMPLETION_FIX.md](Archive/LEVEL5_COMPLETION_FIX.md) — 🔴 Postmortem of a specific bug in C1.1 Level 5.
- [Archive/tasks_full.md](Archive/tasks_full.md) — 🔴 Older long-form task list (2025-11-01).
- [Archive/tasks_old.md](Archive/tasks_old.md) — 🔴 Earlier task list snapshot (2025-11-19).

## Boilerplate / generated

- [math_app/README.md](math_app/README.md) — ⚪ Default Flutter project README. Skip.
- [math_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md](math_app/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md) — ⚪ Xcode launch-image asset readme. Skip.
- [dashboard/README.md](dashboard/README.md) — ⚪ Default Next.js project README. Skip.

---

## Known contradictions to be aware of

- `Archive/C1.1_FINALE_PATTERN.md` prescribes a finale level; the archived framework doc said no finale. Moot until the practice engine is triaged (`tasks.md` R8.1).
- `EXERCISE_DESIGN_SYSTEM.md` uses "exercise" while `TERMINOLOGY.md` says use "skill" — `EXERCISE_DESIGN_SYSTEM.md` calls this out at the top but the body still uses the old word.

When in doubt, prefer in this order: `tasks.md` > `rewrite.md` > `STATUS.md` > `phase1_school_platform.md` > `TERMINOLOGY.md` > rest.

**Note (2026-08-29):** `phase1_school_platform.md` and `STATUS.md` describe the platform as pilot-ready and heading for pricing. That is superseded by `tasks.md` — the diagnostic content is being rebuilt clean-room and the product is non-commercial until that completes. The *infrastructure* status in those docs is still accurate; the *content* and *commercial* status is not.
