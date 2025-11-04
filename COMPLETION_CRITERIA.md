# Exercise Completion Tracking System

## Overview

This document defines the completion tracking system for Math App exercises. It distinguishes between "finished" (explored all levels) and "completed" (mastered with accuracy and speed requirements).

**Key Principle:** ADHD-friendly progression that celebrates exploration while tracking mastery for parent insights.

---

## Completion Status States

### 1. Not Started
- **Definition:** Exercise never opened by this user
- **Visual:** Gray outline, dot icon, opacity 0.5
- **User Action:** Tap to begin
- **Data:** No ExerciseProgress record exists

### 2. In Progress
- **Definition:** Exercise opened, some levels unlocked, but not all
- **Visual:** Cyan highlight, arrow icon, elevated card
- **User Action:** Continue where left off
- **Data:** ExerciseProgress exists with `status = inProgress`

### 3. Finished
- **Definition:** All card-prescribed levels AND finale level unlocked at least once
- **Visual:** Blue checkmark, slight transparency, "Practice Again" label
- **User Action:** Can replay for additional practice
- **Data:** ExerciseProgress with `status = finished`
- **Criteria:**
  - All levels unlocked (including finale)
  - No accuracy or time requirements

### 4. Completed (Mastered)
- **Definition:** Finished + demonstrated mastery in finale level
- **Visual:** Green checkmark, stars icon, full opacity, "Mastered!" label
- **User Action:** Optional review, primarily complete
- **Data:** ExerciseProgress with `status = completed`
- **Criteria:**
  - All levels finished
  - Finale level: Zero errors (100% accuracy)
  - Finale level: All problems within time limits
  - Minimum 10 problems completed in finale

---

## Completion Criteria Per Exercise

### General Rules

**Time Limits (configurable per problem type):**
- Default: 30 seconds per problem
- Counting exercises (simple): 20 seconds
- Decomposition (recall): 15 seconds
- Multi-step problems: 45 seconds
- Configurable via `ExerciseConfig.problemTimeLimit`

**Accuracy Requirements:**
- Finale level: **Zero errors** for "completed" status
- Earlier levels: No accuracy requirement (exploration encouraged)

**Minimum Problems:**
- Finale level must have at least 10 problems for completion

---

## Exercise-Specific Completion Criteria

### C1.1: Count the Dots (V2)

**Card Levels:** 4 levels (Drag → Tap → Look → Flash)
**Finale Level:** Level 5 - Mixed review (8-12 dots, structured layouts only)

**Finished Criteria:**
- Level 1: Complete 3 problems (drag dots to counted area)
- Level 2: Complete 8 problems (tap to mark)
- Level 3: Complete 10 problems (count by looking, structured OR random)
- Level 4: Complete 10 problems (flash 2s then hide)
- Level 5: Unlock after Level 4 completion

**Completed Criteria:**
- All levels 1-5 unlocked
- Level 5: 10 problems, zero errors, <20s per problem
- **Rationale:** Simple counting should be fast

---

### C1.2: Count the Objects

**Card Levels:** 3 levels (Tap shapes → Count emoji → Flash objects)
**Finale Level:** Level 4 - Mixed objects (5-12 count, easier range)

**Finished Criteria:**
- Level 1: 3 problems (tap geometric shapes)
- Level 2: 10 problems (count emoji objects)
- Level 3: 10 problems (flash objects)
- Level 4: Unlock after Level 3

**Completed Criteria:**
- All levels 1-4 unlocked
- Level 4: 10 problems, zero errors, <20s per problem

---

### C2.1: Order Cards to 20

**Card Levels:** 3 levels (Tap sequence → Drag to sort → Memory order)
**Finale Level:** Level 4 - Order 5-7 numbers (easier than max 10)

**Finished Criteria:**
- Level 1: 3 sequences (tap in ascending order)
- Level 2: 10 sequences (drag to reorder)
- Level 3: 5 sequences (flash then recall order)
- Level 4: Unlock after Level 3

**Completed Criteria:**
- All levels 1-4 unlocked
- Level 4: 10 sequences, zero errors, <30s per sequence
- **Rationale:** Ordering requires more processing time

---

### C3.1: Count Forward to 20

**Card Levels:** 3 levels (Hop on line → Write next → Memory forward)
**Finale Level:** Level 4 - Mix of forward by 1s and 2s, within 0-15 (easier range)

**Finished Criteria:**
- Level 1: Exploration complete (3 hopping sequences)
- Level 2: 10 problems (write next numbers)
- Level 3: 10 problems (count forward from memory)
- Level 4: Unlock after Level 3

**Completed Criteria:**
- All levels 1-4 unlocked
- Level 4: 10 problems, zero errors, <25s per problem

---

### C4.1: What Comes Next?

**Card Levels:** 3 levels (Explore before/after → Write neighbors → Mixed challenges)
**Finale Level:** Level 4 - Predecessor/successor within 0-15 (easier range than 0-20)

