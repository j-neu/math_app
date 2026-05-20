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
    this.successMessages = const ['Toll gemacht!', 'Gut gemacht!', 'Super!'],
    this.guidanceMessages = const [
      'Versuchen wir es auf eine andere Art.',
      'Kannst du einen anderen Weg finden?',
    ],
  });

  /// Factory constructor for Z1: Decompose 10 exercise
  factory ExerciseConfig.decompose10() {
    return const ExerciseConfig(
      id: 'Z1',
      title: 'Zahlen zerlegen bis 10',
      skillTags: ['decomposition_1', 'decomposition_3'],

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

      targetNumber: 10,
      expectedDecompositions: 11,
      maxAttemptsBeforeHint: 2,
      orderMatters: false,

      hints: [
        'Findest du noch eine andere Zerlegung?',
        'Hast du alle gefunden? Woher weißt du das?',
        'Was passiert, wenn ein Teil größer wird?',
        'Versuche, einige Plättchen umzudrehen, um neue Kombinationen zu finden.',
      ],

      successMessages: [
        'Super! Du hast eine Zerlegung gefunden!',
        'Tolle Arbeit! Du entdeckst das Muster!',
        'Erstaunlich! Du hast alle Möglichkeiten gefunden!',
        'Du bist ein Zerlegungs-Profi!',
      ],

      guidanceMessages: [
        'Schauen wir uns das auf eine andere Art an.',
        'Versuche, in die Handlungs-Ansicht zu wechseln und mit Plättchen zu arbeiten.',
        'Kannst du einige Plättchen umdrehen, um mehr Wege zu finden?',
      ],
    );
  }
}
