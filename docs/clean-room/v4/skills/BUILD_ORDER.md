# v4 skill-spec build order

91 of 93 skills remain (double_zr10 and halve_zr10 shipped —
`docs/superpowers/plans/2026-09-15-exercise-plan-foundation.md`). Run
`python scripts/check_skill_spec_coverage.py` for live status; this file is
the *order* to close the gap in, not the live status itself.

Each batch below is sized for one follow-on plan (`writing-plans`, using
`docs/skill_spec_authoring_guide.md`'s checklist). Batches are grouped by
`construct_id` within each archetype tier so sibling skills sharing a
manipulative are authored together.

Tier totals are the design doc §3 tally (30 Reused / 31 Extended / 11
New — widget exists / 21 New — from scratch) minus the two shipped skills:
29 / 31 / 11 / 20 remaining. Every archetype tag and manipulative below is
taken from `docs/superpowers/specs/2026-09-15-exercise-plan-design.md` §5.

## Tier 1: Reused (29 remaining of 30)

Cheapest tier — a close 1:1 old exercise exists, so most instances are an
id/field retarget like Task 4's double_zr10.

### Batch 1.1 — counting quantities (construct `quantify_count`)
- [x] `quantify_count_zr10` — shipped, `docs/superpowers/plans/2026-09-17-quantify-count-zr10.md`; Reused from C1.1 `Count the Dots` (`count_dots_exercise_v2.dart`); loose dot/plättchen field, tap-to-count (structured row → scattered → mixed sizes)

### Batch 1.2 — counting forward (construct `count_forward`)
- [x] `count_forward_zr20` — shipped, `docs/superpowers/plans/2026-09-17-count-forward-zr20-zr100.md`; Reused from C3.1 `Count Forward to 20` (`count_forward_exercise.dart`); number strip / spoken-and-typed sequence
- [x] `count_forward_zr100` — shipped, `docs/superpowers/plans/2026-09-17-count-forward-zr20-zr100.md`; Reused from C3.2/C3.3 `Count Forward to 50/100` (same file family); extended range, decade-boundary starts emphasised

### Batch 1.3 — successor & predecessor (constructs `successor`, `predecessor`)
- [x] `successor_zr20_decade` — shipped, `docs/superpowers/plans/2026-09-17-successor-predecessor-zr20-decade.md`; Reused from C4.1 `What Comes Next?` (`what_comes_next_exercise.dart`); single number card, successor direction
- [x] `predecessor_zr20_decade` — shipped, `docs/superpowers/plans/2026-09-17-successor-predecessor-zr20-decade.md`; Reused from the same C4.1 number-card widget, predecessor direction
- Note: these two constructs share one manipulative and archetype per design doc §5; their ZR100 siblings are Extended and live in Batch 2.2

### Batch 1.4 — skip-counting (constructs `skip2_forward`, `skip2_backward`, `skip5_forward`, `skip5_backward`, `skip10_forward`, `skip10_backward`)
- [x] `skip2_forward_zr20` — shipped, `docs/superpowers/plans/2026-09-17-skip2-zr20.md`; Reused from C6.1 `Count in Steps of 2` (`count_steps2_exercise.dart`); number strip with step highlighting
- [x] `skip2_backward_zr20` — shipped, `docs/superpowers/plans/2026-09-17-skip2-zr20.md`; Reused from the same C6.1 file family, backward direction
- [x] `skip2_forward_zr100` — shipped, `docs/superpowers/plans/2026-09-17-skip2-zr100.md`; Reused from C6.2/C6.3 `Count in Steps on 100-Field`; Hundertertafel, field-visible level
- [x] `skip2_backward_zr100` — shipped, `docs/superpowers/plans/2026-09-17-skip2-zr100.md`; Reused from the same C6.2/C6.3 family, backward / mental (field hidden) level
- [x] `skip5_forward_zr100` — shipped, `docs/superpowers/plans/2026-09-17-skip5-skip10-zr100.md`; Reused from the same C6.2/C6.3 family, whose "5er-Schritte" levels are already built
- [x] `skip5_backward_zr100` — shipped, `docs/superpowers/plans/2026-09-17-skip5-skip10-zr100.md`; Reused from the same "5er-Schritte" levels, backward direction
- [x] `skip10_forward_zr100` — shipped, `docs/superpowers/plans/2026-09-17-skip5-skip10-zr100.md`; Reused from the same C6.2/C6.3 family, whose "10er-Schritte" levels are already built
- [x] `skip10_backward_zr100` — shipped, `docs/superpowers/plans/2026-09-17-skip5-skip10-zr100.md`; Reused from the same "10er-Schritte" levels, backward direction

### Batch 1.5 — ordering number cards (construct `order_cards`)
- [x] `order_cards_zr20` — shipped, `docs/superpowers/plans/2026-09-17-order-cards-zr20.md`; Reused from C2.1 `Order Cards to 20` (`order_cards_exercise.dart`); draggable number cards (3 cards → 5 adjacent → 5 spread)

### Batch 1.6 — placing numbers on the line (construct `place_on_numberline`)
- [x] `place_on_numberline_zr20` — shipped, `docs/superpowers/plans/2026-09-17-place-on-numberline-zr20.md`; Reused from C10.1 `Place Numbers on Line (0-20)` (`place_numbers_exercise.dart`); wraps `ZahlenstrahlPainter` (`manipulatives/zahlenstrahl.dart`)
- [x] `place_on_numberline_zr100` — shipped, `docs/superpowers/plans/2026-09-17-place-on-numberline-zr20.md`; Reused from C10.2 `Place Numbers on Line (0-100)`; same line painter, ZR100

### Batch 1.7 — decomposition (construct `decompose`)
- [x] `decompose_single_digit` — shipped, `docs/superpowers/plans/2026-09-17-decompose-single-digit.md`; Reused from `Z1 Decompose 10` (`decompose_10_exercise.dart`), generalised from a fixed 10 to any single-digit target; part-whole splitting tool

### Batch 1.8 — comparing quantities (construct `compare_quantity`)
- [x] `compare_quantity_difference` — shipped, `docs/superpowers/plans/2026-09-17-compare-quantity-difference.md` — Reused from S1.4 `More or Less (Hamstern)` (`more_less_exercise.dart`); dice-roll comparison, intentionally single-level (10 rounds)

### Batch 1.9 — finger-quantity recognition (construct `fingerblitz`)
- [x] `fingerblitz_quantity_zr10` — shipped, `docs/superpowers/plans/2026-09-17-fingerblitz-quantity-zr10.md` — Reused from S1.1 `Fingerblitz`, "See (No limit) → See (Flash)" levels directly; finger-pattern flash display

### Batch 1.10 — deriving via the power of 10 (construct `derive_10`)
- [x] `derive_via_10_add_minus1` — shipped, `docs/superpowers/plans/2026-09-17-derive-via-10.md` — Reused from S1.1 `Fingerblitz`'s "Make (10-n)" level; ten-frame anchored to 10 (e.g. 6+9 via 6+10-1)
- [x] `derive_via_10_add_plus1` — shipped, `docs/superpowers/plans/2026-09-17-derive-via-10.md` — Reused from the same S1.1 power-of-10 family, the 10+1 pattern (e.g. 7+11 via 7+10+1)
- [x] `derive_via_10_sub` — shipped, `docs/superpowers/plans/2026-09-17-derive-via-10.md` — Reused from the same S1.1 power-of-10 family, subtraction (e.g. 15-8 via 15-10+2)

### Batch 1.11 — doubling (construct `double`)
- [x] `double_zr10` — shipped, Task 4 of this plan (`docs/superpowers/plans/2026-09-15-exercise-plan-foundation.md`); Reused from S3.1 `Doubling with Mirror (ZR10)` (`doubling_mirror_exercise.dart`, min 1–5), retargeted onto its v4 id
- [ ] `double_zr10_to_zr20` — Reused from S3.2 `Doubling with Mirror (ZR20)` (same file, min 6–10); same 3-level mirror progression
- [ ] `double_crossing_10` — Reused from S3.4 `Doubling on Calculation Boat` (`doubling_boat_exercise.dart`); Rechenschiffchen 5/10-structure (e.g. double 7)
- [ ] `double_decade` — Reused from S3.6 `Zehner verdoppeln` (`doubling_tens_exercise.dart`); ten-rod material or scaled mirror (e.g. double 30)

### Batch 1.12 — tens arithmetic (construct `tens_add_sub`)
- [ ] `tens_add_tens` — Reused from S3.7 `Rechnen mit Zehnern` (`tens_calculation_exercise.dart`); Visual Add → Symbolic + levels
- [ ] `tens_sub_tens` — Reused from the same S3.7 file; Visual Sub → Symbolic − levels
- [ ] `tens_sub_crossing_hundred` — Reused from the same S3.7 file, plus its 100-crossing level (e.g. 100−20)

### Batch 1.13 — compensation (construct `compensation_strategy`)
- [ ] `compensation_strategy_zr20` — Reused from S2.3 `Opposite Change` (`opposite_change_exercise.dart`); two-pile counters, simultaneous +1/−1 manipulation

## Tier 2: Extended (31)

An old exercise's manipulative and level structure is stretched to a new
range or twist. None shipped yet.

### Batch 2.1 — counting quantities, unstructured (construct `quantify_count`)
- [ ] `quantify_count_zr20` — Extended from C1.1's dot field, range raised to 20 with unstructured layouts only (ZR20 becomes the always-unstructured half)

### Batch 2.2 — successor & predecessor in ZR100 (constructs `successor`, `predecessor`)
- [ ] `successor_zr100_mid` — Extended from C4.1's number-card widget, ZR100 mid-range (ones-digit 1–7, then 8–9 near-carry)
- [ ] `predecessor_zr100_mid` — Extended from the same number-card widget, predecessor direction
- [ ] `successor_zr100_five` — Extended from the same widget, numbers ending in 5
- [ ] `predecessor_zr100_five` — Extended from the same widget, numbers ending in 5
- [ ] `successor_zr100_decade` — Extended from the same widget, decade-boundary numbers (hardest tier)
- [ ] `predecessor_zr100_decade` — Extended from the same widget, decade-boundary numbers

### Batch 2.3 — ordering number cards in ZR100 (construct `order_cards`)
- [ ] `order_cards_zr100` — Extended from C2.1's draggable number cards, ZR100 range (same-decade then cross-decade)

### Batch 2.4 — completing to 20/100 (construct `complete_to`)
- [ ] `complete_to_20` — Extended from the complete_to_10 part-whole completion tool (domain A), target 20
- [ ] `complete_to_100` — Extended from the same completion tool, decade targets (34→40) then direct completion to 100

### Batch 2.5 — structured seeing to 20 (construct `structured_quantity_recognition`)
- [ ] `structured_quantity_recognition_zr20` — Extended from the twenty-frame flash mechanic, two ten-frames (full + 6 → 16)

### Batch 2.6 — rapid recognition on the boat (construct `quick_recognition`)
- [ ] `quick_recognition_rechenschiffchen_zr20` — Extended from S3.4's Rechenschiffchen (`rechenschiffchen_widget.dart`), reframed as flash recognition rather than doubling

### Batch 2.7 — image, symbol and word (construct representation_bild_symbol)
- [ ] `representation_bild_symbol_wort` — Extended from the picture↔numeral matching game, three-way with the confusable number-word triples (6/16/60, 7/17/70)

### Batch 2.8 — bundling overflow (construct `bundling_recognition`)
- [ ] `bundling_recognition_overflow_zr100` — Extended from the Dienes display (`dienes_place_value.dart`), deliberately shown with 10+ loose units (2 rods + 13 units → 33)

### Batch 2.9 — hundred-chart structure (construct `hundred_chart`)
- [ ] `hundred_chart_structure_zr100` — Extended from `hundred_chart_widget.dart`, sparser labeling, explicit ±1 row / ±10 column rule

### Batch 2.10 — marked number line (construct `number_line_strategy`)
- [ ] `number_line_zahlenstrahl` — Extended from `number_line_endpoints_widget.dart`, midpoint positioning (endpoints 40 and 80 → 60)

### Batch 2.11 — power of 5 (construct `basic_fact_5`)
- [ ] `basic_fact_add_with_5` — Extended from S1.1 `Fingerblitz`'s "Make (5+n)" level, generalised from finger patterns to abstract facts
- [ ] `basic_fact_sub_with_5` — Extended from the same "Kraft der 5" finger-pattern display, subtraction

### Batch 2.12 — deriving via the power of 5 (construct `derive_5`)
- [ ] `derive_via_5_add` — Extended from the same Fingerblitz mechanic, framed as deriving an unknown fact from a known 5-fact (5+4=9 → 5+3)
- [ ] `derive_via_5_sub` — Extended from the same, subtraction

### Batch 2.13 — doubling 2-digit numbers (construct `double`)
- [ ] `double_2digit_nocarry` — Extended from S3.6's tens material plus S3.4's boat/structure idea, full 2-digit numbers with no ones-carry (42→84); Dienes place-value display
- [ ] `double_2digit_with_carry` — Extended from the same, deliberately choosing an ones-overflow that becomes a new ten (35→70)

### Batch 2.14 — decade analogy (construct `decade_analogy`)
- [ ] `decade_analogy_add` — Extended from S3.7's "analogy to ones" framing, transferring a known ZR10 fact to ZR20/ZR100 (3+4=7 → 30+40=70)
- [ ] `decade_analogy_add_crossing_hundred` — Extended from the same, crossing toward 100 (60+40)

### Batch 2.15 — near-doubling derivation (construct `derive_near_double`)
- [ ] `derive_via_near_double_add` — Extended from the double family's mastery as anchor fact (6+6=12 → 6+7)
- [ ] `derive_via_near_double_sub` — Extended from the same near-doubling anchor, subtraction

### Batch 2.16 — compensation shift (construct `shift_plus_minus`)
- [ ] `shift_plus_minus_1_2_zr10` — Extended from C4.1's successor/predecessor mechanic, ±1 then ±2 framed as a calculation

### Batch 2.17 — gap-fill arithmetic (construct `complete_gap`)
- [ ] `complete_gap_end` — Extended from the domain A completion tool, reframed as an explicit gap equation (5+_=8)
- [ ] `complete_gap_start` — Extended from the same completion tool, gap on the other side (_+2=7)

### Batch 2.18 — word problems: subtraction and translation (construct `operation_sense`)
- [ ] `operation_sense_sub` — Extended from `templates/word_problem_widget.dart`, both subtraction sub-types the skill names (take-away and comparison)
- [ ] `operation_sense_story` — Extended from the same widget, framed as translation to an equation rather than solving (3 birds + 2 → writes 3+2)
- Note: the third operation_sense skill is New — widget exists and sits in Batch 3.8, not here

## Tier 3: New — widget exists (11)

No old *exercise* covers these, but a reusable visual widget already exists
(built for the diagnostic or the retired Gauntlet template engine) — wrap
it in a new scaffolded exercise rather than drawing the manipulative from
scratch.

### Batch 3.1 — structured seeing to 10 (construct `structured_quantity_recognition`)
- [ ] `structured_quantity_recognition_zr10` — New — widget exists: wraps `interactive_twenty_frame_widget.dart` (ten-frame layout); archetype mechanic borrowed from S1.1's "See (Flash)" level

### Batch 3.2 — hundred-dot-field estimation (construct `dot_field`)
- [ ] `dot_field_full` — New — widget exists: 100-dot field reusing `hundred_chart_widget.dart`'s row/column logic; level 1, full field recognised as 100
- [ ] `dot_field_small` — New — widget exists: same dot field; level 2, ~12 read via tens-structure
- [ ] `dot_field_large` — New — widget exists: same dot field; level 3, ~85 read via tens-structure
- [ ] `dot_field_near_max` — New — widget exists: same dot field; level 4, ~99 by reasoning about the missing dots
- Note: design doc §5 makes these four one exercise family with four levels — build them as one plan, while keeping the four skill ids separately assignable per §2

### Batch 3.3 — bundling recognition (construct `bundling_recognition`)
- [ ] `bundling_recognition_zr100` — New — widget exists: wraps `dienes_place_value.dart`; archetype shape borrowed from S3.6's "Mirror/Material → Manual Placing → Mental"

### Batch 3.4 — hundred-chart navigation (construct `hundred_chart`)
- [ ] `hundred_chart_navigation` — New — widget exists: `hundred_chart_widget.dart`'s single-blank mode (find the missing cell), extending the C6.0 100-field family

### Batch 3.5 — empty number line (construct `number_line_strategy`)
- [ ] `number_line_rechenstrich` — New — widget exists: adapts `number_line_endpoints_widget.dart` into an empty jump-strategy calculation line

### Batch 3.6 — number wall (construct `number_wall`)
- [ ] `number_wall_zr20` — New — widget exists: wraps `number_wall_widget.dart` (currently static, diagnostic-only)

### Batch 3.7 — magnitude estimation (construct `magnitude_estimate`)
- [ ] `magnitude_estimate_zr100` — New — widget exists: reuses the 100-dot-field from the dot_field family for a without-computing estimation task

### Batch 3.8 — word problems: addition (construct `operation_sense`)
- [ ] `operation_sense_add` — New — widget exists: wraps `templates/word_problem_widget.dart` (built for the now-retired template engine, directly reusable)
- Note: the brief asked whether the word-problem skills belong in a Tier 4 batch. Design doc §5 says no: this one is New — widget exists (here) and the other two are Extended (Batch 2.18), so the family straddles Tiers 2 and 3, not Tier 4

## Tier 4: New — from scratch (20 remaining of 21)

No old exercise and no existing widget — design following the same
conventions (CRA progression, `MinimalistExerciseScaffold`,
`EXERCISE_DESIGN_SYSTEM.md`, `DIFFICULTY_CURVE.md`) as everything else.

### Batch 4.1 — cross-decade arithmetic (constructs `cross_decade_add`, `cross_decade_sub`)
- [ ] `cross_decade_add_zr100_1digit` — New — from scratch; builds on the number_line_rechenstrich empty-line jump strategy (domain B), 1-digit second operand (27+8)
- [ ] `cross_decade_add_zr100_2digit` — New — from scratch; same empty-line jump strategy, both operands 2-digit (55+38)
- [ ] `cross_decade_sub_zr100_1digit` — New — from scratch; same empty-line jump strategy, 1-digit subtrahend (44-9)
- [ ] `cross_decade_sub_zr100_2digit` — New — from scratch; same empty-line jump strategy, 2-digit subtrahend (64-28)

### Batch 4.2 — reasoning skills (constructs `even_odd`, `equation_equivalence`, `commutativity`, `calculation_triangle`)
- [ ] `even_odd_recognition` — New — from scratch; pair-up visual (objects grouped into pairs, one leftover if odd), objects then numerals only
- [ ] `equation_equivalence_zr20` — New — from scratch; two equation cards side by side, true/false judgment (7+3 vs 8+2)
- [ ] `commutativity_zr20` — New — from scratch; a+b vs b+a, visually adjacent to equation_equivalence so it could share that widget with a narrower prompt
- [ ] `calculation_triangle_zr20` — New — from scratch; three-number triangle, one side's relationship visualised

### Batch 4.3 — halving: the archetype gap (construct `halve`)
- [x] `halve_zr10` — shipped, Task 5 of this plan (`docs/superpowers/plans/2026-09-15-exercise-plan-foundation.md`); New — from scratch, and the skill whose mirror-plus-boat widgets the rest of this family splits with
- [ ] `halve_zr20_anchor` — New — from scratch; mirrors the doubling widgets run in reverse, anchored at 10 (12 → 10+2 → 5+1)
- [ ] `halve_zr20_crossing` — New — from scratch; Rechenschiffchen, values needing a Bündelwechsel (14→7)
- [ ] `halve_decade` — New — from scratch; Dienes ten-rods split evenly (40→20)
- [ ] `halve_2digit_clean` — New — from scratch; rods and units split separately, no remainder crossing (64→32)
- [ ] `halve_2digit_needs_decomposition` — New — from scratch; a rod must be broken into units first (70→35, 58→29 — the specific gap flagged in `docs/clean-room/00-v1-assessment.md`)
- Note: all six are New — from scratch per design doc §5 (the one construct family with genuinely zero old archetype), not Extended as the brief's worked example filed them

### Batch 4.4 — counting backward (construct `count_backward`)
- [ ] `count_backward_zr20` — New — from scratch; mirrors C3.1's number strip in reverse (20 down to 10, then any start 5–20)
- [ ] `count_backward_zr100` — New — from scratch; same number strip, ZR100 with decade-boundary starts (72 → past 70)

### Batch 4.5 — completing to 10 (construct `complete_to`)
- [ ] `complete_to_10` — New — from scratch: `Z2 Make 10` was planned in `exercise_service.dart` but never built (stub only); run the Z1 part-whole tool in reverse (given one part, find the missing part)

### Batch 4.6 — ordinal numbers & representation (constructs `ordinal`, representation_bild_symbol)
- [ ] `ordinal_1` — New — from scratch; a row of distinct objects (animals in a race), identify the Nth / state the marked object's position
- [ ] `representation_bild_symbol` — New — from scratch; picture↔numeral matching game with distractor numerals (7 vs 17)

### Batch 4.7 — number-word dictation (construct `number_word_dictation`)
- [ ] `number_word_dictation_zr100` — New — from scratch; audio prompt plus numeral-entry pad, reusing the diagnostic's TTS pipeline

### Batch 4.8 — number-line inequality strategies (construct `number_line_strategy`)
- [ ] `number_line_strategies` — New — from scratch; number line with a shrinking highlighted range, one then two inequalities (more than 60, less than 70 → 66)

## Done
- [x] double_zr10 — Task 4, `docs/superpowers/plans/2026-09-15-exercise-plan-foundation.md`
- [x] halve_zr10 — Task 5, `docs/superpowers/plans/2026-09-15-exercise-plan-foundation.md`
- [x] quantify_count_zr10 — `docs/superpowers/plans/2026-09-17-quantify-count-zr10.md`
- [x] count_forward_zr20 — `docs/superpowers/plans/2026-09-17-count-forward-zr20-zr100.md`
- [x] count_forward_zr100 — `docs/superpowers/plans/2026-09-17-count-forward-zr20-zr100.md`
- [x] successor_zr20_decade — `docs/superpowers/plans/2026-09-17-successor-predecessor-zr20-decade.md`
- [x] predecessor_zr20_decade — `docs/superpowers/plans/2026-09-17-successor-predecessor-zr20-decade.md`
- [x] skip2_forward_zr20 — `docs/superpowers/plans/2026-09-17-skip2-zr20.md`
- [x] skip2_backward_zr20 — `docs/superpowers/plans/2026-09-17-skip2-zr20.md`
- [x] skip2_forward_zr100 — `docs/superpowers/plans/2026-09-17-skip2-zr100.md`
- [x] skip2_backward_zr100 — `docs/superpowers/plans/2026-09-17-skip2-zr100.md`
- [x] skip5_forward_zr100 — `docs/superpowers/plans/2026-09-17-skip5-skip10-zr100.md`
- [x] skip5_backward_zr100 — `docs/superpowers/plans/2026-09-17-skip5-skip10-zr100.md`
- [x] skip10_forward_zr100 — `docs/superpowers/plans/2026-09-17-skip5-skip10-zr100.md`
- [x] skip10_backward_zr100 — `docs/superpowers/plans/2026-09-17-skip5-skip10-zr100.md`
- [x] order_cards_zr20 — `docs/superpowers/plans/2026-09-17-order-cards-zr20.md`
- [x] place_on_numberline_zr20 — `docs/superpowers/plans/2026-09-17-place-on-numberline-zr20.md`
- [x] place_on_numberline_zr100 — `docs/superpowers/plans/2026-09-17-place-on-numberline-zr20.md`
- [x] decompose_single_digit — `docs/superpowers/plans/2026-09-17-decompose-single-digit.md`
- [x] compare_quantity_difference — `docs/superpowers/plans/2026-09-17-compare-quantity-difference.md`
- [x] fingerblitz_quantity_zr10 — `docs/superpowers/plans/2026-09-17-fingerblitz-quantity-zr10.md`
- [x] derive_via_10_add_minus1 — `docs/superpowers/plans/2026-09-17-derive-via-10.md`
- [x] derive_via_10_add_plus1 — `docs/superpowers/plans/2026-09-17-derive-via-10.md`
- [x] derive_via_10_sub — `docs/superpowers/plans/2026-09-17-derive-via-10.md`

(Ids are left unbackticked here on purpose: the completeness check counts
each skill id once inside backticks, and these twenty-four are tracked in
Batches 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 1.10 and 4.3 above.)
