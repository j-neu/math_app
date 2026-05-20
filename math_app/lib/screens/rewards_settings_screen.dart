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
          content: Text('Belohnungs-Einstellungen gespeichert.'),
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
          content: Text('Bitte eine Belohnung eingeben'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (text.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belohnungstext darf höchstens 50 Zeichen haben'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_rewardTexts.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximal 10 Belohnungen möglich'),
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
        title: const Text('Belohnungen'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section 1: Reward Triggers
          Text(
            'Belohnungs-Auslöser',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wann sollen Belohnungen erscheinen?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            secondary: const Icon(Icons.calendar_today),
            title: const Text('Belohnung für tägliches Üben'),
            subtitle: const Text('Belohnung, wenn mindestens einmal am Tag geübt wird'),
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
            title: const Text('Belohnung für abgeschlossene Übungen'),
            subtitle: const Text('Belohnung, wenn eine Übung fehlerfrei gemeistert wird'),
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
            title: const Text('Meilenstein-Belohnung'),
            subtitle: const Text('Belohnung für eine ganze Kategorie (z. B. Zählen)'),
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
                'Deine Belohnungen',
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
            'Belohnungen hinzufügen, die dein Kind motivieren:',
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
                  decoration: const InputDecoration(
                    labelText: 'Belohnung hinzufügen…',
                    hintText: 'z. B. „20 Minuten Bildschirmzeit"',
                    border: OutlineInputBorder(),
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
                child: const Text('Hinzufügen'),
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
                    'Noch keine Belohnungen',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Füge Belohnungen hinzu, um dein Kind zu motivieren.',
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
            }),

          // Reward count indicator
          if (_rewardTexts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_rewardTexts.length} / 10 Belohnungen',
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
          'Beispiel-Belohnungen:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ein paar Ideen zum Loslegen:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 12),
        _buildExampleChip('20 Minuten Bildschirmzeit'),
        _buildExampleChip('Eine Kugel Eis'),
        _buildExampleChip('Ausflug zum Spielplatz'),
        _buildExampleChip('Extra Gute-Nacht-Geschichte'),
        _buildExampleChip('Sticker für das Stickerheft'),
        _buildExampleChip('Heute Abend Essen aussuchen'),
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
        title: const Text('Über Belohnungen'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'So funktionieren Belohnungen:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '1. Belohnungen hinzufügen, die dein Kind motivieren (Bildschirmzeit, Naschereien, Aktivitäten usw.).',
              ),
              SizedBox(height: 8),
              Text(
                '2. Belohnungs-Auslöser aktivieren (tägliches Üben, abgeschlossene Übungen, Meilensteine).',
              ),
              SizedBox(height: 8),
              Text(
                '3. Wenn dein Kind eine Belohnung verdient, zeigt die App eine aus deiner Liste.',
              ),
              SizedBox(height: 8),
              Text(
                '4. Wann du die Belohnung tatsächlich gibst, entscheidest du — die App feiert nur den Erfolg.',
              ),
              SizedBox(height: 16),
              Text(
                'Beispiele:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Bildschirmzeit (20 Minuten Trickfilm)'),
              Text('• Naschereien (Eis, besonderer Snack)'),
              Text('• Aktivitäten (Spielplatz, Parkbesuch)'),
              Text('• Sonderrechte (15 Minuten länger aufbleiben)'),
              Text('• Sticker oder Münzen'),
              Text('• Besondere Zeit mit Mama oder Papa'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }
}
