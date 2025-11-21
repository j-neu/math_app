# Parent-Configured Reward System

## Overview

This document defines the reward system that allows parents to configure motivational rewards for their children's math practice. The system supports multiple reward triggers and celebrates achievements with child-friendly displays.

**Key Principle:** Parent autonomy - parents decide what rewards work for their family, app provides the framework.

---

## Reward Triggers

Parents can enable any combination of the following reward types:

### 1. Daily Exercise Reward
**Trigger:** Child completes at least 1 exercise per day (any completion status)
**Parent Config:** Checkbox in Settings > Rewards
**Child Experience:** Trophy icon appears on learning path after first exercise
**Use Case:** Encourage daily practice habit

**Example:**
- Parent enables "Daily Exercise Reward"
- Parent adds reward text: "20 minutes of cartoons"
- Child completes C1.1 today → Trophy appears
- Child taps trophy → Celebration modal: "You practiced today! 🎉 Reward: 20 minutes of cartoons"

---

### 2. Completed Exercise Reward
**Trigger:** Child reaches "completed" status on any exercise (zero errors + time limits)
**Parent Config:** Checkbox in Settings > Rewards
**Child Experience:** Trophy icon appears on learning path after each completion
**Use Case:** Celebrate mastery and high performance

**Example:**
- Parent enables "Completed Exercise Reward"
- Parent adds reward text: "Ice cream cone"
- Child completes C1.1 with zero errors → Trophy appears
- Celebration modal: "You mastered this exercise! 🎉 Reward: Ice cream cone"

---

### 3. Milestone Reward
**Trigger:** Child completes all exercises in a milestone category (e.g., "Foundation Counting")
**Parent Config:** Checkbox in Settings > Rewards
**Child Experience:** Large trophy at milestone marker on learning path
**Use Case:** Celebrate major learning achievements

**Example:**
- Parent enables "Milestone Reward"
- Parent adds reward text: "Trip to the playground"
- Child completes all 6 Foundation Counting exercises → Large trophy appears
- Celebration modal: "You mastered Counting! 🎉 Reward: Trip to the playground"

**Milestones Defined:**
- Foundation Counting (counting_1 through counting_11)
- Number Sense (decomposition_1 through decomposition_16)
- Place Value (place_value_1 through place_value_6)
- Basic Strategies (basic_strategy_1 through basic_strategy_23)
- Combined Strategies (combined_strategy_1 through combined_strategy_20)

---

## Parent Configuration UI

### Settings > Rewards Screen

**Location:** Settings screen, new section after "Lock Exercises in Order"

**UI Structure:**
```
AppBar: "Reward Settings"

Section 1: Reward Triggers
├─ SwitchListTile: "Daily Exercise Reward"
│  └─ Subtitle: "Reward for practicing at least once per day"
├─ SwitchListTile: "Completed Exercise Reward"
│  └─ Subtitle: "Reward for mastering an exercise with zero errors"
├─ SwitchListTile: "Milestone Reward"
│  └─ Subtitle: "Reward for completing a skill category (e.g., Counting)"

Divider

Section 2: Reward Texts
├─ Header: "Your Rewards" + Info icon
│  └─ Info dialog: "Enter rewards that motivate your child. Examples: screen time, treats, activities, stickers"
├─ TextField: "Add a reward..." + Add button
│  └─ Max 50 characters, validates non-empty
├─ List of current rewards (up to 10):
│  ├─ "20 minutes of cartoons" [Delete icon]
│  ├─ "Ice cream cone" [Delete icon]
│  └─ "Trip to the playground" [Delete icon]

Divider

Section 3: Earned Rewards (optional future feature)
├─ ListTile: "View Earned Rewards"
│  └─ Shows list of rewards child has earned (not implemented in v1)
```

**Validation Rules:**
- Reward text: 1-50 characters
- Maximum 10 reward texts
- At least one reward trigger must be enabled to show rewards on learning path

**Save Pattern:**
- Changes save immediately to UserProfile via UserService
- Snackbar confirmation: "Reward settings saved!"

---

## Data Model

