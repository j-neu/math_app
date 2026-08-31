# P2 — Practice Runtime Implementation Plan

**Date:** 2026-08-31
**Owner:** Gauntlet controller
**Spec:** `docs/superpowers/specs/2026-08-30-numeris-learning-path-design.md` §5
**Branch/worktree:** none yet — work happens on a branch off `main` (`562d49f`)

---

## 1. Goal

Build the child-facing practice runtime for the Numeris learning path: a spec-driven problem engine that (a) loads the P3 skill specs, (b) generates ~8 problems per level procedurally from the spec's template + params + a server-provided seed, (c) presents them with excellent child-facing interaction in three representations (E-I-S), (d) gives immediate, encouraging feedback with a hint drawn from the error taxonomy, (e) captures response time, (f) records attempts through the existing `LearningPathService`/`AttemptQueue` (offline-safe), and (g) reports mastery via `endPractice`. Plus a new child learning-path screen (`ChildPathScreen`) wired to the `/lernpfad` route that renders the server path and launches practice.

## 2. Current state (verified 2026-08-31)

- `LearningPathService` (`lib/services/learning_path_service.dart`) is fully built and unit-tested but has **no UI consumer**. `startPractice` → `(practiceSessionId, seed)`; `recordAttempt(token, sessionId, attempt)` (queue + flush, silent-fail); `endPractice(token, sessionId, {slowBandMs})` → `(mastered, slowFlag, unlocked)`; `pendingEndSessions()` / `recoverPendingSessions(token, {slowBandMs})` (doc: "P2 MUST call this at app start").
- `StudentAuthService` persists `student_token` and `student_name` in SharedPreferences. `storedToken()` / `storedName()` / `logout()` exist.
- All six manipulative visuals (Zehnerfeld, Rekenrek, Fingerbild, Stäbchen, Stellenwerttafel, Zahlenstrahl) are **private classes inside `lib/screens/diagnostic_screen.dart`** (see lines 1036–1650), plus `FingerDisplayWidget` is already shared (`lib/widgets/common/finger_display_widget.dart`). `TwentyFrameWidget`, `InteractiveTwentyFrameWidget`, `NumberLineWidget` exist but are unused placeholders.
- `flutter test` = 92 passing. `flutter analyze` baseline ≈ 323 lints, 0 errors (reported by P1; re-run in Task 13).
- No spec interpreter, no `SkillSpec` class, no `/lernpfad` route exist.

## 3. Global constraints

- **Spec §5 is the contract.** The spec JSON format below is the exact, machine-precise realisation of §5; P3 specs must conform to it and the runtime must tolerate only it.
- **Never revive retired skills.** The legacy practice engine (`lib/exercises/*`, `ExerciseService`) and its screen must not be wired into the child path flow. The new `ChildPathScreen` is driven purely by `LearningPath` + skill specs. The legacy `LearningPathScreen` remains reachable from the desktop/legacy diagnostic-complete flow for now — do NOT modify that flow in P2 (flagged for the integration phase).
- **Offline first.** Attempts go through `AttemptQueue`; a session must survive a mid-session network drop and arrive exactly once (`practice_attempts.problem_index` dedupe is server-side).
- **Determinism.** Given (spec, level, seed) the generated problem list must be byte-identical across runs and devices. Only `dart:math Random(seed)` seeded by the server seed. No `DateTime.now()` inside generators.
- **German only.** All child-facing strings German, non-blaming, age-appropriate. No technical errors visible.
- **Accessibility + ADHD guidelines** (repo `adhd guidelines.md`): immediate feedback, large targets (≥ 44 px), no color-only signalling, no long waits, mistakes are normal, sessions are short.
- **Every child-facing correctness rule is a unit test.** Math edge cases are the acceptance gate; a generator whose tests don't cover the ZR boundary, the tens-overstep, and the duplicate-answer cases is not done.
- **Try to keep the existing 92 tests green** except where a task explicitly renames/refactors (visual-widget extraction must keep `visual_display_test.dart` green).
- **Analyzer:** new code must add 0 errors; lints ≤ baseline unless the task says otherwise.

## 4. Spec JSON format (the P2/P3 contract)

