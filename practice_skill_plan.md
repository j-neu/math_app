# Practice-Exercise Skill: Plan for a Claude Code Skill

**Status:** Deferred. Do not build yet.
**Trigger to revisit:** After Phase 0 (Diagnostic/Förderplan) ships AND the missing widget primitives exist.
**Created:** 2026-05-14

---

## Context

Each practice skill (C1.1, Z1, S3.4, etc.) currently costs ~1 day of Claude+human time. A large fraction of that day is spent re-deriving conventions already written down in `IMINT_TO_APP_FRAMEWORK.md`, `COMMON_PITFALLS.md`, `DIFFICULTY_CURVE.md`, and `COMPLETION_CRITERIA.md` — and hitting the same dual-registration / Android-black-background / `ExerciseProgressMixin` traps every time.

A Claude Code Skill is the right shape for this kind of repeatable, multi-doc workflow: progressive disclosure (load the workflow on demand, pull heavy docs only when the active step needs them), captured guardrails, and a slash-command entry point. Realistic target with a good skill: ~4–6 hours per practice skill instead of ~1 day. Skill-heavy interactions and bespoke manipulatives will still cost real time — the savings come from the boilerplate and the pitfalls.

---

## Why not now — three blockers

1. **Canonical pattern not settled.** Z1 has a finale level; `IMINT_TO_APP_FRAMEWORK.md` (current) says no finale ever; `Archive/C1.1_FINALE_PATTERN.md` prescribes one. A skill built today would encode a contradiction. Pick one, retrofit or grandfather the others, then encode.

2. **Widget primitives missing.** `Archive/tasks_2026-05.md` lists `DienesBlocksWidget`, `RechenschiffchenWidget` (partial), `HundredChartWidget`, `FlashCardWidget`, `WendeplättchenWidget` as critical for Sets 2-4 and absent today. A skill that "creates an exercise" hits a wall the moment the required manipulative doesn't exist — turning into a frustration amplifier that runs 80% then dies. Build the widget catalog first; have the skill assume "pick from this list."

3. **Wrong phase.** Phase 0 (Diagnostic) is the MVP. Tooling for deferred work is premature.

---

## Ordering

| Phase | Step | Done before this skill is built? |
|---|---|---|
| Phase 0 | Ship diagnostic + Förderplan | Required |
| Phase 0.5a | Decide finale question definitively (one sentence in `IMINT_TO_APP_FRAMEWORK.md`); retrofit or document legacy implementations | Required |
| Phase 0.5b | Build missing widget primitives (Dienes, Rechenschiffchen, Hundertertafel, Flashcard, Wendeplättchen) | Required |
| Phase 1 | Create the practice-skill Claude Skill | **This document's subject** |
| Phase 1+ | Use the skill to crank out the remaining ~110 practice skills | Goal |

---

## What the skill should do — workflow, not code generator

**Entry point:** a slash command, e.g. `/new-practice-skill S1.3 imint-card-7`.

**Inputs:** skill ID + iMINT/PIKAS card reference.

**Steps:**

1. **Read the card** — open the relevant file under `Research/Research/iMINT_Kartei_extracted-pages/`. Extract the "Wie kommt die Handlung in den Kopf?" section. Output: a numbered list of N levels with the specific action per level (drag / tap / no-action / flash-hide / mirror / etc.). N is whatever the card prescribes — not a template.

2. **Check widget primitives** — match each level's required interaction to the existing widget catalog. If anything is missing, **stop** and report which widgets need to be built. Do not attempt to fake or inline a missing manipulative.

3. **Plan the skill** — produce a short markdown plan: levels, problems per level, difficulty curve (from `DIFFICULTY_CURVE.md`), completion criteria (from `COMPLETION_CRITERIA.md`), tracked skill tags. Confirm with the user before writing code.

4. **Scaffold files** — create:
   - `math_app/lib/exercises/<skill>_exercise.dart` (coordinator)
   - `math_app/lib/widgets/<skill>_level{1..N}_widget.dart` (level widgets)
   Use the smallest possible template — *not* a copy-paste of a previous skill.

5. **Wire `ExerciseProgressMixin` correctly** — encode the four traps from `COMMON_PITFALLS.md` §2–3 as preconditions: override `exerciseId`, `userProfile`, `problemTimeLimit`, `finaleMinProblems`; call `initializeProgress()`; use `isLevelUnlocked()` not a local map; pass `correct:` to `recordProblemResult` not `isCorrect:`.

6. **Register in two places** — `ExerciseService._allExercises` AND the relevant `Milestone.exerciseIds` (pitfall #7). The skill must not exit without both registrations done.

7. **Apply the difficulty curve** — for each level, generate the Trivial→Easy→Medium→Hard→Medium→Easy problem function from `DIFFICULTY_CURVE.md`, parameterized by whichever quantity drives difficulty for this skill.

8. **`flutter analyze`** — must return clean. If not, fix before reporting done.

9. **Report** — what was created, what's left for the human (UI polish, pedagogical review, manual playtest on Android).

**What it must NOT do**

- Generate code from a fixed N-level template. The cards demand bespoke interaction logic — drag, tap, flash-hide, mirror, etc. The skill's value is the *workflow guardrails*, not boilerplate generation.
- Add a finale level by default. Whatever the canonical decision turns out to be in Phase 0.5a, the skill obeys it.
- Skip the manual playtest step. UI/feature correctness is not validated by `flutter analyze`; the skill should explicitly say "human must play this on an Android device before marking done" — quoting `CLAUDE.md`'s rule on UI changes.

---

## Implementation hint

You already have `taches-cc-resources:create-subagents`, `taches-cc-resources:create-slash-commands`, and `taches-cc-resources:audit-subagent` available. The right structure is:

- A `SKILL.md` file under `.claude/skills/` (or wherever the project standard lands) with frontmatter describing the trigger phrases
- Supporting files referenced via progressive disclosure: `IMINT_TO_APP_FRAMEWORK.md`, `COMMON_PITFALLS.md`, `DIFFICULTY_CURVE.md`, `COMPLETION_CRITERIA.md`
- A short slash command (`/new-practice-skill`) that invokes the skill with skill-ID + card-ID arguments

Use the `audit-skill` subagent on the result before relying on it.

---

## Open questions for when this is built

- Does the skill also handle `EXERCISE_DESIGN_SYSTEM.md` UI compliance (segmented progress bar, collapsible instructions, level drawer), or is that a separate pass?
- Should the skill auto-write a stub test under `math_app/test/` for each new skill, or is the manual playtest considered sufficient?
- How does the skill handle bilingual content — German first, English later, or both up front?
- What level of pedagogical judgment is delegated to Claude vs. always escalated to the user? E.g., if the card prescribes a step that contradicts ADHD guidelines, who decides?
