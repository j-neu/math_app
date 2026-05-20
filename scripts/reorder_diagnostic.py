"""
Reorder MathApp_Diagnostic_with_skills.csv pedagogically and emit a Supabase
migration that drops the existing 59 questions and inserts all 98 in the
new order.

Usage:
    python scripts/reorder_diagnostic.py

Writes (in-place):
    math_app/Research/MathApp_Diagnostic_with_skills.csv
    backend/supabase/migrations/<timestamp>_reorder_diagnostic_questions.sql
"""
from __future__ import annotations

import csv
import datetime
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CSV_PATH = ROOT / "math_app" / "Research" / "MathApp_Diagnostic_with_skills.csv"
MIGRATIONS_DIR = ROOT / "backend" / "supabase" / "migrations"
DIAGNOSTIC_ID = "00000000-0000-0000-0000-000000000001"

# new_position (1-indexed) -> original ListNumber
ORDER: list[int] = [
    # Phase 1 — Zählen (1–23)
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,  # subitizing + counting + succ/pred
    15, 16, 17, 18,                                  # Zweierschritte
    43, 44, 45,                                      # Fünfer/Zehnerschritte (moved from end)
    19, 20,                                          # Zahlen ordnen
    # Phase 2 — Zahlzerlegung (24–38)
    21,                                              # Würfel-Zerlegung 7
    22, 23, 24, 25, 26, 27,                          # Ergänzen auf 10/20
    28, 29, 30, 31,                                  # Plättchen
    32, 33, 34, 35,                                  # Rechenschiffchen
    # Phase 3 — Stellenwerte (39–47)
    60, 61,                                          # Dienes (moved from end)
    39, 40, 41, 42,                                  # 100er-Feld
    36, 37,                                          # Bündelung
    38,                                              # Zahlen-Diktat
    # Phase 4 — Grundstrategien (48–87)
    46,                                              # Würfel mehr/weniger
    47, 48, 49, 50, 51,                              # +/- ZR10
    62, 63, 64, 65, 66, 67, 68, 69,                  # Verdoppeln (moved from end)
    70, 71, 72, 73, 74, 75, 76, 77, 78, 79,          # Halbieren (moved from end)
    52, 53, 54, 55,                                  # Zehner+/-Einer ZR20
    56, 57, 58, 59,                                  # Zehner+/-Einer ZR100
    80, 81, 82, 83,                                  # Rechnen mit Zehnern
    84, 85, 86, 87,                                  # Zehner-Analogien
    # Phase 5 — Kombinierte Strategien (88–98)
    88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98,
]

assert len(ORDER) == 98, f"Expected 98 entries, got {len(ORDER)}"
assert sorted(ORDER) == list(range(1, 99)), "ORDER must be a permutation of 1..98"


def sql_literal(value: str) -> str:
    """Single-quoted Postgres literal (escape any internal single quotes)."""
    return "'" + value.replace("'", "''") + "'"


def jsonb_literal(raw: str, answer_format: str) -> str:
    """Build a jsonb literal for the correct_answer column.

    Single-format: jsonb string e.g. '"8"'
    Multiple/sort: jsonb array of strings, parsing the comma-separated list.
    """
    if not raw:
        return "'null'::jsonb"
    if answer_format == "single":
        payload = json.dumps(raw)
    else:
        parts = [p.strip() for p in raw.split(",")]
        payload = json.dumps(parts)
    return sql_literal(payload) + "::jsonb"


def text_array_literal(raw: str) -> str:
    """Build a Postgres text[] literal from a comma-separated string."""
    if not raw:
        return "ARRAY[]::text[]"
    parts = [p.strip() for p in raw.split(",") if p.strip()]
    quoted = ",".join("'" + p.replace("'", "''") + "'" for p in parts)
    return f"ARRAY[{quoted}]"


def main() -> None:
    with CSV_PATH.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    by_list_number: dict[int, dict[str, str]] = {
        int(r["ListNumber"]): r for r in rows
    }
    missing = [n for n in ORDER if n not in by_list_number]
    if missing:
        raise SystemExit(f"Missing rows in CSV for original list numbers: {missing}")

    # --- 1. Rewrite the CSV with new ListNumbers and order ---
    fieldnames = reader.fieldnames
    assert fieldnames is not None
    reordered: list[dict[str, str]] = []
    for new_pos, orig in enumerate(ORDER, start=1):
        row = dict(by_list_number[orig])
        row["ListNumber"] = str(new_pos)
        reordered.append(row)

    with CSV_PATH.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, quoting=csv.QUOTE_MINIMAL)
        writer.writeheader()
        writer.writerows(reordered)

    print(f"Wrote {len(reordered)} rows to {CSV_PATH}")

    # --- 2. Emit SQL migration ---
    timestamp = datetime.datetime.utcnow().strftime("%Y%m%d%H%M%S")
    sql_path = MIGRATIONS_DIR / f"{timestamp}_reorder_diagnostic_questions.sql"
    lines: list[str] = []
    lines.append("-- Reorder diagnostic_questions pedagogically and add 39 new questions.")
    lines.append("-- Deletes all existing questions for diagnostic " + DIAGNOSTIC_ID + ";")
    lines.append("-- cascade-deletes orphan diagnostic_results (acceptable for pilot stage).")
    lines.append("")
    lines.append("begin;")
    lines.append("")
    lines.append(f"delete from public.diagnostic_questions where diagnostic_id = '{DIAGNOSTIC_ID}';")
    lines.append("")
    lines.append(
        "insert into public.diagnostic_questions "
        "(diagnostic_id, question_number, source_type, prompt_de, prompt_en, "
        "answer_format, correct_answer, if_wrong_practice_skills, if_wrong_skip, notes) values"
    )

    value_lines: list[str] = []
    for new_pos, orig in enumerate(ORDER, start=1):
        r = by_list_number[orig]
        source_type = r["SourceType"].strip().lower()
        # Schema check constraint: image|text|cards|picture
        source_type_canonical = {
            "image": "image",
            "text": "text",
            "cards": "cards",
            "picture": "picture",
        }.get(source_type, "text")
        prompt_de = r["German"].strip()
        prompt_en = r["English"].strip()
        answer_format = r["AnswerFormat"].strip().lower()
        if answer_format not in {"single", "multiple", "sort"}:
            answer_format = "single"
        correct = r["CorrectAnswer"].strip()
        skills_list = r["IfWrong_practice_skills"].strip()
        skip = r["Ifwrong_skip"].strip()
        notes = r["Notes"].strip()

        value_lines.append(
            "  ("
            f"'{DIAGNOSTIC_ID}', "
            f"{new_pos}, "
            f"{sql_literal(source_type_canonical)}, "
            f"{sql_literal(prompt_de)}, "
            f"{sql_literal(prompt_en)}, "
            f"{sql_literal(answer_format)}, "
            f"{jsonb_literal(correct, answer_format)}, "
            f"{text_array_literal(skills_list)}, "
            f"{sql_literal(skip) if skip else 'null'}, "
            f"{sql_literal(notes) if notes else 'null'}"
            ")"
        )

    lines.append(",\n".join(value_lines) + ";")
    lines.append("")
    lines.append(
        "update public.diagnostics "
        f"set question_count = {len(ORDER)}, version = version + 1 "
        f"where id = '{DIAGNOSTIC_ID}';"
    )
    lines.append("")
    lines.append("commit;")
    lines.append("")

    sql_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote migration {sql_path}")


if __name__ == "__main__":
    main()
