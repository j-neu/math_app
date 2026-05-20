# Documentation Index

One stop for every `.md` file in this repo. Read this first; jump from here.

**Legend:** ⭐ start here · 🟢 current & reliable · 🟡 partly stale, verify before trusting · 🔴 historical / archived · ⚪ boilerplate, skip

---

## ⭐ Start here

- [README.md](README.md) — 🟡 Project overview, status, doc map. Has duplicate info with GEMINI.md and some now-stale claims (e.g. "6 skills, 5%" — practice work has moved on).
- [GEMINI.md](GEMINI.md) — 🟡 Main project guide: quick-start commands, card-based scaffolding rules, skill creation checklist, common bugs. Long, partly duplicated by README. Was written for the Gemini CLI but is the most complete single overview.
- [TERMINOLOGY.md](TERMINOLOGY.md) — 🟢 Defines Skill / Level / Problem hierarchy. Read once and you'll stop being confused by "exercise" vs "skill".
- [tasks.md](tasks.md) — 🟡 Roadmap and current work. Some items marked done that aren't (e.g. `DiagnosticReportGenerator`). Treat as aspirational, not authoritative.
- [phase0_tasks.md](phase0_tasks.md) — 🟢 The immediate plan: Diagnostic → Förderplan MVP. This is the active work plan.
- [phase0.5_german_pivot.md](phase0.5_german_pivot.md) — 🟢 Full German UI pivot — kills last English strings (start screen, settings, exercise chrome, app title). Must complete before any pilot exposure.
- [phase1_school_platform.md](phase1_school_platform.md) — 🟢 Strategic plan for what comes *after* phase0: pivot from local Flutter to a school SaaS (Flutter Web kids + Next.js dashboard + Supabase EU). Not for execution yet.

## Planning & roadmap

- [phase0_tasks.md](phase0_tasks.md) — 🟢 Active build plan for the diagnostic report system.
- [phase0.5_german_pivot.md](phase0.5_german_pivot.md) — 🟢 German-language pivot plan. Sits between phase0 and phase1; blocks pilot.
- [phase1_school_platform.md](phase1_school_platform.md) — 🟢 Strategic plan for the school-SaaS pivot after phase0 ships. Not execution-ready.
- [practice_skill_plan.md](practice_skill_plan.md) — 🟢 Deferred plan for a Claude Code Skill that automates practice-exercise creation. Includes the three blockers that must clear first.

## Diagnostic / Förderplan

- [phase0_tasks.md](phase0_tasks.md) — 🟢 Active build plan for the diagnostic report system.
- [math_app/Research/MathApp_Diagnostic_with_skills.csv](math_app/Research/MathApp_Diagnostic_with_skills.csv) — 🟢 (CSV) The 59 diagnostic questions and their `IfWrong_practice_skills` mappings. Source of truth for what the diagnostic asks.

## Pedagogical framework (practice exercises)

- [IMINT_TO_APP_FRAMEWORK.md](IMINT_TO_APP_FRAMEWORK.md) — 🟢 How to translate an iMINT/PIKAS card into app levels. The "cards define the scaffolding, not a 3-level template" rule lives here.
- [DIFFICULTY_CURVE.md](DIFFICULTY_CURVE.md) — 🟢 Easy→Hard→Easy progression spec. Trivial(P1-2) → Easy(P3-4) → Medium(P5-6) → Hard(P7-8) → Medium(P9) → Easy(P10).
- [COMPLETION_CRITERIA.md](COMPLETION_CRITERIA.md) — 🟢 "Finished" vs "Completed" status definitions, time limits per skill type, scoring rules.
- [EXERCISE_DESIGN_SYSTEM.md](EXERCISE_DESIGN_SYSTEM.md) — 🟢 Visual design spec: minimalist AppBar, segmented progress bar, instruction modals, level drawer. UI contract for all skill screens.
- [COMMON_PITFALLS.md](COMMON_PITFALLS.md) — 🟢 Concrete bug recipes seen during development: enum misuse, `ExerciseProgressMixin` requirements, Android black background, level-completion hangs, etc.
- [adhd guidelines.md](adhd%20guidelines.md) — 🟢 Seven design principles from ADHD research (concrete/visual, short sessions, immediate feedback, no-fail, etc.). Underpins every UI decision.

## Reward system

- [REWARDS_SYSTEM_QUICK_REF.md](REWARDS_SYSTEM_QUICK_REF.md) — 🟢 One-page summary of the three reward triggers, model fields, service API.
- [Research/REWARDS_SYSTEM.md](Research/REWARDS_SYSTEM.md) — 🟢 Full reward-system spec: trigger types, parent-config UX, celebration modal copy, milestone definitions. The detailed version of the quick-ref above.

## Skill taxonomy & research source material

- [Research/Research/SKILLS_README.md](Research/Research/SKILLS_README.md) — 🟢 Explains the 88-skill `category_number` ID system (76 iMINT + 12 PIKAS), why the renaming was done, what each color category covers.
- [Research/Research/skills_taxonomy.csv](Research/Research/skills_taxonomy.csv) — 🟢 (CSV) The full skill catalog: id, category, color, card #, German title, English title, German one-line description, English one-line description. The single source of truth for skill metadata.
- [Research/Research/PIKAS_Analysis.md](Research/Research/PIKAS_Analysis.md) — 🟡 Card-by-card analysis of PIKAS FÖDIMA cards (36/58 done). Reference for later PIKAS integration; not needed for the MVP.

## Archive (historical, do not edit, may contradict current state)

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

---

## Known contradictions to be aware of

- `tasks.md` marks `DiagnosticReportGenerator` and `DiagnosticReportScreen` as done — they are not. See `phase0_tasks.md`.
- `Archive/C1.1_FINALE_PATTERN.md` prescribes a finale level; `IMINT_TO_APP_FRAMEWORK.md` (current) says no finale. New skills follow the framework, not the archive doc.
- README.md and GEMINI.md duplicate large sections and disagree on current skill count.
- `EXERCISE_DESIGN_SYSTEM.md` uses "exercise" while `TERMINOLOGY.md` says use "skill" — `EXERCISE_DESIGN_SYSTEM.md` calls this out at the top but the body still uses the old word.

When in doubt, prefer in this order: `phase0_tasks.md` > `TERMINOLOGY.md` > `IMINT_TO_APP_FRAMEWORK.md` > `GEMINI.md` > rest.
