# Deckungsmatrix (Phase 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Deckungsmatrix — the root artifact of the v2 content rework — together with the machine gate that makes a missing construct impossible to overlook, and an inventory of the existing hand-built exercises so every matrix cell knows what child-facing content already exists.

**Architecture:** One human-readable, human-signed Markdown file (`docs/clean-room/v2/10-deckungsmatrix.md`) is the single source of truth — there is no generated sibling, because v1's worst mechanical bugs were derived artifacts drifting from their sources. A stdlib Python checker (`scripts/check_deckung.py`) parses that file directly and enforces eight rules. A second script extracts the old Dart exercise catalogue into a CSV inventory the checker cross-references.

**Tech Stack:** Python 3.12 stdlib only (no pyyaml, no pytest — matching the existing `scripts/check_*.py` convention). Tests use stdlib `unittest`. The matrix and all content artifacts are German; the scripts print German pass/fail messages like their siblings.

**Spec:** `docs/superpowers/specs/2026-09-07-diagnostik-v2-design.md`

## Global Constraints

- **Python stdlib only.** No third-party imports in `scripts/`. Matches `check_provenance.py`, `check_mapping.py`, `check_item_independence.py`, `check_specs.py`, `check_skill_descriptions.py`.
- **Checker contract:** exit `0` on success printing a German `OK: …` line; exit `1` on failure printing one `FAIL: …` line per problem. Module docstring names the spec section it enforces.
- **No characters outside cp1252 in script output.** The Windows console this repo is developed on is cp1252: umlauts, `×` (U+00D7), `–` (U+2013) and `—` (U+2014) are fine, but an arrow `→` (U+2192) crashes the script on print. Use `->`. (Found the hard way in Task 1.)
- **German** for the matrix, all content artifacts, and script output. Code identifiers and file names stay ASCII (`uebung`, not `übung`, in Python identifiers; the Markdown field label *is* `übung`).
- **Never commit, push or deploy without Jakob's explicit authorization for that specific action.** The commit steps below are written out but are **gated**: run them only after he says so in that session. A push to `main` auto-deploys the child client.
- **Do not open `_sources_private/`.** The single exception is the one-directional iMINT coverage audit, which is Phase 6, not this plan.
- **Do not modify any v1 artifact.** `docs/clean-room/01-construct-map.md`, `02-blueprint.md`, `items/`, `skills/`, `foerderplan/mapping-rationale.md` and both runtime CSVs are frozen records.
- **Vocabulary is closed.** Strand IDs, Zahlenräume (`ZR10`, `ZR20`, `ZR100`) and Repräsentationen (`enaktiv`, `ikonisch`, `symbolisch`) come from the `## Vokabular` section; anything else is a hard failure, so a typo can never create a phantom cell.
- **Cell status values:** `offen`, `entworfen`, `freigegeben`, `–` (U+2013 en dash = bewusst nicht abgedeckt).

---

## File Structure

| File | Responsibility |
|---|---|
| `scripts/extract_exercise_inventory.py` | Parse `math_app/lib/services/exercise_service.dart` → inventory CSV. Knows Dart source shape; nothing else does. |
| `docs/clean-room/v2/inventory_uebungen.csv` | Generated. `exercise_id,title,widget_class,skill_tags,level_widgets`. Read by the checker and by humans authoring cells. |
| `docs/clean-room/v2/10-deckungsmatrix.md` | The matrix. Hand-authored, hand-signed, machine-checked. Single source of truth. |
| `scripts/check_deckung.py` | Parse + validate the matrix. Rules R1–R8. |
| `scripts/tests/test_extract_exercise_inventory.py` | Unit tests for the Dart parser. |
| `scripts/tests/test_check_deckung.py` | Unit tests for parsing and each validation rule. |
| `docs/clean-room/v2/README.md` | What lives in the v2 tree, which gates run, in what order. |

### Matrix file format (authoritative — Tasks 2–5 all depend on it)

````markdown
## Vokabular

**Stränge:**
- `zaehlen-vorwaerts` — Vorwärtszählen von beliebigem Startpunkt
- `verdoppeln-halbieren` — Verdoppeln und Halbieren als abrufbare Beziehung

**Zahlenräume:** ZR10 · ZR20 · ZR100
**Repräsentationen:** enaktiv · ikonisch · symbolisch
**Status:** offen · entworfen · freigegeben · – (bewusst nicht abgedeckt)

## Strang: verdoppeln-halbieren

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | offen |
| ZR20 | offen | offen | offen |
| ZR100 | – | offen | offen |

**Ausnahmen:**
- `verdoppeln-halbieren × ZR100 × enaktiv` — Die Verdopplung im Hunderterraum wird über Zehnerstrukturen gedacht, nicht handelnd gelegt; das enaktive Signal liefert bereits ZR20.

### verdoppeln-halbieren × ZR100 × symbolisch

- **quelle:** RLP BE/BB Teil C, Zahlen und Operationen; Padberg/Benz 2021 (Kap. n.n.)
- **fehlerbild:** Kind rechnet 25+25 stellenweise neu aus, statt die Verdopplung abzurufen — lange Latenz, keine Verdopplungsnennung
- **diagnostik:** —
- **übung:** S3.6
````

Rules the format encodes:

- **Status lives only in the table.** Detail blocks never repeat it, so the two can never disagree.
- **Every non-`–` cell has exactly one detail block**; every `–` cell has exactly one `Ausnahmen:` line.
- `—` (em dash) in `diagnostik:` / `übung:` means "noch nichts zugeordnet" and is legal while a cell is `offen` or `entworfen`; a `freigegeben` cell must name at least one of each.

---

## Task 1: Exercise inventory extractor

**Files:**
- Create: `scripts/extract_exercise_inventory.py`
- Create: `scripts/tests/test_extract_exercise_inventory.py`
- Generates: `docs/clean-room/v2/inventory_uebungen.csv`
- Reads: `math_app/lib/services/exercise_service.dart` (read-only, never modified)

