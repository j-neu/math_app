#!/usr/bin/env python3
"""Generate the clean-room diagnostic CSVs from the item bank.

Produces:
  * ``math_app/Research/diagnostic_core_v1.csv``    — the 59 core items
  * ``math_app/Research/diagnostic_deepdive_v1.csv`` — the 32 optional
    deep-dive items in a SEPARATE sibling file (tasks.md R5.1).

Source of truth: ``docs/clean-room/items/*.md`` (92 item files),
``docs/clean-room/foerderplan/mapping-rationale.md`` (If-wrong -> skill
mapping) and ``docs/clean-room/skills/skills_taxonomy.csv`` (36 skills).
The column schema is reused EXACTLY from the archived legacy
``MathApp_Diagnostic_with_skills.csv`` (13 columns, matching
``DiagnosticService``'s parser indexes):

    ListNumber,SourceType,QuestionText,AnswerFormat,CorrectAnswer,German,
    English,IfWrong_practice_skills,Ifwrong_skip,Notes,SkipGroup,Zahlenraum,
    AudioAsset

Schemes decided here (documented per the R5.1 brief):

Tier
    The deep-dive blocks live in a sibling file with ListNumber restarting at
    1 (1..32). The core file numbers its 59 items 1..59 in the blueprint
    §Sequenzregeln order (A1 -> A2 -> A3 -> B1 -> B2 -> C1 -> C2 -> C3 -> C4
    -> D1; within a construct items are ordered by difficulty, which for every
    construct matches the item's numeric suffix order).

SourceType
    'Image' iff the item's Stimulus type presents an explicit visual
    arrangement: Zehnerfeld, Rekenrek, Fingerbild, Stäbchen, Zahlenstrahl or
    Stellenwerttafel. Applied to the bank this yields the curated set
    EXPECTED_VISUAL_ITEMS (17 items) — the script fails if a curated visual
    item no longer mentions one of the keywords, and warns if a keyword match
    appears outside the curated set (e.g. B1.1-01 mentions "Keine
    Stellenwerttafel" and B2.3-01 mentions Stäbchen only inside an optional
    hint image; both stay 'Text'). The auditory item DDB-06 (teacher-read
    number dictation, no audio asset) is 'Text'. Everything else is 'Text'.

QuestionText
    For visual items the item ID (e.g. "A2.2-01") is used so R5.2 can key the
    Flutter rendering by item ID; for text items the German wording is used.

AnswerFormat (inference rules)
    * Single  — default; the expected response is one value (number, word or
                short phrase).
    * Multiple — the expected response is multi-part: (a) a selection among
                presented options combined with a result ("Kreuze die passende
                Rechnung an"), i.e. D1.2-01; or (b) several produced
                decompositions ("Finde drei/alle Zerlegungen"), i.e. A3.2-01,
                A3.2-03, DDA-07.
    * The C4.x strategy questions ("Wie hast du gerechnet? Wähle einen Weg")
      stay 'Single' because the graded expected response is the single result;
      the strategy choice is diagnostic metadata carried in the wording/notes.
    * Sort — never used: no item's stimulus asks the child to order/ordnen
      items. Counting items (A1/DDA) produce a fixed spoken or typed sequence
      into a single answer field and remain 'Single'.
    Multi-part items that are neither option-selection nor decomposition
    (Vorgänger/Nachfolger A1.4-01, Zehner/Einer B1.1-01, Stellenwerttafel
    B2.1-01, DDA-10, DDB-02/03, C4.2-01/02, ...) keep 'Single' with a
    comma-separated CorrectAnswer; the R5.2 renderer decides the input UI.

CorrectAnswer
    From the item's "Expected correct answer:" field. A quoted span inside the
    value is preferred (the verbatim sequence), otherwise the whole value is
    used. A few items whose expected answer mixes quoted sub-answers with
    commentary are overridden explicitly (CORRECT_ANSWER_OVERRIDES).

IfWrong_practice_skills
    From mapping-rationale.md's "Recommended (priority order):" line for that
    item ID, comma-space separated, priority order preserved.

Ifwrong_skip / SkipGroup
    Always empty for the new bank. The new skip logic is construct-keyed via
    ``skip_rules.dart`` (tasks.md R1.5) and reads construct IDs from the item
    files, not per-question groups, so neither legacy column carries data.

Zahlenraum
    All ZR<n> tokens found in the item's "Number range:" field (e.g. ZR20,
    ZR100, ZR20/ZR100), joined with '/'.

AudioAsset
    Always empty, including DDB-06: the item is teacher-read aloud and has no
    audio file.

Notes
    Short: "<difficulty>; <construct>" (difficulty normalised to
    easy/medium/hard).

The script self-checks: every item file is covered by exactly one order list,
every item has a recommendation line in the mapping rationale, every
recommended skill ID exists in the new 36-skill taxonomy, and the keyword
based visual detection matches the expected visual set.
"""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ITEMS_DIR = ROOT / "docs" / "clean-room" / "items"
RATIONALE = ROOT / "docs" / "clean-room" / "foerderplan" / "mapping-rationale.md"
TAXONOMY = ROOT / "docs" / "clean-room" / "skills" / "skills_taxonomy.csv"
OUT_CORE = ROOT / "math_app" / "Research" / "diagnostic_core_v1.csv"
OUT_DEEP = ROOT / "math_app" / "Research" / "diagnostic_deepdive_v1.csv"