**Finished Criteria:**
- Level 1: Exploration complete (3 number explorations)
- Level 2: 10 problems (write predecessor and successor)
- Level 3: 10 problems (mixed: before, after, or both)
- Level 4: Unlock after Level 3

**Completed Criteria:**
- All levels 1-4 unlocked
- Level 4: 10 problems, zero errors, <20s per problem
- **Rationale:** Simple recall, should be fast

---

### C10.1: Place Numbers on Line

**Card Levels:** 3 levels (Drag to position → Estimate → Mental positioning)
**Finale Level:** Level 4 - Place 5 numbers on 0-20 line (fewer numbers, easier)

**Finished Criteria:**
- Level 1: 5 problems (drag numbers to correct positions)
- Level 2: 10 problems (estimate position, validate)
- Level 3: 10 problems (hidden line, position from memory)
- Level 4: Unlock after Level 3

**Completed Criteria:**
- All levels 1-4 unlocked
- Level 4: 10 problems, zero errors, <30s per problem
- **Tolerance:** ±2 units for position accuracy (reasonable estimation)

---

### Z1: Decompose 10

**Card Levels:** 3 levels (Explore decompositions → Write equations → Find all 11)
**Finale Level:** Level 4 - Decompose 5-8 (easier numbers, same mechanics)

**Finished Criteria:**
- Level 1: Exploration complete (explored decompositions freely)
- Level 2: 10 correct decompositions (random splits)
- Level 3: Found all 11 ordered pairs (0+10 through 10+0)
- Level 4: Unlock after Level 3

**Completed Criteria:**
- All levels 1-4 unlocked
- Level 4: 10 problems (decompose 5, 6, 7, 8 in rotation), zero errors, <15s per problem
- **Rationale:** Decomposition should be instant recall

---

## Data Model Structure

### ExerciseProgress

```dart
class ExerciseProgress {
  final String exerciseId;                        // e.g., 'C1.1', 'Z1'
  final ExerciseCompletionStatus status;          // notStarted, inProgress, finished, completed
  final Map<int, LevelProgress> levelProgress;    // levelNumber → progress data
  final DateTime? firstAttemptDate;               // When user first opened exercise
  final DateTime? finishedDate;                   // When all levels unlocked
  final DateTime? completedDate;                  // When completion criteria met
  final int totalAttempts;                        // How many times exercise opened
  final double bestAccuracy;                      // Best accuracy across all levels
  final int totalTimeSeconds;                     // Cumulative time spent

  // JSON serialization
  Map<String, dynamic> toJson();
  factory ExerciseProgress.fromJson(Map<String, dynamic> json);

  // Immutable updates
  ExerciseProgress copyWith({...});
}
```

### LevelProgress

```dart
class LevelProgress {
  final int levelNumber;                          // 1-5 (finale is typically highest)
  final bool unlocked;                            // Can user access this level?
  final int correctAnswers;                       // Count of correct answers
  final int totalAttempts;                        // Count of all attempts
  final List<ProblemResult> problemResults;       // Individual problem data
  final DateTime? unlockedDate;                   // When level first unlocked
  final DateTime? masteredDate;                   // When 90%+ accuracy sustained

  // Computed properties
  double get accuracy => totalAttempts > 0 ? correctAnswers / totalAttempts : 0.0;
  double get averageTimePerProblem => _calculateAverage();
  bool get isMastered => accuracy >= 0.9 && totalAttempts >= 20;

  // JSON serialization
  Map<String, dynamic> toJson();
  factory LevelProgress.fromJson(Map<String, dynamic> json);
}
```

### ProblemResult

```dart
class ProblemResult {
  final bool correct;                             // Was answer correct?
  final int timeSeconds;                          // Time taken to solve
  final DateTime timestamp;                       // When problem was attempted
  final String? userAnswer;                       // Optional: what they entered

  // JSON serialization
  Map<String, dynamic> toJson();
  factory ProblemResult.fromJson(Map<String, dynamic> json);
}
```

---

## Persistence Pattern

### Saving Progress

**When to save:**
- On level unlock (immediate)
- Every 5 problems (batch save to reduce I/O)
- On exercise exit (WillPopScope callback)
- On completion criteria met (celebrate + save)

**How to save:**
```dart
// In exercise coordinator
Future<void> _saveProgress() async {
  final userService = UserService();
  final currentProfile = await userService.getUserById(widget.userProfile.id);

  final updatedExerciseProgress = currentProfile!.exerciseProgress ?? {};
  updatedExerciseProgress[widget.config.id] = ExerciseProgress(
    exerciseId: widget.config.id,
    status: _determineStatus(),
    levelProgress: _buildLevelProgressMap(),
    firstAttemptDate: _firstAttemptDate,
    finishedDate: _allLevelsUnlocked ? DateTime.now() : null,
    completedDate: _meetsCompletionCriteria() ? DateTime.now() : null,
    totalAttempts: _totalAttempts,
    bestAccuracy: _calculateBestAccuracy(),
    totalTimeSeconds: _totalTimeSeconds,
  );

  final updatedProfile = currentProfile.copyWith(
    exerciseProgress: updatedExerciseProgress,
  );

  await userService.saveUser(updatedProfile);
}
```

