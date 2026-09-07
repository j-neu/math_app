# Design — Diagnostik & Übungsinhalte v2 (Rework des Clean-Room-Durchlaufs)

| Feld | Wert |
|---|---|
| **Status** | Entwurf zur Freigabe |
| **Datum** | 2026-09-07 |
| **Owner** | Jakob |
| **Ersetzt** | den inhaltlichen Output von `tasks.md` R1–R6 (`cleanroom-v1`) |
| **Bewertung des Vorgängers** | `docs/clean-room/00-v1-assessment.md` |
| **Rechtliche Grundlage (unverändert gültig)** | `rewrite.md`, `docs/clean-room/00-charter.md` |

This document is the design for rebuilding the *content* of Numeris — the diagnostic instrument, the skill taxonomy, and the practice exercises. It does not change the platform: Supabase backend, teacher dashboard, child login, session recording and the deployment pipeline all stay as they are.

---

## 1. Why v2 exists

The clean-room rewrite (2026-08-29 → 2026-09-05) produced `cleanroom-v1`: a 31-construct map, a 59-item core test plus 32 deep-dive items, a 36-skill taxonomy and a 91-entry item→skill mapping. It is not usable as a diagnostic instrument. Verified against the runtime CSVs and the construct map on 2026-09-07:

- **Verdoppeln/Halbieren is grossly under-specified.** ZR10 is covered (items 32–35). **ZR20 has no direct item** — the two "Verdopplung als Stützpunkt" items are `8+7` and `9+8`, Zehnerübergang tasks that presuppose the double without ever testing retrieval of `7+7` or `8+8`; ZR20 halving appears only in one deep-dive item. **ZR100 is absent from the construct map itself** — no construct, therefore no item, no skill, and nothing the Förderplan can recommend.
- **Many items are too complex and diagnostically inverted.** Core items 44–53 are multi-sentence scripts that hand the child the procedure (item 44: *"Rechne 34 + 28. In der Tabelle stehen Zehner und Einer. Die Zahl 34 hat 3 Zehner und 4 Einer …"*). They measure instruction-following, not strategy, and impose a reading load a Klasse-2 Förderkind will not carry.
- **The product's headline construct is not measured.** Zählendes Rechnen is inferred only from response latency on a few items; the child is asked *how* they calculated in four items, all ZR100.
- **The practice catalogue got thinner, not richer.** The pre-clean-room engine holds ~30 hand-built, multi-level, manipulative-first exercises — including `Verdoppeln mit Spiegel (ZR10/ZR20)`, `mit Fingern (ZR10/ZR20)`, `am Rechenschiffchen`, `Zehner verdoppeln`. The gauntlet replaced it with 36 skills × 3 levels × 8 generated problems from 16 generic templates, and the child flow was routed away from the old engine on 2026-09-01. The diagnostic's construct map was then derived to match the thinner thing.
- **The gates never had a chance of catching it.** Provenance, independence, mapping, specs and skill-descriptions were green throughout. All five check paperwork; none checks coverage, difficulty or age-fit. The construct map and blueprint were written in one pass, signed off, and every downstream artifact compounded on them. No coverage check against the Klasse 1–2 curriculum was ever run, and no child ever used the instrument before sign-off.

Jakob's item-by-item walkthrough of the running instrument (2026-09-07) is recorded as **Anhang A** of `00-v1-assessment.md` and confirms the same picture from the child's side — multi-answer items with unlabelled boxes, prompts that contradict what is drawn, a subitizing item that cannot measure subitizing, missing representation and Zahlenraum ladders, and unexplained duplicates. Rules 6–12 in §5.1 exist because of it.

The root cause is a **derivation order**: constructs were invented first and coverage was whatever fell out of them. v2 inverts that.

## 2. Decisions locked (2026-09-07)

