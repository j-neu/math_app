import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/services/diagnostic_audio.dart';

void main() {
  test('asset paths', () {
    expect(DiagnosticAudio.questionAsset(24),
        'assets/audio/diagnostic/q24_frage.mp3');
    expect(DiagnosticAudio.hintAsset(24, 2),
        'assets/audio/diagnostic/q24_hilfe2.mp3');
  });
  test('hint stage out of range throws', () {
    expect(() => DiagnosticAudio.hintAsset(24, 0), throwsRangeError);
    expect(() => DiagnosticAudio.hintAsset(24, 4), throwsRangeError);
  });
}
