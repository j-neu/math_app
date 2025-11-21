# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter-based math learning app for young children (pre-1st to 4th grade), with special focus on ADHD support. Uses research-based pedagogical approaches from iMINT and PIKAS frameworks.

**Current Status:** Phase 2 - Exercise Engine (4/120+ exercises complete)

---

## Quick Start Commands

### Flutter Commands
```bash
# Run the app (from math_app/ directory)
flutter run

# Run tests
flutter test

# Build for production
flutter build apk  # Android
flutter build web  # Web

# Get dependencies
flutter pub get

# Analyze code
flutter analyze
```

---

## Exercise Implementation: Card-Based Scaffolding Framework

**⚠️ CRITICAL PRINCIPLE: The CARDS define the scaffolding, NOT a predetermined template!**

### The Cards Are the Authority

Each iMINT/PIKAS card has a section "Wie kommt die Handlung in den Kopf?" that **explicitly describes the scaffolding progression**. This is NOT always 3 levels!

**You MUST:**
1. Read the card's "Wie kommt die Handlung in den Kopf?" section first
2. Follow the EXACT scaffolding steps the card prescribes
3. Implement the NUMBER of levels the card describes (may be 2, 3, 4, or more)
4. Use the SPECIFIC actions the card prescribes (schieben, antippen, no action, etc.)

**Example: iMINT Card 1 (Plättchen zählen) prescribes 4 levels:**
> "Es gibt verschiedene Handlungen, um den Zählprozess zu begleiten:
> 1. Zuerst wird das gezählte Objekt **zur Seite geschoben**.
> 2. Später wird es beim lauten Zählen nur **angetippt**.
> 3. Der nächste Schritt ist das laute Abzählen **ohne weitere äußere Handlung**.
> 4. Das Verfolgen der Zählhandlung mit den **Augen** und die Nennung des Ergebnisses."

**App must implement 4 levels:**
- Level 1: Drag dots to "counted" area
- Level 2: Tap dots (marks them)
- Level 3: No interaction, child counts silently
- Level 4: Flash then hide (memory challenge)

### Common Misconception to AVOID

❌ **WRONG:** "All exercises have 3 levels: Guided Exploration, Supported Practice, Independent Mastery"

✅ **CORRECT:** "Each card prescribes its own scaffolding. I must read and follow what the card says."

### Why This Matters

The iMINT research is explicit: "Ein Auswendiglernen der Zerlegungen ist erst sinnvoll, wenn diese Beziehungen verstanden worden sind." (Memorizing decompositions only makes sense after these relationships are understood.)

The cards are **research-based pedagogical prescriptions**. They specify:
- The exact actions that help children internalize concepts
- The sequence that supports learning without overloading
- The gradual reduction of support that builds independence

**When we ignore the card and apply a template, we break the pedagogical design.**

### Complete Framework Documentation

**See:** [IMINT_TO_APP_FRAMEWORK.md](IMINT_TO_APP_FRAMEWORK.md) - Now updated with card-first approach

---

## Core Educational Philosophy

### PIKAS: Connecting Representations
Every math concept must be explorable through four interconnected modes:
- **Handlung (Action)**: Interactive manipulatives (draggable blocks, beads, counters)
- **Bild (Image)**: Static structured images (20-frame, 100-field, number line)
- **Sprache (Language)**: Simple spoken/written descriptions
- **Mathesprache (Symbols)**: Formal mathematical notation (5 + 3 = 8)

### iMINT: Diagnosis-First Approach
1. Start with diagnostic test to identify child's calculation strategies
2. Analyze results to create skill profile (stored in `UserProfile.skillTags`)
3. Generate personalized learning path based on skill gaps
4. Match exercises to user's specific `skillTags`

### Five Core Competency Areas
1. **Zahlverständnis** (Number Sense): Understanding numbers as quantities
2. **Operationsverständnis** (Operational Sense): Understanding what operations mean
3. **Stellenwertverständnis** (Place Value): Understanding decimal bundling
4. **Schnelles Kopfrechnen** (Fast Mental Math): Automating basic facts via strategies
5. **Zahlenrechnen** (Calculating): Flexible calculation strategies

---

## ADHD-Informed Design Principles

From [adhd guidelines.md](adhd%20guidelines.md) - these principles MUST be maintained:

1. **Concrete & Visual**: Heavy use of manipulatives and diagrams
2. **Short & Chunked**: Sessions capped at 15 minutes maximum
3. **Immediate Feedback**: Instant positive reinforcement, no delayed grading
4. **No-Fail Approach**: Never say "wrong" - switch to different representation to guide learning
5. **Explicit Strategy Instruction**: Teach strategies (like "make 10") explicitly
6. **Low Cognitive Load**: Minimalist UI, clear navigation, consistent color-coding

---

## Architecture Overview

### Data Flow
```
UserSelectionScreen → HomeScreen → DiagnosticScreen (if new user)
                                 → ExerciseScreen (if returning)

DiagnosticService → Updates UserProfile.skillTags
ExerciseService → Matches exercises to UserProfile.skillTags
```

