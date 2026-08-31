import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/problem.dart';
import 'package:math_app/widgets/manipulatives/fingerbild.dart';
import 'package:math_app/widgets/manipulatives/stellenwerttafel.dart';
import 'package:math_app/widgets/manipulatives/zehnerfeld.dart';
import 'package:math_app/widgets/templates/answer_pad.dart';
import 'package:math_app/widgets/templates/bundle_sticks_widget.dart';
import 'package:math_app/widgets/templates/compare_symbols_widget.dart';
import 'package:math_app/widgets/templates/drag_partition_widget.dart';
import 'package:math_app/widgets/templates/equation_gap_widget.dart';
import 'package:math_app/widgets/templates/equation_solve_widget.dart';
import 'package:math_app/widgets/templates/fingerbild_read_widget.dart';
import 'package:math_app/widgets/templates/numberline_locate_widget.dart';
import 'package:math_app/widgets/templates/numberline_step_widget.dart';
import 'package:math_app/widgets/templates/picture_compare_widget.dart';
import 'package:math_app/widgets/templates/place_counters_widget.dart';
import 'package:math_app/widgets/templates/rekenrek_set_widget.dart';
import 'package:math_app/widgets/templates/sequence_gap_widget.dart';
import 'package:math_app/widgets/templates/stellenwerttafel_read_widget.dart';
import 'package:math_app/widgets/templates/strategy_choice_widget.dart';
import 'package:math_app/widgets/templates/word_problem_widget.dart';
import 'package:math_app/widgets/templates/zehnerfeld_read_widget.dart';

Problem _problem({
  required String template,
  required Map<String, dynamic> display,
  List<String> expected = const [],
  String promptDe = '',
}) => Problem(
      template: template,
      skillId: 'G1',
      level: 1,
      seed: 7,
      index: 0,
      promptDe: promptDe,
      display: display,
      expected: expected,
    );

Future<void> _pumpApp(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _tapPadKey(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(BigAnswerField),
      matching: find.text(label),
    ),
  );
  await tester.pump();
}

