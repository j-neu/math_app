import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../manipulatives/zehnerfeld.dart';
import 'answer_pad.dart';

/// Ikonisch template widget for `picture_compare` (P2 plan §5 rule 10).
///
/// Renders two ten-frame groups (`display.left` / `display.right` counters).
///
/// * question `more`/`less`: the child taps the bigger/smaller group;
///   [onValueChanged] reports `"left"` / `"right"` (re-tapping re-picks).
/// * question `difference`: the child types `|left − right|` into a
///   [BigAnswerField]; the typed value is reported.
///
/// The selected group is signalled by a check mark plus a border — never by
/// colour alone. `""` is reported while nothing has been chosen/typed.
class PictureCompareWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const PictureCompareWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<PictureCompareWidget> createState() => _PictureCompareWidgetState();
}

class _PictureCompareWidgetState extends State<PictureCompareWidget> {
  String? _selected;
  final TextEditingController _controller = TextEditingController();

  int get _left => (widget.problem.display['left'] as num?)?.toInt() ?? 0;
  int get _right => (widget.problem.display['right'] as num?)?.toInt() ?? 0;
  String get _question =>
      (widget.problem.display['question'] as String?) ?? 'more';

  @override
  void didUpdateWidget(covariant PictureCompareWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _selected = null;
      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tapSide(String side) {
    setState(() => _selected = side);
    widget.onValueChanged(side);
  }

  Widget _frame(int count) => ZehnerfeldWidget(
        filled: {for (var i = 0; i < count; i++) i},
      );

  Widget _side(String id, int count) {
    final label = id == 'left' ? 'links' : 'rechts';
    final isSelected = _selected == id;
    final shownLabel = isSelected ? '$label ✓' : label;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          shownLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          key: ValueKey('compare-$id'),
          behavior: HitTestBehavior.opaque,
          onTap: _question == 'difference' ? null : () => _tapSide(id),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.indigo : Colors.transparent,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _frame(count),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final interactive = _question != 'difference';
    final pictures = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _side('left', _left),
              const SizedBox(width: 28),
              _side('right', _right),
            ],
          ),
        ),
      ],
    );

    if (!interactive) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          pictures,
          const SizedBox(height: 16),
          BigAnswerField(
            controller: _controller,
            onChanged: widget.onValueChanged,
            hintText: '?',
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        pictures,
        if (_selected != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Du hast "$_selected" gewählt.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