**Interfaces:**
- Consumes: nothing.
- Produces: `parse_exercises(dart_source: str) -> list[dict]` with keys `exercise_id`, `title`, `widget_class`, `skill_tags` (list[str]); `main()` writing the CSV with header `exercise_id,title,widget_class,skill_tags,level_widgets`.

**Why the parser keys on indentation:** in `exercise_service.dart` a top-level entry starts with exactly four spaces (`    Exercise(`), while nested `ExerciseConfig(` blocks repeat `id:`, `title:` and `skillTags:` at deeper indentation. Splitting on the four-space marker and taking the *first* occurrence of each field inside a chunk therefore yields the top-level values and ignores the nested duplicates (see `S1.2`, `S1.4`, `S2.3`, which all have nested configs).

- [ ] **Step 1: Write the failing test**

Create `scripts/tests/test_extract_exercise_inventory.py`:

```python
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from extract_exercise_inventory import parse_exercises

SAMPLE = """\
class ExerciseService {
  final List<Exercise> _allExercises = [
    Exercise(
      id: 'C1.1',
      title: 'Count the Dots',
      skillTags: ['counting_1'],
      exerciseBuilder: (userProfile) => CountDotsExerciseV2(userProfile: userProfile),
    ),
    Exercise(
      id: 'S1.2',
      title: 'Finger Klappen',
      skillTags: ['basic_strategy_2'],
      exerciseBuilder: (userProfile) => FingerCalculationExercise(
        exerciseConfig: ExerciseConfig(
          id: 'S1.2-nested',
          title: 'Nested Should Be Ignored',
          skillTags: ['ignore_me'],
        ),
        userProfile: userProfile,
      ),
    ),
    Exercise(
      id: 'S3.6',
      title: 'Zehner verdoppeln',
      skillTags: ['strategy_doubling_tens_1', 'basic_strategy_11'],
      exerciseBuilder: (userProfile) => DoublingTensExercise(userProfile: userProfile),
    ),
  ];
}
"""


class ParseExercisesTest(unittest.TestCase):
    def test_finds_every_top_level_exercise(self):
        rows = parse_exercises(SAMPLE)
        self.assertEqual([r["exercise_id"] for r in rows], ["C1.1", "S1.2", "S3.6"])

    def test_ignores_nested_exercise_config(self):
        rows = parse_exercises(SAMPLE)
        s12 = next(r for r in rows if r["exercise_id"] == "S1.2")
        self.assertEqual(s12["title"], "Finger Klappen")
        self.assertEqual(s12["skill_tags"], ["basic_strategy_2"])

    def test_captures_widget_class_and_multiple_tags(self):
        rows = parse_exercises(SAMPLE)
        s36 = next(r for r in rows if r["exercise_id"] == "S3.6")
        self.assertEqual(s36["widget_class"], "DoublingTensExercise")
        self.assertEqual(s36["skill_tags"], ["strategy_doubling_tens_1", "basic_strategy_11"])


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `python -m unittest scripts.tests.test_extract_exercise_inventory -v` from the repo root.
Expected: FAIL — `ModuleNotFoundError: No module named 'extract_exercise_inventory'`.

- [ ] **Step 3: Write the minimal implementation**

Create `scripts/extract_exercise_inventory.py`:

```python
#!/usr/bin/env python3
"""Extrahiert den handgebauten Übungskatalog als Inventar für die Deckungsmatrix (v2-Entwurf §4).

Liest math_app/lib/services/exercise_service.dart (nur lesend) und schreibt
docs/clean-room/v2/inventory_uebungen.csv. Das Inventar sagt je Matrixzelle,
welches kindseitige Material bereits existiert.

Exit 0 wenn geschrieben, Exit 1 bei Parse-Problemen.
"""

import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DART = ROOT / "math_app" / "lib" / "services" / "exercise_service.dart"
EXERCISES_DIR = ROOT / "math_app" / "lib" / "exercises"
OUT = ROOT / "docs" / "clean-room" / "v2" / "inventory_uebungen.csv"

TOP_LEVEL = re.compile(r"^    Exercise\($", re.MULTILINE)
ID_RE = re.compile(r"^\s*id:\s*'([^']+)'", re.MULTILINE)
TITLE_RE = re.compile(r"^\s*title:\s*'([^']+)'", re.MULTILINE)
TAGS_RE = re.compile(r"^\s*skillTags:\s*\[([^\]]*)\]", re.MULTILINE | re.DOTALL)
WIDGET_RE = re.compile(r"=>\s*(\w+)\(")


def parse_exercises(source):
    """Return one dict per top-level Exercise( entry, nested configs ignored."""
    rows = []
    chunks = TOP_LEVEL.split(source)[1:]
    for chunk in chunks:
        id_m = ID_RE.search(chunk)
        title_m = TITLE_RE.search(chunk)
        if not id_m or not title_m:
            continue
        tags = []
        tags_m = TAGS_RE.search(chunk)
        if tags_m:
            tags = [t.strip().strip("'") for t in tags_m.group(1).split(",") if t.strip()]
        widget_m = WIDGET_RE.search(chunk)
        rows.append({
            "exercise_id": id_m.group(1),
            "title": title_m.group(1),
            "widget_class": widget_m.group(1) if widget_m else "",
            "skill_tags": tags,
        })
    return rows


def level_widgets_for(widget_class):
    """Count the level widgets a coordinator imports — the scaffolding already built."""
    if not widget_class:
        return 0
    snake = re.sub(r"(?<!^)(?=[A-Z])", "_", widget_class).lower()
    candidates = [p for p in EXERCISES_DIR.glob("*.dart") if p.stem in (snake, snake.replace("_exercise", "") + "_exercise")]
    if not candidates:
        candidates = [p for p in EXERCISES_DIR.glob("*.dart") if widget_class in p.read_text(encoding="utf-8")[:4000]]
    seen = set()
    for path in candidates[:1]:
        for m in re.finditer(r"^import '\.\./widgets/([^']+)';", path.read_text(encoding="utf-8"), re.MULTILINE):
            seen.add(m.group(1))
    return len(seen)


