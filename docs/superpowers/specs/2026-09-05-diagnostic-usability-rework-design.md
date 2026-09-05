# Design — Diagnostik-Überarbeitung: Bedienbarkeit, Verständlichkeit, Item-Revision

**Date:** 2026-09-05
**Owner:** Jakob
**Status:** DRAFT — awaiting review
**Ships as:** new diagnostic bank `cleanroom-v2` (`cleanroom-v1` frozen, pilot sessions on it stay readable)
**Relates to:** `tasks.md` (clean-room rewrite), `docs/clean-room/02-blueprint.md`, `docs/superpowers/gauntlet-loop.md` §3 (invariant sweep)

---

## 1. Context

The clean-room item bank (59 core items, signed 2026-08-30) is live and children are taking it. Reviewing the running diagnostic surfaced defects across the whole surface: the prompt is printed twice on every text item, counting tasks demand up to fifteen numbers in a row, the subitizing item flashes in the top-left corner for 800 ms, place-value items render a home-made "Stäbchen" bundle children cannot count, and every item from Q44 onward is a paragraph that teaches a method and then asks the child to execute it.

### 1.1 Root cause

The rewrite re-authored the *content* but abandoned the *interaction layer*, and then wrote item text to compensate for the missing interaction.

Four finished, working assets sit unwired in the repo:

| Asset | State |
|---|---|
| `math_app/lib/widgets/common/dienes_block_widget.dart` | Isometric Einer/Zehner/Hunderter/Tausender renderer. Zero usages. |
| `math_app/lib/widgets/answer_widgets.dart` `SortAnswerWidget` | Working drag-to-reorder list. File is imported by nothing. `AnswerFormat.sort` exists in the model; the answer dispatch has no sort mode. |
| `math_app/Research/zahlen_diktat.mp3` | Byte-identical to `Research/math app.mp3`. Bundled in `pubspec.yaml`, auto-played and given a replay button by `diagnostic_screen.dart`. No core item references it. |
| `Hilfetext` field in `docs/clean-room/items/TEMPLATE.md` | On-demand task explanation. **17 items have one written.** The CSV has no such column, so it never reaches the app. |

With no help channel and no sort/manipulative vocabulary available, the only place left to explain a task was the prompt itself. Hence the paragraphs.

A second root cause runs through all 92 item files: **they were authored for a 1:1 assessor-administered test.** Every `Acceptable variants` field admits spoken answers, pointing, word forms, and self-corrections. The product is a child alone in a browser. Some items acknowledge the contradiction in their own prose (`B1.3-01`: *"Die Diagnostik läuft ohne Lehrkraft am Tablet; ein Nachfragen entfällt"*) without resolving it.

The `Acceptable variants` are not merely ungradable — some are **structurally impossible to enter**. `A1.2-01` counts down 21 → 16 and accepts the child repeating the start number ("21, 20, …"), but the sequence widget renders exactly five boxes. A child who takes the accepted variant runs out of boxes before reaching 16 and is scored wrong.

---

## 2. Locked decisions

| # | Decision | Rationale |
|---|---|---|
| 1 | **Determinism rule.** An item's expected answer is exactly one machine-checkable value or ordered tuple. If code cannot grade a variant, the variant is not acceptable — tighten wording and input until it cannot arise. | Jakob, 2026-09-05. A variant only an assessor can judge is a false promise in an unsupervised test, and at worst unenterable. |
| 2 | **Short prompt + `Hilfe` button.** The on-screen prompt states the task in one or two sentences. The fuller explanation lives behind a button the child may press. | Restores the channel the template designed. Removes the reason prompts became paragraphs. |
| 3 | **C3/C4 become bare calculations.** No method text, no strategy self-report. Signal = correctness + response time. | Jakob, 2026-09-05. A screen cannot honestly observe strategy; a slow correct answer is the counting signal the blueprint already relies on. |
| 4 | **Ships as `cleanroom-v2`,** a new `diagnostics` row. | Jakob, 2026-09-05. Renumbering a live bank is the documented data-corruption path (`gauntlet-loop.md` §3); v1 and its pilot sessions stay readable. |
| 5 | **Use the established manipulatives freely** — Dienes, Plättchen, Rechenschiffchen, Rekenrek, Zehnerfeld, Zahlenstrahl. | Jakob, 2026-09-05. They are standard German didactic material, unprotected, and recognisable to the child from the classroom. |
| 6 | **Reuse the existing dictation audio** (`zahlen_diktat.mp3`; numbers 9, 17, 54, 60, 71, 90). | Jakob, 2026-09-05. Already recorded, already bundled, already wired. |
| 7 | **Maximum 6 answer boxes** on any item. | Jakob, 2026-09-05. |
| 8 | **Timeout = 5 s per answer box**, floor 15 s. | Jakob, 2026-09-05. A flat 20 s punishes an eight-box item and demotivates. |

