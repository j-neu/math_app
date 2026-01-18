# GEMINI.md

This file provides guidance to the Gemini CLI agent when working with code in this repository.

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

## Terminology

**⚠️ CRITICAL:** Read **[TERMINOLOGY.md](TERMINOLOGY.md)** first.

It defines the strict hierarchy:
**Skill** (Module) > **Level** (Scaffolding Stage) > **Problem** (Question).

*   **Skill:** The complete unit (e.g., "C1.1 Count the Dots").
*   **Level:** A stage within that skill (e.g., "Level 2: Tap to Count").
*   **Problem:** A single question (e.g., "Count these 5 dots").

**Note:** In code, the class `Exercise` typically refers to a **Skill**.

---

## Skill Implementation: Card-Based Scaffolding Framework

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

**Phase 2:** Skill Engine & Core Content
- **Status:** 6/120+ skills complete (5%)
- **Current Set:** SET 1 - Foundation Counting (5/6 done, 83%)
- **Next:** Z1 finale completion

**See [tasks.md](tasks.md) for complete roadmap**

---

## When Adding Skills

Every skill MUST:

1. **⚠️ READ THE CARD FIRST** - Find and read the iMINT/PIKAS card's "Wie kommt die Handlung in den Kopf?" section
2. **Follow the CARD'S scaffolding** (see [IMINT_TO_APP_FRAMEWORK.md](IMINT_TO_APP_FRAMEWORK.md))
3. **Implement the NUMBER of levels the card prescribes** (may be 2, 3, 4, or more)
4. **NO FINALE LEVEL** - Do NOT add an artificial "summary" or "finale" level. The skill ends when the card's prescribed levels are done.
   - **Reason:** We rely on the card's pedagogical design.
   - **Completion:** Mastery of the final card level constitutes skill completion.
5. **APPLY STANDARD DIFFICULTY CURVE** - Every level follows Easy→Hard→Easy progression (see [DIFFICULTY_CURVE.md](DIFFICULTY_CURVE.md))
   - **Standard curve (10 problems):** Trivial (P1-2), Easy (P3-4), Medium (P5-6), Hard (P7-8), Medium (P9), Easy (P10)
   - **Purpose:** Build confidence, challenge appropriately, end positively (ADHD-friendly)
   - **Override only when:** Card prescribes different pattern OR skill has natural constraints
   - **Document overrides** in code comments with rationale
6. **Use the SPECIFIC actions from the card** (schieben/drag, antippen/tap, no action, flash-hide, etc.)
7. **Tag with appropriate `skillTags`** from skills taxonomy
8. **Support "no-fail" feedback** (hints, representation switching, visual safety net)
9. **Integrate ExerciseProgressMixin** - ALL skills must save/load state:
   - Load progress on initState (restores level unlocks, problem history)
   - Save progress every 5 problems (auto-save)
   - Save progress on exit (WillPopScope/PopScope)
   - Track time per problem with Stopwatch
10. **Implement level completion flow** - After completing all problems in a level:
   - Show dialog: "Continue to Next Level" OR "Stop for Today"
   - Save progress BEFORE executing either choice
   - NO option to replay current level immediately
   - See "Level Completion & Navigation Flow" section below
11. **Implement completion tracking** - Save progress to UserProfile, distinguish "finished" vs "completed" (see [COMPLETION_CRITERIA.md](COMPLETION_CRITERIA.md))
12. **Define completion criteria** - Specify time limits per problem and accuracy requirements for "completed" status
13. **Test state persistence** - Verify child can exit and resume from same point

### Skill Creation Workflow

When implementing any skill:

1. **READ the card** - Extract exact scaffolding levels from "Wie kommt die Handlung in den Kopf?"
2. Create N level widget files in `widgets/` directory (where N = number of levels from card)
3. Create skill coordinator in `exercises/` directory
4. **Integrate ExerciseProgressMixin:**
   - Extend coordinator with `ExerciseProgressMixin`
   - Implement `loadProgress()` in `initState()`
   - Implement `saveProgress()` in `dispose()` and every 5 problems
   - Pass `startProblemTimer` and `recordProblemResult` to level widgets