def main():
    if not DART.exists():
        print(f"FAIL: {DART} nicht gefunden")
        sys.exit(1)
    rows = parse_exercises(DART.read_text(encoding="utf-8"))
    if not rows:
        print("FAIL: keine Exercise-Einträge gefunden — hat sich die Dart-Struktur geändert?")
        sys.exit(1)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerow(["exercise_id", "title", "widget_class", "skill_tags", "level_widgets"])
        for row in rows:
            writer.writerow([
                row["exercise_id"],
                row["title"],
                row["widget_class"],
                " ".join(row["skill_tags"]),
                level_widgets_for(row["widget_class"]),
            ])
    print(f"OK: {len(rows)} Übungen inventarisiert -> {OUT.relative_to(ROOT)}")
    sys.exit(0)


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `python -m unittest scripts.tests.test_extract_exercise_inventory -v`
Expected: PASS, 3 tests.

- [ ] **Step 5: Generate the real inventory and eyeball it**

Run: `python scripts/extract_exercise_inventory.py`
Expected: `OK: 27 Übungen inventarisiert -> docs/clean-room/v2/inventory_uebungen.csv` (around 30 rows).
Then run: `python -c "import csv;rows=list(csv.DictReader(open('docs/clean-room/v2/inventory_uebungen.csv',encoding='utf-8')));print(len(rows));print([r['exercise_id'] for r in rows if r['exercise_id'].startswith('S3')])"`
Expected: the `S3.x` doubling family (`S3.1`–`S3.7`) appears. If it does not, the parser is wrong — fix it before continuing, because the matrix's Verdoppeln row depends on this inventory.

- [ ] **Step 6: Commit (only after Jakob authorizes)**

```bash
git add scripts/extract_exercise_inventory.py scripts/tests/test_extract_exercise_inventory.py docs/clean-room/v2/inventory_uebungen.csv
git commit -m "feat(v2): extract the hand-built exercise catalogue as matrix inventory"
```

---

## Task 2: Matrix skeleton and parser

**Files:**
- Create: `docs/clean-room/v2/10-deckungsmatrix.md` (skeleton: header, `## Vokabular`, one worked strand)
- Create: `scripts/check_deckung.py` (parsing only in this task)
- Create: `scripts/tests/test_check_deckung.py`

**Interfaces:**
- Consumes: `docs/clean-room/v2/inventory_uebungen.csv` (Task 1) — not yet read in this task.
- Produces:
  - `parse_matrix(text: str) -> Matrix`, where `Matrix` is a `dataclass` with fields `strands: dict[str, str]` (id → description), `cells: dict[tuple[str, str, str], str]` (key → status), `exceptions: dict[tuple[str, str, str], str]` (key → reason), `blocks: dict[tuple[str, str, str], dict[str, str]]` (key → field name → value).
  - Constants `ZAHLENRAEUME = ("ZR10", "ZR20", "ZR100")`, `REPRAESENTATIONEN = ("enaktiv", "ikonisch", "symbolisch")`, `STATUSES = ("offen", "entworfen", "freigegeben", "–")`.

- [ ] **Step 1: Write the failing test**

Create `scripts/tests/test_check_deckung.py`:

```python
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from check_deckung import parse_matrix

MATRIX = """\
# 10 — Deckungsmatrix (v2)

## Vokabular

**Stränge:**
- `verdoppeln-halbieren` — Verdoppeln und Halbieren als abrufbare Beziehung

**Zahlenräume:** ZR10 · ZR20 · ZR100
**Repräsentationen:** enaktiv · ikonisch · symbolisch
**Status:** offen · entworfen · freigegeben · – (bewusst nicht abgedeckt)

## Strang: verdoppeln-halbieren

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | freigegeben |
| ZR20 | offen | offen | offen |
| ZR100 | – | offen | offen |

**Ausnahmen:**
- `verdoppeln-halbieren × ZR100 × enaktiv` — Im Hunderterraum wird über Zehnerstrukturen gedacht, nicht gelegt.

### verdoppeln-halbieren × ZR10 × symbolisch

- **quelle:** RLP BE/BB Teil C
- **fehlerbild:** Kind zählt einzeln weiter statt zu verdoppeln
- **diagnostik:** V10-01
- **übung:** S3.1
"""


class ParseMatrixTest(unittest.TestCase):
    def test_reads_the_strand_vocabulary(self):
        m = parse_matrix(MATRIX)
        self.assertIn("verdoppeln-halbieren", m.strands)
        self.assertIn("abrufbare Beziehung", m.strands["verdoppeln-halbieren"])

    def test_reads_every_table_cell_with_its_status(self):
        m = parse_matrix(MATRIX)
        self.assertEqual(len(m.cells), 9)
        self.assertEqual(m.cells[("verdoppeln-halbieren", "ZR10", "symbolisch")], "freigegeben")
        self.assertEqual(m.cells[("verdoppeln-halbieren", "ZR100", "enaktiv")], "–")

    def test_reads_exceptions(self):
        m = parse_matrix(MATRIX)
        key = ("verdoppeln-halbieren", "ZR100", "enaktiv")
        self.assertIn("Zehnerstrukturen", m.exceptions[key])

    def test_reads_detail_block_fields(self):
        m = parse_matrix(MATRIX)
        block = m.blocks[("verdoppeln-halbieren", "ZR10", "symbolisch")]
        self.assertEqual(block["diagnostik"], "V10-01")
        self.assertEqual(block["übung"], "S3.1")
        self.assertIn("RLP", block["quelle"])


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `python -m unittest scripts.tests.test_check_deckung -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'check_deckung'`.

- [ ] **Step 3: Write the minimal implementation**

Create `scripts/check_deckung.py`:

```python
#!/usr/bin/env python3
"""Prüft die Deckungsmatrix v2 — das Wurzelartefakt des Inhaltsneubaus (v2-Entwurf §4, §8).

Grün heißt *abgedeckt*, nicht *dokumentiert*: eine Zelle ohne Item, ohne Übung
oder ohne begründete Ausnahme lässt diesen Gate scheitern.

Exit 0 wenn sauber, Exit 1 mit je einer FAIL-Zeile pro Problem.
"""

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MATRIX_PATH = ROOT / "docs" / "clean-room" / "v2" / "10-deckungsmatrix.md"

