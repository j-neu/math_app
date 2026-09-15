# Practice Exercise Plan — one exercise per diagnosed skill

**Status:** Draft for review
**Scope:** All 93 skills in `math_app/Research/skills_taxonomy.csv` (v4 iMINT/PIKAS taxonomy, domains A–D)
**Author:** Claude Sonnet 5, with Jakob (2026-09-15)

## 1. Purpose

Every skill the diagnostic can flag needs at least one practice exercise the child can be routed
to from their Lernpfad. This document plans all 93, one entry per skill, using the 24 originally
hand-built exercises (`math_app/lib/exercises/`, catalogued in `exercise_service.dart`) as the
design archetype: a manipulative-based, scaffolded-levels game with a CRA (concrete → representational
→ abstract) internalization path, not a generic templated problem generator.

This is a **planning document**, not an implementation plan. It fixes: which old exercise (if any)
each skill descends from, what manipulative/representation it uses, how many levels it has and what
each level trains, and 1–2 concrete example problems per level. It does not fix exact random-number
generation formulas, reward hooks, or file layout — that is the next step (`writing-plans`) once this
is approved.

## 2. Why "one exercise per skill" instead of one per construct family

The taxonomy groups skills into 46 "construct" families (e.g. construct `double` spans 6 skills from
`double_zr10` to `double_2digit_with_carry`). Jakob chose one exercise per individual skill (93 total)
over one exercise per construct (46, with skills as internal levels) — each skill gets its own
dedicated exercise, so a construct family like `double` becomes 6 separate exercises that share a
manipulative and archetype but are separately assigned, unlocked and tracked on the Lernpfad. Within
each of those 93 exercises there are still internal difficulty levels (the CRA progression), matching
how the old exercises worked (e.g. `DoublingBoatExercise` had 3 internal scaffold levels for one skill).

## 3. Archetype status legend

Every entry below is tagged with how it relates to the original 24:

- **Reused** — a close 1:1 old exercise exists for this exact skill; keep its manipulative and level
  structure, adapt numbers/wording to the new skill's exact scope.
- **Extended** — an old exercise's manipulative and level structure is stretched to a new number range
  or a twist the old exercise didn't cover (e.g. the doubling-mirror pattern applied to 2-digit numbers).
- **New — widget exists** — no old *exercise* covers this skill, but a reusable visual widget already
  exists in the codebase (built later, for the diagnostic or the since-retired Gauntlet template
  engine) that can be wrapped in a new scaffolded exercise instead of drawing the manipulative from
  scratch.
- **New — from scratch** — no old exercise and no existing widget; design following the same
  conventions (CRA progression, `MinimalistExerciseScaffold`, `EXERCISE_DESIGN_SYSTEM.md`,
  `DIFFICULTY_CURVE.md`) as everything else here.

Coverage across the 93 skills: **30 Reused, 31 Extended, 11 New (widget exists), 21 New (from scratch)**
— so roughly two-thirds of the taxonomy (61 of 93 skills) has a direct or extended line back to
something you already built. Domain C (Rechenstrategien) carries almost all of the "from scratch"
load (14 of 21), concentrated in two places: the halving family, which has zero old archetype at all
(see below), and the newer combinatorial/reasoning skills (equation equivalence, commutativity,
even/odd, calculation triangle) that the old 24 never attempted. Domain D (word problems) is 3 skills,
all new content territory, but all three reuse one already-existing widget.

Doubling/halving and cross-decade-boundary arithmetic — flagged in `docs/clean-room/00-v1-assessment.md`
as a hole in the *diagnostic* — turn out to be exactly where the *old exercise set* was also thinnest;
halving in particular has zero old archetype anywhere (see §5, domain C).

## 4. Governance carried forward

All 93 entries assume the standing rules that already govern the old exercises and are back in force
per the v2 design doc §6 (`docs/superpowers/specs/2026-09-07-diagnostik-v2-design.md`):
`DIFFICULTY_CURVE.md` (trivial→easy→medium→hard→easy, 10 problems/level by default),
`EXERCISE_DESIGN_SYSTEM.md` (minimalist scaffold, segmented progress bar, collapsible instructions,
hamburger level menu), `COMPLETION_CRITERIA.md`, `REWARDS_SYSTEM.md`, `COMMON_PITFALLS.md` and
`adhd guidelines.md`. Not repeated per-entry below.

**The integration gap named in the v2 design doc is real and unchanged:** the old exercises are
single-device (`UserProfile`, local progress). The live platform is multi-tenant (student JWT via
`student-auth`, attempts synced through `practice-session`). An adapter layer between "old exercise
shell" and "new attempt-reporting backend" is still required and is not designed here — it's the
first task of the implementation plan, not a per-exercise concern.

## 5. The 93 exercises, by domain

### Domain A — Zahlbegriff (40 skills)

#### Counting quantities

