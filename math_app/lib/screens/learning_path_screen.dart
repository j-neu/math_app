import 'package:flutter/material.dart';
import 'package:math_app/models/user_profile.dart';
import 'package:math_app/models/exercise.dart';
import 'package:math_app/models/exercise_progress.dart';
import 'package:math_app/models/milestone.dart';
import 'package:math_app/services/exercise_service.dart';
import 'package:math_app/services/reward_service.dart';
import 'package:math_app/services/user_service.dart';
import 'package:math_app/screens/exercise_screen.dart';
import 'package:math_app/screens/settings_screen.dart';

/// Learning Path Screen with milestone grouping and reward celebrations
///
/// Features:
/// - Vertical scrolling layout with milestone sections
/// - Progress overview card with daily reward trophy
/// - Exercise cards with visual states (completed, finished, in-progress, locked)
/// - Reward celebration modals (daily, completed, milestone)
/// - Left-right alternating exercise card layout
class LearningPathScreen extends StatefulWidget {
  final UserProfile userProfile;

  const LearningPathScreen({super.key, required this.userProfile});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final RewardService _rewardService = RewardService();
  final Set<String> _shownMilestones = {};

  // DEVELOPMENT MODE: Set to true to show ALL exercises regardless of skill tags
  bool _showAllExercises = true;

