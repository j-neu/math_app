import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../manipulatives/staebchen.dart';
import 'answer_pad.dart';
import 'hint_text.dart';

/// Custom-widget template for the registry key `"unbundling"` (B1.3
/// Entbündeln, P2 plan §5): renders a bundled picture — `display.tens`
/// Zehnerbündel and `display.ones` loose Einer. Tapping a bundle opens it into
/// ten single sticks (the visual "opened" state, per the
/// `StaebchenOeffnenWidget` pattern).
///
/// Once at least one bundle is open the child types the total number of
/// Einer — `10 * tens + ones` — into a [BigAnswerField]; [onValueChanged]
/// reports the typed value, `""` while the field is empty.
class UnbundlingWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const UnbundlingWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<UnbundlingWidget> createState() => _UnbundlingWidgetState();
}

class _UnbundlingWidgetState extends State<UnbundlingWidget> {
  final TextEditingController _controller = TextEditingController();
  int _opened = 0;

  int get _tens => (widget.problem.display['tens'] as int?) ?? 0;
  int get _ones => (widget.problem.display['ones'] as int?) ?? 0;
  int get _remainingBundles => _tens - _opened;
  int get _visibleSingles => _ones + 10 * _opened;

  @override
  void didUpdateWidget(covariant UnbundlingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _opened = 0;
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

  void _openBundle() {
    if (_opened >= _tens) return;
    setState(() => _opened++);
  }

  Widget _picture() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _remainingBundles; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Semantics(
              button: true,
              label: 'Bündel ${i + 1} öffnen',
              excludeSemantics: true,
              child: GestureDetector(
                key: ValueKey('ub-bundle-$i'),
                behavior: HitTestBehavior.opaque,
                onTap: _openBundle,
                child: const StaebchenBundelWidget(),
              ),
            ),
          ],
          if (_remainingBundles > 0 && _visibleSingles > 0)
            const SizedBox(width: 26),
          for (var i = 0; i < _visibleSingles; i++)
            const StaebchenEinzelWidget(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opened = _opened > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _picture(),
        const SizedBox(height: 10),
        if (opened) ...[
          const Text(
            'Wie viele Einer sind es jetzt?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          BigAnswerField(
            controller: _controller,
            onChanged: widget.onValueChanged,
            hintText: '?',
          ),
        ] else ...[
          const Text(
            'Tippe auf ein Bündel, um es zu öffnen.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: kHintTextColor),
          ),
        ],
      ],
    );
  }
}
