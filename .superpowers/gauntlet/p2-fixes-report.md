# P2 Critic Findings 2–8, 10 — Fix Report

Date: 2026-09-01 · Branch: `gauntlet/p2-p3-p4` · Fixes by: Kilo session (deepseek/deepseek-v4-flash-0731)

Critical #1 (CORS on `learning-path`) was already fixed and deployed before this session (`3ab353a`); skipped per instructions.

---

## F2+F3 — `place_counters` `take_away` misaligned / unplayable

### Finding
`problem_generators.dart` emitted `expected: [count]` (the removed count) while the evaluator (`template_evaluator.dart:169-178`) and the widget graded the **remaining** `total − count`; the generator never put `op`/`total` operands into `display`, so the widget showed no Minusaufgabe and the child could not know how many cells to remove.

### Fix
- `lib/practice/problem_generators.dart` `_generatePlaceCounters` (take_away branch): now emits `expected: [(total - count).toString()]` and `display {total, remaining, count, op: '-'}`.
- `lib/widgets/templates/place_counters_widget.dart`:
  - renders the equation prominently above the frame — `"8 − 3 = ?"` (`Key('pc-equation')`, U+2212 minus);
  - child taps remove cells; reports the **remaining** count (`total − removed`);
  - removing more than `count` cells shows a friendly inline hint `"Nimm nur 3 Plättchen weg."` (`Key('pc-takeaway-hint')`); re-tapping a cell back clears it.
- `test/all_specs_smoke_test.dart` `manipulativeValid` now asserts `expected == remaining` for take_away (was `== count`).
- C1.1b L1 prompt ("Rechne die Minusaufgabe. Nimm die Plättchen weg und zähle, was übrig bleibt.") already matches the now-rendered equation — no change needed.

### Evidence
- `test/problem_generators_test.dart` "take_away: … expected is the REMAINING count" (updated) — passes over 200 seeds.
- `test/template_widgets_test.dart` "take_away renders 'total − count = ?', removing exactly count reports the remaining, and over-removing shows a friendly hint": display `{total:8, count:3}` → removing 3 cells reports `"5"`; 4th removal shows the hint; re-tap clears it.
- `flutter test` full suite: 453 passed (was 441).

---

## F4 — retry-after-wrong copy

### Finding
A child who fixed a wrong answer saw "Super!" praise but the first (wrong) attempt stayed the only record — the praise over-claimed.

### Decision (documented)
First-attempt-only recording is **kept**: a retry must not create a second attempt row (mastery is computed from first submissions). What changed is the feedback honesty: a correct retry now gets `"Jetzt stimmt es!"` instead of `"Super!"`, which is reserved for first-attempt-correct answers.

### Fix
- `lib/practice/practice_controller.dart`: new `isRetryCorrect` getter — set when the last submission was correct AND the problem was already recorded; reset on `start()`/`advance()`.
- `lib/screens/practice_screen.dart`: `_buildFeedbackArea` shows `"Jetzt stimmt es!"` when `isRetryCorrect`, else the deterministic praise.

### Evidence
- `test/practice_screen_test.dart` retry test now asserts `find.text('Jetzt stimmt es!')` (and `find.text('Super!')` findsNothing) while the attempt count stays 1.
- `test/practice_controller_test.dart` new test "a correct retry is flagged (isRetryCorrect) and not re-recorded".

---

## F5 — `equation_gap` `neighbor` (2 gaps)

### Finding
The widget reported the first non-empty gap; the evaluator's string match accepted either `[n-1]` OR `[n+1]`, so one filled (or one wrong) gap passed.

