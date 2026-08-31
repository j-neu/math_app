#!/usr/bin/env python3
"""Strict validator for the P3 skill specs (docs/clean-room/skills/specs).

Mirrors the P2 plan §4 schema and the P3 plan §4.5 / §4.5b params
vocabulary. Fails (exit 1) when any spec:

  - is missing a required top-level key;
  - uses an unknown template or custom_widget registry key;
  - has != 3 levels, numbered anything other than 1, 2, 3;
  - has a problem_count outside [4, 12] or a slow_band_ms outside
    {9000, 7000, 6000};
  - uses a params key not in the per-template whitelist, an enum value
    outside the whitelisted set, or a range not shaped [lo, hi];
  - has mastery.correct_of != 8;
  - has an error_taxonomy rule without a non-empty code/label_de/hint_de,
    or duplicate codes;
  - has no provenance row for its skill_id in _provenance_specs_new.csv,
    or an empty provenance.sources list.

Prints one readable problem line per violation and "OK" on a clean pass.

Style follows scripts/check_provenance.py: stdlib only, pathlib,
exit 0 on pass / 1 on failure.
"""

from __future__ import annotations

import csv
import json
import sys
from pathlib import Path

SPECS_DIR = Path(__file__).resolve().parent.parent / "docs" / "clean-room" / "skills" / "specs"
PROVENANCE_CSV = SPECS_DIR / "_provenance_specs_new.csv"

REQUIRED_TOP_LEVEL = (
    "spec_version",
    "skill_id",
    "construct_id",
    "domain",
    "title_de",
    "level_titles_de",
    "levels",
    "mastery",
    "error_taxonomy",
    "provenance",
)

TEMPLATES = {
    "drag_partition",
    "place_counters",
    "bundle_sticks",
    "rekenrek_set",
    "numberline_step",
    "zehnerfeld_read",
    "fingerbild_read",
    "stellenwerttafel_read",
    "numberline_locate",
    "picture_compare",
    "equation_solve",
    "equation_gap",
    "sequence_gap",
    "compare_symbols",
    "strategy_choice",
    "word_problem",
    "custom_widget",
}

CUSTOM_WIDGETS = {"bundling", "unbundling", "numberline_mark", "flash_subitize"}

# Per-template allowed params keys (P3 plan §4.5 + the §4.5b extensions and
# the additive variants actually authored into the specs).
PARAMS_BY_TEMPLATE = {
    "drag_partition": {"total_range", "parts", "equal", "box_labels", "multi_valid", "split_constraint"},
    "place_counters": {"count_range", "frame", "action", "mode"},
    "bundle_sticks": {"count_range"},
    "rekenrek_set": {"count_range", "rows"},
    "numberline_step": {"range", "start_range", "target", "step", "direction"},
    "zehnerfeld_read": {"count_range", "arrangement"},
    "fingerbild_read": {"count_range", "hands"},
    "stellenwerttafel_read": {"mode", "columns", "number_range", "rows", "op"},
    "numberline_locate": {"range", "value_range"},
    "picture_compare": {"left_range", "right_range", "question", "difference_min"},
    "equation_solve": {
        "op", "unknown", "zr", "a_range", "b_range", "mode",
        "equal", "tens_range", "ones_range", "multi_valid",
        "rows", "column_constraint",
    },
    "equation_gap": {
        "op", "form", "zr", "a_range", "b_range", "total_range",
        "tens_range", "ones_range", "start_range", "step", "multi_valid",
    },
    "sequence_gap": {"direction", "step", "start_range", "length", "gap_indices", "progression"},
    "compare_symbols": {"a_range", "b_range", "zr"},
    "strategy_choice": {"op", "zr", "a_range", "b_range", "strategies", "correct_strategy"},
    "word_problem": {"contexts", "op", "zr", "ask_operation"},
    "custom_widget": {"count_range", "flash_ms", "display", "number_range", "range", "value_range"},
}