### 2.1 Two calls made under this design, requiring Jakob's signature

- **Number ordering gets a new construct `A2.4 Zahlen der Größe nach ordnen`,** and `A2` is renamed *Anzahlerfassung und Zahlvergleich*. `A2.3` already measures comparison of two quantities; ordering is that comparison generalised beyond two, in the symbolic realm. This amends `01-construct-map.md`, which is signed — so it needs re-signing.
- **Core bank grows 59 → 67 items.** Administration time still falls: fourteen paragraph items (60–120 s each) become bare calculations of 5–15 s. This amends the allocation table in `02-blueprint.md`, which is signed — so it needs re-signing.

---

## 3. Design principles

1. **A child who cannot solve an item still knows what to do.** Comprehensibility and difficulty are independent axes; the diagnostic measures the second and must not accidentally measure the first.
2. **Every accepted answer is enterable.** If the UI cannot express a variant, the item does not accept it.
3. **The picture carries the description.** Where a visual renders the stimulus, the prompt does not re-narrate it.
4. **Use the material the child already knows.** Prefer established manipulatives over invented visuals.
5. **One question per item.** Two constructs in one prompt (Vorgänger *and* Nachfolger) is two items.
6. **Nothing derived stays stale.** Every artifact regenerated from its source in the same change (`gauntlet-loop.md` §3).

---

## 4. Workstream A — Interaction layer

No item content involved. Each is independently testable.

### 4.1 Render the prompt once
`diagnostic_screen.dart:929-950` renders `question.questionText` at 48 px bold **and** `question.german` below it. The CSV holds identical text in both columns for every text item. Remove the `questionText` block; render `german` only. `questionText` keeps its role as the item-ID key for visual items (`buildVisualDisplay`).

### 4.2 No quotation marks
Prompts carry `„…"` (Q1-7), `"…"` (Q12-19, 28-43) and `»…«` (Q20, 27, 44-57) — three styles, none of them meaningful. Strip at `scripts/generate_diagnostic_csv.py`; the item files stop wrapping prompts in quotes. A check script fails on any prompt beginning with a quotation character.

### 4.3 Sequence input shows the given anchor
`diagnostic_answer_widgets.dart:94` renders N bare boxes. Render the given start (and step, where the task defines one) as static, non-editable text ahead of the boxes:

```
12,  [__]  [__]  [__]  [__]
```

The child cannot re-enter the start number, so the `A1.x` "repeating the start is accepted" variants become impossible rather than accepted. Box count equals the count of expected numbers, exactly.

### 4.4 Maximum six boxes
A gate script asserts no item's expected answer exceeds six values. Items over the limit are shortened in Workstream B.

### 4.5 Flash presentation
`rekenrek.dart`: beads render left-aligned in a `Row`, so `A2.1-01` (4 beads, top rod) appears in the top-left corner while the child looks at screen centre; the flash starts on build, 800 ms + 200 ms fade, with no warning.

- Centre the beads on the rod.
- Precede the flash with a fixation point and a visible **3 – 2 – 1** countdown; the child presses **Bereit** to start.
- Raise the exposure to 1500 ms.
- The flash begins only after the countdown completes, never on build.

### 4.6 Response-time budget
`diagnostic_screen.dart:88`: `timeoutSecondsSingle = 20`, `timeoutSecondsMultiple = 60`, applied by `AnswerFormat` alone. Replace with `max(15, 5 × boxCount)`, where `boxCount` comes from the item's answer spec. The dictation item (6 boxes) gets 30 s; a bare calculation gets 15 s.

### 4.7 Dienes replaces Stäbchen
`StaebchenWidget` draws an 84×30 cream rounded rectangle with orange lines and two brown bands — at item scale it reads as a tin, and eleven 5 px loose sticks are genuinely hard to count. Replace with `DienesBlockWidget` (`DienesType.rod` for Zehner, `DienesType.unit` for Einer) on `B1.2-01`, `B1.2-02`, `B1.3-01`, `DDB-01`, `DDB-02`. The interactive "open a bundle" affordance of `StaebchenOeffnenWidget` is preserved against the Dienes rod.