ZAHLENRAEUME = ("ZR10", "ZR20", "ZR100")
REPRAESENTATIONEN = ("enaktiv", "ikonisch", "symbolisch")
STATUSES = ("offen", "entworfen", "freigegeben", "–")
FIELDS = ("quelle", "fehlerbild", "diagnostik", "übung")
LEER = "—"  # em dash: noch nichts zugeordnet

STRAND_VOCAB_RE = re.compile(r"^- `([a-z0-9-]+)`\s+—\s+(.+)$", re.MULTILINE)
STRAND_SECTION_RE = re.compile(r"^## Strang:\s*([a-z0-9-]+)\s*$", re.MULTILINE)
TABLE_ROW_RE = re.compile(r"^\|\s*(ZR10|ZR20|ZR100)\s*\|(.+)\|\s*$", re.MULTILINE)
EXCEPTION_RE = re.compile(r"^- `([a-z0-9-]+) × (\w+) × (\w+)`\s+—\s+(.+)$", re.MULTILINE)
BLOCK_RE = re.compile(r"^### ([a-z0-9-]+) × (\w+) × (\w+)\s*$", re.MULTILINE)
FIELD_RE = re.compile(r"^- \*\*([^:*]+):\*\*\s*(.*)$", re.MULTILINE)


@dataclass
class Matrix:
    strands: dict = field(default_factory=dict)
    cells: dict = field(default_factory=dict)
    exceptions: dict = field(default_factory=dict)
    blocks: dict = field(default_factory=dict)
    duplicate_blocks: list = field(default_factory=list)


def parse_matrix(text):
    """Parse the matrix document into its four indexes."""
    m = Matrix()

    vocab_start = text.find("**Stränge:**")
    vocab_end = text.find("**Zahlenräume:**")
    if vocab_start != -1 and vocab_end != -1:
        for match in STRAND_VOCAB_RE.finditer(text[vocab_start:vocab_end]):
            m.strands[match.group(1)] = match.group(2).strip()

    sections = STRAND_SECTION_RE.split(text)
    # sections[0] = preamble, then alternating (strand_id, body)
    for i in range(1, len(sections) - 1, 2):
        strand = sections[i].strip()
        body = sections[i + 1]

        for row in TABLE_ROW_RE.finditer(body):
            zr = row.group(1)
            values = [v.strip() for v in row.group(2).split("|")]
            for rep, status in zip(REPRAESENTATIONEN, values):
                m.cells[(strand, zr, rep)] = status

        for exc in EXCEPTION_RE.finditer(body):
            m.exceptions[(exc.group(1), exc.group(2), exc.group(3))] = exc.group(4).strip()

        block_parts = BLOCK_RE.split(body)
        for j in range(1, len(block_parts) - 3, 4):
            key = (block_parts[j].strip(), block_parts[j + 1].strip(), block_parts[j + 2].strip())
            fields = {}
            for fm in FIELD_RE.finditer(block_parts[j + 3]):
                fields[fm.group(1).strip()] = fm.group(2).strip()
            if key in m.blocks:
                m.duplicate_blocks.append(key)
            m.blocks[key] = fields

    return m
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `python -m unittest scripts.tests.test_check_deckung -v`
Expected: PASS, 4 tests.

- [ ] **Step 5: Create the matrix skeleton with one real strand**

Create `docs/clean-room/v2/10-deckungsmatrix.md` with the header table (Status `🚧 in Arbeit — nicht freigegeben`, Datum, Owner Jakob, link to the spec), the `## Vokabular` section containing **only** `verdoppeln-halbieren` for now, and that strand's 3×3 table with every cell `offen`, no exceptions, and detail blocks for all nine cells with `quelle:` and `fehlerbild:` filled from the literature and `diagnostik: —` / `übung:` referencing the inventory IDs (`S3.1`, `S3.2`, `S3.3`, `S3.4`, `S3.5`, `S3.6`). Task 5 adds the remaining strands.

- [ ] **Step 6: Verify the parser reads the real file**

Run: `python -c "import sys;sys.path.insert(0,'scripts');from check_deckung import parse_matrix,MATRIX_PATH;m=parse_matrix(MATRIX_PATH.read_text(encoding='utf-8'));print(len(m.strands),'Stränge',len(m.cells),'Zellen',len(m.blocks),'Blöcke')"`
Expected: `1 Stränge 9 Zellen 9 Blöcke`.

- [ ] **Step 7: Commit (only after Jakob authorizes)**

```bash
git add scripts/check_deckung.py scripts/tests/test_check_deckung.py docs/clean-room/v2/10-deckungsmatrix.md
git commit -m "feat(v2): Deckungsmatrix skeleton + parser"
```

---

## Task 3: Structural validation rules R1–R6

**Files:**
- Modify: `scripts/check_deckung.py` (add `validate()` and `main()`)
- Modify: `scripts/tests/test_check_deckung.py` (add a `ValidateTest` class)

**Interfaces:**
- Consumes: `parse_matrix()` and the constants from Task 2.
- Produces: `validate(matrix: Matrix, known_uebungen: set[str] | None = None, known_items: set[str] | None = None) -> list[str]` returning German error strings, empty when clean. The two optional arguments are wired in Task 4; in this task they stay `None` and cross-reference checks are skipped.

Rules implemented here:

- **R1** every strand section corresponds to a vocabulary entry, and every vocabulary entry has a section
- **R2** every strand declares all nine cells (3 Zahlenräume × 3 Repräsentationen)
- **R3** every status is one of `STATUSES`
- **R4** every non-`–` cell has exactly one detail block; every detail block belongs to a non-`–` cell
- **R5** every `–` cell has an `Ausnahmen:` entry whose reason is at least 20 characters
- **R6** every detail block carries all four fields non-empty; `freigegeben` additionally requires `diagnostik` and `übung` to be something other than `—`

