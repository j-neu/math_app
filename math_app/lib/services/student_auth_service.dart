import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_config.dart';

class StudentAuthException implements Exception {
  final String message;
  const StudentAuthException(this.message);
  @override
  String toString() => message;
}

class RosterEntry {
  final String id;
  final String displayName;
  final String? avatar;
  const RosterEntry({required this.id, required this.displayName, required this.avatar});

  factory RosterEntry.fromJson(Map<String, dynamic> j) => RosterEntry(
        id: j['id'] as String,
        displayName: j['display_name'] as String? ?? '',
        avatar: j['avatar'] as String?,
      );
}

class Roster {
  final String classId;
  final bool requirePin;
  final List<RosterEntry> students;
  const Roster({required this.classId, required this.requirePin, required this.students});
}

class StudentSession {
  final String token;
  final String studentId;
  final String displayName;
  const StudentSession({
    required this.token,
    required this.studentId,
    required this.displayName,
  });
}

class StudentAuthService {
  static const _tokenKey = 'student_token';
  static const _nameKey = 'student_name';

  final http.Client _client;
  StudentAuthService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $supabaseAnonKey',
        'apikey': supabaseAnonKey,
      };

  Future<Roster> fetchRoster({
    required String schoolSlug,
    required String classCode,
  }) async {
    final res = await _client.post(
      Uri.parse('$supabaseFunctionsUrl/student-auth/roster'),
      headers: _headers,
      body: jsonEncode({
        'school_slug': schoolSlug,
        'class_code': classCode.trim().toUpperCase(),
      }),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw StudentAuthException(body['error'] as String? ?? 'Anmeldung nicht möglich');
    }

    return Roster(
      classId: body['class_id'] as String? ?? '',
      requirePin: body['require_pin'] as bool? ?? false,
      students: ((body['students'] as List?) ?? const [])
          .map((s) => RosterEntry.fromJson((s as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  Future<StudentSession> login({required String studentId, String? pin}) async {
    final res = await _client.post(
      Uri.parse('$supabaseFunctionsUrl/student-auth/login'),
      headers: _headers,
      body: jsonEncode({'student_id': studentId, if (pin != null) 'pin': pin}),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw StudentAuthException(body['error'] as String? ?? 'Anmeldung nicht möglich');
    }

    final session = StudentSession(
      token: body['token'] as String,
      studentId: body['student_id'] as String,
      displayName: body['display_name'] as String? ?? '',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.token);
    await prefs.setString(_nameKey, session.displayName);
    return session;
  }

  Future<String?> storedToken() async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);

  Future<String?> storedName() async =>
      (await SharedPreferences.getInstance()).getString(_nameKey);

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
  }
}
