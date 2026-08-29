#!/usr/bin/env python3
"""R3.2 independence check: no new skill description may share a word run
with a legacy catalog description (tasks.md R3.2).

Compares every ``description_de`` extracted from the skill files under
docs/clean-room/skills against the ``description_de`` column of the legacy
``skills_taxonomy.csv``. Words are normalized the same way on both sides:
lowercase, every non-alphanumeric character becomes a space, whitespace is
collapsed. A shared run of 6 or more consecutive words is a violation.

Usage:
    python scripts/check_skill_descriptions.py \
        --new docs/clean-room/skills \
        --legacy math_app/Research/skills_taxonomy.csv

Exit status: 0 when no shared run is found, 1 otherwise.
Python 3.12, stdlib only.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

DEFAULT_NEW = Path(__file__).resolve().parent.parent / "docs" / "clean-room" / "skills"
DEFAULT_LEGACY = (
    Path(__file__).resolve().parent.parent / "_sources_private" / "skills_taxonomy_legacy.csv"
)

DESC_DE_RE = re.compile(r"\*\*\s*Description\s*DE\s*:\s*\*+\s*(.*)$", re.IGNORECASE)
NORMALIZE_RE = re.compile(r"[^\w]+")


def normalize(text: str) -> str:
    """Lowercase; non-alphanumerics -> space; collapse whitespace."""
    return NORMALIZE_RE.sub(" ", text.lower()).strip()


def words(text: str) -> list[str]:
    """Normalized word list; empty text yields an empty list."""
    normalized = normalize(text)
    return normalized.split()


def extract_description_de(md_text: str) -> str:
    """Value(s) after the **Description DE:** label, up to the next label."""
    parts: list[str] = []
    capturing = False
    for raw in md_text.splitlines():
        line = raw.strip()
        match = DESC_DE_RE.match(line)
        if match:
            capturing = True
            value = match.group(1).strip()
            if value:
                parts.append(value)
            continue
        if capturing:
            if line.startswith("**") or line.startswith("#"):
                break
            if line:
                parts.append(line)
    return " ".join(parts)


def skill_files(skills_dir: Path) -> list[Path]:
    """Skill .md files, excluding README.md and names starting with '_'."""
    if not skills_dir.is_dir():
        return []
    return [
        path
        for path in sorted(skills_dir.iterdir())
        if path.suffix.lower() == ".md"
        and path.name != "README.md"
        and not path.name.startswith("_")
    ]


def load_legacy_descriptions(csv_path: Path) -> tuple[dict[tuple[str, ...], list[str]], list[str]]:
    """description_de column as normalized word lists plus the source header."""
    header: list[str] = []
    descriptions: list[tuple[str, list[str]]] = []
    with csv_path.open(encoding="utf-8", newline="") as handle:
        reader = csv.reader(handle)
        for row in reader:
            if not row:
                continue
            if not header:
                header = row
                continue
            try:
                idx = header.index("description_de")
            except ValueError:
                raise SystemExit(
                    f"ERROR: legacy CSV {csv_path} has no 'description_de' column"
                ) from None
            if idx < len(row) and row[idx].strip():
                descriptions.append((row[0], words(row[idx])))
    return header, descriptions


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check that new skill descriptions share no 6-word run "
                    "with legacy catalog descriptions."
    )
    parser.add_argument(
        "--new",
        default=str(DEFAULT_NEW),
        help="directory holding the new skill files (default: docs/clean-room/skills)",
    )
    parser.add_argument(
        "--legacy",
        default=str(DEFAULT_LEGACY),
        help="legacy skills_taxonomy.csv to diff against",
    )
    args = parser.parse_args(argv)

    new_dir = Path(args.new)
    legacy_path = Path(args.legacy)

    if not new_dir.is_dir():
        print(f"ERROR: skill directory not found: {new_dir}")
        return 1
    if not legacy_path.is_file():
        print(f"ERROR: legacy CSV not found: {legacy_path}")
        return 1

    _, legacy_descriptions = load_legacy_descriptions(legacy_path)

    six_grams: dict[tuple[str, ...], list[str]] = {}
    for skill_id, word_list in legacy_descriptions:
        for i in range(len(word_list) - 5):
            gram = tuple(word_list[i:i + 6])
            six_grams.setdefault(gram, []).append(skill_id)

    violations: list[tuple[Path, str, tuple[str, ...]]] = []
    for path in skill_files(new_dir):
        try:
            text = path.read_text(encoding="utf-8")
        except OSError as exc:
            print(f"cannot read {path}: {exc}")
            return 1
        description = extract_description_de(text)
        if not description.strip():
            print(f"{path}: no 'Description DE' found")
            violations.append((path, "?", ()))
            continue
        word_list = words(description)
        seen: set[tuple[str, ...]] = set()
        for i in range(len(word_list) - 5):
            gram = tuple(word_list[i:i + 6])
            if gram not in six_grams:
                continue
            start = i
            while start > 0 and tuple(word_list[start - 1:start + 5]) in six_grams:
                start -= 1
            end = i + 6
            while end < len(word_list) and tuple(word_list[end - 5:end + 1]) in six_grams:
                end += 1
            run = tuple(word_list[start:end])
            if run not in seen:
                seen.add(run)
                violations.append((path, run, gram))

    for path, run, gram in violations:
        if not run:
            continue
        legacy_ids = ", ".join(sorted(set(six_grams[gram])))
        print(
            f"{path}: shares word run '{' '.join(run)}' "
            f"with legacy description of '{legacy_ids}'"
        )

    if violations:
        print(f"FAIL: {len(violations)} shared word run(s)")
        return 1
    print("OK: no shared 6-word runs between new and legacy descriptions")
    return 0


if __name__ == "__main__":
    sys.exit(main())