| Frage | Entscheidung |
|---|---|
| Quellenbasis | **Sources as a reading map.** The iMINT-Kartei's bibliography may point us at primary literature; its selection, arrangement, card structure and wording are never the target. Coverage is derived from Rahmenlehrplan BE/BB Teil C + KMK Bildungsstandards, interpreted through the primary literature. |
| iMINT-Abgleich | **Once, late, one-directional.** After the v2 matrix is drafted and signed, the Kartei is opened solely to ask *"welche Zelle fehlt uns?"*. Gaps become cells; the items filling them are authored from our own sources. Protocol recorded as **ADR 0010**. |
| Durchführung | **Kind allein am Gerät, radikal vereinfacht.** No teacher-led block. The process signal must therefore be earned from the interaction (§5.2). |
| Inhaltsumfang | **ZR10 → ZR100, Inhalte der Klassen 1–2.** Grade-independent in use: written for Klasse 1–2, administrable to an older child who is behind. No Einmaleins, no ZR1000. |
| Testform | **Vollständigkeit vor Kürze.** Length is not a design goal. Abkürzung exists only to skip the harder Zahlenraum of a strand the child already failed lower down. Sessions persist for weeks and are continued by the teacher. |
| App-Struktur | **Alte Engine-Struktur, neuer Inhalt.** Hand-built, multi-level, manipulative-first exercises with rewards return as the child-facing model; the gauntlet's server layer (child login, path, session recording, teacher console) stays. |
| Autorenschaft | **Konstrukt für Konstrukt, Jakob gated jede Zelle** — on paper and then in the running app. No parallel bank-drafting. |
| Kommerzieller Status | Unchanged: non-commercial until `tasks.md` R9.3. Now additionally justified on pedagogical grounds, not only legal ones. |

## 3. Artefakt-Architektur

The clean-room *discipline* survives; only its v1 *output* is rejected.

**Stays in service:** `docs/clean-room/00-charter.md`, `03-bibliography.md`, `decisions/` (ADR numbering continues), and the provenance tooling.

**Frozen as the record, read-only, banner VERWORFEN:** `01-construct-map.md`, `02-blueprint.md`, `items/`, `skills/` (incl. `skills/specs/`), `foerderplan/mapping-rationale.md`, `math_app/Research/diagnostic_core_v1.csv`, `diagnostic_deepdive_v1.csv`. Nothing recomputes off them once v2's generator exists. They are not deleted — they are the audit trail the clean-room posture depends on.

**New, under `docs/clean-room/v2/`** (German, like v1 — these are pedagogical artifacts and Jakob is the reviewer):

| Datei | Rolle |
|---|---|
| `10-deckungsmatrix.md` | **Wurzelartefakt.** Coverage is decided here, before anything else exists. |
| `11-konstruktkarte.md` | Constructs, *derived from* the matrix. |
| `12-blueprint.md` | Item allocation, sequencing, Abkürzungsregeln. |
| `items/<ID>.md` | One file per diagnostic item, with slimmed provenance. |
| `uebungen/<ID>.md` | One file per practice exercise: levels, manipulative, number ranges, mastery. |
| `13-zuordnung.md` | Item → Konstrukt → Skill → Übung, in one table. |

**Precedence for the whole project:** Deckungsmatrix > Konstruktkarte > Blueprint > Items/Übungen. In v1 the construct map was the root; that is what made coverage an accident.

**Structural rule, from a v1 bug:** *a skill may only exist if it has practice content.* The gauntlet's one Critical integration finding was a teacher able to add a skill with no child-facing screen — a symptom of items, skills and exercises being derived on three separate tracks. In v2 the matrix cell binds all three, so the condition is machine-checkable.

## 4. Die Deckungsmatrix

Three axes, because two axes are what let ZR100-Verdoppeln vanish.

- **Zeilen — Inhaltsstrang:** Zählen, Anzahlerfassung, Zerlegung, Verdoppeln/Halbieren, Bündeln/Entbündeln, Zahldarstellung, Zahlvergleich, Addition ohne/mit Übergang, Subtraktion ohne/mit Übergang, Ergänzen, flexible Strategien, Sachsituationen.
- **Spalten — Zahlenraum:** ZR10 · ZR20 · ZR100.
- **Tiefe — Repräsentation:** enaktiv · ikonisch · symbolisch.

Rows are derived from **Rahmenlehrplan BE/BB Teil C** and **KMK Bildungsstandards** — open, citable, and the actual authority on what Klasse 1–2 must contain — then cross-read with Padberg/Benz, Wartha/Schulz, Gaidoschik, Schipper and Moser Opitz for what each strand means diagnostically and what a wrong answer indicates.

Every live cell carries five fields:

```
verdoppeln × ZR100 × symbolisch
  quelle:      RLP BE/BB Teil C …; Padberg/Benz …
  diagnostik:  [Item-IDs]         ← ≥1, oder begründete Ausnahme
  übung:       [Übung + Stufen]   ← ≥1, oder begründete Ausnahme
  fehlerbild:  was ein Fehler hier bedeutet
  status:      offen | entworfen | freigegeben | bewusst-nicht-abgedeckt
```