# Allowed enum values per (template, params key).
ENUM_BY_TEMPLATE_AND_KEY = {
    ("equation_solve", "op"): {"+", "-", "+|-"},
    ("equation_solve", "unknown"): {"result", "addend", "subtrahend", "minuend"},
    ("equation_solve", "mode"): {"standard", "place_value"},
    ("equation_gap", "op"): {"+", "-", "+|-"},
    ("equation_gap", "form"): {
        "gap", "helper", "missing_addend", "any_split", "place_value",
        "half", "double", "neighbor", "helper_double",
    },
    ("strategy_choice", "op"): {"+", "-", "+|-"},
    ("word_problem", "op"): {"+", "-", "+|-"},
    ("sequence_gap", "direction"): {"up", "down"},
    ("sequence_gap", "progression"): {"double"},
    ("sequence_gap", "step"): {1, 2, 5, 10},
    ("numberline_step", "direction"): {"up", "down"},
    ("numberline_step", "step"): {1, 2, 5, 10},
    ("zehnerfeld_read", "arrangement"): {"structured", "two_groups", "five_pattern"},
    ("stellenwerttafel_read", "mode"): {"read", "sum_rows"},
    ("stellenwerttafel_read", "rows"): {"two_rows"},
    ("stellenwerttafel_read", "op"): {"+", "-"},
    ("picture_compare", "question"): {"more", "less", "difference"},
    ("place_counters", "frame"): {"zehnerfeld", "rekenrek", "stellenwerttafel"},
    ("place_counters", "action"): {"fill", "take_away"},
    ("place_counters", "mode"): {"standard", "nonstandard"},
    ("fingerbild_read", "hands"): {1, 2},
    ("rekenrek_set", "rows"): {2},
    ("drag_partition", "parts"): {2, 3},
    ("drag_partition", "split_constraint"): {"sum", "equal", "make_ten", "near_double", "tens_ones"},
    ("equation_solve", "rows"): {"two_rows"},
    ("equation_solve", "column_constraint"): {"no_carry", "no_borrow"},
    ("custom_widget", "display"): {"dots", "rekenrek"},
}

# Params keys that must hold a boolean when present.
BOOL_PARAMS = {
    ("drag_partition", "equal"),
    ("drag_partition", "multi_valid"),
    ("equation_solve", "equal"),
    ("equation_solve", "multi_valid"),
    ("equation_gap", "multi_valid"),
    ("word_problem", "ask_operation"),
}

# Params keys that must hold an int >= 1 when present.
MIN_INT_PARAMS = {
    ("picture_compare", "difference_min"),
}

# Params keys that must hold a [lo, hi] pair of ints when present.
RANGE_PARAMS = {
    "total_range",
    "count_range",
    "start_range",
    "a_range",
    "b_range",
    "range",
    "value_range",
    "number_range",
    "tens_range",
    "ones_range",
}

SLOW_BANDS = {9000, 7000, 6000}
PROBLEM_COUNT_RANGE = (4, 12)


def provenance_skill_ids(prov_path: Path) -> set[str]:
    """All skill_ids with a `skill_spec` row in the provenance CSV."""
    ids = set()
    if not prov_path.is_file():
        return ids
    with prov_path.open(encoding="utf-8", newline="") as handle:
        for row in csv.reader(handle):
            if not row:
                continue
            if row[0].strip().lower() == "skill_id":
                continue
            if len(row) > 1 and row[1].strip() == "skill_spec":
                ids.add(row[0].strip())
    return ids