**`quantify_count_zr10`** — Mengen zählen bis 10
*Archetype:* Reused — `C1.1 Count the Dots` (`count_dots_exercise_v2.dart`)
*Manipulative:* Loose dot/plättchen field, tap-to-count
*Levels:* 1) Structured field (dots in a row) → 2) Scattered field → 3) Mixed sizes, no structure
*Example:* Count 7 loosely scattered dots; count 9 dots arranged in two rows of 4+5.

**`quantify_count_zr20`** — Mengen zählen bis 20
*Archetype:* Extended — same as above, range raised to 20 with unstructured layouts only (the old
exercise's target was already 20; this just narrows the taxonomy split so ZR10 stays the "easy"
half and ZR20 is the harder, always-unstructured half)
*Manipulative:* Same dot field
*Levels:* 1) Two visibly separated groups (e.g. 8+9) → 2) Fully scattered 11–20
*Example:* Count 17 dots scattered with no visible grouping.

#### Sequencing forward/backward

**`count_forward_zr20`** — Vorwärts zählen im ZR20
*Archetype:* Reused — `C3.1 Count Forward to 20` (`count_forward_exercise.dart`)
*Manipulative:* Number strip / spoken-and-typed sequence
*Levels:* 1) Start at 1 → 2) Start at any number 1–15, count 5 more
*Example:* "Start at 8, count forward: 8, 9, 10, ...?"

**`count_forward_zr100`** — Vorwärts zählen im ZR100
*Archetype:* Reused — `C3.2`/`C3.3 Count Forward to 50/100` (same file family)
*Manipulative:* Same, extended range; decade-boundary starts emphasised
*Levels:* 1) Start mid-decade (e.g. 34) → 2) Start just before a decade boundary (e.g. 29, 49, 69)
*Example:* "Start at 68, count forward past the next ten."

**`count_backward_zr20`** — Rückwärts zählen im ZR20
*Archetype:* New — from scratch (no old *sequential* backward-counting exercise existed; `C6.3` only
covered backward **skip**-counting). Mirrors `C3.1`'s structure in reverse.
*Manipulative:* Same number strip, reverse direction
*Levels:* 1) Start at 20, count back to 10 → 2) Start at any number 5–20
*Example:* "Start at 14, count backward: 14, 13, ...?"

**`count_backward_zr100`** — Rückwärts zählen im ZR100
*Archetype:* New — from scratch, mirrors `count_backward_zr20` at ZR100 with decade-boundary starts
*Manipulative:* Same, extended range
*Levels:* 1) Start mid-decade → 2) Start just after a decade boundary (e.g. 71, 51)
*Example:* "Start at 72, count backward past 70."

#### Successor / predecessor

**`successor_zr20_decade`** — Nachfolger an der Zehnergrenze (ZR20)
*Archetype:* Reused — `C4.1 What Comes Next?` (`what_comes_next_exercise.dart`)
*Manipulative:* Single number card, child supplies the next one
*Levels:* 1) Away from a boundary → 2) Exactly at a decade boundary (after 10, after 19→20)
*Example:* "What comes after 10?" / "What comes after 19?"

**`predecessor_zr20_decade`** — Vorgänger an der Zehnergrenze (ZR20)
*Archetype:* Reused — same widget, predecessor direction
*Levels:* 1) Away from boundary → 2) Exactly at boundary (before 10, before 20)
*Example:* "What comes before 10?"

**`successor_zr100_mid`** — Nachfolger im ZR100 (Zahlmitte)
*Archetype:* Extended — same widget, ZR100 range, non-boundary numbers
*Levels:* 1) Ones-digit 1–7 (no carry) → 2) Ones-digit 8–9 (near-carry, e.g. after 56)
*Example:* "What comes after 56?"

**`predecessor_zr100_mid`** — Vorgänger im ZR100 (Zahlmitte)
*Archetype:* Extended — same, predecessor direction
*Example:* "What comes before 56?"

**`successor_zr100_five`** — Nachfolger im ZR100 (Fünferposition)
*Archetype:* Extended — same widget, numbers ending in 5
*Example:* "What comes after 65?"

**`predecessor_zr100_five`** — Vorgänger im ZR100 (Fünferposition)
*Archetype:* Extended — same
*Example:* "What comes before 65?"

**`successor_zr100_decade`** — Nachfolger an der Zehnergrenze (ZR100)
*Archetype:* Extended — same widget, decade-boundary numbers (hardest tier)
*Example:* "What comes after 80?"

**`predecessor_zr100_decade`** — Vorgänger an der Zehnergrenze (ZR100)
*Archetype:* Extended — same
*Example:* "What comes before 80?"

*(These 8 successor/predecessor skills share one manipulative and archetype; each still gets its own
exercise entry/id so the Lernpfad can assign and track them independently, per §2.)*

#### Skip-counting

