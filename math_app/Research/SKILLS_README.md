# Skills Taxonomy: iMINT + PIKAS Integration

## Overview

This document explains the skill identification system used in the Math App, integrating both the iMINT Kartei (76 skills) and PIKAS FÖDIMA (12 skills) research frameworks for a total of **88 uniquely identified skills**.

## Problem with Original Numbering

The original diagnostic CSV used ambiguous numbers (e.g., "1", "2", "12") in the `IfWrong_practice` column. This was problematic because:

1. **Color-coding ambiguity:** In the physical iMINT Kartei, cards are color-coded by category. Yellow card #1 is different from Green card #1.
2. **Lack of semantic meaning:** A number like "12" doesn't tell you what skill is being practiced.
3. **Maintenance difficulty:** Developers had to cross-reference PDF pages to understand what each number meant.

## New Skill ID System

### Format: `category_number_shortname`

Examples:
- `counting_3` = Green category, card 3: "Count on number line to 100"
- `decomposition_3` = Yellow category, card 3: "All decompositions of 10"
- `place_value_5` = Blue category, card 5: "Power of 10 (Tens-Ones Quiz)"
- `basic_strategy_20` = Purple category, card 20: "Calculate with decade numbers (10+3)"
- `combined_strategy_6` = Gray category, card 6: "Strategy: Power of 10"

### Benefits

1. **Self-documenting:** `decomposition_3` immediately tells you it's about decomposition
2. **No ambiguity:** Color categories are explicitly named
3. **Easy to extend:** New skills can be added without conflicts
4. **Human-readable:** Code reviewers can understand skill references without lookup tables

## The Five Color Categories

### 1. Zählen (GREEN) - Counting
**Purpose:** Basic counting skills, number sequencing, skip counting

**Key skills:**
- counting_1: Count dots/objects
- counting_3: Count forward/backward on number line
- counting_4: Find neighboring numbers (successor/predecessor)
- counting_6-9: Skip counting by 2s, 5s, 10s

**When to practice:** Child struggles with number sequence, can't identify what comes before/after, counts incorrectly

---

### 2. Zahlzerlegung / Schnelles Sehen (YELLOW) - Decomposition & Quick Recognition
**Purpose:** Part-whole relationships, number decomposition, subitizing

**Key skills:**
- decomposition_1-2: Break numbers 2-9 into parts
- decomposition_3: All decompositions of 10 (foundation for "make 10" strategy)
- decomposition_6-7: Quick visual recognition without counting
- decomposition_9-11: Recognition using structured materials (Rechenschiffchen)
- decomposition_15: Complete to 10 (how many more needed?)

**When to practice:** Child counts everything instead of seeing quantities, doesn't know number pairs that make 10, can't decompose numbers mentally

---

### 3. Stellenwerte verstehen (BLUE) - Place Value Understanding
**Purpose:** Understanding tens/ones structure, bundling, German number word system

**Key skills:**
- place_value_1: Bundle 10 ones into 1 ten
- place_value_2-3: Represent numbers with base-10 blocks
- place_value_4: Understand German number words (achtundneunzig = 8 and ninety)
- place_value_5: Mentally decompose numbers into tens and ones
- place_value_6: Understand 100-chart structure

**When to practice:** Child writes 98 as "89" after hearing "achtundneunzig", doesn't understand that 47 = 40 + 7, can't use place value for calculations

---

### 4. Grundstrategien (PURPLE) - Basic Calculation Strategies
**Purpose:** Foundation strategies for addition/subtraction

**Key skills:**
- basic_strategy_1-5: Finger calculations, ±1, ±2
- basic_strategy_6: Opposite change (gegensinniges Verändern)
- basic_strategy_7-10: Doubling strategies
- basic_strategy_11: Calculate with decade numbers (10, 20, 30...)
- basic_strategy_12-14: Halving strategies
- basic_strategy_18-19: Understanding equality and commutativity
- basic_strategy_20-23: Combining tens and ones, decade analogies

**When to practice:** Child relies only on counting, doesn't use doubling (7+7) to solve near-doubles (7+8), can't calculate with tens

---

### 5. Kombinierte Strategien (GRAY) - Combined Strategies
**Purpose:** Advanced strategies combining multiple approaches