One file per skill: `docs/clean-room/skills/specs/<skill_id>.json` (source of truth) mirrored to `math_app/assets/skill_specs/<skill_id>.json` by `scripts/sync_skill_specs.py` (Task 2). Schema (JSON, all fields present unless `nullable`):

```jsonc
{
  "spec_version": 1,
  "skill_id": "A1.1a",                 // matches skills_taxonomy.csv IDs
  "construct_id": "A1.1",
  "domain": "A",                        // A | B | C | D
  "title_de": "Vorwärtszählen bis 20 und darüber hinaus",
  "level_titles_de": ["Zählen auf dem Zahlenstrahl", "Zahlenfolge fortsetzen", "Lückentext"],
  "levels": [
    {
      "level": 1,                       // 1..3
      "representation": "enaktiv",      // enaktiv | ikonisch | symbolisch
      "template": "numberline_step",    // one of TEMPLATES below, or "custom_widget"
      "custom_widget": null,            // non-null key into the custom-widget registry when template=="custom_widget"
      "params": { /* template-specific, see §5 */ },
      "problem_count": 8,
      "prompt_de": "Tippe die nächste Zahl auf dem Zahlenstrahl an.",
      "slow_band_ms": 8000
    }
  ],
  "mastery": { "correct_of": 8 },
  "error_taxonomy": [
    { "code": "miscount", "label_de": "verzählt", "hint_de": "Zähle noch einmal langsam." }
  ],
  "provenance": {
    "sources": ["Padberg & Benz 2021 (5. Aufl.), Kap. 3; KMK 2022"],
    "author": "<name>", "reviewed_by": "<name>"
  }
}
```

Template list (`TEMPLATES`, fixed by §5): `drag_partition, place_counters, bundle_sticks, rekenrek_set, numberline_step` (enaktiv); `zehnerfeld_read, fingerbild_read, stellenwerttafel_read, numberline_locate, picture_compare` (ikonisch); `equation_solve, equation_gap, sequence_gap, compare_symbols, strategy_choice` (symbolisch); `word_problem`.

## 5. Template semantics (params → generation/evaluation)

General generation contract: `List<Problem> generate(spec, level, seed)` returns exactly `problem_count` problems. Every `Problem` JSON (`practice_attempts.problem` payload) has the shape below; `expected` holds every accepted canonical answer (or is empty when the widget evaluates semantically — those templates still embed `expected` for the DB record where sensible):

```jsonc
{
  "template": "equation_solve", "skill_id": "A1.1a", "level": 1, "seed": 12345, "index": 3,
  "prompt_de": "Wie viel ist 4 + 3?",
  "display": { "a": 4, "b": 3, "op": "+" },
  "expected": ["7"]
}
```

Per-template rules (params keys; generation rule; correctness rule; DB answer string):

