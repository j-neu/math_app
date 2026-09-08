import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from check_item_quality import parse_item, validate_item

FIXTURES = Path(__file__).resolve().parent / "fixtures" / "items"

KONSTRUKT_IDS = {"verdoppeln-halbieren.ZR20", "anzahl-simultan.ZR10"}
LIVE_CELLS = {
    ("verdoppeln-halbieren", "ZR20", "symbolisch"),
    ("verdoppeln-halbieren", "ZR20", "enaktiv"),
    ("anzahl-simultan", "ZR10", "ikonisch"),
}
DARSTELLUNGEN = {
    "keine": "—",
    "rekenrek-blitz": "RekenrekFlashWidget",
    "zehnerfeld": "ZehnerfeldWidget",
}
WIDGETS = {"RekenrekFlashWidget", "ZehnerfeldWidget"}


def load(name):
    path = FIXTURES / name
    return parse_item(path.read_text(encoding="utf-8"), path)


def check(item):
    return validate_item(item, KONSTRUKT_IDS, LIVE_CELLS, DARSTELLUNGEN, WIDGETS)


class ParseItemTest(unittest.TestCase):
    def setUp(self):
        self.item = load("verdoppeln-halbieren.ZR20-01.md")

    def test_reads_scalar_fields(self):
        self.assertEqual(self.item.fields["item-id"], "verdoppeln-halbieren.ZR20-01")
        self.assertEqual(self.item.fields["prompt"], "Rechne: 8 + 8")
        self.assertEqual(self.item.fields["blitz"], "nein")

    def test_reads_sub_bullet_lists(self):
        self.assertEqual(self.item.listen["antwortfelder"], ["`ergebnis` — Ergebnis"])
        self.assertEqual(self.item.listen["erwartete-antwort"], ["`ergebnis` = 16"])
        self.assertEqual(len(self.item.listen["fehlersignatur"]), 3)

    def test_a_list_field_is_not_also_a_scalar(self):
        self.assertNotIn("antwortfelder", self.item.fields)


class CleanItemTest(unittest.TestCase):
    def test_the_reference_item_passes_every_rule(self):
        self.assertEqual(check(load("verdoppeln-halbieren.ZR20-01.md")), [])


