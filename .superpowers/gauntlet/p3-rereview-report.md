# P3 Skill Specs — Independent Re-Review Report

**Date:** 2026-08-31 · **Method:** every finding verified against the actual JSONs in `docs/clean-room/skills/specs/` (not the fixes report); `scripts/check_specs.py` run; arithmetic hand-computed from the params; P2 §5 / P3 §4.5 / §4.5b re-read.

**Gate:** `python scripts/check_specs.py` → `OK: 36 specs validated`, exit 0.

| # | Finding | Verdict | Evidence (actual files) |
|---|---|---|---|
| 1 | A1.1b L3 start_range/prompt contradict sequence; no ten-boundary gap | **ADDRESSED** | `A1.1b.json` L3: `start_range:[47,48]`, `length:8`, `gap_indices:[2,5]`. start 47 → 47…54, gaps 49,52; start 48 → 48…55, gaps 50,53. Every start puts a gap on the 49/50 boundary; within ZR100. Prompt `"Zähle weiter und tippe die fehlenden Zahlen ein."` matches the gap-fill (no false "bis zur 100"). |
| 2 | A1.2b L3 start_range contradicts "cross 100"; no boundary gap | **ADDRESSED** | `A1.2b.json` L3: `start_range:[51,52]`, `length:8`, `gap_indices:[2,6]`, `direction:"down"`. start 51 → 51…44, gaps 49,45; start 52 → 52…45, gaps 50,46. Gap on the 50/49 boundary in every draw; min 44 ≥ 0. Prompt matches sequence. |
| 3 | C3.1b L2 `op:"-"` outside §4.5 vocabulary | **ADDRESSED** | `C3.1b.json` L2 has `mode:"sum_rows"`, `rows:"two_rows"`, `op:"-"`. `scripts/check_specs.py` whitelists `("stellenwerttafel_read","op") ∈ {"+","-"}` (line 121) and the plan §4.5 row now lists `op` for `sum_rows`. Validator passes. |
| 4 | C3.1a no construct-specific taxonomy code | **ADDRESSED** | `C3.1a.json` taxonomy = `column_swap` ("Zehner und Einer vertauscht"), `miscount`, `incomplete`, `other`. `column_swap` is not in the P3 §6 common set; codes unique. |
| 5 | C3.1b no construct-specific taxonomy code | **ADDRESSED** | `C3.1b.json` taxonomy = `place_error`, `sign_error`, `borrow_error` ("unnötig einen Zehner geöffnet"), `miscount`, `incomplete`, `other`. `borrow_error` is construct-specific and consistent with the no-borrow construct. |
| 6 | C3.1a/b L3 `place_value` under-specified (one (tens,ones) pair can't express two operands + no-carry/borrow) | **ADDRESSED** | C3.1a L3: `rows:"two_rows"`, `column_constraint:"no_carry"`, `tens_range:[1,4]`, `ones_range:[1,4]` → max column sum 4+4=8 ≤ 9 (derivable from ranges). C3.1b L3: `column_constraint:"no_borrow"`, `tens_range:[1,9]`, `ones_range:[1,9]`; §4.5b documents the generator obligation (subtrahend column ≤ minuend column). Validator whitelists `rows`/`column_constraint`. |
| 7 | B2.3 L1 cannot express non-standard form | **ADDRESSED** | `B2.3.json` L1: `place_counters`, `count_range:[20,99]`, `frame:"stellenwerttafel"`, `mode:"nonstandard"`. Decomposition z = n div 10 − 1 (1–8), o = 10 + n mod 10 (10–19): e.g. 34 → 2 Z 14 E = 34 ✓. `mode` whitelisted as enum `standard\|nonstandard`. |
| 8 | C2.1 L1 drag_partition only sum-checks | **ADDRESSED** | `C2.1.json` L1: `parts:2`, `split_constraint:"make_ten"`, `box_labels:["volle Zehn","Rest"]`, `total_range:[11,19]`. P2 §5: one box == 10, other == total−10; 15=9+6 now incorrect. `equal` key removed. |
| 9 | C3.3 L1 sum-check accepts 17 = 9+8 | **ADDRESSED** | `C3.3.json` L1: `parts:3`, `split_constraint:"near_double"`, `box_labels:["Verdopplung","Verdopplung","1 dazu"]` (labels length 3 == parts). Odd total 11–19 → n+n+1; 17 = 8+8+1, 9+8 rejected. Validator enforces `near_double` ⇒ parts==3. |
| 10 | C3.4a L1 "Zehner" box need not be a multiple of 10 | **ADDRESSED** | `C3.4a.json` L1: `parts:3`, `split_constraint:"tens_ones"`, `box_labels:["1. Summand","Zehner","Einer"]`. 35+27 → 35, 20, 7; box2 = 10·floor(b/10) ✓. |
| 11 | C3.4b L1 same defect | **ADDRESSED** | `C3.4b.json` L1: `split_constraint:"tens_ones"`, `box_labels:["Rest","Zehner","Einer"]`. 62−27 → 62, 20, 7 ✓. |
| 12 | A1.1b L2 starts 46/47 put gap off the boundary | **ADDRESSED** | `A1.1b.json` L2: `start_range:[47,48]`, `length:5`, `gap_indices:[2]`. start 47 → 47,48,\_,50,51 (gap 49); start 48 → 48,49,\_,51,52 (gap 50). Both on the 49/50 boundary. |
| 13 | A3.3 L2 length 3 violates 4–8 gate | **ADDRESSED** | `A3.3.json` L2: `length:4`, `progression:"double"`, `step:2`, `start_range:[2,3]` → 2,4,8,16 / 3,6,12,24 (gap 4/6). `check_specs.py` now enforces `sequence_gap.length ∈ [4,8]`. |
| 14 | C1.1b L3 admits 2−10 = −8 | **ADDRESSED** | `C1.1b.json` L3: `a_range:[11,20]`, `b_range:[1,10]` → min result 11−10 = 1 ≥ 0. |
| 15 | C4.2 L2 admits 5−9 = −4 | **ADDRESSED** | `C4.2.json` L2: `a_range:[11,18]`, `b_range:[2,9]` → min result 11−9 = 2 ≥ 1. |
| 16 | C2.1 L2 helper admits 8+2=10 (gap 0) | **ADDRESSED** | `C2.1.json` L2: `a_range:[8,9]`, `b_range:[3,9]` → min a+b = 11 > 10; gap = a+b−10 ∈ [1,8] always. Hand-check: 8+7=10+5 ✓, 9+3=10+2 ✓. |
| 17 | C2.3 L2 missing_addend admits 5+2=7 (no overstep) | **ADDRESSED** | `C2.3.json` L2: `a_range:[6,9]`, `b_range:[5,9]` → min sum 11 > 10; 7+\_=12 preserved. |
| 18 | A2.3 L1/L2 picture_compare allows equal counts | **ADDRESSED** | `A2.3.json` L1 (`difference_min:1`, question more) and L2 (`difference_min:1`, question less). Validator enforces `difference_min` is an int ≥ 1; §4.5b re-roll obligation documented. |

**Counts: 18 ADDRESSED · 0 NOT ADDRESSED.**

## Whole-bank re-verification

- `python scripts/check_specs.py` → **OK: 36 specs validated**, exit 0.
- All 36 JSONs parse (validator loaded every `specs/*.json` with `json.loads`).
- Spot-check arithmetic (hand-computed from the params):
  - **C2.1 L2 helper** (`equation_gap form:"helper"`, a∈[8,9], b∈[3,9]): 8+7=10+5, 9+9=10+8 — always `a+b = 10+(a+b−10)`, gap ≥ 1. TRUE.
  - **C3.4a L1 tens_ones** (`total_range:[30,99]`): 62 → 35+20+7 = 62; box2 = 10·floor(27/10) = 20 (multiple of 10), box3 = 27 mod 10. TRUE.
  - **B2.3 L1 nonstandard** (`count_range:[20,99]`): 34 → z = 34 div 10 − 1 = 2, o = 10+4 = 14; 2·10+14 = 34. B2.3 L3 place_value max 8·10+19 = 99 ≤ zr 99. TRUE.
- C3.1b L2 `op:"-"` accepted by `check_specs.py` (whitelist `("stellenwerttafel_read","op"):{"+","-"}`).

## Single biggest remaining content issue

**A1.2b L2 (`start_range:[52,54]`, `length:5`, `gap_indices:[3]`): for start 54 the single gap lands on 51, not on a ten boundary.** The level is titled "Rückwärts über die Zehnergrenze" and mapped as "cross ten boundary", but 1 of the 3 allowed starts (54) produces 54,53,52,_,50 with the missing number 51 — no boundary crossing. Starts 52 (gap 49) and 53 (gap 50) are correct; 54 is not. This is the exact defect class the critic raised for A1.1b L2 (finding 12), fixed there but not mirrored on the symmetric A1.2b L2. Fix would be to restrict `start_range` to `[52,53]`.
