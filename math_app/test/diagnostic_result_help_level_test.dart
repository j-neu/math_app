import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/diagnostic_result.dart';
import 'package:math_app/services/api_service.dart';

void main() {
  test('DiagnosticResult round-trips helpLevel, defaulting to 0', () {
    final r = DiagnosticResult(
        questionId: '1',
        wasCorrect: true,
        responseTimeSeconds: 2,
        helpLevel: 2);
    expect(DiagnosticResult.fromJson(r.toJson()).helpLevel, 2);
    expect(
        DiagnosticResult.fromJson({
          'questionId': '1',
          'wasCorrect': true,
          'responseTimeSeconds': 1
        }).helpLevel,
        0);
  });
  test('ServerResult parses help_level, defaulting to 0', () {
    expect(
        ServerResult.fromJson({'question_number': 3, 'help_level': 3})
            .helpLevel,
        3);
    expect(ServerResult.fromJson({'question_number': 3}).helpLevel, 0);
  });
}
