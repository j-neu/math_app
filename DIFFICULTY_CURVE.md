# Standard Difficulty Curve

**Version:** 1.0
**Last Updated:** 2025-11-23
**Purpose:** Define standard difficulty progression for all levels in all skills

---

## Overview

Every level in every skill follows a consistent difficulty curve designed to:
1. **Build confidence** - Start with trivial/easy problems
2. **Challenge appropriately** - Ramp up to medium and hard
3. **Prevent frustration** - End with easier problems (ADHD-friendly)

This creates an **Easy → Hard → Easy** flow that maintains engagement without causing anxiety.

---

## Standard Difficulty Curve

### Default Pattern (10 Problems per Level)

| Problem # | Difficulty | Purpose |
|-----------|------------|---------|
| 1-2 | **Trivial** | Warm up, build confidence, introduce mechanic |
| 3-4 | **Easy** | Practice basic application |
| 5-6 | **Medium** | Challenge with moderate complexity |
| 7-8 | **Hard** | Peak difficulty, test mastery |
| 9 | **Medium** | Cool down, consolidate learning |
| 10 | **Easy** | End positively, ensure success |

### Visual Representation

```
Difficulty
    ↑
Hard│           ▄▄
    │         ▄▀  ▀▄
Med │       ▄▀      ▀▄
    │     ▄▀          ▀▄
Easy│   ▄▀              ▀▄
    │ ▄▀                  ▀▄
Triv└▀────────────────────▀─→ Problems
     1 2 3 4 5 6 7 8 9 10
```

**Peak:** Problems 7-8 (hardest)
**Ends:** Problem 10 (easy - child always finishes on success)

---

## Difficulty Definitions

### Trivial
- **Minimum complexity** - Simplest possible version of the skill
- **Immediate success** - Child can solve with little thought
- **Purpose:** Build confidence, introduce interface

**Examples:**
- **Counting:** 3-5 objects (subitizable range)
- **Decomposition:** Split 5 (5 = 3 + 2)
- **Number line:** Jump by 1 from 1→2

### Easy
- **Low complexity** - Straightforward application
- **Comfortable range** - Within child's existing knowledge
- **Purpose:** Practice core mechanic

**Examples:**
- **Counting:** 6-8 objects (easy to count)
- **Decomposition:** Split 7 (7 = 4 + 3)
- **Number line:** Jump by 2 from 2→4

### Medium
- **Moderate complexity** - Requires thought, not automatic
- **Stretching range** - Near edge of current ability
- **Purpose:** Challenge without overwhelming

**Examples:**
- **Counting:** 10-12 objects (requires careful counting)
- **Decomposition:** Split 10 (10 = 6 + 4)
- **Number line:** Jump by 5 from 5→10

### Hard
- **High complexity** - Requires full concentration
- **Near-limit range** - At edge of target age group ability
- **Purpose:** Test mastery, prepare for next level

**Examples:**
- **Counting:** 15-20 objects (maximum for level)
- **Decomposition:** Split 18 (18 = 9 + 9)
- **Number line:** Jump by 10 from 20→30

---

## Application Guidelines

### When to Use Standard Curve

✅ **Default for all levels** unless there's a specific pedagogical reason to deviate.

**Examples where standard curve applies:**
- Skill C1.1, Level 2: Tap to count (vary object count)
- Skill Z1, Level 1: Flip counters (vary target sum)
- Skill C3.1, Level 1: Number line hopping (vary jump size)

### When to Modify Curve

❌ **Override only when:**
1. **Card prescribes different pattern** - Follow card explicitly
2. **Skill has natural constraints** - (e.g., only 11 decompositions of 10)
3. **Level introduces fundamentally new mechanic** - May need more trivial/easy problems

**Example override:**
- **Skill Z1, Level 1:** Decompose 10 has only 11 ordered pairs (10+0, 9+1, ..., 0+10)
  - Can't vary difficulty by changing target number
  - Varies difficulty by presentation order or time pressure instead

### Documenting Overrides

