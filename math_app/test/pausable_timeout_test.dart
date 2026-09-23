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

  testWidgets('extend keeps elapsed counting from the original start',
      (tester) async {
    // Regression test for the 2026-09-23 pilot bug: a child who waits out
    // the full budget, gets the timeout popup, and clicks "Weiter
    // versuchen" must have that wait still counted — a fresh start() would
    // zero it and log a multi-second stall as a 1-2s response.
    var fakeNow = DateTime(2026, 1, 1);
    var firedCount = 0;
    final timer = PausableTimeout(
      budget: const Duration(seconds: 10),
      onTimeout: () => firedCount++,
      now: () => fakeNow,
    );
    timer.start();

    // Run out the full original budget.
    fakeNow = fakeNow.add(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 10));
    expect(firedCount, 1);
    expect(timer.elapsed.inSeconds, 10);

    // "Weiter versuchen": grant more time without resetting the clock.
    timer.extend(const Duration(seconds: 10));
    expect(timer.elapsed.inSeconds, 10);

    // Answering 2s later must report ~12s elapsed, not ~2s.
    fakeNow = fakeNow.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(timer.elapsed.inSeconds, 12);
    expect(firedCount, 1);

    // The question was answered before the extended budget ran out again;
    // cancel so no timer is left pending when the test ends.
    timer.cancel();
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
