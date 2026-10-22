import 'package:flutter/material.dart';

/// Child-facing controls under a diagnostic question: replay the question,
/// ask for help (up to three stages), and replay any revealed hint.
/// Big targets: these children are not confident with devices.
class HelpPanel extends StatelessWidget {
  final List<String> hints;
  final int revealed;
  final VoidCallback onReplayQuestion;
  final VoidCallback onRequestHelp;
  final ValueChanged<int> onReplayHint;

  const HelpPanel({
    super.key,
    required this.hints,
    required this.revealed,
    required this.onReplayQuestion,
    required this.onRequestHelp,
    required this.onReplayHint,
  });

  @override
  Widget build(BuildContext context) {
    final shown = hints.take(revealed).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            FilledButton.tonalIcon(
              key: const ValueKey('replay_question'),
              style: FilledButton.styleFrom(minimumSize: const Size(160, 64)),
              icon: const Icon(Icons.volume_up, size: 32),
              label:
                  const Text('Nochmal hören', style: TextStyle(fontSize: 20)),
              onPressed: onReplayQuestion,
            ),
            if (revealed < hints.length)
              FilledButton.icon(
                key: const ValueKey('request_help'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(160, 64),
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.lightbulb, size: 32),
                label: const Text('Hilfe', style: TextStyle(fontSize: 20)),
                onPressed: onRequestHelp,
              ),
          ],
        ),
        for (var i = 0; i < shown.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Card(
              color: const Color(0xFFFFF8E1),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: Colors.black,
                  child: Text('${i + 1}'),
                ),
                title: Text(shown[i], style: const TextStyle(fontSize: 20)),
                trailing: IconButton(
                  key: ValueKey('replay_hint_${i + 1}'),
                  iconSize: 32,
                  tooltip: 'Hilfe nochmal hören',
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => onReplayHint(i + 1),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
