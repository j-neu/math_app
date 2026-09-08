#!/usr/bin/env python3
"""Prüft die Diagnostik-Items gegen die Itemregeln I1-I12 (v2-Entwurf §5.1, §8).

Der mechanische Boden unter Jakobs Urteil, nicht sein Ersatz: geprueft wird, was
eine Maschine entscheiden kann - Satz- und Wortzahl, verratene Verfahren,
Antwortarität, Feldbeschriftung, Darstellungsschluessel gegen das Register,
Verankerung in Konstrukt und Zelle, der Deckel bei 5 fuer die Simultanerfassung.

Jede Regel faengt eine Defektklasse ab, die v1 tatsaechlich ausgeliefert hat.
Die Regeltexte stehen in docs/clean-room/v2/14-itemregeln.md.

Exit 0 wenn sauber, Exit 1 mit je einer FAIL-Zeile pro Problem.
"""

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

from check_deckung import MATRIX_PATH, parse_matrix
from derive_ableitungen import konstrukte

ROOT = Path(__file__).resolve().parents[1]
V2 = ROOT / "docs" / "clean-room" / "v2"
ITEMS_DIR = V2 / "items"
DARSTELLUNGEN_PATH = V2 / "15-darstellungen.md"
DART_ROOT = ROOT / "math_app" / "lib"

LEER = "—"

SCALAR_FIELDS = (
    "item-id",
    "konstrukt",
    "zelle",
    "darstellung",
    "darstellung-konfiguration",
    "blitz",
    "prompt",
    "audio",
    "quelle",
    "eigenstaendigkeit",
    "reviewer",
)
LIST_FIELDS = ("antwortfelder", "erwartete-antwort", "fehlersignatur")

FIELD_RE = re.compile(r"^- \*\*([a-zä-ü-]+):\*\*\s*(.*)$", re.MULTILINE)
SUBBULLET_RE = re.compile(r"^  - (.+)$")
ZELLE_RE = re.compile(r"^([a-z0-9-]+) × (\w+) × (\w+)$")
FELD_LABEL_RE = re.compile(r"^`([a-z0-9_-]+)`\s+—\s+(.+)$")
FELD_WERT_RE = re.compile(r"^`([a-z0-9_-]+)`\s*=\s*(.+)$")
SIGNATUR_RE = re.compile(r"^`[^`]+`\s+—\s+(.+)$")
REGISTER_ROW_RE = re.compile(r"^\|\s*`([a-z-]+)`\s*\|\s*`?([\w—-]+)`?\s*\|", re.MULTILINE)

MAX_WOERTER = 12

# I3 — Wendungen, die dem Kind das Verfahren verraten. Alle aus v1 belegt.
VERBOTENE_WENDUNGEN = (
    "Zerlege",
    "Rechne zuerst",
    "In der Tabelle stehen",
    "Trage ein",
    "Schreib sie so auf",
    "Und wenn du",
    "Sieh dir",
    "Denk daran",
    "Nimm zuerst",
    "Zähl in",
)

# I4 — Nebensatzmarker und Zahlwoerter.
NEBENSATZ_MARKER = (
    "weil", "wenn", "damit", "dass", "nachdem", "obwohl", "während",
)
ZAHLWOERTER = (
    "eins", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun",
    "zehn", "elf", "zwölf", "zwanzig", "dreißig", "vierzig", "fünfzig",
    "hundert",
)
# Fachwoerter, die laenger als die Lesbarkeitsgrenze sind und trotzdem
# unvermeidlich - sie benennen das Material, nach dem gefragt wird.
LANGE_FACHWOERTER = (
    "stellenwerttafel", "rechenschiffchen", "zwanzigerfeld", "hunderterfeld",
    "zehnerstange", "zehnerstangen", "zahlenstrahl", "einerwürfel",
)


@dataclass
class Item:
    path: Path
    fields: dict = field(default_factory=dict)
    listen: dict = field(default_factory=dict)


def parse_item(text, path):
    """Zerlegt eine Item-Datei in Skalarfelder und Unterlisten."""
    item = Item(path=path)
    lines = text.splitlines()
    current_list = None
    for line in lines:
        sub = SUBBULLET_RE.match(line)
        if sub and current_list is not None:
            item.listen[current_list].append(sub.group(1).strip())
            continue
        match = FIELD_RE.match(line)
        if not match:
            if line.strip() and not line.startswith("  "):
                current_list = None
            continue
        name, value = match.group(1).strip(), match.group(2).strip()
        if name in LIST_FIELDS:
            item.listen[name] = []
            current_list = name
        else:
            item.fields[name] = value
            current_list = None
    return item