HEADER = [
    "ListNumber",
    "SourceType",
    "QuestionText",
    "AnswerFormat",
    "CorrectAnswer",
    "German",
    "English",
    "IfWrong_practice_skills",
    "Ifwrong_skip",
    "Notes",
    "SkipGroup",
    "Zahlenraum",
    "AudioAsset",
]

# Blueprint §Sequenzregeln order: constructs A1->A2->A3->B1->B2->C1->C2->C3->
# C4->D1; within each construct items are ordered by difficulty (numeric
# suffix), which matches the blueprint's "smaller numbers first" rule.
CORE_ORDER = [
    "A1.1-01", "A1.1-02",
    "A1.2-01", "A1.2-02",
    "A1.3-01", "A1.3-02",
    "A1.4-01",
    # A1.5-01 removed by the R2.9 review (2026-08-30): redundant against
    # A1.1-02, whose ZR100 counting sequence already crosses two Dekaden and
    # therefore measures the Zehnerübergang. Core tier is 59, not 60.
    "A2.1-01",
    "A2.2-01", "A2.2-02",
    "A2.3-01",
    "A3.1-01", "A3.1-02", "A3.1-03",
    "A3.2-01", "A3.2-02", "A3.2-03",
    "A3.3-01", "A3.3-02",
    "B1.1-01",
    "B1.2-01", "B1.2-02",
    "B1.3-01",
    "B2.1-01", "B2.1-02",
    "B2.2-01",
    "B2.3-01",
    "C1.1-01", "C1.1-02", "C1.1-03", "C1.1-04",
    "C1.2-01", "C1.2-02",
    "C1.3-01", "C1.3-02",
    "C2.1-01", "C2.1-02", "C2.1-03",
    "C2.2-01", "C2.2-02",
    "C2.3-01", "C2.3-02", "C2.3-03",
    "C3.1-01", "C3.1-02", "C3.1-03",
    "C3.2-01", "C3.2-02", "C3.2-03",
    "C3.3-01", "C3.3-02",
    "C3.4-01", "C3.4-02",
    "C4.1-01", "C4.1-02",
    "C4.2-01", "C4.2-02",
    "D1.1-01", "D1.2-01",
]

DEEP_ORDER = (
    [f"DDA-{i:02d}" for i in range(1, 11)]
    + [f"DDB-{i:02d}" for i in range(1, 7)]
    + [f"DDC-{i:02d}" for i in range(1, 11)]
    + [f"DDD-{i:02d}" for i in range(1, 7)]
)