### RewardConfig

```dart
class RewardConfig {
  final bool dailyExerciseReward;           // Show trophy after 1 exercise/day?
  final bool completedExerciseReward;       // Show trophy on each "completed"?
  final bool milestoneReward;               // Show trophy at milestone completion?
  final List<String> rewardTexts;           // Parent-entered reward descriptions
  final Map<String, DateTime> rewardsEarned; // rewardId → timestamp earned

  // Computed properties
  bool get anyRewardsEnabled => dailyExerciseReward || completedExerciseReward || milestoneReward;
  bool get hasRewardTexts => rewardTexts.isNotEmpty;

  // JSON serialization
  Map<String, dynamic> toJson();
  factory RewardConfig.fromJson(Map<String, dynamic> json);

  // Immutable updates
  RewardConfig copyWith({...});
}
```

**Storage:** Part of UserProfile model

```dart
// In UserProfile
final RewardConfig? rewardConfig;
```

---

## Reward Calculation Logic

### RewardService

```dart
class RewardService {
  /// Check if daily exercise reward should be shown
  bool shouldShowDailyReward(UserProfile profile) {
    if (!profile.rewardConfig?.dailyExerciseReward ?? false) return false;

    final today = DateTime.now();
    final lastSession = profile.lastSessionDate;

    // Has child practiced today?
    if (lastSession == null) return false;
    if (!_isSameDay(lastSession, today)) return false;

    // Count exercises completed today
    final completedToday = profile.exercisesCompletedToday;
    return completedToday >= 1;
  }

  /// Check if completed exercise reward should be shown
  bool shouldShowCompletedReward(UserProfile profile, String exerciseId) {
    if (!profile.rewardConfig?.completedExerciseReward ?? false) return false;

    final progress = profile.exerciseProgress?[exerciseId];
    return progress?.status == ExerciseCompletionStatus.completed;
  }

  /// Check if milestone reward should be shown
  bool shouldShowMilestoneReward(UserProfile profile, Milestone milestone) {
    if (!profile.rewardConfig?.milestoneReward ?? false) return false;

    return _isMilestoneComplete(milestone, profile);
  }

  /// Get next reward text (cycles through list)
  String getNextRewardText(UserProfile profile) {
    final texts = profile.rewardConfig?.rewardTexts ?? [];
    if (texts.isEmpty) return "Great job!";

    final rewardCount = profile.rewardConfig?.rewardsEarned.length ?? 0;
    final index = rewardCount % texts.length;
    return texts[index];
  }

  /// Mark reward as shown/earned
  Future<void> markRewardEarned(UserProfile profile, String rewardType) async {
    final rewardId = '${rewardType}_${DateTime.now().millisecondsSinceEpoch}';
    final updatedEarned = {...profile.rewardConfig?.rewardsEarned ?? {}};
    updatedEarned[rewardId] = DateTime.now();

    final updatedConfig = profile.rewardConfig?.copyWith(
      rewardsEarned: updatedEarned,
    );

    final updatedProfile = profile.copyWith(rewardConfig: updatedConfig);
    await UserService().saveUser(updatedProfile);
  }

  // Helper methods
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isMilestoneComplete(Milestone milestone, UserProfile profile) {
    return milestone.exerciseIds.every((exId) {
      final progress = profile.exerciseProgress?[exId];
      return progress?.status == ExerciseCompletionStatus.completed;
    });
  }
}
```

---

## Learning Path Display

### Trophy Icon Placement

**When to show trophy:**
1. **Daily Reward:** After first exercise completed today
   - Placement: Top of learning path, in progress overview card
   - Icon: Gold trophy (`Icons.emoji_events`, color: Colors.amber)

2. **Completed Exercise Reward:** Immediately after exercise completion
   - Placement: Celebration modal (pops up automatically)
   - Icon: Star trophy (animated pulse)

3. **Milestone Reward:** At milestone section when complete
   - Placement: Special milestone completion node on vertical path
   - Icon: Large crown trophy (`Icons.emoji_events`, size: 60)

