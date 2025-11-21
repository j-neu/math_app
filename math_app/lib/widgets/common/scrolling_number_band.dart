import 'package:flutter/material.dart';

/// A reusable horizontal scrolling number band widget.
///
/// Displays a horizontal strip of numbers that can be scrolled sideways.
/// Shows ~5-7 numbers at once with smooth scrolling.
///
/// Used for counting exercises (C3.1, C3.2) where children practice
/// counting forward/backward on a number line.
///
/// Key features:
/// - Smooth horizontal scrolling
/// - Auto-centering of current number
/// - Highlighted numbers (e.g., decade numbers like 10, 20)
/// - Optional number masking (for Level 2 covered-number exercise)
/// - Visibility control (for Level 3 mental counting)
class ScrollingNumberBand extends StatefulWidget {
  /// Minimum number in the range (inclusive)
  final int minNumber;

  /// Maximum number in the range (inclusive)
  final int maxNumber;

  /// Current active position (which number is focused)
  final int currentPosition;

  /// How many numbers to show in viewport at once (default: 5)
  final int visibleCount;

  /// Numbers to highlight (e.g., [10, 20] for decade numbers)
  final List<int> highlightedNumbers;

  /// Number to mask/cover (for Level 2), null if none
  final int? maskedNumber;

  /// Whether the entire band is visible (false for Level 3)
  final bool isVisible;

  /// Callback when a number is tapped
  final Function(int)? onNumberTapped;

  /// Whether to allow manual scrolling (default: true)
  final bool allowManualScroll;

  /// Size of each number cell
  final double cellWidth;
  final double cellHeight;

  const ScrollingNumberBand({
    Key? key,
    required this.minNumber,
    required this.maxNumber,
    required this.currentPosition,
    this.visibleCount = 5,
    this.highlightedNumbers = const [],
    this.maskedNumber,
    this.isVisible = true,
    this.onNumberTapped,
    this.allowManualScroll = true,
    this.cellWidth = 70.0,
    this.cellHeight = 70.0,
  }) : super(key: key);

  @override
  State<ScrollingNumberBand> createState() => _ScrollingNumberBandState();
}

class _ScrollingNumberBandState extends State<ScrollingNumberBand> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Initial scroll to center current position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToPosition(widget.currentPosition, animated: false);
    });
  }

  @override
  void didUpdateWidget(ScrollingNumberBand oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-scroll when current position changes
    if (oldWidget.currentPosition != widget.currentPosition) {
      _scrollToPosition(widget.currentPosition, animated: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls to center the given number position
  void _scrollToPosition(int position, {required bool animated}) {
    if (!_scrollController.hasClients) {
      // If scroll controller isn't ready, wait and retry
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollToPosition(position, animated: false);
        }
      });
      return;
    }

    // Calculate index (0-based)
    final index = position - widget.minNumber;

    // Account for horizontal margins (4px each side = 8px total per cell)
    const horizontalMargin = 8.0;
    final effectiveCellWidth = widget.cellWidth + horizontalMargin;

    // Calculate scroll offset to center this number
    final totalNumbers = widget.maxNumber - widget.minNumber + 1;
    final maxScrollExtent = (totalNumbers * effectiveCellWidth) -
                            (widget.visibleCount * effectiveCellWidth);

    // Ensure maxScrollExtent is positive
    if (maxScrollExtent <= 0) return;

    // Center the current number
    final targetOffset = (index * effectiveCellWidth) -
                         ((widget.visibleCount / 2).floor() * effectiveCellWidth);

    final clampedOffset = targetOffset.clamp(0.0, maxScrollExtent);

    if (animated) {
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.jumpTo(clampedOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.isVisible) {
      // Level 3: Show placeholder when band is hidden
      return Container(
        height: widget.cellHeight,
        alignment: Alignment.center,
        child: Text(
          'Count in your head...',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.cellHeight,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: widget.allowManualScroll
            ? const BouncingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: widget.maxNumber - widget.minNumber + 1,
        itemBuilder: (context, index) {
          final number = widget.minNumber + index;
          return _buildNumberCell(number, theme);
        },
      ),
    );
  }

  Widget _buildNumberCell(int number, ThemeData theme) {
    final isCurrent = number == widget.currentPosition;
    final isHighlighted = widget.highlightedNumbers.contains(number);
    final isMasked = number == widget.maskedNumber;

    // Determine cell styling
    Color backgroundColor;
    Color textColor;
    double scale;

    if (isCurrent) {
      backgroundColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
      scale = 1.2;
    } else if (isHighlighted) {
      backgroundColor = theme.colorScheme.secondaryContainer;
      textColor = theme.colorScheme.onSecondaryContainer;
      scale = 1.0;
    } else {
      backgroundColor = theme.colorScheme.surface;
      textColor = theme.colorScheme.onSurface;
      scale = 1.0;
    }

    return GestureDetector(
      onTap: widget.onNumberTapped != null
          ? () => widget.onNumberTapped!(number)
          : null,
      child: Container(
        width: widget.cellWidth,
        height: widget.cellHeight,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: BoxDecoration(
              color: isMasked ? Colors.grey[400] : backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: isCurrent
                  ? Border.all(color: theme.colorScheme.primary, width: 3)
                  : Border.all(color: Colors.grey[300]!, width: 1),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: isMasked
                ? Icon(
                    Icons.question_mark,
                    color: Colors.white,
                    size: 32,
                  )
                : Text(
                    number.toString(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: textColor,
                      fontWeight: isCurrent || isHighlighted
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// A simple indicator showing current position on an invisible number band
/// Used for Level 3 when the band is hidden but we want to show progress
class NumberBandPositionIndicator extends StatelessWidget {
  final int currentPosition;
  final int targetPosition;
  final int totalSteps;

  const NumberBandPositionIndicator({
    Key? key,
    required this.currentPosition,
    required this.targetPosition,
    required this.totalSteps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (currentPosition - (targetPosition - totalSteps)) / totalSteps;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Step ${(progress * totalSteps).round()} of $totalSteps',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 300,
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
