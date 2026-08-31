#!/usr/bin/env python3
"""Mirror the P3 skill specs into the Flutter bundle assets.

Copies docs/clean-room/skills/specs/*.json → math_app/assets/skill_specs/
creating the destination directory when needed. Idempotent: files that are
already present and byte-identical are left untouched. Prints a summary.
"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = REPO_ROOT / "docs" / "clean-room" / "skills" / "specs"
DEST_DIR = REPO_ROOT / "math_app" / "assets" / "skill_specs"


def main(argv: list[str] | None = None) -> int:
    if not SRC_DIR.is_dir():
        print(f"ERROR: specs directory not found: {SRC_DIR}")
        return 1

    DEST_DIR.mkdir(parents=True, exist_ok=True)

    sources = sorted(SRC_DIR.glob("*.json"))
    copied = 0
    for source in sources:
        target = DEST_DIR / source.name
        if not target.is_file() or target.read_bytes() != source.read_bytes():
            shutil.copy2(source, target)
            copied += 1

    print(f"synced {len(sources)} skill specs to {DEST_DIR} ({copied} copied, {len(sources) - copied} unchanged)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
