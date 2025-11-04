# iMINT/PIKAS to App Translation Framework

## Purpose

This document provides a systematic framework for translating physical iMINT/PIKAS activities (designed for teacher-child interaction with hands-on materials) into effective digital app experiences.

## CRITICAL: The Cards Define the Scaffolding

**⚠️ MOST IMPORTANT PRINCIPLE: The scaffolding levels come FROM THE CARDS, not from a predetermined template.**

When implementing an exercise:
1. **Read the card's "Wie kommt die Handlung in den Kopf?" section carefully**
2. **The card explicitly describes the progression of actions** - follow these exactly
3. **The number of levels may vary** - some cards have 3 levels, some have 4, some have 2
4. **The specific actions are prescribed** - don't substitute different mechanics
5. **Only adapt for app limitations** - stay as faithful to the card as possible

### Example: iMINT Card 1 (Plättchen zählen) defines 4 levels explicitly:

> "Es gibt verschiedene Handlungen, um den Zählprozess zu begleiten:
> 1. Zuerst wird das gezählte Objekt **zur Seite geschoben**. Dabei wird die Zählzahl genannt.
> 2. Später wird es beim lauten Zählen nur **angetippt**.
> 3. Der nächste Schritt ist das laute Abzählen **ohne weitere äußere Handlung**.
> 4. Das Verfolgen der Zählhandlung mit den **Augen** und die Nennung des Ergebnisses stellt schließlich die schwierigste Aufgabe dar."

**App Translation for C1.1 V2 (IMPLEMENTED):**
- **Level 1:** Drag dots to "counted" area (zur Seite geschoben), counter displays current count
- **Level 2:** Tap/touch dots to mark counted (angetippt), counter displays current count
- **Level 3:** No interaction (ohne äußere Handlung), child counts silently by looking, enters total
  - **Toggle available:** Structured (grid) or Random (non-overlapping) layouts
- **Level 4:** Eye-tracking only (mit den Augen), count visible dots efficiently, enters total
  - **Toggle available:** Structured (grid) or Random (scattered) layouts
  - Non-overlapping random positioning with 0.08 minimum distance

**This is NOT a 3-level template!** The card specified 4 distinct scaffolding steps, and C1.1 V2 implements all 4.

### NEW REQUIREMENT: The Finale Level (ADHD Support)

**⚠️ AFTER implementing the card-prescribed levels, ADD ONE FINAL "SUMMARY" or "FINALE" LEVEL.**

**Purpose:** ADHD-informed Easy→Hard→Easy difficulty flow for rewarding completion

**Pedagogical Rationale:**
- The card-prescribed levels build from easy to progressively harder
- ADHD children need to experience success at the end to maintain motivation
- The finale level provides a "victory lap" - easier mixed review that ensures positive ending
- This creates the dopamine reward necessary for continued engagement

**Design Guidelines for Finale Levels:**

1. **Difficulty:** Easier than the hardest card-prescribed level
2. **Content:** Mix of problems from previous levels, not new concepts
3. **Quantity:** Typically 10 problems (enough to demonstrate mastery without fatigue)
4. **Variation:** Exercise-specific (see examples below)
5. **Completion Criteria:** This level determines "completed" status (finished + zero errors + time limits)

**Examples:**

| Exercise | Card Levels | Finale Level (Added) |
|---|---|---|
| C1.1 (Count Dots) | L1-4: Drag→Tap→Look→Flash (5-20 dots) | L5: Mix of 8-12 dots (structured layouts only, no flash) |
| Z1 (Decompose 10) | L1-3: Explore→Write→Memory | L4: Decompose 5-8 (easier numbers, same mechanics) |
| C2.1 (Order Cards) | L1-3: Tap→Drag→Memory (5-10 numbers) | L4: Order 5-7 numbers (easier range) |
| C3.1 (Count Forward) | L1-3: Hop→Write→Memory | L4: Mix of forward by 1s and 2s within 0-15 (easier range) |

**When to Design the Finale:**
- AFTER fully understanding the card's progression
- Think: "What would be a confidence-building review of what they just learned?"
- Avoid: New challenges, maximum difficulty, or time pressure
- Goal: Child leaves exercise feeling successful and accomplished

