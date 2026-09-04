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
  static const _connectionErrorMessage =
      'Verbindung zum Server nicht möglich. Bitte Internetverbindung prüfen.';
  static const _unreadableResponseMessage =
      'Antwort vom Server konnte nicht gelesen werden.';
  static const _requestTimeout = Duration(seconds: 12);

  final http.Client _client;
  StudentAuthService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $supabaseAnonKey',
        'apikey': supabaseAnonKey,
      };

  /// Runs [request] and always comes back with a status code and a decoded
  /// body, never a raw exception: a network failure (dropped wifi, DNS,
  /// timeout, ...) becomes a typed, German-messaged [StudentAuthException],
  /// and a non-JSON body (an HTML captive-portal or proxy error page — both
  /// common on school wifi) decodes to an empty map instead of throwing a
  /// raw [FormatException]. This also fixes the ordering bug where decoding
  /// used to run before the status check, so a non-JSON error response
  /// crashed before its HTTP failure was ever reported.
  Future<({Map<String, dynamic> body, int statusCode})> _send(
    Future<http.Response> Function() request,
  ) async {
    late http.Response res;
    try {
      res = await request().timeout(_requestTimeout);
    } catch (_) {
      throw const StudentAuthException(_connectionErrorMessage);
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      body = const {};
    }

    return (body: body, statusCode: res.statusCode);
  }

  Future<Roster> fetchRoster({
    required String schoolSlug,
    required String classCode,
  }) async {
    final result = await _send(() => _client.post(
          Uri.parse('$supabaseFunctionsUrl/student-auth/roster'),
          headers: _headers,
          body: jsonEncode({
            'school_slug': schoolSlug,
            'class_code': classCode.trim().toUpperCase(),
          }),
        ));

    if (result.statusCode != 200) {
      throw StudentAuthException(
          result.body['error'] as String? ?? 'Anmeldung nicht möglich');
    }

    try {
      return Roster(
        classId: result.body['class_id'] as String? ?? '',
        requirePin: result.body['require_pin'] as bool? ?? false,
        students: ((result.body['students'] as List?) ?? const [])
            .map((s) => RosterEntry.fromJson((s as Map).cast<String, dynamic>()))
            .toList(),
      );
    } catch (_) {
      throw const StudentAuthException(_unreadableResponseMessage);
    }
  }

  Future<StudentSession> login({required String studentId, String? pin}) async {
    final result = await _send(() => _client.post(
          Uri.parse('$supabaseFunctionsUrl/student-auth/login'),
          headers: _headers,
          body: jsonEncode({'student_id': studentId, if (pin != null) 'pin': pin}),
        ));

    if (result.statusCode != 200) {
      throw StudentAuthException(
          result.body['error'] as String? ?? 'Anmeldung nicht möglich');
    }

    final StudentSession session;
    try {
      session = StudentSession(
        token: result.body['token'] as String,
        studentId: result.body['student_id'] as String,
        displayName: result.body['display_name'] as String? ?? '',
      );
    } catch (_) {
      throw const StudentAuthException(_unreadableResponseMessage);
    }

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
