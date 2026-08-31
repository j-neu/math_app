# P2 Practice Runtime — Independent Critic Report

Date: 2026-08-31 · Branch: `gauntlet/p2-p3-p4` (dca479a) · Critic context: fresh

## 1. THE SINGLE BIGGEST REMAINING GAP

**The child path screen can never load a path from the live backend: the `learning-path` edge function does not list `x-student-token` in its CORS `Access-Control-Allow-Headers`, so every browser request to it dies in the CORS preflight and the entire login → path → practice journey is unreachable in a real browser.**

Evidence (all fresh, live backend, this session):
- Browser GET `https://…/functions/v1/learning-path` → `net::ERR_FAILED` (blocked by browser).
- Same request via curl → `HTTP 200 {"path_id":null,"items":[]}`.
- OPTIONS preflight from `Origin: http://localhost:8080` returns `access-control-allow-headers: authorization, x-client-info, apikey, content-type` — **no `x-student-token`**.
- Preflight for `practice-session/start` DOES list `x-student-token` (so practice start/sync/end would pass CORS — the blocker is `learning-path` only).
- Root cause in code: `backend/supabase/functions/learning-path/index.ts:20` (CORS header list) vs `index.ts:131` (`req.headers.get("x-student-token")`). Compare the correct list at `practice-session/index.ts:14-15`.
- Symptom in the running app: with a valid SCH01 token, `/lernpfad` renders `Verbindung zum Server nicht möglich. Bitte Internetverbindung prüfen.` — the friendly no-path state ("Deine Lehrkraft bereitet deinen Lernpfad gerade vor") is never reached, though the backend confirms SCH01 has no path yet (`path_id:null`).

## 2. Findings table

| # | Finding | Severity | Evidence |
|---|---|---|---|
| 1 | `learning-path` CORS omits `x-student-token`; `/lernpfad` fetchPath always fails in-browser; child flow dead | **Critical** | `learning-path/index.ts:20` vs `:131`; live browser `ERR_FAILED` vs curl 200; preflight header list; SCH01 token + `/lernpfad` shows connection error |
| 2 | `place_counters` `take_away`: generator `expected` = removed `count`, evaluator+widget grade the **remaining** `total − count`. Stored `practice_attempts.problem.expected` contradicts the recorded correct answer (C1.1b L1 uses this) | **Important** | `problem_generators.dart:1335` (`expected: [count.toString()]`) vs `template_evaluator.dart:169-178` (target = `remaining`); test codifies the wrong side: `problem_generators_test.dart:1678` (`expect(p.expected, [count.toString()])`) |
| 3 | C1.1b L1 (`take_away`) is unplayable as authored: prompt says "Rechne die Minusaufgabe. Nimm die Plättchen weg…" but no Minusaufgabe/removal count is ever shown; the child must guess how many to remove and is graded on `total − count` | **Important** | `C1.1b.json` L1 params/prompt; `place_counters_widget.dart:87-109` reports only remaining count; generator emits no operand display |
| 4 | Retry-after-wrong never re-records: a child who fixes an answer sees "correct" feedback but the session/mastery keeps the first wrong attempt (`_recordedProblemIndices`); the "Nochmal" affordance promises a second chance that doesn't count toward the 7/8 mastery threshold | **Important** | `practice_controller.dart:176`; `practice_screen.dart:446-453` (Nochmal → `_submit`); test asserts the behavior: `practice_screen_test.dart` "retry records no second attempt". Pedagogically questionable; at minimum should be an explicit plan decision |
| 5 | `equation_gap` `neighbor` validates only the first filled field — child can fill just one side, or fill both with one side wrong, and pass | Minor | `equation_gap_widget.dart:88-91` (`_currentValue` returns first non-empty); generator `expected` = `[n-1, n+1]` (any one matches) |
| 6 | Zero `Semantics(...)` wrappers across all 23 template widgets + 6 manipulatives — every tap interaction (counters, bundling, number line, strategy buttons) is unlabeled for assistive tech; the browser a11y tree showed only raw text | Minor | `grep Semantics\( lib/widgets/templates|manipulatives` → 0 hits |
| 7 | Reduced-motion is honoured only by `flash_subitize`; the correct-answer scale pulse and incorrect-answer shake animate unconditionally (the shake is the more vestibular-provoking one) | Minor | `practice_screen.dart:592-615, 627-649`; `a11y_polish_test.dart` covers only the flash widget |
| 8 | C1.1b L2 prompt promises "graue Punkte werden weggenommen" but the widget renders both ten-frames indigo — no gray dots, no indication which group is taken away | Minor | `C1.1b.json` L2 prompt; `zehnerfeld_read_widget.dart:58-74`; `zehnerfeld.dart` cell color fixed `Colors.indigo` |
| 9 | Flutter 3.35.1 web dev server drops synthetic pointer events through the a11y semantics host: every click on an `flt-semantics` node throws `DartError: Unexpected null value` in the engine `ClickDebouncer` and the tap is lost — automated e2e/a11y click automation against the Flutter web app is currently impossible | Minor (tooling) | Live console (reproducible on every tap attempt, roster + tile + mouse + synthesized PointerEvents); engine revision `1e9a811bf8` matches the served canvaskit |
| 10 | App-start recovery uses a hard-coded `kRecoverySlowBandMs = 7000` instead of the session's level band (only the session id is persisted), so a recovered session's slow flag may use the wrong threshold | Minor | `app_start_recovery.dart:27`; documented tradeoff, but a real correctness caveat |

