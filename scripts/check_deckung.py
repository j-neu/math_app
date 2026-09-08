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


def konstrukt_items_of(matrix):
    """Konstrukt-ID -> Item-IDs, die in irgendeiner Zelle dieses Konstrukts stehen.

    Ein Konstrukt ist ein (Strang x Zahlenraum)-Paar. Diagnostik gehoert zum
    Konstrukt, Uebung zur Zelle (12-blueprint.md).
    """
    result = {}
    for (strang, zr, rep), status in matrix.cells.items():
        if status == "–":
            continue
        key = f"{strang}.{zr}"
        result.setdefault(key, [])
        block = matrix.blocks.get((strang, zr, rep), {})
        for ref in split_refs(block.get("diagnostik", "")):
            if ref not in result[key]:
                result[key].append(ref)
    return result


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


def validate(matrix, known_uebungen=None, known_items=None, konstrukt_items=None):
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
            if block.get("übung", LEER) == LEER:
                errors.append(f"{label}: Status 'freigegeben' verlangt einen Eintrag in 'übung'")
            if konstrukt_items is not None:
                key = f"{strand}.{zr}"
                if not konstrukt_items.get(key):
                    errors.append(
                        f"{label}: Status 'freigegeben', aber das Konstrukt '{key}' "
                        f"hat kein Diagnostik-Item"
                    )

    for key in sorted(matrix.blocks):
        if key not in matrix.cells:
            errors.append(f"{key[0]} × {key[1]} × {key[2]}: Detailblock ohne Tabellenzeile")

    for key in matrix.duplicate_blocks:
        errors.append(f"{key[0]} × {key[1]} × {key[2]}: Detailblock mehrfach vorhanden")

    # R9 — ein Item steht nur in einer Zelle seines eigenen Konstrukts
    for key in sorted(matrix.blocks):
        strand, zr, rep = key
        block = matrix.blocks[key]
        for ref in split_refs(block.get("diagnostik", "")):
            if not ref.startswith(f"{strand}.{zr}-"):
                errors.append(
                    f"{strand} × {zr} × {rep}: R9 — Item '{ref}' gehoert nicht zum "
                    f"Konstrukt '{strand}.{zr}'"
                )

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

    return errors


def main():
    if not MATRIX_PATH.exists():
        print(f"FAIL: {MATRIX_PATH} nicht gefunden")
        sys.exit(1)
    matrix = parse_matrix(MATRIX_PATH.read_text(encoding="utf-8"))
    errors = validate(
        matrix,
        known_uebungen=load_known_uebungen(),
        known_items=load_known_items(),
        konstrukt_items=konstrukt_items_of(matrix),
    )
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
