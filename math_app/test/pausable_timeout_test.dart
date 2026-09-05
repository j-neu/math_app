import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/services/pausable_timeout.dart';

/// PausableTimeout backs the diagnostic's Hilfe-pauses-the-clock behaviour
/// (§4.9). Tests drive a manually-stepped fake clock in lockstep with
/// tester.pump() so Timer firing (virtualized by flutter_test's FakeAsync)
/// and elapsed-time computation stay consistent.
void main() {
  testWidgets('fires after the full budget when never paused', (tester) async {
    var fakeNow = DateTime(2026, 1, 1);
    var fired = false;
    final timer = PausableTimeout(
      budget: const Duration(seconds: 10),
      onTimeout: () => fired = true,
      now: () => fakeNow,
    );
    timer.start();

    fakeNow = fakeNow.add(const Duration(seconds: 9));
    await tester.pump(const Duration(seconds: 9));
    expect(fired, isFalse);

    fakeNow = fakeNow.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(fired, isTrue);
  });

  testWidgets('pause stops both the timeout and elapsed from advancing',
      (tester) async {
    var fakeNow = DateTime(2026, 1, 1);
    var fired = false;
    final timer = PausableTimeout(
      budget: const Duration(seconds: 10),
      onTimeout: () => fired = true,
      now: () => fakeNow,
    );
    timer.start();

    fakeNow = fakeNow.add(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 4));
    timer.pause();
    expect(timer.elapsed, const Duration(seconds: 4));

    // 20 s pass while paused — nothing should fire and elapsed must not grow.
    fakeNow = fakeNow.add(const Duration(seconds: 20));
    await tester.pump(const Duration(seconds: 20));
    expect(fired, isFalse);
    expect(timer.elapsed, const Duration(seconds: 4));

    timer.resume();
    // 5 of the remaining 6 s — must not have fired yet.
    fakeNow = fakeNow.add(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
    expect(fired, isFalse);

    fakeNow = fakeNow.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(fired, isTrue);
    expect(timer.elapsed.inSeconds, 11);
  });

  testWidgets('cancel stops the timer from firing', (tester) async {
    var fakeNow = DateTime(2026, 1, 1);
    var fired = false;
    final timer = PausableTimeout(
      budget: const Duration(seconds: 5),
      onTimeout: () => fired = true,
      now: () => fakeNow,
    );
    timer.start();
    timer.cancel();

    fakeNow = fakeNow.add(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 10));
    expect(fired, isFalse);
  });
}
