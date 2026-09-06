/// The child-facing practice session screen (P2 plan §8 task 9).
///
/// Owns a [PracticeController] and drives the whole session: start →
/// per-problem input → submit → feedback → advance → finish. Layout is
/// progress (dots + "Aufgabe X von Y"), a representation chip ("Lege" /
/// "Sieh hin" / "Rechne"), the prompt in a large card, the template input
/// widget (selected via [buildTemplateWidget]), a big submit button gated on
/// the template reporting a value, feedback (correct: pulse + praise, then
/// auto-advance after 1.2 s; incorrect: gentle shake + taxonomy hint, the
/// child may retry), and a mastered / not-mastered summary.
///
/// The controller is injectable ([controller]) so widget tests can wire a
/// MockClient-backed [LearningPathService]; a [skillStore] lets the summary
/// resolve the server's `unlocked_skill_ids` to child-facing titles.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/problem.dart';
import '../models/skill_spec.dart';
import '../practice/practice_controller.dart';
import '../practice/template_registry.dart';
import '../services/skill_spec_store.dart';

/// The child-facing practice session screen.
class PracticeScreen extends StatefulWidget {
  final String token;
  final SkillSpec spec;

  /// 1..3, selecting the level inside [spec].
  final int level;

  /// Optional controller for tests; when omitted the screen builds and owns
  /// one wired to the real [LearningPathService].
  final PracticeController? controller;

  /// Optional spec store used to turn `masteryResult.unlocked` skill ids
  /// into child-facing titles on the summary.
  final SkillSpecStore? skillStore;