**Completion Tracking:**
- **Finished:** All levels (including finale) unlocked at least once
- **Completed:** Finished + zero errors in finale level + within time limits (typically 30s/problem)

## Core Principle: Handlung → Vorstellung → Symbol (Progressive Scaffolding)

The iMINT research emphasizes the learning progression:
1. **Handlung (Action)**: Physical manipulation with materials
2. **Vorstellung (Mental Imagery)**: Imagining the action without doing it
3. **Symbol (Mathematical Notation)**: Abstract symbolic calculation

**In the app**, we translate the **CARD'S SPECIFIC SCAFFOLDING** (which may have 2, 3, 4, or more levels):

---

## Translation Guidelines: From Card to App

### Step 1: Read "Wie kommt die Handlung in den Kopf?" Section

This section in each card explicitly describes the scaffolding progression. Extract the levels from the card.

**Example patterns you'll find:**
- **Card explicitly lists steps:** "Zuerst... Später... Der nächste Schritt... schließlich..."
- **Card describes reduction of support:** "mit Material... ohne Material... nur mit Augen..."
- **Card describes increasing difficulty:** "konkret... bildlich... abstrakt..."

### Step 2: Map Physical Actions to Digital Equivalents

For each level described in the card, translate the physical action:

| Physical Action (Card) | Digital Equivalent (App) |
|------------------------|--------------------------|
| Zur Seite schieben (push aside) | Drag object to different area |
| Antippen (tap/touch) | Tap/touch on screen |
| Keine Handlung (no action) | No interaction, visual remains |
| Mit Augen verfolgen (follow with eyes) | Brief flash, then hide |
| Material verdecken (cover material) | Hide visual, show only on errors |
| Finger zeigen (show fingers) | Interactive hand widget |
| Stift/Trennstrich (pen/divider) | Tap to place divider |

### Step 3: Preserve Card's Pedagogical Intent

**DO:**
- Follow the exact sequence of scaffolding steps from the card
- Match the level of support/challenge at each step
- Use the card's language for instructions where possible
- Implement all levels the card describes (even if >3 or <3)

**DON'T:**
- Force a 3-level structure if card has more/fewer levels
- Substitute easier mechanics (e.g., tap instead of drag if card says "schieben")
- Skip intermediate steps the card considers important
- Add extra difficulty the card doesn't prescribe

### Step 4: Adapt Only for Technical Limitations

**Acceptable adaptations:**
- "Laut zählen" (count aloud) → "Enter the count" (app can't hear speech reliably)
- "Lehrkraft beobachtet Mundbewegungen" → Track response time as proxy
- "Mit Partner arbeiten" → App provides automated partner prompts
- "Hände verdecken mit Tuch" → Hide visual representation

**Maintain pedagogical equivalence** - the child's mental work should be the same.

---

## Common Scaffolding Patterns in Cards

### Pattern A: Physical Manipulation → Reduced Support → Mental Work
**Example: Decompose 10 (Card 3)**
1. Partner places pen between fingers, you see hands
2. Hands covered with cloth, imagine fingers
3. Work with symbols only

**App Translation:**
1. Tap counters to flip colors, see equation auto-display
2. See counters, write equation yourself
3. Hidden counters, write from memory (shown briefly on errors)

### Pattern B: Concrete → Reduced Action → Eyes Only
**Example: Count the Dots (Card 1)**
1. Push each object aside while counting
2. Touch/tap each object while counting
3. Count without touching (just looking)
4. Brief glimpse, then count from memory

**App Translation:**
1. Drag dots to "counted" area, enter total
2. Tap dots (they mark as counted), enter total
3. Dots visible but no interaction, enter total
4. Flash dots 2 seconds, hide, enter from memory

### Pattern C: Full Visual → Partial Visual → No Visual
**Example: Number Line (Card 10)**
1. Drag number cards to positions on visible line
2. See line, estimate position, validate
3. Hidden line, position from mental image

**App Translation:**
(Already correctly implemented in C10.1)

---

## Translation Rules

### Rule 1: Physical → Visual (Not Physical Simulation)
❌ **Don't try to simulate** real fingers/hands (looks uncanny, doesn't add value)
✅ **Do use abstract visual representations** (counters, blocks, number lines) that convey the CONCEPT