# Explicit visual arrangement keywords from the item files' Stimulus type.
VISUAL_KEYWORDS = (
    "Zehnerfeld",
    "Rekenrek",
    "Fingerbild",
    "Stäbchen",
    "Zahlenstrahl",
    "Stellenwerttafel",
)

# Expected visual set (verified against the item files on 2026-08-29). The
# script asserts the keyword detection matches this set exactly.
EXPECTED_VISUAL_ITEMS = {
    "A2.1-01", "A2.2-01", "A2.2-02", "A2.3-01",
    "B1.2-01", "B1.2-02", "B1.3-01",
    "B2.1-01", "B2.1-02", "B2.2-01",
    "DDA-04", "DDA-05", "DDA-06",
    "DDB-01", "DDB-02", "DDB-04", "DDB-05",
}

# Items whose expected answer mixes quoted sub-answers with scoring commentary
# where the generic quote-preference would pick the wrong span.
CORRECT_ANSWER_OVERRIDES = {
    "A1.4-01": "36, 38",
    "D1.2-01": "9 + 4, 13",
    "DDA-09": "11",
}

# Items whose wording asks for a multi-part response that is either a
# selection among presented options or several produced decompositions.
MULTIPLE_ITEMS = {"A3.2-01", "A3.2-03", "D1.2-01", "DDA-07"}

