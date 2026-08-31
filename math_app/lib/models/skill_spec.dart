/// Model classes for the P3 skill specs (P2 plan §4 schema).
///
/// Parsing is strict: a document that violates the schema raises
/// [SpecFormatException] so a spec that reaches the runtime is always well
/// formed. Template-specific `params` are deliberately NOT deep-validated
/// here — `scripts/check_specs.py` is the authoritative validator for the
/// params vocabulary, while this class only extracts what the runtime needs
/// to build problems.
library;

/// The fixed template set the runtime understands (P2 plan §4).
const Set<String> kKnownTemplates = {
  'drag_partition',
  'place_counters',
  'bundle_sticks',
  'rekenrek_set',
  'numberline_step',
  'zehnerfeld_read',
  'fingerbild_read',
  'stellenwerttafel_read',
  'numberline_locate',
  'picture_compare',
  'equation_solve',
  'equation_gap',
  'sequence_gap',
  'compare_symbols',
  'strategy_choice',
  'word_problem',
  'custom_widget',
};

/// Keys of the custom-widget registry (P2 plan §5).
const Set<String> kKnownCustomWidgets = {
  'bundling',
  'unbundling',
  'numberline_mark',
  'flash_subitize',
};

/// Thrown when a skill-spec JSON document violates the P2 §4 schema.
class SpecFormatException implements Exception {
  final String message;

  const SpecFormatException(this.message);

  @override
  String toString() => 'SpecFormatException: $message';
}

/// One `error_taxonomy` entry: a construct-specific mistake, its child-facing
/// label and the encouraging hint shown on a wrong answer.
class ErrorRule {
  final String code;
  final String labelDe;
  final String hintDe;

  const ErrorRule({
    required this.code,
    required this.labelDe,
    required this.hintDe,
  });

  factory ErrorRule.fromJson(Map<String, dynamic> j) => ErrorRule(
    code: j['code'] as String? ?? '',
    labelDe: j['label_de'] as String? ?? '',
    hintDe: j['hint_de'] as String? ?? '',
  );
}

/// The `mastery` block: how many of the level's problems must be answered
/// correctly for the level to count as mastered.
class Mastery {
  final int correctOf;

  const Mastery({required this.correctOf});

  factory Mastery.fromJson(
    Map<String, dynamic> j, {
    required String specLabel,
  }) {
    final raw = j['correct_of'];
    if (raw is! num) {
      throw SpecFormatException(
        '$specLabel: "mastery.correct_of" must be an integer',
      );
    }
    final correctOf = raw.toInt();
    if (correctOf < 1) {
      throw SpecFormatException(
        '$specLabel: mastery.correct_of must be >= 1, got $correctOf',
      );
    }
    return Mastery(correctOf: correctOf);
  }
}

/// The `provenance` block: bibliographic sources and the authoring trail.
class Provenance {
  final List<String> sources;
  final String? author;
  final String? reviewedBy;

  const Provenance({required this.sources, this.author, this.reviewedBy});

  factory Provenance.fromJson(
    Map<String, dynamic> j, {
    required String specLabel,
  }) {
    final raw = j['sources'];
    if (raw is! List || raw.isEmpty) {
      throw SpecFormatException(
        '$specLabel: "provenance.sources" must be a non-empty list',
      );
    }
    return Provenance(
      sources: raw.cast<String>(),
      author: j['author'] as String?,
      reviewedBy: j['reviewed_by'] as String?,
    );
  }
}

/// One practice level (E-I-S) of a skill: template, params, problem count,
/// prompt and slow band.
class LevelSpec {
  final int level;
  final String representation;
  final String template;
  final String? customWidget;
  final Map<String, dynamic> params;
  final int problemCount;
  final String promptDe;
  final int slowBandMs;

  const LevelSpec({
    required this.level,
    required this.representation,
    required this.template,
    required this.customWidget,
    required this.params,
    required this.problemCount,
    required this.promptDe,
    required this.slowBandMs,
  });