def load_darstellungen():
    """key -> Widget-Klasse, aus 15-darstellungen.md."""
    if not DARSTELLUNGEN_PATH.exists():
        return {}
    text = DARSTELLUNGEN_PATH.read_text(encoding="utf-8")
    return {m.group(1): m.group(2) for m in REGISTER_ROW_RE.finditer(text)}


def load_widget_klassen():
    """Alle im Flutter-Quelltext definierten Widget-Klassen."""
    klassen = set()
    if not DART_ROOT.is_dir():
        return klassen
    pattern = re.compile(r"^class (\w+) extends", re.MULTILINE)
    for path in DART_ROOT.rglob("*.dart"):
        klassen.update(pattern.findall(path.read_text(encoding="utf-8", errors="ignore")))
    return klassen


def item_files(items_dir):
    """Item-Dateien, ohne TEMPLATE.md, README.md und Namen mit fuehrendem '_'."""
    if not items_dir.is_dir():
        return []
    return sorted(
        p for p in items_dir.glob("*.md")
        if p.name not in ("TEMPLATE.md", "README.md") and not p.name.startswith("_")
    )


def validate_item(item, konstrukt_ids, live_cells, darstellungen, widget_klassen):
    """Gibt eine Liste deutscher Fehlermeldungen zurueck; leer heisst sauber."""
    errors = []
    name = item.path.name

    for feld in SCALAR_FIELDS:
        if not item.fields.get(feld):
            errors.append(f"{name}: Feld '{feld}' fehlt oder ist leer")
    for feld in LIST_FIELDS:
        if feld not in item.listen:
            errors.append(f"{name}: Liste '{feld}' fehlt")
        elif not item.listen[feld]:
            errors.append(f"{name}: Liste '{feld}' ist leer")

    # I5 — Aritaet und Beschriftung
    felder, werte = {}, {}
    for zeile in item.listen.get("antwortfelder", []):
        m = FELD_LABEL_RE.match(zeile)
        if not m:
            errors.append(f"{name}: I5 — Antwortfeld ohne Label: '{zeile}'")
            continue
        felder[m.group(1)] = m.group(2)
    for zeile in item.listen.get("erwartete-antwort", []):
        m = FELD_WERT_RE.match(zeile)
        if not m:
            errors.append(f"{name}: I5 — erwartete Antwort ohne Feldbezug: '{zeile}'")
            continue
        werte[m.group(1)] = m.group(2)
    if felder and werte and set(felder) != set(werte):
        fehlend = sorted(set(felder) ^ set(werte))
        errors.append(
            f"{name}: I5 — Antwortfelder und erwartete Antworten stimmen nicht ueberein "
            f"({', '.join(fehlend)})"
        )

    # I6 — Darstellung
    darstellung = item.fields.get("darstellung", "")
    konfiguration = item.fields.get("darstellung-konfiguration", "")
    if darstellung and darstellung not in darstellungen:
        errors.append(
            f"{name}: I6 — Darstellung '{darstellung}' steht nicht im Register "
            f"(15-darstellungen.md)"
        )
    elif darstellung == "keine":
        if konfiguration != LEER:
            errors.append(
                f"{name}: I6 — Darstellung 'keine' verlangt eine leere "
                f"darstellung-konfiguration ('{LEER}')"
            )
    elif darstellung:
        if not konfiguration or konfiguration == LEER:
            errors.append(
                f"{name}: I6 — Darstellung '{darstellung}' ohne "
                f"darstellung-konfiguration"
            )
        klasse = darstellungen[darstellung]
        if klasse != LEER and klasse not in widget_klassen:
            errors.append(
                f"{name}: I6 — Widget-Klasse '{klasse}' aus dem Register existiert "
                f"nicht im Flutter-Quelltext"
            )

    # I10 — Verankerung
    item_id = item.fields.get("item-id", "")
    konstrukt = item.fields.get("konstrukt", "")
    if item_id and item_id != item.path.stem:
        errors.append(
            f"{name}: I10 — item-id '{item_id}' und Dateiname stimmen nicht ueberein"
        )
    if konstrukt and konstrukt not in konstrukt_ids:
        errors.append(
            f"{name}: I10 — Konstrukt '{konstrukt}' steht nicht in der Konstruktkarte"
        )
    if item_id and konstrukt and not item_id.startswith(f"{konstrukt}-"):
        errors.append(
            f"{name}: I10 — item-id '{item_id}' beginnt nicht mit '{konstrukt}-'"
        )
    zelle = item.fields.get("zelle", "")
    m = ZELLE_RE.match(zelle)
    if zelle and not m:
        errors.append(f"{name}: I10 — Zelle '{zelle}' hat nicht die Form 'strang × ZR × rep'")
    elif m:
        key = (m.group(1), m.group(2), m.group(3))
        if key not in live_cells:
            errors.append(
                f"{name}: I10 — Zelle '{zelle}' gibt es in der Matrix nicht oder sie ist "
                f"als nicht abgedeckt markiert"
            )
        if konstrukt and konstrukt != f"{m.group(1)}.{m.group(2)}":
            errors.append(
                f"{name}: I10 — Zelle '{zelle}' gehoert nicht zum Konstrukt '{konstrukt}'"
            )

    # I1-I4 — Sprache des Prompts
    prompt = item.fields.get("prompt", "")
    if prompt:
        saetze = [s for s in re.split(r"[.?!]+", prompt) if s.strip()]
        if len(saetze) > 1:
            errors.append(
                f"{name}: I1 — Prompt hat {len(saetze)} Saetze, erlaubt ist einer"
            )
        woerter = prompt.split()
        if len(woerter) > MAX_WOERTER:
            errors.append(
                f"{name}: I2 — Prompt hat {len(woerter)} Woerter, erlaubt sind "
                f"{MAX_WOERTER}"
            )
        for wendung in VERBOTENE_WENDUNGEN:
            if wendung.lower() in prompt.lower():
                errors.append(
                    f"{name}: I3 — Prompt verraet das Verfahren: '{wendung}'"
                )
        blank = [w.strip(".,;:?!„“\"'()").lower() for w in woerter]
        for marker in NEBENSATZ_MARKER:
            if marker in blank:
                errors.append(f"{name}: I4 — Nebensatzmarker '{marker}' im Prompt")
        for zahlwort in ZAHLWOERTER:
            if zahlwort in blank:
                errors.append(
                    f"{name}: I4 — Zahlwort '{zahlwort}' im Prompt, Ziffern verwenden"
                )
        for wort in blank:
            if len(wort) > 14 and wort not in LANGE_FACHWOERTER:
                errors.append(f"{name}: I4 — zu langes Wort im Prompt: '{wort}'")

    # I7 — Simultanerfassung ist bei 5 gedeckelt
    if item.fields.get("konstrukt", "").startswith("anzahl-simultan"):
        for zeile in item.listen.get("erwartete-antwort", []):
            for zahl in re.findall(r"\d+", zeile):
                if int(zahl) > 5:
                    errors.append(
                        f"{name}: I7 — Simultanerfassung mit erwarteter Antwort {zahl}; "
                        f"ueber 5 misst das Item Zaehlen"
                    )

    # I8 — mindestens zwei benannte Fehlersignaturen
    signaturen = item.listen.get("fehlersignatur", [])
    if len(signaturen) < 2:
        errors.append(
            f"{name}: I8 — nur {len(signaturen)} Fehlersignatur(en), mindestens zwei "
            f"noetig"
        )
    for zeile in signaturen:
        if not SIGNATUR_RE.match(zeile):
            errors.append(
                f"{name}: I8 — Fehlersignatur ohne Bedeutung: '{zeile}'"
            )

    # I9 — Audio-Vertrag
    audio = item.fields.get("audio", "")
    erwartet = f"audio/v2/{item.path.stem}.mp3"
    if audio and audio != erwartet:
        errors.append(f"{name}: I9 — audio muss '{erwartet}' lauten, steht aber '{audio}'")

    return errors


def main():
    matrix = parse_matrix(MATRIX_PATH.read_text(encoding="utf-8"))
    konstrukt_ids = {k.id for k in konstrukte(matrix)}
    live_cells = {key for key, status in matrix.cells.items() if status != "–"}
    darstellungen = load_darstellungen()
    widget_klassen = load_widget_klassen()

    paths = item_files(ITEMS_DIR)
    errors = []
    for path in paths:
        item = parse_item(path.read_text(encoding="utf-8"), path)
        errors += validate_item(
            item, konstrukt_ids, live_cells, darstellungen, widget_klassen
        )

    print(
        f"check_item_quality: {len(paths)} Items gegen {len(konstrukt_ids)} Konstrukte "
        f"und {len(darstellungen)} Darstellungen geprueft"
    )
    if errors:
        for err in errors:
            print("FAIL:", err)
        return 1
    print("OK: jedes Item verankert, beschriftet und regelkonform")
    return 0


if __name__ == "__main__":
    sys.exit(main())
