# P3 — 36 Skill Specs Implementation Plan

**Date:** 2026-08-31
**Owner:** Gauntlet controller
**Depends on:** P2 plan §4 (spec JSON schema) and §5 (template semantics)
**Source of truth:** `docs/clean-room/01-construct-map.md`, `docs/clean-room/skills/skills_taxonomy.csv`, `docs/clean-room/skills/*.md`, `docs/clean-room/03-bibliography.md`

## 1. Goal

Author the 36 machine-readable skill specs (`docs/clean-room/skills/specs/<skill_id>.json`), one per skill in the taxonomy, each defining 3 E-I-S practice levels (enaktiv/ikonisch/symbolisch), template + params, German prompts, an error taxonomy with hints, mastery, slow bands, and provenance. Mirror them to `math_app/assets/skill_specs/`. Every spec must satisfy the P2 schema and the pedagogical/math gates below.

## 2. Global constraints

- **Schema:** exactly as P2 plan §4. `scripts/check_specs.py` (P2 Task 2) is the mechanical gate; it must pass for all 36.
- **Template semantics:** exactly as P2 plan §5, including the additive extensions listed in §5 of THIS plan.
- **Math/pedagogy gates (each is a reviewer checkpoint, not a vibe check):**
  - Number ranges match the skill's ZR (A1.1a ZR20, A1.1b/A1.5/B2.2 ZR100, C1.x ZR20, C3.x/C4.x ZR100, D1 ZR20/100 per level).
  - No generated expression can be negative (subtraction always yields ≥0); word problems have a unique, non-negative, age-plausible answer.
  - Subitizing (A2.1) counts ≤ 5.
  - "No tens-overstep" skills (C1.1a) never cross a ten boundary; "overstep" skills (C1.2/C2.x/C3.2) always do where the construct demands.
  - place_value / helper forms are arithmetically true (e.g. `9+4 = 10+3`; `2 Z 14 E = 34`).
  - Errors in the taxonomy are distinct from the correct answer and mutually distinguishable.
- **German:** prompts are grammatical, child-friendly, imperative, no scare language; hints are encouraging, never blaming.
- **Provenance:** one `provenance.csv` row per spec (`type=skill_spec`), sources from `03-bibliography.md`; `scripts/check_provenance.py` stays green.

## 3. Template extensions (additive to P2 §5, implemented in P2 Tasks 4/5/7/8)

- `numberline_step`: +`direction: "up"|"down"`, `step: 1|2|5|10`.
- `place_counters`: `frame: "zehnerfeld"|"rekenrek"|"stellenwerttafel"`; `action: "fill"|"take_away"`.
- `zehnerfeld_read`: `arrangement: "structured"|"two_groups"|"five_pattern"` (two_groups = two colours; child counts the total).
- `stellenwerttafel_read`: `mode: "read"|"sum_rows"` (sum_rows = two counter rows, child types the total).
- `equation_gap`: `prompt_kind`/`form: "gap"|"helper"|"missing_addend"|"any_split"|"place_value"|"half"|"double"|"neighbor"|"helper_double"`. `any_split` (A3.2 L3) renders two blanks `_ + _ = N`; **all** pairs summing to N are accepted and listed in `expected` (params: `zr`, `total_range`).
- `word_problem`: `ask_operation: false|true` (true → child first picks `+`/`−`, then answers).
- `equation_solve`: `mode: "standard"|"place_value"` (place_value prompt: "4 Zehner 3 Einer = ?").

## 4.5 Params vocabulary (authoritative — authors and P2 generators share this)

Only these keys per template, with these meanings. Values must be chosen so the §2 math gates hold.

