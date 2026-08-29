#!/usr/bin/env python3
"""Independence check for the Numeris/Prozedia clean-room item rewrite (task R1.7).

Compares a NEW diagnostic item bank against the archived legacy item bank
(read from ``_sources_private/``, never committed) and reports new items
that look too close to a legacy item, so a human can adjudicate:

  1. identical operand pairs (order-normalised for ``+``; ``7 + 6`` == ``6 + 7``),
  2. prompt-wording overlap (a shared run of >= 6 words),
  3. identical visual configurations (dot/pattern arrangements: ``Würfel``,
     ``Punkte``, ``dots``, ``Plättchen``, ``Kreis(e)`` or ``img<digits>.jpg``
     references, plus a count when one is in the prompt),
  4. identical ordering runs (byte-identical prompts after whitespace
     normalisation).

The output is a report, NOT a hard gate: Jakob adjudicates every flag.
``--strict`` turns the report into a gate (used later in R2.11): it exits
non-zero while any flagged item has no adjudication entry in the sidecar
file ``<new-basename>.adjudicated`` (same directory as the ``--new`` CSV,
one item ID per line, optionally ``itemid:reason``).

Prompt column detection: first header containing "frag"/"prompt"/"question"
(case-insensitive). Because the legacy CSV stores its question text in the
"German" column (while "QuestionText" carries image references / answer
expressions), that German text column is appended to the prompt when present
so wording-overlap detection works on the actual wording. Subtraction dashes
(U+2013/U+2014/U+2212) are normalised to ``-`` so ``8 – 5`` is detected as an
operand pair. Both are deliberate robustness choices over the letter of the
R1.7 spec and are reported in the script header notes of this docstring.

Construct/category column detection: first header containing
"kategor"/"categor"/"bereich"/"construct"/"skill" (excluding IfWrong/practice
mapping columns). For the ``--new`` CSV, ``construct_id`` / ``Construct`` is
used when present. Legacy items whose construct cannot be determined are
treated as wildcards (eligible for any new item's construct); when a new
item's construct cannot be determined the comparison is global.
"""

from __future__ import annotations

import argparse
import csv
import os
import re
import sys
from typing import Optional

PROMPT_KEYWORDS = ("frag", "prompt", "question")
CONSTRUCT_KEYWORDS = ("kategor", "categor", "bereich", "construct", "skill")
CONSTRUCT_EXCLUDE = ("ifwrong", "practice", "mapping")
ID_HEADERS = (
    "id",
    "item_id",
    "question_id",
    "questionid",
    "listnumber",
    "number",
    "nr",
    "no",
)
GERMAN_KEYWORDS = ("german", "deutsch")

OPERAND_RE = re.compile(r"(\d+)\s*([+\-])\s*(\d+)")
IMG_RE = re.compile(r"img\d+\.jpg", re.IGNORECASE)
VISUAL_WORDS = ("würfel", "punkte", "dots", "plättchen", "kreis", "kreise", "kugeln")
MIN_WORD_RUN = 6
MAX_MATCHES_PER_TYPE = 5


def read_csv(path: str) -> list[dict]:
    """Read a CSV as a list of dicts, tolerating BOM and common encodings."""
    for encoding in ("utf-8-sig", "utf-8", "cp1252"):
        try:
            with open(path, "r", encoding=encoding, newline="") as fh:
                return list(csv.DictReader(fh))
        except UnicodeDecodeError:
            continue
    # Last resort: latin-1 never fails; a human can eyeball mojibake.
    with open(path, "r", encoding="latin-1", newline="") as fh:
        return list(csv.DictReader(fh))


def find_column(headers: list[str], keywords, exclude=()) -> Optional[str]:
    for header in headers:
        lowered = header.lower()
        if any(tok in lowered for tok in exclude):
            continue
        for keyword in keywords:
            if keyword in lowered:
                return header
    return None


def find_id_column(headers: list[str]) -> Optional[str]:
    for header in headers:
        if header.lower() in ID_HEADERS:
            return header
    return None


def resolve_columns(headers: list[str]) -> dict:
    prompt_col = find_column(headers, PROMPT_KEYWORDS)
    german_col = find_column(headers, GERMAN_KEYWORDS)

    construct_col = None
    lowered = [h.lower() for h in headers]
    if "construct_id" in lowered:
        construct_col = headers[lowered.index("construct_id")]
    elif "construct" in lowered:
        construct_col = headers[lowered.index("construct")]
    else:
        construct_col = find_column(headers, CONSTRUCT_KEYWORDS, CONSTRUCT_EXCLUDE)

    id_col = find_id_column(headers)
    return {
        "prompt_col": prompt_col,
        "german_col": german_col,
        "construct_col": construct_col,
        "id_col": id_col,
    }