1. **drag_partition** — params `{total_range:[6,10], parts:2}`. Split `total` into `parts` positive integers (no zero part). Widget: stash of counters, drop into labelled boxes. Correct iff sum of box counts == total. DB answer `"3+4"` (box counts joined by `+`).
2. **place_counters** — params `{count_range:[1,10], frame:"zehnerfeld"|"rekenrek"}`. Widget: tap cells to fill. Correct iff filled == chosen count. DB answer = filled count.
3. **bundle_sticks** — params `{count_range:[12,39]}`. Widget: sticks, tap to bundle into 10s; leftovers counted. Correct iff `10*bundles + singles == count` AND `(count >= 10 → bundles >= 1)`. DB answer `"2 Zehner, 3 Einer"`.
4. **rekenrek_set** — params `{count_range:[1,20], rows:2}`. Widget: tap beads to slide. Correct iff visible == count. DB answer = visible count.
5. **numberline_step** — params `{range:[0,20], start_range:[10,12], target:20, step:1}`. Child taps successive numbers `start+1 … target`. Correct iff the tapped run is exactly that sequence. DB answer = the tapped numbers joined `","`.
6. **zehnerfeld_read** — params `{count_range:[1,10], arrangement:"structured"}`. Show filled ten-frame; type the count. Correct iff typed == count.
7. **fingerbild_read** — params `{count_range:[1,10], hands:2}`. Show `FingerDisplayWidget`; type the count.
8. **stellenwerttafel_read** — params `{number_range:[11,99], columns:["Z","E"]}`. Show Stellenwerttafel with counters; type the number. DB answer = the number.
9. **numberline_locate** — params `{range:[0,100], value_range:[1,99]}`. Tap where `value` sits; tap snaps to nearest tick. Correct iff snapped position == value. DB answer = snapped value.
10. **picture_compare** — params `{left_range:[1,10], right_range:[1,10], question:"mehr"|"weniger"|"difference"}`. Two ten-frames. For `mehr`/`weniger`: tap the bigger/smaller side (correct iff tapped side matches). For `difference`: type `|left-right|`. DB answer: tapped side id or difference.
11. **equation_solve** — params `{op:"+"|"-", unknown:"result"|"addend"|"subtrahend"|"minuend", zr:20, a_range, b_range}`. Compute answer; `display` carries the two known numbers; `expected` = computed answer. For `unknown: addend` the prompt shows `_ + b = c`. DB answer = number.
12. **equation_gap** — params `{op:"+", use_helper:true, zr:20}`. Generates a Stützpunkt-form like `9 + 4 = 10 + _` (helper splits the addend over the tens boundary) or `18 - 9 = _ - 10`; `display.gap_after` selects the gap position; `expected` = the number filling the gap; correctness also requires the whole equation to hold. DB answer = gap number.
13. **sequence_gap** — params `{direction:"up"|"down", step:1|2|5|10, start_range, length:5, gap_indices:[0|1|…]}`. Generate arithmetic sequence; blanks at `gap_indices`; type each missing value. Correct iff all filled values match the sequence. DB answer = values joined `","`.
14. **compare_symbols** — params `{a_range, b_range, zr:100}`. Two numbers; tap `<`,`>`,`=`. Correct iff chosen operator matches. DB answer = operator.
15. **strategy_choice** — params `{op:"+"|"-", zr:20, strategies:[{id,label_de}...], correct_strategy}`. First solve the equation (equation input); then choose the strategy used. Correct iff BOTH the value and the chosen strategy are right. DB answer `"8|verdoppeln"`.
16. **word_problem** — params `{contexts:[{setting_de, object_de}...], op:"+"|"-", zr:20}`. Pick context + numbers; build a German sentence; type the result. `display.prompt_de` carries the finished sentence. Correct iff typed == computed result. Context pool must be age-appropriate and mathematically unambiguous (never negative, never "borrow" language). DB answer = number.

**custom_widget registry** (keys, implemented in Task 8): `"bundling"` (B1.2 Bündeln), `"unbundling"` (B1.3 Entbündeln: interactive Stäbchen-bundle opening, `_StaebchenOeffnenWidget` pattern), `"numberline_mark"` (B2.2), `"flash_subitize"` (A2.1: 800 ms Rekenrek/dots flash then type the count — the `_RekenrekFlashWidget` pattern). Unknown keys must fail spec validation.

## 6. Dart architecture (lib/)

```
lib/models/skill_spec.dart        SkillSpec/LevelSpec/ErrorRule/provenance + JSON
lib/models/problem.dart           Problem (+ json), AnswerRecord (value, wasCorrect, responseMs, errorCode)
lib/services/skill_spec_store.dart  loads bundled assets/skill_specs/*.json, validates, lookup by id
lib/services/answer_normalization.dart  trim, German decimal comma, collapsed whitespace, multi-value
lib/practice/problem_generators.dart    pure fns per template: generate(spec, level, seed, index…) → Problem
lib/practice/template_registry.dart     template name → generator + widget factory + answer evaluator
lib/practice/practice_controller.dart   session orchestration (ChangeNotifier or Riverpod Notifier)
lib/screens/practice_screen.dart        session UI: progress, prompt, input, submit, feedback, summary
lib/screens/child_path_screen.dart      the new learning-path screen
lib/widgets/manipulatives/*.dart        extracted shared visuals + new interactive widgets
```

`PracticeController` responsibilities (unit-testable with a fake `LearningPathService` via `http.testing.MockClient`):
- `start(spec, level)`: call `startPractice` → sessionId+seed; generate problems; begin timer.
- per problem: answer submitted → evaluate via template registry → build `AnswerRecord` with `responseMs` (elapsed since problem shown) + `errorCode` (from taxonomy when wrong) → `recordAttempt` (queued) → feedback.
- `finish()`: `endPractice(token, sessionId, slowBandMs: spec.levels[level-1].slow_band_ms)` → result; expose mastered/unlocked.
- error path: network failure on start/end → typed exception, child-friendly German message, session recoverable via `recoverPendingSessions`.

