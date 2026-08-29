import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

/// One row of `Research/skills_taxonomy.csv` (new taxonomy, tasks.md R3.3):
/// skill_id, domain, construct_id, color, title_de, title_en, description_de,
/// description_en. `nameDe`/`nameEn` map to title_de/title_en.
class SkillCatalogEntry {
  final String skillId;
  final String domain; // Domain letter A–D
  final String constructId; // e.g. 'A1.1'
  final String color; // e.g. 'amber', 'indigo', 'emerald', 'violet'
  final String nameDe;
  final String nameEn;
  final String descriptionDe;
  final String descriptionEn;

  SkillCatalogEntry({
    required this.skillId,
    required this.domain,
    required this.constructId,
    required this.color,
    required this.nameDe,
    required this.nameEn,
    required this.descriptionDe,
    required this.descriptionEn,
  });
}

/// Process-wide cache of the skill taxonomy CSV. Replaces the per-service
/// loader that previously lived in `PdfReportService._loadSkillMetadata`.
class SkillCatalog {
  SkillCatalog._();
  static final SkillCatalog instance = SkillCatalog._();

  final Map<String, SkillCatalogEntry> _bySkillId = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('Research/skills_taxonomy.csv');
    _bySkillId.addAll(parse(raw));
    _loaded = true;
  }

  /// Pure parse of the taxonomy CSV text; used by [load] and by
  /// [loadFromCsv] so tests do not need the asset bundle.
  static Map<String, SkillCatalogEntry> parse(String csv) {
    final rows = const CsvToListConverter()
        .convert(csv.replaceAll('\r\n', '\n'), eol: '\n');
    final map = <String, SkillCatalogEntry>{};

    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.length < 8) continue;
      final id = r[0].toString();
      map[id] = SkillCatalogEntry(
        skillId: id,
        domain: r[1].toString(),
        constructId: r[2].toString(),
        color: r[3].toString(),
        nameDe: r[4].toString(),
        nameEn: r[5].toString(),
        descriptionDe: r[6].toString(),
        descriptionEn: r[7].toString(),
      );
    }
    return map;
  }

  /// Builds a standalone catalog from raw CSV text (test-friendly; no asset
  /// bundle). Prefer [SkillCatalog.instance] for runtime lookups.
  static SkillCatalog loadFromCsv(String csv) {
    final catalog = SkillCatalog._();
    catalog._bySkillId.addAll(parse(csv));
    catalog._loaded = true;
    return catalog;
  }

  SkillCatalogEntry? get(String skillId) => _bySkillId[skillId];

  Iterable<SkillCatalogEntry> get all => _bySkillId.values;
}
