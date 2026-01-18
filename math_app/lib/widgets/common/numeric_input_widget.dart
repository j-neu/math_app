import 'package:flutter/material.dart';

class NumericInputWidget extends StatefulWidget {
  final Function(int) onSubmit;
  final String hintText;

  const NumericInputWidget({
    Key? key,
    required this.onSubmit,
    this.hintText = '?',
  }) : super(key: key);

  @override
  State<NumericInputWidget> createState() => _NumericInputWidgetState();
}

class _NumericInputWidgetState extends State<NumericInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    if (text.isEmpty) return;

    final number = int.tryParse(text);
    if (number != null) {
      widget.onSubmit(number);
      _controller.clear();
      _focusNode.requestFocus(); // Keep focus for next question
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              textStyle: const TextStyle(fontSize: 20),
            ),
            child: const Text('Check'),
          ),
        ],
      ),
    );
  }
}