def check_level(level: dict, spec_label: str) -> list[str]:
    problems = []
    number = level.get("level")
    label = f"{spec_label} level {number}"

    template = level.get("template")
    if template not in TEMPLATES:
        problems.append(f'{label}: unknown template {template!r}')

    custom_widget = level.get("custom_widget")
    if template == "custom_widget":
        if custom_widget not in CUSTOM_WIDGETS:
            problems.append(
                f'{label}: template "custom_widget" requires a registry key from '
                f"{sorted(CUSTOM_WIDGETS)}, found {custom_widget!r}"
            )
    elif custom_widget is not None:
        problems.append(f'{label}: "custom_widget" must be null when template is {template!r}')

    if not isinstance(level.get("representation"), str) or not level["representation"]:
        problems.append(f'{label}: missing non-empty "representation"')

    problem_count = level.get("problem_count")
    if (
        not isinstance(problem_count, int)
        or isinstance(problem_count, bool)
        or not (PROBLEM_COUNT_RANGE[0] <= problem_count <= PROBLEM_COUNT_RANGE[1])
    ):
        problems.append(
            f"{label}: problem_count {problem_count!r} not in "
            f"[{PROBLEM_COUNT_RANGE[0]}, {PROBLEM_COUNT_RANGE[1]}]"
        )

    slow_band = level.get("slow_band_ms")
    if not isinstance(slow_band, int) or isinstance(slow_band, bool) or slow_band not in SLOW_BANDS:
        problems.append(f"{label}: slow_band_ms {slow_band!r} not in {sorted(SLOW_BANDS)}")

    if not isinstance(level.get("prompt_de"), str) or not level["prompt_de"]:
        problems.append(f'{label}: missing non-empty "prompt_de"')

    params = level.get("params")
    if not isinstance(params, dict):
        problems.append(f"{label}: \"params\" must be an object")
        return problems

    allowed = PARAMS_BY_TEMPLATE.get(template, set())
    for key, value in params.items():
        if key not in allowed:
            problems.append(f'{label}: unknown params key "{key}" for template {template!r}')

        enum_set = ENUM_BY_TEMPLATE_AND_KEY.get((template, key))
        if enum_set is not None and value not in enum_set:
            problems.append(
                f"{label}: params.{key}={value!r} not in {sorted(map(str, enum_set))}"
            )

        if (template, key) in BOOL_PARAMS and not isinstance(value, bool):
            problems.append(f"{label}: params.{key} must be a boolean, found {value!r}")

        if (template, key) in MIN_INT_PARAMS and not (
            isinstance(value, int) and not isinstance(value, bool) and value >= 1
        ):
            problems.append(f"{label}: params.{key} must be an int >= 1, found {value!r}")

        if key in RANGE_PARAMS:
            if not (
                isinstance(value, list)
                and len(value) == 2
                and all(isinstance(x, int) and not isinstance(x, bool) for x in value)
                and value[0] <= value[1]
            ):
                problems.append(f"{label}: params.{key} must be a [lo, hi] int pair, found {value!r}")

    if "gap_indices" in params:
        gap_indices = params["gap_indices"]
        length = params.get("length")
        if not isinstance(gap_indices, list) or not all(
            isinstance(x, int) and not isinstance(x, bool) for x in gap_indices
        ):
            problems.append(f"{label}: params.gap_indices must be a list of ints, found {gap_indices!r}")
        elif isinstance(length, int) and not isinstance(length, bool):
            for index in gap_indices:
                if index < 0 or index >= length:
                    problems.append(
                        f"{label}: gap index {index} outside [0, {length - 1}] for length {length}"
                    )

    if template == "sequence_gap":
        length = params.get("length")
        if not isinstance(length, int) or isinstance(length, bool) or not (4 <= length <= 8):
            problems.append(
                f"{label}: sequence_gap length must be in [4, 8], found {length!r}"
            )

    if template == "drag_partition":
        parts = params.get("parts")
        labels = params.get("box_labels")
        split_constraint = params.get("split_constraint")
        if isinstance(parts, int) and not isinstance(parts, bool):
            if not isinstance(labels, list) or len(labels) != parts:
                problems.append(
                    f"{label}: drag_partition box_labels length {len(labels) if isinstance(labels, list) else '?'} != parts {parts}"
                )
            if split_constraint == "make_ten" and parts != 2:
                problems.append(
                    f"{label}: drag_partition split_constraint 'make_ten' requires parts == 2"
                )
            if split_constraint in ("near_double", "tens_ones") and parts != 3:
                problems.append(
                    f"{label}: drag_partition split_constraint {split_constraint!r} requires parts == 3"
                )

    if template == "word_problem":
        contexts = params.get("contexts")
        if not isinstance(contexts, list) or len(contexts) < 2:
            problems.append(f"{label}: word_problem \"contexts\" needs >= 2 entries")

    if template == "strategy_choice":
        strategies = params.get("strategies")
        correct = params.get("correct_strategy")
        if not isinstance(strategies, list) or not strategies:
            problems.append(f"{label}: strategy_choice \"strategies\" must be a non-empty list")
        else:
            ids = [s.get("id") for s in strategies if isinstance(s, dict)]
            if correct not in ids:
                problems.append(
                    f"{label}: strategy_choice correct_strategy {correct!r} not among {ids}"
                )

    return problems


