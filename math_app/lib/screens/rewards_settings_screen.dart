import 'package:flutter/material.dart';
import 'package:math_app/models/user_profile.dart';
import 'package:math_app/models/reward_config.dart';
import 'package:math_app/services/user_service.dart';

/// Rewards Settings Screen
///
/// Allows parents to configure:
/// - Reward triggers (daily, completed exercise, milestone)
/// - Reward texts (up to 10 custom rewards)
///
/// See REWARDS_SYSTEM.md for complete specification.
class RewardsSettingsScreen extends StatefulWidget {
  final UserProfile userProfile;

  const RewardsSettingsScreen({super.key, required this.userProfile});

  @override
  State<RewardsSettingsScreen> createState() => _RewardsSettingsScreenState();
}

class _RewardsSettingsScreenState extends State<RewardsSettingsScreen> {
  final UserService _userService = UserService();
  final TextEditingController _rewardController = TextEditingController();

  late bool _dailyExerciseReward;
  late bool _completedExerciseReward;
  late bool _milestoneReward;
  late List<String> _rewardTexts;

  @override
  void initState() {
    super.initState();
    // Initialize from user profile
    final config = widget.userProfile.rewardConfig;
    _dailyExerciseReward = config?.dailyExerciseReward ?? false;
    _completedExerciseReward = config?.completedExerciseReward ?? false;
    _milestoneReward = config?.milestoneReward ?? false;
    _rewardTexts = List.from(config?.rewardTexts ?? []);
  }

  @override
  void dispose() {
    _rewardController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final updatedConfig = RewardConfig(
      dailyExerciseReward: _dailyExerciseReward,
      completedExerciseReward: _completedExerciseReward,
      milestoneReward: _milestoneReward,
      rewardTexts: _rewardTexts,
      rewardsEarned: widget.userProfile.rewardConfig?.rewardsEarned ?? {},
    );

    final updatedProfile = widget.userProfile.copyWith(
      rewardConfig: updatedConfig,
    );

    await _userService.saveUser(updatedProfile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reward settings saved!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _addRewardText() {
    final text = _rewardController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reward'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (text.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reward text must be 50 characters or less'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_rewardTexts.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 rewards allowed'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _rewardTexts.add(text);
      _rewardController.clear();
    });

    _saveSettings();
  }

  void _removeRewardText(int index) {
    setState(() {
      _rewardTexts.removeAt(index);
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reward Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section 1: Reward Triggers
          Text(
            'Reward Triggers',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose when to show rewards to your child:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            secondary: const Icon(Icons.calendar_today),
            title: const Text('Daily Exercise Reward'),
            subtitle: const Text('Reward for practicing at least once per day'),
            value: _dailyExerciseReward,
            onChanged: (value) {
              setState(() {
                _dailyExerciseReward = value;
              });
              _saveSettings();
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.star),
            title: const Text('Completed Exercise Reward'),
            subtitle: const Text('Reward for mastering an exercise with zero errors'),
            value: _completedExerciseReward,
            onChanged: (value) {
              setState(() {
                _completedExerciseReward = value;
              });
              _saveSettings();
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.emoji_events),
            title: const Text('Milestone Reward'),
            subtitle: const Text('Reward for completing a skill category (e.g., Counting)'),
            value: _milestoneReward,
            onChanged: (value) {
              setState(() {
                _milestoneReward = value;
              });
              _saveSettings();
            },
          ),
          const Divider(height: 32),

          // Section 2: Reward Texts
          Row(
            children: [
              Text(
                'Your Rewards',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                onPressed: _showRewardInfoDialog,
                tooltip: 'Info',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add rewards that motivate your child:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),

          // Add reward input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rewardController,
                  maxLength: 50,
                  decoration: InputDecoration(
                    labelText: 'Add a reward...',
                    hintText: 'e.g., "20 minutes of screen time"',
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                  onSubmitted: (_) => _addRewardText(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addRewardText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Reward list
          if (_rewardTexts.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.card_giftcard, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No rewards added yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add rewards to motivate your child!',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._rewardTexts.asMap().entries.map((entry) {
              final index = entry.key;
              final reward = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber[700],
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(reward),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => _removeRewardText(index),
                  ),
                ),
              );
            }).toList(),

          // Reward count indicator
          if (_rewardTexts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_rewardTexts.length} / 10 rewards',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),

          const SizedBox(height: 32),

          // Example rewards
          if (_rewardTexts.isEmpty) _buildExampleRewards(),
        ],
      ),
    );
  }

  Widget _buildExampleRewards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Example Rewards:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Here are some ideas to get you started:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 12),
        _buildExampleChip('20 minutes of screen time'),
        _buildExampleChip('Ice cream cone'),
        _buildExampleChip('Trip to the playground'),
        _buildExampleChip('Extra story at bedtime'),
        _buildExampleChip('Sticker for sticker chart'),
        _buildExampleChip('Choose tonight\'s dinner'),
      ],
    );
  }

  Widget _buildExampleChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Chip(
        avatar: const Icon(Icons.lightbulb_outline, size: 16),
        label: Text(text),
        backgroundColor: Colors.blue[50],
      ),
    );
  }

  void _showRewardInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Rewards'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How Rewards Work:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '1. Add rewards that motivate your child (screen time, treats, activities, etc.)',
              ),
              SizedBox(height: 8),
              Text(
                '2. Enable reward triggers (daily practice, exercise completion, milestones)',
              ),
              SizedBox(height: 8),
              Text(
                '3. When your child earns a reward, the app will cycle through your list of rewards',
              ),
              SizedBox(height: 8),
              Text(
                '4. You decide when to actually give the reward - the app just celebrates the achievement!',
              ),
              SizedBox(height: 16),
              Text(
                'Examples:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Screen time (20 minutes of cartoons)'),
              Text('• Treats (ice cream, special snack)'),
              Text('• Activities (playground, park visit)'),
              Text('• Privileges (stay up 15 min late)'),
              Text('• Stickers or tokens'),
              Text('• Special time with parent'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