- [ ] **Step 1: Write the failing tests**

Append to `scripts/tests/test_check_deckung.py`:

```python
from check_deckung import validate


def matrix_with(table_rows, extra=""):
    return f"""\
## Vokabular

**Stränge:**
- `teststrang` — Teststrang für die Regelprüfung

**Zahlenräume:** ZR10 · ZR20 · ZR100
**Repräsentationen:** enaktiv · ikonisch · symbolisch
**Status:** offen · entworfen · freigegeben · – (bewusst nicht abgedeckt)

## Strang: teststrang

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
{table_rows}
{extra}
"""


ALL_OFFEN = """\
| ZR10 | offen | offen | offen |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |"""


def blocks_for(keys, diagnostik="—", uebung="—"):
    out = []
    for zr, rep in keys:
        out.append(
            f"\\n### teststrang × {zr} × {rep}\\n\\n"
            f"- **quelle:** RLP BE/BB Teil C\\n"
            f"- **fehlerbild:** Kind zählt statt zu rechnen\\n"
            f"- **diagnostik:** {diagnostik}\\n"
            f"- **übung:** {uebung}\\n"
        )
    return "".join(out)


ALL_KEYS = [(zr, rep) for zr in ("ZR10", "ZR20", "ZR100")
            for rep in ("enaktiv", "ikonisch", "symbolisch")]


class ValidateTest(unittest.TestCase):
    def test_clean_matrix_has_no_errors(self):
        text = matrix_with(ALL_OFFEN, blocks_for(ALL_KEYS))
        self.assertEqual(validate(parse_matrix(text)), [])

    def test_missing_detail_block_fails(self):
        text = matrix_with(ALL_OFFEN, blocks_for(ALL_KEYS[:-1]))
        errors = validate(parse_matrix(text))
        self.assertTrue(any("ohne Detailblock" in e for e in errors), errors)

    def test_unknown_status_fails(self):
        rows = ALL_OFFEN.replace("| ZR10 | offen", "| ZR10 | fertig")
        text = matrix_with(rows, blocks_for(ALL_KEYS))
        errors = validate(parse_matrix(text))
        self.assertTrue(any("Unbekannter Status" in e for e in errors), errors)

    def test_exempt_cell_without_reason_fails(self):
        rows = ALL_OFFEN.replace("| ZR100 | offen | offen | offen |",
                                 "| ZR100 | – | offen | offen |")
        text = matrix_with(rows, blocks_for([k for k in ALL_KEYS if k != ("ZR100", "enaktiv")]))
        errors = validate(parse_matrix(text))
        self.assertTrue(any("ohne begründete Ausnahme" in e for e in errors), errors)

    def test_exempt_cell_with_reason_passes(self):
        rows = ALL_OFFEN.replace("| ZR100 | offen | offen | offen |",
                                 "| ZR100 | – | offen | offen |")
        extra = ("\\n**Ausnahmen:**\\n"
                 "- `teststrang × ZR100 × enaktiv` — Im Hunderterraum wird nicht mehr handelnd gelegt, "
                 "das enaktive Signal liefert ZR20.\\n"
                 + blocks_for([k for k in ALL_KEYS if k != ("ZR100", "enaktiv")]))
        self.assertEqual(validate(parse_matrix(matrix_with(rows, extra))), [])

    def test_freigegeben_without_item_or_exercise_fails(self):
        rows = ALL_OFFEN.replace("| ZR10 | offen", "| ZR10 | freigegeben")
        text = matrix_with(rows, blocks_for(ALL_KEYS))
        errors = validate(parse_matrix(text))
        self.assertTrue(any("freigegeben" in e and "diagnostik" in e for e in errors), errors)

    def test_missing_strand_section_fails(self):
        text = matrix_with(ALL_OFFEN, blocks_for(ALL_KEYS)).replace(
            "- `teststrang` — Teststrang für die Regelprüfung",
            "- `teststrang` — Teststrang für die Regelprüfung\\n- `fehlstrang` — Nie beschrieben")
        errors = validate(parse_matrix(text))
        self.assertTrue(any("fehlstrang" in e for e in errors), errors)
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python -m unittest scripts.tests.test_check_deckung -v`
Expected: FAIL — `ImportError: cannot import name 'validate'`.

- [ ] **Step 3: Write the minimal implementation**

Append to `scripts/check_deckung.py`:

