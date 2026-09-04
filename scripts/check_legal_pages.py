#!/usr/bin/env python3
"""Launch gate: the public legal pages must not ship with unfilled placeholders.

Numeris runs in a German school; the impressum and Datenschutzerklärung are
reachable without login and must carry the operator's real contact data once
the dashboard goes live for the pilot. The pages intentionally start with
bracket tokens ([Name], [E-Mail-Adresse], ...) — this script is the red flag
that those tokens are still present.

Exit 0 when both pages contain no bracketed placeholder. Exit 1 listing the
remaining placeholders. This gate is EXPECTED TO FAIL until the operator data
is entered; it exists to be run before a production push, not as part of the
regular §4 sweep.
"""

import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    ROOT / "dashboard" / "app" / "impressum" / "page.tsx",
    ROOT / "dashboard" / "app" / "datenschutz" / "page.tsx",
]

PLACEHOLDER_RE = re.compile(r"\[[^\]]+\]")


def main():
    failures = []
    for path in FILES:
        text = path.read_text(encoding="utf-8")
        matches = PLACEHOLDER_RE.findall(text)
        if matches:
            failures.append(f"{path.relative_to(ROOT)}: {matches}")
    if failures:
        print("PLACEHOLDER FOUND — the legal pages still carry unfilled operator data:")
        for line in failures:
            print("  " + line)
        print("Fill the real operator details (name, address, E-Mail) in both pages before the live push.")
        return 1
    print("OK: no unfilled placeholders in impressum/datenschutz.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
