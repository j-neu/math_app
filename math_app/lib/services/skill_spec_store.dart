/// Loads the bundled P3 skill specs from `assets/skill_specs/`.
///
/// Construction is strict: the first spec that violates the P2 schema raises
/// [SpecFormatException] (fail fast), so an instance only ever holds valid
/// specs and [validateAll] reports an empty error list on a healthy store.
library;

import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/skill_spec.dart';

/// Thrown when a bundled skill-spec asset cannot be loaded, e.g. because the
/// sync script was never run and the asset is missing from the bundle.
class SkillSpecAssetException implements Exception {
  final String message;

  const SkillSpecAssetException(this.message);

  @override
  String toString() => 'SkillSpecAssetException: $message';
}

/// In-memory store of every [SkillSpec] bundled with the app.
class SkillSpecStore {
  static const String assetDir = 'assets/skill_specs';

  final Map<String, SkillSpec> _specs;

  SkillSpecStore._(Map<String, SkillSpec> specs)
    : _specs = Map.unmodifiable(specs);

  /// Builds a store from a map of `id → spec JSON string`. This is the
  /// constructor seam tests use (feeding the real spec files read from disk)
  /// and the base of [load].
  factory SkillSpecStore.fromJsonMap(Map<String, String> jsonById) {
    final specs = <String, SkillSpec>{};
    for (final entry in jsonById.entries) {
      final decoded = jsonDecode(entry.value);
      if (decoded is! Map<String, dynamic>) {
        throw SpecFormatException(
          '"${entry.key}": spec JSON must be a top-level object',
        );
      }
      final spec = SkillSpec.fromJson(decoded);
      specs[spec.skillId] = spec;
    }
    return SkillSpecStore._(specs);
  }

  /// Loads every bundled spec under [assetDir], discovered through the
  /// asset manifest so no hard-coded id list needs maintenance.
  static Future<SkillSpecStore> load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final ids = manifest
        .listAssets()
        .where(
          (path) => path.startsWith('$assetDir/') && path.endsWith('.json'),
        )
        .map(
          (path) =>
              path.substring(assetDir.length + 1, path.length - '.json'.length),
        )
        .toList();

    final jsonById = <String, String>{};
    for (final id in ids) {
      try {
        jsonById[id] = await rootBundle.loadString('$assetDir/$id.json');
      } on Exception catch (cause) {
        throw SkillSpecAssetException(
          'bundled spec asset "$assetDir/$id.json" could not be loaded: $cause',
        );
      }
    }
    return SkillSpecStore.fromJsonMap(jsonById);
  }

  /// The spec for [skillId]; throws [ArgumentError] when unregistered.
  SkillSpec byId(String skillId) {
    final spec = _specs[skillId];
    if (spec == null) {
      throw ArgumentError.value(
        skillId,
        'skillId',
        'no skill spec with this id is registered',
      );
    }
    return spec;
  }

  /// Every registered skill id, sorted for determinism.
  List<String> allIds() {
    final ids = _specs.keys.toList()..sort();
    return ids;
  }

  /// Every registered spec.
  List<SkillSpec> allSpecs() => _specs.values.toList();

  /// Human-readable validation errors for the store's specs; empty when all
  /// are valid. Construction is strict, so this is normally empty — it lets
  /// callers ask "is the bundle healthy?" in one call instead of catching
  /// [SpecFormatException] themselves.
  List<String> validateAll() {
    final errors = <String>[];
    for (final spec in _specs.values) {
      final problem = _validateSpec(spec);
      if (problem != null) errors.add('${spec.skillId}: $problem');
    }
    return errors;
  }

  static String? _validateSpec(SkillSpec spec) {
    if (spec.levels.length != 3) {
      return 'expected exactly 3 levels, got ${spec.levels.length}';
    }
    for (final level in spec.levels) {
      if (level.problemCount < 4 || level.problemCount > 12) {
        return 'level ${level.level}: problem_count ${level.problemCount} outside [4, 12]';
      }
      if (level.slowBandMs <= 0) {
        return 'level ${level.level}: slow_band_ms missing';
      }
      if (spec.mastery.correctOf < 1 ||
          spec.mastery.correctOf > level.problemCount) {
        return 'level ${level.level}: mastery.correct_of ${spec.mastery.correctOf} '
            'not in [1, ${level.problemCount}]';
      }
    }
    final codes = <String>{};
    for (final rule in spec.errorTaxonomy) {
      if (rule.code.isEmpty) {
        return 'empty error taxonomy code';
      }
      if (rule.hintDe.isEmpty) {
        return 'error "${rule.code}" has an empty hint_de';
      }
      if (!codes.add(rule.code)) {
        return 'duplicate error taxonomy code "${rule.code}"';
      }
    }
    return null;
  }
}
