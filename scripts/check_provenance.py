#!/usr/bin/env python3
"""Provenance completeness and consistency check (tasks.md R1.6 / R3.3).

Scans a clean-room tree (default: <repo>/docs/clean-room) and fails when:

  (a) any item file under items/ (excluding TEMPLATE.md and filenames
      starting with "_") is missing one of the core template fields:
      Item ID, Construct, Difficulty target, Wording, Expected correct
      answer, Maps to skills. A field counts as present when its label
      appears as a Markdown heading (# ...) or a bold label (**...**)
      anywhere in the file (case-insensitive).

  (b) any item ID referenced in provenance.csv (column 1, type item or
      item-deepdive) has no matching item file, OR any item file's ID
      (the value of its first "Item ID:" line, else its filename stem)
      has no row in provenance.csv.

  (c) any skill file under skills/ (excluding README.md and filenames
      starting with "_") is missing one of the skill template fields:
      Title DE, Description DE.

  (d) any skill ID referenced in provenance.csv (type skill) has no
      matching skill file, OR any skill file's ID (the value of its
      first "Skill ID:" line, else its filename stem) has no row in
      provenance.csv.

With --all, every provenance row must additionally have reviewed_by and
reviewed_on filled and sources_cited non-empty (used as the R7.3 gate).

Exit status: 0 with a final "OK" line, or 1 with "FAIL: N problems".
Python 3.12, stdlib only.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

DEFAULT_ROOT = Path(__file__).resolve().parent.parent / "docs" / "clean-room"

REQUIRED_FIELDS = (
    "Item ID",
    "Construct",
    "Difficulty target",
    "Wording",
    "Expected correct answer",
    "Maps to skills",
)

SKILL_REQUIRED_FIELDS = (
    "Title DE",
    "Description DE",
)

FIELD_COLUMNS = {
    "reviewed_by": 5,
    "reviewed_on": 6,
    "sources_cited": 4,
}


def clean_cell(value: str) -> str:
    """Strip surrounding quotes and whitespace from a CSV cell."""
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
        value = value[1:-1].strip()
    return value


def field_present(text_lower: str, label: str) -> bool:
    """True if the label appears within a Markdown heading or bold span."""
    escaped = re.escape(label.lower())
    if re.search(r"^#{1,6}[^\n]*" + escaped, text_lower, re.MULTILINE):
        return True
    if re.search(r"\*\*[^*]*" + escaped + r"[^*]*\*\*", text_lower):
        return True
    return False


def id_of_file(path: Path, label: str) -> str:
    """First '<label> ID:' value at line start, else the filename stem."""
    pattern = re.compile(r"\s*" + re.escape(label) + r"\s*id\s*:\s*(.+)", re.IGNORECASE)
    try:
        for line in path.read_text(encoding="utf-8").splitlines():
            match = pattern.match(line)
            if match:
                return match.group(1).strip()
    except OSError:
        pass
    return path.stem


def item_id_of_file(path: Path) -> str:
    """First 'Item ID:' value, else the filename stem."""
    return id_of_file(path, "item")


def skill_id_of_file(path: Path) -> str:
    """First 'Skill ID:' value, else the filename stem."""
    return id_of_file(path, "skill")


def item_files(items_dir: Path) -> list[Path]:
    """Item .md files, excluding TEMPLATE.md and names starting with '_'."""
    if not items_dir.is_dir():
        return []
    files = []
    for path in sorted(items_dir.iterdir()):
        if path.suffix.lower() != ".md":
            continue
        if path.name == "TEMPLATE.md" or path.name.startswith("_"):
            continue
        files.append(path)
    return files


def skill_files(skills_dir: Path) -> list[Path]:
    """Skill .md files, excluding README.md and names starting with '_'."""
    if not skills_dir.is_dir():
        return []
    files = []
    for path in sorted(skills_dir.iterdir()):
        if path.suffix.lower() != ".md":
            continue
        if path.name == "README.md" or path.name.startswith("_"):
            continue
        files.append(path)
    return files


def split_by_type(rows: list[list[str]]) -> tuple[list[list[str]], list[list[str]]]:
    """Split provenance rows into (skill rows, other rows)."""
    skill_rows = [row for row in rows if len(row) > 1 and row[1] == "skill"]
    other_rows = [row for row in rows if row not in skill_rows]
    return skill_rows, other_rows


def read_provenance(prov_path: Path) -> list[list[str]]:
    """All data rows of provenance.csv (header and blank rows skipped)."""
    rows = []
    with prov_path.open(encoding="utf-8", newline="") as handle:
        reader = csv.reader(handle)
        for row in reader:
            if not row:
                continue
            if row[0].strip().lower() == "artifact_id":
                continue
            rows.append([clean_cell(cell) for cell in row])
    return rows


def check_tree(root: Path, require_complete: bool) -> list[str]:
    problems: list[str] = []

    prov_path = root / "provenance.csv"
    if not prov_path.is_file():
        problems.append(f"provenance.csv not found under {root}")
        return problems
    rows = read_provenance(prov_path)

    items_dir = root / "items"
    skills_dir = root / "skills"
    files = item_files(items_dir)
    skill_paths = skill_files(skills_dir)

    required = [f.lower() for f in REQUIRED_FIELDS]
    for path in files:
        try:
            text = path.read_text(encoding="utf-8").lower()
        except OSError as exc:
            problems.append(f"cannot read {path}: {exc}")
            continue
        for label, want in zip(REQUIRED_FIELDS, required):
            if not field_present(text, label):
                problems.append(
                    f"{path}: missing required field '{label}' "
                    f"(as heading or bold label, case-insensitive)"
                )

    skill_required = [f.lower() for f in SKILL_REQUIRED_FIELDS]
    for path in skill_paths:
        try:
            text = path.read_text(encoding="utf-8").lower()
        except OSError as exc:
            problems.append(f"cannot read {path}: {exc}")
            continue
        for label, want in zip(SKILL_REQUIRED_FIELDS, skill_required):
            if not field_present(text, label):
                problems.append(
                    f"{path}: missing required field '{label}' "
                    f"(as heading or bold label, case-insensitive)"
                )

    skill_rows, item_rows = split_by_type(rows)

    line_numbers_by_id: dict[str, list[str]] = {}
    for index, row in enumerate(rows, start=2):
        if not row[0]:
            continue
        line_numbers_by_id.setdefault(row[0], []).append(str(index))

    file_ids = {item_id_of_file(path): path for path in files}
    item_ids = {row[0] for row in item_rows if row[0]}

    for artifact_id in sorted(item_ids):
        if artifact_id not in file_ids:
            problems.append(
                f"provenance.csv line(s) {', '.join(line_numbers_by_id[artifact_id])}: "
                f"row references item ID '{artifact_id}' with no matching "
                f"item file under {items_dir}"
            )

    for path in files:
        file_id = item_id_of_file(path)
        if file_id not in item_ids:
            problems.append(
                f"{path}: item ID '{file_id}' has no row in provenance.csv"
            )

    skill_ids = {skill_id_of_file(path): path for path in skill_paths}
    skill_ids_in_csv = {row[0] for row in skill_rows if row[0]}

    for artifact_id in sorted(skill_ids_in_csv):
        if artifact_id not in skill_ids:
            problems.append(
                f"provenance.csv line(s) {', '.join(line_numbers_by_id[artifact_id])}: "
                f"row references skill ID '{artifact_id}' with no matching "
                f"skill file under {skills_dir}"
            )

    for path in skill_paths:
        file_id = skill_id_of_file(path)
        if file_id not in skill_ids_in_csv:
            problems.append(
                f"{path}: skill ID '{file_id}' has no row in provenance.csv"
            )

    if require_complete:
        for index, row in enumerate(rows, start=2):
            if not row[0]:
                continue
            missing = [
                name
                for name, col in FIELD_COLUMNS.items()
                if col >= len(row) or not row[col]
            ]
            if missing:
                problems.append(
                    f"provenance.csv line {index} (ID '{row[0]}'): "
                    f"missing {', '.join(missing)}"
                )

    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check clean-room provenance completeness and consistency."
    )
    parser.add_argument(
        "root",
        nargs="?",
        default=str(DEFAULT_ROOT),
        help="clean-room root containing items/ and provenance.csv "
             "(default: the real tree under docs/clean-room)",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="also require reviewed_by, reviewed_on and sources_cited "
             "on every provenance row (R7.3 gate)",
    )
    args = parser.parse_args(argv)

    root = Path(args.root)
    if not root.is_dir():
        print(f"ERROR: root directory not found: {root}")
        return 1

    problems = check_tree(root, require_complete=args.all)

    for problem in problems:
        print(problem)

    if problems:
        print(f"FAIL: {len(problems)} problems")
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
