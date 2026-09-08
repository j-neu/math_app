import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from check_deckung import parse_matrix
from derive_ableitungen import (
    Item,
    konstrukte,
    render_blueprint,
    render_konstruktkarte,
    splice,
    zuteilung,
)

MATRIX = """\
# 10 — Deckungsmatrix (v2)

## Vokabular

**Stränge:**
- `zerlegung` — Zahlen in Teilmengen zerlegen und aus Teilmengen zusammensetzen
- `anzahl-simultan` — Anzahlen bis 5 auf einen Blick erfassen, ohne Zählhandlung

**Zahlenräume:** ZR10 · ZR20 · ZR100
**Repräsentationen:** enaktiv · ikonisch · symbolisch
**Status:** offen · entworfen · freigegeben · – (bewusst nicht abgedeckt)

## Strang: zerlegung

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | offen |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

### zerlegung × ZR10 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Kind legt die Teilmengen nebeneinander, ohne sie als Teile eines Ganzen zu lesen
- **diagnostik:** —
- **übung:** D1.1

### zerlegung × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Kind zählt beide Teilbilder einzeln ab
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR10 × symbolisch

- **quelle:** Padberg/Benz, Teile-Ganzes
- **fehlerbild:** Zerlegungen der 10 sind nicht abrufbar
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Kind entbündelt nicht, sondern zählt neu
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Kind liest das Zwanzigerfeld nicht als Fünferstruktur
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR20 × symbolisch

- **quelle:** Gaidoschik, Kernaufgaben
- **fehlerbild:** Kind rechnet die Zerlegung jedes Mal neu aus
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR100 × enaktiv

- **quelle:** Moser Opitz, Stellenwert
- **fehlerbild:** Kind zerlegt stellenweise falsch
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR100 × ikonisch

- **quelle:** Moser Opitz, Stellenwert
- **fehlerbild:** Kind liest das Hunderterfeld zeilenweise ab
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR100 × symbolisch

- **quelle:** Selter/Spiegel, denkendes Rechnen
- **fehlerbild:** Kind zerlegt nur in Zehner und Einer, nicht flexibel
- **diagnostik:** —
- **übung:** —

## Strang: anzahl-simultan

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | – |
| ZR20 | – | – | – |
| ZR100 | – | – | – |

**Ausnahmen:**
- `anzahl-simultan × ZR10 × symbolisch` — Simultanerfassung wird an Mengen geprüft, nicht an Ziffern.
- `anzahl-simultan × ZR20 × enaktiv` — Simultanerfassung ist bei 5 gedeckelt, im ZR20 misst sie Zählen.
- `anzahl-simultan × ZR20 × ikonisch` — Simultanerfassung ist bei 5 gedeckelt, im ZR20 misst sie Zählen.
- `anzahl-simultan × ZR20 × symbolisch` — Simultanerfassung ist bei 5 gedeckelt, im ZR20 misst sie Zählen.
- `anzahl-simultan × ZR100 × enaktiv` — Simultanerfassung ist bei 5 gedeckelt, im ZR100 misst sie Zählen.
- `anzahl-simultan × ZR100 × ikonisch` — Simultanerfassung ist bei 5 gedeckelt, im ZR100 misst sie Zählen.
- `anzahl-simultan × ZR100 × symbolisch` — Simultanerfassung ist bei 5 gedeckelt, im ZR100 misst sie Zählen.

### anzahl-simultan × ZR10 × enaktiv

- **quelle:** Krajewski, Anzahlerfassung
- **fehlerbild:** Kind tippt die Plättchen einzeln an, statt die Menge zu erfassen
- **diagnostik:** —
- **übung:** —

### anzahl-simultan × ZR10 × ikonisch

- **quelle:** Krajewski, Anzahlerfassung
- **fehlerbild:** Kind zählt die Punkte einzeln, die Latenz wächst mit der Anzahl
- **diagnostik:** —
- **übung:** —
"""


