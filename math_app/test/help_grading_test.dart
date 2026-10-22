import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/services/help_grading.dart';

void main() {
  test('correct with up to two hints stays correct', () {
    for (final h in [0, 1, 2]) {
      expect(gradeWithHelp(textCorrect: true, helpLevel: h), isTrue);
    }
  });
  test('correct after hint 3 counts as not mastered', () {
    expect(gradeWithHelp(textCorrect: true, helpLevel: kMaxHelpLevel), isFalse);
  });
  test('wrong stays wrong', () {
    expect(gradeWithHelp(textCorrect: false, helpLevel: 0), isFalse);
  });
}