def check_spec(spec: dict, spec_path: Path) -> list[str]:
    problems = []
    skill_id = spec.get("skill_id", "?")
    spec_label = f"{spec_path.name} ({skill_id})"

    for key in REQUIRED_TOP_LEVEL:
        if key not in spec:
            problems.append(f"{spec_label}: missing required top-level key \"{key}\"")

    levels = spec.get("levels")
    if not isinstance(levels, list):
        problems.append(f"{spec_label}: \"levels\" must be a list")
    else:
        if len(levels) != 3:
            problems.append(f"{spec_label}: \"levels\" must contain exactly 3, found {len(levels)}")
        for expected_number, level in enumerate(levels, start=1):
            if not isinstance(level, dict):
                problems.append(f"{spec_label}: levels[{expected_number}] is not an object")
                continue
            if level.get("level") != expected_number:
                problems.append(
                    f"{spec_label}: levels[{expected_number}] must have \"level\": "
                    f"{expected_number}, found {level.get('level')!r}"
                )
            problems.extend(check_level(level, spec_label))

    mastery = spec.get("mastery")
    if not isinstance(mastery, dict):
        problems.append(f"{spec_label}: \"mastery\" must be an object")
    elif mastery.get("correct_of") != 8:
        problems.append(f"{spec_label}: mastery.correct_of must be 8, found {mastery.get('correct_of')!r}")

    taxonomy = spec.get("error_taxonomy")
    if not isinstance(taxonomy, list) or not taxonomy:
        problems.append(f"{spec_label}: \"error_taxonomy\" must be a non-empty list")
    else:
        codes = set()
        for rule in taxonomy:
            if not isinstance(rule, dict):
                problems.append(f"{spec_label}: error_taxonomy entry must be an object")
                continue
            for key in ("code", "label_de", "hint_de"):
                value = rule.get(key)
                if not isinstance(value, str) or not value.strip():
                    problems.append(f"{spec_label}: error_taxonomy rule missing non-empty \"{key}\"")
            code = rule.get("code")
            if code in codes:
                problems.append(f"{spec_label}: duplicate error_taxonomy code {code!r}")
            codes.add(code)

    provenance = spec.get("provenance")
    if not isinstance(provenance, dict):
        problems.append(f"{spec_label}: \"provenance\" must be an object")
    else:
        sources = provenance.get("sources")
        if not isinstance(sources, list) or not sources:
            problems.append(f"{spec_label}: provenance.sources must be a non-empty list")

    return problems


def main(argv: list[str] | None = None) -> int:
    if not SPECS_DIR.is_dir():
        print(f"ERROR: specs directory not found: {SPECS_DIR}")
        return 1

    provenance_ids = provenance_skill_ids(PROVENANCE_CSV)
    if not provenance_ids:
        print(f"ERROR: no skill_spec rows found in {PROVENANCE_CSV}")
        return 1

    problems: list[str] = []
    spec_files = sorted(SPECS_DIR.glob("*.json"))
    for spec_path in spec_files:
        try:
            spec = json.loads(spec_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            problems.append(f"{spec_path.name}: invalid JSON: {exc}")
            continue
        if not isinstance(spec, dict):
            problems.append(f"{spec_path.name}: top-level JSON must be an object")
            continue

        skill_id = spec.get("skill_id")
        if skill_id not in provenance_ids:
            problems.append(
                f"{spec_path.name} ({skill_id}): no skill_spec row in "
                f"{PROVENANCE_CSV.name}"
            )
        problems.extend(check_spec(spec, spec_path))

    for problem in problems:
        print(problem)

    if problems:
        print(f"FAIL: {len(problems)} problems in {len(spec_files)} specs")
        return 1
    print(f"OK: {len(spec_files)} specs validated")
    return 0


if __name__ == "__main__":
    sys.exit(main())