| template | params keys |
|---|---|
| `drag_partition` | `total_range:[min,max]`, `parts:int(2..3)`, `equal:bool`, `box_labels:[string]` (length == parts) |
| `place_counters` | `count_range:[min,max]`, `frame:"zehnerfeld"\|"rekenrek"\|"stellenwerttafel"`, `action:"fill"\|"take_away"` |
| `bundle_sticks` | `count_range:[min,max]` (min ≥ 12 for bundling) |
| `rekenrek_set` | `count_range:[min,max]`, `rows:2` |
| `numberline_step` | `range:[lo,hi]`, `start_range:[min,max]` (inside range), `target:int`, `step:int(1,2,5,10)`, `direction:"up"\|"down"` |
| `zehnerfeld_read` | `count_range:[min,max]`, `arrangement:"structured"\|"two_groups"\|"five_pattern"` |
| `fingerbild_read` | `count_range:[min,max]`, `hands:1\|2` |
| `stellenwerttafel_read` | `mode:"read"\|"sum_rows"`, `columns:["Z","E"]\|["H","Z","E"]`, `number_range:[lo,hi]` (mode read), `rows:"two_rows"` (mode sum_rows) |
| `numberline_locate` | `range:[lo,hi]`, `value_range:[min,max]` (inside range, min ≥ 1, max ≤ hi−1) |
| `picture_compare` | `left_range:[min,max]`, `right_range:[min,max]`, `question:"more"\|"less"\|"difference"` |
| `equation_solve` | `op:"+"\|"-"`, `unknown:"result"\|"addend"\|"subtrahend"\|"minuend"`, `zr:int`, `a_range:[min,max]`, `b_range:[min,max]`, `mode:"standard"\|"place_value"` (place_value uses tens/ones ranges instead) |
| `equation_gap` | `op:"+"\|"-"`, `form:"gap"\|"helper"\|"missing_addend"\|"place_value"\|"half"\|"double"\|"neighbor"\|"helper_double"`, `zr:int` (+ form-specific ranges: `a_range`, `b_range`, `tens_range`, `ones_range`, `start_range`, `step`) |
| `sequence_gap` | `direction:"up"\|"down"`, `step:int`, `start_range:[min,max]`, `length:int`, `gap_indices:[int...]` |
| `compare_symbols` | `a_range:[min,max]`, `b_range:[min,max]`, `zr:int` |
| `strategy_choice` | `op:"+"\|"-"`, `zr:int`, `a_range`, `b_range`, `strategies:[{id,label_de}]`, `correct_strategy:id` |
| `word_problem` | `contexts:[{setting_de,object_de}]` (≥2 entries), `op:"+"\|"-"`, `zr:int`, `ask_operation:bool` |
| custom | `bundling`/`unbundling`: `number_range:[12,39]`; `flash_subitize`: `count_range:[min,max]` (max ≤ 5), `flash_ms:800`, `display:"dots"\|"rekenrek"`; `numberline_mark`: `range`, `value_range` |

## 4.5b Generator obligations (extensions the runtime MUST honour — authored into the specs)

- `numberline_step`: `start` is sampled from `start_range` FILTERED to values congruent to `target` mod `step` (A1.3 L1 step 2, start_range [2,10] → only even starts).
- `word_problem` `op: "+|-"`: the generator re-rolls the operation per problem (D1.2 ask_operation levels).
- `zehnerfeld_read` `arrangement: "two_groups"` with `count_range` up to 20 (C1.2/C1.3 L2): renders two equal groups/frames, count is the total.
- `equation_solve` `equal: true` (A3.3 L3): force a == b.
- `sequence_gap` `progression: "double"` (A3.3 L2): geometric doubling sequence; `step` is then ignored.
- `drag_partition` `equal: true`: correctness requires equal box counts AND sum == total.
- `equation_gap` `form: "any_split"` (A3.2 L3): two blanks, every pair summing to the total is correct; `expected` lists all pairs.
- `equation_gap` `helper`/`helper_double`/`half`: the gap value is `a+b−10` (helper), `1` (helper_double near-doubles), `total/2` (half) — arithmetic must hold.

## 4. Authoritative level mapping (skill → L1/L2/L3 template: params)

Representation order within each skill: L1 enaktiv, L2 ikonisch, L3 symbolisch. Where a construct has no natural enaktiv form, the mapping substitutes the nearest concrete form; rationale recorded in the spec's provenance `notes`.

**Hard rule on the `representation` field:** it must record the ACTUAL template category, never the ordinal slot. Template categories are fixed: enaktiv = `drag_partition, place_counters, bundle_sticks, rekenrek_set, numberline_step`; ikonisch = `zehnerfeld_read, fingerbild_read, stellenwerttafel_read, numberline_locate, picture_compare`; symbolisch = `equation_solve, equation_gap, sequence_gap, compare_symbols, strategy_choice, word_problem`; custom widgets: `bundling`/`unbundling` = enaktiv, `flash_subitize`/`numberline_mark` = ikonisch. Consequence for the table below: A1.1a/b, A1.2a/b, A1.3, A1.4, A1.5, A2.3, A3.2 (L2), A3.3 (L2), C2.1 (L2), C2.3, C3.2, C3.3, C3.4a/b, C4.1, C4.2, D1.1, D1.2 may end up with a symbolic level in the L1 or L2 slot when no enaktiv/ikonisch template fits the construct — that is correct and expected; the level's `representation` is set accordingly, and the row's rationale goes into the spec's provenance `notes`.

