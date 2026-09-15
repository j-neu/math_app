#!/usr/bin/env python3
"""Coverage report for the v4 skill-spec bundle.

Compares every skill_id in math_app/Research/skills_taxonomy.csv (the v4
iMINT/PIKAS taxonomy) against every skill_id actually present in the
synced math_app/assets/skill_specs/*.json bundle (see
scripts/sync_skill_specs.py). Reports two kinds of drift:

  - missing: a taxonomy skill with no spec -- a diagnosed skill the child
    cannot yet practice (child_path_screen.dart falls back to "no exercises
    yet" for these).
  - extra: a spec whose skill_id is not in the taxonomy -- orphaned
    content, typically a retired id left behind by a taxonomy rename.
  - malformed: a spec file that is not valid JSON and so could not be
    read at all.

Exit 0 only when all three lists are empty. Run after every
sync_skill_specs.py run to check progress against the 93-skill build
order (docs/clean-room/v4/skills/BUILD_ORDER.md).
"""

from __future__ import annotations

import csv
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TAXONOMY_CSV = REPO_ROOT / "math_app" / "Research" / "skills_taxonomy.csv"
SPECS_DIR = REPO_ROOT / "math_app" / "assets" / "skill_specs"


def taxonomy_skill_ids(csv_path: Path) -> set[str]:
    with csv_path.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        return {row["skill_id"] for row in reader if row.get("skill_id")}


def spec_skill_ids(specs_dir: Path) -> tuple[set[str], list[str]]:
    ids: set[str] = set()
    malformed: list[str] = []
    for path in specs_dir.glob("*.json"):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            print(f"ERROR: {path.name} is not valid JSON: {exc}")
            malformed.append(path.name)
            continue
        skill_id = data.get("skill_id")
        if skill_id:
            ids.add(skill_id)
    return ids, malformed


def main(argv: list[str] | None = None) -> int:
    if not TAXONOMY_CSV.is_file():
        print(f"ERROR: taxonomy CSV not found: {TAXONOMY_CSV}")
        return 1
    if not SPECS_DIR.is_dir():
        print(f"ERROR: specs directory not found: {SPECS_DIR}")
        return 1

    taxonomy_ids = taxonomy_skill_ids(TAXONOMY_CSV)
    spec_ids, malformed = spec_skill_ids(SPECS_DIR)

    missing = sorted(taxonomy_ids - spec_ids)
    extra = sorted(spec_ids - taxonomy_ids)

    print(f"taxonomy: {len(taxonomy_ids)} skills, specs: {len(spec_ids)} skills")
    print(f"covered: {len(taxonomy_ids) - len(missing)}/{len(taxonomy_ids)}")

    if missing:
        print(f"\nmissing ({len(missing)}): no spec yet for these taxonomy skills:")
        for skill_id in missing:
            print(f"  - {skill_id}")
    if extra:
        print(f"\nextra ({len(extra)}): specs with no matching taxonomy skill:")
        for skill_id in extra:
            print(f"  - {skill_id}")
    if malformed:
        print(f"\nmalformed ({len(malformed)}): these spec files are not valid JSON and were skipped:")
        for name in sorted(malformed):
            print(f"  - {name}")

    if not missing and not extra and not malformed:
        print("OK: every taxonomy skill has exactly one spec, no orphans")
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
