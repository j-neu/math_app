import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SingleAnswerWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmit;

  const SingleAnswerWidget({
    super.key,
    required this.controller,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => onSubmit?.call(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Deine Antwort',
            ),
          ),
        ),
      ),
    );
  }
}

class MultipleAnswerWidget extends StatefulWidget {
  final TextEditingController controller;
  final int fieldCount;
  final String? prefixText;
  final VoidCallback? onSubmit;

  const MultipleAnswerWidget({
    super.key,
    required this.controller,
    this.fieldCount = 7, // Default to 7 for backward compatibility
    this.prefixText,
    this.onSubmit,
  });

  @override
  State<MultipleAnswerWidget> createState() => _MultipleAnswerWidgetState();
}

class _MultipleAnswerWidgetState extends State<MultipleAnswerWidget> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.fieldCount; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
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

  void _handleSubmitted(int index) {
    if (index < widget.fieldCount - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      widget.onSubmit?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        children: [
          if (widget.prefixText != null)
            Text(
              widget.prefixText!,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ...List.generate(widget.fieldCount, (index) {
            final isLast = index == widget.fieldCount - 1;
            return SizedBox(
              width: 60,
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                autofocus: index == 0,
                keyboardType: TextInputType.number,
                textInputAction:
                    isLast ? TextInputAction.done : TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _handleSubmitted(index),
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
        ],
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
              return ReorderableDragStartListener(
                key: ValueKey(entry.value),
                index: entry.key,
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.drag_handle),
                    title: Text(
                      entry.value,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