5. **Define completion criteria** in coordinator comments (accuracy %, time limit, min problems)
6. Register in `exercise_service.dart`
7. Run `flutter analyze` to check for errors
8. **Test state persistence:**
   - Start skill → solve some problems → exit
   - Reopen skill → verify progress restored
   - Complete final level → verify "completed" status reached
9. **DO NOT** create individual implementation summary documents (*.md files)
    - ARCHIVE_IMPLEMENTATIONS.md already documents the first 4 skills as reference
    - New skills should be documented in code comments only
    - Major design decisions can be noted in git commit messages
10. Update this file (GEMINI.md) only if status changes significantly

### Skill Planning Questions

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

## Level Completion & Navigation Flow

### After Completing All Problems in a Level

When a child finishes all problems in a level (e.g., completes 10/10 problems), they are presented with **two options only**:

**Option 1: Continue to Next Level**
- If next level is unlocked: Immediately advance to next level
- **CRITICAL:** Save progress BEFORE advancing (level completion must persist)
- Child continues learning in same session

**Option 2: Stop for Today**
- Return child to Learning Path screen
- **CRITICAL:** Save progress BEFORE exiting (level completion must persist)
- Next session: Child resumes at the NEXT level (not the one they just completed)

**❌ NOT ALLOWED:** Staying on the same level to repeat problems
- Child cannot replay completed level immediately
- Prevents obsessive repetition (ADHD concern)
- Forces progression or healthy break

### Progress Saving Requirements

**What MUST be saved when level completes:**
1. **Level completion status** - Mark current level as "finished"
2. **Next level unlock** - Unlock next level if criteria met
3. **Problem history** - Save all problem results, times, accuracy
4. **Overall skill progress** - Update skill status (notStarted → inProgress → finished → completed)

**When to save:**
- **On "Continue"** - Save immediately before advancing to next level
- **On "Stop for Today"** - Save immediately before returning to Learning Path
- **On app exit** - Save in WillPopScope/PopScope callback
- **Every 5 problems** - Auto-save during level (safety net)

**Implementation:**
```dart
void _onLevelComplete() async {
  // Save progress first
  await saveProgress();

  // Unlock next level
  unlockLevel(_currentLevelNumber + 1);

  // Show completion dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('Level $_currentLevelNumber Complete! 🎉'),
      content: Text('Great job! Ready to continue?'),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.pop(context); // Close dialog
            await saveProgress(); // Save again (redundant but safe)
            Navigator.pop(context); // Return to Learning Path
          },
          child: Text('Stop for Today'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context); // Close dialog
            await saveProgress(); // Save again (redundant but safe)
            _advanceToNextLevel();
          },
          child: Text('Continue to Level ${_currentLevelNumber + 1}'),
        ),
      ],
    ),
  );
}
```

**Resumption Behavior:**
- If child stopped after Level 2: Next session starts at Level 3
- If child continued to Level 3: Next session continues from Level 3 (if they exit mid-level)
- If child completed all levels: Skill marked as "finished" (or "completed" if criteria met)

**See:** [COMPLETION_CRITERIA.md](COMPLETION_CRITERIA.md) for finished vs. completed distinction

---

## Important Constraints

### When Modifying UI
1. Maintain minimalist design (ADHD principle: low cognitive load)
2. Keep feedback instant and positive
3. Use consistent color-coding from theme
4. Preserve card-based scaffolding progression

## QA & Common Issues

### 1. Level Completion Hangups
**Symptom:** User completes 10/10 problems, but nothing happens. No dialog, no next level.
**Cause:** Logic error in the problem completion callback or mismatched problem counts.
**Prevention Rule:**
- **Explicit Check:** Every `_onProblemComplete` MUST check `if (currentProblemIndex >= totalProblems)`.
- **Coordinator Logic:** The Coordinator (not the Widget) MUST own the completion logic.
- **Auto-Advance:** Ensure `_onLevelComplete` triggers the dialog/transition immediately.

### 2. Android Rendering (Black Backgrounds)
**Symptom:** Deep black background on Android devices, hiding text/elements (e.g., in "Count the Dots").
**Cause:** Transparent `Scaffold` or `Container` defaulting to the system "canvas" color, which is black in some themes/modes.
**Prevention Rule:**
- **Explicit Backgrounds:** NEVER rely on default theme colors for main surfaces.
- **Rule:** Every `Scaffold` and full-screen `Container` MUST have `backgroundColor: Colors.white` (or a specific theme color) explicitly set.
- **Test:** Verify on an Android emulator or device, not just web/iOS simulator.