  factory LevelSpec.fromJson(
    Map<String, dynamic> j, {
    required String specLabel,
  }) {
    void require(bool ok, String message) {
      if (!ok) throw SpecFormatException('$specLabel: $message');
    }

    final level = (j['level'] as num?)?.toInt() ?? 0;
    final label = 'level $level';
    require(
      j.containsKey('level') && j['level'] is num,
      'a level entry is missing "level"',
    );
    require(
      j['representation'] is String &&
          (j['representation'] as String).isNotEmpty,
      '$label: missing non-empty "representation"',
    );
    require(j['template'] is String, '$label: missing "template"');
    final template = j['template'] as String;
    require(
      kKnownTemplates.contains(template),
      '$label: unknown template "$template"',
    );

    final customWidget = j['custom_widget'] as String?;
    if (template == 'custom_widget') {
      require(
        customWidget != null && customWidget.isNotEmpty,
        '$label: template "custom_widget" requires a non-null "custom_widget" registry key',
      );
      require(
        kKnownCustomWidgets.contains(customWidget),
        '$label: unknown custom_widget key "$customWidget"',
      );
    } else {
      require(
        customWidget == null,
        '$label: "custom_widget" must be null unless template == "custom_widget"',
      );
    }

    require(j['params'] is Map, '$label: missing "params" object');
    final params = (j['params'] as Map).cast<String, dynamic>();

    require(j['problem_count'] is num, '$label: missing "problem_count"');
    final problemCount = (j['problem_count'] as num).toInt();
    require(
      problemCount >= 4 && problemCount <= 12,
      '$label: problem_count $problemCount not in [4, 12]',
    );

    require(
      j['prompt_de'] is String && (j['prompt_de'] as String).isNotEmpty,
      '$label: missing non-empty "prompt_de"',
    );

    require(j['slow_band_ms'] is num, '$label: missing "slow_band_ms"');
    final slowBandMs = (j['slow_band_ms'] as num).toInt();

    return LevelSpec(
      level: level,
      representation: j['representation'] as String,
      template: template,
      customWidget: customWidget,
      params: params,
      problemCount: problemCount,
      promptDe: j['prompt_de'] as String,
      slowBandMs: slowBandMs,
    );
  }

  /// Typed accessors for the template generators.

  int intParam(String key, {required int fallback}) =>
      ((params[key] as num?) ?? fallback).toInt();

  List<int> intListParam(String key) => ((params[key] as List?) ?? const [])
      .cast<num>()
      .map((e) => e.toInt())
      .toList();

  String stringParam(String key, {String fallback = ''}) =>
      params[key] as String? ?? fallback;

  String? stringParamOrNull(String key) => params[key] as String?;

  bool boolParam(String key, {bool fallback = false}) =>
      params[key] as bool? ?? fallback;
}

/// A fully parsed and validated P3 skill spec.
class SkillSpec {
  final int specVersion;
  final String skillId;
  final String constructId;
  final String domain;
  final String titleDe;
  final List<String> levelTitlesDe;
  final List<LevelSpec> levels;
  final Mastery mastery;
  final List<ErrorRule> errorTaxonomy;
  final Provenance provenance;

  const SkillSpec({
    required this.specVersion,
    required this.skillId,
    required this.constructId,
    required this.domain,
    required this.titleDe,
    required this.levelTitlesDe,
    required this.levels,
    required this.mastery,
    required this.errorTaxonomy,
    required this.provenance,
  });

  /// The level with the given 1-based number (1..3).
  LevelSpec levelSpec(int level) {
    if (level < 1 || level > levels.length) {
      throw ArgumentError.value(
        level,
        'level',
        'must be in 1..${levels.length}',
      );
    }
    return levels[level - 1];
  }

