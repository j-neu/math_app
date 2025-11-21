# Reward System - Quick Reference

## Overview
Parent-configured reward system with three trigger types. **Full details:** `Research/REWARDS_SYSTEM.md`

---

## Three Reward Triggers

1. **Daily Exercise Reward** - Trophy after 1st exercise per day
2. **Completed Exercise Reward** - Trophy when child reaches "completed" status (zero errors + time limits)
3. **Milestone Reward** - Large trophy when all exercises in a category finished

Parents configure in Settings > Rewards, add custom reward texts (1-50 chars, max 10).

---

## Key Models & Services

### RewardConfig (part of UserProfile)
```dart
class RewardConfig {
  final bool dailyExerciseReward;
  final bool completedExerciseReward;
  final bool milestoneReward;
  final List<String> rewardTexts;           // Parent-entered rewards
  final Map<String, DateTime> rewardsEarned; // rewardId → timestamp

  bool get anyRewardsEnabled;
  bool get hasRewardTexts;
}
```

### RewardService
```dart
class RewardService {
  bool shouldShowDailyReward(UserProfile profile);
  bool shouldShowCompletedReward(UserProfile profile, String exerciseId);
  bool shouldShowMilestoneReward(UserProfile profile, Milestone milestone);
  String getNextRewardText(UserProfile profile);  // Cycles through list
  Future<void> markRewardEarned(UserProfile profile, String rewardType);
}
```

### Milestone Model
```dart
class Milestone {
  final String id;                      // 'foundation_counting'
  final String title;                   // 'Foundation Counting'
  final List<String> exerciseIds;       // Exercises in milestone
  final List<String> requiredSkillTags; // Skills covered

  static final foundationCounting = Milestone(...);
  static final numberSense = Milestone(...);
  static final placeValue = Milestone(...);
  static final allMilestones = [...];
}
```

---

## Implementation Checklist

When implementing reward system:
1. Add RewardConfig to UserProfile model
2. Create RewardService with trigger logic
3. Add Settings > Rewards screen (SwitchListTiles + TextField)
4. Display trophies on LearningPathScreen
5. Show celebration modals (daily, completed, milestone)
6. Integrate with ExerciseScreen completion flow

**See `Research/REWARDS_SYSTEM.md` for detailed UI specs, celebration modal code, and milestone definitions.**

---

**Last Updated:** 2025-11-09
