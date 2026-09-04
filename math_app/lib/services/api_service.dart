import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_config.dart';

const _headers = {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $supabaseAnonKey',
  'apikey': supabaseAnonKey,
};

/// Bound for every request to the Supabase edge functions. School Wi-Fi
/// black-holes connections (no RST) more often than it refuses them, and an
/// unbounded await would freeze the child's screen forever instead of ever
/// reaching the German error/retry states.
const _requestTimeout = Duration(seconds: 12);

Future<http.Response> _postJson(Uri uri, Map<String, dynamic> body) async {
  try {
    return await http
        .post(uri, headers: _headers, body: jsonEncode(body))
        .timeout(_requestTimeout);
  } on TimeoutException {
    throw const ApiException(
        'Zeitüberschreitung: Der Server hat nicht rechtzeitig geantwortet.');
  }
}

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
  Future<({String sessionId, bool resumed, bool alreadyCompleted, List<ServerResult> priorResults, bool retryMode, List<int> retryQuestionNumbers, bool abbreviatedMode})>
      startSession(String ticketId) => _startSessionRaw({'ticket_id': ticketId});

  // Resolves a school slug + 4-char code and starts (or resumes) a session
  // (keyboard-code / short-URL flow).
  Future<({String sessionId, bool resumed, bool alreadyCompleted, List<ServerResult> priorResults, bool retryMode, List<int> retryQuestionNumbers, bool abbreviatedMode})>
      startSessionByCode(String schoolSlug, String code) =>
          _startSessionRaw({'school_slug': schoolSlug, 'short_code': code.toUpperCase()});

  Future<({String sessionId, bool resumed, bool alreadyCompleted, List<ServerResult> priorResults, bool retryMode, List<int> retryQuestionNumbers, bool abbreviatedMode})>
      _startSessionRaw(Map<String, dynamic> body) async {
    final response = await _postJson(
        Uri.parse('$supabaseFunctionsUrl/diagnostic-sessions'), body);

    if (response.statusCode == 410) throw const SessionExpiredException();
    if (response.statusCode == 404) throw const TicketNotFoundException();
    if (response.statusCode != 200) {
      throw ApiException('diagnostic-sessions failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawResults = (data['results'] as List?) ?? const [];
    final rawRetryNums = (data['retry_question_numbers'] as List?) ?? const [];
    return (
      sessionId: data['session_id'] as String,
      resumed: data['resumed'] as bool? ?? false,
      alreadyCompleted: data['already_completed'] as bool? ?? false,
      priorResults: rawResults
          .map((r) => ServerResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      retryMode: data['retry_mode'] as bool? ?? false,
      retryQuestionNumbers: rawRetryNums.map((n) => n as int).toList(),
      abbreviatedMode: data['abbreviated_mode'] as bool? ?? false,
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
    final response = await _postJson(
        Uri.parse('$supabaseFunctionsUrl/diagnostic-results'), {
      'session_id': sessionId,
      'question_number': questionNumber,
      'was_correct': wasCorrect,
      'response_time_seconds': responseTimeSeconds,
      'status': status,
      if (userAnswer != null && userAnswer.isNotEmpty) 'user_answer': userAnswer,
    });

    if (response.statusCode != 200) {
      throw ApiException('diagnostic-results failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['session_completed'] as bool? ?? false;
  }

  // Explicitly marks a session as completed on the server.
  // Called by the web client after the last question is answered, as a safety
  // net in case any skip-result posts failed silently and the auto-complete
  // check in diagnostic-results never fired.
  Future<void> completeSession(String sessionId) async {
    final response = await _postJson(
        Uri.parse('$supabaseFunctionsUrl/diagnostic-sessions'),
        {'session_id': sessionId, 'action': 'complete'});
    if (response.statusCode != 200) {
      throw ApiException('completeSession failed (${response.statusCode}): ${response.body}');
    }
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
