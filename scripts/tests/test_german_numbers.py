import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
from german_numbers import number_to_words, spoken


def test_numbers():
    cases = {0: 'null', 1: 'eins', 7: 'sieben', 11: 'elf', 16: 'sechzehn', 17: 'siebzehn',
             20: 'zwanzig', 21: 'einundzwanzig', 30: 'dreißig', 65: 'fünfundsechzig',
             70: 'siebzig', 99: 'neunundneunzig', 100: 'hundert', 101: 'hunderteins',
             345: 'dreihundertfünfundvierzig', 1000: 'tausend'}
    for n, w in cases.items():
        assert number_to_words(n) == w, n


def test_spoken_replaces_digits_and_blanks():
    assert spoken('60, 65, 70, __') == 'sechzig, fünfundsechzig, siebzig, …'
    assert spoken('Rechne plus 5.') == 'Rechne plus fünf.'
    assert spoken('1 Punkt') == 'ein Punkt'


def test_spoken_reads_operators():
    assert spoken('5 + 3 = __') == 'fünf plus drei gleich …'
    assert spoken('9 - 5') == 'neun minus fünf'
