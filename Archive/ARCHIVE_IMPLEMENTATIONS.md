# Exercise Implementations Archive

**⚠️ HISTORICAL DOCUMENT:** This file contains implementation notes for the first completed exercise as a reference example.

For current work, see [../tasks.md](../tasks.md).

---

## Z1: Decompose 10

**Date Completed:** 2025-10-29
**Skills:** `decomposition_1`, `decomposition_3`
**Source:** PIKAS Card 9 (Zahlen zerlegen), iMINT Yellow Cards

### Files Created
- `models/scaffold_level.dart` - 3-level progression framework
- `widgets/decompose10_level1_widget.dart` - Guided exploration (tap-to-flip)
- `widgets/decompose10_level2_widget.dart` - Supported practice (visual + write)
- `widgets/decompose10_level3_widget.dart` - Independent mastery (hidden visual)
- `exercises/decompose_10_exercise.dart` - Main coordinator

### Key Features
- **Level 1:** Tap counters to flip blue/red, equation auto-displays "10 = 4 blue + 6 red"
- **Level 2:** Random decomposition shown, child writes equation, 10 correct to unlock L3
- **Level 3:** Visual hidden, child finds all 11 decompositions from memory, counters appear only on errors
- **Order-dependent:** Tracks all 11 ordered pairs (0+10, 1+9, ..., 10+0) to reveal "gegensinniges Verändern"
- **Progression:** L1 always available → L2 unlocks after exploration → L3 unlocks after 10 correct in L2

### Translation from Physical Activity
**iMINT Card 3, Activity A:** Partner places pen between fingers → Digital: Tap counters to create groups
**iMINT Card 3, Activity B:** Hands covered with cloth, imagine decomposition → Digital: Level 3 hides counters

### Bug Fixed
Original implementation counted 3+7 and 7+3 as duplicates, making 11/11 completion impossible. Fixed by storing as ordered pairs without normalization.

### Pedagogical Purpose
- **Gegensinniges Verändern (Co-variation):** When one part increases, the other decreases
- **Part-Whole Understanding:** 10 is ALWAYS the sum, parts are flexible
- **Prepare for Subtraction:** 10 = 7 + ? prepares for 10 - 7 = ?

---

**Note:** C1.1, C1.2, C2.1, C3.1, and C4.1 implementation details have been removed to reduce context usage. All exercises follow the same scaffolding pattern documented in [../IMINT_TO_APP_FRAMEWORK.md](../IMINT_TO_APP_FRAMEWORK.md). See code and git history for implementation specifics.

---

**Last Updated:** 2025-11-09
