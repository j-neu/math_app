import 'dart:convert';
import 'package:http/http.dart' as http;

const _supabaseUrl = 'https://zzxqeqwffexythqzjkxr.supabase.co/functions/v1';
const _anonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp6eHFlcXdmZmV4eXRocXpqa3hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5NjE5ODUsImV4cCI6MjA5NDUzNzk4NX0.Wj_77px6gCPR97W0kOlVhaqDnZp9WqwmtoJlCGHsR4A';

const _headers = {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $_anonKey',
  'apikey': _anonKey,
};

class ServerResult {
  final int questionNumber;
  final bool wasCorrect;
  final double? responseTimeSeconds;
  final String status; // 'attempted' | 'skipped' | 'timeout'
  final String? userAnswer;

  const ServerResult({
    required this.questionNumber,
    required this.wasCorrect,
    required this.responseTimeSeconds,
    required this.status,
    required this.userAnswer,
  });

  factory ServerResult.fromJson(Map<String, dynamic> j) => ServerResult(
        questionNumber: j['question_number'] as int,
        wasCorrect: j['was_correct'] as bool? ?? false,
        responseTimeSeconds: (j['response_time_seconds'] as num?)?.toDouble(),
        status: j['status'] as String? ?? 'attempted',
        userAnswer: j['user_answer'] as String?,
      );
}

class ApiService {
  // Exchanges a session ticket UUID for a session ID (QR-code flow).
  Future<({String sessionId, bool resumed, List<ServerResult> priorResults})>
      startSession(String ticketId) => _startSessionRaw({'ticket_id': ticketId});

  // Resolves a school slug + 4-char code and starts (or resumes) a session
  // (keyboard-code / short-URL flow).
  Future<({String sessionId, bool resumed, List<ServerResult> priorResults})>
      startSessionByCode(String schoolSlug, String code) =>
          _startSessionRaw({'school_slug': schoolSlug, 'short_code': code.toUpperCase()});

  Future<({String sessionId, bool resumed, List<ServerResult> priorResults})>
      _startSessionRaw(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$_supabaseUrl/diagnostic-sessions'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 410) throw const SessionExpiredException();
    if (response.statusCode == 404) throw const TicketNotFoundException();
    if (response.statusCode != 200) {
      throw ApiException('diagnostic-sessions failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawResults = (data['results'] as List?) ?? const [];
    return (
      sessionId: data['session_id'] as String,
      resumed: data['resumed'] as bool? ?? false,
      priorResults: rawResults
          .map((r) => ServerResult.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  // Posts a single question result to the backend.
  // Returns true when the session is now complete (all questions answered).
  Future<bool> postResult({
    required String sessionId,
    required int questionNumber,
    required bool wasCorrect,
    required double responseTimeSeconds,
    required String status, // 'attempted' | 'skipped' | 'timeout'
    String? userAnswer,
  }) async {
    final response = await http.post(
      Uri.parse('$_supabaseUrl/diagnostic-results'),
      headers: _headers,
      body: jsonEncode({
        'session_id': sessionId,
        'question_number': questionNumber,
        'was_correct': wasCorrect,
        'response_time_seconds': responseTimeSeconds,
        'status': status,
        if (userAnswer != null && userAnswer.isNotEmpty) 'user_answer': userAnswer,
      }),
    );

    if (response.statusCode != 200) {
      throw ApiException('diagnostic-results failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['session_completed'] as bool? ?? false;
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

class SessionExpiredException implements Exception {
  const SessionExpiredException();
  @override
  String toString() => 'Ticket abgelaufen';
}

class TicketNotFoundException implements Exception {
  const TicketNotFoundException();
  @override
  String toString() => 'Ticket nicht gefunden';
}