### Domain A — Zahlbegriff (12)
| Skill | L1 | L2 | L3 |
|---|---|---|---|
| A1.1a Vorwärtszählen ZR20 | numberline_step (0–20, start 10–12, dir up, step 1, target 20) | sequence_gap (up, step 1, start 5–14, len 5, mid gap) | sequence_gap (up, step 1, start 5–14, len 8, 2 gaps) |
| A1.1b Vorwärtszählen ZR100 | numberline_step (40–60 window, start 40–42, dir up, step 1, target 60) | sequence_gap (up, step 1, len 5, gap across a ten boundary, e.g. 48,49,_,51) | sequence_gap (up, step 1, len 8, cross 99→100, 2 gaps) |
| A1.2a Rückwärtszählen ZR20 | numberline_step (0–20, start 20–18, dir down, step 1, target 12) | sequence_gap (down, step 1, start 14–18, len 5, mid gap) | sequence_gap (down, step 1, len 8, 2 gaps) |
| A1.2b Rückwärtszählen ZR100 | numberline_step (down, window 60–100, len 5) | sequence_gap (down, step 1, len 5, cross ten boundary) | sequence_gap (down, step 1, len 8, 2 gaps, cross 100) |
| A1.3 Schritte 2/5/10 | numberline_step (0–30, step 2 or 5, dir up) | sequence_gap (step 2/5/10, up+down) | sequence_gap (step 10, ZR100, cross boundary) |
| A1.4 Vorgänger/Nachfolger | sequence_gap (len 3, middle gap: 35,_,37) | sequence_gap (len 5, first-or-last gap: _,43,44,45,46) | sequence_gap (ZR100, len 5, first-and-last gaps) |
| A1.5 Über Zehnerübergang | numberline_step (28–32 window, dir up, target 30) | sequence_gap (gap exactly at 29→30 or 39→40) | sequence_gap (ZR100, gap at 49→50/99→100) |
| A2.1 Subitizing ≤5 | custom flash_subitize (dot flash ≤5) | custom flash_subitize (rekenrek flash ≤5) | zehnerfeld_read (count_range 1–5, structured) |
| A2.2 Strukturierte Erfassung ≤10 | rekenrek_set (count 1–10) | zehnerfeld_read (count 1–10, five_pattern) | fingerbild_read (1–10, two hands) |
| A2.3 Vergleich mehr/weniger | picture_compare (tap more) | picture_compare (tap less) | compare_symbols (a,b ≤10) |
| A3.1 Teil-Teil-Ganzes ZR10 | drag_partition (total 6–10, 2 boxes) | drag_partition (total 6–10, 3 boxes) | equation_gap (missing addend ZR10) |
| A3.2 Zerlegungen flexibel | place_counters (free arrangement, count 5–10) | drag_partition (total 7–10, 2 boxes, different splits) | equation_gap (multi-valid: any split; expected = all valid gaps) |
| A3.3 Zahlbeziehungen | drag_partition (equal boxes, double n≤5 → 2n) | sequence_gap (doubling seq 2,4,8; and 3,6,12) | equation_solve (result, a=b, ≤20) |

### Domain B — Stellenwertverständnis (6)
| Skill | L1 | L2 | L3 |
|---|---|---|---|
| B1.1 Zehner/Einer erkennen | bundle_sticks (12–39) | stellenwerttafel_read (11–99, mode read) | equation_gap (place_value, tens 1–9, ones 1–9) |
| B1.2 Bündelung zu Zehnern | bundle_sticks (12–39, bundle required) | stellenwerttafel_read (11–99, mode read) | equation_gap (place_value) |
| B1.3 Entbündelung | custom unbundling (open bundle → Z/E recount) | stellenwerttafel_read (1 Zehner 13 Einer → 23) | equation_gap (place_value, ones ≥10) |
| B2.1 Standardform/Stellenwerttafel | place_counters (stellenwerttafel, action fill, 11–99) | stellenwerttafel_read (11–99) | equation_gap (place_value) |
| B2.2 Zahlen am Zahlenstrahl | numberline_step (0–20, loc + step) | numberline_locate (ZR20) | numberline_locate (ZR100) |
| B2.3 Nicht-standardisierte Form | place_counters (stellenwerttafel, ones ≥10: "2 Z 14 E") | stellenwerttafel_read (non-standard count → value) | equation_gap (place_value, ones 10–19) |

