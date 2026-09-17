import 'package:flutter/material.dart';

import '../../models/problem.dart';

/// Custom-widget template for the registry key `"order_cards"`
/// (order_cards_zr20/zr100, BUILD_ORDER.md Batch 1.5/2.3): `display.cards`
/// (a shuffled list of distinct numbers) are shown as draggable source
/// cards; the child drags each one into one of `display.cards.length`
/// ordered slots. Tapping a filled slot returns its card to the source row
/// so a mistake is easy to undo. [onValueChanged] reports the comma-joined
/// slot contents once every slot is filled, `""` while any slot is empty.
class OrderCardsWidget extends StatefulWidget {
  final Problem problem;
  final ValueChanged<String> onValueChanged;

  const OrderCardsWidget({
    super.key,
    required this.problem,
    required this.onValueChanged,
  });

  @override
  State<OrderCardsWidget> createState() => _OrderCardsWidgetState();
}

class _OrderCardsWidgetState extends State<OrderCardsWidget> {
  late List<int?> _slots;

  List<int> get _cards =>
      ((widget.problem.display['cards'] as List?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList();

  List<int> get _remaining =>
      _cards.where((c) => !_slots.contains(c)).toList();

  @override
  void initState() {
    super.initState();
    _slots = List<int?>.filled(_cards.length, null);
  }

  @override
  void didUpdateWidget(covariant OrderCardsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem != widget.problem) {
      _slots = List<int?>.filled(_cards.length, null);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValueChanged('');
      });
    }
  }

  void _place(int value, int slotIndex) {
    setState(() {
      _slots[slotIndex] = value;
    });
    _report();
  }

  void _remove(int slotIndex) {
    setState(() {
      _slots[slotIndex] = null;
    });
    _report();
  }

  void _report() {
    if (_slots.contains(null)) {
      widget.onValueChanged('');
    } else {
      widget.onValueChanged(_slots.join(','));
    }
  }

  Widget _card(int value) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _dragSource(int value) {
    return Draggable<int>(
      key: ValueKey('oc-card-$value'),
      data: value,
      feedback: Material(color: Colors.transparent, child: _card(value)),
      childWhenDragging: Opacity(opacity: 0.3, child: _card(value)),
      child: _card(value),
    );
  }

  Widget _slot(int index) {
    final value = _slots[index];
    return DragTarget<int>(
      key: ValueKey('oc-slot-$index'),
      onWillAcceptWithDetails: (details) => value == null,
      onAcceptWithDetails: (details) => _place(details.data, index),
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: value == null ? null : () => _remove(index),
          child: Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: value == null ? Colors.white : Colors.green.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: candidateData.isNotEmpty
                    ? Colors.orange
                    : (value == null ? Colors.grey.shade400 : Colors.green),
                width: 2,
              ),
            ),
            child: value == null
                ? null
                : Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [for (final v in _remaining) _dragSource(v)],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _slots.length; i++) _slot(i),
          ],
        ),
      ],
    );
  }
}
