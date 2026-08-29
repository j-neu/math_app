#!/usr/bin/env python3
"""Assert mapping-rationale.md covers every item and maps only valid skill IDs (tasks.md R4.1).

Checks:
  (a) every item file in docs/clean-room/items/ has a mapping entry,
  (b) every mapped skill ID exists in docs/clean-room/skills/skills_taxonomy.csv,
  (c) no entry is empty (missing or empty 'Recommended (priority order):' line).

Exit 0 when clean, exit 1 listing the failures.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAPPING = ROOT / "docs" / "clean-room" / "foerderplan" / "mapping-rationale.md"
TAXONOMY = ROOT / "docs" / "clean-room" / "skills" / "skills_taxonomy.csv"
ITEMS_DIR = ROOT / "docs" / "clean-room" / "items"

HEADING_RE = re.compile(r"^###\s+([A-Za-z0-9][A-Za-z0-9.\-]*)\s*—", re.MULTILINE)
REC_RE = re.compile(r"^\*\*Recommended \(priority order\):\*\*\s*([^\n]*)$", re.MULTILINE)


def load_skill_ids():
    """Return the set of skill_id values (first CSV column; descriptions may contain commas)."""
    text = TAXONOMY.read_text(encoding="utf-8").strip()
    ids = set()
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        first = line.split(",", 1)[0].strip()
        if first and first != "skill_id":
            ids.add(first)
    return ids


def load_item_ids():
    ids = set()
    for path in ITEMS_DIR.glob("*.md"):
        if path.name == "TEMPLATE.md":
            continue
        ids.add(path.stem)
    return ids


def parse_entries():
    """Split mapping-rationale.md into blocks keyed by item ID."""
    text = MAPPING.read_text(encoding="utf-8")
    blocks = re.split(r"(?m)^###\s+([A-Za-z0-9][A-Za-z0-9.\-]*)\s*—", text)
    # blocks[0] = preamble, then alternating (item_id, body)
    entries = {}
    for i in range(1, len(blocks) - 1, 2):
        entries[blocks[i].strip()] = blocks[i + 1]
    return entries


def main():
    errors = []
    skill_ids = load_skill_ids()
    item_ids = load_item_ids()
    entries = parse_entries()

    missing = sorted(item_ids - set(entries))
    if missing:
        errors.append("Fehlende Einträge (kein Mapping): " + ", ".join(missing))

    extra = sorted(set(entries) - item_ids)
    if extra:
        errors.append("Einträge ohne zugehörige Item-Datei: " + ", ".join(extra))

    bad = []
    for item_id in sorted(entries):
        block = entries[item_id]
        m = REC_RE.search(block)
        if not m or not m.group(1).strip():
            errors.append(f"{item_id}: keine oder leere 'Recommended (priority order):'-Zeile")
            continue
        mapped = [tok for tok in re.split(r"[\s,]+", m.group(1).strip()) if tok]
        if not mapped:
            errors.append(f"{item_id}: keine Skill-IDs empfohlen")
            continue
        for sid in mapped:
            if sid not in skill_ids:
                bad.append(f"{item_id} -> {sid}")

    if bad:
        errors.append("Unbekannte Skill-IDs (nicht in skills_taxonomy.csv): " + ", ".join(bad))

    print(f"check_mapping: {len(entries)} Einträge, {len(item_ids)} Items, {len(skill_ids)} Skill-IDs")
    if errors:
        for err in errors:
            print("FAIL:", err)
        sys.exit(1)
    print("OK: jedes Item gemappt, alle Skill-IDs gültig, kein Eintrag leer")
    sys.exit(0)


if __name__ == "__main__":
    main()