void main() {
  group('BigAnswerField', () {
    testWidgets('reports keypad digit taps and the delete key', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final values = <String>[];
      await _pumpApp(
        tester,
        BigAnswerField(
          controller: controller,
          onChanged: values.add,
          showKeypad: true,
        ),
      );

      await _tapPadKey(tester, '5');
      expect(values.last, '5');
      await _tapPadKey(tester, '0');
      expect(values.last, '50');
      await _tapPadKey(tester, '⌫');
      expect(values.last, '5');
      expect(controller.text, '5');
    });

    testWidgets('reports keyboard typing and the optional submit key',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final values = <String>[];
      var submitted = false;
      await _pumpApp(
        tester,
        BigAnswerField(
          controller: controller,
          onChanged: values.add,
          onSubmit: () => submitted = true,
          showKeypad: true,
        ),
      );

      await tester.enterText(find.byType(TextField), '7');
      expect(values.last, '7');
      await tester.tap(find.text('OK'));
      expect(submitted, isTrue);
    });

    testWidgets('disabled field ignores taps', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final values = <String>[];
      await _pumpApp(
        tester,
        BigAnswerField(
          controller: controller,
          onChanged: values.add,
          enabled: false,
          showKeypad: true,
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
      await _tapPadKey(tester, '3');
      expect(values, isEmpty);
      expect(controller.text, isEmpty);
    });
  });

  group('EquationSolveWidget', () {
    testWidgets('renders equation and prompt, reports the typed result',
        (tester) async {
      final values = <String>[];
      final problem = _problem(
        template: 'equation_solve',
        display: {
          'op': '+',
          'unknown': 'result',
          'mode': 'standard',
          'a': 4,
          'b': 3,
          'c': 7,
        },
        expected: ['7'],
        promptDe: 'Rechne im Kopf.',
      );
      await _pumpApp(
        tester,
        EquationSolveWidget(problem: problem, onValueChanged: values.add),
      );

      expect(find.text('4 + 3 = ?'), findsOneWidget);
      expect(find.text('Rechne im Kopf.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '7');
      expect(values.last, '7');
    });

    testWidgets('empty state reports "" and the field stays editable for retry',
        (tester) async {
      final values = <String>[];
      final problem = _problem(
        template: 'equation_solve',
        display: {
          'op': '+',
          'unknown': 'result',
          'mode': 'standard',
          'a': 4,
          'b': 3,
          'c': 7,
        },
        expected: ['7'],
      );
      await _pumpApp(
        tester,
        EquationSolveWidget(problem: problem, onValueChanged: values.add),
      );

      await tester.enterText(find.byType(TextField), '7');
      expect(values.last, '7');
      await tester.enterText(find.byType(TextField), '');
      expect(values.last, '');
      await tester.enterText(find.byType(TextField), '8');
      expect(values.last, '8');
    });

    testWidgets('place_value mode renders the decomposed operands',
        (tester) async {
      final values = <String>[];
      final problem = _problem(
        template: 'equation_solve',
        display: {
          'op': '+',
          'unknown': 'result',
          'mode': 'place_value',
          'a': 43,
          'b': 22,
          'c': 65,
          'a_tens': 4,
          'a_ones': 3,
          'b_tens': 2,
          'b_ones': 2,
          'tens': 6,
          'ones': 5,
        },
        expected: ['65'],
      );
      await _pumpApp(
        tester,
        EquationSolveWidget(problem: problem, onValueChanged: values.add),
      );

      expect(find.textContaining('4 Zehner 3 Einer'), findsOneWidget);
      expect(find.textContaining('2 Zehner 2 Einer'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '65');
      expect(values.last, '65');
    });

    testWidgets('a new problem resets the typed value', (tester) async {
      final values = <String>[];
      final first = _problem(
        template: 'equation_solve',
        display: {
          'op': '+',
          'unknown': 'result',
          'mode': 'standard',
          'a': 4,
          'b': 3,
          'c': 7,
        },
        expected: ['7'],
      );
      final second = _problem(
        template: 'equation_solve',
        display: {
          'op': '+',
          'unknown': 'result',
          'mode': 'standard',
          'a': 9,
          'b': 5,
          'c': 14,
        },
        expected: ['14'],
      );
      await _pumpApp(
        tester,
        EquationSolveWidget(problem: first, onValueChanged: values.add),
      );
      await tester.enterText(find.byType(TextField), '7');
      expect(values.last, '7');

      await _pumpApp(
        tester,
        EquationSolveWidget(problem: second, onValueChanged: values.add),
      );
      expect(values.last, '');
      expect(find.text('9 + 5 = ?'), findsOneWidget);
    });
  });

  group('EquationGapWidget', () {
    testWidgets('form gap renders the equation and reports the typed number',
        (tester) async {
      final values = <String>[];
      final problem = _problem(
        template: 'equation_gap',
        display: {
          'form': 'gap',
          'op': '-',
          'a': 14,
          'b': 8,
          'gap_after': 'result',
        },
        expected: ['6'],
      );
      await _pumpApp(
        tester,
        EquationGapWidget(problem: problem, onValueChanged: values.add),
      );

      expect(find.text('14 - 8 ='), findsOneWidget);
      await tester.enterText(find.byType(TextField), '6');
      expect(values.last, '6');
      await tester.enterText(find.byType(TextField), '5');
      expect(values.last, '5', reason: 'the gap stays editable for retry');
    });

    testWidgets('form missing_addend places the gap in the middle',
        (tester) async {
      final values = <String>[];
      final problem = _problem(
        template: 'equation_gap',
        display: {
          'form': 'missing_addend',
          'op': '+',
          'a': 7,
          'b': 5,
          'c': 12,
          'gap_after': 'middle',
        },
        expected: ['5'],
      );
      await _pumpApp(
        tester,
        EquationGapWidget(problem: problem, onValueChanged: values.add),
      );

      expect(find.text('7 +'), findsOneWidget);
      expect(find.text('= 12'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '5');
      expect(values.last, '5');
    });

    testWidgets('form any_split reports "i+j" only once both fields are filled',
        (tester) async {
      final values = <String>[];
      final problem = _problem(
        template: 'equation_gap',
        display: {
          'form': 'any_split',
          'op': '+',
          'total': 8,
          'gap_after': 'both',
        },
        expected: ['1+7', '2+6', '3+5', '4+4', '5+3', '6+2', '7+1'],
      );
      await _pumpApp(
        tester,
        EquationGapWidget(problem: problem, onValueChanged: values.add),
      );

      expect(find.text('= 8'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), '3');
      expect(values.last, '', reason: 'one field alone is incomplete');
      await tester.enterText(find.byType(TextField).at(1), '5');
      expect(values.last, '3+5');
      await tester.enterText(find.byType(TextField).at(0), '2');
      expect(values.last, '2+5');
    });

    testWidgets('form helper renders the Stützpunkt equation', (tester) async {
      final values = <String>[];
      final problem = _problem(
        template: 'equation_gap',
        display: {
          'form': 'helper',
          'op': '+',
          'a': 9,
          'b': 4,
          'first': 10,
          'split': 'make_ten',
          'gap_after': 'right',
        },
        expected: ['3'],
      );
      await _pumpApp(
        tester,
        EquationGapWidget(problem: problem, onValueChanged: values.add),
      );

      expect(find.text('9 + 4 ='), findsOneWidget);
      expect(find.text('10 +'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '3');
      expect(values.last, '3');
    });

    testWidgets('form place_value renders Zehner and Einer', (tester) async {
      final values = <String>[];
      final problem = _problem(
        template: 'equation_gap',
        display: {
          'form': 'place_value',
          'op': '+',
          'tens': 4,
          'ones': 13,
          'gap_after': 'result',
        },
        expected: ['53'],
      );
      await _pumpApp(
        tester,
        EquationGapWidget(problem: problem, onValueChanged: values.add),
      );

      expect(find.text('4 Zehner 13 Einer ='), findsOneWidget);
      await tester.enterText(find.byType(TextField), '53');
      expect(values.last, '53');
    });

    testWidgets('form half reports the common value only when both gaps agree',
        (tester) async {
      final values = <String>[];
      final problem = _problem(
        template: 'equation_gap',
        display: {
          'form': 'half',
          'op': '+',
          'total': 8,
          'gap_after': 'both',
        },
        expected: ['4'],
      );
      await _pumpApp(
        tester,
        EquationGapWidget(problem: problem, onValueChanged: values.add),
      );

      await tester.enterText(find.byType(TextField).at(0), '3');
      await tester.enterText(find.byType(TextField).at(1), '5');
      expect(values.last, '', reason: 'unequal halves stay incomplete');
      await tester.enterText(find.byType(TextField).at(1), '3');
      expect(values.last, '3');
      await tester.enterText(find.byType(TextField).at(0), '4');
      await tester.enterText(find.byType(TextField).at(1), '4');
      expect(values.last, '4');
    });
  });

  group('SequenceGapWidget', () {
    testWidgets('reports values joined by commas once every gap is filled',
        (tester) async {
      final values = <String>[];
      final problem = _problem(
        template: 'sequence_gap',
        display: {
          'direction': 'up',
          'step': 1,
          'progression': 'arithmetic',
          'values': [5, 6, 7, 8, 9],
          'gap_indices': [1, 3],
        },
        expected: ['6', '8'],
      );
      await _pumpApp(
        tester,
        SequenceGapWidget(problem: problem, onValueChanged: values.add),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), '6');
      expect(values.last, '', reason: 'one gap alone is incomplete');
      await tester.enterText(find.byType(TextField).at(1), '8');
      expect(values.last, '6,8');
      await tester.enterText(find.byType(TextField).at(1), '9');
      expect(values.last, '6,9');
    });

    testWidgets('a new problem resets all gap fields', (tester) async {
      final values = <String>[];
      final first = _problem(
        template: 'sequence_gap',
        display: {
          'direction': 'up',
          'step': 1,
          'progression': 'arithmetic',
          'values': [5, 6, 7, 8, 9],
          'gap_indices': [1, 3],
        },
        expected: ['6', '8'],
      );
      final second = _problem(
        template: 'sequence_gap',
        display: {
          'direction': 'down',
          'step': 1,
          'progression': 'arithmetic',
          'values': [9, 8, 7, 6, 5],
          'gap_indices': [0],
        },
        expected: ['9'],
      );
      await _pumpApp(
        tester,
        SequenceGapWidget(problem: first, onValueChanged: values.add),
      );
      await tester.enterText(find.byType(TextField).at(0), '6');
      await tester.enterText(find.byType(TextField).at(1), '8');
      expect(values.last, '6,8');

      await _pumpApp(
        tester,
        SequenceGapWidget(problem: second, onValueChanged: values.add),
      );
      expect(values.last, '');
    });
  });

  group('CompareSymbolsWidget', () {
    testWidgets('renders the numbers and reports the tapped operator',
        (tester) async {
      final values = <String>[];
      final problem = _problem(
        template: 'compare_symbols',
        display: {'a': 3, 'b': 5},
        expected: ['<'],
      );
      await _pumpApp(
        tester,
        CompareSymbolsWidget(problem: problem, onValueChanged: values.add),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(values, isEmpty, reason: 'nothing chosen yet');

      await tester.tap(find.text('<'));
      expect(values.last, '<');
    });

    testWidgets('re-picking the operator updates the value', (tester) async {
      final values = <String>[];
      final problem = _problem(
        template: 'compare_symbols',
        display: {'a': 7, 'b': 7},
        expected: ['='],
      );
      await _pumpApp(
        tester,
        CompareSymbolsWidget(problem: problem, onValueChanged: values.add),
      );

      await tester.tap(find.text('<'));
      expect(values.last, '<');
      await tester.tap(find.text('>'));
      expect(values.last, '>');
      await tester.tap(find.text('='));
      expect(values.last, '=');
    });
  });

  group('StrategyChoiceWidget', () {
    testWidgets('reports "result|strategyId" only when both parts are done',
        (tester) async {
      final values = <String>[];
      final problem = _problem(
        template: 'strategy_choice',
        display: {
          'op': '+',
          'a': 4,
          'b': 4,
          'correct_strategy': 'verdoppeln',
          'strategies': [
            {'id': 'verdoppeln', 'label_de': 'Verdoppeln'},
            {'id': 'fast_verdoppeln', 'label_de': 'Fast verdoppeln'},
          ],
        },
        expected: ['8'],
      );
      await _pumpApp(
        tester,
        StrategyChoiceWidget(problem: problem, onValueChanged: values.add),
      );

      expect(find.text('4 + 4 ='), findsOneWidget);
      expect(find.text('Verdoppeln'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '8');
      expect(values.last, '', reason: 'result alone is incomplete');
      await tester.tap(find.text('Verdoppeln'));
      expect(values.last, '8|verdoppeln');
    });

    testWidgets('re-picking the strategy allows a different choice',
        (tester) async {
      final values = <String>[];
      final problem = _problem(
        template: 'strategy_choice',
        display: {
          'op': '+',
          'a': 4,
          'b': 4,
          'correct_strategy': 'verdoppeln',
          'strategies': [
            {'id': 'verdoppeln', 'label_de': 'Verdoppeln'},
            {'id': 'fast_verdoppeln', 'label_de': 'Fast verdoppeln'},
          ],
        },
        expected: ['8'],
      );
      await _pumpApp(
        tester,
        StrategyChoiceWidget(problem: problem, onValueChanged: values.add),
      );

      await tester.enterText(find.byType(TextField), '8');
      await tester.tap(find.text('Verdoppeln'));
      expect(values.last, '8|verdoppeln');
      await tester.tap(find.text('Fast verdoppeln'));
      expect(values.last, '8|fast_verdoppeln');
      await tester.enterText(find.byType(TextField), '');
      expect(values.last, '', reason: 'clearing the result clears the value');
    });
  });

  group('WordProblemWidget', () {
    testWidgets('renders the story sentence and reports the typed result',
        (tester) async {
      final values = <String>[];
      const promptDe =
          'Im Korb sind 3 Äpfel. 2 kommen dazu. Wie viele sind es?';
      final problem = _problem(
        template: 'word_problem',
        display: {
          'setting_de': 'im Korb',
          'object_de': 'Äpfel',
          'a': 3,
          'b': 2,
          'op': '+',
        },
        expected: ['5'],
        promptDe: promptDe,
      );
      await _pumpApp(
        tester,
        WordProblemWidget(problem: problem, onValueChanged: values.add),
      );

      expect(find.text(promptDe), findsOneWidget);
      await tester.enterText(find.byType(TextField), '5');
      expect(values.last, '5');
    });

    testWidgets('empty state reports "" and stays editable for retry',
        (tester) async {
      final values = <String>[];
      final problem = _problem(
        template: 'word_problem',
        display: {
          'setting_de': 'im Korb',
          'object_de': 'Äpfel',
          'a': 3,
          'b': 2,
          'op': '+',
        },
        expected: ['5'],
        promptDe: 'Im Korb sind 3 Äpfel. 2 kommen dazu. Wie viele sind es?',
      );
      await _pumpApp(
        tester,
        WordProblemWidget(problem: problem, onValueChanged: values.add),
      );

      await tester.enterText(find.byType(TextField), '5');
      expect(values.last, '5');
      await tester.enterText(find.byType(TextField), '');
      expect(values.last, '');
      await tester.enterText(find.byType(TextField), '4');
      expect(values.last, '4');
    });
  });

  group('DragPartitionWidget', () {
    Problem partitionProblem(int total, int parts, List<String> labels,
            {String constraint = 'sum'}) =>
        _problem(
          template: 'drag_partition',
          display: {
            'total': total,
            'parts': parts,
            'split_constraint': constraint,
            'box_labels': labels,
          },
        );

    testWidgets('renders the stash and one box per part', (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        DragPartitionWidget(
          problem: partitionProblem(7, 2, ['', '']),
          onValueChanged: values.add,
        ),
      );

      expect(find.text('0 von 7'), findsOneWidget);
      expect(find.byKey(const ValueKey('box-add-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('box-add-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('box-add-2')), findsNothing);
      expect(values, isEmpty);
    });

    testWidgets('box taps add counters and report the joined box counts',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        DragPartitionWidget(
          problem: partitionProblem(6, 2, ['links', 'rechts']),
          onValueChanged: values.add,
        ),
      );

      expect(find.text('links'), findsOneWidget);
      expect(find.text('rechts'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('box-add-0')));
      expect(values.last, '1+0');
      await tester.tap(find.byKey(const ValueKey('box-add-0')));
      expect(values.last, '2+0');
      await tester.tap(find.byKey(const ValueKey('box-add-1')));
      expect(values.last, '2+1');
      await tester.tap(find.byKey(const ValueKey('box-add-1')));
      await tester.tap(find.byKey(const ValueKey('box-add-1')));
      expect(values.last, '2+3');
    });

    testWidgets('tapping a box counter removes one, empty state reports ""',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        DragPartitionWidget(
          problem: partitionProblem(5, 2, ['', '']),
          onValueChanged: values.add,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('box-add-0')));
      await tester.tap(find.byKey(const ValueKey('box-add-0')));
      expect(values.last, '2+0');
      await tester.tap(find.byKey(const ValueKey('box-counters-0')));
      expect(values.last, '1+0');
      await tester.tap(find.byKey(const ValueKey('box-counters-0')));
      expect(values.last, '', reason: 'removing the last counter reports ""');
    });

    testWidgets('cannot place more counters than the stash holds',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        DragPartitionWidget(
          problem: partitionProblem(5, 2, ['', '']),
          onValueChanged: values.add,
        ),
      );

      for (var i = 0; i < 6; i++) {
        await tester.tap(find.byKey(const ValueKey('box-add-0')));
        await tester.pump();
      }
      expect(values.last, '5+0', reason: 'the stash caps the placement');
      expect(find.text('5 von 5'), findsOneWidget);
    });

    testWidgets('a new problem resets the boxes and reports ""', (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        DragPartitionWidget(
          problem: partitionProblem(5, 2, ['', '']),
          onValueChanged: values.add,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('box-add-0')));
      expect(values.last, '1+0');

      await _pumpApp(
        tester,
        DragPartitionWidget(
          problem: partitionProblem(8, 3, ['', '', '']),
          onValueChanged: values.add,
        ),
      );
      expect(values.last, '');
      expect(find.byKey(const ValueKey('box-add-2')), findsOneWidget);
    });
  });

  group('PlaceCountersWidget', () {
    testWidgets('fill renders a ten-frame and reports the filled count',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        PlaceCountersWidget(
          problem: _problem(
            template: 'place_counters',
            display: {'count': 4, 'frame': 'zehnerfeld', 'action': 'fill'},
            expected: ['4'],
          ),
          onValueChanged: values.add,
        ),
      );

      expect(find.byKey(const ValueKey('pc-cell-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('pc-cell-9')), findsOneWidget);
      expect(find.byKey(const ValueKey('pc-cell-10')), findsNothing);
      expect(values, isEmpty, reason: 'nothing filled yet');

      await tester.tap(find.byKey(const ValueKey('pc-cell-0')));
      await tester.pump();
      expect(values.last, '1');
      await tester.tap(find.byKey(const ValueKey('pc-cell-1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('pc-cell-2')));
      await tester.pump();
      expect(values.last, '3');
    });

    testWidgets('tapping a filled cell unfills it and empty reports ""',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        PlaceCountersWidget(
          problem: _problem(
            template: 'place_counters',
            display: {'count': 3, 'frame': 'zehnerfeld', 'action': 'fill'},
            expected: ['3'],
          ),
          onValueChanged: values.add,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('pc-cell-0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('pc-cell-1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('pc-cell-2')));
      await tester.pump();
      expect(values.last, '3');

      await tester.tap(find.byKey(const ValueKey('pc-cell-1')));
      await tester.pump();
      expect(values.last, '2');
      await tester.tap(find.byKey(const ValueKey('pc-cell-2')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('pc-cell-0')));
      await tester.pump();
      expect(values.last, '', reason: 'unfilling the last cell reports ""');
    });

    testWidgets('take_away starts full, reports remaining, all removed → 0',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        PlaceCountersWidget(
          problem: _problem(
            template: 'place_counters',
            display: {
              'count': 4,
              'frame': 'zehnerfeld',
              'action': 'take_away',
              'total': 6,
              'remaining': 2,
            },
            expected: ['2'],
          ),
          onValueChanged: values.add,
        ),
      );

      expect(values, isEmpty, reason: 'nothing removed yet reports ""');
      await tester.tap(find.byKey(const ValueKey('pc-cell-0')));
      await tester.pump();
      expect(values.last, '5', reason: 'one of six removed leaves five');
      for (var i = 1; i < 6; i++) {
        await tester.tap(find.byKey(ValueKey('pc-cell-$i')));
        await tester.pump();
      }
      expect(values.last, '0', reason: 'all removed reports 0');
    });

    testWidgets('nonstandard mode reports the Z/E pair placed on the table',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        PlaceCountersWidget(
          problem: _problem(
            template: 'place_counters',
            display: {
              'count': 23,
              'frame': 'stellenwerttafel',
              'action': 'fill',
              'mode': 'nonstandard',
              'tens': 1,
              'ones': 13,
            },
            expected: ['23'],
          ),
          onValueChanged: values.add,
        ),
      );

      expect(find.text('Z'), findsOneWidget);
      expect(find.text('E'), findsOneWidget);
      expect(values, isEmpty);

      await tester.tap(find.byKey(const ValueKey('swt-z-add')));
      await tester.pump();
      expect(values.last, '1 0');
      await tester.tap(find.byKey(const ValueKey('swt-e-add')));
      await tester.pump();
      expect(values.last, '1 1');
      await tester.tap(find.byKey(const ValueKey('swt-e-counters')));
      await tester.pump();
      expect(values.last, '1 0');
      await tester.tap(find.byKey(const ValueKey('swt-z-counters')));
      await tester.pump();
      expect(values.last, '', reason: 'removing the last counter reports ""');
    });

    testWidgets('a new problem resets the frame and reports ""', (tester) async {
      final values = <String>[];
      final first = _problem(
        template: 'place_counters',
        display: {'count': 4, 'frame': 'zehnerfeld', 'action': 'fill'},
        expected: ['4'],
      );
      final second = _problem(
        template: 'place_counters',
        display: {'count': 2, 'frame': 'rekenrek', 'action': 'fill'},
        expected: ['2'],
      );
      await _pumpApp(
        tester,
        PlaceCountersWidget(problem: first, onValueChanged: values.add),
      );
      await tester.tap(find.byKey(const ValueKey('pc-cell-0')));
      await tester.pump();
      expect(values.last, '1');

      await _pumpApp(
        tester,
        PlaceCountersWidget(problem: second, onValueChanged: values.add),
      );
      expect(values.last, '');
      expect(find.byKey(const ValueKey('pc-cell-19')), findsOneWidget,
          reason: 'the rekenrek frame has 20 cells');
    });
  });

  group('BundleSticksWidget', () {
    testWidgets('renders one tappable stick per count', (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        BundleSticksWidget(
          problem: _problem(
            template: 'bundle_sticks',
            display: {'count': 15, 'bundles': 1, 'singles': 5},
            expected: ['1 Zehner, 5 Einer'],
          ),
          onValueChanged: values.add,
        ),
      );

      expect(find.byKey(const ValueKey('stick-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('stick-14')), findsOneWidget);
      expect(find.byKey(const ValueKey('stick-15')), findsNothing);
      expect(find.byKey(const ValueKey('bundle-0')), findsNothing);
      expect(values, isEmpty, reason: 'nothing bundled yet');
    });

    testWidgets('tapping sticks bundles tens and reports the Z/E split',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        BundleSticksWidget(
          problem: _problem(
            template: 'bundle_sticks',
            display: {'count': 25, 'bundles': 2, 'singles': 5},
            expected: ['2 Zehner, 5 Einer'],
          ),
          onValueChanged: values.add,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('stick-0')));
      await tester.pump();
      expect(values.last, '1 Zehner, 15 Einer');
      await tester.tap(find.byKey(const ValueKey('stick-0')));
      await tester.pump();
      expect(values.last, '2 Zehner, 5 Einer');
    });

    testWidgets('tapping a bundle unbundles it, empty state reports ""',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        BundleSticksWidget(
          problem: _problem(
            template: 'bundle_sticks',
            display: {'count': 25, 'bundles': 2, 'singles': 5},
            expected: ['2 Zehner, 5 Einer'],
          ),
          onValueChanged: values.add,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('stick-0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('stick-0')));
      await tester.pump();
      expect(values.last, '2 Zehner, 5 Einer');

      await tester.tap(find.byKey(const ValueKey('bundle-0')));
      await tester.pump();
      expect(values.last, '1 Zehner, 15 Einer');
      await tester.tap(find.byKey(const ValueKey('bundle-0')));
      await tester.pump();
      expect(values.last, '', reason: 'no bundles left reports ""');
    });

    testWidgets('boundary: 39 sticks bundle to 3 Zehner and 9 Einer',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        BundleSticksWidget(
          problem: _problem(
            template: 'bundle_sticks',
            display: {'count': 39, 'bundles': 3, 'singles': 9},
            expected: ['3 Zehner, 9 Einer'],
          ),
          onValueChanged: values.add,
        ),
      );

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const ValueKey('stick-0')));
        await tester.pump();
      }
      expect(values.last, '3 Zehner, 9 Einer',
          reason: 'a fourth bundle is impossible with only 9 singles left');
    });

    testWidgets('a new problem resets the bundles and reports ""',
        (tester) async {
      final values = <String>[];
      final first = _problem(
        template: 'bundle_sticks',
        display: {'count': 15, 'bundles': 1, 'singles': 5},
        expected: ['1 Zehner, 5 Einer'],
      );
      final second = _problem(
        template: 'bundle_sticks',
        display: {'count': 12, 'bundles': 1, 'singles': 2},
        expected: ['1 Zehner, 2 Einer'],
      );
      await _pumpApp(
        tester,
        BundleSticksWidget(problem: first, onValueChanged: values.add),
      );
      await tester.tap(find.byKey(const ValueKey('stick-0')));
      await tester.pump();
      expect(values.last, '1 Zehner, 5 Einer');

      await _pumpApp(
        tester,
        BundleSticksWidget(problem: second, onValueChanged: values.add),
      );
      expect(values.last, '');
      expect(find.byKey(const ValueKey('bundle-0')), findsNothing);
    });
  });

  group('RekenrekSetWidget', () {
    testWidgets('renders two rods of ten beads and reports the moved count',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        RekenrekSetWidget(
          problem: _problem(
            template: 'rekenrek_set',
            display: {'count': 8, 'rows': 2},
            expected: ['8'],
          ),
          onValueChanged: values.add,
        ),
      );

      expect(find.byKey(const ValueKey('bead-top-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('bead-top-9')), findsOneWidget);
      expect(find.byKey(const ValueKey('bead-bottom-9')), findsOneWidget);
      expect(values, isEmpty, reason: 'no bead moved yet');

      await tester.tap(find.byKey(const ValueKey('bead-top-2')));
      await tester.pump();
      expect(values.last, '3');
      await tester.tap(find.byKey(const ValueKey('bead-bottom-1')));
      await tester.pump();
      expect(values.last, '5');
    });

    testWidgets('tapping a moved bead slides it back', (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        RekenrekSetWidget(
          problem: _problem(
            template: 'rekenrek_set',
            display: {'count': 6, 'rows': 2},
            expected: ['6'],
          ),
          onValueChanged: values.add,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('bead-top-2')));
      await tester.pump();
      expect(values.last, '3');
      await tester.tap(find.byKey(const ValueKey('bead-top-2')));
      await tester.pump();
      expect(values.last, '2', reason: 'beads 0..2 slide back to 0..1');

      await tester.tap(find.byKey(const ValueKey('bead-top-1')));
      await tester.pump();
      expect(values.last, '1');
      await tester.tap(find.byKey(const ValueKey('bead-top-0')));
      await tester.pump();
      expect(values.last, '', reason: 'the last moved bead returns reports ""');
    });

    testWidgets('boundary: all 20 beads moved reports 20/20', (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        RekenrekSetWidget(
          problem: _problem(
            template: 'rekenrek_set',
            display: {'count': 20, 'rows': 2},
            expected: ['20'],
          ),
          onValueChanged: values.add,
        ),
      );

      for (var i = 0; i < 10; i++) {
        await tester.tap(find.byKey(ValueKey('bead-top-$i')));
        await tester.pump();
      }
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.byKey(ValueKey('bead-bottom-$i')));
        await tester.pump();
      }
      expect(values.last, '20');
    });

    testWidgets('rows: 1 renders a single rod', (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        RekenrekSetWidget(
          problem: _problem(
            template: 'rekenrek_set',
            display: {'count': 4, 'rows': 1},
            expected: ['4'],
          ),
          onValueChanged: values.add,
        ),
      );

      expect(find.byKey(const ValueKey('bead-top-9')), findsOneWidget);
      expect(find.byKey(const ValueKey('bead-bottom-0')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('bead-top-3')));
      await tester.pump();
      expect(values.last, '4');
    });

    testWidgets('a new problem resets the beads and reports ""', (tester) async {
      final values = <String>[];
      final first = _problem(
        template: 'rekenrek_set',
        display: {'count': 6, 'rows': 2},
        expected: ['6'],
      );
      final second = _problem(
        template: 'rekenrek_set',
        display: {'count': 9, 'rows': 2},
        expected: ['9'],
      );
      await _pumpApp(
        tester,
        RekenrekSetWidget(problem: first, onValueChanged: values.add),
      );
      await tester.tap(find.byKey(const ValueKey('bead-top-2')));
      await tester.pump();
      expect(values.last, '3');

      await _pumpApp(
        tester,
        RekenrekSetWidget(problem: second, onValueChanged: values.add),
      );
      expect(values.last, '');
    });
  });

  group('NumberlineStepWidget', () {
    double dxForValue(
      WidgetTester tester,
      int value,
      int lo,
      int hi,
    ) {
      final rect = tester.getRect(
        find.byKey(const ValueKey('numberline-step-line')),
      );
      return rect.left +
          16 +
          (rect.width - 32) * (value - lo) / (hi - lo);
    }

    testWidgets('renders the line and reports the tapped run in order',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        NumberlineStepWidget(
          problem: _problem(
            template: 'numberline_step',
            display: {
              'range': [0, 20],
              'start': 10,
              'target': 13,
              'step': 1,
              'direction': 'up',
            },
            expected: ['11', '12', '13'],
          ),
          onValueChanged: values.add,
        ),
      );

      final line = tester.getRect(
        find.byKey(const ValueKey('numberline-step-line')),
      );
      expect(values, isEmpty, reason: 'no tick tapped yet');

      await tester.tapAt(Offset(dxForValue(tester, 11, 0, 20), line.center.dy));
      await tester.pump();
      expect(values.last, '11');
      await tester.tapAt(Offset(dxForValue(tester, 12, 0, 20), line.center.dy));
      await tester.pump();
      expect(values.last, '11,12');
      await tester.tapAt(Offset(dxForValue(tester, 13, 0, 20), line.center.dy));
      await tester.pump();
      expect(values.last, '11,12,13', reason: 'full run once the target is hit');
    });

    testWidgets('only the next required tick registers; wrong taps are ignored',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        NumberlineStepWidget(
          problem: _problem(
            template: 'numberline_step',
            display: {
              'range': [0, 20],
              'start': 10,
              'target': 13,
              'step': 1,
              'direction': 'up',
            },
            expected: ['11', '12', '13'],
          ),
          onValueChanged: values.add,
        ),
      );

      final line = tester.getRect(
        find.byKey(const ValueKey('numberline-step-line')),
      );
      await tester.tapAt(Offset(dxForValue(tester, 15, 0, 20), line.center.dy));
      await tester.pump();
      expect(values, isEmpty, reason: 'tapping ahead of the run is ignored');
      await tester.tapAt(Offset(dxForValue(tester, 13, 0, 20), line.center.dy));
      await tester.pump();
      expect(values, isEmpty, reason: 'tapping the target first is ignored');

      await tester.tapAt(Offset(dxForValue(tester, 11, 0, 20), line.center.dy));
      await tester.pump();
      await tester.tapAt(Offset(dxForValue(tester, 11, 0, 20), line.center.dy));
      await tester.pump();
      expect(values.last, '11', reason: 're-tapping the same tick does nothing');
      await tester.tapAt(Offset(dxForValue(tester, 13, 0, 20), line.center.dy));
      await tester.pump();
      expect(values.last, '11', reason: 'skipping 12 keeps the run at 11');
    });

    testWidgets('direction down reports the descending run', (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        NumberlineStepWidget(
          problem: _problem(
            template: 'numberline_step',
            display: {
              'range': [0, 20],
              'start': 15,
              'target': 12,
              'step': 1,
              'direction': 'down',
            },
            expected: ['14', '13', '12'],
          ),
          onValueChanged: values.add,
        ),
      );

      final line = tester.getRect(
        find.byKey(const ValueKey('numberline-step-line')),
      );
      await tester.tapAt(Offset(dxForValue(tester, 14, 0, 20), line.center.dy));
      await tester.pump();
      await tester.tapAt(Offset(dxForValue(tester, 13, 0, 20), line.center.dy));
      await tester.pump();
      await tester.tapAt(Offset(dxForValue(tester, 12, 0, 20), line.center.dy));
      await tester.pump();
      expect(values.last, '14,13,12');
    });

    testWidgets('step 2 taps every other number', (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        NumberlineStepWidget(
          problem: _problem(
            template: 'numberline_step',
            display: {
              'range': [0, 20],
              'start': 6,
              'target': 12,
              'step': 2,
              'direction': 'up',
            },
            expected: ['8', '10', '12'],
          ),
          onValueChanged: values.add,
        ),
      );

      final line = tester.getRect(
        find.byKey(const ValueKey('numberline-step-line')),
      );
      for (final v in [8, 10, 12]) {
        await tester.tapAt(Offset(dxForValue(tester, v, 0, 20), line.center.dy));
        await tester.pump();
      }
      expect(values.last, '8,10,12');
    });

    testWidgets('a new problem resets the run and reports ""', (tester) async {
      final values = <String>[];
      final first = _problem(
        template: 'numberline_step',
        display: {
          'range': [0, 20],
          'start': 10,
          'target': 13,
          'step': 1,
          'direction': 'up',
        },
        expected: ['11', '12', '13'],
      );
      final second = _problem(
        template: 'numberline_step',
        display: {
          'range': [0, 20],
          'start': 5,
          'target': 8,
          'step': 1,
          'direction': 'up',
        },
        expected: ['6', '7', '8'],
      );
      await _pumpApp(
        tester,
        NumberlineStepWidget(problem: first, onValueChanged: values.add),
      );
      final lineRect = tester.getRect(
        find.byKey(const ValueKey('numberline-step-line')),
      );
      await tester.tapAt(
        Offset(dxForValue(tester, 11, 0, 20), lineRect.center.dy),
      );
      await tester.pump();
      expect(values.last, '11');

      await _pumpApp(
        tester,
        NumberlineStepWidget(problem: second, onValueChanged: values.add),
      );
      expect(values.last, '');
    });
  });

  group('ZehnerfeldReadWidget', () {
    testWidgets('structured renders one filled frame and reports the typed count',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        ZehnerfeldReadWidget(
          problem: _problem(
            template: 'zehnerfeld_read',
            display: {'count': 7, 'arrangement': 'structured'},
            expected: ['7'],
          ),
          onValueChanged: values.add,
        ),
      );

      expect(find.byType(ZehnerfeldWidget), findsOneWidget);
      expect(values, isEmpty);

      await tester.enterText(find.byType(TextField), '7');
      expect(values.last, '7');
    });

    testWidgets('two_groups renders both frames and stays editable for retry',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        ZehnerfeldReadWidget(
          problem: _problem(
            template: 'zehnerfeld_read',
            display: {
              'count': 17,
              'arrangement': 'two_groups',
              'ask': 'total',
              'split': [10, 7],
            },
            expected: ['17'],
          ),
          onValueChanged: values.add,
        ),
      );

      expect(find.byType(ZehnerfeldWidget), findsNWidgets(2));
      await tester.enterText(find.byType(TextField), '17');
      expect(values.last, '17');
      await tester.enterText(find.byType(TextField), '');
      expect(values.last, '');
      await tester.enterText(find.byType(TextField), '16');
      expect(values.last, '16');
    });

    testWidgets('a new problem clears the field and reports ""', (tester) async {
      final values = <String>[];
      final first = _problem(
        template: 'zehnerfeld_read',
        display: {'count': 7, 'arrangement': 'structured'},
        expected: ['7'],
      );
      final second = _problem(
        template: 'zehnerfeld_read',
        display: {'count': 4, 'arrangement': 'structured'},
        expected: ['4'],
      );
      await _pumpApp(
        tester,
        ZehnerfeldReadWidget(problem: first, onValueChanged: values.add),
      );
      await tester.enterText(find.byType(TextField), '7');
      expect(values.last, '7');

      await _pumpApp(
        tester,
        ZehnerfeldReadWidget(problem: second, onValueChanged: values.add),
      );
      expect(values.last, '');
    });
  });

  group('FingerbildReadWidget', () {
    testWidgets('renders the fingers and reports the typed count',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        FingerbildReadWidget(
          problem: _problem(
            template: 'fingerbild_read',
            display: {'count': 7, 'hands': 2},
            expected: ['7'],
          ),
          onValueChanged: values.add,
        ),
      );

      expect(find.byType(FingerBildWidget), findsOneWidget);
      expect(values, isEmpty);

      await tester.enterText(find.byType(TextField), '7');
      expect(values.last, '7');
    });

    testWidgets('hands: 1 renders the count on a single hand', (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        FingerbildReadWidget(
          problem: _problem(
            template: 'fingerbild_read',
            display: {'count': 4, 'hands': 1},
            expected: ['4'],
          ),
          onValueChanged: values.add,
        ),
      );

      final widget = tester.widget<FingerBildWidget>(
        find.byType(FingerBildWidget),
      );
      expect(widget.leftCount, 4);
      expect(widget.rightCount, 0);
      await tester.enterText(find.byType(TextField), '4');
      expect(values.last, '4');
    });

    testWidgets('a new problem clears the field and reports ""', (tester) async {
      final values = <String>[];
      final first = _problem(
        template: 'fingerbild_read',
        display: {'count': 7, 'hands': 2},
        expected: ['7'],
      );
      final second = _problem(
        template: 'fingerbild_read',
        display: {'count': 3, 'hands': 1},
        expected: ['3'],
      );
      await _pumpApp(
        tester,
        FingerbildReadWidget(problem: first, onValueChanged: values.add),
      );
      await tester.enterText(find.byType(TextField), '7');
      expect(values.last, '7');

      await _pumpApp(
        tester,
        FingerbildReadWidget(problem: second, onValueChanged: values.add),
      );
      expect(values.last, '');
    });
  });

  group('StellenwerttafelReadWidget', () {
    testWidgets('mode read renders the table and reports the typed number',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        StellenwerttafelReadWidget(
          problem: _problem(
            template: 'stellenwerttafel_read',
            display: {
              'mode': 'read',
              'columns': ['Z', 'E'],
              'number': 47,
              'tens': 4,
              'ones': 7,
            },
            expected: ['47'],
          ),
          onValueChanged: values.add,
        ),
      );

      expect(find.byType(StellenwerttafelWidget), findsOneWidget);
      final inTable = find.descendant(
        of: find.byType(StellenwerttafelWidget),
        matching: find.byType(Text),
      );
      expect(inTable, findsNWidgets(4));
      expect(
        find.descendant(
          of: find.byType(StellenwerttafelWidget),
          matching: find.text('4'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(StellenwerttafelWidget),
          matching: find.text('7'),
        ),
        findsOneWidget,
      );
      expect(values, isEmpty);

      await tester.enterText(find.byType(TextField), '47');
      expect(values.last, '47');
    });

    testWidgets('mode sum_rows renders two counter rows and a plus sign',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        StellenwerttafelReadWidget(
          problem: _problem(
            template: 'stellenwerttafel_read',
            display: {
              'mode': 'sum_rows',
              'op': '+',
              'columns': ['Z', 'E'],
              'row1': [2, 4],
              'row2': [1, 3],
              'value': 37,
            },
            expected: ['37'],
          ),
          onValueChanged: values.add,
        ),
      );

      expect(find.text('+'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '37');
      expect(values.last, '37');
    });

    testWidgets('mode sum_rows with minus subtracts column-wise',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        StellenwerttafelReadWidget(
          problem: _problem(
            template: 'stellenwerttafel_read',
            display: {
              'mode': 'sum_rows',
              'op': '-',
              'columns': ['Z', 'E'],
              'row1': [5, 6],
              'row2': [2, 3],
              'value': 33,
            },
            expected: ['33'],
          ),
          onValueChanged: values.add,
        ),
      );

      expect(find.text('-'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '33');
      expect(values.last, '33');
      await tester.enterText(find.byType(TextField), '');
      expect(values.last, '');
      await tester.enterText(find.byType(TextField), '34');
      expect(values.last, '34');
    });

    testWidgets('a new problem clears the field and reports ""', (tester) async {
      final values = <String>[];
      final first = _problem(
        template: 'stellenwerttafel_read',
        display: {
          'mode': 'read',
          'columns': ['Z', 'E'],
          'number': 47,
          'tens': 4,
          'ones': 7,
        },
        expected: ['47'],
      );
      final second = _problem(
        template: 'stellenwerttafel_read',
        display: {
          'mode': 'sum_rows',
          'op': '+',
          'columns': ['Z', 'E'],
          'row1': [2, 4],
          'row2': [1, 3],
          'value': 37,
        },
        expected: ['37'],
      );
      await _pumpApp(
        tester,
        StellenwerttafelReadWidget(problem: first, onValueChanged: values.add),
      );
      await tester.enterText(find.byType(TextField), '47');
      expect(values.last, '47');

      await _pumpApp(
        tester,
        StellenwerttafelReadWidget(problem: second, onValueChanged: values.add),
      );
      expect(values.last, '');
    });
  });

  group('NumberlineLocateWidget', () {
    Offset pointFor(WidgetTester tester, int value, int lo, int hi) {
      final rect = tester.getRect(
        find.byKey(const ValueKey('numberline-locate-line')),
      );
      final dx =
          rect.left + 16 + (rect.width - 32) * (value - lo) / (hi - lo);
      return Offset(dx, rect.center.dy);
    }

    testWidgets('tapping snaps to the nearest tick and reports the value',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        NumberlineLocateWidget(
          problem: _problem(
            template: 'numberline_locate',
            display: {
              'range': [0, 100],
              'value': 64,
            },
            expected: ['64'],
          ),
          onValueChanged: values.add,
        ),
      );

      expect(values, isEmpty, reason: 'nothing tapped yet');

      await tester.tapAt(pointFor(tester, 64, 0, 100));
      await tester.pump();
      expect(values.last, '64');

      await tester.tapAt(pointFor(tester, 25, 0, 100));
      await tester.pump();
      expect(values.last, '25', reason: 're-tapping moves the marker');
    });

    testWidgets('boundary: tapping the very edge snaps to the clamped endpoint',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        NumberlineLocateWidget(
          problem: _problem(
            template: 'numberline_locate',
            display: {
              'range': [0, 100],
              'value': 50,
            },
            expected: ['50'],
          ),
          onValueChanged: values.add,
        ),
      );

      final rect = tester.getRect(
        find.byKey(const ValueKey('numberline-locate-line')),
      );
      await tester.tapAt(Offset(rect.left, rect.center.dy));
      await tester.pump();
      expect(values.last, '0', reason: 'the left edge clamps to rangeLo');
      await tester.tapAt(Offset(rect.right - 1, rect.center.dy));
      await tester.pump();
      expect(values.last, '100', reason: 'the right edge clamps to rangeHi');
    });

    testWidgets('a new problem clears the marker and reports ""',
        (tester) async {
      final values = <String>[];
      final first = _problem(
        template: 'numberline_locate',
        display: {
          'range': [0, 100],
          'value': 64,
        },
        expected: ['64'],
      );
      final second = _problem(
        template: 'numberline_locate',
        display: {
          'range': [0, 20],
          'value': 8,
        },
        expected: ['8'],
      );
      await _pumpApp(
        tester,
        NumberlineLocateWidget(problem: first, onValueChanged: values.add),
      );
      await tester.tapAt(pointFor(tester, 64, 0, 100));
      await tester.pump();
      expect(values.last, '64');

      await _pumpApp(
        tester,
        NumberlineLocateWidget(problem: second, onValueChanged: values.add),
      );
      expect(values.last, '');
      expect(tester.getRect(find.byKey(const ValueKey('numberline-locate-line'))),
          isNot(equals(Rect.zero)));
    });
  });

  group('PictureCompareWidget', () {
    testWidgets('question more renders both frames and reports the tapped side',
        (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        PictureCompareWidget(
          problem: _problem(
            template: 'picture_compare',
            display: {'left': 8, 'right': 5, 'question': 'more'},
            expected: ['left'],
          ),
          onValueChanged: values.add,
        ),
      );

      expect(find.byType(ZehnerfeldWidget), findsNWidgets(2));
      expect(find.text('links'), findsOneWidget);
      expect(find.text('rechts'), findsOneWidget);
      expect(values, isEmpty, reason: 'nothing tapped yet');

      await tester.tap(find.byKey(const ValueKey('compare-left')));
      await tester.pump();
      expect(values.last, 'left');
      await tester.tap(find.byKey(const ValueKey('compare-right')));
      await tester.pump();
      expect(values.last, 'right', reason: 're-tapping the other side re-picks');
    });

    testWidgets('question less reports the smaller side', (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        PictureCompareWidget(
          problem: _problem(
            template: 'picture_compare',
            display: {'left': 3, 'right': 9, 'question': 'less'},
            expected: ['left'],
          ),
          onValueChanged: values.add,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('compare-left')));
      await tester.pump();
      expect(values.last, 'left');
      expect(find.text('links ✓'), findsOneWidget,
          reason: 'the selection is signalled with a check mark');
    });

    testWidgets('question difference types |left - right|', (tester) async {
      final values = <String>[];
      await _pumpApp(
        tester,
        PictureCompareWidget(
          problem: _problem(
            template: 'picture_compare',
            display: {'left': 1, 'right': 10, 'question': 'difference'},
            expected: ['9'],
          ),
          onValueChanged: values.add,
        ),
      );

      expect(find.byType(ZehnerfeldWidget), findsNWidgets(2));
      await tester.enterText(find.byType(TextField), '9');
      expect(values.last, '9');
      await tester.enterText(find.byType(TextField), '');
      expect(values.last, '');
      await tester.enterText(find.byType(TextField), '8');
      expect(values.last, '8');
    });

    testWidgets('a new problem resets the selection and reports ""',
        (tester) async {
      final values = <String>[];
      final first = _problem(
        template: 'picture_compare',
        display: {'left': 8, 'right': 5, 'question': 'more'},
        expected: ['left'],
      );
      final second = _problem(
        template: 'picture_compare',
        display: {'left': 2, 'right': 7, 'question': 'less'},
        expected: ['right'],
      );
      await _pumpApp(
        tester,
        PictureCompareWidget(problem: first, onValueChanged: values.add),
      );
      await tester.tap(find.byKey(const ValueKey('compare-left')));
      await tester.pump();
      expect(values.last, 'left');

      await _pumpApp(
        tester,
        PictureCompareWidget(problem: second, onValueChanged: values.add),
      );
      expect(values.last, '');
      expect(find.text('links ✓'), findsNothing);
    });
  });
}