### 4.8 Sort answer mode
Add `DiagnosticAnswerMode.sort` to `answer_grading.dart` and dispatch it in `diagnostic_answer_widgets.dart` to `SortAnswerWidget`, lifted from the orphaned `answer_widgets.dart`. Grading compares the child's order against the expected order exactly. The widget shuffles on entry; a shuffle equal to the solution is re-rolled.

### 4.9 Hilfetext channel
- `generate_diagnostic_csv.py` emits a new `Hilfetext` column from the item files.
- `DiagnosticQuestion` gains `hilfetext`; `diagnostic_service.dart` parses it.
- A **Hilfe** button renders beside the prompt when the field is non-empty, opening a calm German panel. Pressing it is recorded on the result row (new `used_help` boolean on `diagnostic_results`, added by the §7 migration) — a child who needed the explanation is diagnostically interesting and the teacher should see it.
- Pressing Hilfe pauses the response-time budget.

### 4.10 Dictation item wiring
`Research/zahlen_diktat.mp3` is already bundled and already auto-played by `diagnostic_screen.dart:214`. The new B2 dictation item sets `AudioAsset` to it, uses six sequence boxes for 9, 17, 54, 60, 71, 90, and gets a 30 s budget from §4.6. The replay button already exists.

---

## 5. Workstream B — Item revision

Target: **67 core items**. Every changed or new item gets its `docs/clean-room/items/<ID>.md` rewritten and its `provenance.csv` row re-signed by Jakob.

### 5.1 Determinism pass across all 92 item files
Rewrite `Acceptable variants` in every file. The field either states a variant the grader actually implements, or it says none. Concretely:

| Pattern found | Resolution |
|---|---|
| "Wiederholen der Startzahl akzeptiert" (A1.1-01/02, A1.2-01/02, A1.3-01/02) | Impossible by A3 — the anchor is static text. Field: none. |
| Spoken/word-form answers ("vier", "vierundzwanzig", "sechzig") | Input is numeric-only. Field: none. |
| Pointing / gesture ("Zeigen auf das rechte Zehnerfeld") | Input is a tap on a labelled choice. Field: none. |
| "Mündlich statt Ankreuzen akzeptiert" (D1.2-01) | Input is a tap. Field: none. |
| "Optionale Zusatzangabe verbessert die Diagnose" (B1.2-02) | Ask one thing. Split into two boxes if both are wanted. |
| Order-free part answers (A1.4-01) | Split into two items (§5.2), each one box. |
| Commutativity (D1.1-01, "5 + 8" for "8 + 5") | **Kept** — genuinely gradable as an unordered pair. The grader must implement it. |

Rule: a variant survives only if a named grading function accepts it and a test proves it.

### 5.2 Domain A — Zahlbegriff (7 → 10 in A1, 4 → 6 in A2)

- **A1.1-01** (12 → 20, eight numbers) and **A1.1-02** (48 → 63, **fifteen** numbers): shortened to ≤ 6 boxes, keeping the ZR20 / ZR100-with-Dekadenwechsel distinction the blueprint relies on.
- **A1.2-01/02**: shortened to ≤ 6 boxes.
- **A1.3**: currently 2er *forward* only and 5er *backward* only. Add **2er backward** and **5er forward**, completing the matrix (A1.3 ×2 → ×4).
- **A1.4-01** asks Vorgänger *and* Nachfolger in one prompt, which reduces to writing a sequence. **Split into two items**, one box each.
- **A2 order**: present structured quantity recognition (`A2.2-01`) *before* the subitizing flash (`A2.1-01`). The flash is the more demanding presentation and should not be the child's first encounter with a quantity task.
- **New `A2.4-01`, `A2.4-02` — Zahlen der Größe nach ordnen.** Drag-to-sort (§4.8), four to five numbers, one item in ZR20 and one in ZR100. Requires the construct-map amendment in §2.1.

### 5.3 Domain B — Stellenwert (8 items, composition changes)