class KonstrukteTest(unittest.TestCase):
    def setUp(self):
        self.k = konstrukte(parse_matrix(MATRIX))
        self.by_id = {k.id: k for k in self.k}

    def test_one_konstrukt_per_live_strang_zahlenraum_pair(self):
        # zerlegung has three live Zahlenräume, anzahl-simultan only ZR10.
        self.assertEqual(len(self.k), 4)
        self.assertEqual(
            [k.id for k in self.k],
            [
                "zerlegung.ZR10",
                "zerlegung.ZR20",
                "zerlegung.ZR100",
                "anzahl-simultan.ZR10",
            ],
        )

    def test_fully_exempted_pairs_produce_no_konstrukt(self):
        self.assertNotIn("anzahl-simultan.ZR20", self.by_id)
        self.assertNotIn("anzahl-simultan.ZR100", self.by_id)

    def test_konstrukt_keeps_only_live_representations_in_axis_order(self):
        self.assertEqual(
            self.by_id["anzahl-simultan.ZR10"].repraesentationen,
            ["enaktiv", "ikonisch"],
        )
        self.assertEqual(
            self.by_id["zerlegung.ZR20"].repraesentationen,
            ["enaktiv", "ikonisch", "symbolisch"],
        )

    def test_leading_representation_is_the_most_symbolic_live_one(self):
        self.assertEqual(self.by_id["zerlegung.ZR20"].leitend, "symbolisch")
        self.assertEqual(self.by_id["anzahl-simultan.ZR10"].leitend, "ikonisch")

    def test_supporting_representation_is_the_most_enactive_live_one(self):
        self.assertEqual(self.by_id["zerlegung.ZR20"].stuetzend, "enaktiv")

    def test_konstrukt_carries_the_fehlerbild_of_each_live_cell(self):
        k = self.by_id["zerlegung.ZR10"]
        self.assertIn("Teile eines Ganzen", k.fehlerbilder["enaktiv"])
        self.assertIn("nicht abrufbar", k.fehlerbilder["symbolisch"])

    def test_konstrukt_collects_sources_without_duplicates_in_order(self):
        k = self.by_id["zerlegung.ZR10"]
        self.assertEqual(
            k.quellen,
            ["RLP BE/BB Teil C, L1, Niveaustufe A", "Padberg/Benz, Teile-Ganzes"],
        )

    def test_konstrukt_collects_exercise_ids_of_its_cells(self):
        self.assertEqual(self.by_id["zerlegung.ZR10"].uebungen, ["D1.1"])
        self.assertEqual(self.by_id["zerlegung.ZR20"].uebungen, [])


class RenderKonstruktkarteTest(unittest.TestCase):
    def setUp(self):
        self.body = render_konstruktkarte(konstrukte(parse_matrix(MATRIX)))

    def test_lists_every_konstrukt_with_a_heading(self):
        self.assertIn("### zerlegung.ZR20", self.body)
        self.assertIn("### anzahl-simultan.ZR10", self.body)

    def test_names_the_leading_and_supporting_representation(self):
        self.assertIn("**leitende Repräsentation:** symbolisch", self.body)
        self.assertIn("**stützende Repräsentation:** enaktiv", self.body)

    def test_states_the_total(self):
        self.assertIn("4 Konstrukte", self.body)

    def test_output_is_cp1252_safe(self):
        self.body.encode("cp1252")


class SpliceTest(unittest.TestCase):
    def test_replaces_only_the_marked_region(self):
        doc = (
            "Vorspann\n\n"
            "<!-- AUTOGEN:START — erzeugt von scripts/derive_ableitungen.py, "
            "nicht von Hand bearbeiten -->\n\nalt\n\n"
            "<!-- AUTOGEN:ENDE -->\n\nNachspann\n"
        )
        out = splice(doc, "neu")
        self.assertIn("Vorspann", out)
        self.assertIn("Nachspann", out)
        self.assertIn("neu", out)
        self.assertNotIn("alt", out)

    def test_missing_marker_raises(self):
        with self.assertRaises(ValueError):
            splice("kein Marker hier", "neu")


