import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math_app/services/student_auth_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('fetchRoster returns names and avatars', () async {
    final client = MockClient((req) async => http.Response(
          jsonEncode({
            'class_id': 'c1',
            'require_pin': false,
            'students': [
              {'id': 's1', 'display_name': 'Mia', 'avatar': 'fuchs'},
              {'id': 's2', 'display_name': 'Jonas', 'avatar': 'eule'},
            ],
          }),
          200,
        ));

    final roster = await StudentAuthService(client: client)
        .fetchRoster(schoolSlug: 'lindenschule', classCode: '7k2m');

    expect(roster.students.length, 2);
    expect(roster.students.first.displayName, 'Mia');
    expect(roster.requirePin, isFalse);
  });

  test('an unknown code raises a German error', () async {
    final client = MockClient((req) async =>
        http.Response(jsonEncode({'error': 'Code nicht gefunden'}), 404));

    expect(
      () => StudentAuthService(client: client)
          .fetchRoster(schoolSlug: 'x', classCode: 'ZZZZ'),
      throwsA(isA<StudentAuthException>()
          .having((e) => e.message, 'message', 'Code nicht gefunden')),
    );
  });

  test('too many attempts surfaces the rate-limit message', () async {
    final client = MockClient((req) async => http.Response(
        jsonEncode({'error': 'Zu viele Versuche. Bitte später noch einmal probieren.'}), 429));

    expect(
      () => StudentAuthService(client: client)
          .fetchRoster(schoolSlug: 'x', classCode: 'ABCD'),
      throwsA(isA<StudentAuthException>()),
    );
  });

  test('login stores the token for the next screen', () async {
    final client = MockClient((req) async => http.Response(
          jsonEncode({'token': 'jwt-abc', 'student_id': 's1', 'display_name': 'Mia'}),
          200,
        ));

    final service = StudentAuthService(client: client);
    final session = await service.login(studentId: 's1');

    expect(session.token, 'jwt-abc');
    expect(await service.storedToken(), 'jwt-abc');
  });

  test('logout clears the stored token', () async {
    final client = MockClient((req) async => http.Response(
        jsonEncode({'token': 't', 'student_id': 's1', 'display_name': 'Mia'}), 200));
    final service = StudentAuthService(client: client);
    await service.login(studentId: 's1');
    await service.logout();
    expect(await service.storedToken(), isNull);
  });

  test('the class code is sent upper-cased and trimmed', () async {
    String? sentBody;
    final client = MockClient((req) async {
      sentBody = req.body;
      return http.Response(
          jsonEncode({'class_id': 'c1', 'require_pin': false, 'students': []}), 200);
    });

    await StudentAuthService(client: client)
        .fetchRoster(schoolSlug: 'lindenschule', classCode: ' 7k2m ');

    expect(jsonDecode(sentBody!)['class_code'], '7K2M');
  });
}
