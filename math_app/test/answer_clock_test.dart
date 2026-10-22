import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/services/answer_clock.dart';

void main() {
  test('elapsed is zero before start', () {
    final clock = AnswerClock(now: () => DateTime(2026, 1, 1, 10));
    expect(clock.started, isFalse);
    expect(clock.elapsed, Duration.zero);
  });

  test('startIfIdle only starts once; elapsed counts from first start', () {
    var t = DateTime(2026, 1, 1, 10, 0, 0);
    final clock = AnswerClock(now: () => t);
    clock.startIfIdle();
    t = t.add(const Duration(seconds: 5));
    clock.startIfIdle(); // second trigger (e.g. audio end after typing) is ignored
    t = t.add(const Duration(seconds: 7));
    expect(clock.elapsed, const Duration(seconds: 12));
  });

  test('stop freezes elapsed', () {
    var t = DateTime(2026, 1, 1, 10);
    final clock = AnswerClock(now: () => t);
    clock.startIfIdle();
    t = t.add(const Duration(seconds: 3));
    clock.stop();
    t = t.add(const Duration(seconds: 100));
    expect(clock.elapsed, const Duration(seconds: 3));
  });
}
