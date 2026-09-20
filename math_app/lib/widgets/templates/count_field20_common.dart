import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/problem.dart';
import 'answer_pad.dart';

/// Side length of the square play area every ZR20 count-field widget draws
/// its dots in.
const double kCountField20Area = 320.0;

const int _kGridSide = 5;
const double _kCell = kCountField20Area / _kGridSide;
const double _kInnerMargin = 2.0;

/// One dot's top-left corner and diameter inside the play area.
class CountField20Dot {
  final double left;
  final double top;
  final double size;

  const CountField20Dot(this.left, this.top, this.size);

  Rect get rect => Rect.fromLTWH(left, top, size, size);
}

/// Deterministic, overlap-free layout for `count` dots (1..25) in the
/// [kCountField20Area]-square play area. The area is a 5x5 grid of 64 px
/// cells; `count` distinct cells are chosen by a seeded shuffle and each dot
/// is jittered inside its own cell, keeping at least [_kInnerMargin] px to the
/// cell edge whenever the dot is small enough to leave room. Every dot lies
/// wholly inside its own cell, so no two dots can overlap and none can leave
/// the play area, by construction. Every entry of `sizes` must be <= 64.
List<CountField20Dot> layoutCountField20({
  required int seed,
  required int index,
  required int count,
  required List<double> sizes,
}) {
  final random = Random(seed * 173 + index * 59 + count);
  final cells = List<int>.generate(_kGridSide * _kGridSide, (i) => i)
    ..shuffle(random);
  final dots = <CountField20Dot>[];
  for (var i = 0; i < count; i++) {
    final cell = cells[i];
    final col = cell % _kGridSide;
    final row = cell ~/ _kGridSide;
    final size = sizes[random.nextInt(sizes.length)];
    final slack = _kCell - size;
    final range = max(0.0, slack - 2 * _kInnerMargin);
    final inset = (slack - range) / 2;
    final left = col * _kCell + inset + random.nextDouble() * range;
    final top = row * _kCell + inset + random.nextDouble() * range;
    dots.add(CountField20Dot(left, top, size));
  }
  return dots;
}

/// Shared body of the three `count_field20_*` registry keys
/// (quantify_count_zr20, BUILD_ORDER.md Batch 2.1): `display.count` dots laid
/// out by [layoutCountField20]; tapping a dot toggles it as counted (a visual
/// counting aid, never part of the graded answer); the child types the total
/// into [BigAnswerField] and [onValueChanged] reports every typed value, `""`
/// while the field is empty. [showTally] adds a live "Angetippt: n" line.
class CountField20Core extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onSubmit;
  final List<double> dotSizes;
  final bool showTally;

  const CountField20Core({
    super.key,
    required this.problem,
    required this.onValueChanged,
    required this.dotSizes,
    required this.showTally,
    this.onSubmit,
  });

  @override
  State<CountField20Core> createState() => _CountField20CoreState();
}

class _CountField20CoreState extends State<CountField20Core> {
  final TextEditingController _controller = TextEditingController();
  final Set<int> _tapped = {};
  late List<CountField20Dot> _dots;

  int get _count => (widget.problem.display['count'] as int?) ?? 0;

  @override
  void initState() {
    super.initState();
    _dots = _layout();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CountField20Core oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _controller.clear();
      _tapped.clear();
      _dots = _layout();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  List<CountField20Dot> _layout() => layoutCountField20(
        seed: widget.problem.seed,
        index: widget.problem.index,
        count: _count,
        sizes: widget.dotSizes,
      );

  void _toggle(int index) {
    setState(() {
      if (!_tapped.remove(index)) _tapped.add(index);
    });
  }

  Widget _dot(int index) {
    final isTapped = _tapped.contains(index);
    final size = _dots[index].size;
    return Semantics(
      button: true,
      label: isTapped ? 'Punkt ${index + 1} gezählt' : 'Punkt ${index + 1}',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('cf20-dot-$index'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggle(index),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isTapped ? Colors.green : Colors.indigo,
            border: Border.all(
              color: isTapped ? Colors.green.shade700 : Colors.indigo.shade700,
              width: 2,
            ),
          ),
          child: isTapped
              ? Icon(Icons.check, color: Colors.white, size: size * 0.45)
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: kCountField20Area,
          height: kCountField20Area,
          child: Stack(
            children: [
              for (var i = 0; i < _dots.length; i++)
                Positioned(
                  left: _dots[i].left,
                  top: _dots[i].top,
                  child: _dot(i),
                ),
            ],
          ),
        ),
        if (widget.showTally) ...[
          const SizedBox(height: 8),
          Text(
            'Angetippt: ${_tapped.length}',
            key: const ValueKey('cf20-tapped-count'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
        const SizedBox(height: 12),
        BigAnswerField(
          controller: _controller,
          onChanged: widget.onValueChanged,
          onSubmit: widget.onSubmit,
          hintText: '?',
        ),
      ],
    );
  }
}