**`skip2_forward_zr20`** / **`skip2_backward_zr20`** — Zweierschritte vor-/rückwärts (ZR20)
*Archetype:* Reused — `C6.1 Count in Steps of 2` (`count_steps2_exercise.dart`)
*Manipulative:* Number strip with step highlighting
*Levels:* 1) Forward from 0 → 2) Forward from an odd start → 3) (backward variant) same, reverse
*Example:* "2, 4, 6, ...?" / backward: "20, 18, 16, ...?"

**`skip2_forward_zr100`** / **`skip2_backward_zr100`** — Zweierschritte vor-/rückwärts (ZR100)
*Archetype:* Reused — `C6.2`/`C6.3 Count in Steps on 100-Field` (100-field, "2er-Schritte" levels
already built exactly this way: field-visible → mental)
*Manipulative:* Hundertertafel (100-field)
*Levels:* 1) On the field (visible) → 2) Mental (field hidden)
*Example:* "34, 36, 38, ...?" on the field, then without it.

**`skip5_forward_zr100`** / **`skip5_backward_zr100`** — Fünferschritte vor-/rückwärts (ZR100)
*Archetype:* Reused — same `C6.2`/`C6.3` file family, "5er-Schritte" levels already built
*Example:* "15, 20, 25, ...?"

**`skip10_forward_zr100`** / **`skip10_backward_zr100`** — Zehnerschritte vor-/rückwärts (ZR100)
*Archetype:* Reused — same family, "10er-Schritte" levels already built
*Example:* "30, 40, 50, ...?"

#### Ordering & placing numbers

**`order_cards_zr20`** — Zahlenkarten ordnen im ZR20
*Archetype:* Reused — `C2.1 Order Cards to 20` (`order_cards_exercise.dart`)
*Manipulative:* Draggable number cards
*Levels:* 1) 3 cards → 2) 5 cards, adjacent values → 3) 5 cards, spread out
*Example:* Order [14, 3, 9] smallest to largest.

**`order_cards_zr100`** — Zahlenkarten ordnen im ZR100
*Archetype:* Extended — same widget, ZR100 range
*Levels:* 1) Same-decade cards (41, 47, 44) → 2) Cross-decade cards (23, 68, 41)
*Example:* Order [72, 8, 65] smallest to largest.

**`place_on_numberline_zr20`** — Zahlen auf dem Zahlenstrahl verorten (ZR20)
*Archetype:* Reused — `C10.1 Place Numbers on Line (0-20)` (`place_numbers_exercise.dart`)
*Manipulative:* Zahlenstrahl (reuses `ZahlenstrahlPainter` from `manipulatives/zahlenstrahl.dart`,
currently used only in the diagnostic — wrap in a scaffolded exercise)
*Levels:* 1) 3 numbers placed → 2) 5 numbers placed
*Example:* Place 4, 11, 18 on a 0–20 line.

**`place_on_numberline_zr100`** — Zahlen auf dem Zahlenstrahl verorten (ZR100)
*Archetype:* Reused — `C10.2 Place Numbers on Line (0-100)`
*Levels:* 1) 3 numbers → 2) 5 numbers, closer together
*Example:* Place 23, 67, 89 on a 0–100 line.

#### Decomposition and completion

**`decompose_single_digit`** — Zerlegung einstelliger Zahlen (2-9)
*Archetype:* Reused — `Z1 Decompose 10` (`decompose_10_exercise.dart`), generalised from a fixed 10
to any single-digit target
*Manipulative:* Part-whole splitting tool (two-hand / two-bowl metaphor)
*Levels:* 1) Target 2–5 → 2) Target 6–9
*Example:* Split 7 into two parts.

**`complete_to_10`** — Ergänzen bis 10
*Archetype:* New — from scratch. `Z2 Make 10` was **planned in `exercise_service.dart` but never
actually built** (no `exerciseBuilder`, just a stub entry) — there is no code to reuse, only intent.
Build following `Z1`'s decomposition-tool pattern in reverse (given one part, find the missing part).
*Manipulative:* Same part-whole tool as `Z1`, used as completion instead of splitting
*Levels:* 1) Given part 5–8 → 2) Given part 1–4 (larger gap)
*Example:* "6 and how many more make 10?"

**`complete_to_20`** — Ergänzen bis 20
*Archetype:* Extended — same tool as `complete_to_10`, target 20
*Example:* "14 and how many more make 20?"

**`complete_to_100`** — Ergänzen bis 100
*Archetype:* Extended — same tool, decade targets
*Levels:* 1) Complete to the next ten (e.g. 34→40) → 2) Complete to 100 directly
*Example:* "76 and how many more make 100?"

#### Subitizing / structured seeing

**`structured_quantity_recognition_zr10`** — Strukturiertes Sehen bis 10
*Archetype:* New — widget exists. No old exercise trained *flash* subitizing directly (`C1.1` was
tap-and-count, the opposite skill), but `S1.1 Fingerblitz`'s "See (Flash)" level is the right
archetype mechanic, applied here to a dot field instead of fingers. Reuses
`interactive_twenty_frame_widget.dart` (structured ten-frame layout) as the visual.
*Levels:* 1) Flash a ten-frame pattern (untimed) → 2) Flash briefly, child states the count instantly
*Example:* Flash a ten-frame showing 7 (two rows of 5, two empty) for 1.5s; child answers without counting.

