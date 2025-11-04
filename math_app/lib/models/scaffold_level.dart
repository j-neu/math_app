/// Enumeration of scaffolding levels from the iMINT/PIKAS framework.
///
/// NOTE: The number of levels is determined by each card's "Wie kommt die
/// Handlung in den Kopf?" section. Some exercises have 3 levels, some have 4.
/// See IMINT_TO_APP_FRAMEWORK.md for complete framework documentation.
enum ScaffoldLevel {
  /// Level 1: Guided Exploration (Handlung)
  /// - Visual objects always visible
  /// - Child manipulates (tap, drag, flip)
  /// - Equation auto-displays based on manipulation
  /// - Purpose: Understand relationship through exploration
  /// - Always available (exploration phase)
  guidedExploration(1, 'Guided Exploration'),

  /// Level 2: Supported Practice (Vorstellung begins)
  /// - Visual objects still shown
  /// - Child must WRITE equation themselves
  /// - Immediate validation feedback
  /// - Purpose: Build fluency connecting visual → symbol
  /// - Unlocks after completing Level 1
  supportedPractice(2, 'Supported Practice'),

  /// Level 3: Independent Mastery (Vorstellung → Symbol)
  /// - Visual objects HIDDEN by default OR visible but no interaction
  /// - Child works from mental imagery/memory OR counts by looking only
  /// - Visual appears ONLY on error (no-fail safety net)
  /// - Purpose: Internalize the action ("in den Kopf")
  /// - Unlocks after 80% accuracy in Level 2
  independentMastery(3, 'Independent Mastery'),

  /// Level 4: Advanced Challenge (used by some exercises)
  /// - Most difficult level prescribed by certain cards
  /// - Example (Card 1): Follow with eyes only, track dots visually
  /// - Only exists for exercises where the card prescribes 4+ levels
  /// - Unlocks after demonstrating mastery in Level 3
  advancedChallenge(4, 'Advanced Challenge'),

  /// Finale Level: Summary Review (ADHD-friendly Easy→Hard→Easy flow)
  /// - Added AFTER card-prescribed levels (typically Level 4 or 5)
  /// - Easier mixed review of previous content
  /// - Purpose: Ensure positive ending, build confidence, celebrate success
  /// - This level determines "completed" status (finished + zero errors + time limits)
  /// - See IMINT_TO_APP_FRAMEWORK.md "The Finale Level" section
  finale(5, 'Finale');

  final int levelNumber;
  final String displayName;

  const ScaffoldLevel(this.levelNumber, this.displayName);

  bool get isGuidedExploration => this == ScaffoldLevel.guidedExploration;
  bool get isSupportedPractice => this == ScaffoldLevel.supportedPractice;
  bool get isIndependentMastery => this == ScaffoldLevel.independentMastery;
  bool get isAdvancedChallenge => this == ScaffoldLevel.advancedChallenge;
  bool get isFinale => this == ScaffoldLevel.finale;
}

/// Progress tracking for scaffolding levels
class ScaffoldProgress {
  /// Which level is currently active
  final ScaffoldLevel currentLevel;

  /// Whether Level 1 has been completed (explored freely)
  final bool level1Complete;

  /// Number of correct answers in Level 2
  final int level2Correct;

  /// Number of total attempts in Level 2
  final int level2Total;

  /// Whether Level 3 is unlocked (80% accuracy in Level 2)
  final bool level3Unlocked;

  /// Number of correct answers in Level 3 (for 4-level exercises)
  final int level3Correct;

  /// Number of total attempts in Level 3 (for 4-level exercises)
  final int level3Total;

  /// Whether Level 4 is unlocked (only for exercises with 4+ levels)
  final bool level4Unlocked;

  const ScaffoldProgress({
    this.currentLevel = ScaffoldLevel.guidedExploration,
    this.level1Complete = false,
    this.level2Correct = 0,
    this.level2Total = 0,
    this.level3Unlocked = false,
    this.level3Correct = 0,
    this.level3Total = 0,
    this.level4Unlocked = false,
  });

  /// Level 2 accuracy percentage (0.0 to 1.0)
  double get level2Accuracy {
    if (level2Total == 0) return 0.0;
    return level2Correct / level2Total;
  }

  /// Level 3 accuracy percentage (0.0 to 1.0)
  double get level3Accuracy {
    if (level3Total == 0) return 0.0;
    return level3Correct / level3Total;
  }

  /// Whether Level 2 is unlocked
  bool get level2Unlocked => level1Complete;

  /// Copy with updated values
  ScaffoldProgress copyWith({
    ScaffoldLevel? currentLevel,
    bool? level1Complete,
    int? level2Correct,
    int? level2Total,
    bool? level3Unlocked,
    int? level3Correct,
    int? level3Total,
    bool? level4Unlocked,
  }) {
    return ScaffoldProgress(
      currentLevel: currentLevel ?? this.currentLevel,
      level1Complete: level1Complete ?? this.level1Complete,
      level2Correct: level2Correct ?? this.level2Correct,
      level2Total: level2Total ?? this.level2Total,
      level3Unlocked: level3Unlocked ?? this.level3Unlocked,
      level3Correct: level3Correct ?? this.level3Correct,
      level3Total: level3Total ?? this.level3Total,
      level4Unlocked: level4Unlocked ?? this.level4Unlocked,
    );
  }
}