**Key skills:**
- combined_strategy_1-2: Near-doubles (use double ±1)
- combined_strategy_3-4: Power of 5 (use 5 as anchor)
- combined_strategy_5-6: Power of 10 (calculate across 10)
- combined_strategy_7: Transform tasks for easier calculation
- combined_strategy_8: Partial steps method
- combined_strategy_12: Addition with crossing tens (27+8)
- combined_strategy_14: Subtraction with crossing tens (44-9)
- combined_strategy_15-16: 2-digit addition/subtraction with crossing

**When to practice:** Child can do basic operations but struggles with crossing decade boundaries, doesn't use strategic thinking for complex problems

---

## How the Diagnostic Flow Works

### Example 1: Question 21 - Dice Decomposition

```
Diagnostic Question 21:
"I rolled a 7 with two dice. What else could be on the dice?"

Child's response: Incorrect or incomplete

System action:
IfWrong_practice_skills: "decomposition_1, decomposition_2, decomposition_5, decomposition_6, decomposition_7"

Interpretation:
- decomposition_1: Child needs to practice finding ALL decompositions of a number
- decomposition_2: Use structured material (Rechenschiffchen) to visualize decompositions
- decomposition_5: Play games that reinforce decomposition thinking
- decomposition_6: Practice quick visual recognition of quantities
- decomposition_7: See structured representations of numbers to 10

User Profile Update:
skillTags: ['decomposition_1', 'decomposition_2', 'decomposition_5', 'decomposition_6', 'decomposition_7']

Exercise Matching:
ExerciseService filters all exercises where:
  exercise.skillTags CONTAINS ANY OF user.skillTags

Results in exercises like:
- "Decompose 10 with TwentyFrame" (tagged: decomposition_1, decomposition_3)
- "Quick Flash Game" (tagged: decomposition_6, decomposition_7)
- "Find All Ways to Make 8" (tagged: decomposition_1, decomposition_5)
```

### Example 2: Question 7 - Successor After 10

```
Diagnostic Question 7:
"Which number comes after 10?"

Child's response: Incorrect (maybe says "20" or doesn't know)

System action:
IfWrong_practice_skills: "counting_4, counting_5"

Interpretation:
- counting_4: Practice neighboring numbers on number line
- counting_5: Play games to reinforce successor/predecessor concept

User Profile Update:
skillTags: ['counting_4', 'counting_5']

Exercise Matching:
Child gets exercises about neighboring numbers, with special focus on
decade transitions (9→10, 19→20, etc.)
```

## Migration Notes

### For Developers

**Old code:**
```dart
if (question.ifWrongPractice.contains('12')) {
  // What is skill 12? Need to look it up...
}
```

**New code:**
```dart
if (question.ifWrongPracticeSkills.contains('decomposition_12')) {
  // Clear: this is about dice tower addition!
}
```

### Data Migration Steps

1. **Use new file:** `MathApp_Diagnostic_with_skills.csv` instead of old `MathApp - Diagnostic.csv`
2. **Column change:** `IfWrong_practice` (old, numbers) → `IfWrong_practice_skills` (new, named IDs)
3. **Parse as CSV list:** Skills are comma-separated strings like `"counting_1, counting_2"`
4. **Update UserProfile model:** `skillTags: List<String>` now contains IDs like `['counting_3', 'decomposition_1']`

### Backward Compatibility

For now, both systems exist:
- **Old:** Numbers 1-76+ (ambiguous)
- **New:** Named skill IDs (clear semantic meaning)

Eventually the old system will be deprecated once all references are updated.

## 6. PIKAS FÖDIMA Integration

### New Skill Categories (12 skills added)

The following categories extend the original 75 iMINT skills with concepts from PIKAS FÖDIMA research:

#### Ordinal Numbers (2 skills)
- `ordinal_1` - `ordinal_2`
- **Color:** Orange
- **Focus:** Understanding and using 1st, 2nd, 3rd... vs cardinal numbers
- **Source:** PIKAS Card 6 (Ordnungszahlen nutzen)
- **Why needed:** iMINT focuses on cardinal numbers (counting quantities); PIKAS adds ordinal understanding (position in sequence)

#### Representation Networking (4 skills)
- `representation_1` - `representation_4`
- **Color:** Teal
- **Focus:** Explicitly connecting Action ↔ Image ↔ Symbol representations
- **Source:** PIKAS Cards 3, 15 (Darstellungen vernetzen)
- **Why needed:** While iMINT uses representations, PIKAS explicitly teaches the SKILL of moving between them

