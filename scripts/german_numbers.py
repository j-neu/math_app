"""German number words for TTS input (0..1000). Displayed texts keep digits;
only the string sent to the voice engine is converted."""
import re

_ONES = ['null', 'eins', 'zwei', 'drei', 'vier', 'fünf', 'sechs', 'sieben', 'acht', 'neun',
         'zehn', 'elf', 'zwölf', 'dreizehn', 'vierzehn', 'fünfzehn', 'sechzehn', 'siebzehn',
         'achtzehn', 'neunzehn']
_TENS = {2: 'zwanzig', 3: 'dreißig', 4: 'vierzig', 5: 'fünfzig', 6: 'sechzig', 7: 'siebzig',
         8: 'achtzig', 9: 'neunzig'}


def _below_100(n: int) -> str:
    if n < 20:
        return _ONES[n]
    t, o = divmod(n, 10)
    if o == 0:
        return _TENS[t]
    unit = 'ein' if o == 1 else _ONES[o]
    return f'{unit}und{_TENS[t]}'


def number_to_words(n: int) -> str:
    if n == 1000:
        return 'tausend'
    if not 0 <= n < 1000:
        return str(n)
    h, rest = divmod(n, 100)
    if h == 0:
        return _below_100(rest)
    head = 'hundert' if h == 1 else _ONES[h] + 'hundert'
    return head if rest == 0 else head + _below_100(rest)


def spoken(text: str) -> str:
    text = re.sub(r'_{2,}', '…', text)
    text = re.sub(r'\s*\+\s*', ' plus ', text)
    text = re.sub(r'(?<=\d)\s*-\s*(?=\d)', ' minus ', text)
    text = re.sub(r'\s*=\s*', ' gleich ', text)
    # "1 Punkt" -> "ein Punkt"; a standalone 1 elsewhere stays "eins"
    text = re.sub(r'(?<![\d])1(?= [A-ZÄÖÜ][a-zäöüß])', 'ein', text)
    return re.sub(r'\d+', lambda m: number_to_words(int(m.group())), text)