### 3. Stacked/Doubled App Bar
**Symptom:** Two app bars appear stacked on top of each other with the same title.
**Cause:** ExerciseScreen wrapping an exercise that already has its own Scaffold (via MinimalistExerciseScaffold).
**Fix:** Ensure ExerciseScreen does NOT wrap exercises with `exerciseBuilder` in a Scaffold.

### 4. Widget State Not Resetting (Random Problems)
**Symptom:** UI doesn't update when a new problem is generated if the primary parameters (e.g., finger counts) happen to be the same as the previous problem.
**Cause:** `didUpdateWidget` only checking subset of parameters.
**Fix:** Check ALL parameters that affect state in `didUpdateWidget`.
```dart
if (oldWidget.a != widget.a || oldWidget.b != widget.b || oldWidget.target != widget.target) {
  _resetState();
}
```

### 5. Level Completion Not Saving
**Symptom:** User finishes level, but next time it's locked again.
**Cause:** Shadowing `ExerciseProgressMixin` state with local `_levelUnlocked` map that resets on init.
**Fix:** Do NOT maintain local unlock state. Use `isLevelUnlocked(int)` from mixin directly.
```dart
// ❌ BAD: Map<int, bool> _levelUnlocked = {1: true...};
// ✅ GOOD: isLevelUnlocked(levelNumber)
```

### 6. Layout Errors in ScrollViews
**Symptom:** "RenderBox was not laid out" inside `SingleChildScrollView`.
**Cause:** Using `Spacer()` or `Expanded()` inside a scroll view (infinite height constraint).
**Fix:** Use `SizedBox(height: X)` instead of `Spacer()`.


### Data Structure
- Skill tags are strings, not integers (e.g., 'counting_4' not 4)
- User profiles persisted via SharedPreferences (includes exercise progress, reward config)
- Exercise progress tracked per-level with timestamps, accuracy, response times
- Completion status: `notStarted` → `inProgress` → `finished` → `completed`
- Diagnostic CSV at `Research/MathApp_Diagnostic_with_skills.csv` is source of truth

---

## Key Documentation

**Essential Reading:**
- [TERMINOLOGY.md](TERMINOLOGY.md) - Skill vs. Level vs. Problem clarification (READ FIRST)
- [IMINT_TO_APP_FRAMEWORK.md](IMINT_TO_APP_FRAMEWORK.md) - Scaffolding framework + finale level design (CRITICAL)
- [DIFFICULTY_CURVE.md](DIFFICULTY_CURVE.md) - Standard difficulty progression for all levels (NEW)
- [COMPLETION_CRITERIA.md](COMPLETION_CRITERIA.md) - Exercise completion tracking system (finished vs completed)
- [REWARDS_SYSTEM_QUICK_REF.md](REWARDS_SYSTEM_QUICK_REF.md) - Parent-configured reward system (quick reference)
- [tasks.md](tasks.md) - Current work and roadmap
- [adhd guidelines.md](adhd%20guidelines.md) - ADHD design principles

**Historical Context:**
- [Archive/COMPLETED_TASKS_PHASE2.md](Archive/COMPLETED_TASKS_PHASE2.md) - What's been done (Phases 1 & 1.5)
- [Archive/ARCHIVE_IMPLEMENTATIONS.md](Archive/ARCHIVE_IMPLEMENTATIONS.md) - Reference implementation (Z1 only)

**Research Materials:**
- `Research/SKILLS_README.md` - Complete skill system documentation
- `Research/skills_taxonomy.csv` - All 88 skills cataloged
- `Research/PIKAS_Analysis.md` - 36/58 PIKAS cards analyzed
- `Research/iMINT-Kartei_190529.pdf` - iMINT cards (German)
- `Research/REWARDS_SYSTEM.md` - Detailed reward system spec (UI, modals, milestones)

---

## Completed Skills (Reference)

**Skill Z1: Decompose 10** - Tags: `decomposition_1`, `decomposition_3`
- 3 levels + finale (needs implementation)
- Tap-to-flip counters, hidden visual on L3, tracks 11 ordered pairs
- ~1,654 lines