```python
def validate(matrix, known_uebungen=None, known_items=None):
    """Return a list of German error strings; empty means the gate passes."""
    errors = []
    section_strands = {key[0] for key in matrix.cells}

    # R1 — vocabulary and sections agree
    for strand in sorted(set(matrix.strands) - section_strands):
        errors.append(f"Strang `{strand}` steht im Vokabular, hat aber keinen Abschnitt")
    for strand in sorted(section_strands - set(matrix.strands)):
        errors.append(f"Strang `{strand}` hat einen Abschnitt, steht aber nicht im Vokabular")

    for strand in sorted(section_strands):
        # R2 — all nine cells declared
        for zr in ZAHLENRAEUME:
            for rep in REPRAESENTATIONEN:
                if (strand, zr, rep) not in matrix.cells:
                    errors.append(f"{strand} × {zr} × {rep}: Zelle fehlt in der Tabelle")

    for key in sorted(matrix.cells):
        strand, zr, rep = key
        status = matrix.cells[key]
        label = f"{strand} × {zr} × {rep}"

        # R3 — known status
        if status not in STATUSES:
            errors.append(f"{label}: Unbekannter Status '{status}'")
            continue

        if status == "–":
            # R5 — exemption needs a written reason
            reason = matrix.exceptions.get(key, "")
            if len(reason) < 20:
                errors.append(f"{label}: als nicht abgedeckt markiert, aber ohne begründete Ausnahme")
            if key in matrix.blocks:
                errors.append(f"{label}: nicht abgedeckt, hat aber einen Detailblock")
            continue

        # R4 — live cell needs exactly one block
        block = matrix.blocks.get(key)
        if block is None:
            errors.append(f"{label}: Status '{status}' ohne Detailblock")
            continue

        # R6 — all fields present, freigegeben needs real references
        for name in FIELDS:
            if not block.get(name):
                errors.append(f"{label}: Feld '{name}' fehlt oder ist leer")
        if status == "freigegeben":
            for name in ("diagnostik", "übung"):
                if block.get(name, LEER) == LEER:
                    errors.append(f"{label}: Status 'freigegeben' verlangt einen Eintrag in '{name}'")

    for key in sorted(matrix.blocks):
        if key not in matrix.cells:
            errors.append(f"{key[0]} × {key[1]} × {key[2]}: Detailblock ohne Tabellenzeile")

    for key in matrix.duplicate_blocks:
        errors.append(f"{key[0]} × {key[1]} × {key[2]}: Detailblock mehrfach vorhanden")

    return errors


def main():
    if not MATRIX_PATH.exists():
        print(f"FAIL: {MATRIX_PATH} nicht gefunden")
        sys.exit(1)
    matrix = parse_matrix(MATRIX_PATH.read_text(encoding="utf-8"))
    errors = validate(matrix)
    live = sum(1 for status in matrix.cells.values() if status != "–")
    freigegeben = sum(1 for status in matrix.cells.values() if status == "freigegeben")
    print(f"check_deckung: {len(matrix.strands)} Stränge, {len(matrix.cells)} Zellen "
          f"({live} aktiv, {freigegeben} freigegeben)")
    if errors:
        for err in errors:
            print("FAIL:", err)
        sys.exit(1)
    print("OK: jede Zelle deklariert, jede Ausnahme begründet, jeder Detailblock vollständig")
    sys.exit(0)


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python -m unittest scripts.tests.test_check_deckung -v`
Expected: PASS, 11 tests.

- [ ] **Step 5: Run the gate against the real matrix**

Run: `python scripts/check_deckung.py`
Expected: `check_deckung: 1 Stränge, 9 Zellen (9 aktiv, 0 freigegeben)` and `OK: …`, exit 0.

- [ ] **Step 6: Commit (only after Jakob authorizes)**

```bash
git add scripts/check_deckung.py scripts/tests/test_check_deckung.py
git commit -m "feat(v2): Deckungsmatrix structural gate (R1-R6)"
```

---

## Task 4: Cross-reference rules R7–R8

**Files:**
- Modify: `scripts/check_deckung.py` (`load_known_uebungen()`, `load_known_items()`, wire into `main()`)
- Modify: `scripts/tests/test_check_deckung.py` (add a `CrossReferenceTest` class)

**Interfaces:**
- Consumes: `docs/clean-room/v2/inventory_uebungen.csv` (Task 1), `docs/clean-room/v2/items/` and `docs/clean-room/v2/uebungen/` (created empty here, filled in later phases).
- Produces: `load_known_uebungen() -> set[str]` (inventory IDs ∪ `v2/uebungen/*.md` stems) and `load_known_items() -> set[str]` (`v2/items/*.md` stems); `validate()` now uses both when they are passed.

Rules:

- **R7** every ID named in `diagnostik:` resolves to a file in `v2/items/`; every ID in `übung:` resolves to an inventory row or a file in `v2/uebungen/`. `—` is exempt. Multiple IDs are comma-separated; a trailing bracketed note like `S3.6 [alt, Triage offen]` is stripped before resolving.
- **R8** an ID appears in no more than one cell's `diagnostik:` field — an item measures one cell.

- [ ] **Step 1: Write the failing tests**

Append to `scripts/tests/test_check_deckung.py`:

```python
class CrossReferenceTest(unittest.TestCase):
    def test_unknown_exercise_id_fails(self):
        text = matrix_with(ALL_OFFEN, blocks_for(ALL_KEYS, uebung="S9.9"))
        errors = validate(parse_matrix(text), known_uebungen={"S3.1"}, known_items=set())
        self.assertTrue(any("Unbekannte Übung" in e and "S9.9" in e for e in errors), errors)

    def test_known_exercise_id_passes(self):
        text = matrix_with(ALL_OFFEN, blocks_for(ALL_KEYS, uebung="S3.1"))
        self.assertEqual(validate(parse_matrix(text), known_uebungen={"S3.1"}, known_items=set()), [])

    def test_bracketed_note_is_stripped_before_resolving(self):
        text = matrix_with(ALL_OFFEN, blocks_for(ALL_KEYS, uebung="S3.1 [alt, Triage offen]"))
        self.assertEqual(validate(parse_matrix(text), known_uebungen={"S3.1"}, known_items=set()), [])

    def test_unknown_item_id_fails(self):
        text = matrix_with(ALL_OFFEN, blocks_for(ALL_KEYS, diagnostik="V99-01"))
        errors = validate(parse_matrix(text), known_uebungen=set(), known_items={"V10-01"})
        self.assertTrue(any("Unbekanntes Item" in e and "V99-01" in e for e in errors), errors)

    def test_item_used_in_two_cells_fails(self):
        blocks = (blocks_for([ALL_KEYS[0]], diagnostik="V10-01")
                  + blocks_for(ALL_KEYS[1:2], diagnostik="V10-01")
                  + blocks_for(ALL_KEYS[2:]))
        text = matrix_with(ALL_OFFEN, blocks)
        errors = validate(parse_matrix(text), known_uebungen=set(), known_items={"V10-01"})
        self.assertTrue(any("mehreren Zellen" in e for e in errors), errors)
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python -m unittest scripts.tests.test_check_deckung -v`
Expected: FAIL — the five new tests fail because `validate()` ignores its cross-reference arguments.

- [ ] **Step 3: Write the minimal implementation**

In `scripts/check_deckung.py`, add the loaders after the constants:

```python
import csv

INVENTORY = ROOT / "docs" / "clean-room" / "v2" / "inventory_uebungen.csv"
V2_ITEMS = ROOT / "docs" / "clean-room" / "v2" / "items"
V2_UEBUNGEN = ROOT / "docs" / "clean-room" / "v2" / "uebungen"

REF_NOTE_RE = re.compile(r"\s*\[[^\]]*\]")


def split_refs(value):
    """'S3.1 [alt], S3.2' -> ['S3.1', 'S3.2']; '—' -> []."""
    if not value or value == LEER:
        return []
    cleaned = REF_NOTE_RE.sub("", value)
    return [tok.strip() for tok in cleaned.split(",") if tok.strip()]


def load_known_uebungen():
    known = set()
    if INVENTORY.exists():
        with INVENTORY.open(encoding="utf-8") as fh:
            for row in csv.DictReader(fh):
                known.add(row["exercise_id"])
    if V2_UEBUNGEN.exists():
        known.update(p.stem for p in V2_UEBUNGEN.glob("*.md") if p.stem != "README")
    return known


def load_known_items():
    if not V2_ITEMS.exists():
        return set()
    return {p.stem for p in V2_ITEMS.glob("*.md") if p.stem not in ("README", "TEMPLATE")}
```

Then, inside `validate()`, immediately before `return errors`:

```python
    if known_uebungen is not None or known_items is not None:
        item_owner = {}
        for key in sorted(matrix.blocks):
            block = matrix.blocks[key]
            label = f"{key[0]} × {key[1]} × {key[2]}"
            if known_uebungen is not None:
                for ref in split_refs(block.get("übung", "")):
                    if ref not in known_uebungen:
                        errors.append(f"{label}: Unbekannte Übung '{ref}' (weder im Inventar noch in v2/uebungen/)")
            if known_items is not None:
                for ref in split_refs(block.get("diagnostik", "")):
                    if ref not in known_items:
                        errors.append(f"{label}: Unbekanntes Item '{ref}' (keine Datei in v2/items/)")
                    if ref in item_owner:
                        errors.append(f"{label}: Item '{ref}' wird in mehreren Zellen verwendet "
                                      f"(bereits in {item_owner[ref]})")
                    else:
                        item_owner[ref] = label
```

And in `main()`, replace `errors = validate(matrix)` with:

```python
    errors = validate(matrix, known_uebungen=load_known_uebungen(), known_items=load_known_items())
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python -m unittest scripts.tests.test_check_deckung -v`
Expected: PASS, 16 tests.

- [ ] **Step 5: Create the empty v2 content directories and re-run the gate**

```bash
mkdir -p docs/clean-room/v2/items docs/clean-room/v2/uebungen
```

Run: `python scripts/check_deckung.py`
Expected: exit 0. If the skeleton's `übung:` fields name inventory IDs, they now resolve; if one fails, the ID in the matrix is wrong — fix the matrix, not the checker.

- [ ] **Step 6: Commit (only after Jakob authorizes)**

```bash
git add scripts/check_deckung.py scripts/tests/test_check_deckung.py
git commit -m "feat(v2): Deckungsmatrix cross-reference gate (R7-R8)"
```

---

## Task 5: Author the full matrix

**Files:**
- Modify: `docs/clean-room/v2/10-deckungsmatrix.md` (all remaining strands)
- Read: `docs/clean-room/v2/inventory_uebungen.csv`, `docs/clean-room/03-bibliography.md`, `docs/clean-room/00-v1-assessment.md` (Anhang A), `adhd guidelines.md`

**Interfaces:**
- Consumes: the format and the gate from Tasks 2–4.
- Produces: the signed root artifact every later phase derives from.

**This is content work, not code.** It ends at Jakob's Gate 1 and must not be rushed past it.

**The strand vocabulary to author** (20 strands; each gets a 3×3 table, exceptions where a cell is meaningless, and a detail block per live cell):

`zaehlen-vorwaerts` · `zaehlen-rueckwaerts` · `zaehlen-schritte` · `vorgaenger-nachfolger` · `anzahl-simultan` · `anzahl-strukturiert` · `anzahl-vergleich` · `zahlvergleich-ordnen` · `zerlegung` · `verdoppeln-halbieren` · `buendeln-entbuendeln` · `stellenwerttafel` · `zahlenstrahl` · `addition-ohne-uebergang` · `addition-mit-uebergang` · `subtraktion-ohne-uebergang` · `subtraktion-mit-uebergang` · `ergaenzen` · `flexibles-rechnen` · `sachsituationen`

Four of these exist specifically because v1 lacked them: `zahlvergleich-ordnen` (no construct at all), `verdoppeln-halbieren` (no ZR20 item, no ZR100 construct), `anzahl-simultan` split away from `anzahl-strukturiert` (v1 filed a Rekenrek — a structured tool — under Simultanerfassung), and `zahlenstrahl` as its own strand so the 0–10 → 0–20 → 0–100 ladder is visible as three cells instead of one item at 0–100.

- [ ] **Step 1: Derive the row set from the curriculum, with citations**

For each of the 20 strands, read Rahmenlehrplan BE/BB Teil C and the KMK Bildungsstandards for what Klasse 1–2 must contain, and record the citation in each cell's `quelle:`. Where the curriculum is silent on a distinction the literature makes, cite the literature (`03-bibliography.md`) instead. Never cite a source that was not actually read for that cell.

- [ ] **Step 2: Fill each cell's `fehlerbild`**

One sentence per cell: what a wrong answer at this strand, in this Zahlenraum, in this representation actually indicates. This is the field the Förderplan and the error-pattern analysis both read later, so a vague entry here becomes a vague Förderplan.

- [ ] **Step 3: Mark the exemptions with reasons**

Cells that are pedagogically meaningless get `–` plus an `Ausnahmen:` line of at least 20 characters. Known cases: `anzahl-simultan × ZR20/ZR100 × alle` (Simultanerfassung is capped at 5 by definition — one of the v1 defects), `sachsituationen × alle × enaktiv`, and the enaktiv column of the ZR100 strategy strands. Do not exempt a cell merely because it is inconvenient to build.