# Plain-English translations of the German wording, keyed by item ID.
ENGLISH = {
    # --- Domain A ---
    "A1.1-01": "Count on from the number 12 up to the number 20.",
    "A1.1-02": "Count on from the number 48 up to the number 63.",
    "A1.2-01": "Count backwards from the number 21 down to the number 16.",
    "A1.2-02": "Count backwards from the number 59 down to the number 51.",
    "A1.3-01": "Count on in steps of two from the number 26. Name the next four numbers.",
    "A1.3-02": "Count backwards in steps of five from the number 45. Name the next five numbers.",
    "A1.4-01": "Which number comes directly before 37, and which number comes directly after 37?",
    "A2.1-01": "A counting frame will appear for a short moment. Remember exactly how many beads you see. How many beads were there?",
    "A2.2-01": "Here is a ten-frame. Some boxes are filled. You may look as long as you like. How many boxes are filled?",
    "A2.2-02": "You see two hands. Some fingers are stretched out. How many fingers are there in total?",
    "A2.3-01": "On the left and on the right you see a ten-frame. Where are more boxes filled — left or right?",
    "A3.1-01": "There are 6 marbles in the jar. 4 marbles are red, the others are blue. How many marbles are blue?",
    "A3.1-02": "Which number is missing? 10 = 3 + ___",
    "A3.1-03": "Lena has 6 red and 4 blue beads. How many beads does Lena have altogether?",
    "A3.2-01": "Find three different decompositions of 8. Write them like this: 8 = ___ + ___.",
    "A3.2-02": "Paul knows: 8 = 5 + 3. That tells him: 8 = 3 + ___. Which number is missing?",
    "A3.2-03": "Find all decompositions of 10 into two numbers. Write each decomposition exactly once.",
    "A3.3-01": "Kim knows the number 4. Which number is twice as large as 4?",
    "A3.3-02": "Tim knows: 4 + 4 = 8. What is 4 + 5 then?",
    # --- Domain B ---
    "B1.1-01": "Look at the number. The number is 58. How many tens does 58 have? And how many ones does 58 have?",
    "B1.2-01": "Here are sticks. Some are bundled in tens. Count the bundles first, then the single sticks. What number is shown here?",
    "B1.2-02": "Here are 3 bundles of ten and 11 single sticks. How many sticks is that altogether? And if you bundle again: how many tens and how many ones are there then?",
    "B1.3-01": "Here lie 13 sticks: one bundle of ten and 3 single sticks. Open the bundle so that only single sticks are left. How many single sticks do you have then?",
    "B2.1-01": "Here is a place-value table with two columns: Z for tens and E for ones. Enter the number 47. Write the tens in the Z column and the ones in the E column.",
    "B2.1-02": "In this place-value table there is a 6 in the tens column and a 0 in the ones column. Write down the number that is in the table.",
    "B2.2-01": "This number line goes from 0 to 100. Here is 0, here is 50, here is 100. The arrow points to a position. What is the number the arrow points to?",
    "B2.3-01": "Read this number carefully: 1 Z + 14 E. That means: 1 ten and 14 ones. What is the number?",
    # --- Domain C ---
    "C1.1-01": "How much is 3 plus 4?",
    "C1.1-02": "How much is 6 minus 6?",
    "C1.1-03": "What is 2 plus 8?",
    "C1.1-04": "How much is 10 minus 4?",
    "C1.2-01": "How much is 4 plus 4?",
    "C1.2-02": "How much is 5 plus 5?",
    "C1.3-01": "Which number is half as large as 6?",
    "C1.3-02": "Which number is half as large as 10?",
    "C2.1-01": "How much is 7 plus 6?",
    "C2.1-02": "How much is 8 plus 5?",
    "C2.1-03": "How much is 9 plus 7?",
    "C2.2-01": "How much is 8 plus 7?",
    "C2.2-02": "How much is 9 plus 8?",
    "C2.3-01": "How much is 13 minus 8?",
    "C2.3-02": "How much is 12 minus 9?",
    "C2.3-03": "How much is 15 minus 6?",
    "C3.1-01": "Calculate 34 + 28. In the table are the tens and the ones. The number 34 has 3 tens and 4 ones. The number 28 has 2 tens and 8 ones. Enter: How many tens do both numbers have together? How many ones do both numbers have together? Now add everything up and write down the result.",
    "C3.1-02": "Calculate 57 − 19. Split: 57 has 5 tens and 7 ones. 19 has 1 ten and 9 ones. First subtract the tens. With the ones you have to unbundle a ten. Explain what you do with the ones. Then calculate 57 − 19 and enter the result.",
    "C3.1-03": "Calculate 84 − 26. Split 84 into tens and ones. Split 26 into tens and ones. Subtract tens minus tens and ones minus ones. What is special about the ones? Choose how you calculated the ones and calculate 84 − 26.",
    "C3.2-01": "Calculate 26 + 35 in steps. How much is missing from 26 to reach the next ten? Calculate: 26 + 4 = __. If you take the 4 away from 35, how much of 35 is left? Then calculate: 30 + 31 = __. How much is 26 + 35?",
    "C3.2-02": "Calculate 63 − 28 in steps. First subtract the tens: 63 − 20 = __. Then subtract the ones: 43 − 8 = __. How much is 63 − 28?",
    "C3.2-03": "Calculate 67 + 28 in steps. First fill up to the next ten: 67 + 3 = __. Of the 28, 25 then remains. Now calculate: 70 + 25 = __. How much is 67 + 28?",
    "C3.3-01": "This task helps you: 20 + 50 = 70. Use it to calculate: 21 + 50 = __. Briefly explain how 20 + 50 helped you.",
    "C3.3-02": "You know two neighbouring tasks: 45 + 40 = 85 and 45 + 30 = 75. Use them to calculate: 45 + 38 = __. Explain how you calculated.",
    "C3.4-01": "Calculate 37 + 38. Tip: 37 and 38 are almost the same size. First calculate 38 + 38 = __ and then take 1 away. How much is 37 + 38?",
    "C3.4-02": "Calculate 73 − 38. Split the 38 conveniently: 38 is almost 40. Calculate 73 − 40 = __ and then add 2. How much is 73 − 38? Explain your way.",
    "C4.1-01": "Calculate 34 + 29. Then: 'How did you calculate?' Choose a way: (a) I added 30 and then subtracted 1. (b) I calculated the tens first and then the ones. (c) I added 20 first and then 9. (d) I counted.",
    "C4.1-02": "Calculate 52 − 19. Then: 'How did you calculate?' Choose a way: (a) I subtracted 20 and added 1: 52 − 20 = 32, then 32 + 1. (b) I subtracted the tens first and then the ones: 52 − 10 = 42, then 42 − 9. (c) I counted on from 19 to 52. (d) I counted.",
    "C4.2-01": "We know: 43 + 29 = 72. Use it: 72 − 29 = __. And calculate: 72 − 43 = __. Then: 'How did you calculate?' (a) I turned the addition around. (b) I subtracted step by step. (c) I counted.",
    "C4.2-02": "Calculate 83 − 47. Tip: use the inverse task. Which addition fits 83 − 47? Calculate: 47 + __ = 83. What is 83 − 47 then? Then: 'How did you calculate?' (a) I added on from 47 to 83. (b) I used the inverse task. (c) I subtracted step by step. (d) I counted.",
    # --- Domain D ---
    "D1.1-01": "In swimming class the children swim laps in the pool. In the first exercise Luna swims 8 laps. After the break she swims 5 more laps. How many laps did Luna swim in total? Write down the matching calculation and work it out.",
    "D1.2-01": "In the school garden class 2b sowed beans. This morning Leo counts 9 bean plants in his bed. In the afternoon he sees: there are 4 more plants. How many bean plants are in Leo's bed now? Tick the matching calculation and work it out: 9 + 4 · 9 − 4 · 4 − 9.",
    # --- Deep-dive A ---
    "DDA-01": "Count on in steps of ten from the number 47. Name the next four numbers.",
    "DDA-02": "Count forward from 86 to 94.",
    "DDA-03": "Count backwards in steps of five from 60 to 35.",
    "DDA-04": "Here is a ten-frame. Some boxes are filled. You may look as long as you like. How many boxes are filled?",
    "DDA-05": "Here you see a counting board with two rods. Some beads are pushed to the left. How many beads are on the left?",
    "DDA-06": "Here lie two counting boards. On which board are more beads? How many more?",
    "DDA-07": "Find three different decompositions of the number 9. Write them like this: 9 = ___ + ___.",
    "DDA-08": "The number 7 consists of 3 and another number. What is the other number?",
    "DDA-09": "You know: 5 and 5 are 10. What are 5 and 6 then? Briefly explain how you get it.",
    "DDA-10": "If you double the number 6, which number do you get? And what is half of 12 then?",
    # --- Deep-dive B ---
    "DDB-01": "Here are sticks. Some are bundled in tens. Count the bundles first, then the single sticks. What number is shown here?",
    "DDB-02": "The number 25 is laid out as 2 tens and 5 ones. Exchange one ten for ten single sticks. How many tens and how many ones do you have now? Enter it.",
    "DDB-03": "Here is the number 60. How many tens does it have? And how many ones?",
    "DDB-04": "In this place-value table are the tens and the ones. The table shows the tens on the left and the ones on the right. What is the number?",
    "DDB-05": "Here is a number line from 0 to 100. Mark the number 75 on the number line.",
    "DDB-06": "I will say a number to you in a moment. Listen carefully, I say it only once. Write the number down: Seventy.",
    # --- Deep-dive C ---
    "DDC-01": "How much is 9 + 5? State the result.",
    "DDC-02": "How much is 14 − 8? State the result.",
    "DDC-03": "How much is 7 + 8? State the result.",
    "DDC-04": "How much is 16 − 9? State the result.",
    "DDC-05": "How much is 48 − 26? State the result.",
    "DDC-06": "How much is 37 + 8? State the result.",
    "DDC-07": "How much is 38 + 27? State the result.",
    "DDC-08": "How much is 62 − 7? State the result.",
    "DDC-09": "How much is 36 + 39? State the result.",
    "DDC-10": "How much is 54 − 28? State the result.",
    # --- Deep-dive D ---
    "DDD-01": "At the school fair 14 children are getting their faces painted. 6 children are already finished. How many children are still waiting? Only write down the calculation, you do not need to work it out.",
    "DDD-02": "8 jackets are hanging in the class cloakroom. 3 jackets are picked up during break. Write down the calculation.",
    "DDD-03": "9 bicycles are standing in the school bike rack. At lunchtime 4 more bicycles are added. Write down the calculation.",
    "DDD-04": "During break 6 children are playing on the climbing frame and 5 children on the swing. How many children are playing together?",
    "DDD-05": "12 picture books are lying on the shelf in the class library. 4 books are borrowed. How many books stay on the shelf?",
    "DDD-06": "In Tom's sports bag there are 9 skipping ropes. In Anna's sports bag there are 7 skipping ropes. How many skipping ropes do they have together?",
}