Cells that are pedagogically meaningless (e.g. Subitizing × ZR100) are marked `bewusst-nicht-abgedeckt` with a reason rather than silently omitted. Expect **roughly 60–70 live cells** against v1's 31 constructs.

The old exercise catalogue is read into the matrix as **inventory** during Phase 1, so each cell knows what child-facing content already exists before anything new is authored.

## 5. Diagnostik v2

### 5.1 Itemregeln (acceptance criteria)

1. **Eine Anweisung, ein Satz.** No embedded procedure. v1's item 44 becomes `Rechne: 34 + 28` with a Stellenwerttafel on screen if the cell is ikonisch.
2. **Leselast raus.** Short words, no subordinate clauses, digits rather than number words — and **every prompt is spoken as well as written**. Without a teacher to read aloud, reading ability otherwise confounds the maths measurement.
3. **Das Verfahren wird nie verraten.** If the prompt names the strategy, the item measures obedience.
4. **Manipulative-first wherever the cell is enaktiv:** Dienes, Rechenschiffchen, Zehnerfeld, Rekenrek, Finger, Zahlenstrahl. All unprotected, all already built as widgets.
5. **Jede Item-Datei benennt ihr `fehlerbild`** — what a specific wrong answer means — because the Förderplan and the error-pattern analysis both read it.
6. **Ein Item, eine Antwort.** The number of answer fields equals the number of expected answers, and every field carries its own label. Two answers means two items, or two separately labelled lines — never two bare boxes (v1 Q7, Q20, Q22; see `00-v1-assessment.md` Anhang A).
7. **Das Antwortlayout bildet die Aufgabe ab.** `8 = [ ] + [ ]` renders the operator; a Zahlenstrahl arrow points at the line, not away from it.
8. **Prompt und Darstellung sind ein Artefakt.** The item file names its manipulative and its visual configuration; the rendered widget must match. v1 asked about "Stäbchen" while the screen showed Würfel because text and widget were maintained separately.
9. **Konstrukttreue vor Bequemlichkeit.** Simultanerfassung is capped at 5 by definition — beyond that the item measures counting, whatever it claims. Structured arrangements are aligned, never row-shifted.
10. **Kein Beiwerk.** Every sentence that is not measured is reading load ("Kim kennt die Zahl 4." → gone).
11. **Zwei Items in derselben Zelle brauchen einen benannten Unterschied.** If the item file cannot state what this one measures that its sibling does not, one of them goes (v1 Q15/Q17, Q20/Q24/Q25).
12. **Monotoner Schwierigkeitsverlauf innerhalb eines Strangs.** A hard item followed by a trivial neighbour is a defect in its own right, and the Zahlenraum ladder is walked in order: Zahlenstrahl 0–10 → 0–20 → 0–100, never straight to 0–100.

### 5.2 Prozess-Spur — the replacement for the teacher's eyes

With the child alone at the device, the zählendes-Rechnen signal has to be earned from the interaction:

- **Latenz** per item (already captured; now specified per item rather than ad hoc).
- **Interaktionsspur** where the widget affords one: did the child step the Zahlenstrahl one number at a time, or answer directly? Did they re-count a bundle they had already bundled?
- **Fehlersignatur**, declared per item: ±1 errors as the counting fingerprint, Stellenwert-Dreher, Abriss an der Dekadengrenze.
- **Blitz-Items**: exposure short enough that counting is impossible by construction. This is the cleanest machine-readable evidence of the construct the product is named for. v1 had exactly one such item.

### 5.3 Abkürzung (break-off)

Strand-local: failing the ZR10/ZR20 cell of a strand skips the **ZR100 cell of that same strand**. Not v1's rule, which skipped all of Domain C on a counting failure and discarded information the teacher needed.

Skipped items are recorded as `übersprungen (Abkürzung)` and never as wrong. The Förderplan states *"im ZR100 nicht erhoben"* rather than implying failure.

### 5.4 Persistenz über Wochen

The session stays open indefinitely, resumes at the exact item, keeps item order stable across resumes, and recomputes break-off decisions from stored answers so a two-week gap cannot change the path. The teacher sees per-strand progress and a **"Diagnostik fortsetzen"** action in the dashboard. **F5** (the queued abandoned-session job) must exclude in-progress diagnostics outright — otherwise it silently kills exactly this workflow.