def item_prompt(row: dict, prompt_col: Optional[str], german_col: Optional[str]) -> str:
    parts = []
    for col in (prompt_col, german_col):
        if col and row.get(col) is not None:
            value = str(row[col]).strip()
            if value:
                parts.append(value)
    return " ".join(parts)


def item_construct(row: dict, construct_col: Optional[str]) -> Optional[str]:
    if construct_col and row.get(construct_col) is not None:
        value = str(row[construct_col]).strip()
        return value or None
    return None


def item_id(row: dict, id_col: Optional[str], index: int) -> str:
    if id_col and row.get(id_col) is not None:
        value = str(row[id_col]).strip()
        if value:
            return value
    return str(index + 1)


def whitespace_normalize(text: str) -> str:
    return " ".join(text.split())


def normalize_words(text: str) -> str:
    """Lowercase, keep alphanumerics and spaces, collapse whitespace."""
    low = text.lower()
    cleaned = []
    for ch in low:
        cleaned.append(ch if ch.isalnum() or ch.isspace() else " ")
    return " ".join("".join(cleaned).split())


def dash_normalize(text: str) -> str:
    for dash in ("\u2013", "\u2014", "\u2212"):
        text = text.replace(dash, "-")
    return text


def operand_pairs(text: str) -> list[tuple]:
    """Return (canonical_key, display) for every operand pair in text."""
    found = []
    for match in OPERAND_RE.finditer(dash_normalize(text)):
        a, op, b = int(match.group(1)), match.group(2), int(match.group(3))
        if op == "-":
            key = ("-", a, b)
        else:
            key = ("+", min(a, b), max(a, b))
        found.append((key, f"{a} {op} {b}"))
    return found


def longest_common_run(a: list, b: list) -> list:
    """Longest contiguous run of equal tokens shared by token lists a and b."""
    best = []
    for i in range(len(a)):
        for j in range(len(b)):
            k = 0
            while i + k < len(a) and j + k < len(b) and a[i + k] == b[j + k]:
                k += 1
            if k > len(best):
                best = a[i : i + k]
    return best


def visual_configuration(text: str) -> Optional[tuple]:
    """Return a comparison key + display description, or (None, None)."""
    imgs = sorted({m.group(0) for m in IMG_RE.finditer(text)})
    if imgs:
        key = ("img", tuple(imgs))
        return key, "img:" + ",".join(imgs)
    lowered = text.lower()
    if any(word in lowered for word in VISUAL_WORDS):
        count_match = re.search(r"\d+", text)
        count = int(count_match.group(0)) if count_match else None
        arrangement = normalize_words(re.sub(r"\d+", " ", text))
        key = ("dots", count, arrangement)
        count_desc = str(count) if count is not None else "? (no count in prompt)"
        return key, f"{count_desc} dots; arrangement {arrangement!r}"
    return None, None


def snippet(text: str, limit: int = 60) -> str:
    text = whitespace_normalize(text)
    return text if len(text) <= limit else text[: limit - 1] + "\u2026"


def load_sidecar(path: str) -> set[str]:
    """Read adjudicated item IDs from the sidecar file."""
    adjudicated: set[str] = set()
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8-sig") as fh:
            for line in fh:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if ":" in line:
                    line = line.split(":", 1)[0].strip()
                if line:
                    adjudicated.add(line)
    return adjudicated


def legacy_data(legacy_rows, legacy_cols):
    """Precompute per-legacy-item derived data once."""
    data = []
    for idx, row in enumerate(legacy_rows):
        prompt = item_prompt(row, legacy_cols["prompt_col"], legacy_cols["german_col"])
        data.append(
            {
                "index": idx,
                "row": row,
                "id": item_id(row, legacy_cols["id_col"], idx),
                "prompt": prompt,
                "construct": item_construct(row, legacy_cols["construct_col"]),
                "operand_keys": {k for k, _ in operand_pairs(prompt)},
                "words": normalize_words(prompt).split(),
                "visual": visual_configuration(prompt)[0],
                "text": whitespace_normalize(prompt),
            }
        )
    return data


