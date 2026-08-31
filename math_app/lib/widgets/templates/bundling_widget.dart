import 'package:flutter/material.dart';

import '../../models/problem.dart';
import '../manipulatives/staebchen.dart';
import 'hint_text.dart';

/// Custom-widget template for the registry key `"bundling"` (B1.2 Bündeln,
/// P2 plan §5): renders `display.count` loose sticks. Tapping a loose stick
/// bundles ten of them into a Zehnerbündel (grouped and highlighted); tapping
/// a bundle opens it again.
///
/// [onValueChanged] reports the current `"Z Zehner, E Einer"` split on every
/// change — `""` while no bundle exists yet (a count >= 10 always needs at
/// least one Zehner bundle). The value is live; there is no "fertig"
/// confirmation. The evaluator (`_evaluateBundles`) accepts the same form.
class BundlingWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const BundlingWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<BundlingWidget> createState() => _BundlingWidgetState();
}

class _BundlingWidgetState extends State<BundlingWidget> {
  int _bundles = 0;

  int get _count => (widget.problem.display['count'] as int?) ?? 0;
  int get _singles => _count - 10 * _bundles;

  @override
  void didUpdateWidget(covariant BundlingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _bundles = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  void _report() {
    if (_bundles == 0) {
      widget.onValueChanged('');
      return;
    }
    widget.onValueChanged('$_bundles Zehner, $_singles Einer');
  }

  void _bundle() {
    if (_singles < 10) return;
    setState(() => _bundles++);
    _report();
  }

  void _unbundle() {
    if (_bundles == 0) return;
    setState(() => _bundles--);
    _report();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_bundles > 0) ...[
          Text(
            '$_bundles Zehner, $_singles Einer',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              for (var i = 0; i < _bundles; i++)
                GestureDetector(
                  key: ValueKey('bundle-$i'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _unbundle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.brown.shade400, width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const StaebchenBundelWidget(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < _singles; i++)
              GestureDetector(
                key: ValueKey('stick-$i'),
                behavior: HitTestBehavior.opaque,
                onTap: _bundle,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(child: StaebchenEinzelWidget()),
                ),
              ),
          ],
        ),
        if (_singles >= 10) ...[
          const SizedBox(height: 8),
          Text(
            'Tippe auf ein Stäbchen, um 10 zu bündeln.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: kHintTextColor,
                  fontSize: 14,
                ),
          ),
        ],
      ],
    );
  }
}