### Verified sound (no findings)

- Evaluator hand-traces (all five requested cases): `drag_partition` make_ten **rejects** `9+6` for total 15 (`template_evaluator.dart:135`); `strategy_choice` `"8|verdoppeln"` composite accepted; `sequence_gap` joined values match; `bundle_sticks` `"2 Zehner, 3 Einer"` recomposes; `two_groups` difference expected == |a−b|. No generator/evaluator format disagreement beyond finding #2.
- Determinism: `generateProblems` is pure (seeded Random only); tests assert byte-identical output across 50 seeds.
- Generator ZR/boundary coverage is strong: equation_solve never-negative subtraction, addend/subtrahend/minuend bounds, equation_gap helper/missing_addend/any_split/place_value/half/double/neighbor/helper_double, sequence_gap ZR20/ZR100 clamps, drag_partition equal/make_ten/near_double/tens_ones constraints, numberline_step congruence, picture_compare `difference_min`, flash_subitize ≤5, bundling ≥12, nonstandard ≥20.
- `check_specs.py` is genuinely strict (unknown template/params key/enum/range-shape, provenance CSV row, gap-index bounds, strategy id membership) and passes 36/36.
- Offline path is real: `AttemptQueue` add-then-flush, `/sync` idempotent dedupe, `endPractice` refuses to `/end` on incomplete flush and marks pending, `recoverPendingSessions` wired at app start (`main.dart:92`), all unit-tested.
- Child flow wiring: `/lernpfad` route exists; login welcome "Los geht's" → `context.go('/lernpfad')`; logout clears prefs → `/`. Roster + login endpoints verified live (roster 200 with SCH01, login 200 with valid JWT).

## 3. What I could and could not inspect

**Could inspect:** branch + all 18 P2 commits; every model/service/controller/screen/widget file listed in scope; plan §5 + spec §5; all 23 template widget files; 4 of the 6 tests' full listings (generator 106 KB, evaluator, controller, screen, a11y, widget 75 KB); `check_specs.py`; backend edge functions. Ran fresh `flutter test` (441 pass), `flutter analyze`, `python scripts/check_specs.py`.

**Browser inspection: YES — used Playwright against http://localhost:8080 (live Supabase backend).** Walked: `/lernen/pilotschule` loaded (no boot console errors) → code `22WW` → roster fetched and rendered ("Wer bist du?", SCH01 tile, require_pin false) → login endpoint verified directly (200 + JWT). Drove `/lernpfad` with a real token → reproduced the CORS connection-error state. Could NOT: tap SCH01 to complete login, because the Flutter 3.35.1 web engine drops every synthetic pointer event through the a11y semantics host (finding #9) — roster→welcome and the practice session UI were therefore verified at the network/endpoint layer, not by clicking. Also could not view screenshots (model has no image input), so visual overflow/contrast at the three mandated sizes was not independently verified (mitigated by the widget tests + a11y test).

## 4. Fresh gate output

```
$ cd math_app && flutter test        → 441 passed, 0 failed (All tests passed!)
$ cd math_app && flutter analyze     → 335 issues, 0 errors (baseline 323 → +12, all info-level,
                                        incl. 13 new use_key_in_widget_constructors in the extracted
                                        manipulative widgets)
$ python scripts/check_specs.py      → OK: 36 specs validated
```

Additional live checks: roster POST 200 (SCH01, `require_pin:false`); `student-auth/login` POST 200 (valid JWT); `learning-path` GET via curl 200 `{"path_id":null,"items":[]}` but via browser `net::ERR_FAILED` (CORS); `practice-session/start` preflight allows `x-student-token`; `learning-path` preflight does not.