_FIELD_RE = re.compile(r"^\*\*(?P<name>[^*]+):\*\*\s*(?P<value>.*)$")
_NUMBER_RANGE_RE = re.compile(r"ZR\d+")


def parse_item(item_id: str) -> dict:
    """Extract the template fields from one item file."""
    path = ITEMS_DIR / f"{item_id}.md"
    fields: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        m = _FIELD_RE.match(line.strip())
        if m:
            fields[m.group("name")] = m.group("value").strip()
    return fields


def clean_answer(value: str) -> str:
    """Prefer a quoted span in the expected answer, else use the whole value."""
    value = value.strip()
    # German typographic quotes: „..." — open U+201E, close U+201C/U+201D or
    # ASCII U+0022 (the item files use both closing styles).
    m = re.search(r"„([^”\u201c\"]+)[”\u201c\"]", value)
    if m:
        return m.group(1).strip()
    m = re.search(r'"([^"]+)"', value)
    return m.group(1).strip() if m else value


def parse_recommendations() -> dict[str, list[str]]:
    """Parse mapping-rationale.md into item ID -> priority skill IDs."""
    out: dict[str, list[str]] = {}
    current = None
    for line in RATIONALE.read_text(encoding="utf-8").splitlines():
        if line.startswith("### "):
            current = line.split(" ", 2)[1].strip()
            out.setdefault(current, [])
            continue
        if current is None or not line.startswith("**Recommended (priority order):**"):
            continue
        rest = line[len("**Recommended (priority order):**"):].strip()
        out[current] = [
            s.strip() for s in rest.split(",") if s.strip()
        ]
    return out


