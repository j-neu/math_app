# v1 Item-Quality Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the concrete, itemized defects Jakob found in the live `cleanroom-v1` diagnostic (`docs/clean-room/00-v1-assessment.md`, Anhang A) — Q7, Q11, Q15, Q17, Q18, Q20, Q22, Q23, Q26 — without touching any frozen v1 artifact.

**Architecture:** Two classes of fix. (A) Pure Dart/widget bugs (answer-field layout, missing "+", arrow direction, block colors) — fixed in place, no content change, no DB change. (B) Wording/content defects in v1 items (Q18, Q22, Q23) and coverage gaps (Q11 has no symbolic counterpart; Q26's number-line jumps straight to ZR100) — the v1 CSV/item files stay untouched (frozen); `diagnostic_service.dart`'s existing `_kSupersededByV2` exclusion set drops the three broken v1 list numbers from what a child is served, and new v2-authored replacement/supplement items are appended the same way the verdoppeln-halbieren pilot was (Phase 3a, 2026-09-11) — own CSV rows, own item files under `docs/clean-room/v2/items/`, own provenance rows, own backend migration.

**Tech Stack:** Flutter/Dart (math_app), Supabase Postgres migrations (backend), Python gate scripts (scripts/).

**Spec:** `docs/clean-room/00-v1-assessment.md` (Befunde + Anhang A) is the spec this plan implements — no separate design doc was written; Jakob's findings state their own required outcome for each item.

## Global Constraints

- **Never modify** `Research/diagnostic_core_v1.csv`, `docs/clean-room/01-construct-map.md`, `02-blueprint.md`, `docs/clean-room/items/`, `docs/clean-room/skills/`, `foerderplan/mapping-rationale.md` — frozen v1 record (Jakob decision, 2026-09-11 session).
- New v2 content lives under `docs/clean-room/v2/items/` and a new sibling CSV `math_app/Research/diagnostic_v2_item_quality_fixes.csv`, loaded by `diagnostic_service.dart` alongside the existing v2 verdoppeln-halbieren CSV.
- `provenance.csv` rows for new v2 items use `type=v2-item` (not `item`/`item-*`, which route into v1-only file-matching logic in `check_provenance.py`).
- Any change to what the child is served (add/exclude a question) requires a matching backend migration to `backend/supabase/migrations/` — the live `cleanroom-v1` bank has its own copy of every question in `diagnostic_questions`, resolved by exact `(diagnostic_id, question_number)` match in `diagnostic-results/index.ts`, and `diagnostics.question_count` gates session completion. A CSV-only change without the matching migration reproduces the exact bug fixed earlier today (child's last answer 409s as "session already completed").
- `diagnostic_id` = `00000000-0000-0000-0000-000000000002` (`cleanroom-v1`). Current live state after today's earlier migration: `question_count=64`, core tier occupies 1-59 and 92-96, deep-dive occupies 60-91, one retired row at 900.
- New question_numbers for this plan: **97-102** (six new rows; 92-96 already taken by verdoppeln-halbieren). New `question_count` after this plan: **67** (64 + 6 new − but see Task 5: three v1 items are *excluded client-side*, not deleted from the DB, so they are simply never answered going forward and must NOT be counted — 64 + 6 = 70 is WRONG; the correct arithmetic is worked in Task 8).
- Every migration follows the guarded pre/post-check pattern in `backend/supabase/migrations/20260911000000_v2_verdoppeln_halbieren_items.sql` (abort on unexpected state, verify the postcondition, never guess).
- Controller (this session) applies all `supabase db push` operations personally after reviewing Kilo's migration file — never delegate the live push itself.
- Kilo CLI subagent model: `kilo/deepseek/deepseek-v4.1-flash`, dispatched via `kilo run "<message>" -m kilo/deepseek/deepseek-v4.1-flash --auto --dir <path>`. Controller performs all task reviews personally (re-running gates/tests), not via a dispatched reviewer subagent.

---

### Task 1: Dart-only rendering fixes (batched — four independent, same-shape bugs)

**Files:**
- Modify: `math_app/lib/models/diagnostic_question.dart`
- Modify: `math_app/lib/services/answer_grading.dart`
- Modify: `math_app/lib/widgets/diagnostic_answer_widgets.dart`
- Modify: `math_app/lib/widgets/manipulatives/zahlenstrahl.dart`
- Modify: `math_app/lib/widgets/manipulatives/dienes_place_value.dart`
- Test: `math_app/test/diagnostic_answer_widgets_test.dart`, `math_app/test/answer_grading_test.dart` (create if it doesn't exist), `math_app/test/zahlenstrahl_test.dart` or existing manipulatives test file, `math_app/test/dienes_place_value_test.dart` or existing.

**Interfaces:**
- Produces: `DiagnosticAnswerMode.labeledFields` enum value; `AnswerSpec.labeledFields(List<String> labels, List<int> expectedNumbers)` constructor; `AnswerGrading.labeledFieldsLabels(DiagnosticQuestion q) -> List<String>`.
- Consumes: existing `DiagnosticAnswerMode`, `AnswerSpec`, `kAnswerSpecs` map, `_gradeSequence` (reused for grading — labeledFields and sequence compare positional int lists identically).

**Bug 1a — Q7 and Q20 render unlabeled fields for a two-part question.**

Add a new answer mode so each part of a compound question gets its own labeled row, reusing the existing positional-comparison grading logic (`_gradeSequence`) since the values are still compared as an ordered list.

In `math_app/lib/models/diagnostic_question.dart` — no changes needed (the enum lives in `answer_grading.dart`, not here — skip this file; it is listed above in error, do not modify it).

In `math_app/lib/services/answer_grading.dart`:

1. Add to `DiagnosticAnswerMode`:
```dart
  /// Several numbers, each with its own full-sentence or short label (e.g.
  /// "Zahl davor" / "Zahl danach"), one field per label, stacked as rows.
  labeledFields,
```

2. Add a new `AnswerSpec` constructor (alongside the existing ones):
```dart
  final List<String>? fieldLabels;

  const AnswerSpec.labeledFields(this.fieldLabels, this.expectedNumbers)
      : mode = DiagnosticAnswerMode.labeledFields,
        target = null,
        rows = null,
        choiceOptions = null,
        choiceAnswer = null,
        anchor = null;
```
Note: `fieldLabels` must be added as a new final field on the class (alongside `anchor` etc.), defaulting to `null` in every other constructor's initializer list — add `fieldLabels = null` to the initializer list of `.number`, `.sequence`, `.pairs`, `.choice`, `.freeText`.

3. Add to `kAnswerSpecs`:
```dart
  7: AnswerSpec.labeledFields(['Zahl davor', 'Zahl danach'], [36, 38]),
  20: AnswerSpec.labeledFields(['Zehner', 'Einer'], [5, 8]),
```
(Remove nothing — item 20 is not currently in `kAnswerSpecs`; item 7 is not currently in `kAnswerSpecs` either. Both fall back to `_modeByShape` today, which is the bug.)

4. In `grade()`'s switch, add:
```dart
      DiagnosticAnswerMode.labeledFields => _gradeSequence(input, spec, question),
```

5. In `boxCount()`'s switch, add:
```dart
      DiagnosticAnswerMode.labeledFields => spec != null && spec.fieldLabels != null ? spec.fieldLabels!.length : 1,
```
where `spec` must first be resolved inside `boxCount` via `final spec = kAnswerSpecs[q.listNumber];` — check the existing method body and add this local if not already present (it currently switches on `modeFor(q)` without a local `spec` binding; add one at the top of `boxCount`).

6. Add a new static accessor:
```dart
  /// Field labels for a `DiagnosticAnswerMode.labeledFields` item, in the
  /// same order as its expected numbers.
  static List<String> labeledFieldsLabels(DiagnosticQuestion q) =>
      kAnswerSpecs[q.listNumber]?.fieldLabels ?? const [];
```

7. In `answerFieldLabel()`, add:
```dart
      DiagnosticAnswerMode.labeledFields => 'Trage für jede Zeile die passende Zahl ein.',
```

In `math_app/lib/widgets/diagnostic_answer_widgets.dart`:

1. In `DiagnosticAnswerInput.build()`'s switch, add:
```dart
      case DiagnosticAnswerMode.labeledFields:
        return _LabeledFields(
          labels: AnswerGrading.labeledFieldsLabels(question),
          controller: controller,
          onSubmit: onSubmit,
        );
```

2. Add a new widget class (place it after `_SequenceFields`, before `_PairRows`):
```dart
/// One labeled row per expected number (e.g. "Zahl davor" / "Zahl danach",
/// or "Zehner" / "Einer") — fixes items whose question asks two distinct
/// things but rendered as unlabeled boxes (v1 assessment Q7, Q20).
/// Values are joined ", " into [controller], in label order.
class _LabeledFields extends StatefulWidget {
  final List<String> labels;
  final TextEditingController controller;
  final VoidCallback? onSubmit;

  const _LabeledFields({
    required this.labels,
    required this.controller,
    this.onSubmit,
  });

  @override
  State<_LabeledFields> createState() => _LabeledFieldsState();
}

class _LabeledFieldsState extends State<_LabeledFields> {
  late final List<TextEditingController> _fields;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _fields =
        List.generate(widget.labels.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.labels.length, (_) => FocusNode());
    for (final c in _fields) {
      c.addListener(_join);
    }
  }

  @override
  void dispose() {
    for (final c in _fields) {
      c.removeListener(_join);
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _join() {
    widget.controller.text =
        _fields.map((c) => c.text.trim()).where((t) => t.isNotEmpty).join(', ');
  }

  void _submitted(int index) {
    if (index < widget.labels.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      widget.onSubmit?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.labels.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    '${widget.labels[i]}:',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 64,
                  child: TextField(
                    controller: _fields[i],
                    focusNode: _focusNodes[i],
                    autofocus: i == 0,
                    keyboardType: TextInputType.number,
                    textInputAction: i == widget.labels.length - 1
                        ? TextInputAction.done
                        : TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: (_) => _submitted(i),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
```

**Bug 1b — Q15/Q17 decomposition rows render "8 = [box][box]" with no visible "+".**

In `math_app/lib/widgets/diagnostic_answer_widgets.dart`, inside `_PairRowsState.build()`, the row currently is:
```dart
              children: [
                Text('${widget.target} = ',
                    style: Theme.of(context).textTheme.titleLarge),
                ...List.generate(2, (col) {
```
Change to insert a "+" between the two generated fields:
```dart
              children: [
                Text('${widget.target} = ',
                    style: Theme.of(context).textTheme.titleLarge),
                ...List.generate(2, (col) {
                  final field = Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(
                      width: 64,
                      child: TextField(
                        controller: _fields[row][col],
                        focusNode: _focusNodes[row][col],
                        autofocus: row == 0 && col == 0,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onSubmitted: (_) => _submitted(row, col),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  );
                  if (col == 1) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(' + ', style: Theme.of(context).textTheme.titleLarge),
                        field,
                      ],
                    );
                  }
                  return field;
                }),
              ],
```
(This wraps the second field with a leading " + " text, producing "target = [box] + [box]". Remove the old `...List.generate(2, (col) { return Padding(...) })` block entirely and replace with the above — do not leave both.)

**Bug 1c — Q26 number-line arrow points up instead of down at the target.**

In `math_app/lib/widgets/manipulatives/zahlenstrahl.dart`, inside `ZahlenstrahlPainter.paint()`, the `arrowAt` block currently draws the stem from `baseline - 4` to `baseline - 30` and the arrowhead apex at `baseline - 38` (pointing away from the line, i.e. up). Replace the whole `if (arrowAt != null) { ... }` block with:
```dart
    if (arrowAt != null) {
      final x = xFor(arrowAt!);
      canvas.drawLine(
        Offset(x, baseline - 38),
        Offset(x, baseline - 16),
        Paint()
          ..color = Colors.red
          ..strokeWidth = 2.5,
      );
      final head = Path()
        ..moveTo(x, baseline - 4)
        ..lineTo(x - 8, baseline - 16)
        ..lineTo(x + 8, baseline - 16)
        ..close();
      canvas.drawPath(
        head,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill,
      );
    }
```
(Stem now runs from high up down to `baseline - 16`; the arrowhead's apex sits at `baseline - 4`, just above the tick mark, pointing down at it.)

**Bug 1d — Q23's "open the bundle" doesn't visually distinguish the 3 pre-existing ones from the 10 newly-opened ones.**

In `math_app/lib/widgets/manipulatives/dienes_place_value.dart`, inside `_DienesOeffnenWidgetState.build()`, the `_opened` branch currently renders all 13 units identically (default green). Replace:
```dart
    if (_opened) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 13; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  const DienesBlockWidget(type: DienesType.unit),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '13 einzelne Einer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }
```
with:
```dart
    if (_opened) {
      const openedColor = Color(0xFF1E88E5); // matches the rod's own blue
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  const DienesBlockWidget(type: DienesType.unit),
                ],
                const SizedBox(width: 16),
                for (var i = 0; i < 10; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  const DienesBlockWidget(
                      type: DienesType.unit, color: openedColor),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '13 einzelne Würfel',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }
```
(3 green pre-existing units, a visible gap, then 10 blue newly-opened units — total still 13. `DienesBlockWidget` already accepts an optional `color` override, see `math_app/lib/widgets/common/dienes_block_widget.dart:19`. Label text changed from "13 einzelne Einer" to "13 einzelne Würfel" to match the terminology fix in Task 2.)

**Steps:**
- [ ] **Step 1:** Make all four changes above.
- [ ] **Step 2:** Write/extend tests:
  - `diagnostic_answer_widgets_test.dart`: a test pumping a fixture `DiagnosticQuestion` with `listNumber: 7` through `DiagnosticAnswerInput`, entering "36" then "38" in the two fields (find by the two `TextField`s in order), and asserting the joined controller text is `"36, 38"` and `AnswerGrading.grade(userAnswer: controller.text, question: question)` is `true`. A second test for `listNumber: 20` with labels `Zehner`/`Einer`, values `5`/`8`.
  - A test for `_PairRows` (pump a `listNumber: 15` fixture, enter values into all 6 fields (3 rows × 2), assert the rendered widget tree contains a `Text` widget with data `' + '` at least 3 times — one per row).
  - A `ZahlenstrahlPainter` test (or extend existing manipulatives golden/geometry test if one exists — search `math_app/test/` for `zahlenstrahl` first): assert that for `arrowAt: 80`, the painted arrow's triangle apex y-coordinate is numerically *greater* (lower on screen, closer to the baseline) than its base y-coordinates — i.e. the tip points down. If no existing test file touches `ZahlenstrahlPainter`'s geometry, add the assertion as a plain unit test calling the painter's `paint` method against a `PictureRecorder`/`Canvas` is unnecessary — instead just assert the widget builds without error and (if a golden test harness already exists for other manipulatives) add a golden. If neither pattern exists in this codebase, skip the pixel-level assertion and note in the report why (BLOCKED is not appropriate here — a build-only smoke test is an acceptable minimum; DONE_WITH_CONCERNS is correct).
  - A test for `DienesOeffnenWidget`: pump it, tap the rod to open it, and assert the widget tree contains at least one `DienesBlockWidget` with `color == const Color(0xFF1E88E5)` (the 10 newly-opened ones) alongside ones with `color == null` (the 3 pre-existing, default-green ones) — total 13 `DienesBlockWidget` instances of `type: DienesType.unit`.
- [ ] **Step 3:** Run `flutter test test/diagnostic_answer_widgets_test.dart` (and whichever manipulatives test files you touched/created). All must pass.
- [ ] **Step 4:** Run `flutter analyze` — must stay at the pre-existing baseline (no new lints).
- [ ] **Step 5:** Commit: `git add -A && git commit -m "fix: labeled two-field answers, decomposition '+', number-line arrow direction, bundle-open colors"`.

---

### Task 2: Retire three flawed v1 items client-side, author their v2 replacements

**Files:**
- Modify: `math_app/lib/services/diagnostic_service.dart` (only the `_kSupersededByV2` set — nothing else in this file changes)
- Create: `docs/clean-room/v2/items/A3.3-repl-01.md`
- Create: `docs/clean-room/v2/items/B1.2-repl-01.md`
- Create: `docs/clean-room/v2/items/B1.3-repl-01.md`
- Modify: `docs/clean-room/provenance.csv` (append 3 rows)

**Interfaces:**
- Produces: three new item IDs (`A3.3-repl-01`, `B1.2-repl-01`, `B1.3-repl-01`) that Task 4 will wire into a new CSV at list numbers 97, 98, 99 respectively.
- Consumes: nothing new — `_kSupersededByV2` already exists in `diagnostic_service.dart` exactly for this purpose (currently an empty set).

**Why these three:** Jakob's assessment (`docs/clean-room/00-v1-assessment.md`, Anhang A) found: Q18 ("Kim kennt die Zahl 4...") carries an unmeasured decorative sentence; Q22 renders three answer fields for a single-number answer (41) when the item file itself already says only the total is required for full credit; Q23's prompt says "Stäbchen" (sticks) while the widget (since the Dienes rework) shows Dienes rods/cubes. The v1 CSV and item files are frozen, so the fix is: stop serving list numbers 18, 22, 23 (via the existing `_kSupersededByV2` exclusion set — the child never sees them, so nothing is ever answered or posted for them, and no DB retirement is needed) and serve corrected v2-authored replacements instead.

**Step 1 — exclude the three v1 items:**

In `math_app/lib/services/diagnostic_service.dart`, change:
```dart
  static const Set<int> _kSupersededByV2 = {};
```
to:
```dart
  static const Set<int> _kSupersededByV2 = {18, 22, 23};
```

**Step 2 — author the replacement item files.**

`docs/clean-room/v2/items/A3.3-repl-01.md`:
```markdown
# Item A3.3-repl-01

- **item-id:** A3.3-repl-01
- **ersetzt:** A3.3-01 (v1, ausgeschlossen via `_kSupersededByV2` in `diagnostic_service.dart` — Grund: docs/clean-room/00-v1-assessment.md Anhang A, Q18)
- **konstrukt:** A3.3 Zahlbeziehungen (Verdopplungen, Nachbarzahlen)
- **zahlenraum:** ZR10
- **darstellung:** keine (rein symbolisch/verbal)
- **prompt:** Welche Zahl ist doppelt so groß wie die 4?
- **erwartete-antwort:** 8
- **fehlersignatur:**
  - `2` — halbiert statt zu verdoppeln
  - `4` — nennt die Ausgangszahl, Zahlbeziehung nicht erfasst
  - `5` — verwechselt Verdopplung mit Nachbaraufgabe (4+1)
- **quelle:** Gaidoschik 2010; Padberg & Benz 2021
- **eigenstaendigkeit:** Identischer Zahlenwert und Grundfrage wie das ersetzte v1-Item (A3.3-01, selbst bereits als eigenständig geprüft und freigegeben), mit der Fehlerkorrektur, dass der v1-Vorspann "Kim kennt die Zahl 4." als unmessbares Beiwerk entfernt wurde (Jakob, 2026-09-11). Kein neuer Bezug zu einer dritten Quelle nötig, da nur die redaktionelle Reduktion des bereits geprüften Wortlauts erfolgt.
- **reviewer:** —
```

`docs/clean-room/v2/items/B1.2-repl-01.md`:
```markdown
# Item B1.2-repl-01

- **item-id:** B1.2-repl-01
- **ersetzt:** B1.2-02 (v1, ausgeschlossen via `_kSupersededByV2` — Grund: docs/clean-room/00-v1-assessment.md Anhang A, Q22: "Drei Antwortfelder, obwohl die Antwort 41 ist. Es darf genau ein Feld geben.")
- **konstrukt:** B1.2 Bündelung von Einzelobjekten zu Zehnern
- **zahlenraum:** ZR100
- **darstellung:** 3 Zehnerstangen + 11 einzelne Würfel (Dienes-Material, sichtbare Lücke zwischen den Gruppen)
- **darstellung-konfiguration:** `DienesPlaceValueWidget(tens: 3, ones: 11)`
- **prompt:** Wie viel ist das insgesamt?
- **erwartete-antwort:** 41
- **fehlersignatur:**
  - `311` — hält an der Oberflächendarstellung fest (3 Zehner, 11 Einer als Ziffernfolge gelesen), keine Überbündelung
  - `31` — wertet die 11 Einer fälschlich als "1 Einer"
  - `14` — zählt alle sichtbaren Teile als Einer (3 + 11), ignoriert den Zehnerwert der Bündel
- **quelle:** Schipper 2009; Moser Opitz 2013
- **eigenstaendigkeit:** Gleiche Zahlenwahl (41 = 3 Zehner + 11 Einer) und Anordnung wie das ersetzte v1-Item (B1.2-02, selbst bereits als eigenständig geprüft und freigegeben); die zweite Teilfrage ("und wenn du neu bündelst...") wurde gestrichen, weil sie ein zweites Antwortfeld für dieselbe Aufgabe erzwang (Ein-Item-eine-Antwort-Regel, Jakob 2026-09-11) und die Entbündelungs-Kompetenz bereits eigenständig durch B1.3-repl-01 geprüft wird.
- **reviewer:** —
```

`docs/clean-room/v2/items/B1.3-repl-01.md`:
```markdown
# Item B1.3-repl-01

- **item-id:** B1.3-repl-01
- **ersetzt:** B1.3-01 (v1, ausgeschlossen via `_kSupersededByV2` — Grund: docs/clean-room/00-v1-assessment.md Anhang A, Q23: Prompt spricht von "Stäbchen", Darstellung zeigt seit der Dienes-Umstellung Würfel/Stangen.)
- **konstrukt:** B1.3 Entbündelung eines Zehners
- **zahlenraum:** ZR100
- **darstellung:** 1 Zehnerstange + 3 einzelne Würfel; Tippen auf die Stange öffnet sie in 10 einzelne (blaue) Würfel neben den 3 vorhandenen (grünen) Würfeln
- **darstellung-konfiguration:** `DienesOeffnenWidget` (interaktiv)
- **prompt:** Öffne die Zehnerstange. Wie viele einzelne Würfel hast du dann?
- **erwartete-antwort:** 13
- **fehlersignatur:**
  - `10` — fasst die Entbündelung als reinen Tausch auf, vergisst die bereits vorhandenen 3 Würfel (Mengenerhaltung nicht gesichert)
  - `3` — zählt nur die ungebündelten Würfel, übergeht die Stange vollständig
- **quelle:** Schipper 2009; Rahmenlehrplan BE/BB 2023 Teil C; Moser Opitz 2013
- **eigenstaendigkeit:** Gleiche Zahlenwahl (13 = 1 Zehner + 3 Einer) und Interaktion wie das ersetzte v1-Item (B1.3-01, selbst bereits als eigenständig geprüft und freigegeben); nur die Wortwahl wurde von "Stäbchen" auf "Zehnerstange"/"Würfel" korrigiert, damit Prompt und Darstellung übereinstimmen (Jakob 2026-09-11).
- **reviewer:** —
```

**Step 3 — provenance rows.** Append to `docs/clean-room/provenance.csv` (same 8-column format as the existing rows — `artifact_id,type,author,created,sources_cited,reviewed_by,reviewed_on,independent_of`):
```
A3.3-repl-01,v2-item,Claude (draft),2026-09-11,"Gaidoschik 2010; Padberg & Benz 2021",,,"Reduktion des geprüften v1-Wortlauts (A3.3-01) um unmessbares Beiwerk; keine neue Quelle nötig."
B1.2-repl-01,v2-item,Claude (draft),2026-09-11,"Schipper 2009; Moser Opitz 2013",,,"Gleiche Zahlenwahl wie das geprüfte v1-Item (B1.2-02), zweite Teilfrage gestrichen (Ein-Item-eine-Antwort)."
B1.3-repl-01,v2-item,Claude (draft),2026-09-11,"Schipper 2009; Rahmenlehrplan BE/BB 2023 Teil C; Moser Opitz 2013",,,"Gleiche Zahlenwahl wie das geprüfte v1-Item (B1.3-01), Wortwahl auf Dienes-Material korrigiert."
```

**Steps:**
- [ ] **Step 1:** Change `_kSupersededByV2` as shown above.
- [ ] **Step 2:** Create the three item files exactly as given above.
- [ ] **Step 3:** Append the three provenance rows exactly as given above.
- [ ] **Step 4:** Run `python scripts/check_provenance.py` (non-strict) from the repo root — must print `OK`.
- [ ] **Step 5:** Run `flutter test test/diagnostic_service_test.dart` — the existing "loadQuestions merges the v2 CSV and excludes superseded v1 rows" test (if that's its exact name; if a differently-named test already covers `_kSupersededByV2`, it should now start asserting something — check `math_app/test/diagnostic_service_test.dart` for any test referencing `_kSupersededByV2` or "superseded" and update its expected exclusion set to `{18, 22, 23}` if it hardcodes the empty set today). If no such test exists yet, add one: load questions, assert `questions.every((q) => ![18, 22, 23].contains(q.listNumber))`.
- [ ] **Step 6:** Commit: `git add -A && git commit -m "content(v2): exclude 3 flawed v1 items client-side, author v2 replacements"`.

---

### Task 3: Author two coverage-gap supplements (A2.3 symbolic counterpart, B2.2 number-range ladder)

**Files:**
- Create: `docs/clean-room/v2/items/A2.3-repl-01.md`
- Create: `docs/clean-room/v2/items/B2.2-repl-01.md`
- Create: `docs/clean-room/v2/items/B2.2-repl-02.md`
- Modify: `docs/clean-room/provenance.csv` (append 3 rows)

**Interfaces:**
- Produces: three new item IDs (`A2.3-repl-01`, `B2.2-repl-01`, `B2.2-repl-02`) that Task 4 wires into the new CSV at list numbers 100, 101, 102.
- Consumes: nothing.

**Why:** Q11 (A2.3, quantity comparison) is purely iconic with no symbolic counterpart (assessment: "Es fehlt die symbolische Entsprechung — der Strang endet auf der Bildebene"). Q26 (B2.2, number line) jumps straight to a 0-100 line with no 0-10/0-20 step (assessment: "der Sprung direkt auf 0–100 ist für diese Altersgruppe zu groß: es braucht erst 0–10, dann 0–20, dann 0–100"). These are additions, not replacements — nothing is excluded.

`docs/clean-room/v2/items/A2.3-repl-01.md`:
```markdown
# Item A2.3-repl-01

- **item-id:** A2.3-repl-01
- **ergaenzt:** A2.3-01 (v1, bleibt bestehen — dieses Item liefert die fehlende symbolische Entsprechung, siehe docs/clean-room/00-v1-assessment.md Anhang A, Q11)
- **konstrukt:** A2.3 Mengen vergleichen
- **zahlenraum:** ZR10
- **darstellung:** keine (rein symbolisch — zwei Ziffern, kein Zehnerfeld)
- **prompt:** Welche Zahl ist größer: 6 oder 8?
- **erwartete-antwort:** 8
- **fehlersignatur:**
  - `6` — nennt die zuerst genannte oder kleinere Zahl; Vergleichsrichtung nicht gesichert
- **quelle:** Rahmenlehrplan BE/BB Teil C; Krajewski, Anzahlerfassung strukturierter Mengen (Übertrag auf symbolische Vergleiche)
- **eigenstaendigkeit:** Eigenes Zahlenpaar (6/8, abweichend von A2.3-01s Zehnerfeld-Werten) und eigene, rein symbolische Aufgabenform ohne visuelle Stütze; kein bestehendes Instrument als Vorlage.
- **reviewer:** —
```

`docs/clean-room/v2/items/B2.2-repl-01.md`:
```markdown
# Item B2.2-repl-01

- **item-id:** B2.2-repl-01
- **ergaenzt:** B2.2-01 (v1, bleibt bestehen — dieses Item liefert die fehlende ZR10-Stufe vor dem direkten Sprung auf ZR100, siehe docs/clean-room/00-v1-assessment.md Anhang A, Q26)
- **konstrukt:** B2.2 Zahlen am Zahlenstrahl verorten
- **zahlenraum:** ZR10
- **darstellung:** Zahlenstrahl 0–10, Anker bei 0/5/10, Pfeil zeigt auf eine Position
- **darstellung-konfiguration:** neue Variante von `ZahlenstrahlArrowWidget` mit Skalenende 10 statt 100 (siehe Task 4/5 für den Parameter)
- **prompt:** Auf welche Zahl zeigt der Pfeil?
- **erwartete-antwort:** 7
- **fehlersignatur:**
  - `6` — ±1 nach unten
  - `8` — ±1 nach oben
- **quelle:** Rahmenlehrplan BE/BB Teil C; Schipper, Handbuch (Zahlenstrahl als Modell)
- **eigenstaendigkeit:** Eigener Zielwert (7) und eigener Zahlenraum (0–10) gegenüber B2.2-01 (0–100, Zielwert 80); eigenständige Anordnung, kein bestehendes Instrument als Vorlage.
- **reviewer:** —
```

`docs/clean-room/v2/items/B2.2-repl-02.md`:
```markdown
# Item B2.2-repl-02

- **item-id:** B2.2-repl-02
- **ergaenzt:** B2.2-01 (v1, bleibt bestehen — ZR20-Zwischenstufe, siehe docs/clean-room/00-v1-assessment.md Anhang A, Q26)
- **konstrukt:** B2.2 Zahlen am Zahlenstrahl verorten
- **zahlenraum:** ZR20
- **darstellung:** Zahlenstrahl 0–20, Anker bei 0/10/20, Pfeil zeigt auf eine Position
- **darstellung-konfiguration:** neue Variante von `ZahlenstrahlArrowWidget` mit Skalenende 20
- **prompt:** Auf welche Zahl zeigt der Pfeil?
- **erwartete-antwort:** 14
- **fehlersignatur:**
  - `13` — ±1 nach unten, am Zehnerübergang
  - `15` — ±1 nach oben, am Zehnerübergang
- **quelle:** Rahmenlehrplan BE/BB Teil C; Schipper, Handbuch
- **eigenstaendigkeit:** Eigener Zielwert (14) und eigener Zahlenraum (0–20) gegenüber B2.2-01 und B2.2-repl-01; eigenständige Anordnung, kein bestehendes Instrument als Vorlage.
- **reviewer:** —
```

Append to `docs/clean-room/provenance.csv`:
```
A2.3-repl-01,v2-item,Claude (draft),2026-09-11,"Rahmenlehrplan BE/BB Teil C; Krajewski, Anzahlerfassung strukturierter Mengen",,,"Eigenes Zahlenpaar (6/8) und rein symbolische Aufgabenform; kein bestehendes Instrument als Vorlage."
B2.2-repl-01,v2-item,Claude (draft),2026-09-11,"Rahmenlehrplan BE/BB Teil C; Schipper, Handbuch",,,"Eigener Zielwert (7) im ZR10; kein bestehendes Instrument als Vorlage."
B2.2-repl-02,v2-item,Claude (draft),2026-09-11,"Rahmenlehrplan BE/BB Teil C; Schipper, Handbuch",,,"Eigener Zielwert (14) im ZR20; kein bestehendes Instrument als Vorlage."
```

**Steps:**
- [ ] **Step 1:** Create the three item files exactly as given above.
- [ ] **Step 2:** Append the three provenance rows exactly as given above.
- [ ] **Step 3:** Run `python scripts/check_provenance.py` — must print `OK`.
- [ ] **Step 4:** Commit: `git add -A && git commit -m "content(v2): symbolic quantity-comparison item + ZR10/ZR20 number-line ladder"`.

---

### Task 4: New ZR10/ZR20 number-line widget parameter + CSV/registry wiring

**Files:**
- Modify: `math_app/lib/widgets/manipulatives/zahlenstrahl.dart`
- Modify: `math_app/lib/screens/diagnostic_screen.dart` (the `buildVisualDisplay` switch)
- Create: `math_app/Research/diagnostic_v2_item_quality_fixes.csv`
- Modify: `math_app/lib/services/diagnostic_service.dart` (`loadQuestions`, to also load the new CSV)
- Modify: `math_app/pubspec.yaml` (register the new CSV asset)
- Test: `math_app/test/diagnostic_service_test.dart`

**Interfaces:**
- Consumes: item content from Task 2 and Task 3 (exact prompts/answers/list numbers below).
- Produces: `ZahlenstrahlArrowWidget` gains a `scaleMax` parameter (default 100, preserving every existing call site); `buildVisualDisplay` gains two new `case` arms; `diagnostic_service.dart` loads a third CSV.

**Step 1 — generalize `ZahlenstrahlArrowWidget` to a configurable scale.**

In `math_app/lib/widgets/manipulatives/zahlenstrahl.dart`, `ZahlenstrahlPainter.paint()` currently hardcodes `v / 100.0` in `xFor`. Add a `scaleMax` field to the painter and thread it through:
```dart
class ZahlenstrahlPainter extends CustomPainter {
  final double? arrowAt;
  final double? markAt;
  final Set<int> majorTicks;
  final Set<int> minorTicks;
  final Map<int, String> labels;
  final double scaleMax;

  const ZahlenstrahlPainter({
    this.arrowAt,
    this.markAt,
    this.majorTicks = const {},
    this.minorTicks = const {},
    this.labels = const {},
    this.scaleMax = 100,
  });
```
and change `xFor`:
```dart
    double xFor(num v) => left + (right - left) * (v / scaleMax);
```
Then update `ZahlenstrahlArrowWidget` to accept and forward a `scaleMax`:
```dart
class ZahlenstrahlArrowWidget extends StatelessWidget {
  final int value;
  final int scaleMax;

  const ZahlenstrahlArrowWidget({required this.value, this.scaleMax = 100});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      height: 110,
      child: CustomPaint(
        painter: ZahlenstrahlPainter(
          arrowAt: value.toDouble(),
          scaleMax: scaleMax.toDouble(),
          majorTicks: {for (var v = 0; v <= scaleMax; v += scaleMax ~/ 10) v},
          labels: {0: '0', scaleMax ~/ 2: '${scaleMax ~/ 2}', scaleMax: '$scaleMax'},
        ),
      ),
    );
  }
}
```
Leave `ZahlenstrahlMarkWidget` untouched (DDB-05 is unaffected by this plan). Every existing caller of `ZahlenstrahlArrowWidget` (there is exactly one, `case 'B2.2-01':` in `diagnostic_screen.dart`) keeps compiling unchanged because `scaleMax` defaults to 100.

**Step 2 — new `buildVisualDisplay` cases.**

In `math_app/lib/screens/diagnostic_screen.dart`, in the `buildVisualDisplay` switch, add two new cases alongside the existing `case 'B2.2-01':`:
```dart
    // B2.2-repl-01 — Zahlenstrahl 0–10, arrow at 7 (v2 ZR10 ladder rung).
    case 'B2.2-repl-01':
      return const ZahlenstrahlArrowWidget(value: 7, scaleMax: 10);
    // B2.2-repl-02 — Zahlenstrahl 0–20, arrow at 14 (v2 ZR20 ladder rung).
    case 'B2.2-repl-02':
      return const ZahlenstrahlArrowWidget(value: 14, scaleMax: 20);
```

**Step 3 — new CSV.** Create `math_app/Research/diagnostic_v2_item_quality_fixes.csv` (same 14-column header as every other diagnostic CSV):
```csv
ListNumber,SourceType,QuestionText,AnswerFormat,CorrectAnswer,German,English,IfWrong_practice_skills,Ifwrong_skip,Notes,SkipGroup,Zahlenraum,AudioAsset,Hilfetext
97,Text,"Welche Zahl ist doppelt so groß wie die 4?",Single,8,"Welche Zahl ist doppelt so groß wie die 4?",Which number is twice as large as 4?,"A3.3, A3.1",,easy; A3.3 Zahlbeziehungen (Verdopplungen) -- v2-Ersatz fuer A3.3-01 (Beiwerk entfernt),,ZR10,,
98,Image,B1.2-repl-01,Single,41,"Wie viel ist das insgesamt?",How much is this altogether?,"B1.2, B1.3, B2.3",,hard; B1.2 Buendelung -- v2-Ersatz fuer B1.2-02 (ein Feld statt drei),,ZR100,,"Hier liegen 3 Zehnerstangen und 11 einzelne Wuerfel."
99,Image,B1.3-repl-01,Single,13,"Öffne die Zehnerstange. Wie viele einzelne Würfel hast du dann?","Open the ten-rod. How many single cubes do you have then?","B1.3, B1.1, B2.3",,medium; B1.3 Entbuendelung -- v2-Ersatz fuer B1.3-01 (Wortwahl korrigiert),,ZR100,,"Hier liegen 13 Wuerfel: eine Zehnerstange und 3 einzelne Wuerfel."
100,Text,"Welche Zahl ist größer: 6 oder 8?",Single,8,"Welche Zahl ist größer: 6 oder 8?",Which number is larger: 6 or 8?,"A2.3, A2.2",,medium; A2.3 Anzahlvergleich -- symbolische Entsprechung zu A2.3-01,,ZR10,,
101,Image,B2.2-repl-01,Single,7,"Auf welche Zahl zeigt der Pfeil?","What number does the arrow point to?","B2.2, B1.1, A1.5",,easy; B2.2 Zahlenstrahl -- ZR10-Stufe vor B2.2-01,,ZR10,,
102,Image,B2.2-repl-02,Single,14,"Auf welche Zahl zeigt der Pfeil?","What number does the arrow point to?","B2.2, B1.1, A1.5",,medium; B2.2 Zahlenstrahl -- ZR20-Stufe vor B2.2-01,,ZR20,,
```
(Rows 98/99/101/102 use `SourceType=Image` with `QuestionText` set to the item ID — this is the existing convention `buildVisualDisplay` and `DiagnosticQuestion` parsing already use, matching e.g. `A2.1-01`/`B2.2-01` in the v1 CSV. Row 98/99's `QuestionText` values `B1.2-repl-01`/`B1.3-repl-01` must exactly match the case labels used in Step 2 of this task if you add visual cases for them — **check first**: these two reuse the *existing* `DienesPlaceValueWidget`/`DienesOeffnenWidget` cases keyed by `B1.2-02`/`B1.3-01` in the current switch — since those keys won't match the new `QuestionText` values, you must ALSO add two new cases reusing the same widgets:
```dart
    case 'B1.2-repl-01':
      return const DienesPlaceValueWidget(tens: 3, ones: 11);
    case 'B1.3-repl-01':
      return const DienesOeffnenWidget();
```
Add these alongside the two Zahlenstrahl cases from Step 2, in the same switch in `diagnostic_screen.dart`.)

**Step 4 — wire the new CSV into `loadQuestions()`.** In `math_app/lib/services/diagnostic_service.dart`:
```dart
  Future<List<DiagnosticQuestion>> loadQuestions() async {
    final coreCsv = await rootBundle.loadString('Research/diagnostic_core_v1.csv');
    final coreQuestions = loadQuestionsFromCsv(coreCsv)
        .where((q) => !_kSupersededByV2.contains(q.listNumber))
        .toList();
    final v2Csv = await rootBundle.loadString('Research/diagnostic_v2_verdoppeln_halbieren.csv');
    final v2Questions = loadQuestionsFromCsv(v2Csv);
    final v2FixesCsv = await rootBundle.loadString('Research/diagnostic_v2_item_quality_fixes.csv');
    final v2FixesQuestions = loadQuestionsFromCsv(v2FixesCsv);
    return [...coreQuestions, ...v2Questions, ...v2FixesQuestions];
  }
```

**Step 5 — register the asset.** In `math_app/pubspec.yaml`, in the `flutter: assets:` list, add a line `- Research/diagnostic_v2_item_quality_fixes.csv` immediately after the existing `- Research/diagnostic_v2_verdoppeln_halbieren.csv` line.

**Steps:**
- [ ] **Step 1:** Make the `zahlenstrahl.dart` change (Step 1 above).
- [ ] **Step 2:** Make the `diagnostic_screen.dart` changes (Step 2 above — four new case arms total: two Zahlenstrahl, two Dienes-reuse).
- [ ] **Step 3:** Create the CSV exactly as given (Step 3 above).
- [ ] **Step 4:** Make the `diagnostic_service.dart` change (Step 4 above).
- [ ] **Step 5:** Make the `pubspec.yaml` change (Step 5 above).
- [ ] **Step 6:** Extend `math_app/test/diagnostic_service_test.dart`: add a test loading questions and asserting a question with `ifWrongPracticeSkills.contains('A3.3')` has `correctAnswer == '8'` and german text NOT containing `'Kim'`; a question with `ifWrongPracticeSkills.contains('B1.2')` has `correctAnswer == '41'`; a question with `questionText == 'B2.2-repl-02'` exists with `zahlenraum == 'ZR20'`.
- [ ] **Step 7:** Run `flutter test test/diagnostic_service_test.dart` — must pass.
- [ ] **Step 8:** Run `flutter analyze` — must stay at baseline.
- [ ] **Step 9:** Commit: `git add -A && git commit -m "feat(v2): wire item-quality-fix items into the runtime diagnostic"`.

---

### Task 5: Full gate suite, backend migration, live verification (controller-run — not delegated to Kilo)

This task is run by the controller directly, not dispatched to Kilo, because it ends in a live-database push (standing constraint: controller applies all `supabase db push` operations personally).

- [ ] **Step 1:** Run the full gate suite from repo root: `python scripts/check_deckung.py`, `python scripts/check_provenance.py`, `python scripts/check_provenance.py --all` (expect the 6 new items to show as pending review — same status as the verdoppeln-halbieren items already carry; this is expected, not a failure).
- [ ] **Step 2:** Run `flutter test` (full suite) in `math_app/` — must be 100% green.
- [ ] **Step 3:** Write `backend/supabase/migrations/20260911000001_v2_item_quality_fixes.sql`, following the exact guarded pattern of `20260911000000_v2_verdoppeln_halbieren_items.sql`: pre-check `question_count = 64` and that `question_number` 97-102 are all free, insert 6 rows (97-102, tier='core', prompt/answer content exactly matching the CSV in Task 4 Step 3 — note `correct_answer` is `'"41"'::jsonb` / `'"13"'::jsonb` / etc., a JSON string, not `'"41 Stäbchen..."'` prose), then `update diagnostics set question_count = 70, version = version + 1` — **verify this arithmetic before writing the migration**: current live `question_count` is 64 (59 v1 core minus nothing yet excluded, since exclusion is client-side only and does not change what the DB has been asked to count — re-derive carefully: the DB's `question_count` must equal exactly how many questions `loadQuestions()` now returns and the client will submit answers for. `loadQuestions()` returns: 59 v1 core rows MINUS the 3 excluded (18, 22, 23) = 56, PLUS 5 verdoppeln-halbieren (92-96) PLUS 6 new item-quality-fix rows (97-102) = 56 + 5 + 6 = **67**. Use `question_count = 67`, not 64 and not 70 — this is the exact bug class fixed earlier today; get the arithmetic right by counting what `loadQuestions()` actually returns, not by incrementing the previous value.
- [ ] **Step 4:** Post-check block in the same migration: assert `count(*) where tier='core' between 97 and 102` = 6, and `question_count = 67`.
- [ ] **Step 5:** `supabase db push --linked --dry-run` from `backend/` — confirm only this one migration is pending.
- [ ] **Step 6:** `supabase db push --linked` — apply it.
- [ ] **Step 7:** Verify live via REST: `diagnostics?slug=eq.cleanroom-v1&select=version,question_count` shows `question_count: 67`; `diagnostic_questions?question_number=gte.97&question_number=lte.102` returns 6 rows with the expected `prompt_de`/`correct_answer`.
- [ ] **Step 8:** Restart the local Flutter dev server (kill whatever is bound to port 8080 first, then `flutter run -d web-server --web-port 8080 --web-hostname 127.0.0.1` in the background) and ask Jakob to re-run the full diagnostic end to end, confirming: Q7 and Q20 show labeled rows; Q15/Q17 show a visible "+"; Q18/Q22/Q23 no longer appear (replaced by the new wording); the new symbolic 6-vs-8 item and the two number-line ladder rungs appear; Q26's arrow points down; the session completes and saves without the "Deine Antwort konnte noch nicht gespeichert werden" error.