### Loading Progress

**When to load:**
- On exercise init (before first render)

**How to load:**
```dart
// In exercise coordinator initState
@override
void initState() {
  super.initState();
  _loadSavedProgress();
}

Future<void> _loadSavedProgress() async {
  final userService = UserService();
  final profile = await userService.getUserById(widget.userProfile.id);

  final savedProgress = profile?.exerciseProgress?[widget.config.id];
  if (savedProgress != null) {
    setState(() {
      _restoreFromSavedProgress(savedProgress);
    });
  }
}
```

---

## Completion Detection Logic

### Determining Status

```dart
ExerciseCompletionStatus _determineStatus() {
  final allLevelsUnlocked = _levelProgress.values.every((lp) => lp.unlocked);

  if (!allLevelsUnlocked) {
    return ExerciseCompletionStatus.inProgress;
  }

  // Check finale level completion criteria
  final finaleLevel = _levelProgress[_finaleLevelNumber];
  if (finaleLevel == null) {
    return ExerciseCompletionStatus.finished;
  }

  final finaleProblems = finaleLevel.problemResults;
  if (finaleProblems.length < 10) {
    return ExerciseCompletionStatus.finished;  // Not enough problems
  }

  // Check zero errors
  final recentFinaleProblems = finaleProblems.takeLast(10);
  final hasErrors = recentFinaleProblems.any((p) => !p.correct);
  if (hasErrors) {
    return ExerciseCompletionStatus.finished;
  }

  // Check time limits
  final timeLimit = widget.config.problemTimeLimit ?? 30;
  final tooSlow = recentFinaleProblems.any((p) => p.timeSeconds > timeLimit);
  if (tooSlow) {
    return ExerciseCompletionStatus.finished;
  }

  return ExerciseCompletionStatus.completed;  // All criteria met!
}
```

---

## Learning Path Integration

### Filtering Exercises by Status

```dart
// In ExerciseService
List<Exercise> getInProgressExercises(UserProfile profile) {
  return _allExercises.where((ex) {
    final progress = profile.exerciseProgress?[ex.id];
    return progress?.status == ExerciseCompletionStatus.inProgress;
  }).toList();
}

List<Exercise> getFinishedButNotCompleted(UserProfile profile) {
  return _allExercises.where((ex) {
    final progress = profile.exerciseProgress?[ex.id];
    return progress?.status == ExerciseCompletionStatus.finished;
  }).toList();
}
```

### Next Recommended Exercise

```dart
Exercise? getNextRecommendedExercise(UserProfile profile) {
  // Priority 1: In-progress exercises
  final inProgress = getInProgressExercises(profile);
  if (inProgress.isNotEmpty) return inProgress.first;

  // Priority 2: Not started exercises in unlocked milestones
  final notStarted = getNotStartedExercises(profile);
  final unlockedNotStarted = notStarted.where((ex) {
    return _isMilestoneUnlocked(ex, profile);
  }).toList();

  if (unlockedNotStarted.isNotEmpty) return unlockedNotStarted.first;

  // Priority 3: Finished but not completed (review for mastery)
  final needsReview = getFinishedButNotCompleted(profile);
  if (needsReview.isNotEmpty) return needsReview.first;

  return null;  // All exercises completed!
}
```

---

## Parent Dashboard Insights

### Completion Statistics

```dart
class CompletionStats {
  final int totalExercises;
  final int notStarted;
  final int inProgress;
  final int finished;
  final int completed;

  double get completionRate => completed / totalExercises;
  double get explorationRate => (inProgress + finished + completed) / totalExercises;

  String get summary {
    return '$completed completed, $finished need practice, $inProgress in progress';
  }
}
```

### Time Spent Analysis

```dart
// From ExerciseProgress
final totalMinutes = exerciseProgress.values
  .map((ep) => ep.totalTimeSeconds)
  .fold(0, (sum, time) => sum + time) ~/ 60;

print('Total practice time: $totalMinutes minutes');
```

---

## Future Enhancements (Phase 4+)

### Adaptive Time Limits

- Adjust time limits based on child's age and performance
- Younger children: +50% time (45s instead of 30s)
- Struggling exercises: Increase time limit after 3 failed attempts

### Partial Credit

- "Almost Completed": 1-2 errors in finale (instead of zero)
- Allows celebration while encouraging retry

### Streak Tracking

- Days in a row practicing
- Consecutive completions
- Motivational element

### Performance Trends

- Graph accuracy over time
- Identify exercises needing review
- Celebrate improvements

---

**Last Updated:** 2025-11-01
**Status:** Specification complete, ready for implementation