def parse_taxonomy_skill_ids() -> set[str]:
    rows = list(csv.reader(TAXONOMY.read_text(encoding="utf-8").splitlines()))
    return {row[0] for row in rows[1:] if row and row[0].strip()}


def strip_quotation_wrapping(text: str) -> str:
    """Strip one layer of wrapping quotation marks from a prompt.

    Every item's Wording (German) field wraps the whole prompt in „…", "…"
    or »…« — a holdover from assessor-script authoring with no meaning in a
    UI that renders the text directly (diagnostic usability rework §4.2).
    Only the outermost pair is removed; a nested quote inside the prompt
    (e.g. a quoted sub-instruction in the C4.x items) is left alone.
    """
    s = text.strip()
    if len(s) < 2:
        return s
    pairs = {
        "„": {"“", "”", '"'},
        '"': {'"'},
        "»": {"«"},
    }
    valid_closers = pairs.get(s[0])
    if valid_closers and s[-1] in valid_closers:
        return s[1:-1].strip()
    return s


def build_rows(order: list[str]) -> list[list[str]]:
    recommendations = parse_recommendations()
    rows: list[list[str]] = []
    for number, item_id in enumerate(order, start=1):
        fields = parse_item(item_id)
        stimulus = fields.get("Stimulus type", "")
        visual = item_id in EXPECTED_VISUAL_ITEMS
        wording = strip_quotation_wrapping(fields.get("Wording (German)", ""))

        difficulty_raw = fields.get("Difficulty target", "").lower().split()
        difficulty = difficulty_raw[0] if difficulty_raw else "medium"
        construct = fields.get("Construct", "")
        number_range = fields.get("Number range", "")

        correct = CORRECT_ANSWER_OVERRIDES.get(
            item_id, clean_answer(fields.get("Expected correct answer", ""))
        )
        zr = "/".join(_NUMBER_RANGE_RE.findall(number_range))

        rows.append([
            str(number),
            "Image" if visual else "Text",
            item_id if visual else wording,
            "Multiple" if item_id in MULTIPLE_ITEMS else "Single",
            correct,
            wording,
            ENGLISH[item_id],
            ", ".join(recommendations[item_id]),
            "",
            f"{difficulty}; {construct}",
            "",
            zr,
            "",
        ])
    return rows


