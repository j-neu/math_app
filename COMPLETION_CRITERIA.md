# Exercise Completion Tracking

**Purpose:** Distinguish "finished" (explored all levels) from "completed" (mastered final level).

## Status States

1. **Not Started:** Never opened • Gray outline
2. **In Progress:** Some levels unlocked • Cyan highlight
3. **Finished:** All levels unlocked • Blue checkmark • No accuracy/time requirements
4. **Completed (Mastered):** Final level mastered • Green checkmark with stars
   - **Criteria:** 10 problems, zero errors, within time limits on the **last level**.

## Completion Rules

**Time Limits:** Counting = 20s | Decomposition = 15s | Ordering = 30s | Multi-step = 45s
**Accuracy:** Final level requires zero errors | Earlier levels have no requirements (encourage exploration)
**Minimum:** 10 problems in final level

## Exercise-Specific Criteria (Quick Reference)

| Exercise | Card Levels | Completion Target | Time Limit | Notes |
|----------|-------------|-------------------|------------|-------|
| **C1.1** | 4 (Drag→Tap→Look→Flash) | Level 4: Flash-hide | 20s | Mental image |
| **C1.2** | 3 (Tap→Count→Flash) | Level 3: Flash-hide | 20s | Mental image |
| **C2.1** | 3 (Tap→Drag→Memory) | Level 3: Memory | 30s | More processing |
| **C3.1** | 3 (Hop→Write→Memory) | Level 3: Memory | 25s | Number line |
| **C4.1** | 3 (Explore→Write→Mixed) | Level 3: Mixed | 20s | Recall |
| **Z1** | 3 (Explore→Write→Find all) | Level 3: Find all | 15s | Instant recall |

**Finished = All levels unlocked | Completed = Final level mastered (10 problems, 0 errors, within time)**

## Data Models (Key Fields)

**ExerciseProgress:** `exerciseId`, `status`, `levelProgress` (Map), `firstAttemptDate`, `finishedDate`, `completedDate`, `totalTimeSeconds`

**LevelProgress:** `levelNumber`, `unlocked`, `correctAnswers`, `totalAttempts`, `problemResults[]`, accuracy (computed)

**ProblemResult:** `correct`, `timeSeconds`, `timestamp`, `userAnswer?`

## Implementation Pattern

**Save Progress:** On level unlock | Every 5 problems | On exit (WillPopScope) | On completion
**Load Progress:** In `initState()` before first render
**Status Logic:** Check all levels unlocked → Check final level stats (10+ problems, 0 errors, within time) → Return status

**ExerciseService Priority:** In-progress → Not started (unlocked milestones) → Needs review (finished but not completed)

**Parent Dashboard:** CompletionStats (notStarted, inProgress, finished, completed counts) • Time spent analysis

## Future Enhancements

- Adaptive time limits (+50% for younger children)
- Partial credit (1-2 errors = "almost completed")
- Streak tracking • Performance trends graphs