class StructuralRulesTest(unittest.TestCase):
    def mutate(self, **changes):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        for old, new in changes.items():
            text = text.replace(old.replace("_", " "), new)
        return check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))

    def test_i5_answer_field_count_must_match_expected_answer_count(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace(
            "  - `ergebnis` — Ergebnis",
            "  - `ergebnis` — Ergebnis\n  - `zweites` — Zweites",
        )
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I5" in e for e in errors), errors)

    def test_i5_every_answer_field_needs_a_label(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace("  - `ergebnis` — Ergebnis", "  - `ergebnis`")
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I5" in e and "Label" in e for e in errors), errors)

    def test_i6_unknown_darstellung_key_fails(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace("**darstellung:** keine", "**darstellung:** wolkenbild")
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I6" in e for e in errors), errors)

    def test_i6_darstellung_keine_requires_an_empty_configuration(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace(
            "**darstellung-konfiguration:** —", "**darstellung-konfiguration:** oben 8"
        )
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I6" in e for e in errors), errors)

    def test_i6_a_real_darstellung_requires_a_configuration(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace("**darstellung:** keine", "**darstellung:** zehnerfeld")
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I6" in e and "konfiguration" in e for e in errors), errors)

    def test_i10_unknown_konstrukt_fails(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace(
            "**konstrukt:** verdoppeln-halbieren.ZR20",
            "**konstrukt:** verdoppeln-halbieren.ZR50",
        )
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I10" in e for e in errors), errors)

    def test_i10_cell_must_be_live_in_the_matrix(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace(
            "**zelle:** verdoppeln-halbieren × ZR20 × symbolisch",
            "**zelle:** verdoppeln-halbieren × ZR20 × ikonisch",
        )
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I10" in e for e in errors), errors)

    def test_i10_cell_must_belong_to_the_konstrukt(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace(
            "**zelle:** verdoppeln-halbieren × ZR20 × symbolisch",
            "**zelle:** anzahl-simultan × ZR10 × ikonisch",
        )
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I10" in e for e in errors), errors)

    def test_i10_item_id_must_match_the_filename(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace(
            "**item-id:** verdoppeln-halbieren.ZR20-01",
            "**item-id:** verdoppeln-halbieren.ZR20-09",
        )
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I10" in e and "Dateiname" in e for e in errors), errors)

    def test_a_missing_field_is_reported_by_name(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace("- **audio:** audio/v2/verdoppeln-halbieren.ZR20-01.mp3\n", "")
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("audio" in e for e in errors), errors)


class LanguageRulesTest(unittest.TestCase):
    def with_prompt(self, prompt):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace("**prompt:** Rechne: 8 + 8", f"**prompt:** {prompt}")
        return check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))

    def test_i1_more_than_one_sentence_fails(self):
        errors = self.with_prompt("Sieh die Zahl an. Wie viel ist 8 + 8?")
        self.assertTrue(any("I1" in e for e in errors), errors)

    def test_i1_a_single_question_mark_is_fine(self):
        errors = self.with_prompt("Wie viel ist 8 + 8?")
        self.assertEqual(errors, [])

    def test_i2_more_than_twelve_words_fails(self):
        errors = self.with_prompt(
            "Rechne die Aufgabe 8 + 8 aus und schreibe dein Ergebnis in das Kaestchen dort"
        )
        self.assertTrue(any("I2" in e for e in errors), errors)

    def test_i3_banned_procedure_phrase_fails(self):
        errors = self.with_prompt("Zerlege die 8 in zwei Teile")
        self.assertTrue(any("I3" in e for e in errors), errors)

    def test_i3_reports_which_phrase_it_found(self):
        errors = self.with_prompt("Trage ein: 8 + 8")
        self.assertTrue(any("Trage ein" in e for e in errors), errors)

    def test_i4_subordinate_clause_marker_fails(self):
        errors = self.with_prompt("Rechne 8 + 8, wenn du bereit bist")
        self.assertTrue(any("I4" in e for e in errors), errors)

    def test_i4_number_word_fails(self):
        errors = self.with_prompt("Verdopple acht")
        self.assertTrue(any("I4" in e for e in errors), errors)

    def test_i4_allows_a_long_subject_term(self):
        errors = self.with_prompt("Wie viele Zehner hat die Stellenwerttafel?")
        self.assertEqual(errors, [])

    def test_i8_fewer_than_two_error_signatures_fails(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace(
            "  - `17` — ±1 nach oben: zählend gerechnet, ein Schritt zu viel\n", ""
        ).replace(
            "  - `10` — die Verdopplung wird als Ergänzung zur Zehn missdeutet\n", ""
        )
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I8" in e for e in errors), errors)

    def test_i9_audio_path_must_follow_the_naming_contract(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace(
            "**audio:** audio/v2/verdoppeln-halbieren.ZR20-01.mp3",
            "**audio:** audio/v2/irgendwas.mp3",
        )
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I9" in e for e in errors), errors)


class V1RegressionCorpusTest(unittest.TestCase):
    """Jede Regel gegen einen Defekt, den v1 tatsaechlich ausgeliefert hat."""

    def test_q44_stellenwert_script_is_rejected_for_length_and_procedure(self):
        errors = check(load("_v1-q44-stellenwert.md"))
        self.assertTrue(any("I1" in e for e in errors), errors)
        self.assertTrue(any("I2" in e for e in errors), errors)
        self.assertTrue(any("I3" in e for e in errors), errors)

    def test_q07_vorgaenger_nachfolger_is_rejected_for_arity(self):
        errors = check(load("_v1-q07-vorgaenger-nachfolger.md"))
        self.assertTrue(any("I5" in e for e in errors), errors)

    def test_q15_zerlegung_is_rejected_for_giving_away_the_form(self):
        errors = check(load("_v1-q15-zerlegung.md"))
        self.assertTrue(any("I3" in e for e in errors), errors)

    def test_subitizing_at_eight_is_rejected_by_the_cap(self):
        errors = check(load("_v1-q-subitizing-acht.md"))
        self.assertTrue(any("I7" in e for e in errors), errors)


if __name__ == "__main__":
    unittest.main()