**Visual Design:**
```dart
// Trophy icon in progress card
Icon(
  Icons.emoji_events,
  color: Colors.amber,
  size: 32,
)

// Milestone trophy (larger)
Icon(
  Icons.emoji_events,
  color: Colors.amber,
  size: 60,
)
```

### Progress Overview Card (Updated)

```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        // Progress bar
        LinearProgressIndicator(value: progress),

        SizedBox(height: 16),

        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$completedExercises/$totalExercises completed'),

            // Trophy if daily reward earned
            if (shouldShowDailyReward)
              GestureDetector(
                onTap: _showDailyRewardCelebration,
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                    SizedBox(width: 4),
                    Text('Reward!', style: TextStyle(color: Colors.amber)),
                  ],
                ),
              ),
          ],
        ),
      ],
    ),
  ),
)
```

---

## Celebration Modals

### Daily Reward Celebration

```dart
void _showDailyRewardCelebration() {
  final rewardText = RewardService().getNextRewardText(userProfile);

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          Icon(Icons.emoji_events, size: 80, color: Colors.amber),
          SizedBox(height: 16),
          Text(
            '🎉 You practiced today! 🎉',
            style: TextStyle(fontSize: 24, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reward:',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Text(
              rewardText,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: Text('Celebrate! 🎊', style: TextStyle(fontSize: 18)),
        ),
      ],
    ),
  );
}
```

### Completed Exercise Celebration

**Trigger:** Immediately after exercise completion (from ExerciseScreen)

```dart
void _onExerciseCompleted(ExerciseProgress progress) async {
  // Save progress
  final updatedProfile = await _saveExerciseProgress(progress);

  // Check for reward
  final rewardService = RewardService();
  if (rewardService.shouldShowCompletedReward(updatedProfile, exerciseId)) {
    await _showCompletedRewardCelebration();
    await rewardService.markRewardEarned(updatedProfile, 'completed_exercise');
  }

  // Navigate back
  Navigator.pop(context);
}

Future<void> _showCompletedRewardCelebration() async {
  final rewardText = RewardService().getNextRewardText(widget.userProfile);

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.green.withOpacity(0.95),
      title: Column(
        children: [
          // Animated star trophy
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Icon(Icons.stars, size: 100, color: Colors.amber),
              );
            },
          ),
          SizedBox(height: 16),
          Text(
            '🌟 Exercise Mastered! 🌟',
            style: TextStyle(fontSize: 26, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Zero errors! Great job!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),
            Text(
              'Reward:',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Text(
              rewardText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
            child: Text('Amazing! 🎉', style: TextStyle(fontSize: 20)),
          ),
        ),
      ],
    ),
  );
}
```

### Milestone Celebration

**Trigger:** When navigating to learning path and milestone just completed

```dart
void _checkMilestoneCompletion() {
  final rewardService = RewardService();

  for (final milestone in Milestone.allMilestones) {
    if (rewardService.shouldShowMilestoneReward(userProfile, milestone)) {
      final alreadyShown = _hasShownMilestone(milestone.id);
      if (!alreadyShown) {
        _showMilestoneCelebration(milestone);
        _markMilestoneShown(milestone.id);
        break;  // Only show one at a time
      }
    }
  }
}

Future<void> _showMilestoneCelebration(Milestone milestone) async {
  final rewardText = RewardService().getNextRewardText(userProfile);

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.95),
      title: Column(
        children: [
          Icon(Icons.emoji_events, size: 120, color: Colors.amber),
          SizedBox(height: 20),
          Text(
            '🏆 ${milestone.title} Complete! 🏆',
            style: TextStyle(fontSize: 28, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You mastered all ${milestone.exerciseIds.length} exercises!',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Divider(thickness: 2),
            SizedBox(height: 20),
            Text(
              'Special Reward:',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            SizedBox(height: 12),
            Text(
              rewardText,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: EdgeInsets.symmetric(horizontal: 48, vertical: 18),
            ),
            child: Text(
              'Incredible! 🎊',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );
}
```

---

## Milestone Definitions

### Milestone Model