**`structured_quantity_recognition_zr20`** — Strukturiertes Sehen bis 20
*Archetype:* Extended — same mechanic, two ten-frames
*Example:* Flash two ten-frames (full + 6) briefly; child answers 16.

**`quick_recognition_rechenschiffchen_zr20`** — Schnelles Sehen am Rechenschiffchen (ZR20)
*Archetype:* Extended — reuses the Rechenschiffchen manipulative from `S3.4 Doubling Boat`
(`rechenschiffchen_widget.dart`), but as a flash-recognition task, not a doubling task
*Levels:* 1) Boat visible, untimed → 2) Flash briefly (5/10-structure only, no counting time)
*Example:* Flash a boat with 13 counters (two full rows of 5 + 3); child reads it via the structure.

**`dot_field_full`** / **`dot_field_small`** / **`dot_field_large`** / **`dot_field_near_max`** —
Hunderterpunktefeld: full / ~12 / ~85 / ~99
*Archetype:* New — widget exists. No old exercise used the 100-dot-field for estimation (`C6.0`
used the numbered 100-*chart* for sequences, a different artifact), but the field itself is cheap to
build as a static/interactive grid reusing the same row/column logic as `hundred_chart_widget.dart`.
One exercise family, 4 skills as its levels by design (full → near-max is a genuine progression):
*Levels:* 1) Full field (recognize as 100 instantly) → 2) Small quantity ~12 (count via tens-structure)
→ 3) Large quantity ~85 (read via tens-structure) → 4) Near-max ~99 (reason about the missing dots)
*Example:* A field with 88 dots filled, 12 empty; child determines the count by reasoning about the gap.

#### Ordinal numbers, representation

**`ordinal_1`** — Ordnungszahlen verwenden
*Archetype:* New — from scratch, no old archetype
*Manipulative:* A row of distinct objects (animals in a race, children in a line)
*Levels:* 1) Identify "the Nth" object → 2) State the ordinal position of a marked object
*Example:* "Which one is the third from the left?" / "The dog is in which position?"

**`representation_bild_symbol`** — Bild und Symbol verknüpfen
*Archetype:* New — from scratch
*Manipulative:* Matching game, picture card ↔ numeral card
*Levels:* 1) Match a picture of N objects to the numeral N → 2) Match with distractor numerals nearby (7 vs 17)
*Example:* Match a picture of 8 apples to the numeral "8" among ["8", "3", "18"].

**`representation_bild_symbol_wort`** — Bild, Symbol und Wort flexibel verknüpfen
*Archetype:* Extended — same matching game, three-way (picture ↔ numeral ↔ spoken/written word),
specifically targeting the confusable German number-word triples (sechs/sechzehn/sechzig)
*Levels:* 1) Picture↔numeral↔word, non-confusable numbers → 2) Confusable triples (6/16/60, 7/17/70, etc.)
*Example:* Hear "sechzehn" spoken; choose between pictures of 6, 16 and 60 objects.

---

### Domain B — Stellenwertverständnis (8 skills)

**`bundling_recognition_zr100`** — Bündelungserkennung im ZR100
*Archetype:* New — widget exists. `dienes_place_value.dart` (tens-rods + ones-units display) already
exists, built for the diagnostic. No old *exercise* trained this, but `S3.6 Zehner verdoppeln`'s
"Mirror/Material → Manual Placing → Mental" progression is the right archetype shape, applied to
reading Dienes displays instead of doubling them.
*Manipulative:* Dienes place-value display (rods + units)
*Levels:* 1) Count rods and units, state the number (material visible) → 2) State the number from a
briefly-shown display (mental)
*Example:* 4 rods + 7 units shown → child answers 47.

**`bundling_recognition_overflow_zr100`** — Bündelung erkennen bei mehr als 10 Einern
*Archetype:* Extended — same Dienes display, deliberately shown with 10+ loose units (needing a
further bundling step)
*Levels:* 1) 11–15 loose units, child recognizes one more ten is hiding → 2) recognizes it without a hint
*Example:* 2 rods + 13 units shown → child determines this is actually 33 (3 rods + 3 units).

**`number_word_dictation_zr100`** — Zahlen hören und schreiben (ZR100)
*Archetype:* New — from scratch. No old exercise did dictation (writing a heard number). Straightforward
audio-prompt + numeral-entry pad, following the same "hear it, answer it" shape as the diagnostic's
existing audio items.
*Manipulative:* None beyond a number-entry pad; audio prompt (reuses the diagnostic's TTS pipeline)
*Levels:* 1) Round/simple numbers (e.g. 30, 45) → 2) Numbers with tricky number-word order (e.g. "einundzwanzig")
*Example:* Audio says "vierundsiebzig"; child types 74.

