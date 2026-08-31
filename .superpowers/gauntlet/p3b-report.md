# P3B — Domain B Skill Specs (B1.1–B2.3) — Report

**Date:** 2026-08-31
**Author:** Claude (domain author)
**Status:** ✅ Complete — 6 specs authored, validated, provenance appended. Not committed.

## Deliverables

Files written to `docs/clean-room/skills/specs/`:

- `B1.1.json` — Zehner und Einer erkennen
- `B1.2.json` — Einzelstücke zu Zehnern bündeln
- `B1.3.json` — Einen Zehner in Einer tauschen
- `B2.1.json` — Zahlen in der Stellenwerttafel darstellen
- `B2.2.json` — Zahlen am Zahlenstrahl verorten
- `B2.3.json` — Zahlen in ungewohnter Schreibweise lesen

Provenance appended (8 data rows now) to `docs/clean-room/skills/specs/_provenance_specs_new.csv`; header exactly `skill_id,type,created_by,date,sources,reviewed_by,notes`. `docs/clean-room/provenance.csv` NOT touched.

## Per-skill template triples

| Skill | L1 (enaktiv) | L2 (ikonisch) | L3 (symbolisch) |
|---|---|---|---|
| B1.1 | bundle_sticks, count_range [12,39] | stellenwerttafel_read, mode read, ZE, [11,99] | equation_gap, form place_value, tens [1,9], ones [1,9] |
| B1.2 | bundle_sticks, count_range [12,39] | stellenwerttafel_read, mode read, ZE, [11,99] | equation_gap, form place_value, tens [1,9], ones [1,9] |
| B1.3 | custom_widget `unbundling`, number_range [12,39] | stellenwerttafel_read, mode sum_rows, two_rows (1 Zehner 13 Einer → 23) | equation_gap, place_value, tens [1,8], ones [10,18] |
| B2.1 | place_counters, stellenwerttafel, fill, [11,99] | stellenwerttafel_read, mode read, ZE, [11,99] | equation_gap, place_value, tens [1,9], ones [1,9] |
| B2.2 | numberline_step, 0–20, start 10–12, step 1, up, target 20 | numberline_locate, range [0,20], value [1,19] | numberline_locate, range [0,100], value [1,99] |
| B2.3 | place_counters, stellenwerttafel, fill, [20,99] (ones ≥10) | stellenwerttafel_read, mode sum_rows, two_rows (2 Z 14 E → 34) | equation_gap, place_value, tens [1,8], ones [10,19] |

## Deviations / interpretations from P3 §4 mapping

1. **B1.3 L2 & B2.3 L2 (`1 Zehner 13 Einer → 23`, `non-standard count → value`):** encoded as `stellenwerttafel_read` `mode:"sum_rows"`, `columns:["Z","E"]`, `rows:"two_rows"` (two stacked counter rows) instead of `mode:"read"`. A single read column cannot render >9 counters in one cell; sum_rows/two_rows is the §4.5-supported representation of stacked Z/E rows. The mode-read gate (`number_range` within [11,99], columns ZE) therefore applies to B1.1/B1.2/B2.1 L2 only.
2. **B2.3 L1:** `place_counters` `count_range:[20,99]` encodes the target number; the unique non-standard decomposition `z = n div 10 − 1, o = 10 + n mod 10` keeps ones in [10,19] for every n in range (verified exhaustively). Documented in the provenance notes.
3. **B2.2 has no symbolic level** (L2 and L3 both ikonisch numberline_locate) — exactly per the mapping row; the hard rule on the `representation` field is satisfied (it records the actual category, not the ordinal slot).
4. **B1.1 vs B1.2 L1** are both `bundle_sticks [12,39]` per the mapping; differentiated by prompt emphasis (recognizing vs. bundling). Bundling is forced by the template correctness rule (count ≥ 10 ⇒ bundles ≥ 1).
5. **`equation_gap`** uses the `form` key (authoritative §4.5 name for the P3 §3 `prompt_kind` extension).

## Self-check result

- ✅ 6/6 JSON parse (`json.load`), valid JSON, no comments/trailing commas.
- ✅ Schema keys match P2 plan §4 exactly (spec_version, skill_id, construct_id, domain, title_de, level_titles_de, levels[level/representation/template/custom_widget/params/problem_count/prompt_de/slow_band_ms], mastery.correct_of, error_taxonomy[code/label_de/hint_de], provenance).
- ✅ `representation` equals the ACTUAL template category for all 18 levels (enaktiv/ikonisch/symbolisch; custom unbundling = enaktiv).
- ✅ Slow bands 9000/7000/6000 ms; mastery.correct_of = 8; problem_count = 8.
- ✅ Hard math gates verified programmatically: B1.2 bundle_sticks min ≥ 12; B1.3 unbundling ones ≥ 10; B2.3 ones ∈ [10,19]; numberline_locate never an endpoint; stellenwerttafel_read mode-read number_range ∈ [11,99] with columns Z,E; place-value forms arithmetically true (4Z3E=43, 1Z13E=23, 2Z14E=34 reachable); no negative expression anywhere.
- ✅ German prompts imperative/friendly, no English, no product names; Stellenwert vocabulary correct (Zehner, Einer, Stellenwerttafel, Bündel, entbündeln-context wording).
- ✅ Error taxonomy: 4–5 rules per spec, common codes (miscount/incomplete/place_error/other) + at least one construct-specific code each (bundling_error ×2, unbundling_error, zero_ones_error, mislocate/distance_error, digit_string_error).
- ✅ Provenance CSV: exact header, 8 data rows (D1.1, D1.2, B1.1–B2.3), field order preserved; main provenance.csv untouched.

## Concerns

- `check_specs.py` does not exist in `scripts/` yet (a P2 Task 2 deliverable), so mechanical validation against it was not possible; validation here is script-based against the P2 §4 schema and P3 §4.5 vocabulary.
- The sum_rows encoding for the two non-standard stellenwerttafel levels relies on generator-side ranges (tens 1–8, ones 10–18/10–19) that are documented in provenance notes rather than in the params vocabulary; `mode:sum_rows` itself signals the non-standard form.
