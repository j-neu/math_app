import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

/// One row of `Research/skills_taxonomy.csv`.
class SkillCatalogEntry {
  final String skillId;
  final String category;
  final String categoryColor;
  final int cardNumber;
  final String nameDe;
  final String nameEn;
  final String descriptionDe;
  final String descriptionEn;

  SkillCatalogEntry({
    required this.skillId,
    required this.category,
    required this.categoryColor,
    required this.cardNumber,
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
    final rows = const CsvToListConverter().convert(raw, eol: '\n');

    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.length < 8) continue;
      final id = r[0].toString();
      _bySkillId[id] = SkillCatalogEntry(
        skillId: id,
        category: r[1].toString(),
        categoryColor: r[2].toString(),
        cardNumber: int.tryParse(r[3].toString()) ?? 0,
        nameDe: r[4].toString(),
        nameEn: r[5].toString(),
        descriptionDe: r[6].toString(),
        descriptionEn: r[7].toString(),
      );
    }
    _loaded = true;
  }

  SkillCatalogEntry? get(String skillId) => _bySkillId[skillId];

  Iterable<SkillCatalogEntry> get all => _bySkillId.values;
}