If you deviate from standard curve, document in code:

```dart
// DIFFICULTY CURVE OVERRIDE:
// This level uses custom progression because [reason]
// Pattern: [custom pattern description]
```

---

## Implementation Strategy

### For New Skills

When implementing a new skill, apply standard curve to each level:

```dart
// Level 1: Drag dots to count
// Difficulty curve (standard):
//   P1-2: Trivial (3-5 dots)
//   P3-4: Easy (6-8 dots)
//   P5-6: Medium (10-12 dots)
//   P7-8: Hard (15-20 dots)
//   P9: Medium (10-12 dots)
//   P10: Easy (6-8 dots)
```

**Implementation approach:**
1. Define difficulty parameters (e.g., `dotCount`, `jumpSize`, `targetSum`)
2. Map problem index to difficulty tier
3. Generate problem with appropriate parameters

**Code example:**

```dart
int _getDotCountForProblem(int problemIndex) {
  switch (problemIndex) {
    case 0:
    case 1:
      return 3 + Random().nextInt(3); // 3-5 (Trivial)
    case 2:
    case 3:
      return 6 + Random().nextInt(3); // 6-8 (Easy)
    case 4:
    case 5:
      return 10 + Random().nextInt(3); // 10-12 (Medium)
    case 6:
    case 7:
      return 15 + Random().nextInt(6); // 15-20 (Hard)
    case 8:
      return 10 + Random().nextInt(3); // 10-12 (Medium)
    case 9:
      return 6 + Random().nextInt(3); // 6-8 (Easy)
    default:
      return 8; // Fallback
  }
}
```

### For Existing Skills (Retroactive)

**Status:** To be applied retroactively to all 6 existing skills

**Priority:** Medium (after Z1 finale completion)

**Process:**
1. Audit each level in each skill
2. Identify current difficulty pattern
3. If doesn't match standard curve, update problem generation logic
4. Test to ensure curve feels right

**Skills to audit:**
- [ ] Skill C1.1: Count the Dots V2 (5 levels)
- [ ] Skill C1.2: Count the Objects (5 levels)
- [ ] Skill C2.1: Order Cards (4 levels)
- [ ] Skill C3.1: Count Forward (4 levels)
- [ ] Skill C4.1: What Comes Next (5 levels)
- [ ] Skill Z1: Decompose 10 (3 levels + finale pending)

**See:** [tasks.md](tasks.md) for retroactive application tracking

---

## Difficulty Parameters by Skill Type

### Counting Skills (C1.x, C2.x)

**Primary parameter:** Object count

| Difficulty | Object Count |
|------------|--------------|
| Trivial | 3-5 |
| Easy | 6-8 |
| Medium | 10-12 |
| Hard | 15-20 |

### Number Line Skills (C3.x, C10.x)

**Primary parameter:** Jump size OR starting number

| Difficulty | Jump Size | Starting Number |
|------------|-----------|-----------------|
| Trivial | 1 | 1-5 |
| Easy | 2-3 | 5-10 |
| Medium | 5 | 10-15 |
| Hard | 10 | 15-20 |

### Decomposition Skills (Z1.x)

**Primary parameter:** Target number OR time constraint

| Difficulty | Target Number | Time Limit |
|------------|---------------|------------|
| Trivial | 5 | No limit |
| Easy | 6-7 | 30s |
| Medium | 8-10 | 20s |
| Hard | 15-20 | 15s |

### Ordering/Sequencing Skills (C2.x, C4.x)

**Primary parameter:** Number of items OR number range

| Difficulty | Items to Order | Number Range |
|------------|----------------|--------------|
| Trivial | 3-4 | 1-5 |
| Easy | 5-6 | 1-10 |
| Medium | 7-8 | 5-15 |
| Hard | 9-10 | 10-20 |

---

## Rationale: Why Easy → Hard → Easy?

### ADHD Design Principle

From [adhd guidelines.md](adhd%20guidelines.md):
- **Start easy:** Reduce anxiety, build confidence
- **Peak in middle:** Challenge when child is engaged
- **End easy:** Ensure child finishes on success (positive reinforcement)