### Rule 2: Teacher Prompts → Adaptive Hints
❌ **Don't require** open-ended verbal responses we can't process
✅ **Do provide** targeted written hints based on iMINT "Gezielte Impulse"

**Example from iMINT Card:**
- **Physical prompt:** "Stell dir jetzt deine Hände und den Stift vor. Wie viele Finger denkst du dir links und rechts vom Stift?" (Imagine your hands and the pen. How many fingers do you imagine left and right of the pen?)
- **App translation (Level 3 hint):** "Close your eyes and imagine 10 counters in a line. If 4 are blue, how many are red?"

### Rule 3: Observation → Data Tracking
❌ **Don't just track** correct/incorrect
✅ **Do track** patterns that reveal strategy:
- Response time (slow = counting, fast = recall)
- Error patterns (always off by 1 = counting error)
- Sequence of answers (systematic = mature approach)

**iMINT says:** "Die Lehrkraft beobachtet dabei, ob das Kind bei verdeckten Händen wieder zählt (auf Finger- und Mundbewegungen achten)."
(Teacher observes if child is counting again with covered hands - watch for finger and mouth movements)

**App equivalent:** Track response time. If consistently >5 seconds per decomposition, child may still be counting. Surface this in parent dashboard: "Practice needed: Fast recall of decompositions"

### Rule 4: Memorization Comes LAST
iMINT is explicit: "Ein Auswendiglernen der Zerlegungen ist erst sinnvoll, wenn diese Beziehungen verstanden worden sind."
(Memorizing decompositions only makes sense after these relationships are understood.)

**App translation:**
- Level 1-2: Focus on **understanding** (gegensinniges Verändern, pattern recognition)
- Level 3: Only unlocks after child demonstrates understanding in Level 2
- **Never** pure rote drill without visual foundation first

---

## Implementation Checklist

For any iMINT/PIKAS activity, ask:

### 1. What Does the Card Say?
- [ ] **FIRST:** Read the card's "Wie kommt die Handlung in den Kopf?" section
- [ ] Extract the exact scaffolding steps the card describes
- [ ] Note the specific actions at each step (schieben, antippen, no action, etc.)
- [ ] Count how many levels the card prescribes (may be 2, 3, 4, or more)

### 2. What is the Physical Action at Each Level?
- [ ] For **each level the card describes**, identify:
  - The hands-on material (fingers, counters, blocks, strips)
  - The specific manipulation (placing, flipping, dividing, bundling, dragging, tapping, just looking)
  - The mathematical relationship revealed by the action
  - What the child must do/produce at this level

### 3. How to Translate Each Level to App?
- [ ] For each card level, map physical action to digital equivalent (see table above)
- [ ] Preserve the pedagogical intent (same mental work for child)
- [ ] Adapt only for technical limitations (speech → typing, etc.)
- [ ] Keep the same sequence and number of levels as the card

### 4. What Helps Transition Between Levels?
- [ ] What prompt helps child move from more to less support?
- [ ] What hint helps child work at the more difficult levels?
- [ ] What visual fallback prevents frustration? (no-fail safety net)

### 4. What Data Reveals Strategy?
- [ ] Response time (counting vs recall)
- [ ] Error patterns (systematic vs random)
- [ ] Sequence of attempts (organized vs scattered)

### 5. Answer Uniqueness: Order Matters or Not?
- [ ] **CRITICAL DECISION:** Does order matter for this exercise?
- [ ] **Order-dependent (count separately):** Use when the pedagogical goal is understanding commutativity or seeing systematic patterns
  - Example: Decompose 10 → 2+8 and 8+2 are DIFFERENT (teaches gegensinniges Verändern pattern)
  - Example: Commutativity exercises → 3+5 and 5+3 are DIFFERENT (teaches that order can be swapped)
  - Implementation: Store as ordered pairs `"a_b"` without normalization
- [ ] **Order-independent (count as same):** Use when the focus is on the numerical relationship only
  - Example: "Find pairs that sum to 10" (any order acceptable)
  - Example: "Make 10 using two numbers" (focus on sum, not sequence)
  - Implementation: Normalize to canonical form `min_max` before storing
- [ ] Document this decision in exercise comments and config

---

