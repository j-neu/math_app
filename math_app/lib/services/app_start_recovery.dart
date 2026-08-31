/// App-start recovery of stranded practice sessions (P2 plan §8 task 11).
///
/// [LearningPathService.endPractice] leaves a session "pending" when its
/// final flush or `/end` call did not complete; nothing else ever revisits
/// an old `practiceSessionId`, so [LearningPathService.recoverPendingSessions]
/// is the only thing that can still deliver that child's last answer. The P2
/// plan mandates calling it at app start, guarded by a stored student token.
/// This module hosts that call as an injectable, unit-testable top-level
/// function so the app shell can fire it best-effort without blocking
/// startup or ever surfacing an error to the child.
library;

import 'learning_path_service.dart';
import 'student_auth_service.dart';

/// Conservative slow-band fallback used when a stranded session is recovered
/// at app start.
///
/// A session ends with its spec's own `slow_band_ms`, but pending sessions
/// persist only their id (`learning_path_pending_end_sessions` is a list of
/// session ids) — the spec is not available at app start, so the band cannot
/// be recovered from it. 7000 ms is the middle of the band values the real
/// specs use (6000–9000 ms) and is deliberately conservative: too low would
/// flag a child as "slow" too eagerly, too high merely postpones the flag.
/// `PracticeController.finish` still uses the exact spec value during the
/// live session.
const int kRecoverySlowBandMs = 7000;

/// Best-effort, non-blocking recovery of pending practice sessions.
///
/// * Reads the stored student token; with no token it is a no-op.
/// * Otherwise calls [LearningPathService.recoverPendingSessions].
/// * Never throws: recovery must be silent on failure — a session that
///   still cannot complete simply stays pending for the next app run
///   (recovery is idempotent, so retrying it later neither duplicates nor
///   loses anything).
///
/// [auth] and [service] are injectable for tests.
Future<void> maybeRecoverPendingSessions(
  StudentAuthService auth,
  LearningPathService service, {
  int slowBandMs = kRecoverySlowBandMs,
}) async {
  try {
    final token = await auth.storedToken();
    if (token == null) return;
    await service.recoverPendingSessions(token, slowBandMs: slowBandMs);
  } catch (_) {
    // Silent by design (P2 plan §8 task 11): a failed recovery must never
    // reach the child, and recoverPendingSessions is idempotent — the
    // session simply stays pending for the next run.
  }
}