**Avoids:** Ending on hardest problem → frustration → quitting

### Research Support

**iMINT framework:** "Ablösung vom zählenden Rechnen" (moving away from counting-based calculation)
- Children need **safe practice** before challenging problems
- Success on **final problem** consolidates learning
- **Positive ending** encourages returning to skill

**PIKAS framework:** "Entdeckendes Lernen" (discovery-based learning)
- Difficulty ramp allows **pattern discovery**
- Easier ending allows **reflection** on learned patterns
- **No-fail approach:** Every child can succeed on problem 10

---

## Edge Cases & Special Considerations

### Finale Levels

**Difficulty curve for finale levels:** Even flatter than standard

| Problem # | Difficulty | Purpose |
|-----------|------------|---------|
| 1-3 | **Trivial** | Maximum confidence |
| 4-6 | **Easy** | Light practice |
| 7-8 | **Medium** | Gentle challenge |
| 9-10 | **Easy** | Positive end |

**No "Hard" problems in finale** - Purpose is completion/mastery, not new challenges.

### Levels with <10 Problems

If a level has fewer than 10 problems (rare), use proportional scaling:

**5 problems:**
- P1: Trivial
- P2: Easy
- P3: Medium
- P4: Medium
- P5: Easy

**7 problems:**
- P1-2: Trivial/Easy
- P3-4: Medium
- P5: Hard
- P6: Medium
- P7: Easy

### Levels with >10 Problems

If a level has more than 10 problems (rare), extend the "Hard" plateau:

**15 problems:**
- P1-2: Trivial
- P3-4: Easy
- P5-7: Medium
- P8-11: Hard (extended)
- P12-13: Medium
- P14-15: Easy

---

## Testing & Validation

### How to Verify Curve is Correct

When testing a level:

1. **Observe problem sequence:**
   - Do first 2 feel immediately solvable?
   - Does difficulty gradually increase through P3-6?
   - Are P7-8 noticeably harder?
   - Does P9-10 feel easier again?

2. **Check child response:**
   - Early problems: Quick success, building confidence
   - Middle problems: Engaged, thinking, not frustrated
   - Late problems: Relief, positive end

3. **Adjust if needed:**
   - If P7-8 too easy: Increase hardest parameter
   - If P7-8 too hard: Decrease hardest parameter
   - If curve feels wrong: Check implementation matches spec

### Common Implementation Errors

❌ **Mistake:** Randomizing difficulty completely (flat curve)
```dart
// WRONG: No curve, just random
int dotCount = 5 + Random().nextInt(16); // 5-20 random
```

✅ **Correct:** Map problem index to difficulty tier
```dart
// CORRECT: Follows standard curve
int dotCount = _getDotCountForProblem(problemIndex);
```

❌ **Mistake:** Ending on hardest problem
```dart
// WRONG: Backwards curve
case 9: return 20; // Hardest at end
```

✅ **Correct:** End easy
```dart
// CORRECT: Easy at end
case 9: return 6 + Random().nextInt(3); // 6-8 (Easy)
```

---

## Summary

**Standard difficulty curve for all levels:**
1. Trivial (P1-2)
2. Easy (P3-4)
3. Medium (P5-6)
4. Hard (P7-8)
5. Medium (P9)
6. Easy (P10)

**Apply by default** unless card prescribes different pattern.

**Document overrides** in code comments when deviating.

**Test retroactively** on existing 6 skills after Z1 finale complete.

---

**See also:**
- [CLAUDE.md](CLAUDE.md) - Skill creation checklist (includes difficulty curve requirement)
- [adhd guidelines.md](adhd%20guidelines.md) - ADHD design principles (rationale for Easy→Hard→Easy)
- [IMINT_TO_APP_FRAMEWORK.md](IMINT_TO_APP_FRAMEWORK.md) - Scaffolding framework
- [tasks.md](tasks.md) - Retroactive application tracking
