import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Standard die dot positions as (x, y) fractions of die size (0..1).
const _dotPositions = <int, List<(double, double)>>{
  1: [(0.5, 0.5)],
  2: [(0.75, 0.25), (0.25, 0.75)],
  3: [(0.75, 0.25), (0.5, 0.5), (0.25, 0.75)],
  4: [(0.25, 0.25), (0.75, 0.25), (0.25, 0.75), (0.75, 0.75)],
  5: [(0.25, 0.25), (0.75, 0.25), (0.5, 0.5), (0.25, 0.75), (0.75, 0.75)],
  6: [
    (0.25, 0.25), (0.75, 0.25),
    (0.25, 0.5),  (0.75, 0.5),
    (0.25, 0.75), (0.75, 0.75),
  ],
};

class _DicePainter extends CustomPainter {
  final int value;
  final Color faceColor;
  final Color dotColor;
  final Color borderColor;

  const _DicePainter({
    required this.value,
    required this.faceColor,
    required this.dotColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width * 0.15;
    final rect = Offset.zero & size;
    final rRect = RRect.fromRectXY(rect, radius, radius);

    canvas.drawRRect(rRect, Paint()..color = faceColor);
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    final dotRadius = size.width * 0.1;
    final dotPaint = Paint()..color = dotColor;
    for (final pos in _dotPositions[value.clamp(1, 6)] ?? []) {
      canvas.drawCircle(
        Offset(pos.$1 * size.width, pos.$2 * size.height),
        dotRadius,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DicePainter old) =>
      old.value != value ||
      old.faceColor != faceColor ||
      old.dotColor != dotColor;
}

/// Draws a single die face using CustomPaint.
class DiceWidget extends StatelessWidget {
  final int value;
  final Color faceColor;
  final Color dotColor;
  final Color borderColor;
  final double size;

  const DiceWidget({
    super.key,
    required this.value,
    this.faceColor = Colors.white,
    this.dotColor = Colors.black,
    this.borderColor = Colors.black54,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DicePainter(
        value: value,
        faceColor: faceColor,
        dotColor: dotColor,
        borderColor: borderColor,
      ),
    );
  }
}

/// Two-field answer widget for Q21 (dice decomposition of 7).
///
/// Syncs its state to [controller] as "val1, val2" so the existing
/// `_checkAnswer` special-case in DiagnosticScreen still works unchanged.
class Q21AnswerWidget extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmit;

  const Q21AnswerWidget({
    super.key,
    required this.controller,
    this.onSubmit,
  });

  @override
  State<Q21AnswerWidget> createState() => _Q21AnswerWidgetState();
}

class _Q21AnswerWidgetState extends State<Q21AnswerWidget> {
  final _ctrl1 = TextEditingController();
  final _ctrl2 = TextEditingController();
  final _focus1 = FocusNode();
  final _focus2 = FocusNode();

  @override
  void dispose() {
    _ctrl1.dispose();
    _ctrl2.dispose();
    _focus1.dispose();
    _focus2.dispose();
    super.dispose();
  }

  void _sync() {
    widget.controller.text = '${_ctrl1.text.trim()}, ${_ctrl2.text.trim()}';
  }

  Widget _dieInput({
    required TextEditingController ctrl,
    required FocusNode focusNode,
    required String label,
    required bool isFirst,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: TextField(
            controller: ctrl,
            focusNode: focusNode,
            autofocus: isFirst,
            keyboardType: TextInputType.number,
            textInputAction:
                isFirst ? TextInputAction.next : TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 1,
            onSubmitted: (_) {
              if (isFirst) {
                _focus2.requestFocus();
              } else {
                widget.onSubmit?.call();
              }
            },
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.black38, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (_) => _sync(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _dieInput(
          ctrl: _ctrl1,
          focusNode: _focus1,
          label: 'Würfel 1',
          isFirst: true,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14, left: 12, right: 12),
          child: Text(
            '+',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        _dieInput(
          ctrl: _ctrl2,
          focusNode: _focus2,
          label: 'Würfel 2',
          isFirst: false,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14, left: 12),
          child: Text(
            '= 7',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
