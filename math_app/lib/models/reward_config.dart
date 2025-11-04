/// Parent-configured reward system for motivating practice.
///
/// Allows parents to:
/// - Enable/disable different reward triggers
/// - Add custom reward texts (e.g., "20 minutes of cartoons", "Ice cream cone")
/// - Track which rewards have been earned
///
/// See REWARDS_SYSTEM.md for complete specification.
class RewardConfig {
  /// Show trophy after child practices 1+ exercise per day?
  final bool dailyExerciseReward;

  /// Show trophy when child completes an exercise (zero errors + time limits)?
  final bool completedExerciseReward;

  /// Show trophy when child completes all exercises in a milestone?
  final bool milestoneReward;

  /// Parent-entered reward descriptions (max 10)
  /// Examples: "20 minutes of cartoons", "Ice cream cone", "Trip to playground"
  final List<String> rewardTexts;

  /// Map of earned rewards: rewardId → timestamp
  /// Used to track which rewards have been shown and cycle through reward texts
  final Map<String, DateTime> rewardsEarned;

  RewardConfig({
    this.dailyExerciseReward = false,
    this.completedExerciseReward = false,
    this.milestoneReward = false,
    this.rewardTexts = const [],
    this.rewardsEarned = const {},
  });

  /// Are any reward types enabled?
  bool get anyRewardsEnabled {
    return dailyExerciseReward || completedExerciseReward || milestoneReward;
  }

  /// Does parent have any reward texts configured?
  bool get hasRewardTexts {
    return rewardTexts.isNotEmpty;
  }

  /// Create from JSON
  factory RewardConfig.fromJson(Map<String, dynamic> json) {
    // Parse rewardsEarned map
    Map<String, DateTime> parsedRewardsEarned = {};
    if (json['rewardsEarned'] != null) {
      final rewardsMap = json['rewardsEarned'] as Map<String, dynamic>;
      rewardsMap.forEach((key, value) {
        parsedRewardsEarned[key] = DateTime.parse(value as String);
      });
    }

    return RewardConfig(
      dailyExerciseReward: json['dailyExerciseReward'] as bool? ?? false,
      completedExerciseReward: json['completedExerciseReward'] as bool? ?? false,
      milestoneReward: json['milestoneReward'] as bool? ?? false,
      rewardTexts: (json['rewardTexts'] as List<dynamic>?)?.cast<String>() ?? [],
      rewardsEarned: parsedRewardsEarned,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    // Convert rewardsEarned map (DateTime values to ISO strings)
    final rewardsEarnedJson = <String, String>{};
    rewardsEarned.forEach((key, value) {
      rewardsEarnedJson[key] = value.toIso8601String();
    });

    return {
      'dailyExerciseReward': dailyExerciseReward,
      'completedExerciseReward': completedExerciseReward,
      'milestoneReward': milestoneReward,
      'rewardTexts': rewardTexts,
      'rewardsEarned': rewardsEarnedJson,
    };
  }

  /// Create a copy with updated fields
  RewardConfig copyWith({
    bool? dailyExerciseReward,
    bool? completedExerciseReward,
    bool? milestoneReward,
    List<String>? rewardTexts,
    Map<String, DateTime>? rewardsEarned,
  }) {
    return RewardConfig(
      dailyExerciseReward: dailyExerciseReward ?? this.dailyExerciseReward,
      completedExerciseReward: completedExerciseReward ?? this.completedExerciseReward,
      milestoneReward: milestoneReward ?? this.milestoneReward,
      rewardTexts: rewardTexts ?? this.rewardTexts,
      rewardsEarned: rewardsEarned ?? this.rewardsEarned,
    );
  }

  /// Add a reward text (max 10)
  RewardConfig addRewardText(String text) {
    if (rewardTexts.length >= 10) {
      return this; // Max 10 rewards
    }

    final updatedTexts = [...rewardTexts, text];
    return copyWith(rewardTexts: updatedTexts);
  }

  /// Remove a reward text by index
  RewardConfig removeRewardText(int index) {
    if (index < 0 || index >= rewardTexts.length) {
      return this;
    }

    final updatedTexts = [...rewardTexts];
    updatedTexts.removeAt(index);
    return copyWith(rewardTexts: updatedTexts);
  }

  /// Mark a reward as earned
  RewardConfig markRewardEarned(String rewardType) {
    final rewardId = '${rewardType}_${DateTime.now().millisecondsSinceEpoch}';
    final updatedEarned = {...rewardsEarned, rewardId: DateTime.now()};
    return copyWith(rewardsEarned: updatedEarned);
  }

  /// Get next reward text (cycles through list)
  String getNextRewardText() {
    if (!hasRewardTexts) {
      return "Great job!"; // Default fallback
    }

    final rewardCount = rewardsEarned.length;
    final index = rewardCount % rewardTexts.length;
    return rewardTexts[index];
  }
}
