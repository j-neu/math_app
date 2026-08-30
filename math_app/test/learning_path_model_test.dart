import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/learning_path.dart';

void main() {
  test('parses a path payload from the edge function', () {
    final path = LearningPath.fromJson({
      'path_id': 'p1',
      'unlock_width': 3,
      'items': [
        {
          'skill_id': 'A3.1',
          'position': 0,
          'state': 'available',
          'title_de': 'Teil-Teil-Ganzes bis 10',
          'description_de': 'Zerlegt Zahlen bis 10.',
          'color': 'emerald',
          'progress': [
            {'level': 1, 'attempts': 8, 'correct': 7, 'mastered_at': '2026-08-30T10:00:00Z'},
          ],
        },
      ],
    });

    expect(path.pathId, 'p1');
    expect(path.unlockWidth, 3);
    expect(path.items.single.skillId, 'A3.1');
    expect(path.items.single.state, PathItemState.available);
    expect(path.items.single.progressForLevel(1)?.correct, 7);
    expect(path.items.single.progressForLevel(2), isNull);
  });

  test('an empty path parses without throwing', () {
    final path = LearningPath.fromJson({'path_id': null, 'items': []});
    expect(path.pathId, isNull);
    expect(path.items, isEmpty);
    expect(path.hasActivePath, isFalse);
  });

  test('unknown state falls back to locked rather than crashing', () {
    final path = LearningPath.fromJson({
      'path_id': 'p1',
      'items': [
        {'skill_id': 'A1.1', 'position': 0, 'state': 'wat', 'title_de': 'X', 'progress': []},
      ],
    });
    expect(path.items.single.state, PathItemState.locked);
  });

  test('isMastered requires all three levels', () {
    final item = PathItem.fromJson({
      'skill_id': 'A1.1', 'position': 0, 'state': 'in_progress', 'title_de': 'X',
      'progress': [
        {'level': 1, 'attempts': 8, 'correct': 8, 'mastered_at': '2026-08-30T10:00:00Z'},
        {'level': 2, 'attempts': 8, 'correct': 8, 'mastered_at': '2026-08-30T10:00:00Z'},
      ],
    });
    expect(item.isMastered, isFalse);
  });
}