### Key Models
- [UserProfile](math_app/lib/models/user_profile.dart): Stores user data, `skillTags` (88 skill IDs), exercise progress, rewards config
- [DiagnosticQuestion](math_app/lib/models/diagnostic_question.dart): 59 diagnostic questions from CSV
- [Exercise](math_app/lib/models/exercise.dart): Exercise content + `exerciseWidget` field
- [ScaffoldProgress](math_app/lib/models/scaffold_level.dart): Tracks level progression (ephemeral, in-exercise only)
- [ExerciseProgress](math_app/lib/models/exercise_progress.dart): Persistent per-exercise completion tracking
- [LevelProgress](math_app/lib/models/level_progress.dart): Persistent per-level performance data
- [RewardConfig](math_app/lib/models/reward_config.dart): Parent-configured reward system settings

### Services
- [DiagnosticService](math_app/lib/services/diagnostic_service.dart): Loads/parses diagnostic CSV, populates `skillTags` on wrong answers
- [ExerciseService](math_app/lib/services/exercise_service.dart): Generates learning path by matching exercise `skillTags` to user's `skillTags`, filters by completion status, groups by milestones
- [RewardService](math_app/lib/services/reward_service.dart): Calculates reward eligibility, manages reward celebrations

### Skill System (88 Skills)
- **76 iMINT skills:** `counting_1` through `combined_strategy_20`
- **12 PIKAS skills:** `ordinal_1-2`, `representation_1-4`, `operation_sense_*`, `number_line_*`
- **Format:** `category_number` (e.g., `decomposition_3`, `counting_15`)
- **Documentation:** `Research/SKILLS_README.md`, `Research/skills_taxonomy.csv`

---

## Project Structure

```
math_app/
├── lib/
│   ├── main.dart                 # App entry point, theme, routing
│   ├── models/                   # Data models (UserProfile, Exercise, ScaffoldLevel)
│   ├── screens/                  # Full-screen UI (Diagnostic, Exercise, LearningPath)
│   ├── widgets/                  # Reusable UI (level-specific widgets, manipulatives)
│   ├── exercises/                # Exercise coordinators (decompose_10_exercise.dart, etc.)
│   └── services/                 # Business logic (DiagnosticService, ExerciseService)
├── Research/                     # Pedagogical research documents
└── test/                         # Unit/widget tests
```

---

## Current Development Phase

**Phase 2:** Exercise Engine & Core Content
- **Status:** 6/120+ exercises complete (5%)
- **Current Set:** SET 1 - Foundation Counting (5/6 done, 83%)
- **Next:** C10.1 (Place Numbers on Line)

**See [tasks.md](tasks.md) for complete roadmap**

---

## When Adding Exercises

Every exercise MUST:

1. **⚠️ READ THE CARD FIRST** - Find and read the iMINT/PIKAS card's "Wie kommt die Handlung in den Kopf?" section
2. **Follow the CARD'S scaffolding** (see [IMINT_TO_APP_FRAMEWORK.md](IMINT_TO_APP_FRAMEWORK.md))
3. **Implement the NUMBER of levels the card prescribes** (may be 2, 3, 4, or more - NOT always 3!)
4. **ADD A FINALE LEVEL** - After card-prescribed levels, add one final "Summary" level with easier mixed review (ADHD: Easy→Hard→Easy flow)
   - **⚠️ CRITICAL:** Finale MUST be completable - child must be able to reach "completed" status
   - Define clear completion criteria (accuracy, time, minimum problems)
   - Test that criteria are achievable by target age group
5. **Use the SPECIFIC actions from the card** (schieben/drag, antippen/tap, no action, flash-hide, etc.)
6. **Tag with appropriate `skillTags`** from skills taxonomy
7. **Support "no-fail" feedback** (hints, representation switching, visual safety net)
8. **Integrate ExerciseProgressMixin** - ALL exercises must save/load state:
   - Load progress on initState (restores level unlocks, problem history)
   - Save progress every 5 problems (auto-save)
   - Save progress on exit (WillPopScope/PopScope)
   - Track time per problem with Stopwatch
9. **Implement completion tracking** - Save progress to UserProfile, distinguish "finished" vs "completed" (see [COMPLETION_CRITERIA.md](COMPLETION_CRITERIA.md))
10. **Define completion criteria** - Specify time limits per problem and accuracy requirements for "completed" status
11. **Test state persistence** - Verify child can exit and resume from same point

### Exercise Creation Workflow

When implementing any exercise:

1. **READ the card** - Extract exact scaffolding levels from "Wie kommt die Handlung in den Kopf?"
2. Create N level widget files in `widgets/` directory (where N = number of levels from card)
3. Create N+1 level widget file for finale level (easier mixed review)
4. Create exercise coordinator in `exercises/` directory
5. **Integrate ExerciseProgressMixin:**
   - Extend coordinator with `ExerciseProgressMixin`
   - Implement `loadProgress()` in `initState()`
   - Implement `saveProgress()` in `dispose()` and every 5 problems
   - Pass `startProblemTimer` and `recordProblemResult` to level widgets