- **B1.2-01, B1.2-02, B1.3-01**: Dienes visuals (§4.7).
- **B2.1-02 dropped.** It renders a Stellenwerttafel already showing Z=6, E=0 and asks the child to write 60. A child who can read a digit passes; the item separates nobody.
- **New B2.1-03 — Zahlendiktat.** Replaces the dropped item in the allocation. Audio plays; six boxes; 9, 17, 54, 60, 71, 90. Measures hearing a number name and writing its standard form. `DDB-06` (the deep-dive auditory item) stays where it is.

### 5.4 Domain C — Rechenstrategien (C3+C4: 14 → 17; C1/C2 unchanged at 16)

- **C1, C2 (Q28-43) unchanged.** They are already bare, short and clear.
- **New whole-tens items under C3.1**: `30 + 7`, `60 − 4`, `7 + 80`. The bank currently has no item where a ten and a unit are combined directly — the most basic ZR100 competence, and the one whose absence hides a place-value gap.
- **C3 (Q44-53) rewritten as bare calculations.** Every prompt today walks the child through the method and then asks for the result; the grader keeps one number and discards the rest. The rewritten items present the calculation alone. C3.1 ×3 → ×6 (three rewritten plus three whole-tens), C3.2 ×3, C3.3 ×2, C3.4 ×2 — thirteen items.
- **C4 (Q54-57) rewritten as bare calculations**, four items. The construct (strategy choice, inverse relation) is carried by **item design, not by asking**: numbers are chosen so a relational route is dramatically faster than a procedural one, and the pairing is made adjacent so the relation is available.

  | Item | Task | Why these numbers |
  |---|---|---|
  | C4.1-01 | `21 + 50` | Trivial via 20 + 50; slow means no relational route |
  | C4.1-02 | `37 + 38` | Near-double; slow means step-by-step |
  | C4.2-01 | `43 + 29`, then `72 − 29` adjacent | The second is the first inverted |
  | C4.2-02 | `73 − 38` | Round to 40 and adjust |

  The strategy self-report (a/b/c/d) is removed entirely, per decision 3.

### 5.5 Domain D — Sachsituationen (2 items)

- **D1.1-01** kept; commutativity variant retained and implemented (§5.1).
- **D1.2-01**: the prompt currently embeds `9 + 4 · 9 − 4 · 4 − 9` as literal text where the middle dots are separators. Render three tappable choices.

### 5.6 Comprehensibility sweep — all 67 items
Each item is read against principle 1. Known instances:

- **A3.2-02 (Q17)**: "Finde alle Zerlegungen von 10 in zwei Zahlen" uses *Zerlegungen* with no explanation, while Q15 shows the form `8 = ___ + ___` and is understandable. Q17 gets the same treatment.
- **B1.1-01 (Q20)**: "Sieh dir die Zahl an. Die Zahl ist 58. Wie viele Zehner hat die Zahl 58? Und wie viele Einer hat die Zahl 58?" — states the number three times. One sentence, two labelled boxes.
- The remaining items are audited in the plan's first phase (§8), not assumed clean.

---

## 6. Workstream C — Clean-room integrity

Content is signed material; this workstream keeps the audit trail true.

1. **Item files** rewritten for every changed item; new files for the eight new items, from `TEMPLATE.md`, every field filled.
2. **`01-construct-map.md`** amended for `A2.4` and the `A2` rename. Status returns to draft until Jakob re-signs.
3. **`02-blueprint.md`** allocation table amended to 67 with a written rationale per changed row. Status returns to draft until Jakob re-signs.
4. **`provenance.csv`** rows for changed and new items reset to unsigned. **Claude never fills `reviewed_by`.** Jakob signs per domain as batches land.
5. **`mapping-rationale.md`** entries added or revised for every changed and new item; `check_mapping.py` must pass.
6. **Independence**: `check_item_independence.py --strict` on both banks. The `A3.3-02` adjudication sidecar keys on **row index** — renumbering will move it again, and it must be re-keyed and verified by reading the row back (`gauntlet-loop.md` §3 rule 2).
7. **New gates**: `check_answer_determinism.py` (no ungradable variant; box count equals expected-value count; ≤ 6 boxes) and a prompt-hygiene check (no leading quotation mark, no duplicated prompt text).

---

## 7. Workstream D — Delivery

