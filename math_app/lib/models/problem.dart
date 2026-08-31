/// Runtime problem and answer models for the practice session.
library;

/// One generated practice problem, serialised as the
/// `practice_attempts.problem` JSON payload (P2 plan §4).
class Problem {
  final String template;
  final String skillId;
  final int level;
  final int seed;
  final int index;
  final String promptDe;
  final Map<String, dynamic> display;
  final List<String> expected;

  const Problem({
    required this.template,
    required this.skillId,
    required this.level,
    required this.seed,
    required this.index,
    required this.promptDe,
    required this.display,
    required this.expected,
  });

  Map<String, dynamic> toJson() => {
    'template': template,
    'skill_id': skillId,
    'level': level,
    'seed': seed,
    'index': index,
    'prompt_de': promptDe,
    'display': display,
    'expected': expected,
  };

  factory Problem.fromJson(Map<String, dynamic> j) => Problem(
    template: j['template'] as String,
    skillId: j['skill_id'] as String,
    level: (j['level'] as num).toInt(),
    seed: (j['seed'] as num).toInt(),
    index: (j['index'] as num).toInt(),
    promptDe: j['prompt_de'] as String? ?? '',
    display: ((j['display'] as Map?) ?? const {}).cast<String, dynamic>(),
    expected: ((j['expected'] as List?) ?? const []).cast<String>(),
  );
}

/// One answered problem within a practice session: the value the child
/// submitted, whether it was correct, the response time and, on a wrong
/// answer, the matching error-taxonomy code.
class AnswerRecord {
  final String value;
  final bool wasCorrect;
  final int responseMs;
  final String? errorCode;

  const AnswerRecord({
    required this.value,
    required this.wasCorrect,
    required this.responseMs,
    this.errorCode,
  });

  Map<String, dynamic> toJson() => {
    'value': value,
    'was_correct': wasCorrect,
    'response_ms': responseMs,
    'error_code': errorCode,
  };

  factory AnswerRecord.fromJson(Map<String, dynamic> j) => AnswerRecord(
    value: j['value'] as String? ?? '',
    wasCorrect: j['was_correct'] as bool? ?? false,
    responseMs: (j['response_ms'] as num?)?.toInt() ?? 0,
    errorCode: j['error_code'] as String?,
  );
}