```dart
class Milestone {
  final String id;                          // e.g., 'foundation_counting'
  final String title;                       // e.g., 'Foundation Counting'
  final String description;                 // What this milestone represents
  final List<String> requiredSkillTags;     // Skills covered (e.g., ['counting_1', 'counting_2'])
  final List<String> exerciseIds;           // Exercises in this milestone
  final IconData icon;                      // Display icon

  // Predefined milestones
  static final foundationCounting = Milestone(
    id: 'foundation_counting',
    title: 'Foundation Counting',
    description: 'Counting objects, ordering numbers, and number sequences',
    requiredSkillTags: ['counting_1', 'counting_2', 'counting_3', 'counting_4', 'counting_5', 'counting_10', 'counting_11'],
    exerciseIds: ['C1.1', 'C1.2', 'C2.1', 'C3.1', 'C4.1', 'C10.1'],
    icon: Icons.onetwothree,
  );

  static final numberSense = Milestone(
    id: 'number_sense',
    title: 'Number Sense',
    description: 'Decomposing numbers and recognizing patterns',
    requiredSkillTags: ['decomposition_1', 'decomposition_2', 'decomposition_3', 'decomposition_4', 'decomposition_5', 'decomposition_6', 'decomposition_7', 'decomposition_8', 'decomposition_11', 'decomposition_15', 'decomposition_16'],
    exerciseIds: ['Z1', 'Z1.1', 'Z1.2', 'Z1.4', 'Z1.5', 'Z2.2', 'Z3.1', 'Z3.2'],
    icon: Icons.psychology,
  );

  static final placeValue = Milestone(
    id: 'place_value',
    title: 'Place Value',
    description: 'Understanding tens and ones, bundling, place value notation',
    requiredSkillTags: ['place_value_1', 'place_value_2', 'place_value_3', 'place_value_4', 'place_value_5', 'place_value_6'],
    exerciseIds: ['P1.1', 'P1.2', 'P2.1', 'P2.2', 'P3.1', 'P4.1', 'P4.2', 'P5.1', 'P6.1', 'P6.2'],
    icon: Icons.grid_3x3,
  );

  // All milestones
  static final allMilestones = [
    foundationCounting,
    numberSense,
    placeValue,
    // ... add more as exercises are implemented
  ];
}
```

---

## Learning Path Integration

### Milestone Section Header

```dart
Widget _buildMilestoneSection(Milestone milestone) {
  final progress = _calculateMilestoneProgress(milestone);
  final isComplete = progress >= 1.0;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Milestone header
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isComplete ? Colors.green.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(milestone.icon, size: 32, color: isComplete ? Colors.green : Colors.grey[700]),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.title,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    milestone.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Trophy if milestone complete and rewards enabled
            if (isComplete && _shouldShowMilestoneTrophy)
              Icon(Icons.emoji_events, size: 40, color: Colors.amber),
          ],
        ),
      ),

      SizedBox(height: 8),

      // Progress bar
      LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey[300],
        color: isComplete ? Colors.green : Theme.of(context).colorScheme.primary,
      ),

      SizedBox(height: 8),

      Text(
        '${(progress * 100).toInt()}% complete',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),

      SizedBox(height: 16),

      // Exercises in this milestone (left-right alternating)
      _buildMilestoneExercises(milestone),
    ],
  );
}
```

---

## Future Enhancements (Phase 4+)

### Photo Rewards
- Allow parents to upload photos of rewards
- Display images instead of text in celebration modals
- Good for non-readers or visual learners

### Reward Redemption Tracking
- Parent checkbox: "Reward given"
- Track which rewards have been redeemed
- Show "Pending" rewards to parents

### Custom Milestone Creation
- Parents define custom milestones (e.g., "Week 1 Complete")
- Select which exercises to include
- Set custom reward for that milestone

### Reward Scheduling
- Time-based rewards (e.g., "After 7 days of practice")
- Streak-based rewards (e.g., "5 days in a row")
- Total exercise count (e.g., "After 20 exercises completed")

---

**Last Updated:** 2025-11-01
**Status:** Specification complete, ready for implementation
