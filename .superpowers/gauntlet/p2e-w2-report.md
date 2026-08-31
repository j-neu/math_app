# P2 Task 8 (part 1) — Interactive manipulative template widgets

**Date:** 2026-08-31
**Branch:** `gauntlet/p2-p3-p4`
**Scope:** 10 interactive template widgets in `math_app/lib/widgets/templates/` + shared scaled number-line painter, with widget tests in `test/template_widgets_test.dart`.

## Contract (shared by all 10)

`({key, required Problem problem, required ValueChanged<String> onValueChanged})` — every widget reports the current answer string on every interaction, `""` when empty, and resets + reports `""` when the `Problem` instance changes (`didUpdateWidget` + `addPostFrameCallback`). All interactive targets are ≥ 44 px.

## New files

- `lib/widgets/templates/numberline_common.dart` — shared `ScaledNumberLinePainter` (arbitrary `[lo, hi]` interval), `snappedValueForX`, `numberLineTicks`, `numberLineLabels` (the existing `ZahlenstrahlPainter` is hard-coded to 0–100).
- `lib/widgets/templates/{drag_partition,place_counters,bundle_sticks,rekenrek_set,numberline_step,numberline_locate,zehnerfeld_read,fingerbild_read,stellenwerttafel_read,picture_compare}_widget.dart`.

---

## 1. DragPartitionWidget (`drag_partition_widget.dart`)

- **Display fields consumed:** `total`, `parts`, `box_labels`. (`split_constraint`, `boxes`, `a`, `b` intentionally ignored — the evaluator judges any placement.)
- **Interaction model:** stash of `total` dots + one labelled box per part. Tap a box's `+` zone (key `box-add-$i`) to add one counter; tap the box's counter display (key `box-counters-$i`) to remove one. Placement capped at `total`.
- **Value format:** `"b1+b2+…"` (counts in box order, joined `+`); `""` when nothing placed.
- **Tests:** renders stash/boxes; box taps add + join; counter tap removes + empty → `""`; stash cap (5+0); new problem resets.

## 2. PlaceCountersWidget (`place_counters_widget.dart`)

- **Display fields consumed:** `action`, `mode`, `frame`, `total` (take_away), `count`. (Nonstandard carries `tens`/`ones` but the widget builds the number from scratch.)
- **Interaction model:** standard — 5×2 (zehnerfeld) or 10×2 (rekenrek) grid of tappable cells (key `pc-cell-$i`), tap to fill/unfill. `take_away` starts with `total` filled. Nonstandard (B2.3) — interactive Stellenwerttafel with Z/E columns (keys `swt-z-add`/`swt-e-add`, `swt-z-counters`/`swt-e-counters`); Einer column may hold > 9.
- **Value format:** fill → filled count; take_away → remaining count (`""` before the first removal, `"0"` when all removed); nonstandard → `"Z E"` (e.g. `"1 13"`, evaluator checks `10Z+E == count`).
- **Tests:** fill count reporting; unfill + empty → `""`; take_away 6→5→0; nonstandard Z/E reporting; new problem resets (rekenrek 20 cells).

## 3. BundleSticksWidget (`bundle_sticks_widget.dart`)

- **Display fields consumed:** `count`.
- **Interaction model:** `count` loose sticks; tapping a loose stick (key `stick-$i`) bundles the next ten into a Zehner; tapping a bundle (key `bundle-$i`) unbundles. Singles always `count − 10·Z`.
- **Value format:** `"Z Zehner, E Einer"` on every change; `""` while nothing is bundled (also when the last bundle is opened).
- **Tests:** renders one stick per count; bundle 25 → 1Z/15E → 2Z/5E; unbundle → `""`; boundary 39 → 3 Zehner, 9 Einer (4th bundle impossible); new problem resets.

## 4. RekenrekSetWidget (`rekenrek_set_widget.dart`)

- **Display fields consumed:** `rows` (1 = single rod).
- **Interaction model:** beads slide — tap an empty slot at index `i` fills beads `0..i`; tap a filled slot at index `i` slides beads back to `0..i−1`. Keys `bead-top-$i` / `bead-bottom-$i`, 44 px cells.
- **Value format:** total beads pushed left (`top + bottom`); `""` while none moved.
- **Tests:** top/bottom fill reporting; slide-back (3→2→1→`""`); boundary 20/20; `rows: 1` single rod; new problem resets.

