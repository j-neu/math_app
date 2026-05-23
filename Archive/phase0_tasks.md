# Phase 0: Diagnostic → Förderplan (MVP)

**Status:** Planned. Implementation starts next session.
**Scope:** Diagnostic flow only — not the practice exercises.
**Created:** 2026-05-14

---

## Context

The diagnostic feature works end-to-end on the input side: 59 questions load from CSV, response times are tracked, timeouts mark questions as wrong (the signal for "child is counting, not calculating"), failed questions populate `userProfile.skillTags`. But on the **output** side it falls off a cliff — the child is dumped onto the Learning Path with no teacher-facing report.

A `PdfReportService` exists but outputs English text, dumps skills in a flat list with no pedagogical sequencing, and is buried behind a "view PDF" link. There is no in-app report screen. `tasks.md` claims `DiagnosticReportGenerator` is done — it isn't; report logic is inlined in the PDF service.

**Goal:** Ship a German, teacher-ready Förderplan generated immediately after a child completes the diagnostic — an in-app screen with a **brief view (next 3 skills)** and an **extended view (all recommended skills)**, plus PDF export. Use only data that already exists: the 59-question CSV and the German skill titles + one-sentence descriptions already in `skills_taxonomy.csv`. Keep the flat 59-question structure (decision: do not regroup into the iMINT book's 28 test cards).

**Out of scope here:** PIKAS integration, accounts, practice-app changes, broad documentation overhaul, restructuring the diagnostic into 28 test cards.

---

## Decisions locked in

| Decision | Choice |
|---|---|
| Diagnostic unit | Keep 59 flat questions (no test-card regrouping) |
| Förderplan ordering | Pedagogical sequence: category order → `card_number` ASC within category |
| Delivery | In-app screen **and** PDF export |
| CSV errors | Fix obvious typos/mismatches; list ambiguous ones for separate review |

---

## Work breakdown

### Task 1 — New models

**Files to create:**
- `math_app/lib/models/skill_recommendation.dart`
- `math_app/lib/models/foerderplan.dart`

**`SkillRecommendation` fields:**
`skillId`, `skillNameDe`, `descriptionDe`, `category`, `categoryColor`, `cardNumber`, `triggeringQuestionIds: List<int>`.

**`Foerderplan` fields:**
- `sessionDate`, `studentName`
- `recommendedSkills: List<SkillRecommendation>` — sorted, deduped, pedagogically ordered
- `briefSkills` — first 3 of the above
- `categoryStats: Map<String, ({int failed, int total})>`
- `slowResponseFlag: bool` — true if ≥30% of *correct* answers exceeded a per-question slow threshold (correct-but-slow = the same "counted instead of calculated" signal)

### Task 2 — New service: `DiagnosticReportGenerator`

**File to create:** `math_app/lib/services/diagnostic_report_generator.dart`

Single public method: `Future<Foerderplan> generate(UserProfile, DiagnosticSession)`.

Algorithm:
1. Load `skills_taxonomy.csv` (reuse the loader pattern at `pdf_report_service.dart:325–349`; promote to a shared helper).
2. Collect skill IDs from `IfWrong_practice_skills` of every failed/timeout question; dedupe.
3. For each skill ID, look up taxonomy metadata → build `SkillRecommendation`. Track which question(s) triggered it.
4. Sort by category sequence `[Zählen, Zahlzerlegung / Schnelles Sehen, Stellenwerte verstehen, Grundstrategien, Kombinierte Strategien]`, then `card_number` ASC. (PIKAS categories aren't referenced by any current question, so no fallback path needed.)
5. `briefSkills = recommendedSkills.take(3)`.
6. Compute `categoryStats` by counting questions whose `IfWrong_practice_skills` belong to each category.
7. Compute `slowResponseFlag` from `DiagnosticResult.responseTimeSeconds` over **correct** answers (timeouts already become wrong).

### Task 3 — Rewrite `DiagnosticReportScreen`

**File:** `math_app/lib/screens/diagnostic_report_screen.dart` (currently a thin PdfPreview wrapper — replace entirely).

Native Flutter screen, top to bottom:
- **Header:** student name, date.
- **Kurzer Förderplan** card: 3 skill tiles. Each tile: German title (large), one-sentence German description, category-colored badge.
- **Counting/Calculating banner** (only if `slowResponseFlag`): "Dieses Kind benötigt häufig viel Zeit zum Rechnen — vermutlich zählt es noch. Empfehlung: Schwerpunkt auf Grundstrategien zur Ablösung vom zählenden Rechnen."
- **Kategorie-Übersicht:** "Zählen: 3/14 falsch" etc.
- **Vollständiger Förderplan** (expandable, collapsed): all recommendations, grouped by category, title + description per skill.
- **Detail-Tabelle** (expandable, collapsed): per-question results — Q#, German text, correct answer, child's answer, time, status. Port from existing `_buildDetailsTable` in PdfReportService.
- **Actions:** `Als PDF exportieren`, `Weiter zum Üben` (→ existing `LearningPathScreen`).

### Task 4 — Rewrite `PdfReportService`

**File:** `math_app/lib/services/pdf_report_service.dart`

New signature: `Future<Uint8List> generatePdf(Foerderplan plan, DiagnosticSession session)`. German throughout. Layout mirrors the screen: header → brief plan → optional counting banner → category overview → extended plan → detail table. Reuse category colors from the taxonomy CSV.

### Task 5 — Wire navigation

**File:** `math_app/lib/screens/diagnostic_screen.dart` (around lines 450–515 where it currently navigates after completion).

After saving the session, build the `Foerderplan` via the generator and push the new `DiagnosticReportScreen`. **Do not** route directly to `LearningPathScreen`. The teacher advances to the Learning Path from the report screen.

### Task 6 — CSV fixes

**File:** `math_app/Research/MathApp_Diagnostic_with_skills.csv`

**Auto-fix (obvious):**
- Q23 English typo: `untill` → `until`.
- Q32–35 English column says "red" but German asks for "grüne" → change English to "green".
- Q39 same green/red mismatch.
- Q21 English text truncated mid-sentence ("How many more ").
- Q46 English text truncated ("How many more ").

**List for user review — do not fix without approval:**
- Q15–18 skill mapping includes `counting_8, counting_9` (Hundertertafel skills) for a "skip-count by 2 in ZR20" task — likely too broad.
- Q21 (dice rolling 7) has `CorrectAnswer = "1, 6"` but 2+5, 3+4, 4+3, 5+2, 6+1 are equally valid. Either the answer-checker must accept any decomposition or the answer column must enumerate them.
- Q36–37 mappings include `combined_strategy_12, combined_strategy_13` (addition/subtraction with crossing) for a pure bundling/place-value perception task — likely wrong category.
- Q47 ("1 + 5") maps to `combined_strategy_3, combined_strategy_4` (Kraft der 5) but the task is trivial enough that strategy-failure inference is weak.

### Task 7 — Minimal doc touch-up

In existing `tasks.md`:
- Move "Create `DiagnosticReportGenerator`" out of "done". Mark in-progress here.
- After implementation, mark new in-app Förderplan screen done.

Broader documentation cleanup (the user noted "the documentation is a hot mess") is **deferred** — a separate phase after the diagnostic itself is shipped.

---

## Critical files

| File | Action |
|---|---|
| `math_app/lib/models/skill_recommendation.dart` | Create |
| `math_app/lib/models/foerderplan.dart` | Create |
| `math_app/lib/services/diagnostic_report_generator.dart` | Create |
| `math_app/lib/services/pdf_report_service.dart` | Rewrite — accepts `Foerderplan`, German output |
| `math_app/lib/screens/diagnostic_report_screen.dart` | Rewrite — native screen + PDF export button |
| `math_app/lib/screens/diagnostic_screen.dart` | Change post-completion navigation |
| `math_app/Research/MathApp_Diagnostic_with_skills.csv` | Apply obvious fixes from Task 6 |
| `tasks.md` | Reflect actual diagnostic status |

## Reuse — do not re-implement

- CSV loader in `pdf_report_service.dart:_loadSkillMetadata` (lines 325–349) → promote to shared `SkillCatalog` helper.
- `DiagnosticResult.responseTimeSeconds` and `status` ('attempted' / 'skipped' / 'timeout') in `math_app/lib/models/diagnostic_result.dart` — sufficient for `slowResponseFlag`, no new timing infra.
- `_buildDetailsTable` in `pdf_report_service.dart` — port to a reusable widget for the screen.
- Category names + colors from `skills_taxonomy.csv` columns 2–3.
- German skill titles (column 5) + one-sentence descriptions (column 7) — no new copy to author.

---

## Verification (end-to-end)

1. `flutter run` from `math_app/`.
2. New user profile.
3. Take the diagnostic. Deliberately fail ~10 questions across at least 3 categories (Zählen, Zahlzerlegung, Grundstrategien). On 2 *correct* answers, respond slowly (>15 s) to trigger `slowResponseFlag`.
4. On completion: new `DiagnosticReportScreen` opens — not the Learning Path.
5. **Kurzer Förderplan** shows exactly 3 skills, German title + one-line description each, ordered Zählen → Zahlzerlegung → … .
6. Counting/calculating banner is visible (slow responses were intentional).
7. Expand **Vollständiger Förderplan**: every failed skill appears under its category heading.
8. Expand **Detail-Tabelle**: every question shows status (correct / wrong / timeout) and response time.
9. **Als PDF exportieren** opens a PDF in German with the same content (brief + extended plans + detail table).
10. **Weiter zum Üben** lands on existing `LearningPathScreen`.
11. Edge case — everything correct, normal timing: report screen shows graceful empty state ("Keine Förderschwerpunkte erkannt — herzlichen Glückwunsch!").
12. Edge case — every question times out: all 59 questions feed into the Förderplan, still sorted, deduped, pedagogically ordered.
13. `flutter analyze` clean.

If any ambiguous CSV defect from Task 6 (especially Q21 dice decomposition) blocks correct scoring during testing, escalate before guessing.

---

## Open questions to revisit before implementation

- Slow-response threshold per question: hard-coded 15 s, or use `AnswerFormat` (single = 15 s, multiple/sort = 30 s)? Default plan: tier by AnswerFormat.
- `slowResponseFlag` threshold: 30% of correct answers slow → flag. Confirm or tune.
- Should the brief Förderplan link the 3 skills directly to their practice screens (when those exist for the practice phase)? Not required for MVP; deferring.
