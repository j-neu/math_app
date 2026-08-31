# P2 Task 10 — ChildPathScreen + routing + login hand-off — Report

**Date:** 2026-08-31
**Branch:** `gauntlet/p2-p3-p4`
**Status:** ✅ Complete — implemented, all tests green, analyzer 0 errors.

## Deliverables

1. **`math_app/lib/screens/child_path_screen.dart`** (new) — `ChildPathScreen({super.key, this.token, this.displayName, this.service, this.store})`.
   - Token + display name resolved from `StudentAuthService` prefs; both injectable for tests; `LearningPathService?` and `SkillSpecStore?` injectable too (store falls back to `SkillSpecStore.load()` from the bundle).
   - States: no token → "Bitte melde dich an." + "Zur Anmeldung" → `context.go('/')`; loading → spinner; load failed → German error (service message, no status codes) + "Nochmal versuchen"; no active path (`hasActivePath == false`) → "Deine Lehrkraft bereitet deinen Lernpfad gerade vor. Schau bald wieder vorbei." + "Aktualisieren"; path rendered.
   - Rendered state: AppBar header `Hallo, <name>!` + logout (`Icons.logout`, clears prefs → `context.go('/')`); overview strip (open-item count + mastered count); vertical list of tiles. Each tile: `title_de`, `description_de`, 3 level pips (filled per `progressForLevel(l).isMastered`), state visual icon + text (never colour-only): locked → lock + "Noch gesperrt" + dimmed, available → play + "Verfügbar", in_progress → refresh + "Weiterüben", mastered → green check + "Geschafft", skipped → muted circle + "Übersprungen".
   - Available/in_progress tiles tappable → `Navigator.push(PracticeScreen(token, spec: store.byId(item.skillId), level: item.nextLevel, skillStore: store))`; on return the path is refetched. Locked/skipped tiles disabled. Unknown skill id falls back to a child-friendly German message.
2. **`math_app/lib/main.dart`** — added `GoRoute(path: '/lernpfad', builder: (_, __) => const ChildPathScreen())`.
3. **`math_app/lib/screens/child_login_screen.dart`** — `_buildWelcomeStep` now shows the child's name plus a primary 56 px "Los geht's" button doing `context.go('/lernpfad')` (go_router's context); secondary "Zurück zur Anmeldung" kept.

## Tests

- `math_app/test/child_path_screen_test.dart` (new, 5 tests): (a) no-token state + button to `/`; (b) loading spinner → rendered path with mixed states (mastered/available/locked, icons + German labels + pips) via MockClient `fetchPath` + real `SkillSpecStore` built from the clean-room spec JSONs (test-only loader pattern from `skill_spec_store_test.dart`); locked tile does not navigate; tapping the available tile opens `PracticeScreen` (verified by widget presence); leaving practice via the close dialog refetches the path (`fetchCalls == 2`); (c) socket failure → German error → "Nochmal versuchen" reloads; (d) no-active-path empty state + "Aktualisieren" refetches; (e) logout clears `student_token`/`student_name` prefs and navigates to `/`.
- `math_app/test/child_login_screen_test.dart` — existing welcome test now also asserts `"Los geht's"`; new test verifies tapping it navigates to `/lernpfad` via `GoRouter`.
- `math_app/test/widget_test.dart` — unchanged (asserts `UserSelectionScreen` on `/`, no welcome-text dependency).

## Verification evidence

- `flutter test test/child_path_screen_test.dart test/child_login_screen_test.dart test/widget_test.dart` → **All tests passed** (24/24 in scope).
- `flutter analyze` → **0 errors** (335 info/warnings, all pre-existing; 0 in new/changed files).
- `flutter test` (full) → **All tests passed** (430/430).
- §9 gate: no `imint`/`pikas` references, no child-facing English strings, no raw status codes in new code.

## Concerns

- The `+12` analyzer info/warning delta vs. the P1 baseline of ~323 is entirely from earlier P2 tasks and pre-existing files; this task adds 0 issues.
- `ChildPathScreen` constructs `PracticeScreen` internally, so the "opens practice" assertion relies on `PracticeScreen` mounting (its own start request fails cleanly against the test HttpClient's 400 response, which is exactly what the assertion needs).
