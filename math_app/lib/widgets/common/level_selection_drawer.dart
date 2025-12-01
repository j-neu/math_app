import 'package:flutter/material.dart';
import '../../models/scaffold_level.dart';

class LevelSelectionDrawer extends StatelessWidget {
  final List<ScaffoldLevel> levels;
  final ScaffoldLevel currentLevel;
  final Function(ScaffoldLevel) onLevelSelected;
  final bool Function(ScaffoldLevel) isLevelUnlocked;

  const LevelSelectionDrawer({
    super.key,
    required this.levels,
    required this.currentLevel,
    required this.onLevelSelected,
    required this.isLevelUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.layers, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'Choose Level',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Level list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: levels.length,
                itemBuilder: (context, index) {
                  final level = levels[index];
                  return _buildLevelItem(context, level);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelItem(BuildContext context, ScaffoldLevel level) {
    final unlocked = isLevelUnlocked(level);
    final isCurrent = level == currentLevel;

    // Skip advanced challenge level
    if (level == ScaffoldLevel.advancedChallenge) {
      return const SizedBox.shrink();
    }

    Color borderColor;
    Color backgroundColor;
    IconData icon;
    Color iconColor;
    FontWeight fontWeight;
    Color textColor;

    if (isCurrent) {
      borderColor = Theme.of(context).primaryColor;
      backgroundColor = Theme.of(context).primaryColor.withOpacity(0.1);
      icon = Icons.play_arrow;
      iconColor = Theme.of(context).primaryColor;
      fontWeight = FontWeight.bold;
      textColor = Theme.of(context).primaryColor;
    } else if (unlocked) {
      borderColor = Colors.grey.shade300;
      backgroundColor = Colors.white;
      icon = Icons.check_circle;
      iconColor = Colors.green;
      fontWeight = FontWeight.normal;
      textColor = Colors.black;
    } else {
      borderColor = Colors.grey.shade400;
      backgroundColor = Colors.grey.shade200;
      icon = Icons.lock;
      iconColor = Colors.grey.shade600;
      fontWeight = FontWeight.normal;
      textColor = Colors.grey.shade600;
    }

    return GestureDetector(
      onTap: () {
        if (unlocked) {
          Navigator.pop(context); // Close drawer
          onLevelSelected(level);
        } else {
          _showLockedMessage(context, level);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Text(
              'Level ${level.levelNumber}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
            if (unlocked && !isCurrent) ...[
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ],
        ),
      ),
    );
  }

  void _showLockedMessage(BuildContext context, ScaffoldLevel level) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Complete previous levels to unlock Level ${level.levelNumber}!'),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}