## 5. NumberlineStepWidget (`numberline_step_widget.dart`)

- **Display fields consumed:** `range`, `start`, `target`, `step`, `direction`.
- **Interaction model:** full-width tappable line strip (key `numberline-step-line`, 72 px tall); tap snaps to nearest integer; only the *next* required tick (`start±step … target`) registers, wrong/out-of-order taps ignored. Tapped ticks light up (highlighted circles); order is enforced, so the run always lands on the target.
- **Value format:** tapped run joined `","` (partial while counting, full once complete); `""` if none tapped.
- **Tests:** ordered run 11,12,13; wrong-tap rejection (ahead/target-first/repeat/skip); direction down 14,13,12; step 2 (8,10,12); new problem resets.

## 6. ZehnerfeldReadWidget (`zehnerfeld_read_widget.dart`)

- **Display fields consumed:** `count`, `arrangement`, `split` (two_groups).
- **Interaction model:** static filled ten-frame(s) (one frame, or two side-by-side groups from `split`) + `BigAnswerField`; prompt tells the child what to count (`ask`: total/difference/part).
- **Value format:** typed value; `""` while empty.
- **Tests:** structured renders + typing; two_groups 2 frames + retry edit; new problem clears.

## 7. FingerbildReadWidget (`fingerbild_read_widget.dart`)

- **Display fields consumed:** `count`, `hands`.
- **Interaction model:** `FingerBildWidget` (hands 1 → one hand; hands 2 → 5/rest split) + `BigAnswerField`.
- **Value format:** typed count; `""` while empty.
- **Tests:** renders + typing 7; hands:1 split (left 4, right 0); new problem clears.

## 8. StellenwerttafelReadWidget (`stellenwerttafel_read_widget.dart`)

- **Display fields consumed:** `mode`, `tens`/`ones` (read), `row1`/`row2`/`op` (sum_rows).
- **Interaction model:** mode read → `StellenwerttafelWidget`; mode sum_rows → custom two-row Z/E counter table with the op sign and result rule; both + `BigAnswerField`.
- **Value format:** typed composed number; `""` while empty.
- **Tests:** read renders cells 4/7 + typing; sum_rows `+`; sum_rows `-` with retry; new problem clears.

## 9. NumberlineLocateWidget (`numberline_locate_widget.dart`)

- **Display fields consumed:** `range` (value is the target, never an endpoint).
- **Interaction model:** full-width tappable line strip (key `numberline-locate-line`, 72 px tall); tap snaps to the nearest integer tick and places the marker.
- **Value format:** snapped value; `""` until the first tap.
- **Tests:** snap to 64 then re-snap to 25; boundary edge taps clamp to `rangeLo`/`rangeHi`; new problem clears marker + reports `""`.

## 10. PictureCompareWidget (`picture_compare_widget.dart`)

- **Display fields consumed:** `left`, `right`, `question`.
- **Interaction model:** more/less → tap a group (keys `compare-left`/`compare-right`), re-tapping re-picks; selection signalled by check mark + border (never colour alone). difference → static groups + `BigAnswerField`.
- **Value format:** `"left"`/`"right"` (side id) or the typed difference; `""` before choice/typing.
- **Tests:** more → left then re-pick right; less → left with `links ✓` indicator; difference |1−10|=9 with retry; new problem resets selection.

---

## Verification

- `cd math_app && flutter test test/template_widgets_test.dart` → **63 passed** (21 prior + 42 new).
- `flutter analyze` → **0 errors**; 335 pre-existing warnings/infos, **0 issues in the new files** (identical count to the w1 gate).
- `flutter test` → **398 passed** (356 prior + 42 new).

## Concerns

- `rekenrek_set` and `place_counters` share a fill/unfill-by-slot model where tapping the first filled slot collapses the run back to 0 — intended (matches "slide beads back"), and documented in the tests.
- `numberline_step` enforces the tap order strictly (out-of-order taps are ignored without feedback); the PracticeScreen should surface the partial run text the widget renders (`11 → 12 → 13`) so the child gets visual confirmation of progress.