**`hundred_chart_navigation`** — Hundertertafel: Struktur nutzen
*Archetype:* New — widget exists. `hundred_chart_widget.dart` already supports a single-blank mode
(find the missing cell). Extends the archetype family from `C6.0`'s 100-field sequence exercise.
*Manipulative:* Hundertertafel, single blank cell
*Levels:* 1) Blank has visible neighbours on 3 sides → 2) Blank at an edge (only 1–2 neighbours visible)
*Example:* Find the missing number between 43, [?], 45, with 33 and 53 visible above/below.

**`hundred_chart_structure_zr100`** — Hundertertafel: Struktur nutzen (oben/unten/links/rechts)
*Archetype:* Extended — same widget, sparser labeling (fewer visible anchor numbers), explicitly
training the ±1 row / ±10 column rule rather than just reading neighbours
*Levels:* 1) One anchor number + direction given ("2 rows down from 34") → 2) Two-step navigation
("3 right, then 1 down from 56")
*Example:* "Start at 34. What number is 2 rows down and 1 column left?"

**`number_line_rechenstrich`** — Rechenstrich zum Rechnen nutzen
*Archetype:* New — widget exists. `number_line_endpoints_widget.dart` exists (labels only the
endpoints, for diagnostic "what's between" items) but this skill is different: an *empty* number
line used as a jump-strategy calculation tool, not a read-a-position task. New exercise design,
reusing the same line-drawing primitive.
*Manipulative:* Empty number line, child draws/taps jumps
*Levels:* 1) Single jump to the next ten (e.g. 47+3) → 2) Two jumps (ten then ones, e.g. 47+15)
*Example:* Solve 38+25 by jumping +2 (to 40), then +23, on an empty line.

**`number_line_zahlenstrahl`** — Zahlenstrahl zur Positionierung nutzen (Mitte finden)
*Archetype:* Extended — reuses `number_line_endpoints_widget.dart` directly (already built exactly
for "find the value at the marked midpoint" diagnostic items); wrap in a scaffolded exercise
*Levels:* 1) Midpoint of two multiples of 10 (e.g. between 40 and 60) → 2) Midpoint of arbitrary numbers
*Example:* Endpoints 40 and 80 shown, midpoint arrow marked; child answers 60.

**`number_line_strategies`** — Zahlenstrahl-Strategien: Zahl über Ungleichungen eingrenzen
*Archetype:* New — from scratch (inequality narrowing is a distinct interaction, closer to a
number-guessing game than a placement task)
*Manipulative:* Number line with a shrinking highlighted range
*Levels:* 1) One inequality narrows the range (e.g. "more than 50") → 2) Two inequalities narrow it
to a single number (e.g. "more than 50, less than 55, even")
*Example:* "The number is more than 60 and less than 70. It's the number right after 65+1." → 66.

---

### Domain C — Rechenstrategien (42 skills)

#### Comparison and the power of 5

**`compare_quantity_difference`** — Mengenunterschied vergleichen
*Archetype:* Reused — `S1.4 More or Less (Hamstern)` (`more_less_exercise.dart`)
*Manipulative:* Dice-roll comparison game ("Hamstern")
*Levels:* One level (matches the old exercise, which was intentionally single-level — 10 rounds)
*Example:* Roll two quantities (5 and 8); child states the difference (3) and which is more.

**`basic_fact_add_with_5`** / **`basic_fact_sub_with_5`** — Kraft der 5: Addition / Subtraktion
*Archetype:* Extended — `S1.1 Fingerblitz`'s "Make (5+n)" level, generalised from finger patterns to
abstract facts
*Manipulative:* Finger-pattern display fading to bare number facts
*Levels:* 1) Fingers shown (5+n visible) → 2) Fingers hidden, abstract fact only
*Example:* "5+3 = ?" shown with fingers, then as a bare equation.

**`fingerblitz_quantity_zr10`** — Fingerblitz: Mengen an Fingern erkennen
*Archetype:* Reused — `S1.1 Fingerblitz`, "See (No limit) → See (Flash)" levels directly
*Manipulative:* Finger-pattern flash display
*Levels:* 1) Untimed → 2) Flashed briefly
*Example:* Flash a finger pattern showing 7; child answers instantly.

**`derive_via_5_add`** / **`derive_via_5_sub`** — Ableiten über die Kraft der 5
*Archetype:* Extended — same Fingerblitz "Kraft der 5" mechanic, framed as deriving a *different*,
unknown fact from a known 5-fact
*Levels:* 1) Known fact shown alongside the target → 2) Target only, known fact recalled from memory
*Example:* "You know 5+4=9. So what's 5+3?"

