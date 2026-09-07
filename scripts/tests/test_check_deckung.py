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
        rows = ALL_OFFEN.replace("| ZR10 | offen", "| ZR10 | freigegeben")
        text = matrix_with(rows, blocks_for(ALL_KEYS))
        errors = validate(parse_matrix(text))
        self.assertTrue(any("freigegeben" in e and "diagnostik" in e for e in errors), errors)

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
