import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from check_deckung import parse_matrix, konstrukt_items_of

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
            f"\n### teststrang × {zr} × {rep}\n\n"
            f"- **quelle:** RLP BE/BB Teil C\n"
            f"- **fehlerbild:** Kind zählt statt zu rechnen\n"
            f"- **diagnostik:** {diagnostik}\n"
            f"- **übung:** {uebung}\n"
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
        extra = ("\n**Ausnahmen:**\n"
                 "- `teststrang × ZR100 × enaktiv` — Im Hunderterraum wird nicht mehr handelnd gelegt, "
                 "das enaktive Signal liefert ZR20.\n"
                 + blocks_for([k for k in ALL_KEYS if k != ("ZR100", "enaktiv")]))
        self.assertEqual(validate(parse_matrix(matrix_with(rows, extra))), [])

    def test_freigegeben_without_item_or_exercise_fails(self):
        # Decision B (12-blueprint.md): die Uebung gehoert zur Zelle, das Diagnostik-Item
        # zum Konstrukt. Vor Phase 2 verlangte diese Regel beides auf der Zelle.
        rows = ALL_OFFEN.replace("| ZR10 | offen", "| ZR10 | freigegeben")
        text = matrix_with(rows, blocks_for(ALL_KEYS))
        errors = validate(parse_matrix(text), konstrukt_items={})
        self.assertTrue(any("freigegeben" in e and "übung" in e for e in errors), errors)
        self.assertTrue(
            any("freigegeben" in e and "teststrang.ZR10" in e for e in errors), errors)

    def test_missing_strand_section_fails(self):
        text = matrix_with(ALL_OFFEN, blocks_for(ALL_KEYS)).replace(
            "- `teststrang` — Teststrang für die Regelprüfung",
            "- `teststrang` — Teststrang für die Regelprüfung\n- `fehlstrang` — Nie beschrieben")
        errors = validate(parse_matrix(text))
        self.assertTrue(any("fehlstrang" in e for e in errors), errors)


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


FREIGEGEBEN_MATRIX = """\
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
| ZR10 | offen | offen | offen |
| ZR20 | freigegeben | offen | freigegeben |
| ZR100 | offen | offen | offen |

### verdoppeln-halbieren × ZR10 × enaktiv

- **quelle:** RLP
- **fehlerbild:** zaehlt statt zu verdoppeln
- **diagnostik:** —
- **übung:** S3.3

### verdoppeln-halbieren × ZR10 × ikonisch

- **quelle:** RLP
- **fehlerbild:** zaehlt die Punkte einzeln
- **diagnostik:** —
- **übung:** —

### verdoppeln-halbieren × ZR10 × symbolisch

- **quelle:** RLP
- **fehlerbild:** Kernaufgabe nicht abrufbar
- **diagnostik:** —
- **übung:** —

### verdoppeln-halbieren × ZR20 × enaktiv

- **quelle:** RLP
- **fehlerbild:** nutzt die Fuenferstruktur nicht
- **diagnostik:** —
- **übung:** S3.4

### verdoppeln-halbieren × ZR20 × ikonisch

- **quelle:** RLP
- **fehlerbild:** zaehlt am Zwanzigerfeld weiter
- **diagnostik:** —
- **übung:** S3.2

### verdoppeln-halbieren × ZR20 × symbolisch

- **quelle:** RLP
- **fehlerbild:** Verdopplungen nicht automatisiert
- **diagnostik:** verdoppeln-halbieren.ZR20-01
- **übung:** S3.5

### verdoppeln-halbieren × ZR100 × enaktiv

- **quelle:** RLP
- **fehlerbild:** verdoppelt Zehnerstangen zaehlend
- **diagnostik:** —
- **übung:** —

### verdoppeln-halbieren × ZR100 × ikonisch

- **quelle:** RLP
- **fehlerbild:** liest das Hunderterfeld zeilenweise
- **diagnostik:** —
- **übung:** —

### verdoppeln-halbieren × ZR100 × symbolisch

- **quelle:** RLP
- **fehlerbild:** rechnet stellenweise neu
- **diagnostik:** —
- **übung:** —
"""


class KonstruktFreigabeTest(unittest.TestCase):
    def setUp(self):
        self.matrix = parse_matrix(FREIGEGEBEN_MATRIX)
        self.k_items = konstrukt_items_of(self.matrix)

    def test_collects_item_ids_per_konstrukt(self):
        self.assertEqual(
            self.k_items["verdoppeln-halbieren.ZR20"],
            ["verdoppeln-halbieren.ZR20-01"],
        )
        self.assertEqual(self.k_items["verdoppeln-halbieren.ZR10"], [])

    def test_a_freigegeben_cell_may_borrow_its_item_from_a_sibling_cell(self):
        # ZR20 x enaktiv has no diagnostik of its own but its Konstrukt does,
        # and the cell has an exercise -> it may be freigegeben.
        errors = validate(self.matrix, konstrukt_items=self.k_items)
        self.assertEqual(
            [e for e in errors if "ZR20 × enaktiv" in e], []
        )

    def test_a_freigegeben_cell_without_an_exercise_still_fails(self):
        text = FREIGEGEBEN_MATRIX.replace(
            "| ZR100 | offen | offen | offen |",
            "| ZR100 | freigegeben | offen | offen |",
        )
        matrix = parse_matrix(text)
        errors = validate(matrix, konstrukt_items=konstrukt_items_of(matrix))
        self.assertTrue(
            any("ZR100 × enaktiv" in e and "übung" in e for e in errors), errors
        )

    def test_a_freigegeben_cell_whose_konstrukt_has_no_item_fails(self):
        text = FREIGEGEBEN_MATRIX.replace(
            "- **diagnostik:** verdoppeln-halbieren.ZR20-01", "- **diagnostik:** —"
        )
        matrix = parse_matrix(text)
        errors = validate(matrix, konstrukt_items=konstrukt_items_of(matrix))
        self.assertTrue(
            any("ZR20 × enaktiv" in e and "Konstrukt" in e for e in errors), errors
        )

    def test_r9_an_item_must_sit_in_a_cell_of_its_own_konstrukt(self):
        text = FREIGEGEBEN_MATRIX.replace(
            "- **diagnostik:** verdoppeln-halbieren.ZR20-01",
            "- **diagnostik:** verdoppeln-halbieren.ZR100-01",
        )
        matrix = parse_matrix(text)
        errors = validate(matrix, konstrukt_items=konstrukt_items_of(matrix))
        self.assertTrue(any("R9" in e for e in errors), errors)