## Example: Decompose 10 (Revised Design)

### iMINT Activity A (Card 3, Page 112):
> "Kind A legt einen Stift zwischen zwei Finger von Kind B. Kind B nennt die Anzahl seiner Finger zunächst links und dann rechts vom Stift."
> (Partner places pen between your fingers. You name the count left and right of the pen.)

### iMINT Activity B (Card 3, Page 112):
> "Jetzt werden die Hände mit einem Tuch zugedeckt: Kind B hat nun keine Sicht mehr auf seine Finger. Kind A nennt eine Zahl bis 10. Kind B stellt sich seine 10 Finger und die Zerlegungshandlung vor und benennt die Zerlegungszahlen."
> (Now hands are covered with cloth: Child B no longer sees their fingers. Partner names a number up to 10. Child B imagines their 10 fingers and the decomposition action and names the decomposition numbers.)

### App Translation:

**LEVEL 1: Explore Decompositions**
- Title: "Explore: Break Apart 10"
- Visual: 10 counters in a row (initially all red)
- Instruction: "Tap counters to flip them blue. Watch what happens!"
- Child taps 4 counters → they turn blue
- **Auto-display:** "10 = 4 blue + 6 red"
- Child can freely explore, equation updates in real-time
- No completion criteria - pure exploration
- Button: "Ready to practice? →"

**LEVEL 2: Write Decompositions**
- Title: "Practice: Write the Decomposition"
- Visual: 10 counters with random split (e.g., 7 blue, 3 red)
- Instruction: "How many blue counters? How many red? Write the equation!"
- Input: `10 = ___ + ___`
- Child enters values, gets immediate feedback
- After correct answer, new random decomposition appears
- Progress: "Correct answers: 8/10 to unlock next level"

**LEVEL 3: Find All Decompositions**
- Title: "Challenge: Find All Ways to Make 10!"
- Visual: **Hidden** (counters not shown)
- Instruction: "You know 10 can be broken into parts. How many ways can you find?"
- Input: `10 = ___ + ___`
- Tracks found decompositions (prevents duplicates)
- Progress: "Found 3 of 11 ways"
- **ORDER-DEPENDENT:** 2+8 and 8+2 count as DIFFERENT (all 11 ordered pairs: 0+10, 1+9, ..., 10+0)
- **Pedagogical reason:** Observing the full sequence reveals "gegensinniges Verändern" pattern (as first part increases by 1, second part decreases by 1)

**Error Handling in Level 3:**
- Wrong sum (e.g., `10 = 3 + 8`):
  - Feedback: "Hmm, 3 + 8 = 11, not 10. Let's see the counters!"
  - Counters appear briefly (3 sec) showing correct split
  - Then disappear again
- Already found:
  - Feedback: "Great! You already found 4 + 6. Can you find a different one?"
- Stuck finding all:
  - Hint 1: "Try starting with 0. What is 0 + ?"
  - Hint 2: "You found 1+9, 2+8, 3+7. Do you see a pattern?"
  - Hint 3: "Don't forget 5+5!"

---

## Summary: The 3-Level Scaffolding Pattern

| Level | Visual Support | Child Action | Purpose | Unlocks When |
|-------|---------------|--------------|---------|--------------|
| **1: Guided Exploration** | ✓ Always visible | Manipulate objects, read equation | Understand relationship | Always available |
| **2: Supported Practice** | ✓ Visible | See object, write equation | Build notation fluency | After exploration |
| **3: Independent Mastery** | ✗ Hidden (shown on error only) | Write from memory/imagination | Internalize ("in den Kopf") | After 80% success in Level 2 |

This framework ensures that **"Wie kommt die Handlung in den Kopf?"** (How does the action get into the head?) is properly addressed through progressive scaffolding, not just direct translation of physical materials.

---

## Application to Future Exercises

When implementing ANY iMINT or PIKAS exercise:

1. **Read the card** - identify the physical activity
2. **Apply this framework** - design 3 levels of scaffolding
3. **Translate "Gezielte Impulse"** - convert teacher prompts to adaptive hints
4. **Track strategy signals** - identify what data reveals child's thinking
5. **Test progression** - ensure child can move from visual to mental to symbolic

This ensures pedagogical integrity while adapting to the app medium.
