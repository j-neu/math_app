# P2 Task 1 — Manipulative widget extraction report

**Date:** 2026-08-31
**Branch:** `gauntlet/p2-p3-p4`
**Task:** Extract private manipulative widget classes from `lib/screens/diagnostic_screen.dart` into shared public widgets under `lib/widgets/manipulatives/`.

## Files created

| File | Public classes |
| --- | --- |
| `math_app/lib/widgets/manipulatives/zehnerfeld.dart` | `ZehnerfeldWidget`, `VergleichZehnerfelderWidget` |
| `math_app/lib/widgets/manipulatives/rekenrek.dart` | `RekenrekWidget`, `RekenrekFlashWidget`, `VergleichRekenrekWidget` |
| `math_app/lib/widgets/manipulatives/fingerbild.dart` | `FingerBildWidget` |
| `math_app/lib/widgets/manipulatives/staebchen.dart` | `StaebchenBundelWidget`, `StaebchenEinzelWidget`, `StaebchenWidget`, `StaebchenOeffnenWidget` |
| `math_app/lib/widgets/manipulatives/stellenwerttafel.dart` | `StellenwerttafelWidget` |
| `math_app/lib/widgets/manipulatives/zahlenstrahl.dart` | `ZahlenstrahlPainter`, `ZahlenstrahlArrowWidget`, `ZahlenstrahlMarkWidget` |
| `math_app/test/manipulatives_widget_test.dart` | 17 focused widget smoke tests |
| `.superpowers/gauntlet/p2a-report.md` | this report |

## Files changed

- `math_app/lib/screens/diagnostic_screen.dart` — removed the 14 moved private classes (lines ~1031–1686 of the original), added imports for the six new files, renamed all references inside the public `buildVisualDisplay` switch to the public names, removed the now-unused `finger_display_widget.dart` import.

## Verification

### Regression gate — `flutter test test/visual_display_test.dart`

```
00:00 +0: loading C:/Users/jakob/StudioProjects/Math_App/math_app/test/visual_display_test.dart
00:01 +17: DDB-05 tap places the marker and writes the snapped value
00:01 +18: All tests passed!
```

All 18 tests pass unchanged (incl. the 800 ms Rekenrek flash timer flush and the DDB-05 tap-to-marker test).

### New widget tests — `flutter test test/manipulatives_widget_test.dart`

```
00:00 +0: loading C:/Users/jakob/StudioProjects/Math_App/math_app/test/manipulatives_widget_test.dart
00:01 +17: All tests passed!
```

### Full suite — `flutter test`

```
00:04 +109: All tests passed!
```

92 baseline + 17 new = 109 tests, all passing. Test count grew, never shrank.

### Analyzer — `flutter analyze`

```
335 issues found. (ran in 43.6s)
```

- **0 errors** (required gate met).
- 53 warnings, 282 infos.
- Baseline was ≈323 issues; the +12 net (335) comes from **13 new `use_key_in_widget_constructors` infos** on the now-public widget constructors (the lint never fired while the classes were private), minus 1 previously-existing warning that disappeared (the `finger_display_widget.dart` import removal had no lint effect; net offset from other churn). Constructors were deliberately left unchanged per the "move VERBATIM" rule.

## Content-equivalence check

A scripted class-by-class comparison of the moved code (original block from `git HEAD`, underscore-prefix stripped) against the new files confirmed **all 18 classes are byte-for-byte identical** to the originals (fields, constructors, params, logic, doc comments). The only deltas are:

1. State classes (`_RekenrekFlashWidgetState`, `_StaebchenOeffnenWidgetState`, `_ZahlenstrahlMarkWidgetState`) keep their original **private** names in the new files; only the widget classes are public. `createState()` generics reference the public widget names.
2. Each new file carries the required imports (`package:flutter/material.dart` everywhere; `dart:async` in `rekenrek.dart` for the flash `Timer`; `finger_display_widget.dart` in `fingerbild.dart`).

## Deviations

1. **Removed the `finger_display_widget.dart` import from `diagnostic_screen.dart`** — its sole consumer (`_FingerBildWidget`) moved to `fingerbild.dart`; keeping it would add an `unused_import` warning. `dart:async` was kept in `diagnostic_screen.dart` because the screen's own question-timeout `Timer`s still use it.
2. **`use_key_in_widget_constructors` lints** appear on the 13 public constructors. Adding `Key` parameters would violate the "move VERBATIM (same fields, constructors, params)" rule, so constructors are unchanged. These are info-level; 0 errors.
3. Each new file has a standard single blank line after its import(s); no behavior impact.