### 5.5 Umfang

No target length. Expect **~70–90 items** in the bank, with Abkürzung pruning any individual child to fewer.

## 6. Übungs-Engine

**Keep the server layer, replace the child-facing content model.**

Stays, unchanged and content-agnostic: `student-auth` (child login/roster), `learning-path` (per-student path from the Förderplan), `practice-session` (start/sync/end, attempt rows, `skill_progress`, mastery), and the teacher console.

Goes: the content model of 36 JSON specs × 3 levels × 8 generated problems from 16 generic templates. That ceiling is why levels came out thin.

In its place: a path item opens the **hand-built exercise** for that skill — own scaffolded levels, own manipulative, own rewards — and reports attempts back through `practice-session`, so the teacher console and mastery keep working unchanged. An **adapter layer** sits between them.

**The main integration cost, named up front:** the old engine is single-device — every exercise takes a `UserProfile` and writes local progress — while the platform is multi-tenant with a student JWT. Bridging those is the bulk of the restoration work, not the exercises themselves.

**Kept from the gauntlet's child-facing work:** the §3a fixes were expensive and correct. The tap-anywhere `numberline_step` and the `bundle_sticks` canonical-split gate survive as **reusable widgets inside hand-built levels**, just not as an auto-generated curriculum. The unwired custom `bundling` widget's partial-bundle hole is closed or the widget is deleted when its cell comes up.

**R8.1 stops being a deferred phase.** Each old exercise is triaged (keep structure / rewrite levels / drop) at the moment its matrix cell comes up, with numbers and level design re-derived from the matrix and the literature rather than from the card it originally came from. Cells with no old exercise get one authored in the same style.

**Governance returns to force:** `DIFFICULTY_CURVE.md`, `COMPLETION_CRITERIA.md`, `REWARDS_SYSTEM.md` / `REWARDS_SYSTEM_QUICK_REF.md`, `EXERCISE_DESIGN_SYSTEM.md`, `COMMON_PITFALLS.md` and `adhd guidelines.md` govern this engine and come off "paused". **One level = one sitting = 5–10 Minuten** is a hard level-sizing rule.

## 7. Laufzeit & Migration

**Ship as a new row, never edit the old one.** `cleanroom-v2` gets its own `diagnostics` row, its own questions and its own skills. `cleanroom-v1` and every session against it stay readable and untouched; a Förderplan from June still renders in September. `cleanroom-v1` is **not** disabled in the product (decision 2026-09-07: only Jakob uses it).

**Three mechanical v1 defects designed out:**

- The runtime CSV drifted from the signed item files (22 stale prompts, `question_count` 60 vs 59) because a derived artifact was not regenerated when its source changed. v2 has **one generator, one source**, plus a gate asserting *item files == CSV == live DB*, run on every content change.
- The independence sidecar keyed adjudications on **row index**, so deleting one item silently re-pointed them. v2's CSV carries an explicit **item-ID column**; nothing keys on row order anywhere.
- `diagnostic-results` resolves answers by `question_number`, so numbering is a contract, not a display detail. The generator and the migration keep it gapless; the gate verifies it against live.

**Schema deltas:** a path item references an **exercise** rather than a generated skill spec (§6); items carry an **audio asset** for the spoken prompt. Audio is generated as German TTS at build time into the existing Storage bucket — consistent and regenerable; a recorded voice can replace it later without a schema change.

**F5** excludes in-progress diagnostics (§5.4).

## 8. Prozess & Gates

**The unit of work is a matrix cell. The loop is fixed:**

1. Cell opened: `quelle` and `fehlerbild` written from RLP/KMK + literature.
2. Diagnostic item **and** exercise levels drafted together — never on separate tracks.
3. **Gate 1 — Jakob reads them** as the Förderlehrer. Wrong ones die here.
4. Implemented in the running app.
5. **Gate 2 — Jakob sees it as the child sees it**, on the actual screen. A cell is not `freigegeben` before this.
6. Checker green, next cell.

The bank can never get more than one strand ahead of Jakob's judgement. v1 drafted 92 items with parallel agents and reviewed 127 provenance rows in a single day; **no parallel bank-drafting in v2.**

**Gates:**

