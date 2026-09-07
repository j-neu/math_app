#!/usr/bin/env python3
"""Extrahiert den handgebauten Übungskatalog als Inventar für die Deckungsmatrix (v2-Entwurf §4).

Liest math_app/lib/services/exercise_service.dart (nur lesend) und schreibt
docs/clean-room/v2/inventory_uebungen.csv. Das Inventar sagt je Matrixzelle,
welches kindseitige Material bereits existiert.

Exit 0 wenn geschrieben, Exit 1 bei Parse-Problemen.
"""

import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DART = ROOT / "math_app" / "lib" / "services" / "exercise_service.dart"
EXERCISES_DIR = ROOT / "math_app" / "lib" / "exercises"
OUT = ROOT / "docs" / "clean-room" / "v2" / "inventory_uebungen.csv"

TOP_LEVEL = re.compile(r"^    Exercise\($", re.MULTILINE)
ID_RE = re.compile(r"^\s*id:\s*'([^']+)'", re.MULTILINE)
TITLE_RE = re.compile(r"^\s*title:\s*'([^']+)'", re.MULTILINE)
TAGS_RE = re.compile(r"^\s*skillTags:\s*\[([^\]]*)\]", re.MULTILINE | re.DOTALL)
WIDGET_RE = re.compile(r"=>\s*(\w+)\(")


def parse_exercises(source):
    """Return one dict per top-level Exercise( entry, nested configs ignored."""
    rows = []
    chunks = TOP_LEVEL.split(source)[1:]
    for chunk in chunks:
        id_m = ID_RE.search(chunk)
        title_m = TITLE_RE.search(chunk)
        if not id_m or not title_m:
            continue
        tags = []
        tags_m = TAGS_RE.search(chunk)
        if tags_m:
            tags = [t.strip().strip("'") for t in tags_m.group(1).split(",") if t.strip()]
        widget_m = WIDGET_RE.search(chunk)
        rows.append({
            "exercise_id": id_m.group(1),
            "title": title_m.group(1),
            "widget_class": widget_m.group(1) if widget_m else "",
            "skill_tags": tags,
        })
    return rows


def level_widgets_for(widget_class):
    """Count the level widgets a coordinator imports — the scaffolding already built."""
    if not widget_class:
        return 0
    snake = re.sub(r"(?<!^)(?=[A-Z])", "_", widget_class).lower()
    candidates = [p for p in EXERCISES_DIR.glob("*.dart") if p.stem in (snake, snake.replace("_exercise", "") + "_exercise")]
    if not candidates:
        candidates = [p for p in EXERCISES_DIR.glob("*.dart") if widget_class in p.read_text(encoding="utf-8")[:4000]]
    seen = set()
    for path in candidates[:1]:
        for m in re.finditer(r"^import '\.\./widgets/([^']+)';", path.read_text(encoding="utf-8"), re.MULTILINE):
            seen.add(m.group(1))
    return len(seen)


def main():
    if not DART.exists():
        print(f"FAIL: {DART} nicht gefunden")
        sys.exit(1)
    rows = parse_exercises(DART.read_text(encoding="utf-8"))
    if not rows:
        print("FAIL: keine Exercise-Einträge gefunden — hat sich die Dart-Struktur geändert?")
        sys.exit(1)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerow(["exercise_id", "title", "widget_class", "skill_tags", "level_widgets"])
        for row in rows:
            writer.writerow([
                row["exercise_id"],
                row["title"],
                row["widget_class"],
                " ".join(row["skill_tags"]),
                level_widgets_for(row["widget_class"]),
            ])
    print(f"OK: {len(rows)} Übungen inventarisiert -> {OUT.relative_to(ROOT)}")
    sys.exit(0)


if __name__ == "__main__":
    main()
