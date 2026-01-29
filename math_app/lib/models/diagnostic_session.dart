import 'diagnostic_result.dart';

class DiagnosticSession {
  final DateTime date;
  final List<DiagnosticResult> results;
  final List<String> generatedSkillTags;

  DiagnosticSession({
    required this.date,
    required this.results,
    required this.generatedSkillTags,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'results': results.map((result) => result.toJson()).toList(),
      'generatedSkillTags': generatedSkillTags,
    };
  }

  factory DiagnosticSession.fromJson(Map<String, dynamic> json) {
    return DiagnosticSession(
      date: DateTime.parse(json['date']),
      results: (json['results'] as List)
          .map((result) => DiagnosticResult.fromJson(result))
          .toList(),
      generatedSkillTags: (json['generatedSkillTags'] as List).cast<String>(),
    );
  }
}
