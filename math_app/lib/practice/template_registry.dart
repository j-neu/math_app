/// Widget-factory half of the template registry (P2 plan §5, §6): maps
/// `problem.template` — and, for `custom_widget`, the `custom_widget` display
/// key — to the widget that renders the input and reports the answer via
/// [buildTemplateWidget]'s [ValueChanged] callback.
///
/// Every template widget shares the construction contract
/// `({required Problem problem, required ValueChanged<String> onValueChanged})`
/// and reports `""` while no answer is set (see the template widget tasks).
library;

import 'package:flutter/widgets.dart';

import '../models/problem.dart';
import '../widgets/templates/bundle_sticks_widget.dart';
import '../widgets/templates/bundling_widget.dart';
import '../widgets/templates/compare_symbols_widget.dart';
import '../widgets/templates/drag_partition_widget.dart';
import '../widgets/templates/equation_gap_widget.dart';
import '../widgets/templates/equation_solve_widget.dart';
import '../widgets/templates/fingerbild_read_widget.dart';
import '../widgets/templates/flash_subitize_widget.dart';
import '../widgets/templates/numberline_locate_widget.dart';
import '../widgets/templates/numberline_mark_widget.dart';
import '../widgets/templates/numberline_step_widget.dart';
import '../widgets/templates/picture_compare_widget.dart';
import '../widgets/templates/place_counters_widget.dart';
import '../widgets/templates/rekenrek_set_widget.dart';
import '../widgets/templates/sequence_gap_widget.dart';
import '../widgets/templates/stellenwerttafel_read_widget.dart';
import '../widgets/templates/strategy_choice_widget.dart';
import '../widgets/templates/unbundling_widget.dart';
import '../widgets/templates/word_problem_widget.dart';
import '../widgets/templates/zehnerfeld_read_widget.dart';

/// Builds the input widget for [problem].
///
/// The fallback (`_UnavailableTemplateWidget`) is unreachable in practice —
/// [SkillSpec] validation rejects unknown templates and custom-widget keys —
/// but keeps the switch exhaustive so an unforeseen value renders a calm
/// German notice instead of a crash.
Widget buildTemplateWidget({
  required Problem problem,
  required ValueChanged<String> onValueChanged,
}) {
  return switch (problem.template) {
    'drag_partition' => DragPartitionWidget(
        problem: problem,
        onValueChanged: onValueChanged,
      ),
    'place_counters' => PlaceCountersWidget(
        problem: problem,
        onValueChanged: onValueChanged,
      ),
    'bundle_sticks' => BundleSticksWidget(
        problem: problem,
        onValueChanged: onValueChanged,
      ),
    'rekenrek_set' => RekenrekSetWidget(
        problem: problem,
        onValueChanged: onValueChanged,
      ),
    'numberline_step' => NumberlineStepWidget(
        problem: problem,
        onValueChanged: onValueChanged,
      ),
    'zehnerfeld_read' => ZehnerfeldReadWidget(
        problem: problem,
        onValueChanged: onValueChanged,
      ),
    'fingerbild_read' => FingerbildReadWidget(
        problem: problem,
        onValueChanged: onValueChanged,
      ),
    'stellenwerttafel_read' => StellenwerttafelReadWidget(
        problem: problem,
        onValueChanged: onValueChanged,
      ),
    'numberline_locate' => NumberlineLocateWidget(
        problem: problem,
        onValueChanged: onValueChanged,
      ),
    'picture_compare' => PictureCompareWidget(
        problem: problem,
        onValueChanged: onValueChanged,
      ),
    'equation_solve' => EquationSolveWidget(
        problem: problem,
        onValueChanged: onValueChanged,
      ),
    'equation_gap' => EquationGapWidget(
        problem: problem,
        onValueChanged: onValueChanged,
      ),
    'sequence_gap' => SequenceGapWidget(
        problem: problem,
        onValueChanged: onValueChanged,
      ),
    'compare_symbols' => CompareSymbolsWidget(
        problem: problem,
        onValueChanged: onValueChanged,
      ),
    'strategy_choice' => StrategyChoiceWidget(
        problem: problem,
        onValueChanged: onValueChanged,
      ),
    'word_problem' => WordProblemWidget(
        problem: problem,
        onValueChanged: onValueChanged,
      ),
    'custom_widget' => switch (problem.display['custom_widget']) {
      'bundling' => BundlingWidget(
          problem: problem,
          onValueChanged: onValueChanged,
        ),
      'unbundling' => UnbundlingWidget(
          problem: problem,
          onValueChanged: onValueChanged,
        ),
      'numberline_mark' => NumberlineMarkWidget(
          problem: problem,
          onValueChanged: onValueChanged,
        ),
      'flash_subitize' => FlashSubitizeWidget(
          problem: problem,
          onValueChanged: onValueChanged,
        ),
      _ => const _UnavailableTemplateWidget(),
    },
    _ => const _UnavailableTemplateWidget(),
  };
}

/// Calm fallback for a template the runtime does not know. Kept deliberately
/// minimal: it reports nothing, so the submit button stays disabled.
class _UnavailableTemplateWidget extends StatelessWidget {
  const _UnavailableTemplateWidget();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        'Diese Aufgabe ist gerade nicht verfügbar.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
