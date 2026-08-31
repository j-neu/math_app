import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/problem.dart';
import 'package:math_app/widgets/templates/answer_pad.dart';
import 'package:math_app/widgets/templates/compare_symbols_widget.dart';
import 'package:math_app/widgets/templates/equation_gap_widget.dart';
import 'package:math_app/widgets/templates/equation_solve_widget.dart';
import 'package:math_app/widgets/templates/sequence_gap_widget.dart';
import 'package:math_app/widgets/templates/strategy_choice_widget.dart';
import 'package:math_app/widgets/templates/word_problem_widget.dart';

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
}