  @override
  void initState() {
    super.initState();
    // Check for milestone completions after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMilestoneCompletions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupedExercises =
        _exerciseService.getLearningPathGroupedByMilestone(
          widget.userProfile,
          showAll: _showAllExercises,
        );
    final completedCount =
        _exerciseService.getCompletedExercises(widget.userProfile).length;
    final totalCount = _exerciseService.getAllExercises().length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userProfile.name}\'s Learning Path'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Development mode toggle - shows ALL exercises
          IconButton(
            icon: Icon(_showAllExercises ? Icons.visibility : Icons.visibility_off),
            tooltip: _showAllExercises ? 'Showing all exercises' : 'Showing matched exercises only',
            onPressed: () {
              setState(() {
                _showAllExercises = !_showAllExercises;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsScreen(userProfile: widget.userProfile),
                ),
              );
              // Refresh on return from settings
              setState(() {});
            },
          ),
        ],
      ),
      body: groupedExercises.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress overview card
                  _buildProgressCard(progress, completedCount, totalCount),
                  const SizedBox(height: 24),

                  // Milestone sections
                  ...groupedExercises.entries.map((entry) {
                    final milestone = entry.key;
                    final exercises = entry.value;
                    return _buildMilestoneSection(milestone, exercises);
                  }).toList(),
                ],
              ),
            ),
    );
  }

  /// Build progress overview card with daily reward trophy
  Widget _buildProgressCard(double progress, int completed, int total) {
    final shouldShowDailyReward =
        _rewardService.shouldShowDailyReward(widget.userProfile);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 16,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completed / $total exercises completed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
                // Daily reward trophy
                if (shouldShowDailyReward)
                  GestureDetector(
                    onTap: _showDailyRewardCelebration,
                    child: Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Colors.amber[700],
                          size: 24,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reward!',
                          style: TextStyle(
                            color: Colors.amber[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build milestone section with progress bar and exercises
  Widget _buildMilestoneSection(Milestone milestone, List<Exercise> exercises) {
    final progress = _exerciseService.getMilestoneProgress(
      milestone,
      widget.userProfile,
    );
    final isComplete = _exerciseService.isMilestoneComplete(
      milestone,
      widget.userProfile,
    );
    final shouldShowTrophy = isComplete &&
        _rewardService.shouldShowMilestoneReward(
          widget.userProfile,
          milestone,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Milestone header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isComplete
                ? Colors.green.withOpacity(0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                milestone.icon,
                size: 32,
                color: isComplete ? Colors.green : Colors.grey[700],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      milestone.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      milestone.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Trophy if milestone complete
              if (shouldShowTrophy)
                GestureDetector(
                  onTap: () => _showMilestoneCelebration(milestone),
                  child: Icon(
                    Icons.emoji_events,
                    size: 40,
                    color: Colors.amber[700],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Progress bar
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          color: isComplete
              ? Colors.green
              : Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).toInt()}% complete',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),

        // Exercises in milestone (left-right alternating)
        ...exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value;
          final isLeft = index % 2 == 0;
          return _buildExerciseCard(exercise, isLeft);
        }).toList(),

        const SizedBox(height: 24),
      ],
    );
  }

  /// Build exercise card with visual state indicators
  Widget _buildExerciseCard(Exercise exercise, bool isLeft) {
    final exerciseProgress =
        widget.userProfile.exerciseProgress?[exercise.id];
    final status =
        exerciseProgress?.status ?? ExerciseCompletionStatus.notStarted;

    // Visual styling based on status
    Color backgroundColor;
    Color borderColor;
    IconData iconData;
    String statusLabel;
    double opacity;

    switch (status) {
      case ExerciseCompletionStatus.completed:
        backgroundColor = Colors.green.withOpacity(0.1);
        borderColor = Colors.green;
        iconData = Icons.check_circle;
        statusLabel = 'Mastered!';
        opacity = 1.0;
        break;
      case ExerciseCompletionStatus.finished:
        backgroundColor = Colors.blue.withOpacity(0.1);
        borderColor = Colors.blue;
        iconData = Icons.check;
        statusLabel = 'Practice Again';
        opacity = 0.9;
        break;
      case ExerciseCompletionStatus.inProgress:
        backgroundColor = Colors.cyan.withOpacity(0.1);
        borderColor = Colors.cyan;
        iconData = Icons.arrow_forward;
        statusLabel = 'Continue';
        opacity = 1.0;
        break;
      case ExerciseCompletionStatus.notStarted:
      default:
        backgroundColor = Colors.grey.withOpacity(0.05);
        borderColor = Colors.grey;
        iconData = Icons.circle_outlined;
        statusLabel = 'Start';
        opacity = 0.5;
        break;
    }

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: isLeft ? 0 : 40,
          right: isLeft ? 40 : 0,
        ),
        child: Card(
          elevation: status == ExerciseCompletionStatus.inProgress ? 4 : 1,
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _navigateToExercise(exercise),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Icon
                  CircleAvatar(
                    backgroundColor: borderColor,
                    child: Icon(iconData, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: borderColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  Icon(Icons.chevron_right, color: borderColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build empty state when no exercises available
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.userProfile.skillTags.isEmpty
                ? 'Complete the diagnostic test to start'
                : 'Great job! You\'ve completed all current exercises',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Navigate to exercise and check for rewards on return
  Future<void> _navigateToExercise(Exercise exercise) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseScreen(
          userProfile: widget.userProfile,
          exerciseOverride: exercise,
        ),
      ),
    );
    // Refresh UI and check for completion rewards
    setState(() {});
    await _checkCompletionReward(exercise.id);
  }

  /// Check if exercise was just completed and show reward
  Future<void> _checkCompletionReward(String exerciseId) async {
    // Reload user profile to get latest progress
    final userService = UserService();
    final freshProfile = await userService.getUserById(widget.userProfile.id);

    if (freshProfile == null) {
      print('[LearningPath] _checkCompletionReward: freshProfile is null');
      return;
    }

    print('[LearningPath] _checkCompletionReward for $exerciseId');
    print('[LearningPath] Exercise status: ${freshProfile.exerciseProgress?[exerciseId]?.status}');
    print('[LearningPath] Rewards enabled: ${freshProfile.rewardConfig?.completedExerciseReward}');

    if (_rewardService.shouldShowCompletedReward(
      freshProfile,
      exerciseId,
    )) {
      print('[LearningPath] Showing completion celebration!');
      await _showCompletedRewardCelebration(exerciseId);
      await _rewardService.markRewardEarned(
        freshProfile,
        'completed_exercise',
      );
      // Refresh UI with updated profile
      setState(() {});
    } else {
      print('[LearningPath] Reward not shown (either not enabled or not completed)');
    }
  }

  /// Check for newly completed milestones
  Future<void> _checkMilestoneCompletions() async {
    for (final milestone in Milestone.allMilestones) {
      if (_rewardService.shouldShowMilestoneReward(
        widget.userProfile,
        milestone,
      )) {
        final alreadyShown = _shownMilestones.contains(milestone.id);
        if (!alreadyShown) {
          await _showMilestoneCelebration(milestone);
          _shownMilestones.add(milestone.id);
          await _rewardService.markRewardEarned(
            widget.userProfile,
            'milestone_${milestone.id}',
          );
          break; // Only show one at a time
        }
      }
    }
  }

  /// Show daily reward celebration modal
  Future<void> _showDailyRewardCelebration() async {
    final rewardText = _rewardService.getNextRewardText(widget.userProfile);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor:
            Theme.of(context).colorScheme.secondary.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.emoji_events, size: 80, color: Colors.amber[700]),
            const SizedBox(height: 16),
            const Text(
              '🎉 You practiced today! 🎉',
              style: TextStyle(fontSize: 24, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 8),
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
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Celebrate! 🎊',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show completed exercise reward celebration modal
  Future<void> _showCompletedRewardCelebration(String exerciseId) async {
    final rewardText = _rewardService.getNextRewardText(widget.userProfile);
    final exercise = _exerciseService.getExerciseById(exerciseId);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.green.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            // Animated star trophy
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(Icons.stars, size: 100, color: Colors.amber[700]),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              '🌟 Exercise Mastered! 🌟',
              style: TextStyle(fontSize: 26, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You completed: ${exercise?.title ?? 'Exercise'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Zero errors! Great job!',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Reward:',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
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
                backgroundColor: Colors.amber[700],
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: const Text(
                'Amazing! 🎉',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show milestone reward celebration modal
  Future<void> _showMilestoneCelebration(Milestone milestone) async {
    final rewardText = _rewardService.getNextRewardText(widget.userProfile);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor:
            Theme.of(context).colorScheme.primary.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.emoji_events, size: 120, color: Colors.amber[700]),
            const SizedBox(height: 20),
            Text(
              '🏆 ${milestone.title} Complete! 🏆',
              style: const TextStyle(fontSize: 28, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You mastered all ${milestone.exerciseIds.length} exercises!',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Divider(thickness: 2),
              const SizedBox(height: 20),
              Text(
                'Special Reward:',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
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
                backgroundColor: Colors.amber[700],
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
              ),
              child: const Text(
                'Incredible! 🎊',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