def main() -> int:
    errors: list[str] = []

    # 1. Item files cover both order lists completely and vice versa.
    all_ids = set(CORE_ORDER) | set(DEEP_ORDER)
    file_ids = {p.stem for p in ITEMS_DIR.glob("*.md") if p.stem != "TEMPLATE"}
    if missing := sorted(file_ids - all_ids):
        errors.append(f"Item files not covered by an order list: {missing}")
    if extra := sorted(all_ids - file_ids):
        errors.append(f"Order entries without an item file: {extra}")

    # 2. Counts per the blueprint.
    if len(CORE_ORDER) != 59:
        errors.append(f"Core order has {len(CORE_ORDER)} items, expected 59")
    if len(DEEP_ORDER) != 32:
        errors.append(f"Deep-dive order has {len(DEEP_ORDER)} items, expected 32")

    # 3. Every item has an English translation.
    if missing_en := sorted(all_ids - set(ENGLISH)):
        errors.append(f"Missing English translations: {missing_en}")

    # 4. Visual detection: every curated visual item must mention an explicit
    # arrangement keyword (hard), keyword matches outside the curated set are
    # reported (soft) — see the SourceType scheme in the docstring.
    detected = {
        item_id
        for item_id in all_ids
        if any(kw in parse_item(item_id).get("Stimulus type", "") for kw in VISUAL_KEYWORDS)
    }
    for item_id in sorted(EXPECTED_VISUAL_ITEMS - detected):
        errors.append(f"Visual item {item_id} mentions no arrangement keyword")
    if extra_visual := sorted(detected - EXPECTED_VISUAL_ITEMS):
        print(
            "WARNING: keyword matches outside the curated visual set "
            f"(kept as Text): {extra_visual}"
        )

    # 5. Mapping rationale covers every item and every skill ID exists.
    recommendations = parse_recommendations()
    if missing_rec := sorted(all_ids - set(recommendations)):
        errors.append(f"Items without a recommendation line: {missing_rec}")
    taxonomy_ids = parse_taxonomy_skill_ids()
    unknown = sorted(
        {
            skill
            for skills in recommendations.values()
            for skill in skills
            if skill not in taxonomy_ids
        }
    )
    if unknown:
        errors.append(f"Unknown skill IDs in mapping rationale: {unknown}")

    if errors:
        print("generate_diagnostic_csv.py FAILED:")
        for e in errors:
            print(f"  - {e}")
        return 1

    # Only build rows once every structural check above has passed —
    # build_rows reads every item file and would raise on a missing one.
    core_rows = build_rows(CORE_ORDER)
    deep_rows = build_rows(DEEP_ORDER)

    # 6. Prompt hygiene: no generated prompt keeps its item-file quote
    # wrapping (stripped above) — regression guard, usability rework §4.2.
    quote_starts = ("„", '"', "»", "“", "”", "«")
    hygiene_errors = [
        f"{label} item {row[0]} prompt still starts with a quote: {row[5]!r}"
        for rows, label in ((core_rows, "core"), (deep_rows, "deep-dive"))
        for row in rows
        if row[5] and row[5][0] in quote_starts
    ]
    if hygiene_errors:
        print("generate_diagnostic_csv.py FAILED:")
        for e in hygiene_errors:
            print(f"  - {e}")
        return 1

    for path, rows, label in (
        (OUT_CORE, core_rows, "core"),
        (OUT_DEEP, deep_rows, "deep-dive"),
    ):
        with path.open("w", encoding="utf-8", newline="") as f:
            writer = csv.writer(f, lineterminator="\n")
            writer.writerow(HEADER)
            writer.writerows(rows)
        print(f"Wrote {path} ({len(rows)} {label} questions)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