#### Operational Sense (3 skills)
- `operation_sense_add`, `operation_sense_sub`, `operation_sense_story`
- **Color:** Brown
- **Focus:** Understanding what operations MEAN in real-world contexts
- **Source:** PIKAS Cards 19, 20, 33, 34 (Alltagssituationen, Rechengeschichten)
- **Why needed:** iMINT focuses on calculation strategies; PIKAS adds conceptual understanding of what + and - represent

#### Advanced Number Line (3 skills)
- `number_line_rechenstrich`, `number_line_zahlenstrahl`, `number_line_strategies`
- **Color:** Pink
- **Focus:** Distinguishing Rechenstrich (empty line for calculation) from Zahlenstrahl (marked line for positioning)
- **Source:** PIKAS Cards 16, 17 (Zahlen am Zahlenstrahl/Rechenstrich)
- **Why needed:** PIKAS makes explicit distinction between number line types; important pedagogical difference

### Combined Taxonomy Summary
- **iMINT skills:** 76 (5 categories)
- **PIKAS skills:** 12 (4 new categories)
- **TOTAL:** 88 uniquely identified skills

### Phase 1.5 Integration Status

**STATUS: SUFFICIENT FOR PHASE 2** ✅

- ✅ 36 of 58 PIKAS cards analyzed (62% complete)
- ✅ 12 new skills identified and added to taxonomy
- ✅ Pilot diagnostic questions created (9 questions in `MathApp_Diagnostic_PILOT_PIKAS.csv`)
- 🔄 Remaining 22 cards (Division, advanced Multiplication) to be analyzed just-in-time during Phase 4
- ✅ **Ready for Phase 2 exercise development**

**Bridge Approach:** Instead of completing exhaustive analysis of all 58 PIKAS cards before proceeding, we've taken a streamlined approach:
1. Added 12 new PIKAS-specific skills to the taxonomy (ordinal, representation networking, operational sense, advanced number line)
2. Created pilot diagnostic questions covering these new concepts (Q60-Q68)
3. Deferred remaining card analysis to Phase 4 when those specific exercises are being developed

This allows us to move forward with Phase 2 (Exercise Engine & Core Content) while maintaining the pedagogical integrity of both iMINT and PIKAS frameworks.

### Integration Philosophy

The app now benefits from BOTH frameworks:
- **iMINT** provides precision in targeting calculation strategies
- **PIKAS** adds depth in conceptual understanding and representation flexibility

Every exercise can be tagged with skills from both frameworks, ensuring comprehensive learning coverage.

---

## Reference Files

1. **skills_taxonomy.csv** - Complete list of all 87 skills with descriptions
2. **MathApp_Diagnostic_with_skills.csv** - 59 iMINT diagnostic questions mapped to named skills
3. **MathApp_Diagnostic_PILOT_PIKAS.csv** - 8 pilot PIKAS diagnostic questions for new skill categories
4. **iMINT_Kartei_extracted-pages/** - Original iMINT research PDFs (source of truth)
5. **PIKAS/PIKAS_Kartei/** - Extracted PIKAS FÖDIMA text files (116 pages)
6. **PIKAS_Analysis.md** - Detailed analysis of 36 PIKAS cards

## Quick Reference Table

### Original iMINT Categories
| Category | Color | # Skills | ID Prefix | Example |
|----------|-------|----------|-----------|---------|
| Zählen | Green | 11 | `counting_` | `counting_3` = Count on number line |
| Zahlzerlegung | Yellow | 16 | `decomposition_` | `decomposition_3` = All decompositions of 10 |
| Stellenwerte | Blue | 6 | `place_value_` | `place_value_5` = Tens-Ones Quiz |
| Grundstrategien | Purple | 23 | `basic_strategy_` | `basic_strategy_20` = Calculate with tens |
| Kombinierte Strategien | Gray | 20 | `combined_strategy_` | `combined_strategy_6` = Power of 10 strategy |

### New PIKAS Categories
| Category | Color | # Skills | ID Prefix | Example |
|----------|-------|----------|-----------|---------|
| Ordinal Numbers | Orange | 2 | `ordinal_` | `ordinal_1` = Use ordinal numbers for position |
| Representation Networking | Teal | 4 | `representation_` | `representation_4` = Flexible across all representations |
| Operational Sense | Brown | 3 | `operation_sense_` | `operation_sense_add` = Understand addition in context |
| Advanced Number Line | Pink | 3 | `number_line_` | `number_line_rechenstrich` = Use empty number line |

**Total: 88 uniquely identified skills (76 iMINT + 12 PIKAS)**
