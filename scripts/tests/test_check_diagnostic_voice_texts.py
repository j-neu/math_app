import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
from check_diagnostic_voice_texts import check

def row(**kw):
    base = dict(ListNumber='24', CorrectAnswer='75, 80, 85, 90', Sprechtext='Zähle weiter.',
                Hilfe1='Die Zahlen werden immer um 5 größer.',
                Hilfe2='Was kommt nach 70, wenn du 5 weiterzählst?',
                Hilfe3='Rechne zu jeder Zahl plus 5.')
    base.update(kw)
    return base

def test_clean_row_passes():
    assert check([row()]) == []

def test_missing_text_fails():
    assert any('Hilfe2' in e for e in check([row(Hilfe2='')]))

def test_hint3_must_not_contain_answer():
    assert any('verrät' in e for e in check([row(Hilfe3='Schreib 75, 80, 85, 90.')]))

def test_single_answer_leak_is_whole_word_only():
    # answer 9 must not match inside 90 or 19
    assert check([row(CorrectAnswer='9', Hilfe3='Die 19 und die 90 gehören nicht dazu.')]) == []
    assert any('verrät' in e for e in check([row(CorrectAnswer='9', Hilfe3='Es sind 9.')]))

def test_overlong_hint_fails():
    assert any('zu lang' in e for e in check([row(Hilfe1='wort ' * 31)]))

def test_choice_word_answers_may_be_named():
    assert check([row(CorrectAnswer='ja', Hilfe3='Sind beide gleich, tippst du auf ja. Sonst auf nein.')]) == []

def test_hints_must_not_tell_the_child_to_count():
    assert any('Zählen' in e for e in check([row(Hilfe2='Schau auf die 70. Zähle 5 weiter.')]))
    assert any('Zählen' in e for e in check([row(Hilfe3='Dann zähle beide Ergebnisse zusammen.')]))
    assert check([row(Hilfe1='Welche Rechnung erzählt die gleiche Geschichte?')]) == []
