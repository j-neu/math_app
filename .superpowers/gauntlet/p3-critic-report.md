# P3 Skill Specs — Independent Critic Report

**Date:** 2026-08-31 · **Scope:** all 36 `docs/clean-room/skills/specs/*.json` vs. P2 §4/§5, P3 §2–§6, construct map, provenance CSV
**Method:** every spec read in full; all arithmetic hand-computed from the params; mechanical verification scripted (schema, params vocabulary, taxonomy, slow bands, mastery, sequence_gap ZR/length, numberline congruence, provenance coverage, U+FFFD/mojibake scan)

## Single biggest remaining gap

Several C-domain levels require construct-specific partitions — a full ten in one box (C2.1 L1), Verdopplung+1 (C3.3 L1), Summand/Zehner/Einer (C3.4a/b L1) — but P2 §5 rule 1 defines drag_partition correctness as only "sum of box counts == total", so the evaluator accepts a child's wrong split (e.g. C2.1 L1: 11 = 9 + 2, no full ten anywhere) as correct, and no param or extension in §4.5/§4.5b encodes the required split.

## Findings

| Spec | Finding | Severity | JSON path |
|---|---|---|---|
| A1.1b | L3 `start_range:[40,50]` contradicts mapping ("cross 99→100") and provenance note ("[93,93] erzwingt die Folge 93-100"); max sequence value is 57, so the level never reaches 100 and no gap ever sits on a ten boundary; prompt "Zähle bis zur 100 weiter" is false | Critical | levels[2].params.start_range |
| A1.2b | L3 `start_range:[71,73]` contradicts mapping ("cross 100") and provenance note ("[100,100] kreuzt 100 nach 99"); sequence runs 73…66, never crosses 100, no gap on a ten boundary; prompt "Zähle von der 100 rückwärts" is false | Critical | levels[2].params.start_range |
| C3.1b | L2 params carry `op:"-"`, a key not in the §4.5 vocabulary for `stellenwerttafel_read` (mode/columns/rows/number_range) nor in §4.5b; provenance admits "in §4.5 nicht explizit geführt"; a strict `check_specs.py` rejects the spec | Important | levels[1].params.op |
| C3.1a | No construct-specific error rule — taxonomy is only common codes (place_error, miscount, incomplete, other); P3 §6 mandates ≥1 per spec | Important | error_taxonomy |
| C3.1b | Same: only place_error, sign_error, miscount, incomplete, other | Important | error_taxonomy |
| C3.1a / C3.1b | L3 `mode:"place_value"` is under-specified for the construct: §4.5 defines place_value as a single-number decomposition ("4 Zehner 3 Einer = ?"), but the construct needs two two-digit addends with column-wise sums; params provide only singular `tens_range`/`ones_range`, so two addends (and the no-carry / no-borrow constraint) are not derivable from the spec | Important | levels[2].params.mode |
| B2.3 | L1 place_counters with only `count_range:[20,99]` renders the standard form (34 = 3 Z, 4 E); the construct requires the non-standard form (2 Z, 14 E) and no param encodes that decomposition, so the enactive level cannot deliver the construct | Important | levels[0].params |
| C2.1 | L1 drag_partition box_labels ["volle Zehn","Rest"] requires one box to hold exactly 10, but §5 evaluates only "sum == total" (11 = 9+2 passes with no full ten); only `equal:true` (§4.5b) has a stricter documented rule | Important | levels[0].params.box_labels |
| C3.3 | L1 drag_partition ["Verdopplung","1 dazu"] requires one box = total−1 and one = 1; sum-check accepts e.g. 17 = 9+8 | Important | levels[0].params.box_labels |
| C3.4a | L1 drag_partition ["1. Summand","Zehner","Einer"] requires the "Zehner" box to hold a multiple of 10; sum-check accepts any 3-part split (e.g. 62 = 60+1+1) | Important | levels[0].params.box_labels |
| C3.4b | L1 drag_partition ["Rest","Zehner","Einer"] same defect as C3.4a | Important | levels[0].params.box_labels |
| A1.1b | L2 start_range [46,49] with gap_indices [2]: starts 46/47 put the gap off the boundary (46,47,_,49,50 → gap 48); only starts 48/49 deliver "gap across the ten boundary" as mapped | Minor | levels[1].params.start_range |
| A3.3 | L2 `length:3` violates the stated length gate 4..8 (A1.4's provenance explicitly documents lengthening to 5 to meet this gate; A3.3 silently uses 3) | Minor | levels[1].params.length |
| C1.1b | L3 minuend [2,20] × subtrahend [1,10] admits 2−10 = −8; never-negative depends on an undocumented generator filter, not on the params | Minor | levels[2].params.a_range |
| C4.2 | L2 `form:"gap"` op "-" minuend [5,18] × subtrahend [2,9] admits 5−9 = −4 | Minor | levels[1].params.a_range |
| C2.1 | L2 `form:"helper"` a [8,9] × b [2,9] admits 8+2 = 10 → gap 0 (no overstep) for an always-overstep construct | Minor | levels[1].params.b_range |
| C2.3 | L2 `form:"missing_addend"` a [5,9] × b [2,9] admits 5+2 = 7 (no overstep) for the "Ergänzen über die Zehn" construct | Minor | levels[1].params.b_range |
| A2.3 | L1/L2 picture_compare left/right ranges [1,10]×[1,10] allow equal counts, making "mehr/weniger" unanswerable; relies on an undocumented re-roll (P2 Task 5 "difference ≥ 1") | Minor | levels[0].params |

**Counts: Critical 2 · Important 9 · Minor 7 · Total 18**

## Evidence (independent arithmetic)

- **A1.1b L3 (Critical):** start 50 + step 1 × 7 = 57 max; start 40 → 40…47. No start in [40,50] puts index 2 or 5 of an 8-sequence at 99/100 (would need starts 94/97). Provenance row for A1.1b literally says `start_range [93,93]`; JSON says `[40,50]`.
- **A1.2b L3 (Critical):** start 73 − 7 = 66 min; start 71 → 71…64. Gap at 100→99 would need start 101 or 105; at 90→89 would need 92/96 — none in [71,73]. Provenance row says `[100,100]`; JSON says `[71,73]`.
- **C3.1b L2 (Important):** `"op": "-"` on `stellenwerttafel_read`; §4.5 key list for that template is `mode, columns, rows, number_range` only. Provenance confirms it is an unlisted additive variant.
- **C3.1a/b taxonomy (Important):** all codes ∈ {place_error, sign_error, miscount, incomplete, other} = the P3 §6 common set; no construct code.
- **C3.1a/b L3 (Important):** `place_value` mode per §4.5 renders one number ("4 Zehner 3 Einer = ?"); a two-addend renderer needs two (tens,ones) draws — only one `tens_range`/`ones_range` exists. Hand-check of intent: (3,4)+(2,1) → 34+21=55, column sums 5/5 ≤ 9 ✓; (4,4)+(4,4) → 88, still fine — arithmetic works, but the spec cannot express it.
- **B2.3 L1 (Important):** place_counters §5 rule 2 = "Correct iff filled == chosen count" with count drawn from `count_range`; 34 fills 3 Z + 4 E. The non-standard 2 Z + 14 E needs a distinct display mode that no param selects.
- **drag_partition sum-check (Important):** §5 rule 1 "Correct iff sum of box counts == total" (parts ≥ 1). C2.1 L1: total 11, child splits 9+2 → sum 11 = correct, but no full ten → construct (Teilschritt zur vollen Zehn) not exercised. Same for C3.3 (17=9+8), C3.4a (62=60+1+1, "Zehner" box not a ten), C3.4b.
- **Sample instantiations that DID verify clean** (all 15 checked): C2.1 helper 8+7=10+5 (gap=15−10=5 ✓), 9+3=10+2 ✓; C3.2 helper − 45−7=40−2 (gap=7−5=2 ✓), 98−9=90−1 ✓; C3.4a helper 35+27=35+20+7 (gap=ones(27)=7 ✓); C3.4b 62−27=62−20−7 ✓; helper_double 6+7=12+1 (gap=1 ✓), 13+14=26+1 ✓; half 12→6 (=12/2 ✓); place_value 2 Z 14 E = 34 ✓, max 8×10+19=99 ≤ zr ✓; any_split total 7 → (0,7)…(7,0) all sum 7 ✓; missing_addend 7+5=12 ✓; strategy_choice 6+6=12 (verdoppeln ✓), 37+28=65 (ones 7+8=15 ≥ 11 ✓), 13+14=27 (fast_verdoppeln ✓); C3.1a/b L1 count_range 22–88 / 11–88 two-digit results ✓.
- **Checks that passed across all 36:** provenance CSV has exactly one `skill_spec` row per skill_id (0 missing, 0 extra); zero U+FFFD/mojibake (verified at codepoint level, umlauts are `0xe4`/`0xf6`/`0xfc`); all child-facing strings German, imperative, non-blaming; representation == template category on all 108 level slots; slow_band_ms ∈ {9000,7000,6000} per slot and mastery.correct_of == 8 everywhere; all equation_solve/equation_gap/strategy_choice/word_problem keys within the §4.5/§4.5b vocabulary (only `op` on C3.1b L2 violates); subitizing ≤5 (A2.1 all levels [1,5], flash_ms 800); numberline_locate values never endpoints and inside range (B2.2 L2 [1,19]/[0,20], L3 [1,99]/[0,100]); A1.3 L1 congruence start ∈ {2,4,6,8,10} ≡ 0 mod 2 ✓; taxonomy codes unique within every spec.
