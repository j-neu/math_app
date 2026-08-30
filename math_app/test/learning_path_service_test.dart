import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math_app/services/learning_path_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('fetchPath parses a well-formed payload', () async {
    final client = MockClient((req) async => http.Response(
          jsonEncode({
            'path_id': 'p1',
            'unlock_width': 3,
            'items': [
              {
                'skill_id': 'add-10',
                'position': 1,
                'state': 'available',
                'title_de': 'Addieren bis 10',
                'description_de': 'Zahlen bis 10 addieren',
                'color': 'blue',
                'progress': [],
              },
            ],
          }),
          200,
        ));

    final path = await LearningPathService(client: client).fetchPath('tok');

    expect(path.pathId, 'p1');
    expect(path.items, hasLength(1));
    expect(path.items.first.skillId, 'add-10');
  });

  test('fetchPath surfaces a not-yet-activated path as an empty path, not an error', () async {
    final client = MockClient((req) async => http.Response(
        jsonEncode({'path_id': null, 'items': []}), 200));

    final path = await LearningPathService(client: client).fetchPath('tok');

    expect(path.pathId, isNull);
    expect(path.items, isEmpty);
    expect(path.hasActivePath, isFalse);
  });

  test('fetchPath raises a clean, typed exception on a non-200 response', () async {
    final client = MockClient((req) async =>
        http.Response(jsonEncode({'error': 'nicht gefunden'}), 500));

    expect(
      () => LearningPathService(client: client).fetchPath('tok'),
      throwsA(isA<LearningPathException>()),
    );
  });

  test('fetchPath raises a clean, typed exception on malformed data instead of a raw TypeError', () async {
    // skill_id is a number here, not a String — LearningPath.fromJson /
    // PathItem.fromJson would otherwise throw a raw TypeError deep inside
    // the model parsing. The service must catch that and surface a
    // German-messaged, typed exception instead, with no half-built path
    // reaching the caller.
    final client = MockClient((req) async => http.Response(
          jsonEncode({
            'path_id': 'p1',
            'unlock_width': 3,
            'items': [
              {
                'skill_id': 12345,
                'position': 1,
                'state': 'available',
                'title_de': 'Kaputt',
                'description_de': 'Kaputt',
                'color': 'blue',
                'progress': [],
              },
            ],
          }),
          200,
        ));

    late Object caught;
    try {
      await LearningPathService(client: client).fetchPath('tok');
      fail('expected fetchPath to throw');
    } catch (e) {
      caught = e;
    }

    expect(caught, isA<LearningPathException>());
    expect(caught, isNot(isA<TypeError>()));
  });
}
