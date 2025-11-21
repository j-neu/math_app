# Exercise Completion Tracking

**Purpose:** Distinguish "finished" (explored all levels) from "completed" (mastered finale).

## Status States

1. **Not Started:** Never opened • Gray outline
2. **In Progress:** Some levels unlocked • Cyan highlight
3. **Finished:** All levels unlocked • Blue checkmark • No accuracy/time requirements
4. **Completed (Mastered):** Finished + finale mastered • Green checkmark with stars
   - Finale: 10 problems, zero errors, within time limits

## Completion Rules

**Time Limits:** Counting = 20s | Decomposition = 15s | Ordering = 30s | Multi-step = 45s
**Accuracy:** Finale requires zero errors | Earlier levels have no requirements (encourage exploration)
**Minimum:** 10 problems in finale

## Exercise-Specific Criteria (Quick Reference)

| Exercise | Card Levels | Finale | Time Limit | Notes |
|----------|-------------|--------|------------|-------|
| **C1.1** | 4 (Drag→Tap→Look→Flash) | L5: 8-12 dots | 20s | Simple counting |
| **C1.2** | 3 (Tap→Count→Flash) | L4: Mixed objects | 20s | Various objects |
| **C2.1** | 3 (Tap→Drag→Memory) | L4: Order 5-7 nums | 30s | More processing |
| **C3.1** | 3 (Hop→Write→Memory) | L4: Count by 1s/2s | 25s | Number line |
| **C4.1** | 3 (Explore→Write→Mixed) | L4: Before/after 0-15 | 20s | Simple recall |
| **C10.1** | 3 (Drag→Estimate→Mental) | L4: Place 5 nums | 30s | ±2 tolerance |
| **Z1** | 3 (Explore→Write→Find all) | L4: Decompose 5-8 | 15s | Instant recall |

**Finished = All levels unlocked | Completed = Finale mastered (10 problems, 0 errors, within time)**

## Data Models (Key Fields)

**ExerciseProgress:** `exerciseId`, `status`, `levelProgress` (Map), `firstAttemptDate`, `finishedDate`, `completedDate`, `totalTimeSeconds`

**LevelProgress:** `levelNumber`, `unlocked`, `correctAnswers`, `totalAttempts`, `problemResults[]`, accuracy (computed)

**ProblemResult:** `correct`, `timeSeconds`, `timestamp`, `userAnswer?`

## Implementation Pattern

**Save Progress:** On level unlock | Every 5 problems | On exit (WillPopScope) | On completion
**Load Progress:** In `initState()` before first render
**Status Logic:** Check all levels unlocked → Check finale (10+ problems, 0 errors, within time) → Return status

**ExerciseService Priority:** In-progress → Not started (unlocked milestones) → Needs review (finished but not completed)

**Parent Dashboard:** CompletionStats (notStarted, inProgress, finished, completed counts) • Time spent analysis

## Future Enhancements

- Adaptive time limits (+50% for younger children)
- Partial credit (1-2 errors = "almost completed")
- Streak tracking • Performance trends graphs
