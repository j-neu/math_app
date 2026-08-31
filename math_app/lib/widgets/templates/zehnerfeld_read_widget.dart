import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../manipulatives/zehnerfeld.dart';
import 'answer_pad.dart';

/// Ikonisch template widget for `zehnerfeld_read` (P2 plan §5 rule 6).
///
/// Renders the filled ten-frame(s) from `display` — one frame for
/// `arrangement: "structured"`, two side-by-side groups for `"two_groups"`
/// (using `display.split` [a, b]) — and the child types the answer into a
/// [BigAnswerField]. [onValueChanged] reports the typed value, `""` while the
/// field is empty. The prompt tells the child what to count (total,
/// difference or part per `display.ask`).
class ZehnerfeldReadWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const ZehnerfeldReadWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<ZehnerfeldReadWidget> createState() => _ZehnerfeldReadWidgetState();
}

class _ZehnerfeldReadWidgetState extends State<ZehnerfeldReadWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void didUpdateWidget(covariant ZehnerfeldReadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
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

  Widget _singleFrame(int count) =>
      ZehnerfeldWidget(filled: {for (var i = 0; i < count; i++) i});

  @override
  Widget build(BuildContext context) {
    final d = widget.problem.display;
    final arrangement = (d['arrangement'] as String?) ?? 'structured';

    final Widget picture;
    if (arrangement == 'two_groups') {
      final split = d['split'];
      if (split is List && split.length >= 2) {
        final a = (split[0] as num).toInt();
        final b = (split[1] as num).toInt();
        picture = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _singleFrame(a),
            const SizedBox(width: 24),
            _singleFrame(b),
          ],
        );
      } else {
        picture = _singleFrame((d['count'] as num?)?.toInt() ?? 0);
      }
    } else {
      picture = _singleFrame((d['count'] as num?)?.toInt() ?? 0);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        picture,
        const SizedBox(height: 16),
        BigAnswerField(
          controller: _controller,
          onChanged: widget.onValueChanged,
          hintText: '?',
        ),
      ],
    );
  }
}
