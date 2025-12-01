# Math App Terminology Guide

**Last Updated:** 2025-11-23
**Purpose:** Clarify terminology to avoid confusion between skills, levels, and problems

---

## Quick Reference

| Term | Meaning | Example | File Location |
|------|---------|---------|---------------|
| **Skill** | Complete learning module with multiple levels | C1.1 "Count the Dots" | `exercises/count_dots_exercise_v2.dart` |
| **Level** | Scaffolding stage within a skill | Level 2: "Tap to Count" | `widgets/countdots_level2_widget_v2.dart` |
| **Problem** | Individual question within a level | "Count these 7 dots" | Generated within level widget |
| **Exercise** | AMBIGUOUS - avoid in discussion | Use "Skill" instead | Used in code (legacy) |

---

## The Hierarchy

```
Skill C1.1: "Count the Dots"                    ← The complete learning module
├── Level 1: Drag dots (10 problems)            ← Scaffolding stage
│   ├── Problem 1: Count 5 dots                 ← Individual question
│   ├── Problem 2: Count 8 dots
│   ├── Problem 3: Count 12 dots
│   └── ... (10 problems total)
├── Level 2: Tap dots (10 problems)
├── Level 3: Look-only (10 problems)
├── Level 4: Flash-hide (10 problems)
└── Level 5: Finale (10 problems, easier)

Total: 1 skill, 5 levels, 50 problems
```

---

## Why This Matters

### The Confusion

Previously, we were saying things like:
- "Exercise C1.1" (ambiguous - do we mean the whole skill or one level?)
- "Complete exercise" (do we mean finish one problem, one level, or the whole skill?)
- "Exercise progress" (which exercise - a level or the whole skill?)

### The Solution

Now we say:
- **"Skill C1.1"** = The complete multi-level module
- **"Level 2 of Skill C1.1"** = The "Tap to Count" scaffolding stage
- **"Problem 5 in Level 2"** = The fifth individual counting question
- **"Complete the skill"** = Finish all levels including finale (reach "completed" status)
- **"Complete a level"** = Finish all 10 problems in that level

---

## In Code vs. In Discussion

### Code (Legacy Names - Don't Change)

These names are used in the codebase and should NOT be changed:

```dart
// Models
class Exercise { ... }                          // Actually represents a Skill
class ExerciseProgress { ... }                  // Actually represents Skill progress

// Services
class ExerciseService { ... }                   // Manages Skills
ExerciseProgressMixin                           // Manages Skill progress

// Directories
exercises/                                      // Contains Skill coordinators
  count_dots_exercise_v2.dart                   // Skill C1.1 coordinator
  decompose_10_exercise.dart                    // Skill Z1 coordinator
```

**Why not rename?** Too many files, too much risk of breaking things. The code works fine.

### Discussion (Use Clear Terms)

When writing documentation or discussing features, use clear terms:

✅ **Good:**
- "Skill C1.1 has 5 levels"
- "Level 2 contains 10 problems"
- "The child completed 7 problems in Level 3"
- "All skills must have a finale level"

❌ **Avoid:**
- "Exercise C1.1" (ambiguous)
- "Exercise 2" (do you mean Skill 2 or Level 2?)
- "Complete the exercise" (which one?)

---

## Skill Naming Convention

### Format: `[Category][Number].[Variant]`

**Examples:**
- **C1.1** = Counting skill 1, variant 1 ("Count the Dots")
- **C1.2** = Counting skill 1, variant 2 ("Count the Objects")
- **C4.1** = Counting skill 4, variant 1 ("What Comes Next")
- **Z1** = Number decomposition skill 1 ("Decompose 10")
- **P3.1** = Place value skill 3, variant 1

### Categories
- **C** = Counting (Zählen)
- **Z** = Number decomposition (Zerlegungen)
- **P** = Place value (Stellenwert)
- **O** = Operations (Operationen)
- **S** = Strategies (Strategien)

---

## Progress & Completion

### Progress States

A skill can be in one of four states:

1. **notStarted** - Child has never opened this skill
2. **inProgress** - Child has started but not finished all levels
3. **finished** - Child has completed all levels at least once
4. **completed** - Child has met mastery criteria (accuracy + time limits)

### What "Complete" Means

| Context | Meaning |
|---------|---------|
| Complete a **problem** | Answer correctly (or attempt if no-fail) |
| Complete a **level** | Finish all 10 problems in that level |
| **Finish** a **skill** | Complete all levels at least once |
| **Complete** a **skill** | Finish all levels AND meet mastery criteria (zero errors + time limits in finale) |

**Important:** "Finished" ≠ "Completed"
- Finished = touched all levels
- Completed = mastered the skill (eligible for rewards)

See [COMPLETION_CRITERIA.md](COMPLETION_CRITERIA.md) for details.

---

## File Naming Conventions

### Skill Coordinators

**Location:** `exercises/`
**Pattern:** `{skill_name}_exercise.dart`

Examples:
- `count_dots_exercise_v2.dart` (Skill C1.1)
- `count_objects_exercise.dart` (Skill C1.2)
- `decompose_10_exercise.dart` (Skill Z1)

### Level Widgets

**Location:** `widgets/`
**Pattern:** `{skill_name}_level{N}_widget.dart`

Examples:
- `countdots_level1_widget_v2.dart` (Level 1 of C1.1)
- `countdots_level2_widget_v2.dart` (Level 2 of C1.1)
- `decompose10_level1_widget.dart` (Level 1 of Z1)

---

## Common Phrases & Translations

### When Writing Documentation

| Instead of... | Say... |
|---------------|--------|
| "Add a new exercise" | "Add a new skill" |
| "Exercise C1.1" | "Skill C1.1" |
| "Exercise has 3 levels" | "Skill has 3 levels" |
| "Complete exercise" | "Complete skill" (or specify: "finish level", "solve problem") |
| "Exercise progress" | "Skill progress" |
| "Exercise completion" | "Skill completion" |

### When Discussing in Code Comments

```dart
// ❌ Avoid
// This exercise has 3 levels

// ✅ Clear
// Skill C1.1 has 4 card levels + 1 finale level (5 total)
// Each level contains 10 problems
```

---

## Summary

**Use in discussion:**
- **Skill** = Complete learning module (C1.1, Z1, etc.)
- **Level** = Scaffolding stage (Level 1, Level 2, etc.)
- **Problem** = Individual question

**Keep in code:**
- `Exercise` class, `ExerciseService`, `exercises/` directory (legacy names, don't change)

**When in doubt:**
- Be specific: "Level 2 of Skill C1.1" is always clear
- Avoid "exercise" in documentation - use "skill" instead

---

**See also:**
- [CLAUDE.md](CLAUDE.md) - Main project guide with terminology section
- [COMPLETION_CRITERIA.md](COMPLETION_CRITERIA.md) - Progress & completion tracking
- [IMINT_TO_APP_FRAMEWORK.md](IMINT_TO_APP_FRAMEWORK.md) - Skill scaffolding framework
