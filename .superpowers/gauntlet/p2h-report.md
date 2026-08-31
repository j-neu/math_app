# P2 Tasks 11–12 Report — Startup Recovery + Accessibility/ADHD Polish

**Date:** 2026-08-31
**Branch:** `gauntlet/p2-p3-p4`
**Scope:** Task 11 (app-start recovery) and Task 12 (a11y/ADHD polish of the new P2 screens).

---

## Task 11 — App-start recovery

### Design choice: `slowBandMs` for recovered sessions

`endPractice` ends a live session with the **spec's own** `slow_band_ms`
(`PracticeController.finish` → `spec.levelSpec(level).slowBandMs`). Pending
sessions, however, persist only their **session id** (`learning_path_pending_end_sessions`
is a plain list of ids); the spec is not stored alongside and is not
available at app start. So the exact band cannot be recovered — the plan's
"read it from the pending session's spec if stored" option is not possible
without changing the pending-session storage format (out of scope for a
small, focused task).

**Decision: a conservative constant default of `kRecoverySlowBandMs = 7000`**
(lower end of the middle of the band values the real specs use, 6000–9000 ms).
Deliberately conservative: too low would flag a child as "slow" too eagerly;
too high merely postpones the slow flag by one recovery run. Documented on
the constant in `lib/services/app_start_recovery.dart`.

### Wiring

- New `lib/services/app_start_recovery.dart` exposes the top-level
  `maybeRecoverPendingSessions(StudentAuthService, LearningPathService, {int slowBandMs})`
  — the injectable, unit-testable trigger. It reads `storedToken()`; a null
  token is a no-op; every failure is swallowed (silent, best-effort;
  `recoverPendingSessions` is idempotent so a stranded session simply stays
  pending for the next run).
- `lib/main.dart` `MyApp` is now a `StatefulWidget` with optional
  `authService`/`learningPathService` test seams. In `initState` it fires the
  recovery in a **post-first-frame** callback, unawaited — never blocking
  startup, never visible to the child.

### Tests (`test/app_start_recovery_test.dart`, 5 tests)

- no stored token → `/end` never called
- token + pending session (+ one queued attempt) → flushed and `/end` called **exactly once**, pending list cleared, queue drained
- network failure → silent, session stays pending
- the provided `slowBandMs` is forwarded to `/end`
- widget test: pumping the real app shell (`MyApp`) with seeded prefs fires recovery once after the first frame and still boots to the profile screen

---

## Task 12 — Accessibility + ADHD audit

Audit scope: `child_path_screen.dart`, `practice_screen.dart`, and all
`lib/widgets/templates/*` template widgets.

| # | Check (ADHD/a11y guideline) | Verdict | Fix |
|---|------------------------------|---------|-----|
| 1 | Touch targets ≥ 44×44 logical px: buttons, tiles, number-pad keys, flash "Nochmal sehen" | Mostly OK, one violation | Number-pad keys 56 px, submit/action buttons 56 px, path tiles padded InkWell, cell/bead/box targets 44 px+ already compliant. **Fixed:** flash "Nochmal sehen" was a M3 `TextButton` at the 40 px default → now `minimumSize: Size(160, 48)`. |
| 2 | No state communicated ONLY by colour | OK + one sub-item fixed | Path tiles already carry icon **and** text for lock/available/mastered/skipped (verified; existing test asserts it). **Fixed:** per-level pips were green-vs-grey dots → mastered pips now render a white `Icons.check` inside, so a green dot is never the only indicator. |
| 3 | Feedback encouraging, never punitive | OK, contrast verified | Practice wrong-answer feedback shows the taxonomy hint + gentle shake in `scheme.primary` (≈10:1), never a red "Falsch!"; retry always possible. New test asserts no "Falsch" copy and no red hint. **Fixed:** summary headline "Geschafft!" was `amber.shade800` (~2.3:1 on white, fails even large-text 3:1) → now `scheme.primary` (~10:1); the trophy icon keeps the celebration colour. |
| 4 | Contrast ≥ 4.5:1 for hint text | Borderline → fixed | Template hint lines used `Colors.black54` (~4.6:1). **Fixed:** new shared `kHintTextColor` (0xFF424242, ~12:1 on white) used by bundle_sticks / bundling / unbundling hints. Unit test computes WCAG contrast. |
| 5 | Flash (800 ms) must not be the only chance to see the pattern | OK | "Nochmal sehen" re-shows the pattern (already present). |
| 6 | Reduced motion: `MediaQuery.disableAnimations` skips the flash | Missing → fixed | `flash_subitize` now reads `MediaQuery.disableAnimationsOf` in `didChangeDependencies`; under reduced motion the pattern **never auto-hides** (stays visible while the child types) and the fade duration is zero. Widget test drives `FakeAccessibilityFeatures(disableAnimations: true)`. |
| 7 | Session length guard | OK | Session bounded by `problem_count` (8); progress header always shows "Aufgabe X von Y". No change needed. |
| 8 | Keyboard/web: `BigAnswerField` reachable by keyboard on web | OK | The `TextField` is always present; the keypad is touch-only (hidden on web). `onSubmitted`/IME `done` wired. No change needed. |
| 9 | Focus/hover: tappable tiles have visible focus indicators | OK | Path tiles use `InkWell` inside `Material` (M3 focus/hover highlight default); operator/strategy buttons and all fields are real focusable buttons/inputs. GestureDetector-based manipulative cells (beads, counters, sticks) remain touch-first by design — documented, not converted (out of scope for this pass). |
| 10 | Pending `_RekenrekFlashWidget` (legacy diagnostic flow) | Out of P2 scope | The plan's reduced-motion requirement names `flash_subitize`; the legacy widget in `manipulatives/rekenrek.dart` is untouched. |

### Tests (`test/a11y_polish_test.dart`, 5 tests + 1 added to `practice_screen_test.dart`)

- WCAG contrast unit tests: `kHintTextColor` and `scheme.primary` vs white ≥ 4.5:1
- "Nochmal sehen" ≥ 44×44
- reduced-motion flash: dots stay visible through the flash window and after re-show
- path tiles: states carry icon + text, mastered pips show a check, tiles ≥ 44 px tall
- practice screen: wrong-answer feedback shows the hint, never "Falsch", hint not red

---

## Verification

- `flutter test test/app_start_recovery_test.dart` — 5/5 pass
- `flutter test` — **441/441 pass**
- `flutter analyze` — **0 errors**, 335 warnings/infos, none in the files touched by this task (all pre-existing)