def run_checks(new_rows, legacy_rows, new_cols, legacy_cols):
    legacy = legacy_data(legacy_rows, legacy_cols)

    new_items = []
    for idx, row in enumerate(new_rows):
        prompt = item_prompt(row, new_cols["prompt_col"], new_cols["german_col"])
        if not prompt:
            continue
        new_items.append(
            {
                "id": item_id(row, new_cols["id_col"], idx),
                "construct": item_construct(row, new_cols["construct_col"]),
                "prompt": prompt,
                "words": normalize_words(prompt).split(),
                "visual": visual_configuration(prompt),
                "text": whitespace_normalize(prompt),
            }
        )

    flag_summary = {"operands": 0, "wording": 0, "visual": 0, "text": 0}
    flagged_items = []

    for item in new_items:
        if item["construct"] is None:
            pool = legacy
        else:
            pool = [l for l in legacy if l["construct"] is None or l["construct"] == item["construct"]]

        flags = []
        for key, display in operand_pairs(item["prompt"]):
            for l in pool:
                if key in l["operand_keys"]:
                    flags.append(("operands", l, f"pair {display}"))
                    break

        for l in pool:
            run = longest_common_run(item["words"], l["words"])
            if len(run) >= MIN_WORD_RUN:
                flags.append(("wording", l, f"shared run {len(run)} words: {' '.join(run)!r}"))

        new_visual, new_visual_desc = item["visual"]
        if new_visual is not None:
            for l in pool:
                if l["visual"] is not None and l["visual"] == new_visual:
                    flags.append(("visual", l, f"arrangement {new_visual_desc}"))

        for l in pool:
            if item["text"] and item["text"] == l["text"]:
                flags.append(("text", l, f"identical to {snippet(item['text'])}"))

        if flags:
            flagged_items.append((item, flags))
            for kind, _, _ in flags:
                flag_summary[kind] += 1

    return new_items, flagged_items, flag_summary


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--legacy",
        default="_sources_private/MathApp_Diagnostic_with_skills.csv",
        help="path to the archived legacy item bank CSV (default: _sources_private/MathApp_Diagnostic_with_skills.csv)",
    )
    parser.add_argument("--new", required=True, help="path to the NEW item bank CSV")
    parser.add_argument(
        "--strict",
        action="store_true",
        help="exit non-zero while any flagged item is not adjudicated in the sidecar file",
    )
    args = parser.parse_args()

    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    legacy_rows = read_csv(args.legacy)
    new_rows = read_csv(args.new)
    if not legacy_rows:
        print(f"error: no rows in legacy CSV {args.legacy}", file=sys.stderr)
        return 2
    if not new_rows:
        print(f"error: no rows in new CSV {args.new}", file=sys.stderr)
        return 2

    legacy_cols = resolve_columns(list(legacy_rows[0].keys()))
    new_cols = resolve_columns(list(new_rows[0].keys()))

    print("Independence report (R1.7)")
    print("=" * 40)
    print(f"Legacy bank : {args.legacy} ({len(legacy_rows)} items)")
    print(f"New bank    : {args.new} ({len(new_rows)} items)")
    print(f"Prompt col  : legacy={legacy_cols['prompt_col'] or 'none'}"
          f"{' (+' + legacy_cols['german_col'] + ')' if legacy_cols['german_col'] else ''}"
          f"  new={new_cols['prompt_col'] or 'none'}"
          f"{' (+' + new_cols['german_col'] + ')' if new_cols['german_col'] else ''}")
    print(f"Construct col: legacy={legacy_cols['construct_col'] or 'none (global comparison)'}"
          f"  new={new_cols['construct_col'] or 'none (global comparison)'}")
    print()

    new_items, flagged_items, flag_summary = run_checks(new_rows, legacy_rows, new_cols, legacy_cols)

    for item, flags in flagged_items:
        construct_note = (
            f" (construct: {item['construct']})"
            if item["construct"] is not None
            else " (construct not determinable, global comparison)"
        )
        print(f"New item {item['id']}{construct_note}")
        for kind, legacy_entry, detail in flags:
            legacy_id = legacy_entry["id"]
            legacy_prompt = legacy_entry["prompt"]
            label = {
                "operands": "identical operands",
                "wording": "wording overlap",
                "visual": "visual configuration",
                "text": "identical text",
            }[kind]
            print(f"  [{label}] legacy item {legacy_id} {snippet(legacy_prompt)!r}: {detail}")
        print()

    total_flags = sum(flag_summary.values())
    print(
        f"{total_flags} flags for {len(flagged_items)} items "
        f"({flag_summary['operands']} identical operands, "
        f"{flag_summary['wording']} wording overlap, "
        f"{flag_summary['text']} identical text)"
    )
    print(f"(visual configuration flags: {flag_summary['visual']}; report only, no hard gate)")

    if not args.strict:
        return 0

    sidecar = os.path.join(
        os.path.dirname(os.path.abspath(args.new)),
        os.path.splitext(os.path.basename(args.new))[0] + ".adjudicated",
    )
    adjudicated = load_sidecar(sidecar)
    unadjudicated = [item["id"] for item, _ in flagged_items if item["id"] not in adjudicated]
    if unadjudicated:
        print(f"\nSTRICT: {len(unadjudicated)} flagged item(s) not adjudicated in {sidecar}")
        print("STRICT: " + ", ".join(unadjudicated))
        return 1
    print(f"\nSTRICT OK: all flagged items adjudicated in {sidecar}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