### Domain C — Rechenstrategien (12)
| Skill | L1 | L2 | L3 |
|---|---|---|---|
| C1.1a Kleine Plus ZR20 | place_counters (zehnerfeld, fill a+b) | zehnerfeld_read (two_groups, no overstep) | equation_solve (result, no overstep) |
| C1.1b Kleine Minus ZR20 | place_counters (zehnerfeld, take_away) | zehnerfeld_read (two_groups with shaded part → diff) | equation_solve (result, minus, ZR20) |
| C1.2 Verdoppeln | drag_partition (equal boxes, 2×n ≤20) | zehnerfeld_read (two_groups equal → double) | equation_solve (result, a=b ≤20) |
| C1.3 Halbieren | drag_partition (split equal, total 2n ≤20) | zehnerfeld_read (two_groups equal → one part) | equation_gap (half, even ≤20) |
| C2.1 Teilschritt-Verfahren | drag_partition (total 11–19, 2 boxes split-to-ten) | equation_gap (helper: 8+7 = 10+_) | equation_solve (result, overstep ZR20) |
| C2.2 Doppeln als Stützpunkt | drag_partition (equal boxes, 6+7 via 6+6) | zehnerfeld_read (two_groups near-equal) | equation_gap (helper_double: 6+7 = 12+_) |
| C2.3 Ergänzen statt Abziehen | place_counters (zehnerfeld, fill-up from 7 to 12) | equation_gap (missing addend: 7+_=12) | equation_solve (unknown addend) |
| C3.1a Stellenweises Plus | place_counters (stellenwerttafel, add Z+Z then E+E) | stellenwerttafel_read (mode sum_rows) | equation_solve (place_value mode, ZR100 no overstep) |
| C3.1b Stellenweises Minus | place_counters (stellenwerttafel, subtract Z then E) | stellenwerttafel_read (mode sum_rows, minus) | equation_solve (place_value mode, minus, ZR100) |
| C3.2 Schrittweises Rechnen | numberline_step (35→40→45 via jumps) | equation_gap (helper: 45−7 = 45−5−2 = 40−_ ) | equation_solve (result, ZR100 overstep) |
| C3.3 Hilfsaufgaben | drag_partition (7+8 via 7+7+1) | equation_gap (helper_double, overstep) | equation_solve (result, overstep) |
| C3.4a/b Zerlegung ZR100 | drag_partition (35+27 → 35+20+7, 3 boxes) | equation_gap (helper, ZR100) | equation_solve (result, ZR100) |
| C4.1 Strategieauswahl | strategy_choice (double/near-double, ZR20) | strategy_choice (ZR100) | strategy_choice (mixed) |
| C4.2 Inverse +/− | drag_partition (total → fact family 3+4=7,7−4=3) | equation_gap (family: given 3+4=7 → 7−4=_) | equation_solve (unknown addend/subtrahend via inverse) |

### Domain D — Sachsituationen (2)
| Skill | L1 | L2 | L3 |
|---|---|---|---|
| D1.1 Mathematisierung | word_problem (+ small, ZR10, concrete objects) | word_problem (−, ZR20, everyday setting) | word_problem (ZR100, single-step) |
| D1.2 Rechenoperation erkennen | word_problem (ask_operation, ZR10) | word_problem (ask_operation, ZR20) | word_problem (ask_operation, ZR100) |

36 skills total (A1.1a/b, A1.2a/b, A1.3–A1.5, A2.1–A2.3, A3.1–A3.3, B1.1–B1.3, B2.1–B2.3, C1.1a/b, C1.2, C1.3, C2.1–C2.3, C3.1a/b, C3.2, C3.3, C3.4a/b, C4.1, C4.2, D1.1, D1.2).

## 5. Slow bands (starting values; ADR 0009 governs, teacher-tunable)

- Level 1 (enaktiv, manipulative drag/tap): 9000 ms
- Level 2 (ikonisch, reading structured pictures): 7000 ms
- Level 3 (symbolisch, mental computation): 6000 ms
Recorded in every spec; flagged slow when a problem's `response_ms` exceeds the band.

## 6. Error taxonomy (common codes; each spec adds its own specific rules)

`miscount` (verzählt) · `incomplete` (unvollständig) · `place_error` (Stellenwert vertauscht) · `overstep_error` (Zehnerübergang) · `strategy_miss` (andere Strategie) · `sign_error` (Vorzeichen) · `other` (default, encouraging "Schau noch mal genau hin."). Specs MUST add at least one construct-specific code+label+hint (e.g. A1.5: `tens_boundary` "An der Zehnergrenze".

## 7. Tasks

**Task 1 — Spec harness + Domain A (12 specs).** Author A-skill JSONs per mapping; validate; provenance rows.
**Task 2 — Domain B (6 specs).** Same.
**Task 3 — Domain C (12 specs).** Same.
**Task 4 — Domain D (2 specs) + full-pass cleanup.** All 36 validate (`scripts/check_specs.py`), provenance green, mirror sync script run, `flutter test test/skill_spec_store_test.dart` (P2 Task 2 gate) green if available.
**Task 5 — Independent math/pedagogy critic (fresh context).** Reviews the actual spec JSONs against the §2 gates + the construct map; returns findings; fix loop until clean.

## 8. Verification gates
- `python scripts/check_specs.py` → OK, exit 0.
- `python scripts/check_provenance.py` → OK, exit 0.
- Math-reviewer sign-off per domain in the evidence log (GAUNTLET_PROGRESS.md).
