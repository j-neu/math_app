import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math_app/services/attempt_queue.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  PracticeAttempt attempt(int i, {bool correct = true}) => PracticeAttempt(
        problemIndex: i,
        problem: {'a': i, 'b': 1},
        answer: '$i',
        wasCorrect: correct,
        responseMs: 1500,
        errorCode: correct ? null : 'off_by_one',
      );

  test('queues attempts and reports them as pending', () async {
    final q = AttemptQueue();
    await q.add('ps1', attempt(0));
    await q.add('ps1', attempt(1));
    expect((await q.pending('ps1')).length, 2);
  });

  test('queues are isolated per practice session', () async {
    final q = AttemptQueue();
    await q.add('ps1', attempt(0));
    await q.add('ps2', attempt(0));
    expect((await q.pending('ps1')).length, 1);
    expect((await q.pending('ps2')).length, 1);
  });

  test('a successful flush empties the queue', () async {
    final q = AttemptQueue();
    await q.add('ps1', attempt(0));
    final sent = await q.flush('ps1', (batch) async => true);
    expect(sent, 1);
    expect(await q.pending('ps1'), isEmpty);
  });

  test('a failed flush keeps everything for the next attempt', () async {
    final q = AttemptQueue();
    await q.add('ps1', attempt(0));
    final sent = await q.flush('ps1', (batch) async => false);
    expect(sent, 0);
    expect((await q.pending('ps1')).length, 1);
  });

  test('attempts survive a new queue instance (closed browser)', () async {
    await AttemptQueue().add('ps1', attempt(0));
    expect((await AttemptQueue().pending('ps1')).length, 1);
  });

  test('re-adding the same problem_index does not duplicate', () async {
    final q = AttemptQueue();
    await q.add('ps1', attempt(3));
    await q.add('ps1', attempt(3));
    expect((await q.pending('ps1')).length, 1);
  });

  test('flushing an empty queue is a no-op that does not call send', () async {
    final q = AttemptQueue();
    var called = false;
    final sent = await q.flush('ps1', (batch) async {
      called = true;
      return true;
    });
    expect(sent, 0);
    expect(called, isFalse);
  });

  test('concurrent adds for the same session do not clobber each other', () async {
    final q = AttemptQueue();
    await Future.wait([
      for (var i = 0; i < 20; i++) q.add('ps1', attempt(i)),
    ]);
    expect((await q.pending('ps1')).length, 20);
  });

  test('pending() recovers from a corrupted queue entry instead of throwing',
      () async {
    SharedPreferences.setMockInitialValues({
      'attempt_queue_ps1': 'not-json{{{',
    });
    final q = AttemptQueue();
    expect(await q.pending('ps1'), isEmpty);
    await q.add('ps1', attempt(0));
    expect((await q.pending('ps1')).length, 1);
  });

  test(
      'one malformed element among several does not discard its siblings',
      () async {
    // Only the middle element is bad (missing every required field, so
    // PracticeAttempt.fromJson throws on it). The decode must happen
    // element-by-element: the two good attempts must survive even though
    // one entry in the same stored list is corrupt.
    SharedPreferences.setMockInitialValues({
      'attempt_queue_ps1': jsonEncode([
        attempt(0).toJson(),
        {'not': 'a valid attempt'},
        attempt(2).toJson(),
      ]),
    });
    final q = AttemptQueue();
    final pending = await q.pending('ps1');
    expect(pending.length, 2);
    expect(pending.map((a) => a.problemIndex), containsAll([0, 2]));
  });

  test(
      'flush removes only what it sent, so a concurrent append from another tab survives',
      () async {
    // Two browser tabs share localStorage but not AttemptQueue's in-memory
    // Lock. This simulates Tab B's flush: it reads [attempt 0], then while
    // its network call is "in flight" Tab A appends attempt 1 directly to
    // the shared storage (no shared lock to stop it). If flush cleared the
    // whole key on success, attempt 1 would be destroyed even though it
    // was never sent.
    final q = AttemptQueue();
    await q.add('ps1', attempt(0));

    final sent = await q.flush('ps1', (batch) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'attempt_queue_ps1',
        jsonEncode([attempt(0).toJson(), attempt(1).toJson()]),
      );
      return true;
    });

    expect(sent, 1);
    final stillPending = await q.pending('ps1');
    expect(stillPending.map((a) => a.problemIndex).toList(), [1]);
  });
}
