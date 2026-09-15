#!/usr/bin/env python3
"""Mirror the v4 skill specs into the Flutter bundle assets.

Copies docs/clean-room/v4/skills/specs/*.json into
math_app/assets/skill_specs/, creating the destination directory when
needed. Idempotent: files that are already present and byte-identical are
left untouched. Prints a summary.

The v1 (docs/clean-room/skills/specs) and v2 (docs/clean-room/v2/skills/specs)
trees this script used to also mirror are retired: their skill ids predate
the current taxonomy (math_app/Research/skills_taxonomy.csv) and are archived
under docs/archive/skill_specs_pre_v4/.
"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SRC_DIRS = [
    REPO_ROOT / "docs" / "clean-room" / "v4" / "skills" / "specs",
]
DEST_DIR = REPO_ROOT / "math_app" / "assets" / "skill_specs"


def main(argv: list[str] | None = None) -> int:
    DEST_DIR.mkdir(parents=True, exist_ok=True)

    sources: list[Path] = []
    for src_dir in SRC_DIRS:
        if not src_dir.is_dir():
            print(f"ERROR: specs directory not found: {src_dir}")
            return 1
        sources.extend(sorted(src_dir.glob("*.json")))

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
