import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/widgets/diagnostic/help_panel.dart';

Widget host(int revealed,
        {VoidCallback? onHelp, ValueChanged<int>? onHint, VoidCallback? onReplay}) =>
    MaterialApp(
        home: Scaffold(
            body: HelpPanel(
      hints: const ['Eins', 'Zwei', 'Drei'],
      revealed: revealed,
      onReplayQuestion: onReplay ?? () {},
      onRequestHelp: onHelp ?? () {},
      onReplayHint: onHint ?? (_) {},
    )));

void main() {
  testWidgets('shows only revealed hints', (t) async {
    await t.pumpWidget(host(2));
    expect(find.text('Eins'), findsOneWidget);
    expect(find.text('Zwei'), findsOneWidget);
    expect(find.text('Drei'), findsNothing);
  });

  testWidgets('Hilfe button calls onRequestHelp and disappears after stage 3',
      (t) async {
    var asked = 0;
    await t.pumpWidget(host(0, onHelp: () => asked++));
    await t.tap(find.text('Hilfe'));
    expect(asked, 1);
    await t.pumpWidget(host(3));
    expect(find.text('Hilfe'), findsNothing);
  });

  testWidgets('replay buttons report question and hint stage', (t) async {
    var replays = 0;
    int? hint;
    await t.pumpWidget(
        host(2, onReplay: () => replays++, onHint: (s) => hint = s));
    await t.tap(find.byKey(const ValueKey('replay_question')));
    await t.tap(find.byKey(const ValueKey('replay_hint_2')));
    expect(replays, 1);
    expect(hint, 2);
  });
}
