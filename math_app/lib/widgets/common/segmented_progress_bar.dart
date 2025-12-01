import 'package:flutter/material.dart';

class SegmentedProgressBar extends StatefulWidget {
  final int totalSegments;
  final int currentSegment;
  final List<bool> results; // true = correct (green), false = incorrect (gold)

  const SegmentedProgressBar({
    super.key,
    required this.totalSegments,
    required this.currentSegment,
    required this.results,
  });

  @override
  State<SegmentedProgressBar> createState() => _SegmentedProgressBarState();
}

class _SegmentedProgressBarState extends State<SegmentedProgressBar>
    with TickerProviderStateMixin {
  int? _animatingSegment;
  late AnimationController _expandController;
  late AnimationController _popController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _popController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400), // Increased duration for the sequence
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: -2.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -2.0, end: 2.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 2.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(SegmentedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger animation when new segment completes
    if (widget.currentSegment > oldWidget.currentSegment) {
      if (widget.currentSegment -1 < widget.results.length) {
         _animateSegment(widget.currentSegment - 1);
      }
    }
  }

  Future<void> _animateSegment(int index) async {
    if (index < 0) return;
    setState(() {
      _animatingSegment = index;
    });

    // Expand
    await _expandController.forward();

    // Shake if incorrect
    if (index < widget.results.length && !widget.results[index]) {
      await _shakeController.forward();
      _shakeController.reset();
    }

    // Pop
    await _popController.forward();
    _popController.reset();

    // Contract
    await _expandController.reverse();

    setState(() {
      _animatingSegment = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.totalSegments, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _buildSegment(index),
          );
        }),
      ),
    );
  }

  Widget _buildSegment(int index) {
    final isComplete = index < widget.results.length;
    final isCorrect = isComplete && widget.results[index];
    final isAnimating = _animatingSegment == index;

    Color color = Colors.grey.shade300;
    if (isComplete) {
      color = isCorrect ? Colors.green : Colors.amber;
    }

    final segmentWidth =
        (MediaQuery.of(context).size.width - 32) / widget.totalSegments - 4;

    return AnimatedBuilder(
      animation:
          Listenable.merge([_expandController, _popController, _shakeController]),
      builder: (context, child) {
        double height = 8.0;
        double scale = 1.0;
        double translateX = 0.0;
        double borderRadius = 2.0;

        if (isAnimating) {
          height = 8.0 + (24.0 * _expandController.value); // 8 -> 32
          scale = 1.0 + (0.2 * _popController.value); // 1.0 -> 1.2
          borderRadius = 2.0 + (6.0 * _expandController.value); // 2 -> 8

          if (_shakeController.value > 0) {
            translateX = _shakeAnimation.value;
          }
        }

        return Transform.translate(
          offset: Offset(translateX, 0),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: segmentWidth > 0 ? segmentWidth : 0,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    _popController.dispose();
    _shakeController.dispose();
    super.dispose();
  }
}