### Fix
- `lib/widgets/templates/equation_gap_widget.dart`: `neighbor` now requires BOTH fields and reports `"n-1,n+1"` (single filled gap → `""`).
- `lib/practice/template_evaluator.dart`: new `_evaluateNeighbor` — correct iff both expected neighbours are present (set-based, so order doesn't matter; `"5,5"`-style duplicates rejected). Routed from `evaluate` when `form == 'neighbor'`.

### Evidence
- `test/template_widgets_test.dart` "form neighbor requires BOTH gaps and reports 'n-1,n+1'".
- `test/template_evaluator_test.dart` group `equation_gap neighbor`: `"5,7"`/`"7,5"` correct; `"5"`, `"5,6"`, `"5,5"`, `""` all rejected.

---

## F6 — Semantics on interactive tap targets

### Finding
Zero `Semantics(...)` in `lib/widgets/templates` + `lib/widgets/manipulatives`; every GestureDetector/icon tap was unlabeled.

### Fix
Added labelled `Semantics(button: true, label: …, excludeSemantics: true)` wrappers to:
- `place_counters` — every frame cell ("Plättchen N wegnehmen/hinzulegen…") + Stellenwerttafel Z/E add/remove controls;
- `rekenrek_set` — each bead ("Perle N"/"Perle N unten");
- `bundle_sticks` + `bundling` — sticks ("Stäbchen N bündeln") and bundles ("Bündel N öffnen");
- `unbundling` — bundle open target;
- `drag_partition` — box counter display ("… zählt N") and the `+` zone ("… hinzufügen");
- `numberline_step` / `numberline_locate` / `numberline_mark` — the line tap area ("Zahlenstrahl");
- `strategy_choice` — strategy buttons ("Strategie: …");
- `picture_compare` — both sides ("links"/"rechts", "… gewählt" when selected);
- `flash_subitize` — "Nochmal sehen" button;
- `compare_symbols` — `<`/`>`/`=` buttons ("kleiner als"/"größer als"/"gleich").

### Evidence
- `test/template_widgets_test.dart` "tappable cells carry semantic labels for assistive tech": with `tester.ensureSemantics()`, `find.bySemanticsLabel('Plättchen 1 wegnehmen')` etc. resolve, and 10 labelled cells are found.

---

## F7 — reduced motion on the practice screen

### Finding
Only `flash_subitize` honoured `disableAnimations`; the correct-pulse and incorrect-shake (vestibular-provoking) animated unconditionally.

### Fix
- `lib/screens/practice_screen.dart`: `_buildFeedbackArea` reads `MediaQuery.disableAnimationsOf(context)` and passes `animate: !reduceMotion` to `_CorrectFeedback`/`_IncorrectFeedback`. Under reduced motion the pulse/shake are skipped but the icon + text feedback still renders.

### Evidence
- `test/practice_screen_test.dart` "reduced motion: correct feedback stays visible without the pulse and the incorrect shake is skipped" — pumps the screen under `FakeAccessibilityFeatures(disableAnimations: true)`, asserts `Super!` + check icon appear, `TweenAnimationBuilder<double>` findsNothing, and the wrong-answer hint text appears without a shake.

---

## F8 — C1.1b L2 gray (taken-away) group

### Finding
The prompt promised gray dots but the widget rendered both ten-frames indigo — no indication which group is taken away.

### Fix
- `lib/practice/problem_generators.dart` `_generateZehnerfeldRead` (ask `difference`): split is now ordered big-first `[big, small]` and `display['subtract_group'] = 1` — the smaller group is always the one taken away, so "graue Punkte werden weggenommen" leaves exactly the expected difference.
- `lib/widgets/templates/zehnerfeld_read_widget.dart`: the group at `subtract_group` is wrapped in `Opacity(key: 'zf-group-dimmer-N', opacity: 0.35)`.
- C1.1b L2 prompt already matches the rendered gray-group picture — no change needed.

### Evidence
- `test/problem_generators_test.dart` "two_groups ask difference: split is big-first and the subtracted group is flagged…" (200 seeds) + real-spec C1.1b L2 test now asserts `subtract_group == 1`.
- `test/template_widgets_test.dart` "the subtracted group is rendered with reduced opacity": `zf-group-dimmer-1` exists with opacity < 1, `zf-group-dimmer-0` absent; plus "no subtract_group means neither frame is dimmed".

---

## F10 — recovery band (pending-session storage)

### Finding
`learning_path_pending_end_sessions` stored only session ids; `app_start_recovery.dart` re-ended recovered sessions with a hard-coded `kRecoverySlowBandMs = 7000`, which could be the wrong threshold.

### Fix
- `lib/services/learning_path_service.dart`:
  - pending entries are now JSON `{"practice_session_id": …, "slow_band_ms": …}` (`_markSessionPending(id, slowBandMs)`);
  - `pendingEndSessions()` returns `List<({String practiceSessionId, int slowBandMs})>`; legacy plain-id entries parse with `defaultSlowBandMs = 7000`;
  - `recoverPendingSessions(String token)` re-ends each session with its **stored** band.
- `lib/services/app_start_recovery.dart`: removed `kRecoverySlowBandMs` and the `slowBandMs` parameter; `maybeRecoverPendingSessions` delegates to `recoverPendingSessions`, which falls back to 7000 only when a stored band is absent.

### Evidence
- `test/learning_path_service_test.dart`: pending record persists the band (5000) and recovery re-sends it; legacy plain-id entry recovers with `defaultSlowBandMs`; new test "recoverPendingSessions uses the band stored on each pending session" (9000).
- `test/app_start_recovery_test.dart`: "uses the band stored with the pending session for the /end call" (9000) and "a legacy pending entry without a band falls back to 7000 ms"; existing tests updated for the record return type.

---

## A1.2b L2 `start_range` [52, 54] → [52, 53]

The gap (index 3 of a length-5 downward run) now necessarily sits on/at the ten boundary (49/50) instead of being able to sit at 49..51.

- `docs/clean-room/skills/specs/A1.2b.json` updated.
- `scripts/sync_skill_specs.py` run → `math_app/assets/skill_specs/A1.2b.json` synced (1 copied, 35 unchanged).

---

## Verification (fresh, this session)

```
$ cd math_app && flutter test        → 453 passed, 0 failed (All tests passed!)
$ cd math_app && flutter analyze     → 335 issues, 0 errors (all info/warning; 0 in any touched file)
$ python scripts/check_specs.py      → OK: 36 specs validated
$ python scripts/sync_skill_specs.py → synced 36 skill specs (1 copied, 35 unchanged)
```

Git: `git status` clean except the untracked `.superpowers/gauntlet/*` evidence reports and `p2-login-code.png`.