  factory SkillSpec.fromJson(Map<String, dynamic> j) {
    var specLabel = 'skill spec';
    if (j['skill_id'] is String) specLabel += ' "${j['skill_id']}"';

    void require(bool ok, String message) {
      if (!ok) throw SpecFormatException('$specLabel: $message');
    }

    require(j['spec_version'] is num, 'missing "spec_version"');
    require(
      j['skill_id'] is String && (j['skill_id'] as String).isNotEmpty,
      '"skill_id" must be a non-empty string',
    );
    require(
      j['construct_id'] is String && (j['construct_id'] as String).isNotEmpty,
      '"construct_id" must be a non-empty string',
    );
    require(
      j['domain'] is String && (j['domain'] as String).isNotEmpty,
      '"domain" must be a non-empty string',
    );
    require(
      j['title_de'] is String && (j['title_de'] as String).isNotEmpty,
      '"title_de" must be a non-empty string',
    );
    require(
      j['level_titles_de'] is List &&
          (j['level_titles_de'] as List).length == 3,
      '"level_titles_de" must be a list of exactly 3 titles',
    );

    final levelsRaw = j['levels'];
    require(levelsRaw is List, '"levels" must be a list');
    final levels = <LevelSpec>[];
    for (final raw in levelsRaw as List) {
      require(raw is Map, 'each "levels" entry must be an object');
      levels.add(
        LevelSpec.fromJson(
          (raw as Map).cast<String, dynamic>(),
          specLabel: specLabel,
        ),
      );
    }
    require(
      levels.length == 3,
      '"levels" must contain exactly 3 levels, found ${levels.length}',
    );
    require(
      levels.length == 3 &&
          levels[0].level == 1 &&
          levels[1].level == 2 &&
          levels[2].level == 3,
      '"levels" must be numbered 1, 2, 3',
    );

    require(j['mastery'] is Map, 'missing "mastery" object');
    final mastery = Mastery.fromJson(
      (j['mastery'] as Map).cast<String, dynamic>(),
      specLabel: specLabel,
    );

    for (final level in levels) {
      require(
        mastery.correctOf >= 1 && mastery.correctOf <= level.problemCount,
        'mastery.correct_of (${mastery.correctOf}) must be in [1, problem_count] '
        '(${level.problemCount}) for every level',
      );
    }

    final taxonomyRaw = j['error_taxonomy'];
    require(
      taxonomyRaw is List && taxonomyRaw.isNotEmpty,
      '"error_taxonomy" must be a non-empty list',
    );
    final taxonomy = <ErrorRule>[];
    final codes = <String>{};
    for (final raw in taxonomyRaw as List) {
      require(raw is Map, 'each "error_taxonomy" rule must be an object');
      final rule = ErrorRule.fromJson((raw as Map).cast<String, dynamic>());
      require(rule.code.isNotEmpty, 'error taxonomy rule has an empty "code"');
      require(
        rule.labelDe.isNotEmpty,
        'error taxonomy rule "${rule.code}" has an empty "label_de"',
      );
      require(
        rule.hintDe.isNotEmpty,
        'error taxonomy rule "${rule.code}" has an empty "hint_de"',
      );
      require(
        codes.add(rule.code),
        'duplicate error taxonomy code "${rule.code}"',
      );
      taxonomy.add(rule);
    }

    require(j['provenance'] is Map, 'missing "provenance" object');
    final provenance = Provenance.fromJson(
      (j['provenance'] as Map).cast<String, dynamic>(),
      specLabel: specLabel,
    );

    return SkillSpec(
      specVersion: (j['spec_version'] as num).toInt(),
      skillId: j['skill_id'] as String,
      constructId: j['construct_id'] as String,
      domain: j['domain'] as String,
      titleDe: j['title_de'] as String,
      levelTitlesDe: (j['level_titles_de'] as List).cast<String>(),
      levels: levels,
      mastery: mastery,
      errorTaxonomy: taxonomy,
      provenance: provenance,
    );
  }
}
