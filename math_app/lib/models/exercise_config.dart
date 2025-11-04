/// Configuration model for exercises based on iMINT and PIKAS research.
///
/// This model captures the complete pedagogical structure of an exercise,
/// following the three key questions from iMINT Arbeitskarten:
/// 1. Worum geht es? (What's it about?)
/// 2. Worauf ist zu achten? (What to pay attention to?)
/// 3. Wie kommt die Handlung in den Kopf? (How does action become mental?)
class ExerciseConfig {
  /// Unique identifier for the exercise (e.g., 'Z1', 'C1')
  final String id;

  /// Display title for the exercise
  final String title;

  /// Skill tags this exercise addresses (e.g., ['decomposition_1', 'decomposition_3'])
  final List<String> skillTags;

  // ========== Pedagogical Metadata ==========

  /// Source Arbeitskarte reference (e.g., "PIKAS Card 9: Zahlen zerlegen")
  final String sourceCard;

  /// What mathematical concept does this teach? (Worum geht es?)
  final String concept;

  /// What should be observed or emphasized? (Worauf ist zu achten?)
  final List<String> observationPoints;

  /// How does the action become internalized? (Wie kommt die Handlung in den Kopf?)
  final String internalizationPath;

  // ========== Exercise Configuration ==========

  /// Target number for this exercise (e.g., 10 for "Decompose 10")
  final int targetNumber;

  /// Number of decompositions expected (e.g., 11 for decomposing 10: 0+10 through 10+0)
  final int? expectedDecompositions;

  /// Maximum number of attempts before showing hint
  final int maxAttemptsBeforeHint;

  /// Whether order matters (e.g., is 3+7 different from 7+3?)
  final bool orderMatters;

  // ========== Hints & Feedback ==========

  /// Hints to provide when child struggles (from PIKAS "Gezielte Impulse")
  final List<String> hints;

  /// Positive feedback messages for correct answers
  final List<String> successMessages;

  /// Constructive guidance for incorrect answers (no "wrong"!)
  final List<String> guidanceMessages;

  const ExerciseConfig({
    required this.id,
    required this.title,
    required this.skillTags,
    required this.sourceCard,
    required this.concept,
    required this.observationPoints,
    required this.internalizationPath,
    required this.targetNumber,
    this.expectedDecompositions,
    this.maxAttemptsBeforeHint = 2,
    this.orderMatters = false,
    this.hints = const [],
    this.successMessages = const ['Great job!', 'Well done!', 'Excellent!'],
    this.guidanceMessages = const [
      'Let\'s try a different way to see this.',
      'Can you find another way?',
    ],
  });

  /// Factory constructor for Z1: Decompose 10 exercise
  factory ExerciseConfig.decompose10() {
    return const ExerciseConfig(
      id: 'Z1',
      title: 'Decompose 10',
      skillTags: ['decomposition_1', 'decomposition_3'],

      // Pedagogical metadata from PIKAS Card 9
      sourceCard: 'PIKAS Card 9: Zahlen zerlegen',
      concept: 'Understanding part-whole relationships: 10 can be split into pairs (10+0, 9+1, 8+2, etc.)',
      observationPoints: [
        'Gegensinniges Verändern: As one part increases (+1), other decreases (-1)',
        'Systematic finding: Can child find ALL decompositions without missing any?',
        'Pattern recognition: Children should notice the inverse relationship',
      ],
      internalizationPath: 'Start with physical Wendeplättchen (flip counters) in Action view → '
          'Progress to seeing decomposition table in Image view → '
          'Master symbolic equations in Symbol view (10 = ___ + ___)',

      // Exercise configuration
      targetNumber: 10,
      expectedDecompositions: 11, // 0+10, 1+9, 2+8, ..., 10+0
      maxAttemptsBeforeHint: 2,
      orderMatters: false, // 3+7 same as 7+3 for this exercise

      // Hints from PIKAS "Gezielte Impulse"
      hints: [
        'Can you find another decomposition? (Findest du noch eine andere Zerlegung?)',
        'Have you found them all? How do you know? (Hast du alle gefunden? Woher weißt du das?)',
        'What happens when one part gets larger? (Was passiert, wenn ein Teil größer wird?)',
        'Try flipping the counters to see different combinations.',
      ],

      successMessages: [
        'Excellent! You found a decomposition!',
        'Great work! You\'re discovering the pattern!',
        'Amazing! You found all the ways to make 10!',
        'You\'re a decomposition expert!',
      ],

      guidanceMessages: [
        'Let\'s look at this in a different way.',
        'Try switching to the Action view to see it with counters.',
        'Can you flip some counters to find more ways?',
      ],
    );
  }
}
