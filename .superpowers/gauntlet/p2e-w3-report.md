# P2 Task 8 (part 2) — Custom interaction template widgets

**Date:** 2026-08-31
**Branch:** `gauntlet/p2-p3-p4`
**Scope:** P2 plan §8 Task 8 part 2 — the 4 `custom_widget` registry widgets in `lib/widgets/templates/`, TDD (test-first per widget, green before moving on).

## Widgets implemented (same contract: `Problem problem`, `ValueChanged<String> onValueChanged`)

1. **`flash_subitize_widget.dart`** (`FlashSubitizeWidget`, A2.1)
   - Shows the dot pattern (`display.display == "dots"`, one dot per `display.count`, keyed `flash-dot-i`) or a single-rod Rekenrek (`"rekenrek"`) for `display.flash_ms` (800 ms), then fades out via `AnimatedOpacity` — the extracted `RekenrekFlashWidget` Timer + fade pattern.
   - Child types the count into the shared `BigAnswerField`; `onValueChanged` reports every typed value.
   - **"Nochmal sehen"** button (`flash-reshow`) re-shows the pattern for another `flash_ms` (ADHD / working-memory support, required).
   - Flash timer cancelled in `dispose` (and on problem change).

2. **`bundling_widget.dart`** (`BundlingWidget`, B1.2)
   - Renders `display.count` loose sticks (44 px tap targets, keyed `stick-i`). Tapping a stick bundles 10 into a Zehnerbündel (grouped/highlighted, keyed `bundle-i`); tapping a bundle opens it.
   - Reports `"Z Zehner, E Einer"` on every change; `""` until at least one bundle exists when count ≥ 10.
   - Matches the `_evaluateBundles` evaluator (`10·Z + E == count`).

3. **`unbundling_widget.dart`** (`UnbundlingWidget`, B1.3)
   - Shows a bundled picture (`display.tens` tappable bundles keyed `ub-bundle-i` + `display.ones` singles). Tapping a bundle opens it into 10 singles (visual "opened" state, `StaebchenOeffnenWidget` pattern).
   - Once at least one bundle is open, the child types the total number of Einer (`10·tens + ones`) into a `BigAnswerField`; the "Wie viele Einer sind es jetzt?" prompt appears with the field.

4. **`numberline_mark_widget.dart`** (`NumberlineMarkWidget`, B2.2)
   - Number line over `display.range`; tap snaps to the nearest tick (`snappedValueForX` from `numberline_common.dart`, keyed `numberline-mark-line`); reports the snapped value, `""` until the first tap. Target `display.value` is interior (endpoint excluded); edge taps clamp to the endpoint.

All widgets reset on problem change (`didUpdateWidget`): clear field/state and report `""` post-frame, matching the other template widgets.

## Tests

Extended `test/template_widgets_test.dart` with 21 new tests (file total 84):

| Widget | renders | interaction / onValueChanged | reset / "" | boundary |
|---|---|---|---|---|
| FlashSubitizeWidget | dots + field + re-show button | 800 ms fade + typed count; **re-show button re-flashes**; dispose cancels timer; rekenrek display | new problem clears + reports "" + re-flashes | counts 1 and 5 dot counts |
| BundlingWidget | one stick per count | tap-to-bundle `"1 Zehner, 15 Einer"` → `"2 Zehner, 5 Einer"`; grouped bundle opens again → "" | new problem resets → "" | 39 → `3 Zehner, 9 Einer` |
| UnbundlingWidget | bundled picture + hint, no field yet | open → field + prompt; typed total; editable for retry; 2 bundles keep one closed | "" until opened; new problem closed again → "" | 1Z 13E → 23 |
| NumberlineMarkWidget | line renders, "" until tap | tap snaps; re-tap moves marker | new problem clears → "" | edges clamp to endpoints (target interior) |

Flash timer tests use `tester.pump(Duration)` to advance the fake clock (800 ms + 200 ms fade) and assert the `AnimatedOpacity` opacity; the re-show test verifies the second flash also expires after its own duration.

## Verification (all run from `math_app/`)

- `flutter test test/template_widgets_test.dart` — **84 passed** (21 new).
- `flutter analyze` — **0 errors**, 335 issues total (0 issues in the new files / test additions; pre-existing baseline, previously reported ≈ 323 in the P2 plan).
- `flutter test` (full suite) — **419 passed**.
- Retired-skill gate: no `imint`/`pikas` and no English child-facing strings in the new files.

## Concerns

- `bundling`/`numberline_mark` intentionally mirror the already-committed `BundleSticksWidget`/`NumberlineLocateWidget` interactions (identical contract, §5 rule 3 vs the B1.2 custom key, rule 9 vs B2.2); they are standalone classes so the Task 9 template registry can dispatch the four `custom_widget` keys without ambiguity.
- The flash visual uses a simple dot row for `"dots"` (count ≤ 5); a dice/quincunx arrangement would be a cosmetic upgrade, not a behaviour change.
- Lint count 335 vs the 323 P2 baseline is inherited from earlier P2 tasks (not this task: 0 issues attributable to new code); Task 13 gate records the exact number.
