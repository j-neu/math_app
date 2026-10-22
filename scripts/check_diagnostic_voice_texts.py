"""Gate for the diagnostic voice texts (spec 2026-10-22 §2).

Every row needs Sprechtext + Hilfe1..3, each hint at most 30 words, and
Hilfe3 (the direct instruction) must not give away the answer.
Usage: uv run --no-project python scripts/check_diagnostic_voice_texts.py
"""
import csv, re, sys, pathlib

CSV = pathlib.Path(__file__).resolve().parents[1] / 'math_app/Research/diagnostic_v4_master.csv'
FIELDS = ['Sprechtext', 'Hilfe1', 'Hilfe2', 'Hilfe3']
MAX_WORDS = 30
# Tap-choice answers: a direct instruction may name both options
# ("tippst du auf ja, sonst auf nein") without giving anything away.
# Help must build calculating, never counting (Jakob, 2026-10-22): no
# "zähle", "weiterzählen", "zusammenzählen", finger counting. "erzählen" is fine.
COUNTING = re.compile(r'(?<!er)zähl|mit den Fingern|Schritte? (?:weiter|rückwärts)', re.I)
CHOICE_WORDS = {'ja', 'nein', 'gerade', 'ungerade', 'größer', 'kleiner'}


def _answer_tokens(answer: str) -> list[str]:
    return [t for t in re.split(r'[,;/\s]+', answer.strip()) if t]


def check(rows):
    errors = []
    for r in rows:
        n = r['ListNumber']
        for f in FIELDS:
            text = (r.get(f) or '').strip()
            if not text:
                errors.append(f'Q{n}: {f} fehlt')
            elif f != 'Sprechtext' and len(text.split()) > MAX_WORDS:
                errors.append(f'Q{n}: {f} zu lang ({len(text.split())} Wörter)')
            if f != 'Sprechtext' and COUNTING.search(text):
                errors.append(f'Q{n}: {f} sagt Zählen: {text}')
        h3 = r.get('Hilfe3') or ''
        tokens = _answer_tokens(r.get('CorrectAnswer') or '')
        if all(t.lower() in CHOICE_WORDS for t in tokens):
            tokens = []
        if tokens and all(re.search(rf'(?<![\d\w]){re.escape(t)}(?![\d\w])', h3, re.I) for t in tokens):
            errors.append(f'Q{n}: Hilfe3 verrät die Antwort')
    return errors


def main():
    rows = list(csv.DictReader(open(CSV, encoding='utf-8')))
    errors = check(rows)
    for e in errors:
        print(e)
    print(f'{len(rows)} Zeilen, {len(errors)} Fehler')
    sys.exit(1 if errors else 0)


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    main()