  const PracticeScreen({
    super.key,
    required this.token,
    required this.spec,
    required this.level,
    this.controller,
    this.skillStore,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final PracticeController _controller =
      widget.controller ??
      PracticeController(
        token: widget.token,
        spec: widget.spec,
        level: widget.level,
      );

  /// The value the template widget last reported; the submit button stays
  /// disabled while this is empty.
  String _lastValue = '';

  /// Problem index the reported value belongs to, so a new problem resets
  /// `_lastValue` even before the template widget reports its (empty) state.
  int _lastProblemIndex = -1;

  /// Invalidates pending auto-advance timers whenever the flow moves on.
  int _feedbackGeneration = 0;

  /// Bumped per wrong answer so a repeated incorrect state re-plays the
  /// shake animation.
  int _incorrectCount = 0;

  /// True while `finish()` is in flight on the last problem; hides the
  /// action buttons so the child cannot trigger a second `/end`.
  bool _finishRequested = false;

  PracticeState? _lastState;

  static const List<String> _praise = ['Super!', 'Toll!', 'Genau so!'];

  LevelSpec get _levelSpec => widget.spec.levelSpec(widget.level);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    if (_controller.state == PracticeState.starting) {
      // Deferred so the first synchronous notifyListeners from start() does
      // not hit setState during initState.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.start();
      });
    }
  }

  @override
  void dispose() {
    _feedbackGeneration++;
    _controller.removeListener(_onControllerChanged);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (_controller.problemIndex != _lastProblemIndex) {
      _lastProblemIndex = _controller.problemIndex;
      _lastValue = '';
    }
    final state = _controller.state;
    if (state != _lastState) {
      _lastState = state;
      if (state == PracticeState.correct) _scheduleAutoAdvance();
      if (state == PracticeState.incorrect) _incorrectCount++;
    }
    if (state == PracticeState.starting ||
        state == PracticeState.finished ||
        state == PracticeState.failed) {
      _finishRequested = false;
    }
    // Safety net: the summary must not appear without a mastery verdict.
    if (state == PracticeState.finished && _controller.masteryResult == null) {
      _controller.finish();
    }
    setState(() {});
  }

  void _onValueChanged(String value) {
    _lastValue = value;
    setState(() {});
  }

  /// Whether the current value is a submittable answer. Every template
  /// reports a value as soon as input exists; the submit button follows.
  /// The tap-line (`numberline_step`) is the exception (§3a 2026-09-06): its
  /// steps are correct by construction, so a partial run is not an answer —
  /// submitting mid-run would record a wrong attempt and let a single lucky
  /// tick skip the whole counting task. The full run must be tapped first.
  bool get _canSubmit {
    if (_lastValue.isEmpty) return false;
    final problem = _controller.currentProblem;
    if (problem == null) return false;
    if (problem.template == 'numberline_step') {
      return _lastValue == problem.expected.join(',');
    }
    return true;
  }

  Future<void> _submit() async {
    if (_lastValue.isEmpty) return;
    await _controller.submit(_lastValue);
  }

  /// Advances to the next problem, or — after the last one — asks the
  /// controller to finish the session.
  void _advance() {
    if (!mounted || _finishRequested || _controller.problemCount == 0) return;
    _feedbackGeneration++;
    if (_controller.problemIndex + 1 >= _controller.problemCount) {
      setState(() => _finishRequested = true);
      _controller.finish();
    } else {
      _controller.advance();
    }
  }

  /// After a correct answer the session auto-advances once the child has had
  /// time to read the praise (1.2 s). The "Weiter" button cancels it.
  void _scheduleAutoAdvance() {
    final generation = ++_feedbackGeneration;
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 1200)).then((_) {
        if (!mounted || generation != _feedbackGeneration) return;
        if (_controller.state == PracticeState.correct) _advance();
      }),
    );
  }

  Future<void> _confirmClose() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Übung beenden?'),
        content: const Text('Möchtest du die Übung beenden?'),
        actions: [
          SizedBox(
            height: 52,
            child: TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Weiterüben', style: TextStyle(fontSize: 18)),
            ),
          ),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Beenden', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      // NOTE (integration-critic F5): this pops without telling the server.
      // The practice_session keeps ended_at = null (a dangling row) until the
      // /end path runs. A safe fix needs a product decision (an explicit
      // abandon action or an inactivity threshold) — ending here and letting
      // the server score partial attempts would be wrong. Document-only.
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const ValueKey('practice-close'),
          tooltip: 'Übung beenden',
          icon: const Icon(Icons.close, size: 32),
          onPressed: _confirmClose,
        ),
        title: Text(widget.spec.titleDe),
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_controller.state) {
      case PracticeState.starting:
        return const Center(child: CircularProgressIndicator());
      case PracticeState.failed:
        return _buildFailed(context);
      case PracticeState.finished:
        return _buildSummary(context);
      case PracticeState.ready:
      case PracticeState.submitting:
      case PracticeState.correct:
      case PracticeState.incorrect:
        return _buildSession(context);
    }
  }

  Widget _buildFailed(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _controller.errorMessage ??
                    'Es hat nicht geklappt. Bitte noch einmal versuchen.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _controller.start,
                  child: const Text(
                    'Nochmal versuchen',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSession(BuildContext context) {
    final problem = _controller.currentProblem;
    if (problem == null) return const Center(child: CircularProgressIndicator());
    final state = _controller.state;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProgress(context),
              const SizedBox(height: 12),
              _buildRepresentationChip(context),
              const SizedBox(height: 16),
              _buildPromptCard(context, problem),
              const SizedBox(height: 16),
              // Keyed per problem so a new problem mounts a fresh template
              // widget (clearing its input), while a retry on the same
              // problem keeps the widget — and the child's input — alive.
              KeyedSubtree(
                key: ValueKey('template-${problem.index}'),
                child: buildTemplateWidget(
                  problem: problem,
                  onValueChanged: _onValueChanged,
                ),
              ),
              const SizedBox(height: 20),
              ..._buildFeedbackArea(context, state),
              const SizedBox(height: 12),
              _buildActionArea(context, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final index = _controller.problemIndex;
    final count = _controller.problemCount;
    return Column(
      children: [
        Text(
          'Aufgabe ${index + 1} von $count',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              Container(
                key: ValueKey('progress-dot-$i'),
                width: 22,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < index
                      ? scheme.primary
                      : (i == index
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerHighest),
                  border: Border.all(
                    color: i == index ? scheme.primary : scheme.outlineVariant,
                    width: i == index ? 3 : 1,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRepresentationChip(BuildContext context) {
    final label = switch (_levelSpec.representation) {
      'enaktiv' => 'Lege',
      'ikonisch' => 'Sieh hin',
      'symbolisch' => 'Rechne',
      _ => '',
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPromptCard(BuildContext context, Problem problem) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Text(
          problem.promptDe,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFeedbackArea(BuildContext context, PracticeState state) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    switch (state) {
      case PracticeState.correct:
        // A correct retry of an already-recorded problem gets honest
        // feedback; "Super!" is reserved for first-attempt-correct answers.
        final praise = _controller.isRetryCorrect
            ? 'Jetzt stimmt es!'
            : _praise[_controller.problemIndex % _praise.length];
        return [
          _CorrectFeedback(
            key: ValueKey('correct-${_controller.problemIndex}'),
            praise: praise,
            animate: !reduceMotion,
          ),
        ];
      case PracticeState.incorrect:
        return [
          _IncorrectFeedback(
            key: ValueKey('incorrect-$_incorrectCount'),
            hint: _controller.hintDe ?? 'Schau noch einmal genau hin.',
            animate: !reduceMotion,
          ),
        ];
      default:
        return const [];
    }
  }

  Widget _buildActionArea(BuildContext context, PracticeState state) {
    if (_finishRequested) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'Deine Antworten werden gespeichert…',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      );
    }
    switch (state) {
      case PracticeState.ready:
      case PracticeState.submitting:
        return _submitButton(
          _canSubmit && state == PracticeState.ready,
          'Weiter',
          _submit,
        );
      case PracticeState.correct:
        return _submitButton(true, 'Weiter', _advance);
      case PracticeState.incorrect:
        // The retry is the emphasised action; "Weiter" (skip past the
        // recorded wrong attempt without fixing) stays available but visually
        // secondary — two equal primary buttons after an error read as
        // ambiguous to a 7-year-old (§3a 2026-09-05).
        return Row(
          children: [
            Expanded(
              child: _submitButton(_lastValue.isNotEmpty, 'Nochmal', _submit),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 56,
                child: TextButton(
                  onPressed: _advance,
                  child: const Text(
                    'Weiter',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _submitButton(
    bool enabled,
    String label,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        child: Text(
          label,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final result = _controller.masteryResult;
    final scheme = Theme.of(context).colorScheme;
    // The primary verdict is the SESSION result, not the whole-skill one:
    // a child who aces the session (e.g. 8/8) has "Geschafft!" even when the
    // skill still has further levels; "Fast geschafft!" is reserved for a
    // session that did not reach the mastery threshold (integration-critic F3).
    final sessionMastered = _controller.sessionMastered;
    final celebrated = sessionMastered || (result?.mastered ?? false);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                celebrated ? Icons.emoji_events : Icons.flag,
                size: 72,
                color: celebrated ? Colors.amber.shade700 : scheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                celebrated ? 'Geschafft!' : 'Fast geschafft!',
                // Dark primary on the surface, not amber: amber.shade800 is
                // only ~2.3:1 on white (fails even the large-text 3:1
                // threshold). The trophy icon keeps the celebration colour;
                // the text itself must stay readable (≈10:1).
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: celebrated ? scheme.primary : scheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildSummaryMessage(result),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Zurück zum Lernpfad',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSummaryMessage(MasteryResult? result) {
    if (result == null) {
      return const [
        Text(
          'Deine Antworten sind gespeichert.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ];
    }
    if (_controller.sessionMastered) {
      final remainingLevels = widget.spec.levels.length - _controller.level;
      final unlocked = result.mastered
          ? result.unlocked.map(_titleForSkill).where((t) => t.isNotEmpty).toList()
          : const <String>[];
      return [
        Text(
          'Du hast alle ${_controller.problemCount} Aufgaben richtig.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        // The skill may still have further levels even though the session was
        // mastered — say so instead of implying failure.
        if (!result.mastered && remainingLevels > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              remainingLevels == 1
                  ? 'Noch 1 Stufe bis die Kompetenz ganz geschafft ist.'
                  : 'Noch $remainingLevels Stufen bis die Kompetenz ganz '
                        'geschafft ist.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, height: 1.4),
            ),
          ),
        if (result.mastered && unlocked.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Du hast eine neue Fähigkeit geöffnet:',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          for (final title in unlocked)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ];
    }
    return const [
      Text(
        'Du hast schon viel geschafft. Übe bald weiter, '
        'dann schaffst du es ganz sicher!',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, height: 1.4),
      ),
    ];
  }

  /// Resolves a server-reported skill id to its German title; empty when the
  /// store does not carry it (never a raw technical id on the summary).
  String _titleForSkill(String skillId) {
    final store = widget.skillStore;
    if (store == null) return '';
    try {
      return store.byId(skillId).titleDe;
    } on ArgumentError {
      return '';
    }
  }
}

/// Green check with a one-shot scale pulse and the deterministic praise text.
/// Under reduced motion the pulse is skipped but the feedback stays visible.
class _CorrectFeedback extends StatelessWidget {
  final String praise;
  final bool animate;

  const _CorrectFeedback({
    super.key,
    required this.praise,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final green = Colors.green.shade700;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, size: 72, color: green),
        const SizedBox(height: 8),
        Text(
          praise,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: green,
          ),
        ),
      ],
    );
    if (!animate) return content;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: content,
    );
  }
}

/// Gentle horizontal shake (decaying) plus the taxonomy hint. The widget is
/// keyed per wrong answer so a second wrong attempt re-plays the shake.
/// Under reduced motion the shake is skipped but the hint stays visible.
class _IncorrectFeedback extends StatelessWidget {
  final String hint;
  final bool animate;

  const _IncorrectFeedback({
    super.key,
    required this.hint,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.refresh, size: 28, color: scheme.primary),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            hint,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
    if (!animate) return content;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (context, t, child) {
        final dx = math.sin(t * 6 * math.pi) * (1 - t) * 12;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: content,
    );
  }
}