`ChildPathScreen`: loads `LearningPath` via `fetchPath(storedToken())`. States: loading, error (retry), no-path (friendly "Deine Lehrkraft bereitet deinen Lernpfad vor"), path rendered. Item tile shows skill title, level pips (1–3), state lock/hint; `available` items tappable → `PracticeScreen(skillId, level: item.nextLevel)`. On return: refetch path. Header shows name + logout (clears prefs → `/lernen/:slug`).

## 7. Route wiring

`main.dart` adds:
```dart
GoRoute(
  path: '/lernpfad',
  builder: (context, state) => const ChildPathScreen(),
),
```
`ChildLoginScreen` replaces its post-login welcome placeholder with `context.go('/lernpfad')` after `login` succeeds (token + name already persisted by `StudentAuthService`). `main.dart`'s `initState`/app start calls `LearningPathService.recoverPendingSessions` guarded by `storedToken() != null` (Task 11).

## 8. Tasks (TDD; each: failing test → implement → green → self-review → task reviewer)

**Task 1 — Extract manipulative widgets (behaviour-preserving).**
Move `_ZehnerfeldWidget`, `_VergleichZehnerfelderWidget`, `_RekenrekWidget`, `_RekenrekFlashWidget`, `_VergleichRekenrekWidget`, `_FingerBildWidget` (wrap `FingerDisplayWidget`), `_StaebchenWidget` + `_StaebchenBundelWidget`/`_StaebchenEinzelWidget`/`_StaebchenOeffnenWidget`, `_StellenwerttafelWidget`, `_ZahlenstrahlPainter`/`_ZahlenstrahlArrowWidget`/`_ZahlenstrahlMarkWidget` from `diagnostic_screen.dart` into `lib/widgets/manipulatives/{zehnerfeld,rekenrek,fingerbild,staebchen,stellenwerttafel,zahlenstrahl}.dart` with public names (`ZehnerfeldWidget`, …). `diagnostic_screen.dart` imports them; **`visual_display_test.dart` must stay green** — this is the regression gate. Add focused widget tests for each extracted widget (renders without throwing for boundary inputs: 0, full frame, 10×2 beads).

**Task 2 — Spec model, store, validation.**
`SkillSpec.fromJson` with strict validation (schema above): unknown template / unknown custom_widget key / level count ≠ 3 / problem_count not in [4,12] / mastery.correct_of not in [1..problem_count] / slow_band_ms missing → `SpecFormatException`. `SkillSpecStore` loads bundled assets, exposes `byId`, `allIds`, and a `validateAll()` used by tests. Add `scripts/sync_skill_specs.py` (copies `docs/clean-room/skills/specs/*.json` → `math_app/assets/skill_specs/`) and a `scripts/check_specs.py` JSON-schema validator that exits non-zero on violations (mirrors `check_provenance.py` style). Fixture specs for the 16 templates live in `test/fixtures/specs/`. Tests: valid fixture loads; each of 12 injected schema violations throws; store finds all bundled specs.

**Task 3 — Problem model, seeded generator harness, answer normalization.**
`Problem.fromJson/toJson`; `SeededGenerator` wrapper around `Random(seed)`; `answer_normalization.dart` (`normalizeAnswer` trims, collapses spaces, replaces `,`→`.`? NO — keep German decimal as-is; canonical compare set: `{"7", "7,0"}` style handled in template eval). Tests: determinism (same seed → identical problem list, across 50 seeds), uniqueness within a level, normalization table.

**Task 4 — Symbolic template generators (pure).**
Implement generators for `equation_solve, equation_gap, sequence_gap, compare_symbols, strategy_choice, word_problem`. **Math-correctness tests are the gate**: e.g. equation_solve for unknown=subtrahend never yields negative; equation_gap always `a+b` == gap expression both sides; sequence_gap respects step/direction and ZR bound; compare_symbols `expected` matches the true operator; word_problem result never negative and story numbers age-plausible; every generated `expected` set non-empty. Include ZR20/ZR100 boundary and tens-overstep cases.

