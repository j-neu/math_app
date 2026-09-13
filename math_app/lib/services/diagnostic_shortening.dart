import '../models/diagnostic_question.dart';

/// Abbreviated-diagnostic break-off, construct-keyed (Jakob's 2026-09-13
/// premise: a skill tested across ZR10 -> ZR20 -> ZR100 needs no harder level
/// once an easier one is failed).
///
/// The core test orders every construct's items easy -> medium -> hard. The
/// shortened mode uses that order as its gate: once a child has answered an
/// item of a construct WRONG, the remaining items of the SAME construct that
/// are strictly harder carry no new diagnostic information and are skipped.
/// Items of equal difficulty are still presented even when the numbers get
/// larger -- a "double 20" after a failed "double 7" tests the same level at a
/// round number and may well be solved, so skipping it would remove signal.
///
/// Two cross-construct dependencies ride on top of that per-construct ladder
/// (see [FamilyDependencies]):
///  - a block rule: failing ANY level of one construct fully skips another
///    construct that presupposes it (e.g. failing to double at all makes the
///    near-double strategy item unanswerable by its intended method).
///  - a mirror rule: failing `count_forward` at a given level also gates
///    `count_backward` at that SAME level and beyond ("can't count forward,
///    can't count backward either"); passing `count_forward` at a level
///    leaves `count_backward` to be judged normally at that level, per
///    Jakob's "then we go step by step by Zahlenraum again."
///
/// A failure never gates constructs outside these explicit dependencies:
/// insight is preserved in every other construct down to the level the child
/// demonstrably cannot exceed.
class ConstructGates {
  /// Whether shortening is active for this run (abbreviated_mode ticket).
  final bool abbreviated;

  /// Per construct: highest difficulty rank the child has answered wrong.
  final Map<String, int> _failedRank = {};

  /// Constructs fully skipped by a [FamilyDependencies.blockRules] trigger,
  /// regardless of their own difficulty rank.
  final Set<String> _blockedConstructs = {};

  ConstructGates({required this.abbreviated});

  /// Records an answered (presented) question. Skipped questions are never
  /// passed here -- they carry no signal and must not raise a gate.
  void noteAnswered(DiagnosticQuestion question, bool wasCorrect) {
    if (!abbreviated || wasCorrect) return;
    final construct = question.constructId;
    final rank = question.difficulty?.rank;
    if (construct == null || rank == null) return;

    final previous = _failedRank[construct] ?? -1;
    if (rank > previous) _failedRank[construct] = rank;

    for (final rule in FamilyDependencies.blockRules) {
      if (rule.triggers.contains(construct)) {
        _blockedConstructs.addAll(rule.blocks);
      }
    }
    for (final rule in FamilyDependencies.mirrorRules) {
      if (rule.trigger != construct) continue;
      final mirroredFloor = rank - 1;
      final currentDependent = _failedRank[rule.dependent] ?? -1;
      if (mirroredFloor > currentDependent) {
        _failedRank[rule.dependent] = mirroredFloor;
      }
    }
  }

  /// Decides whether [question] is skipped because an EASIER item of the same
  /// construct has already been failed, because a dependency construct has
  /// been fully blocked, or because a mirrored construct's gate applies.
  bool shouldSkip(DiagnosticQuestion question) {
    if (!abbreviated) return false;
    final construct = question.constructId;
    final rank = question.difficulty?.rank;
    if (construct == null || rank == null) return false;
    if (_blockedConstructs.contains(construct)) return true;
    final failed = _failedRank[construct];
    if (failed == null) return false;
    return rank > failed;
  }

  /// Difficulty of the hardest wrong answer so far in [construct], or null.
  int? failedRankOf(String construct) => _failedRank[construct];

  void clear() {
    _failedRank.clear();
    _blockedConstructs.clear();
  }
}

/// Failing any level of ANY of [triggers] fully skips every construct in
/// [blocks], regardless of the blocked construct's own difficulty rank.
class FamilyBlockRule {
  final Set<String> triggers;
  final Set<String> blocks;
  const FamilyBlockRule({required this.triggers, required this.blocks});
}

/// Failing [trigger] at rank R also marks [dependent] as failed at rank
/// (R - 1) -- so [dependent]'s item at that SAME level, and everything
/// harder, is gated too, while easier levels of [dependent] are unaffected.
class FamilyMirrorRule {
  final String trigger;
  final String dependent;
  const FamilyMirrorRule({required this.trigger, required this.dependent});
}

/// Explicit cross-construct dependencies confirmed by Jakob on 2026-09-13.
/// Deliberately a short, hand-curated list rather than an inferred graph --
/// each entry documents a specific pedagogical judgment call, not a pattern
/// to generalize from.
class FamilyDependencies {
  FamilyDependencies._();

  static const List<FamilyBlockRule> blockRules = [
    // Step-counting (by 2/5/10) presupposes plain sequential counting works
    // at all; without it, step-counting items are pure frustration items.
    FamilyBlockRule(
      triggers: {'count_forward', 'count_backward'},
      blocks: {
        'skip2_forward',
        'skip2_backward',
        'skip5_forward_zr100',
        'skip5_backward_zr100',
        'skip10_forward_zr100',
        'skip10_backward_zr100',
      },
    ),
    // The near-double strategy items are explicitly solved BY doubling
    // (e.g. "8+7 via near-double 7+7=14, +1"); without doubling/halving
    // fluency the item can't be solved by its intended method.
    FamilyBlockRule(
      triggers: {'double', 'halve'},
      blocks: {'derive_via_near_double_add', 'derive_via_near_double_sub'},
    ),
    // The 10-1/10+1 derive-via-10 items rely on knowing complements of 10,
    // which is exactly the complete_to_10 skill.
    FamilyBlockRule(
      triggers: {'complete_to'},
      blocks: {
        'derive_via_10_add_minus1',
        'derive_via_10_add_plus1',
        'derive_via_10_sub',
      },
    ),
  ];

  static const List<FamilyMirrorRule> mirrorRules = [
    FamilyMirrorRule(trigger: 'count_forward', dependent: 'count_backward'),
  ];
}

/// Construct id used for gating. An explicit `SkipGroup` CSV value merges
/// several skill ids into one family (e.g. count_forward_zr20 +
/// count_forward_zr100 -> "count_forward"); otherwise a question's own
/// (first) skill id IS its construct, so a skill with no sibling at another
/// Zahlenraum never gates anything.
String? constructIdFrom(String? skipGroup, List<String> skills) {
  if (skipGroup != null && skipGroup.isNotEmpty) return skipGroup;
  if (skills.isNotEmpty) return skills.first;
  return null;
}

final RegExp _zrPattern = RegExp(r'ZR(\d+)');

/// Difficulty rung derived from the Zahlenraum column. ZR10/ZR20/ZR100 map to
/// easy/medium/hard. A row listing more than one value (e.g. "ZR10, ZR20")
/// uses the first -- those rows are helper/target pairs that share one skill
/// id and one Zahlenraum string across both rows, so they always land on the
/// same rung and never gate each other.
QuestionDifficulty? difficultyFromZahlenraum(String? zahlenraum) {
  if (zahlenraum == null) return null;
  final m = _zrPattern.firstMatch(zahlenraum);
  if (m == null) return null;
  return switch (m.group(1)) {
    '10' => QuestionDifficulty.easy,
    '20' => QuestionDifficulty.medium,
    '100' => QuestionDifficulty.hard,
    _ => null,
  };
}