| Gate | Rolle |
|---|---|
| `scripts/check_deckung.py` | **New, headline gate.** Fails on: an empty cell without a written exemption; an item pointing at a non-existent cell; a skill with no exercise; an exercise covering no cell. Green means *covered*, not *documented*. |
| `scripts/check_item_quality.py` | **New.** The mechanical half of §5.1: sentence count, word count, banned procedure-phrases (`Zerlege …`, `Rechne zuerst …`, `In der Tabelle stehen …`), reading-level proxy, audio asset present — plus **answer-field arity == expected-answer count**, **every field labelled**, **manipulative named in the item file == widget registered for it**, and **Simultanerfassung items capped at 5**. Each of those catches a defect v1 actually shipped. A floor, not a substitute for Gate 1. |
| `scripts/check_provenance.py` | **Kept, demoted to hygiene.** Per-item provenance stays — it is the legal firewall — slimmed from 13 fields to four: source, rationale, independence statement, reviewer. |
| `scripts/check_item_independence.py` | **Kept unchanged.** Still legally necessary; still compares against the archived legacy CSV. |

v1 had five green gates while the instrument was unusable. v2's gates fail on substance.

**iMINT-Deckungsaudit.** Runs once, after the matrix is drafted and signed, before launch. One-directional: the Kartei is opened only to ask which cell is missing. A gap becomes a cell; the item filling it is authored from our own sources. Written up as **ADR 0010** with the protocol — who looked, when, which cells were added, and an explicit statement that no wording, numbers or arrangement were carried across. The record is what makes the audit defensible rather than contaminating.

## 9. Reihenfolge

**Phase 1 — Fundament (~1 Woche).** Deckungsmatrix; `check_deckung.py`; old exercise catalogue read in as inventory; VERWORFEN banners; `v2/` tree. **Ends with Jakob's signature on the matrix** — the most consequential sign-off in the project, since everything is now derived from it.

**Phase 2 — Ableitungen (kurz).** Konstruktkarte and Blueprint fall out of the matrix. Item acceptance criteria written down; `check_item_quality.py`.

**Phase 3 — Erster Slice, vertikal und komplett: Verdoppeln/Halbieren × ZR10 · ZR20 · ZR100.** Diagnostic items → hand-built exercise levels → adapter into `learning-path`/`practice-session` → visible in the teacher console. Chosen because it is the named gap, spans all three Zahlenräume (proving the strand-local Abkürzung), has old exercises to re-derive (proving the adapter and the R8.1 triage), and has an empty diagnostic side (proving the item rules).

**Phase 4 — Strang für Strang** through the rest, in curriculum order, at the pace the two gates allow.

**Phase 5 — Generator, Migration, `cleanroom-v2` live, TTS-Audio.**

**Phase 6 — iMINT-Deckungsaudit (ADR 0010), dann Abnahme.** R6.4's device run finally has something worth accepting; R9's legal review reviews a bank that is final.

## 10. Nicht im Umfang

- Platform, backend, dashboard, deployment: unchanged.
- Einmaleins, Division, ZR1000: out of scope (§2).
- Teacher-led administration: rejected (§2).
- Commercial launch: still gated on `tasks.md` R9.
- Disabling or migrating `cleanroom-v1` data: explicitly not done.

## 11. Offene Punkte

- **Q15/Q17 und Q20/Q24/Q25** (Zerlegungs- und Stellenwert-Dubletten aus Anhang A): the constructs behind them are distinguishable, the items as authored are not. Resolved when those matrix cells are opened — the recommendation is in §5.1 rule 11.
- **Audio:** TTS at build time is the assumption; a recorded voice is a later, schema-neutral swap.
- **Old-engine adapter depth:** whether `UserProfile` is bridged or replaced is settled by the Phase-3 slice, not by this document.

## 12. Folgen für die vorhandene Dokumentation

To keep every document pointing at the same goal:

- `STATUS.md` — carries the VERWORFEN banner; the v2 rework becomes the top Active item.
- `README.md` — status paragraph updated; stale claims about the 92-question CSV and the 88-skill catalogue corrected.
- `DOCS_INDEX.md` — this spec and `00-v1-assessment.md` at the top; v1 clean-room content docs marked 🔴; the practice-framework docs flipped from 🟡 paused to 🟢 in force (§6).
- `tasks.md` — keeps its Nachtrag; remains the record of the first run and the home of the still-live R9 legal items.
- `GAUNTLET_PROGRESS.md` — archived as the closed programme's evidence log, with pointers preserved.
- Memory files describing the clean-room rewrite as sound are corrected.