**`derive_via_10_add_minus1`** / **`derive_via_10_add_plus1`** / **`derive_via_10_sub`** —
Ableiten über die Kraft der 10
*Archetype:* Reused — `S1.1 Fingerblitz`'s "Make (10-n)" level directly covers this family
*Manipulative:* Ten-frame / finger pattern anchored to 10
*Levels:* 1) 10-1 pattern (e.g. 6+9 via 6+10-1) → 2) 10+1 pattern (e.g. 7+11 via 7+10+1) → 3)
subtraction via 10 (e.g. 15-8 via 15-10+2)
*Example:* "9+6: think 6+10, then take away 1."

#### Doubling (constructs `double`)

**`double_zr10`** — Verdoppeln im ZR10
*Archetype:* Reused — `S3.1 Doubling with Mirror (ZR10)` (`doubling_mirror_exercise.dart`, min 1–5)
*Manipulative:* Mirror tool (place N counters, mirror shows the double)
*Levels:* 1) Manual placing → 2) Mirror tool → 3) Mental doubling (matches the old exercise's 3 scaffold levels)
*Example:* Double 4 using the mirror, then mentally.

**`double_zr10_to_zr20`** — Verdoppeln ZR10 nach ZR20 (ohne Übergang)
*Archetype:* Reused — `S3.2 Doubling with Mirror (ZR20)` (same file, min 6–10)
*Levels:* Same 3-level progression, inputs 6–10
*Example:* Double 8 (→16) using the mirror, then mentally.

**`double_crossing_10`** — Verdoppeln mit Zehnerübergang
*Archetype:* Reused — `S3.4 Doubling on Calculation Boat` (`doubling_boat_exercise.dart`), whose
5/10-structure is exactly the tool for seeing a ten-crossing double
*Manipulative:* Rechenschiffchen (calculation boat)
*Levels:* 1) Action (place counters) → 2) Partial view (cover) → 3) Mental (empty boat) — matches
the old exercise's existing 3 levels
*Example:* Double 7 on the boat (two rows of 5, sees 5+5 then +2+2).

**`double_decade`** — Verdoppeln von Zehnerzahlen
*Archetype:* Reused — `S3.6 Zehner verdoppeln` (`doubling_tens_exercise.dart`)
*Manipulative:* Ten-rod material (Dienes), or mirror tool scaled to tens
*Levels:* 1) Mirror/material → 2) Manual placing → 3) Mental (matches old exercise's 3 levels)
*Example:* Double 30 using ten-rods, then mentally.

**`double_2digit_nocarry`** — Verdoppeln zweistelliger Zahlen (ohne Übertrag)
*Archetype:* Extended — combines `S3.6`'s tens-material approach with `S3.4`'s boat/structure idea,
scaled to full 2-digit numbers where no carry is needed
*Manipulative:* Dienes place-value display (rods + units), doubled digit-wise
*Levels:* 1) Material visible, double tens and ones separately → 2) Mental
*Example:* Double 42 (4 rods→8 rods, 2 units→4 units) → 84.

**`double_2digit_with_carry`** — Verdoppeln zweistelliger Zahlen (mit Übertrag)
*Archetype:* Extended — same as above, deliberately choosing numbers where the ones-double exceeds 10
*Levels:* 1) Material visible, sees the ones-overflow become a new ten → 2) Mental
*Example:* Double 35 (3 rods→6 rods, 5 units→10 units→1 more rod) → 70.

#### Halving (construct `halve`) — the archetype gap

**`halve_zr10`** through **`halve_2digit_needs_decomposition`** (6 skills: `halve_zr10`,
`halve_zr20_anchor`, `halve_zr20_crossing`, `halve_decade`, `halve_2digit_clean`,
`halve_2digit_needs_decomposition`)
*Archetype:* **New — from scratch, for all 6.** This is the one construct family with genuinely zero
old archetype: none of the 24 original exercises taught halving at all (the pre-existing v1
diagnostic assessment flagged this exact gap — "Verdoppeln/Halbieren fehlt im ZR20... und im ZR100").
Design mirrors the `double` family's manipulatives exactly, run in reverse (splitting instead of
combining), so building these six reuses the same widgets as doubling:
*Manipulative:* Mirror tool (split, not combine) for ZR10/20; Rechenschiffchen for the ZR20-crossing
case; Dienes place-value display for decade and 2-digit cases
*Per-skill levels (all 2–3 level CRA progressions, material → mental):*
- `halve_zr10`: split 2–10 counters evenly using the mirror tool.
- `halve_zr20_anchor`: split 12–20 via "half of 10, plus half the rest" (anchor at 10).
- `halve_zr20_crossing`: split numbers like 14 on the Rechenschiffchen, where a bundle must be broken (14→7 needs splitting one 5-group).
- `halve_decade`: split ten-rods evenly (e.g. 40→20).
- `halve_2digit_clean`: split rods and units separately, no remainder crossing (64→32).
- `halve_2digit_needs_decomposition`: split where a rod must be broken into units first (70→35, 58→29).
*Example (halve_2digit_needs_decomposition):* 58 = 5 rods + 8 units → break one rod into 10 units (4
rods + 18 units) → split into 2 groups of (2 rods + 9 units) → 29.