1. **Migration** `backend/supabase/migrations/<ts>_cleanroom_v2_bank.sql`: a new `diagnostics` row (`cleanroom-v2`, version 1, `question_count = 67`) plus its questions. `cleanroom-v1` untouched — no renumbering, no prompt edits, no retirement. Pilot Förderpläne on v1 keep rendering.
2. **Dashboard** points newly issued session tickets at `cleanroom-v2`. Existing unconsumed v1 tickets keep working.
3. **Deploy order.** Migration and Flutter web bundle ship together. A v2 bank in the database with a v1 bundle on the client files answers against the wrong questions — the exact failure `gauntlet-loop.md` §3 documents. If both cannot ship together, neither ships.
4. **Verify against the live table**, not the migration's own notices: query `diagnostic_questions` for v2 and diff prompt text and numbering against `diagnostic_core_v2.csv`.

---

## 8. Execution model

Jakob is the controller's principal; Claude Opus controls; **Sonnet subagents do the work**. Sequence:

| Phase | Work | Agents |
|---|---|---|
| 0 | **Item audit.** All 67 target items read against principle 1 and the determinism rule. Visual items rendered and inspected — an agent looks at the actual widget output, it does not read the spec and infer. Output: a per-item findings table that feeds phase 2. | Sonnet, parallel by domain |
| 1 | Workstream A (interaction layer). Independently testable, no content dependency; runs first so phase 2 authors against real widgets. | Sonnet, one agent per fix cluster |
| 2 | Workstream B (item revision), domain by domain. | Sonnet, one agent per domain |
| 3 | Workstream C (clean-room integrity, gates). | Sonnet |
| 4 | Fresh-context critic runs the actual diagnostic end to end. | Sonnet, no prior context |
| 5 | Workstream D (migration + deploy). | Jakob's step |

Every phase ends with the §9 gates green and evidence appended to `GAUNTLET_PROGRESS.md`.

---

## 9. Testing

| Layer | What |
|---|---|
| Unit | Timeout budget = `max(15, 5 × boxCount)` per item; sequence anchor renders and is not editable; sort grading is order-exact; help-button state and time-budget pause; commutativity grading for D1.1-01 |
| Widget | Every visual item renders at 768×1024, 1024×768 and 390×844; flash countdown sequence; Dienes rendering for each place-value item |
| Data | Every item ≤ 6 boxes; box count equals expected-value count; no prompt duplicated across `QuestionText`/`German`; no leading quotation mark; every `IfWrong` skill resolves |
| Coverage | Shortened mode still presents ≥ 1 item per construct and per domain (extends `diagnostic_shortening_test.dart`) |
| Answerability | All 67 items gradable by `answer_grading.dart` with no assessor judgment (extends `diagnostic_answerability_test.dart`) |
| Live | v2 questions in Postgres byte-match `diagnostic_core_v2.csv` |

Existing gates unchanged: `flutter test`, `flutter analyze` (0 errors), `npx tsc --noEmit`, `deno task check`, `check_provenance.py --all`, `check_item_independence.py --strict` ×2, `check_mapping.py`, `check_specs.py`, `check_skill_descriptions.py`.

---

## 10. Risks

| Risk | Mitigation |
|---|---|
| Sign-off becomes the bottleneck — 67 items plus two amended signed documents | Batched per domain, in reviewable form. Claude never fills `reviewed_by`; unsigned rows fail `check_provenance.py`, so an unsigned bank cannot ship by accident. |
| Independence sidecar silently mis-keys after renumbering | Re-key and verify by reading the row back. `gauntlet-loop.md` §3 rule 2. |
| Client/DB drift corrupts answers | v2 is a new row, so v1 traffic is unaffected during the window; migration and bundle ship together (§7.3). |
| Rewritten C3/C4 items collide with legacy operands | `check_item_independence.py --strict` before sign-off; adjudicate in writing where a construct forces the range. |
| Growing to 67 items lengthens the session | Fourteen paragraph items become 5–15 s calculations; net administration time falls. Measured on the acceptance run, not assumed. |
| Test coverage of a construct lost when items are dropped or split | Coverage test asserts ≥ 1 item per construct in both full and shortened modes. |

---

## 11. Non-goals

- Changing `cleanroom-v1`, or any pilot session, Förderplan or result already recorded against it.
- Serving the 32 deep-dive items through a UI flow. They remain unserved; this design does not change that.
- Reviving the eight retired practice skills, or touching the practice runtime, learning path or teacher console.
- Lifting the commercial freeze (`tasks.md` R9.3) or adding any pricing surface.
- Capturing intermediate steps of a multi-step calculation. C3/C4 grade the final result, by decision 3.
- Native builds. Web only; Android tablet in Chrome is the target device.
