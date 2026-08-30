enum PathItemState { locked, available, inProgress, mastered, skipped }

PathItemState _stateFrom(String? raw) {
  switch (raw) {
    case 'available':
      return PathItemState.available;
    case 'in_progress':
      return PathItemState.inProgress;
    case 'mastered':
      return PathItemState.mastered;
    case 'skipped':
      return PathItemState.skipped;
    default:
      return PathItemState.locked;
  }
}

class SkillProgress {
  final int level;
  final int attempts;
  final int correct;
  final DateTime? masteredAt;

  const SkillProgress({
    required this.level,
    required this.attempts,
    required this.correct,
    required this.masteredAt,
  });

  bool get isMastered => masteredAt != null;

  factory SkillProgress.fromJson(Map<String, dynamic> j) => SkillProgress(
        level: j['level'] as int? ?? 0,
        attempts: j['attempts'] as int? ?? 0,
        correct: j['correct'] as int? ?? 0,
        masteredAt: j['mastered_at'] == null
            ? null
            : DateTime.tryParse(j['mastered_at'] as String),
      );
}

class PathItem {
  final String skillId;
  final int position;
  final PathItemState state;
  final String titleDe;
  final String descriptionDe;
  final String color;
  final List<SkillProgress> progress;

  const PathItem({
    required this.skillId,
    required this.position,
    required this.state,
    required this.titleDe,
    required this.descriptionDe,
    required this.color,
    required this.progress,
  });

  SkillProgress? progressForLevel(int level) {
    for (final p in progress) {
      if (p.level == level) return p;
    }
    return null;
  }

  /// A skill counts as mastered only when all three E-I-S levels are.
  bool get isMastered =>
      [1, 2, 3].every((lv) => progressForLevel(lv)?.isMastered ?? false);

  /// The next level the child should work on: the first not yet mastered.
  int get nextLevel {
    for (final lv in [1, 2, 3]) {
      if (!(progressForLevel(lv)?.isMastered ?? false)) return lv;
    }
    return 3;
  }

  factory PathItem.fromJson(Map<String, dynamic> j) => PathItem(
        skillId: j['skill_id'] as String,
        position: j['position'] as int? ?? 0,
        state: _stateFrom(j['state'] as String?),
        titleDe: j['title_de'] as String? ?? '',
        descriptionDe: j['description_de'] as String? ?? '',
        color: j['color'] as String? ?? 'gray',
        progress: ((j['progress'] as List?) ?? const [])
            .map((p) => SkillProgress.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

class LearningPath {
  final String? pathId;
  final int unlockWidth;
  final List<PathItem> items;

  const LearningPath({
    required this.pathId,
    required this.unlockWidth,
    required this.items,
  });

  bool get hasActivePath => pathId != null && items.isNotEmpty;

  List<PathItem> get openItems => items
      .where((i) =>
          i.state == PathItemState.available || i.state == PathItemState.inProgress)
      .toList();

  factory LearningPath.fromJson(Map<String, dynamic> j) => LearningPath(
        pathId: j['path_id'] as String?,
        unlockWidth: j['unlock_width'] as int? ?? 3,
        items: ((j['items'] as List?) ?? const [])
            .map((i) => PathItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}
