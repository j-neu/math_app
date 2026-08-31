import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Large, child-friendly numeric input shared by the symbolic template
/// widgets: a big centred [TextField] that stays keyboard-usable plus an
/// on-screen keypad (>= 44 px keys) on touch platforms.
///
/// The field never evaluates or submits — [onChanged] reports every change
/// and [onSubmit] (optional) is a "done" affordance the host may wire to its
/// own submit action. Setting [enabled] to false freezes input while the host
/// shows feedback.
class BigAnswerField extends StatelessWidget {
  /// The shared text being edited; owned by the parent so the parent can
  /// reset it when the problem changes.
  final TextEditingController controller;

  /// Called with the current field text on every change.
  final ValueChanged<String> onChanged;

  /// Optional "done" action for the submit key / IME action.
  final VoidCallback? onSubmit;

  /// When false the field and keypad are disabled (feedback state).
  final bool enabled;

  /// When null the keypad shows only on touch platforms.
  final bool? showKeypad;

  /// Placeholder shown in the empty field.
  final String hintText;

  /// Label of the optional submit key.
  final String submitLabel;

  const BigAnswerField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onSubmit,
    this.enabled = true,
    this.showKeypad,
    this.hintText = '',
    this.submitLabel = 'OK',
  });

  bool get _isTouch {
    if (kIsWeb) return false;
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS ||
        platform == TargetPlatform.fuchsia;
  }

  void _append(String digit) {
    controller.text = controller.text + digit;
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
    onChanged(controller.text);
  }

  void _backspace() {
    final text = controller.text;
    if (text.isEmpty) return;
    controller.text = text.substring(0, text.length - 1);
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
    onChanged(controller.text);
  }

  Widget _key(String label, VoidCallback? onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: enabled && onTap != null ? onTap : null,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _keypad() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [for (var d = 1; d <= 3; d++) _key('$d', () => _append('$d'))]),
          Row(children: [for (var d = 4; d <= 6; d++) _key('$d', () => _append('$d'))]),
          Row(children: [for (var d = 7; d <= 9; d++) _key('$d', () => _append('$d'))]),
          Row(
            children: [
              _key('⌫', _backspace),
              _key('0', () => _append('0')),
              if (onSubmit != null) _key(submitLabel, onSubmit) else const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showPad = showKeypad ?? _isTouch;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            textInputAction: onSubmit != null
                ? TextInputAction.done
                : TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 12,
              ),
            ),
            onChanged: onChanged,
            onSubmitted: (_) => onSubmit?.call(),
          ),
        ),
        if (showPad) ...[
          const SizedBox(height: 12),
          _keypad(),
        ],
      ],
    );
  }
}