**Task 5 — Manipulative template generators + custom widgets.**
Generators for `drag_partition, place_counters, bundle_sticks, rekenrek_set, numberline_step, zehnerfeld_read, fingerbild_read, stellenwerttafel_read, numberline_locate, picture_compare` and the custom registry keys. Math gates: bundle_sticks never generates count<10 with bundles required; numberline_locate value within range and ≠ endpoints; picture_compare difference ≥ 1; flash_subitize count within subitizable range (≤5, later spec-defined).

**Task 6 — PracticeController + answer evaluation.**
Controller orchestrates start → problems → per-problem submit (evaluate via `TemplateEvaluator`: correct? + errorCode) → feedback state → finish → `endPractice`; uses `LearningPathService` (injected, MockClient-backed). Tests: full session with mixed answers sends attempts in order with correct `was_correct`/`response_ms`/`error_code`; network drop mid-session → queue retains, no loss; `finish` maps `mastered`/`slowFlag`/`unlocked`; slow response (> slow_band_ms on a problem) reflected in the record; controller exposes per-problem `feedback` state machine (unanswered → correct | incorrect+hint).

**Task 7 — Symbolic template widgets.**
Widgets for `equation_solve, equation_gap, sequence_gap, compare_symbols, strategy_choice, word_problem` + a shared `NumberPad`/`AnswerField` (large keys, ≥44 px, audio cue optional). Widget tests: type answer → `onSubmitted(value)`; wrong submit clears for retry; strategy_choice requires both parts.

**Task 8 — Manipulative template widgets + custom widgets.**
Widgets for the 10 manipulative templates + custom registry (flash 800 ms + fade per `_RekenrekFlashWidget`, bundling/unbundling interactivity). Widget tests incl. tap-to-fill/remove, tap-to-bundle, number-line tap snapping, Rekenrek slide; all with 44 px+ targets.

**Task 9 — PracticeScreen + session flow UI.**
Layout: top progress (8 dots or fill bar), prompt (large), representation label ("Lege", "Sieh hin", "Rechne"), input area (from template widget), submit + feedback (correct: green pulse + "Super!"; incorrect: gentle shake + taxonomy hint + "Nochmal"), 1.2 s between feedback and next, final summary screen (stars + "Geschafft! / Bald schaffst du es!") with mastered/unlocked messaging. Widget tests: full 8-problem session renders steps, feedback states, summary; encouragement copy asserted.

**Task 10 — ChildPathScreen + routing + login hand-off.**
Screen states above; `/lernpfad` route; `ChildLoginScreen` hand-off after login; logout; refetch on return from practice. Tests: loading/error/no-path/path states (MockClient `fetchPath`); locked vs available tappability; tap available → `PracticeScreen` pushed; mastery refresh.

**Task 11 — App-start recovery.**
`main()` or app shell: if `storedToken() != null`, call `recoverPendingSessions` (best-effort, non-blocking, silent on failure). Test: controller-level test that a pending session is flushed once on startup path.

**Task 12 — Accessibility + ADHD polish pass.**
Review all new screens: min target sizes, contrast, no color-only states (lock + icon + text), feedback not punitive, session length guard, reduced-motion respect for flashes where cheap. Deliverable: written checklist in plan appendix + fixes. Run the visual-reviewer critic.

**Task 13 — Gates.**
`cd math_app && flutter test && flutter analyze && flutter build web --no-tree-shake-icons`. Expected: all tests pass; analyzer 0 errors, lints ≤ baseline+20 (record exact); web build succeeds.

**Task 14 — Independent critic review + fix loops.**
Fresh-context critic inspects the real artifact (running app where possible, code + tests otherwise), reports the single biggest remaining gap; fix; re-review until clean.

## 9. Verification gates (per task)

- Tests green for the task's scope; Task 13 full suite.
- No child-facing English strings, no raw errors, no retired-skill references in new code (grep `imint|pikas` on new files).
- Determinism and math-edge tests present where the task mandates them.

## 10. Known gaps / deferred (explicitly out of P2)

- Legacy diagnostic-complete → legacy `LearningPathScreen` hand-off (integration-phase decision).
- Real device/speech audio polish; rewards (milestones/stars) reuse `RewardService` only if non-disruptive.
- P3 spec authoring is a parallel workstream; Task 2 defines the format it must satisfy.