#### Tens arithmetic and analogy

**`tens_add_tens`** / **`tens_sub_tens`** / **`tens_sub_crossing_hundred`** — Zehnerzahl plus/minus Zehnerzahl
*Archetype:* Reused — `S3.7 Rechnen mit Zehnern` (`tens_calculation_exercise.dart`), whose 4 levels
(Visual Add → Visual Sub → Symbolic +→ Symbolic −) already cover exactly this split
*Manipulative:* Ten-rod material, then symbolic
*Levels:* 1) Visual (rods) → 2) Symbolic; `tens_sub_crossing_hundred` adds a third level for the
100-crossing case specifically (e.g. 100−20)
*Example:* 50+30 with rods, then 100−20 symbolically.

**`decade_analogy_add`** / **`decade_analogy_add_crossing_hundred`** — Zehner-Analogie: Addition
*Archetype:* Extended — `S3.7`'s "analogy to ones" framing, applied to transferring a known ZR10 fact
to ZR20/ZR100 explicitly (e.g. 3+4=7 → 30+40=70)
*Levels:* 1) Known ZR10 fact shown beside the target → 2) Target only, crossing toward 100
*Example:* "You know 3+4=7. So what's 60+40?" (crosses to 100).

**`derive_via_near_double_add`** / **`derive_via_near_double_sub`** — Ableiten über Nachbarverdopplung
*Archetype:* Extended — builds on the `double` family's mastery as the "anchor fact" (e.g. know
double 6=12, derive 6+7)
*Levels:* 1) Anchor double shown alongside the target → 2) Target only
*Example:* "You know 6+6=12. So what's 6+7?"

**`cross_decade_add_zr100_1digit`** / **`cross_decade_sub_zr100_1digit`** /
**`cross_decade_add_zr100_2digit`** / **`cross_decade_sub_zr100_2digit`** —
Zehnerübergang ZR100 (1- and 2-digit operand)
*Archetype:* New — from scratch. No old exercise combined ten-crossing with 2-digit operands; builds
on the `number_line_rechenstrich` jump-strategy exercise (domain B) as its manipulative rather than
inventing a new one.
*Manipulative:* Empty number line (rechenstrich), jump-strategy
*Levels:* 1) 1-digit second operand (e.g. 27+8) → 2) both operands 2-digit (e.g. 55+38)
*Example:* 27+8: jump +3 to 30, then +5, on the empty line.

#### Compensation, shifting, equivalence

**`shift_plus_minus_1_2_zr10`** — Um 1 oder 2 mehr/weniger
*Archetype:* Extended — `C4.1 What Comes Next?`'s successor/predecessor mechanic, extended to ±2 and
framed as a calculation ("what's 2 more") rather than a bare sequence question
*Levels:* 1) ±1 → 2) ±2
*Example:* "What's 2 less than 8?"

**`compensation_strategy_zr20`** — Gegensinniges Verändern
*Archetype:* Reused — `S2.3 Opposite Change` (`opposite_change_exercise.dart`)
*Manipulative:* Two-pile counters, simultaneous +1/−1 manipulation
*Levels:* 1) Covered manipulation → 2) Mental manipulation → 3) Numerical compensation (matches old exercise)
*Example:* 8+5 → move 2 from the 5-pile to the 8-pile → 10+3=13.

**`even_odd_recognition`** — Gerade und ungerade Zahlen
*Archetype:* New — from scratch
*Manipulative:* Pair-up visual (objects grouped into pairs, one leftover if odd)
*Levels:* 1) Objects visibly paired → 2) Numeral only, no objects
*Example:* Pair up 7 counters — one is left over, so 7 is odd.

**`equation_equivalence_zr20`** — Gleichungen: Was ist gleich?
*Archetype:* New — from scratch
*Manipulative:* Two equation cards side by side, true/false judgment
*Levels:* 1) Visually similar equations (7+3 vs 3+7) → 2) Visually different but equal (7+3 vs 8+2)
*Example:* "Is 6+4 the same as 8+2?" → yes.

**`commutativity_zr20`** — Tauschaufgaben (Kommutativgesetz)
*Archetype:* New — from scratch, though visually adjacent to `equation_equivalence` (could share the
same widget with a narrower prompt: specifically a+b vs b+a)
*Levels:* 1) Given a+b=c, predict b+a → 2) Recognize the pair among distractors
*Example:* "3+5=8. What's 5+3?"

**`number_wall_zr20`** — Zahlenmauer
*Archetype:* New — widget exists. `number_wall_widget.dart` already exists (static version, built for
the diagnostic); wrap it in a scaffolded exercise with levels.
*Manipulative:* Number wall (Zahlenmauer)
*Levels:* 1) Fill the top stone from two given base stones → 2) Fill a missing base stone given the
top and one base stone
*Example:* Base stones 5 and 7 → top stone 12; then: base 5, top 12 → find the other base (7).