**Skill C1.1: Count the Dots (V2)** - Tags: `counting_1`
- 4 card levels + finale (5 total)
- L1 drag, L2 tap, L3 look-only, L4 flash-hide, L5 finale
- Structured & random layouts (toggle in L3/L4)
- Non-overlapping random positioning (0.08 min distance)
- Adaptive difficulty 5→20
- ~2,000 lines

**Skill C1.2: Count the Objects** - Tags: `counting_1`
- 4 card levels + finale (5 total)
- Various objects (stars, hearts, emoji), custom painters
- ~1,929 lines

**Skill C2.1: Order Cards to 20** - Tags: `counting_2`
- 3 card levels (NO finale - per iMINT card 2)
- L1: Read sequence, L2: Find 2-3 missing, L3: Find 5+ missing
- ~1,326 lines

**Skill C3.1: Count Forward to 20** - Tags: `counting_3`
- 3 card levels + finale (4 total)
- Interactive number line with hopping, custom painter, adaptive difficulty
- ~2,000 lines

**Skill C4.1: What Comes Next?** - Tags: `counting_4`, `counting_5`
- 3 card levels + challenge + finale (5 total)
- Predecessor/successor exploration, 3 problem types in L3, pulse animations
- ~1,900 lines

**Skill S1.1: Fingerblitz** - Tags: `basic_strategy_1`
- 4 levels (Guided, Supported, Mastery, Challenge)
- Flash card mode (2s visibility), interactive finger construction (additive/subtractive)
- Uses `FingerDisplayWidget` with increment/decrement interaction
- ~1,200 lines

**Total:** ~12,000 lines across 7 skills

**See [Archive/ARCHIVE_IMPLEMENTATIONS.md](Archive/ARCHIVE_IMPLEMENTATIONS.md) for detailed notes on first 4 skills.**

---

## Common Issues & Troubleshooting

### Doubled/Stacked App Bar

**Symptom:** Two app bars appear stacked on top of each other with the same title.

**Cause:** ExerciseScreen wrapping an exercise that already has its own Scaffold (via MinimalistExerciseScaffold).

**Fix:** Ensure ExerciseScreen does NOT wrap exercises with `exerciseBuilder` in a Scaffold:
```dart
// In ExerciseScreen.build():
if (currentExercise.exerciseBuilder != null) {
  return _buildRepresentationView(currentExercise);  // Direct return
}
```

**See:** "⚠️ CRITICAL: Stacked/Doubled App Bar Issue" section above for full details.

### Level Selector Not Showing

**Cause:** DraggableScrollableSheet without proper constraints or missing builder parameters.

**Fix:** Use LevelSelectionDrawer directly in showModalBottomSheet:
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => LevelSelectionDrawer(
    levels: [...],
    currentLevel: _currentLevel,
    onLevelSelected: _switchLevel,
    isLevelUnlocked: (level) => isLevelUnlocked(level.levelNumber),
  ),
);
```

### Skill Won't Complete After Final Level

**Cause:** `totalLevels` or `finaleLevelNumber` set incorrectly, or trying to unlock Level 4/5 when only 3 levels exist.

**Fix:** Set `totalLevels` and `finaleLevelNumber` to match actual number of levels:
```dart
@override
int get totalLevels => 3;  // Match actual level count

@override
int get finaleLevelNumber => 3;  // Last level number
```

### Recent Issues & Lessons Learned

1.  **Mixin Requirements:** When using `ExerciseProgressMixin`, you **MUST** implement `exerciseId` and `userProfile` getters in the state class. The mixin relies on these to load/save progress.
2.  **ExerciseConfig Parameters:** `ExerciseConfig` requires all pedagogical metadata fields (`sourceCard`, `concept`, `observationPoints`, `internalizationPath`, `targetNumber`). Do not omit them or use the old `Exercise` model.
3.  **State Management Restoration:** When updating a file (like adding `problemIndex`), ensure you restore ALL existing state variables and methods. Do not accidentally delete unrelated logic.
4.  **Syntax Verification:** After using `replace` or `write_file`, ALWAYS run `flutter analyze` to catch syntax errors (like stray characters) immediately.

---

**Last Updated:** 2026-01-11
**Current Focus:** SET 1 completion (Foundation Counting) & Basic Strategies