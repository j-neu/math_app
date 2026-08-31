# P3 Domain D — Skill Specs Report (D1.1, D1.2)

**Date:** 2026-08-31
**Author:** Claude (domain author)
**Scope:** Domain D, skills D1.1 and D1.2 (2 specs)

## Status

DONE — both specs written, validated, and self-checked.

## Count

2 spec files + 1 provenance CSV (2 rows):

- `docs/clean-room/skills/specs/D1.1.json`
- `docs/clean-room/skills/specs/D1.2.json`
- `docs/clean-room/skills/specs/_provenance_specs_new.csv`

## One-line summary

D1.1 (Sachsituationen mathematisch erfassen) and D1.2 (passende Rechenoperation erkennen) ship as pure `word_problem` specs — D1.1 with `ask_operation: false` on all levels, D1.2 with `ask_operation: true` on all levels — over ZR 10 / 20 / 100, slow bands 9000/7000/6000 ms, mastery 8-of-8, everyday German contexts with unique non-negative answers.

## Self-check

### Mechanical gates (run via `validate_d_specs.py`, temp copy)

- Both JSON files parse; no comments, no trailing commas.
- Top-level keys exactly the P2 schema §4 set: `spec_version, skill_id, construct_id, domain, title_de, level_titles_de, levels, mastery, error_taxonomy, provenance`.
- Level keys exactly: `level, representation, template, custom_widget, params, problem_count, prompt_de, slow_band_ms`.
- `representation: "symbolisch"`, `template: "word_problem"`, `custom_widget: null` on all 6 levels (word_problem is in the symbolisch template category, P2 §5).
- `params` keys exactly `{contexts, op, zr, ask_operation}` (P3 §4.5 vocabulary); every level has 6 context entries (≥ 4 required).
- zr: D1.1 → 10/20/100, D1.2 → 10/20/100; op + / − / + per level (D1.1), + / − / + (D1.2, ask_operation).
- Slow bands 9000/7000/6000; `mastery.correct_of = 8`; `problem_count = 8`.
- Error taxonomy: 5 rules per spec (within 3–6); rule keys `{code, label_de, hint_de}`; each spec includes the common codes (`miscount`, `incomplete`, `other`) plus construct-specific rules — D1.2 carries `sign_error` ("Plus und Minus verwechselt") as required; D1.1 adds `number_from_story` (Zahlen aus der Geschichte verwechselt).
- Provenance block keys exactly `{sources, author, reviewed_by}`; sources cite `03-bibliography.md` entries (KMK 2022 = B1, Rahmenlehrplan BE/BB 2023 = B2, Padberg & Benz 2021 = A1).
- CSV parses; header exactly `skill_id,type,created_by,date,sources,reviewed_by,notes`; `created_by = "Claude (domain author)"`, `reviewed_by = "open"`; `docs/clean-room/provenance.csv` untouched.

### Example word problems (hand-combined context + numbers, one per level)

Level 1 — D1.1 (op +, ZR10), context `auf dem Markt / Äpfel`, numbers 3 + 2:
> Auf dem Markt liegen 3 Äpfel. Dazu kommen 2 Äpfel. Wie viele Äpfel sind es zusammen?
> **Answer: 5** (unique, non-negative, ≤ 10)

Level 2 — D1.1 (op −, ZR20), context `auf dem Schulhof / Kinder`, numbers 16 − 7:
> Auf dem Schulhof sind 16 Kinder. 7 Kinder gehen nach Hause. Wie viele Kinder bleiben auf dem Schulhof?
> **Answer: 9** (unique, non-negative, ≤ 20)

Level 3 — D1.2 (ask_operation, ZR100), context `im Supermarkt / Flaschen`, story 60 − 25:
> Im Supermarkt stehen 60 Flaschen. 25 Flaschen werden verkauft. Wie viele Flaschen bleiben übrig?
> **Operation: −, Answer: 35** (the story supports only the minus reading; unique and non-negative)

All 18 context entries were grammar-checked in the frame "In/auf … gibt es N Objekte" (plus) and "… N … werden weggenommen/gehen weg" (minus); setting phrases carry their article (`im`, `auf dem`, `in der`, `am`), objects are countable plural nouns — no zero-count, no "borrow" language, no negative results possible under the ZR-bound generators.

## Concerns

1. **D1.2 op is a single value per level** while `ask_operation: true` conceptually wants a mix of + and − stories. The P2 generator is responsible for varying the operation across problems (its word_problem tests require non-negative, age-plausible stories); the spec's `op` value serves as the generation default. If the P2 generator instead fixes `op` per level, D1.2 L1/L3 would collapse to "always +" — flag for the P2 generator author to confirm that `ask_operation: true` re-rolls the operation per problem.
2. **Level prompts are task instructions only** ("Lies die Geschichte …"), as the sentence itself is generated from `contexts`; the generator owns German sentence construction and must choose grammatical frames (e.g. "gibt es" avoids verb-agreement pitfalls for objects like Vögel or Blumen).
3. **Provenance split:** per the P3 plan, provenance also lands in `provenance.csv`; the instruction here restricts writes to the new `_provenance_specs_new.csv`, which is where the rows live now. The existing `provenance.csv` was not modified.