6. **Define completion criteria** in coordinator comments (accuracy %, time limit, min problems)
7. Register in `exercise_service.dart`
8. Run `flutter analyze` to check for errors
9. **Test state persistence:**
   - Start exercise → solve some problems → exit
   - Reopen exercise → verify progress restored
   - Complete finale → verify "completed" status reached
10. **DO NOT** create individual implementation summary documents (*.md files)
    - ARCHIVE_IMPLEMENTATIONS.md already documents the first 4 exercises as reference
    - New exercises should be documented in code comments only
    - Major design decisions can be noted in git commit messages
11. Update this file (CLAUDE.md) only if status changes significantly

### Exercise Planning Questions

Before implementing, answer these IN ORDER:

1. **Source:** Which iMINT Arbeitskarte or PIKAS card? (Find the extracted text file)
2. **Worum geht es?** (What's it about?) - Mathematical concept from card
3. **Worauf ist zu achten?** (What to observe?) - Key points, misconceptions from card
4. **Wie kommt die Handlung in den Kopf?** - READ THIS SECTION FROM CARD:
   - How many levels does the card describe? (count them!)
   - What SPECIFIC action at each level? (schieben, antippen, no action, etc.)
   - What is the progression of support? (more → less)
5. **App Translation:** For EACH level from card, map physical action → digital equivalent
6. **Data Tracking:** What reveals child's strategy?
7. **Answer Uniqueness:** Does order matter? (document clearly)

**See [IMINT_TO_APP_FRAMEWORK.md](IMINT_TO_APP_FRAMEWORK.md) for complete methodology.**

---

## Important Constraints

### When Modifying UI
1. Maintain minimalist design (ADHD principle: low cognitive load)
2. Keep feedback instant and positive
3. Use consistent color-coding from theme
4. Preserve 3-level progression pattern

### Data Structure
- Skill tags are strings, not integers (e.g., 'counting_4' not 4)
- User profiles persisted via SharedPreferences (includes exercise progress, reward config)
- Exercise progress tracked per-level with timestamps, accuracy, response times
- Completion status: `notStarted` → `inProgress` → `finished` → `completed`
- Diagnostic CSV at `Research/MathApp_Diagnostic_with_skills.csv` is source of truth

---

## Key Documentation

**Essential Reading:**
- [IMINT_TO_APP_FRAMEWORK.md](IMINT_TO_APP_FRAMEWORK.md) - Scaffolding framework + finale level design (CRITICAL)
- [COMPLETION_CRITERIA.md](COMPLETION_CRITERIA.md) - Exercise completion tracking system (finished vs completed)
- [REWARDS_SYSTEM_QUICK_REF.md](REWARDS_SYSTEM_QUICK_REF.md) - Parent-configured reward system (quick reference)
- [tasks.md](tasks.md) - Current work and roadmap
- [adhd guidelines.md](adhd%20guidelines.md) - ADHD design principles

**Historical Context:**
- [COMPLETED_TASKS.md](COMPLETED_TASKS.md) - What's been done (Phases 1 & 1.5)
- [Archive/ARCHIVE_IMPLEMENTATIONS.md](Archive/ARCHIVE_IMPLEMENTATIONS.md) - Reference implementation (Z1 only)

**Research Materials:**
- `Research/SKILLS_README.md` - Complete skill system documentation
- `Research/skills_taxonomy.csv` - All 88 skills cataloged
- `Research/PIKAS_Analysis.md` - 36/58 PIKAS cards analyzed
- `Research/iMINT-Kartei_190529.pdf` - iMINT cards (German)
- `Research/REWARDS_SYSTEM.md` - Detailed reward system spec (UI, modals, milestones)

---

## Completed Exercises (Reference)

**Z1: Decompose 10** - `decomposition_1`, `decomposition_3`
- Tap-to-flip counters, hidden visual on L3, tracks 11 ordered pairs
- ~1,654 lines

**C1.1: Count the Dots (V2)** - `counting_1`
- 4-level implementation: L1 drag, L2 tap, L3 look-only, L4 eye-tracking
- Structured & random layouts (toggle in L3/L4)
- Non-overlapping random positioning (0.08 min distance)
- Adaptive difficulty 5→20
- ~2,000 lines

**C1.2: Count the Objects** - `counting_1`
- Various objects (stars, hearts, emoji), custom painters
- ~1,929 lines

**C2.1: Order Cards to 20** - `counting_2`
- Tap/drag/memory sorting, adaptive 5→10 numbers
- ~1,326 lines

**C3.1: Count Forward to 20** - `counting_3`
- Interactive number line with hopping, custom painter, adaptive difficulty
- ~2,000 lines

**C4.1: What Comes Next?** - `counting_4`, `counting_5`
- Predecessor/successor exploration, 3 problem types in L3, pulse animations
- ~1,900 lines

**Total:** ~10,809 lines of exercise code (6 exercises)
**Note:** C1.1 uses V2 (4-level implementation with non-overlapping random positioning)

**See [ARCHIVE_IMPLEMENTATIONS.md](ARCHIVE_IMPLEMENTATIONS.md) for detailed notes on first 4 exercises.**

---

**Last Updated:** 2025-10-30
**Current Focus:** SET 1 completion (Foundation Counting)