class ZuteilungTest(unittest.TestCase):
    def setUp(self):
        self.ks = konstrukte(parse_matrix(MATRIX))
        self.items = zuteilung(self.ks)
        self.by_konstrukt = {}
        for item in self.items:
            self.by_konstrukt.setdefault(item.konstrukt, []).append(item)

    def test_every_konstrukt_gets_a_kern_item(self):
        for k in self.ks:
            self.assertGreaterEqual(len(self.by_konstrukt[k.id]), 1)
            self.assertEqual(self.by_konstrukt[k.id][0].rolle, "Kern")

    def test_kern_item_sits_at_the_leading_representation(self):
        self.assertEqual(
            self.by_konstrukt["zerlegung.ZR20"][0].repraesentation, "symbolisch"
        )
        self.assertEqual(
            self.by_konstrukt["anzahl-simultan.ZR10"][0].repraesentation, "ikonisch"
        )

    def test_second_item_only_when_all_three_reps_live_and_zr20_or_zr100(self):
        self.assertEqual(len(self.by_konstrukt["zerlegung.ZR20"]), 2)
        self.assertEqual(len(self.by_konstrukt["zerlegung.ZR100"]), 2)
        # ZR10 is excluded by the rule even with three live representations.
        self.assertEqual(len(self.by_konstrukt["zerlegung.ZR10"]), 1)
        # Two live representations is not enough.
        self.assertEqual(len(self.by_konstrukt["anzahl-simultan.ZR10"]), 1)

    def test_second_item_sits_at_the_supporting_representation(self):
        second = self.by_konstrukt["zerlegung.ZR20"][1]
        self.assertEqual(second.repraesentation, "enaktiv")
        self.assertEqual(second.rolle, "Stütze")

    def test_item_ids_are_konstrukt_plus_two_digit_index(self):
        self.assertEqual(
            [i.id for i in self.by_konstrukt["zerlegung.ZR20"]],
            ["zerlegung.ZR20-01", "zerlegung.ZR20-02"],
        )

    def test_positions_are_gapless_and_start_at_one(self):
        self.assertEqual(
            [i.position for i in self.items], list(range(1, len(self.items) + 1))
        )

    def test_administration_order_is_strand_major_then_zahlenraum_ascending(self):
        order = [i.konstrukt for i in self.items]
        self.assertLess(order.index("zerlegung.ZR10"), order.index("zerlegung.ZR20"))
        self.assertLess(order.index("zerlegung.ZR20"), order.index("zerlegung.ZR100"))
        self.assertLess(
            order.index("zerlegung.ZR100"), order.index("anzahl-simultan.ZR10")
        )

    def test_blitz_flag_follows_the_named_strand_list(self):
        blitz = {i.id: i.blitz for i in self.items}
        self.assertTrue(blitz["anzahl-simultan.ZR10-01"])
        self.assertTrue(blitz["zerlegung.ZR10-01"])
        self.assertFalse(blitz["zerlegung.ZR20-02"])  # Stütze is never a Blitz item


class RenderBlueprintTest(unittest.TestCase):
    def setUp(self):
        ks = konstrukte(parse_matrix(MATRIX))
        self.body = render_blueprint(ks, zuteilung(ks))

    def test_states_both_totals(self):
        self.assertIn("4 Konstrukte", self.body)
        self.assertIn("6 Items", self.body)

    def test_allocation_table_carries_every_item_once(self):
        for item_id in ("zerlegung.ZR10-01", "zerlegung.ZR20-02", "anzahl-simultan.ZR10-01"):
            self.assertEqual(self.body.count(f"`{item_id}`"), 1)

    def test_output_is_cp1252_safe(self):
        self.body.encode("cp1252")


if __name__ == "__main__":
    unittest.main()