**`calculation_triangle_zr20`** — Rechendreieck
*Archetype:* New — from scratch
*Manipulative:* Three-number triangle, one side's relationship visualized
*Levels:* 1) Find the missing corner given two → 2) Find a missing edge value
*Example:* Corners 3 and 5 relate to edge 8; given corners 3 and edge 8, find the other corner (5).

**`magnitude_estimate_zr100`** — Zahlenblick: Größenschätzung ohne Rechnen
*Archetype:* New — widget exists, reuses the 100-dot-field from `dot_field_*` (domain A) for a
without-computing estimation task
*Levels:* 1) Compare two magnitudes without counting (which is bigger, 78 or 34?) → 2) Estimate a
single quantity's rough size (closer to 20, 50, or 80?)
*Example:* "Without counting exactly — is this closer to 50 or 90 dots?"

#### Gap-fill and completion arithmetic

**`complete_gap_end`** — Ergänzungsaufgabe: Lücke am Ende (5+_=8)
*Archetype:* Extended — same completion tool as `complete_to_10/20/100` (domain A), reframed as an
explicit equation with the gap notation
*Levels:* 1) Small gap (1–3) → 2) Larger gap
*Example:* "5+_=8"

**`complete_gap_start`** — Ergänzungsaufgabe: Lücke am Anfang (_+2=7)
*Archetype:* Extended — same tool, gap on the other side
*Example:* "_+2=7"

---

### Domain D — Sachsituationen (3 skills)

**`operation_sense_add`** — Addition im Kontext verstehen
*Archetype:* New — widget exists. `templates/word_problem_widget.dart` already exists (built for the
now-retired generic template engine, but the widget itself — collecting a typed result for a finished
German story sentence — is directly reusable). No old hand-built exercise ever covered word problems;
this is a genuinely new content area for the hand-built engine.
*Manipulative:* Illustrated story scene + word-problem widget
*Levels:* 1) Explicit "and" story (joining) → 2) Implicit addition story (no keyword, inferred from context)
*Example:* "Lea has 4 apples. She gets 3 more. How many now?" → then a story without "more," inferred from context.

**`operation_sense_sub`** — Subtraktion im Kontext verstehen (wegnehmen und vergleichen)
*Archetype:* Extended — same widget, both subtraction sub-types the skill explicitly names
*Levels:* 1) Take-away story → 2) Comparison story ("how many more does X have than Y")
*Example:* "Tom had 9 marbles, gave away 3." vs "Anna has 8, Ben has 5 — how many more does Anna have?"

**`operation_sense_story`** — Rechengeschichten in Gleichungen übersetzen
*Archetype:* Extended — same widget, framed as translation rather than solving (child writes the
equation, not just the answer)
*Levels:* 1) Addition stories → 2) Mixed addition/subtraction stories
*Example:* "3 birds were on the branch. 2 more landed." → child writes 3+2, not just answers 5.

## 6. Manipulative/widget reuse summary

Widgets that already exist and get reused across multiple entries above (all currently used only in
the diagnostic or the retired template engine — none has a scaffolded-exercise wrapper yet):

| Widget | File | Reused by |
|---|---|---|
| Dienes place-value display | `manipulatives/dienes_place_value.dart` | bundling_recognition ×2, double_2digit ×2, halve_decade, halve_2digit ×2 |
| Zahlenstrahl (labeled line) | `manipulatives/zahlenstrahl.dart` | place_on_numberline ×2 |
| Rechenschiffchen | `manipulatives/rechenschiffchen_widget.dart` | double_crossing_10, quick_recognition_rechenschiffchen, halve_zr20_crossing |
| Hundertertafel | `common/hundred_chart_widget.dart` | hundred_chart_navigation, hundred_chart_structure, dot_field ×4 (as base grid), magnitude_estimate |
| Number wall | `common/number_wall_widget.dart` | number_wall_zr20 |
| Number-line endpoints | `common/number_line_endpoints_widget.dart` | number_line_zahlenstrahl, number_line_rechenstrich (adapted) |
| Twenty-frame | `common/interactive_twenty_frame_widget.dart` | structured_quantity_recognition ×2 |
| Word problem | `templates/word_problem_widget.dart` | operation_sense ×3 |

## 7. Open items for the implementation plan (not decided here)

1. **The multi-tenant adapter layer** (§4) — how an exercise reports attempts to `practice-session`
   instead of local `UserProfile` storage. Blocks every entry above equally; should be built once,
   first.
2. **Exact difficulty-curve parameters** (number ranges per problem index within a level) — deferred
   per the "structural design" scope Jakob chose; to be filled in per exercise during implementation,
   following `DIFFICULTY_CURVE.md`.
3. **Build order** — 93 exercises is a lot of work; the implementation plan should propose a
   domain-by-domain or construct-by-construct build sequence, not "all 93 at once."
4. **Z2 (`complete_to_10` family)** was planned once before and never built — worth flagging to Jakob
   directly since it's the one place where "old exercise" in the catalog turned out to be vapor, not code.
