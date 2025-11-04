import '../models/user_profile.dart';
import '../models/exercise_progress.dart';
import '../models/milestone.dart';
import 'user_service.dart';

/// Service for managing parent-configured reward system
///
/// Handles reward eligibility checks, text cycling, and reward tracking.
/// See REWARDS_SYSTEM.md for complete specification.
class RewardService {
  final UserService _userService = UserService();

  /// Check if daily exercise reward should be shown
  ///
  /// Returns true if:
  /// - Daily reward is enabled in config
  /// - Child has completed at least 1 exercise today
  bool shouldShowDailyReward(UserProfile profile) {
    if (!(profile.rewardConfig?.dailyExerciseReward ?? false)) {
      return false;
    }

    final today = DateTime.now();
    final lastSession = profile.lastSessionDate;

    // Has child practiced today?
    if (lastSession == null) return false;
    if (!_isSameDay(lastSession, today)) return false;

    // Count exercises completed today
    final completedToday = profile.exercisesCompletedToday ?? 0;
    return completedToday >= 1;
  }

  /// Check if completed exercise reward should be shown
  ///
  /// Returns true if:
  /// - Completed exercise reward is enabled in config
  /// - Exercise has "completed" status (not just "finished")
  bool shouldShowCompletedReward(UserProfile profile, String exerciseId) {
    if (!(profile.rewardConfig?.completedExerciseReward ?? false)) {
      return false;
    }

    final progress = profile.exerciseProgress?[exerciseId];
    return progress?.status == ExerciseCompletionStatus.completed;
  }

  /// Check if milestone reward should be shown
  ///
  /// Returns true if:
  /// - Milestone reward is enabled in config
  /// - All exercises in milestone are completed
  bool shouldShowMilestoneReward(UserProfile profile, Milestone milestone) {
    if (!(profile.rewardConfig?.milestoneReward ?? false)) {
      return false;
    }

    return _isMilestoneComplete(milestone, profile);
  }

  /// Get next reward text (cycles through list)
  ///
  /// If no reward texts configured, returns generic "Great job!"
  /// Otherwise cycles through reward texts based on total rewards earned.
  String getNextRewardText(UserProfile profile) {
    final texts = profile.rewardConfig?.rewardTexts ?? [];
    if (texts.isEmpty) return "Great job!";

    final rewardCount = profile.rewardConfig?.rewardsEarned.length ?? 0;
    final index = rewardCount % texts.length;
    return texts[index];
  }

  /// Mark reward as shown/earned
  ///
  /// Saves reward timestamp to UserProfile for tracking and text cycling.
  ///
  /// [rewardType]: 'daily', 'completed_exercise', or 'milestone'
  Future<void> markRewardEarned(
    UserProfile profile,
    String rewardType,
  ) async {
    final rewardId = '${rewardType}_${DateTime.now().millisecondsSinceEpoch}';
    final updatedEarned = {
      ...profile.rewardConfig?.rewardsEarned ?? {},
    };
    updatedEarned[rewardId] = DateTime.now();

    final updatedConfig = profile.rewardConfig?.copyWith(
      rewardsEarned: updatedEarned,
    );

    final updatedProfile = profile.copyWith(rewardConfig: updatedConfig);
    await _userService.saveUser(updatedProfile);
  }

  /// Check if any rewards are enabled
  ///
  /// Returns true if at least one reward type is enabled in config.
  bool hasRewardsEnabled(UserProfile profile) {
    return profile.rewardConfig?.anyRewardsEnabled ?? false;
  }

  /// Check if reward texts are configured
  ///
  /// Returns true if parent has added at least one reward text.
  bool hasRewardTexts(UserProfile profile) {
    return profile.rewardConfig?.hasRewardTexts ?? false;
  }

  // Helper methods

  /// Check if two dates are on the same calendar day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Check if milestone is complete (all exercises completed)
  bool _isMilestoneComplete(Milestone milestone, UserProfile profile) {
    return milestone.exerciseIds.every((exId) {
      final progress = profile.exerciseProgress?[exId];
      return progress?.status == ExerciseCompletionStatus.completed;
    });
  }

  /// Get milestone progress (0.0 to 1.0)
  ///
  /// Returns the fraction of exercises completed in the milestone.
  double getMilestoneProgress(Milestone milestone, UserProfile profile) {
    if (milestone.exerciseIds.isEmpty) return 0.0;

    final completedCount = milestone.exerciseIds.where((exId) {
      final progress = profile.exerciseProgress?[exId];
      return progress?.status == ExerciseCompletionStatus.completed;
    }).length;

    return completedCount / milestone.exerciseIds.length;
  }

  /// Get list of completed milestones
  List<Milestone> getCompletedMilestones(UserProfile profile) {
    return Milestone.allMilestones
        .where((m) => _isMilestoneComplete(m, profile))
        .toList();
  }

  /// Get list of in-progress milestones (at least one exercise started)
  List<Milestone> getInProgressMilestones(UserProfile profile) {
    return Milestone.allMilestones.where((m) {
      final progress = getMilestoneProgress(m, profile);
      return progress > 0.0 && progress < 1.0;
    }).toList();
  }
}
