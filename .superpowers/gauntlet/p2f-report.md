# P2 Task 9 — PracticeScreen + session flow UI — report

**Task:** docs/superpowers/plans/2026-08-31-p2-practice-runtime.md §8 Task 9
**Branch:** `gauntlet/p2-p3-p4`
**Date:** 2026-08-31

## Scope

`lib/screens/practice_screen.dart` (new, ~520 lines), the widget-factory half
of the template registry `lib/practice/template_registry.dart` (new), a
retry-semantics change in `lib/practice/practice_controller.dart`, and the
widget tests `test/practice_screen_test.dart` (new, 5 testWidgets).

## Layout

`PracticeScreen({token, spec, level, controller?, skillStore?})` owns a
`PracticeController` (injectable for tests) and drives the session:

- **AppBar** — minimal: an X close button (`Icons.close`, tooltip "Übung
  beenden") and the skill title (`spec.titleDe`). The X opens a confirm dialog
  "Übung beenden?" with "Weiterüben" (dismiss, stay) / "Beenden" (pop).
- **starting** — centered `CircularProgressIndicator`.
- **ready / submitting** — scrollable centered column (max width 560):
  progress header ("Aufgabe X von 8" + 8 dots; done dots filled, current dot
  highlighted via border+fill — never color-only, the text carries the state),
  a representation chip derived from `spec.levelSpec(level).representation`
  (enaktiv→"Lege", ikonisch→"Sieh hin", symbolisch→"Rechne"), the
  `problem.promptDe` in a large `Card`, the template input widget built by
  `buildTemplateWidget` (keyed `template-<index>` so a new problem mounts a
  fresh widget while a retry on the same problem keeps the input alive), and a
  big (56 px) "Weiter" submit button **disabled while the template reports
  `""`**.
- **correct** — one-shot green `check_circle` scale pulse
  (`TweenAnimationBuilder`, easeOutBack) + deterministic praise
  `['Super!', 'Toll!', 'Genau so!'][problemIndex % 3]`; auto-advance after
  1.2 s via `Future.delayed` guarded by `mounted` + a generation counter, plus
  a "Weiter" button that cancels the pending timer.
- **incorrect** — decaying horizontal shake (keyed per wrong answer so a
  repeated wrong retry re-plays it) + the taxonomy hint
  (`controller.hintDe ?? 'Schau noch einmal genau hin.'`). The input stays, a
  "Nochmal" button retries, and a "Weiter" button advances.
- **finished** — summary: mastered → `Icons.emoji_events` + "Geschafft!" +
  the unlocked skill **titles** (resolved from `skillStore`; a missing store /
  unknown id degrades to no title, never a raw id), not mastered →
  "Fast geschafft!" + encouraging text; "Zurück zum Lernpfad" pops.
- **failed** — `cloud_off` icon + the controller's German message + a 56 px
  "Nochmal versuchen" button calling `controller.start()`.

Wiring: `controller.addListener` + `setState` (no ListenableBuilder because the
screen also resets the reported value on problem change); submit →
`controller.submit(value)`; on the last problem `_advance()` calls
`controller.finish()` (guarded by a `_finishRequested` flag so a double tap
cannot trigger a second `/end`; a saving spinner covers the await); a safety
net calls `finish()` if the state reaches `finished` without a verdict.

## Feedback / retry decision (and rationale)

A wrong answer is **recorded exactly once per problem**. On retry the child may
fix the answer and submit again — the controller *evaluates* the retry (so the
screen can show the correct feedback) but **never re-records** it: a new
`_recordedProblemIndices` set in `PracticeController.submit` marks a problem
index recorded on first submission and skips `recordAttempt` for retries
(reset in `start()`, so a restarted session records fresh).

Rationale: the DB contract dedupes on `(practice_session_id, problem_index)`
and the server scores mastery from the attempt set; a retry that overwrote the
wrong attempt would erase the diagnostic signal ("first attempt on this
problem"), and a retry that *added* a second row would corrupt the count and
the mastery math. Keeping exactly one record per problem preserves both
diagnostics and the offline queue's exactly-once property. This is a deliberate
product decision, not a controller omission: the retry feedback ("Super!") is
purely motivational; the attempt record stays as submitted first.

## Tests (`test/practice_screen_test.dart`)

All 5 tests run against a MockClient-backed `LearningPathService` injected via
`controller:`. Backend seeds 8 equation_solve problems (seed 7), counts
attempts, and returns a configurable `/end` verdict.

1. `full all-correct session: progress, feedback, summary, /end and submit gated on a reported value`
   — asserts title, "Aufgabe 1 von 8", "Rechne" chip, 8 progress dots, the
   submit button disabled while no value is reported, per-problem deterministic
   praise, advancing progress, then "Geschafft!", the unlocked title
   ("Vorwärtszählen bis 100" resolved from a store built on the real A1.1b
   spec), `endCalls == 1` and exactly 8 attempts.
2. `wrong answer: hint shown, retry records no second attempt, "Weiter" advances`
   — asserts the miscount hint, the input staying, a successful retry showing
   correct feedback with **1** recorded attempt for problem 0 (was_correct
   false), "Weiter" advancing, and exactly 8 attempts total at the end.
3. `exit dialog: Beenden pops the screen, Weiterüben stays`
4. `start failure shows the German error and retry works`
5. `unmount during the 1.2s feedback delay does not throw`

## Verification output

- `cd math_app && flutter test test/practice_screen_test.dart` → **All tests passed!** (+5)
- `flutter test` (full suite) → **All tests passed!** (424 tests)
- `flutter analyze` → **0 errors**; 335 lints (baseline 323) — **0 issues in
  the new files** (practice_screen.dart, template_registry.dart,
  practice_controller.dart, practice_screen_test.dart all clean).
- §9 gate greps: no `imint|pikas` refs; all child-facing strings German.

## Notes / concerns

- `practice_controller.dart` changed (retry-no-re-record); existing
  `practice_controller_test.dart` stays green — no existing test submits the
  same index twice.
- The screen resolves unlocked skill titles via the optional `skillStore`;
  `ChildPathScreen` (task 10) should pass the loaded store.
