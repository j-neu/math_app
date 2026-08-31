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

/// Best-effort, non-blocking recovery of pending practice sessions.
///
/// * Reads the stored student token; with no token it is a no-op.
/// * Otherwise calls [LearningPathService.recoverPendingSessions], which
///   re-ends each stranded session with the level band stored on it (the
///   service falls back to 7000 ms only when a legacy entry carries no band).
/// * Never throws: recovery must be silent on failure — a session that
///   still cannot complete simply stays pending for the next app run
///   (recovery is idempotent, so retrying it later neither duplicates nor
///   loses anything).
///
/// [auth] and [service] are injectable for tests.
Future<void> maybeRecoverPendingSessions(
  StudentAuthService auth,
  LearningPathService service,
) async {
  try {
    final token = await auth.storedToken();
    if (token == null) return;
    await service.recoverPendingSessions(token);
  } catch (_) {
    // Silent by design (P2 plan §8 task 11): a failed recovery must never
    // reach the child, and recoverPendingSessions is idempotent — the
    // session simply stays pending for the next run.
  }
}
