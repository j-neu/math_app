import 'package:flutter/material.dart';

class SingleAnswerWidget extends StatelessWidget {
  final TextEditingController controller;

  const SingleAnswerWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Your Answer',
        ),
      ),
    );
  }
}

class MultipleAnswerWidget extends StatefulWidget {
  final TextEditingController controller;
  final int fieldCount;

  const MultipleAnswerWidget({
    super.key,
    required this.controller,
    this.fieldCount = 7, // Default to 7 for backward compatibility
  });

  @override
  State<MultipleAnswerWidget> createState() => _MultipleAnswerWidgetState();
}

class _MultipleAnswerWidgetState extends State<MultipleAnswerWidget> {
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.fieldCount; i++) {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateMainController() {
    // Combine all non-empty answers into a comma-separated string
    final answers = _controllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .join(', ');
    widget.controller.text = answers;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: List.generate(widget.fieldCount, (index) {
          return SizedBox(
            width: 60,
            child: TextField(
              controller: _controllers[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (_) => _updateMainController(),
            ),
          );
        }),
      ),
    );
  }
}

class SortAnswerWidget extends StatefulWidget {
  final TextEditingController controller;
  final List<String> items;

  const SortAnswerWidget({
    super.key,
    required this.controller,
    required this.items,
  });

  @override
  State<SortAnswerWidget> createState() => _SortAnswerWidgetState();
}

class _SortAnswerWidgetState extends State<SortAnswerWidget> {
  late List<String> _sortedItems;

  @override
  void initState() {
    super.initState();
    _sortedItems = List.from(widget.items)..shuffle();
  }

  void _updateMainController() {
    widget.controller.text = _sortedItems.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ReorderableListView(
        shrinkWrap: true,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = _sortedItems.removeAt(oldIndex);
            _sortedItems.insert(newIndex, item);
            _updateMainController();
          });
        },
        children: _sortedItems.asMap().entries.map((entry) {
          return Card(
            key: ValueKey(entry.value),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Icon(Icons.drag_handle),
              title: Text(
                entry.value,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}