- [ ] **Step 4: Wire the inventory into `übung:`**

For every cell where a hand-built exercise already exists, name it from `inventory_uebungen.csv` with the note `[alt, Triage offen]` — it is a candidate, not yet triaged (spec §6, R8.1). Cells with no candidate keep `—`. The `S3.1`–`S3.7` family populates the `verdoppeln-halbieren` row; the `C*` family populates the counting strands.

- [ ] **Step 5: Run the gate**

Run: `python scripts/check_deckung.py`
Expected: exit 0, with a line like `check_deckung: 20 Stränge, 180 Zellen (N aktiv, 0 freigegeben)`.
Every failure is a real gap — fix the matrix, never loosen the rule.

- [ ] **Step 6: Cross-check against Anhang A**

Verify by reading that each of Jakob's item-level findings now has a home: Q7 (Vorgänger/Nachfolger, two answers) → `vorgaenger-nachfolger`; Q8 (Simultanerfassung ≤5) → `anzahl-simultan` capped; Q11 (ikonisch without symbolic sibling) → both cells of `anzahl-vergleich` live; Q26 (straight to 0–100) → three `zahlenstrahl` cells. If a finding has no cell, the vocabulary is incomplete.

- [ ] **Step 7: Gate 1 — Jakob reviews and signs**

Present the matrix to Jakob as the Förderlehrer. He reviews coverage — *is anything a Klasse-1/2 child must be able to do missing, and is anything here that does not belong?* Nothing downstream (Konstruktkarte, Blueprint, items) starts before he has signed. On sign-off, change the header Status to `✅ FREIGEGEBEN — Jakob, <Datum>`.

- [ ] **Step 8: Commit (only after Jakob authorizes)**

```bash
git add docs/clean-room/v2/10-deckungsmatrix.md
git commit -m "feat(v2): Deckungsmatrix — 20 Stränge über ZR10/ZR20/ZR100, freigegeben"
```

---

## Task 6: Wire the v2 tree into the documentation

**Files:**
- Create: `docs/clean-room/v2/README.md`
- Modify: `DOCS_INDEX.md` (v2 tree entries + precedence rule)
- Modify: `STATUS.md` (Active item 1: Phase 1 done, matrix signed)

**Interfaces:**
- Consumes: everything above.
- Produces: no code. The doc map tells the next session which artifact is the source of truth and which gate proves it.

- [ ] **Step 1: Write the v2 README**

`docs/clean-room/v2/README.md` states: what each file in the tree is; that `10-deckungsmatrix.md` is the root artifact and outranks the Konstruktkarte; the cell lifecycle `offen → entworfen → freigegeben`, with `freigegeben` requiring both Jakob gates (paper, then the running child screen); and the gate commands:

```bash
python scripts/extract_exercise_inventory.py   # Inventar neu erzeugen
python scripts/check_deckung.py                # Deckungsgate
python -m unittest discover -s scripts/tests -v # Tests der Prüfskripte
```

- [ ] **Step 2: Add the v2 tree to DOCS_INDEX**

Under "Start here", add `docs/clean-room/v2/10-deckungsmatrix.md` — 🟢 **Wurzelartefakt** — and `docs/clean-room/v2/README.md`. Then apply the precedence rule the index already anticipates: once the matrix is signed, it sits at the top of the Vorrangregel, above the v2 spec.

- [ ] **Step 3: Update STATUS**

In Active item 1, record: Phase 1 complete, the matrix signed on `<Datum>` with N live cells, the gate green, and that Phase 2 (Konstruktkarte + Blueprint, derived from the matrix) is next.

- [ ] **Step 4: Run every gate one final time**

```bash
python scripts/check_deckung.py
python -m unittest discover -s scripts/tests -v
python scripts/check_provenance.py --all
python scripts/check_item_independence.py --new math_app/Research/diagnostic_core_v1.csv --strict
```

Expected: the first two green; the last two unchanged from their recorded baseline — Phase 1 touches no v1 artifact, so any change there means something was modified that should not have been.

- [ ] **Step 5: Commit (only after Jakob authorizes)**

```bash
git add docs/clean-room/v2/README.md DOCS_INDEX.md STATUS.md
git commit -m "docs(v2): wire the Deckungsmatrix tree into the doc map"
```

---

## Self-Review

**Spec coverage.** Spec §3 (artifact architecture) → Tasks 2, 4 (tree), 6 (doc wiring). §4 (Deckungsmatrix, three axes, five fields, ~60–70 live cells, inventory as input) → Tasks 1, 2, 5. §8 `check_deckung.py` — "fails on an empty cell without exemption, an item pointing at a non-existent cell, a skill with no exercise, an exercise covering no cell" → R4/R5/R6 (Task 3) and R7/R8 (Task 4). §8 process loop, Gate 1 → Task 5 Step 7. §9 Phase 1 scope → this whole plan.

**Deliberately out of scope for this plan** (later phases of the spec, each needing its own plan): `check_item_quality.py` and the item acceptance criteria (spec §5.1, Phase 2), the Konstruktkarte and Blueprint derivations (Phase 2), the Verdoppeln/Halbieren vertical slice (Phase 3), the generator/migration/TTS work (Phase 5), the iMINT coverage audit and ADR 0010 (Phase 6).

**Placeholder scan.** No `TBD`/`TODO`/"similar to Task N". Every code step carries runnable code; every content step states its acceptance condition. The strand vocabulary is enumerated rather than left to the implementer.

**Type consistency.** `parse_matrix()` returns `Matrix` with `strands`/`cells`/`exceptions`/`blocks`/`duplicate_blocks` — the same names used in Tasks 3 and 4. `validate(matrix, known_uebungen=None, known_items=None)` keeps that signature from Task 3 through Task 4. `split_refs()`, `load_known_uebungen()`, `load_known_items()` are defined in Task 4 and used only there and in `main()`. The inventory CSV header `exercise_id,title,widget_class,skill_tags,level_widgets` is written in Task 1 and read by `load_known_uebungen()` in Task 4 under the same key.
