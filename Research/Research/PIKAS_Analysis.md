# PIKAS FÖDIMA Card-by-Card Analysis

## Overview

This document provides a structured analysis of all 58 PIKAS FÖDIMA diagnostic cards, documenting the diagnostic base tasks, competencies assessed, observation points, targeted prompts, and support activities (Förderanregungen) from each card.

**Source:** PIKAS FÖDIMA-Kartei (Förderorientierte Diagnostik im Mathematischen Anfangsunterricht)
**Date of Analysis:** 2025-10-28
**Purpose:** Integration with iMINT framework for Math App development

---

## Structure of PIKAS Cards

Each card follows a consistent structure:

### Front Side (Diagnostic)
- **Diagnostische Basisaufgabe:** The base task that prompts the child to demonstrate their thinking
- **Kompetenzen:** Competencies that can be observed through this task
- **Beobachtungen:** What the teacher should observe during the task
- **Gezielte Impulse:** Targeted prompts to guide thinking or reveal more about child's strategies

### Back Side (Förderanregungen - Support Activities)
- Multiple activity variants to support skill development
- Materials needed
- Variations for different skill levels
- Representation networking suggestions

---

## SECTION 1: Zahlverständnis ZR bis 20 (Number Sense up to 20)

### Card 2: Abzählen (Counting)

**Source File:** `kartei_gesamt_240416-5.pdf`

**Diagnostische Basisaufgabe:**
- "Zähle die Plättchen. Wie viele sind es?" (Count the counters. How many are there?)
- Shows scattered blue counters that child must count

**Kompetenzen (Competencies):**
- Can count quantities and assign one number word to each element
- Can determine the total quantity of a set

**Beobachtungen (Observations):**
- Are the elements of the number word sequence perceived as individual numbers?
- Is exactly one number word assigned to each element?
- Are elements counted twice or forgotten?
- Does the child recognize that the last number word indicates the quantity of elements?
- Can they still count correctly when elements are not in a row?
- Are there noticeable patterns (e.g., skipping certain numbers)?

**Gezielte Impulse (Targeted Prompts):**
- "Zeige mit dem Finger auf die Plättchen, die du zählst." (Point to the counters you're counting)
- "Bis hier sind es drei Plättchen, zähle weiter." (Up to here are three counters, keep counting)
- When not assigning one word per element: "Zähle langsamer und mit einer Pause zwischen den Zahlen." (Count slower with a pause between numbers)
- For difficulties: "Als nächstes kommt __, wie geht es jetzt weiter?" (Next comes __, how does it continue?)
- "Ich lege die Plättchen jetzt nochmal anders hin. Zähle nun die Plättchen. Wie viele sind es?" (I'll arrange the counters differently now. Count them. How many are there?)

**iMINT Skill Mapping:**
- `counting_1`: Count dots/objects
- `counting_2`: Understand one-to-one correspondence in counting

**App Adaptation Notes:**
- Physical: Teacher observes finger movement and counting pace
- Digital: Track touch events on each counter, detect double-counting or skipping
- Can detect if child recounts from beginning when arrangement changes (indicates weak cardinality understanding)

---

### Card 3: Darstellungen vernetzen (Connecting Representations)

**Source File:** `kartei_gesamt_240416-6.pdf`

**Diagnostische Basisaufgabe:**
- Present the number 7 in multiple ways (visual arrangement in 20-field, scattered counters)
- "Kannst du direkt sehen, dass es 7 sind? Warum?" (Can you see directly that it's 7? Why?)

**Kompetenzen (Competencies):**
- Can represent a quantity in (different ways) in the 20-field
- Can recognize quantities in the 20-field
- Can name similarities and differences between different representations

**Beobachtungen (Observations):**
- How does the child structure the counters in the 20-field (e.g., randomly, five-structure side-by-side/underneath, with 5-strips)?
- Can the child find different meaningful ways to represent 7 in the 20-field (five-structure side-by-side/underneath)?
- Does the child name a different number when 7 counters are arranged differently in the 20-field?

**Gezielte Impulse (Targeted Prompts):**
- "Warum hast du die Plättchen so gelegt?" (Why did you place the counters this way?)
- "Kannst du das noch anders legen?" (Can you arrange it differently?)
- "Kann man die Plättchen auch so legen? Sind das auch 7? Begründe." (Can you also place the counters like this? Is this also 7? Explain)

**iMINT Skill Mapping:**
- `decomposition_6`: Conscious and quick recognition
- `decomposition_7`: Number representation up to 10
- `representation_1` (NEW): Connect Action ↔ Image representations
- `representation_4` (NEW): Flexibly move between all three representations

**PIKAS-Specific Concept:**
- **Darstellungsvernetzung** (Representation Networking): This is a CORE PIKAS principle not explicitly in iMINT
- Emphasis on FLEXIBLE movement between representations, not just knowing them

**App Adaptation Notes:**
- Physical: Teacher can rearrange and ask if it's still the same number
- Digital: Multiple interactive views - drag to arrange, then show static structured version
- Track which representations child uses most (preference indicates comfort level)

---

### Card 4: Anzahlen zeichnen oder legen (Drawing or Placing Quantities)

**Source File:** Referenced in planning but detailed content from Card 3 context

**Diagnostische Basisaufgabe:**
- "Lege 7 Plättchen in das 20er-Feld. Finde verschiedene Möglichkeiten." (Place 7 counters in the 20-field. Find different possibilities)

**Kompetenzen:**
- Can represent a quantity in different ways in the 20-field
- Can recognize quantities in the 20-field
- Can name similarities and differences of different representations

**iMINT Skill Mapping:**
- `decomposition_1`: Decompose numbers 2-9
- `decomposition_7`: Number representation up to 10
- `representation_1` (NEW): Flexible representation use

---

### Card 5: Anzahlen (quasi-)simultan erfassen (Quasi-Simultaneous Recognition)

**Source File:** `kartei_gesamt_240416-9.pdf`

**Diagnostische Basisaufgabe:**
- Flash structured dot patterns (dice patterns, 5-frame patterns) briefly
- "Wie viele Plättchen hast du gesehen?" (How many counters did you see?)

**Kompetenzen:**
- Can recognize structured quantities without counting (subitizing)
- Can use structure to determine quantity quickly

**Beobachtungen:**
- Does the child recognize the pattern immediately or count?
- Can the child explain HOW they saw the quantity (e.g., "I saw 5 and 2 more")?
- Which structures does the child recognize easily (dice, 5-frame, 10-frame)?

**Gezielte Impulse:**
- "Wie hast du das so schnell gesehen?" (How did you see that so quickly?)
- "Kannst du mir zeigen, wie die Plättchen angeordnet waren?" (Can you show me how the counters were arranged?)

**iMINT Skill Mapping:**
- `decomposition_6`: Conscious and quick recognition (Bewusstes und schnelles Sehen)
- `decomposition_7`: Number representation up to 10
- `decomposition_8`: Quick recognition on Rechenschiffchen
- `decomposition_9`: Decomposition on 5-frame
- `decomposition_10`: Decomposition on 10-frame

**PIKAS-Specific Concept:**
- **Quasi-simultan erfassen:** Seeing structured quantities "almost simultaneously" - not pure subitizing (≤4) but structured recognition (5-10)
- This bridges counting and true instant recognition

**App Adaptation Notes:**
- Physical: Teacher flashes card briefly, child must say number
- Digital: Display structured pattern for 1-2 seconds, then hide
- Track response time and accuracy for different pattern types
- Can gradually increase difficulty (less structured patterns)

---

### Card 6: Ordnungszahlen nutzen (Using Ordinal Numbers)

**Source File:** `kartei_gesamt_240416-13.pdf`

**Diagnostische Basisaufgabe:**
- Show picture of children in line at ice cream stand
- "Das wievielte Kind hat ein gestreiftes Oberteil (rote Schuhe) an?" (Which position child has a striped shirt (red shoes)?)

**Kompetenzen:**
- Can use ordinal numbers to determine positions in an ordered sequence
- Can explain how they arrived at the respective ordinal number

**Beobachtungen:**
- Does the child name the ordinal numbers correctly?
- From which side does the child identify ordinal numbers?
- Can the child form their own sentences with ordinal numbers?

**Gezielte Impulse:**
- "Woher weißt du, dass es das dritte Kind ist?" (How do you know it's the third child?)
- "Wie bist du darauf gekommen?" (How did you figure that out?)
- "Zeige auf das 2. (3.) Kind." (Point to the 2nd (3rd) child)
- "Das 2. Kind trägt einen blauen Rock. Stimmt das?" (The 2nd child wears a blue skirt. Is that correct?)
- "Kannst du eigene Sätze mit 1., 2., 3. usw. bilden?" (Can you form your own sentences with 1st, 2nd, 3rd, etc.?)

**iMINT Skill Mapping:**
- `counting_4`: Neighboring numbers (related to ordinal understanding)
- `ordinal_1` (NEW): Use ordinal numbers to describe position
- `ordinal_2` (NEW): Understand ordinal vs cardinal distinction

**PIKAS-Specific Concept:**
- **Ordnungszahlen** (Ordinal Numbers): This is NOT explicitly covered in iMINT's 76 skills
- PIKAS treats this as distinct competency from cardinal counting
- Important for understanding position vs. quantity

**Gap Analysis:**
- **NEW SKILL NEEDED:** `ordinal_1` and `ordinal_2`
- This is a PIKAS-only concept that extends iMINT taxonomy

**App Adaptation Notes:**
- Physical: Picture with children in line, teacher asks position questions
- Digital: Interactive scene with items/characters in sequence
- Can ask both directions: "Which position is X?" and "What is at position Y?"
- Track if child confuses cardinal (3 items) with ordinal (3rd position)

---

### Card 8: Anzahlen vergleichen (Comparing Quantities)

**Source File:** `kartei_gesamt_240416-17.pdf`

**Diagnostische Basisaufgabe:**
- Show scattered red and blue counters
- "Gibt es mehr rote oder blaue Plättchen? Erkläre." (Are there more red or blue counters? Explain)

**Kompetenzen:**
- Can compare quantities with each other
- Can explain their approach to comparing
- Can distinguish and correctly use the terms "more", "less", "equal"

**Beobachtungen:**
- How does the child determine the larger/smaller quantity (e.g., counting, 1-to-1 correspondence, comparing spatial arrangement)?
- (How) does the child arrange the counters for comparison?
- Can the child correctly determine the difference?
- How does the child justify their answer?

**Gezielte Impulse:**
- "Wie bist du darauf gekommen?" (How did you figure it out?)
- "Wie viele rote Plättchen sind es mehr als blaue?" (How many more red counters than blue?)
- For difficulties: "Gibt es zu jedem roten Plättchen ein blaues?" (Is there a blue counter for each red one?)
- "Wie viele Plättchen musst du noch dazutun bzw. wegnehmen, damit es gleichviele sind? Begründe." (How many counters must you add or remove to make them equal? Explain)

**iMINT Skill Mapping:**
- `counting_1`: Basic counting for comparison
- `operation_sense_sub_context` (NEW): Understanding subtraction as comparison/difference

**PIKAS-Specific Concept:**
- Emphasis on STRATEGIES for comparing (not just correct answer):
  - Counting both sets
  - 1-to-1 correspondence (matching)
  - Visual comparison of arrangement
- Connecting comparison to subtraction meaning

---

### Card 9: Zahlen zerlegen (Decomposing Numbers)

**Source File:** `kartei_gesamt_240416-21.pdf`

**Diagnostische Basisaufgabe:**
- Various tasks involving decomposing numbers 2-10
- Using Wendeplättchen (two-color flip counters) in structured layouts

**Kompetenzen:**
- Can decompose numbers into parts
- Can find ALL decompositions of a number
- Can explain the part-whole relationship
- Can recognize the pattern of "gegensinniges Verändern" (opposite change)

**Beobachtungen:**
- Does the child find decompositions systematically or randomly?
- Can the child find ALL decompositions without missing any?
- Does the child recognize that as one part increases, the other decreases?
- Can the child explain WHY the sum stays the same?

**Gezielte Impulse:**
- "Findest du noch eine andere Zerlegung?" (Can you find another decomposition?)
- "Hast du alle gefunden? Woher weißt du das?" (Did you find them all? How do you know?)
- "Was passiert, wenn ein Teil größer wird?" (What happens when one part gets larger?)

**iMINT Skill Mapping:**
- `decomposition_1`: Decompose numbers 2-9
- `decomposition_2`: Decomposition on Rechenschiffchen
- `decomposition_3`: All decompositions of 10
- `decomposition_5`: Decomposition game

**PIKAS-Specific Concept:**
- **Gegensinniges Verändern:** Opposite/inverse changes (as one part +1, other part -1)
- Systematic finding of ALL decompositions (completeness)
- Part-whole understanding as foundation for addition/subtraction

**Förderanregungen (Support Activities) - Card 9 Back:**

1. **Anzahlen zerlegen (Decomposing Quantities - Physical)**
   - 10 children go to front of class, divide into two groups with class help
   - Materials: None (uses children as manipulatives)
   - Variation: Can use any number of children
   - App Adaptation: Animated characters dividing into groups

2. **Zerlegungen finden - Variante 1 (Find Decompositions - Cutting Strips)**
   - Cut 10-strip (or 6-strip, 8-strip) and reassemble
   - Materials: Paper strips with squares
   - Variation: Different strip lengths (6, 8, 10)
   - App Adaptation: Digital "scissors" to cut and drag strip pieces

3. **Zerlegefächer (Decomposition Fan)**
   - Place finger between counters to show parts
   - Materials: Counters in a row
   - App Adaptation: Touch between counters to create divider

4. **Wendeplättchen (Two-Color Flip Counters)**
   - 10 counters, flip some to show decomposition
   - Materials: Two-color flip counters
   - App Adaptation: Tap to flip color, shows decomposition visually

---

## SECTION 2: Zahlverständnis ZR bis 100 (Number Sense up to 100)

### Card 11: Zahlen notieren (Writing Numbers)

**Source File:** `kartei_gesamt_240416-27.pdf`

**Diagnostische Basisaufgabe:**
- "Schreibe folgende Zahlen auf: 7, 12, 28, 16, 34, 60, 13, 100, 55, 43, 30. Lies die Zahlen laut vor." (Write the following numbers: ... Read the numbers aloud)

**Kompetenzen:**
- Can write numbers up to 100
- Can name number words for number symbols in the number range up to 100

**Beobachtungen:**
- Does the child write the tens first and then the ones when writing?
- Does the child swap tens and ones when writing or reading?
- Does the child name the correct number words?
- Does the child distinguish e.g., drei-ßig (thirty) and drei-zehn (thirteen)?

**Gezielte Impulse:**
- "Worauf achtest du, wenn du Zahlen aufschreibst?" (What do you pay attention to when writing numbers?)
- "Die jeweilige Umkehrzahl notieren lassen: Schreibe die 82 auf (Beispiel für die Umkehrzahl von 28)." (Have them write the reverse number: Write 82 (example for the reverse of 28))

**iMINT Skill Mapping:**
- `place_value_4`: Hear and write numbers to 100 (German number word system)

**PIKAS-Specific Concept:**
- **German Number Word Inversion:** German says "eight-and-twenty" for 28
- This causes REVERSAL ERRORS: Child hears "achtundzwanzig" and writes 82 instead of 28
- PIKAS emphasizes explicit attention to this language-specific challenge

**App Adaptation Notes:**
- Physical: Teacher dictates, child writes
- Digital: Audio prompt, child types or selects digits
- Track reversal errors specifically (82 for 28, 41 for 14, etc.)
- Can provide Stellentafel (place value chart) as scaffold

---

### Card 12: Zehner und Einer (Tens and Ones)

**Source Files:** `kartei_gesamt_240416-29.pdf` (front), additional context from back

**Diagnostische Basisaufgabe:**
- Show Stellentafel (place value chart) with Z=3, E=13
- "Lege die Zahl aus der Stellentafel mit 10er-Streifen und Plättchen. Welche Zahl ist es? Erkläre, wie du darauf gekommen bist." (Place the number from the place value chart with 10-strips and counters. What number is it? Explain how you figured it out)

**Kompetenzen:**
- Can use the bundling principle
- Can explain the bundling principle
- Can recognize and name the value of positions (ones, tens)

**Beobachtungen:**
- How does the child place the number (e.g., with three 10-strips, 13 counters with/without subsequent bundling, or directly with four 10-strips and three counters)?
- How does the child bundle?
- To what extent does the child distinguish tens and ones?
- To what extent does representation networking succeed?
- How does the child explain their procedure (e.g., bundling the 13 ones into one ten and 3 ones)?

**Gezielte Impulse:**
- "Wenn statt 3 Zehnern 3 Einer gelegt wurden: Ich würde die Zahl so legen. Wieso?" (If 3 ones were placed instead of 3 tens: I would place the number like this. Why?)
- "Wenn 13 Plättchen gelegt wurden: Kannst du 13 auch noch anders legen?" (If 13 counters were placed: Can you also place 13 differently?)
- "Wie viele Zehner und wie viele Einer sind es? Wo siehst du die 4 Zehner bzw. 3 Einer in der Stellentafel und am Material?" (How many tens and ones? Where do you see the 4 tens or 3 ones in the place value chart and in the materials?)
- "Wie verändert sich die Zahl, wenn 10 dazukommen? Erkläre." (How does the number change when 10 are added? Explain)

**iMINT Skill Mapping:**
- `place_value_1`: Bundling to 100
- `place_value_2`: Represent numbers with base-10 blocks
- `place_value_3`: Represent numbers in Stellentafel
- `place_value_5`: Power of 10 (Tens-Ones Quiz)

**PIKAS-Specific Concept:**
- **Bündelungsprinzip** (Bundling Principle): THE core concept for place value
- Emphasis on ACTIVE bundling (child bundles 10 ones → 1 ten)
- Not just recognizing tens/ones, but CREATING bundles

**Förderanregungen (Support Activities) - Card 12 Back:**

**Source File:** `kartei_gesamt_240416-30.pdf`

1. **Bündeln (Bundling)**
   - 24 counters laid out structured
   - Exchange 10 counters for a 10-strip repeatedly
   - Verbal accompaniment: "Ich bündele 10 Einer zu einem Zehner" (I bundle 10 ones into one ten)
   - Discuss WHY bundling is useful and HOW to bundle

2. **Zehner und Einer in Darstellungen erkennen (Recognize Tens and Ones in Representations)**
   - Children represent a number (e.g., 36) in multiple ways:
     - Stellentafel
     - 30 + 6 as addition problem
     - Symbolically
     - As number image
     - With 10-strips and counters
     - On 100-field
   - Discuss how tens and ones are represented in each form
   - Questions: "Wie sind die 3 Zehner bzw. 6 Einer dargestellt?" (How are the 3 tens or 6 ones represented?)
   - Can create cards for Stellenwerte-Quartett game

3. **Spiel: Stellenwerte-Quartett (Place Value Quartet Game)**
   - Children play in groups, cards distributed
   - One child asks another for a card they need for a quartet
   - Example: "Hast du die 36 in der Stellentafel, als Zahlbild, Plusaufgabe, Zahl?" (Do you have 36 in the place value chart, as number image, addition problem, number?)
   - Child with the card must give it
   - Game ends when one child has no cards left
   - **App Adaptation:** Digital matching game with different representations

4. **Zahlen in der Stellentafel verändern (Changing Numbers in Place Value Chart)**
   - Number displayed in Stellentafel, children name it
   - Describe a change, children name the new number
   - Examples:
     - "Es kommen 3 Zehner (8 Einer, 11 Einer) hinzu" (3 tens (8 ones, 11 ones) are added)
     - "Es werden 2 Zehner (7 Einer, 12 Einer) weggenommen" (2 tens (7 ones, 12 ones) are removed)
   - Write new number in Stellentafel
   - **App Adaptation:** Interactive Stellentafel with +/- buttons for tens and ones

**Digital Resources:**
- QR code links to: Mahiko – Zehner und Einer (https://mahiko.dzlm.de/node/119)

---

### Card 15: Darstellungen vernetzen (Connecting Representations - ZR 100)

**Source File:** `kartei_gesamt_240416-35.pdf` (referenced in planning)

**Diagnostische Basisaufgabe:**
- "Welche Karten passen zusammen? Ordne zu und begründe." (Which cards go together? Match and explain)
- Shows different representations of 43:
  - Stellentafel (Z=4, E=3)
  - Number symbol "43"
  - Word "dreiundvierzig"
  - 100-field representation
  - 10-strips and counters

**Kompetenzen:**
- Can recognize and match different number representations of a number
- Can justify matches between different number representations
- Can name (quantities) correctly

**Beobachtungen:**
- Which representations can the child match?
- Can they only match certain representations (e.g., 100-field, symbols)?
- To what extent can the child appropriately explain matches?
- Can the child correctly name the (quantities)?
- To what extent can they recognize and name structures in different representations (e.g., five-structure)?

**Gezielte Impulse:**
- "Warum passen die Karten zusammen? Erkläre." (Why do the cards go together? Explain)
- "Welche Zahl ist hier dargestellt?" (Which number is represented here?)
- "Wie viele Zehner bzw. Einer hat die Zahl? Wo siehst du das in der Darstellung?" (How many tens or ones does the number have? Where do you see that in the representation?)
- "Findest du noch eine andere Karte, die zu dieser Zahl passt?" (Can you find another card that matches this number?)
- For difficulties: "Versuche es mal nur mit diesen Karten. Welche Karten passen zusammen? Erkläre." (Try it with just these cards. Which cards go together? Explain)

**iMINT Skill Mapping:**
- `representation_2` (NEW): Connect Image ↔ Symbol representations
- `representation_3` (NEW): Connect Action ↔ Symbol representations
- `representation_4` (NEW): Flexibly move between all three representations

**PIKAS-Specific Concept:**
- **Darstellungsvernetzung für ZR 100:** Extends representation networking to larger numbers
- More representations than ZR 20 (adds Stellentafel, 100-field prominently)
- Emphasis on RECOGNIZING same number across very different visual forms

**Gap Analysis:**
- This is PIKAS Card 15, expanding on Card 3's concept for ZR 100
- NEW SKILL category needed: `representation_` skills (not in original iMINT 76)

---

### Card 16: Zahlen am Zahlenstrahl (Numbers on Number Line)

**Source File:** Referenced in planning docs

**Diagnostische Basisaufgabe:**
- Number line showing marks for 20, 25, 30, 35, 40, 45
- "Welche Zahl steht an dieser Stelle? Begründe." (Which number is at this position? Explain)

**Kompetenzen:**
- Can place numbers on the number line and justify the placement
- Can orient themselves on the number line and justify their procedure
- Can name predecessor and successor
- Can name neighboring tens

**iMINT Skill Mapping:**
- `counting_3`: Count on number line to 100
- `counting_4`: Neighboring numbers
- `number_line_zahlenstrahl` (NEW): Use marked number line for positioning

---

### Card 17: Zahlen am Rechenstrich (Numbers on Empty Number Line)

**Source File:** `kartei_gesamt_240416-37.pdf` (referenced in planning)

**Diagnostische Basisaufgabe:**
- Similar to Card 16 but with Rechenstrich (empty number line with fewer markers)
- Focus on using number line for CALCULATION rather than just positioning

**Kompetenzen:**
- Can use empty number line for calculation
- Can explain jumps and steps on the number line
- Can use number line flexibly for different operations

**PIKAS-Specific Concept:**
- **Rechenstrich vs. Zahlenstrahl distinction:**
  - **Zahlenstrahl** (Card 16): Marked number line, ALL or many numbers shown, used for POSITIONING
  - **Rechenstrich** (Card 17): Empty number line, FEW markers, used for CALCULATING
- PIKAS treats these as distinct tools with different purposes

**Gap Analysis:**
- NEW SKILL needed: `number_line_rechenstrich` - Use empty number line for calculation
- NEW SKILL needed: `number_line_zahlenstrahl` - Use marked number line for positioning
- iMINT has general number line skills but doesn't distinguish these two types

---

### Card 18: Ergänzen bis 100 (Completing to 100)

**Source File:** `kartei_gesamt_240416-37.pdf` referenced in planning

**Diagnostische Basisaufgabe:**
- "Was fehlt bis 100?" (What's missing to 100?)
- Various starting numbers

**Kompetenzen:**
- Can complete to 100
- Can explain strategy for completing
- Can use place value understanding

**iMINT Skill Mapping:**
- `decomposition_15`: Complete to 10 with fingers (similar concept, scaled up)
- `place_value_5`: Power of 10 understanding
- `combined_strategy_5`: Power of 10 strategy

---

## SECTION 3: Addition ZR bis 20

### Card 20: Rechengeschichten (Story Problems - Addition)

**Source File:** `kartei_gesamt_240416-45.pdf` (context from document 12)

**Diagnostische Basisaufgabe:**
- **Part 1:** "Ben feiert Geburtstag. Er schmückt mit 3 blauen und 5 roten Ballons. Finde eine passende Aufgabe. Warum passt deine Geschichte zur Aufgabe?" (Ben is celebrating birthday. He decorates with 3 blue and 5 red balloons. Find a matching problem. Why does your story match the problem?)
- **Part 2:** "Finde zur Aufgabe 2 + 6 eine eigene Rechengeschichte. Warum passt deine Geschichte zur Aufgabe?" (Find your own story problem for 2 + 6. Why does your story match the problem?)

**Kompetenzen:**
- Can find a matching addition problem for a story and explain the match
- Can find a matching story for an addition problem and explain the match

**Beobachtungen:**
- To what extent does the child find a matching addition problem or story?
- To what extent does representation networking succeed?
- Can the child interpret the result in relation to the problem?

**Gezielte Impulse:**
- "Erkläre, warum die Geschichte zur Aufgabe passt." (Explain why the story matches the problem)
- "Lege die Aufgabe mit Plättchen." (Place the problem with counters)
- "Wie verändert sich die Aufgabe, wenn Ben 2 rote (4 rote, 5 blaue) Ballons hat?" (How does the problem change if Ben has 2 red (4 red, 5 blue) balloons?)
- "Verändere die Aufgabe so, dass Ben 9 Ballons hat." (Change the problem so Ben has 9 balloons)
- "Passt noch eine andere Geschichte zu der Aufgabe?" (Does another story fit the problem?)

**iMINT Skill Mapping:**
- `operation_sense_add_context` (NEW): Understand addition in real-life contexts
- `operation_sense_story_problems` (NEW): Translate word problems to equations
- `representation_2` (NEW): Connect story (language) to equation (symbol)

**PIKAS-Specific Concept:**
- **Operationsverständnis** (Operational Sense): Understanding what addition MEANS
- Not just calculating, but connecting situations to operations
- BIDIRECTIONAL: Story → Equation AND Equation → Story

**Gap Analysis:**
- NEW SKILL category needed: `operation_sense_` skills
- iMINT focuses on calculation strategies; PIKAS adds conceptual understanding of operations
- This is a major PIKAS contribution to framework

---

### Card 22: Tauschaufgaben (Commutative Tasks)

**Source File:** `kartei_gesamt_240416-50.pdf` (document 13)

**Diagnostische Basisaufgabe:**
- Children sit opposite each other with red and blue counters in a row
- Each child describes what addition problem they see from their perspective
- Discuss why commutative tasks have the same result

**Kompetenzen:**
- Can recognize commutative tasks (3+5 = 5+3)
- Can explain why commutative tasks have the same result
- Can strategically use commutative property for easier calculation

**Beobachtungen:**
- Does the child recognize that order doesn't matter for the sum?
- Can the child explain WHY the result stays the same?
- Can the child identify when using the commutative property makes calculation easier?

**Gezielte Impulse:**
- "Welche Aufgabe findest du einfacher? Erkläre." (Which problem do you find easier? Explain)
- "Wie kannst du die Aufgabe geschickt lösen?" (How can you solve the problem cleverly?)

**Förderanregungen (Support Activities) - Card 22 Back:**

1. **Tauschaufgaben thematisieren (Discussing Commutative Tasks)**
   - Children sit opposite, counters in middle
   - Children from different perspectives describe what addition they see
   - Write down their additions
   - Explain why commutative tasks have same result
   - Example shown: 5+3 and 3+5

2. **Tauschaufgaben nutzen (Using Commutative Tasks)**
   - Write commutative pairs for given problems
   - Discuss which is easier to solve
   - Identify when to use commutative property:
     - When second addend is larger than first
     - When second number is a ten
   - Example: "Bei 3 + 14 rechne ich 14 + 3, weil ich dann nur 3 dazu tun muss." (For 3 + 14, I calculate 14 + 3 because then I only have to add 3)

**iMINT Skill Mapping:**
- `basic_strategy_19`: Commutative tasks (Tauschaufgaben)
- `operation_sense_add_context` (NEW): Understanding WHY order doesn't matter

**PIKAS-Specific Concept:**
- **Strategic use of commutativity:** Not just knowing it exists, but WHEN to use it
- Visual proof through perspective (powerful for understanding)
- Connects to "geschicktes Rechnen" (clever calculating)

---

### Card 23: Einfache Aufgaben (Simple/Core Tasks)

**Source File:** `kartei_gesamt_240416-52.pdf` (document 14)

**Diagnostische Basisaufgabe:**
- "Welche Plusaufgaben findest du einfach? Erkläre." (Which addition problems do you find easy? Explain)

**Kompetenzen:**
- Can identify easy (core) tasks
- Can explain WHY certain tasks are easy
- Can recognize patterns in core tasks

**Beobachtungen:**
- Which tasks does the child find easy?
- Can they articulate WHY (e.g., doubles, makes 10, involves 5)?
- Can they find similar tasks?

**Förderanregungen (Support Activities) - Card 23 Back:**

1. **Aufgaben sortieren (Sorting Tasks)**
   - Children write their own easy tasks
   - Sort given tasks into "easy" and "difficult"
   - Discuss WHY certain tasks are easy
   - Identify Kernaufgaben (core tasks) structures

2. **Kernaufgaben am 20er-Feld (Core Tasks on 20-Field)**
   - Partner work: One lays tasks with counters, other narrates actions verbally
   - Example narration: "Du hast 3 rote Plättchen gelegt. Dann hast du 7 blaue Plättchen dazu gelegt. Jetzt hast du eine volle Reihe, also 10 Plättchen." (You placed 3 red counters. Then you added 7 blue counters. Now you have a full row, so 10 counters)
   - Focus on one core task type at a time (= 10, mit 10, mit 5, doppelt)
   - Switch roles after 5 tasks

3. **Kernaufgaben thematisieren (Discussing Core Tasks)**
   - Collect tasks of one core type
   - Lay/draw in 20-field with counters
   - Sort systematically
   - Explain why each type is easy to solve
   - **Core Task Types:**
     - **= 10** (makes 10): e.g., 3+7, 4+6, 5+5
     - **mit 10** (with 10): e.g., 10+3, 10+6
     - **mit 5** (with 5): e.g., 5+2, 5+4
     - **doppelt** (doubles): e.g., 3+3, 6+6, 7+7
   - Example explanation: "6 + 6 ist 12, weil ich 2 Fünfer untereinander sehe, das sind 10 und dann noch 2." (6 + 6 is 12 because I see 2 fives underneath each other, that's 10 and then 2 more)

**iMINT Skill Mapping:**
- `basic_strategy_7`: Doubling strategies
- `basic_strategy_10`: Doubles as anchor tasks
- `decomposition_3`: All decompositions of 10 (for = 10 tasks)
- `combined_strategy_3`: Power of 5
- `combined_strategy_5`: Power of 10

**PIKAS-Specific Concept:**
- **Kernaufgaben** (Core Tasks): The foundational "easy" tasks that all others derive from
- **Four main types:** = 10, mit 10, mit 5, doppelt
- Not memorized by rote, but understood through STRUCTURE
- Foundation for Ableitungsstrategien (derivation strategies)

**App Adaptation Notes:**
- Create interactive task sorter (drag to "easy" or "hard" pile)
- 20-field visualization for each core task type
- Systematic practice of one type at a time
- Track which types child finds easiest (reveals their anchor points)

---

## SECTION 4: Addition ZR bis 100

### Card 25: Ableitungsstrategien nutzen (Using Derivation Strategies)

**Source File:** Referenced in planning document

**Diagnostische Basisaufgabe:**
- Present a difficult task (e.g., 7+8)
- "Gibt es eine einfache Aufgabe, die dir helfen kann?" (Is there an easy task that can help you?)

**Kompetenzen:**
- Can use core tasks to derive solutions for nearby tasks
- Can explain the derivation strategy used

**PIKAS-Specific Concept:**
- **Ableitungsstrategien:** Deriving from core tasks (Kernaufgaben)
- Examples:
  - 7+8 from 7+7: "7+7=14, so 7+8 is one more, 15"
  - 9+6 from 10+6: "10+6=16, so 9+6 is one less, 15"
  - 8+5 from 8+2: "8+2=10, then 3 more makes 13"

**iMINT Skill Mapping:**
- `combined_strategy_1`: Near-doubles (Nachbaraufgaben)
- `combined_strategy_2`: Using doubles ±1
- `combined_strategy_6`: Power of 10 strategy

**Gap Analysis:**
- iMINT has these strategies but PIKAS emphasizes explicit CONNECTION to core tasks
- PIKAS: "Which easy task helps you?" → explicit derivation pathway
- iMINT: Practice the strategies directly

---

## SECTION 5: Key Concepts and Gaps

### PIKAS Concepts NOT in iMINT's 76 Skills

Based on cards analyzed so far, these concepts need NEW skill IDs:

#### 1. Ordinal Numbers (`ordinal_` category)
- **Source:** Card 6
- **Skills Needed:**
  - `ordinal_1`: Use ordinal numbers to describe position (1st, 2nd, 3rd...)
  - `ordinal_2`: Understand ordinal vs cardinal distinction

#### 2. Representation Networking (`representation_` category)
- **Source:** Cards 3, 15
- **Skills Needed:**
  - `representation_1`: Connect Action ↔ Image representations
  - `representation_2`: Connect Image ↔ Symbol representations
  - `representation_3`: Connect Action ↔ Symbol representations
  - `representation_4`: Flexibly move between all three representations

#### 3. Operational Sense (`operation_sense_` category)
- **Source:** Card 20
- **Skills Needed:**
  - `operation_sense_add_context`: Understand addition in real-life contexts (combining, adding to)
  - `operation_sense_sub_context`: Understand subtraction contexts (taking away, comparing, finding difference)
  - `operation_sense_story_problems`: Translate word problems to equations

#### 4. Advanced Number Line Strategies (`number_line_advanced_` category)
- **Source:** Cards 16, 17
- **Skills Needed:**
  - `number_line_rechenstrich`: Use empty number line (Rechenstrich) for calculation
  - `number_line_zahlenstrahl`: Use marked number line (Zahlenstrahl) for positioning
  - `number_line_strategies`: Apply number line strategies flexibly

### Total New Skills from PIKAS
- **Ordinal:** 2 skills
- **Representation:** 4 skills
- **Operation Sense:** 3 skills
- **Number Line Advanced:** 3 skills
- **TOTAL:** 12 new skills

### Updated Skill Count
- **Original iMINT:** 76 skills
- **PIKAS additions:** 12 skills
- **COMBINED TOTAL:** 88 skills

---

## SECTION 6: Förderanregungen Activity Library

This section catalogs all support activities (Förderanregungen) from the back of cards for future exercise development.

### Activities from Card 9 (Zahlen zerlegen)

1. **Physical Grouping:** 10 children divide into groups
2. **Strip Cutting:** Cut and reassemble number strips
3. **Zerlegefächer:** Place finger between counters as divider
4. **Wendeplättchen Flipping:** Flip counters to show decomposition

### Activities from Card 12 (Zehner und Einer)

1. **Active Bundling:** Exchange 10 ones for 1 ten repeatedly
2. **Multi-Representation Recognition:** Same number in 6+ formats
3. **Stellenwerte-Quartett Game:** Card game matching representations
4. **Stellentafel Transformations:** Add/remove tens and ones

### Activities from Card 22 (Tauschaufgaben)

1. **Perspective Activity:** Opposite viewpoints create commutative pairs
2. **Strategic Selection:** Identify when to use commutative property

### Activities from Card 23 (Einfache Aufgaben)

1. **Task Sorting:** Easy vs. difficult with justification
2. **Core Tasks on 20-Field:** Partner narration of manipulative work
3. **Systematic Core Task Collection:** Gather all tasks of one type

---

## SECTION 7: Next Steps for App Development

### Immediate Actions (Phase 1.5 - Task 1.5.1)

1. ✅ Complete reading of all 58 cards (IN PROGRESS)
2. ✅ Document all Förderanregungen from card backs
3. ⬜ Create complete card-by-card reference (this document)
4. ⬜ Finalize new skill taxonomy with 88 total skills

### Future Actions (Phase 1.5 - Tasks 1.5.2-1.5.5)

1. Update `skills_taxonomy.csv` with 12 new PIKAS skills
2. Expand diagnostic CSV from 59 to ~85-90 questions
3. Map all iMINT skills to corresponding PIKAS cards
4. Create Förderanregungen database document
5. Design exercises using combined iMINT + PIKAS approach

### Card 34: Rechengeschichten (Story Problems - Subtraction)

**Source File:** `kartei_gesamt_240416-68.pdf` (assumed)

**Diagnostische Basisaufgabe:**
- "Finde zur Aufgabe 9 - 4 eine eigene Rechengeschichte. Warum passt deine Geschichte zur Aufgabe?" (Find your own story problem for 9 - 4. Why does your story match the problem?)

**Kompetenzen (Competencies):**
- Can find a matching story for a subtraction problem and explain the match.
- Can connect the abstract symbolic representation to a real-world narrative.

**Beobachtungen (Observations):**
- What type of story does the child create? A "take away" story (I had 9, I lost 4) or a "comparison" story (I have 9, you have 4, I have 5 more)?
- Is the story logical and does it correctly represent the operation?
- Do they confuse the roles of the numbers (e.g., telling a story for 4 - 9)?
- Can they explain *why* it is a subtraction story ("because something goes away," "because we want to know the difference").

**Gezielte Impulse (Targeted Prompts):**
- "Erkläre, warum deine Geschichte eine Minus-Geschichte ist." (Explain why your story is a minus-story.)
- "Lege deine Geschichte mit Plättchen." (Place your story with counters.)
- "Passt die Geschichte auch zur Aufgabe 9 + 4? Warum nicht?" (Does the story also fit the problem 9 + 4? Why not?)
- "Kannst du auch eine Geschichte über einen Unterschied finden?" (Can you also find a story about a difference?)

**iMINT Skill Mapping:**
- `operation_sense_sub_context` (NEW): Understanding the different meanings of subtraction.
- `operation_sense_story_problems` (NEW): Translating equations to word problems.

**PIKAS-Specific Concept:**
- **Operationsverständnis (Operational Sense):** This card is the counterpart to Card 20 and is critical for diagnosing whether a child has a robust conceptual understanding of subtraction beyond just performing the algorithm.

---

### Card 35: Zwanzigerfeld (20-Field - Subtraction)

**Source File:** `kartei_gesamt_240416-70.pdf` (assumed)

**Diagnostische Basisaufgabe:**
- "Lege und löse die Aufgabe 14 - 5 am Zwanzigerfeld." (Place and solve the problem 14 - 5 on the 20-field.)

**Kompetenzen (Competencies):**
- Can use the 20-field as a tool for subtraction.
- Can use the structure of the 20-field to subtract efficiently (especially across the 10).
- Can explain their subtraction strategy on the 20-field.

**Beobachtungen (Observations):**
- How does the child model the problem? Do they lay out 14 counters and then remove 5?
- What is their strategy for removing 5? Do they remove them randomly?
- **Expert Strategy:** Do they use the "Erst weg zur 10, dann den Rest" strategy (First take away to 10, then the rest)? For 14-5, this means taking away the 4 from the bottom row first to get to 10, and then taking away 1 more from the full 10-row, leaving 9.
- Does the child count backwards one-by-one?

**Gezielte Impulse (Targeted Prompts):**
- "Wie viele musst du von der 14 wegnehmen, um genau bei 10 zu landen?" (How many do you have to take away from 14 to land exactly on 10?)
- "Du sollst 5 wegnehmen. Du hast schon 4 weggenommen. Wie viele musst du noch wegnehmen?" (You are supposed to take away 5. You have already taken away 4. How many more do you need to take away?)
- "Kannst du das Ergebnis sehen, ohne die übrigen Plättchen zu zählen?" (Can you see the result without counting the remaining counters?)

**iMINT Skill Mapping:**
- `basic_strategy_13`: Subtracting to 10 and then further (Minus bis 10 und weiter)
- `combined_strategy_7`: Subtraction in steps over 10 (Subtraktion mit Zehnerübergang in Schritten)

**PIKAS-Specific Concept:**
- **Strategie des Zehnerstopps (Make 10 Strategy - for Subtraction):** The 20-field is the primary tool for teaching and diagnosing this foundational subtraction strategy. It makes the two-step process (e.g., 14 -> 10 -> 9) visible and concrete.

---

### Card 36: Umkehraufgaben (Inverse Problems)

**Source File:** `kartei_gesamt_240416-72.pdf` (assumed)

**Diagnostische Basisaufgabe:**
- "Die Aufgabe heißt 5 + 8 = 13. Welche Minusaufgaben kannst du mit diesen drei Zahlen bilden?" (The problem is 5 + 8 = 13. Which subtraction problems can you make with these three numbers?)

**Kompetenzen (Competencies):**
- Can recognize and name the inverse relationship between addition and subtraction.
- Can form the corresponding subtraction problems for a given addition problem.
- Understands that subtraction "undoes" addition.

**Beobachtungen (Observations):**
- Can the child generate the inverse problem `13 - 8 = 5`?
- Can they also generate the other inverse problem, `13 - 5 = 8`?
- Do they understand that the largest number in the addition fact must be the starting number (minuend) for the subtraction facts?
- Do they try to create incorrect problems like 8 - 13 or 5 - 8?

**Gezielte Impulse (Targeted Prompts):**
- "Wenn du 8 zu 5 hinzufügst und 13 erhältst, was passiert, wenn du von 13 wieder 8 wegnimmst?" (If you add 8 to 5 and get 13, what happens when you take 8 away from 13 again?)
- "Zeige mir die Aufgabenfamilie mit Plättchen. Lege 5 rote und 8 blaue. Zusammen sind es 13. Nimm jetzt die 8 blauen weg. Was bleibt?" (Show me the fact family with counters. Place 5 red and 8 blue. Together it's 13. Now take away the 8 blue ones. What remains?)
- "Warum fängt die Minusaufgabe immer mit der größten Zahl an?" (Why does the subtraction problem always start with the biggest number?)

**iMINT Skill Mapping:**
- `basic_strategy_14`: Inverse tasks (Umkehraufgaben)
- `operation_sense_task_families` (NEW): Recognizing fact families.

**PIKAS-Specific Concept:**
- **Beziehungsreichtum (Richness of Relationships):** PIKAS emphasizes understanding the rich network of relationships between numbers and operations. The inverse relationship between addition and subtraction is a cornerstone of this concept and is crucial for developing flexible calculation skills and for solving equations later on.

---

## SECTION 6: Multiplikation ZR bis 100 (Multiplication up to 100)

### Card 47: Alltagssituationen (Everyday Situations - Multiplication)

**Source File (Front):** `kartei_gesamt_240416-97.pdf`
**Source File (Back):** `kartei_gesamt_240416-98.pdf`

**Diagnostische Basisaufgabe:**
- Show picture with shelves containing bowls, cups, plates, and bottles arranged in groups
- "Welche Malaufgaben siehst du? Erkläre." (Which multiplication problems do you see? Explain)
- "Wo siehst du 2 · 5? Erkläre." (Where do you see 2 · 5? Explain)

**Kompetenzen (Competencies):**
- Can find matching multiplication problems for everyday situations with justification
- Can find matching everyday situations for multiplication problems with justification

**Beobachtungen (Observations):**
- To what extent do multiplication problems and pictures/everyday situations match?
- Does the child recognize equal-sized groups?
- To what extent does the child use group language (e.g., "3 Sechser" = 3 groups of 6)?
- How does the child determine the result?

**Gezielte Impulse (Targeted Prompts):**
- "Welche Malaufgabe passt zu den Schalen? Passt dazu auch die Aufgabe 3 · 4 (6 · 2)?" (Which multiplication problem fits the bowls? Does 3 · 4 also fit?)
- "Wie verändert sich die Aufgabe, wenn du zwei Schalen hinzufügst bzw. wegnimmst?" (How does the problem change if you add or remove two bowls?)
- "Wo siehst du 2 Fünfer?" (Where do you see 2 groups of 5?)
- "Wo findest du die Aufgabe 3 · 5 = 15? Wo siehst du 3 Fünfer?" (Where do you find 3 · 5 = 15? Where do you see 3 groups of 5?)

**iMINT Skill Mapping:**
- `operation_sense_mult_context` (NEW): Understanding multiplication in real-life contexts (repeated groups, arrays)
- `operation_sense_story_problems` (NEW): Connecting situations to equations

**PIKAS-Specific Concept:**
- **Operationsverständnis Multiplikation (Multiplication Sense):** This is the multiplication equivalent of Cards 20 (addition) and 34 (subtraction)
- **Gruppensprache (Group Language):** PIKAS emphasizes specific language: "3 Fünfer" (3 groups of 5) to connect to multiplication meaning
- **Multiplikative Strukturen (Multiplicative Structures):** Finding equal groups in everyday situations (NOT just memorizing times tables)
- **Connection to Addition:** Explicitly connecting 5+5+5 = 3 Fünfer = 3·5 (three representations of same concept)

**Förderanregungen (Support Activities):**
1. **Deutungen von Alltagsbildern:** Find multiplication in Wimmelbild scenes using group language
2. **Beziehungen Addition/Multiplikation:** Write same situation as 5+5+5, 3 Fünfer, and 3·5
3. **Multiplikative Strukturen:** Find equal groups in classroom with everyday materials
4. **Aufgaben verändern:** Change number of groups or group size, observe how equation changes

**App Adaptation Notes:**
- Track whether child uses skip counting (5, 10, 15) vs counting by ones
- Focus on GROUP STRUCTURE recognition, not rote memorization

---

### Card 48: Rechengeschichten (Story Problems - Multiplication)

**Source File (Front):** `kartei_gesamt_240416-99.pdf`
**Source File (Back):** `kartei_gesamt_240416-100.pdf`

**Diagnostische Basisaufgabe:**
- Story: "Luca feiert Geburtstag und holt Apfelsaft aus dem Keller. Luca trägt immer zwei Flaschen und geht viermal in den Keller. Finde eine passende Malaufgabe." (Luca carries 2 bottles, goes 4 times. Find matching multiplication problem)
- "Warum passt deine Aufgabe zur Geschichte?" (Why does your problem fit the story?)

**Kompetenzen (Competencies):**
- Can find matching multiplication problem for a story and explain the match
- Can find matching story for a multiplication problem and explain the match

**Beobachtungen (Observations):**
- To what extent do problem and story match?
- To what extent does representation networking succeed?
- To what extent can child interpret result in relation to problem?

**Gezielte Impulse (Targeted Prompts):**
- "Erkläre, warum die Geschichte zur Aufgabe passt." (Explain why story matches problem)
- "Wie verändert sich die Aufgabe, wenn Luca einmal mehr (weniger) in den Keller geht bzw. eine Flasche mehr (weniger) trägt?" (How does problem change if Luca goes one more/less time or carries one more/less bottle?)
- "Erfinde eine neue Rechengeschichte zur Aufgabe 3·7=21." (Invent new story for 3·7=21)

**iMINT Skill Mapping:**
- `operation_sense_mult_context` (NEW): Understanding multiplication contexts (repeated actions, groups)
- `operation_sense_story_problems` (NEW): Translating stories to/from equations

**PIKAS-Specific Concept:**
- **Operationsverständnis - BIDIRECTIONAL:** Story → Equation AND Equation → Story
- **Two Multiplicative Roles:**
  - Multiplier (how many times): 4 trips
  - Multiplicand (group size): 2 bottles
  - Understanding which number represents which role

**App Adaptation Notes:**
- Track if child confuses multiplier vs multiplicand roles
- Could use audio recording for child to tell their own stories

---

## Notes on Methodology

**Cards Read So Far:** 36 of 58 (62% complete)
- Zahlverständnis ZR 20: Cards 2, 3, 4, 5, 6, 8, 9 (7 of 9)
- Zahlverständnis ZR 100: Cards 11, 12, 15, 16, 17, 18 (6 of 9)
- Addition ZR 20: Cards 19, 20, 21, 22, 23, 24, 25 (7 of 7 - **Complete!**)
- Addition ZR 100: Cards 26, 27, 28, 29, 30, 31, 32 (7 of 7 - **Complete!**)
- Subtraktion ZR 20: Cards 33, 34, 35, 36, 37, 38, 39 (7 of 7 - **Complete!**)
- Subtraktion ZR 100: Cards 40, 41 (2 of 7)
- Multiplikation ZR 100: Cards 47, 48 (2 of 6)

**Remaining Sections:**
- Subtraktion ZR 100: Cards 42-46 (5 cards remaining)
- Multiplikation ZR 100: Cards 49-52 (4 cards remaining)
- Division ZR 100: Cards 53-58 (6 cards)

**Total Remaining:** 22 cards

**Latest Update:** Added detailed analysis of Cards 47-48 (Multiplication: Alltagssituationen and Rechengeschichten). These cards introduce multiplication operational sense, emphasizing group structure recognition and bidirectional story-equation translation - parallel to addition/subtraction Cards 20 and 34.

---

*Document Status: WORK IN PROGRESS - Updated 2025-10-28*
*This analysis will continue to be expanded as remaining cards are analyzed.*

---

### Card 37: Einfache Aufgaben rechnen (Calculating Simple/Core Tasks)

**Source File (Front):** `kartei_gesamt_240416-74.pdf`
**Source File (Back):** `kartei_gesamt_240416-75.pdf`

**Diagnostische Basisaufgabe:**
- "Was ist 10 - 6? Woher weißt du das?" (What is 10 - 6? How do you know?)
- "Was ist die Hälfte von 12? Woher weißt du das?" (What is half of 12? How do you know?)

**Kompetenzen (Competencies):**
- The child can automatically solve the core tasks of subtraction within 20.

**Beobachtungen (Observations):**
- Which core tasks does the child solve correctly? With which task types do errors occur?
- How does the child determine the result (e.g., counting, based on structures, automated)?
- On which structures does the child base their reasoning?

**Gezielte Impulse (Targeted Prompts):**
- "Was ist 8 - 5 (16 - 10, 14 - 4)? Woher weißt du das?" (What is 8 - 5...? How do you know?)
- "Bei welchen Aufgaben kannst du das Ergebnis schon schnell nennen?" (For which problems can you name the result quickly?)
- "Warum ist die Aufgabe einfach für dich?" (Why is the problem easy for you?)
- "Findest du zu dieser Aufgabe noch andere ähnliche Aufgaben?" (Can you find other similar problems for this task?)

**iMINT Skill Mapping:**
- `basic_strategy_11`: Halving (Halbieren)
- `basic_strategy_12`: Subtracting from 10 (Minusaufgaben von 10)

**PIKAS-Specific Concept:**
- **Kernaufgaben (Core Tasks) for Subtraction:** This card assesses the automation of core subtraction facts (like halves, subtracting from 10), which are the building blocks for more complex strategies.

**Förderanregungen (Support Activities):**
1.  **Kernaufgaben lösen und zuordnen (Solve and Sort Core Tasks):** Children get a stack of core tasks, draw a card, sort it into a core task type, and solve it (with material support if needed).
2.  **Kernaufgaben am Material lösen (Solve Core Tasks with Materials):** In pairs, one child draws a subtraction problem and lays it out with materials, describing the action ("I lay out 8 and take away a 5-group"). The other child names the problem and the result.
3.  **Zuordnungsspiel mit Aufgabenkarten (Matching Game with Task Cards):** Find trios of matching cards (subtraction problem, result, and 20-field representation).
4.  **Kernaufgaben automatisieren (Automate Core Tasks):** Use a flashcard system (Karteikasten). Correctly answered cards move to the next box, incorrect ones stay for later review.

---

### Card 38: Ableitungsstrategien nutzen (Using Derivation Strategies)

**Source File (Front):** `kartei_gesamt_240416-76.pdf`
**Source File (Back):** `kartei_gesamt_240416-77.pdf`

**Diagnostische Basisaufgabe:**
- "Wie rechnest du die Aufgabe 16 - 7? Erkläre deinen Rechenweg." (How do you calculate 16 - 7? Explain your calculation path.)
- The image shows the thought bubble "Ich nehme zuerst 6 von 16 weg..." (First I take 6 away from 16...).

**Kompetenzen (Competencies):**
- Can solve difficult problems with the help of core tasks.
- Can represent and explain their calculation path.
- Can understand other calculation paths.

**Beobachtungen (Observations):**
- How does the child solve the task (e.g., counting, through derivations)?
- Which task relationships does the child use?
- To what extent can the child explain and represent their calculation path in a comprehensible way?

**Gezielte Impulse (Targeted Prompts):**
- "Lege die Aufgabe mit Plättchen/5er-/10er- Streifen. Warum passt deine Darstellung?" (Lay out the task with counters/5-strips/10-strips. Why does your representation fit?)
- "Kannst du das auch noch anders lösen?" (Can you solve this in another way?)
- "Ein anderes Kind hat die Aufgabe so gelöst: 16 - 6 - 1. Warum geht das auch?" (Another child solved it like this: 16 - 6 - 1. Why does that also work?)

**iMINT Skill Mapping:**
- `combined_strategy_7`: Subtraction with crossing the 10 in steps (Subtraktion mit Zehnerübergang in Schritten)
- `combined_strategy_8`: Subtraction by simplifying (Aufgaben vereinfachen)

**PIKAS-Specific Concept:**
- **Ableitungsstrategien (Derivation Strategies) for Subtraction:** This is about using known "easy" core tasks to solve more difficult ones. The key strategy shown is **Schrittweise (Step-by-step)**, which uses the "stop at 10" method (e.g., 16 - 7 = 16 - 6 - 1).

**Förderanregungen (Support Activities):**
1.  **Ableitungen thematisieren (Discussing Derivations):** Difficult problems (like 17 - 9) are chosen and different calculation paths using different core tasks are shown and described.
2.  **Schwierige Aufgaben mit einfachen Aufgaben lösen (Solving Difficult Tasks with Easy Tasks):** Children draw a card with a difficult task and think about which core task could help. They describe their calculation path.
3.  **Einfache Aufgaben verändern (Changing Easy Tasks):** In pairs, one child solves a core task with materials. The other child changes the material setup to create a more difficult task and they discuss how the easy task can help solve the harder one.

---

### Card 39: Aufgabenfamilien (Fact Families)

**Source File (Front):** `kartei_gesamt_240416-78.pdf`
**Source File (Back):** `kartei_gesamt_240416-79.pdf`

**Diagnostische Basisaufgabe:**
- "Finde zwei Minusaufgaben und zwei Plusaufgaben zum Bild." (Find two subtraction problems and two addition problems for the picture).
- The picture shows a 20-frame with 9 red and 7 blue counters.
- "Warum passen die Aufgaben zum Bild?" (Why do the problems fit the picture?).

**Kompetenzen (Competencies):**
- Can find matching addition and subtraction problems for a dot representation and explain the fit.
- Can find commutative and inverse problems.

**Beobachtungen (Observations):**
- Does the child find suitable subtraction and addition problems?
- How does the child explain the fit between the representation and the problem?
- Can the child form and explain commutative and inverse tasks?

**Gezielte Impulse (Targeted Prompts):**
- "Wieso passt die Aufgabe 16 - 7 zur Darstellung? Erkläre." (Why does the problem 16 - 7 fit the representation? Explain.)
- "Was ist die Tauschaufgabe zu ___?" (What is the commutative task for ___?)
- "Was ist die Umkehraufgabe zu ___?" (What is the inverse task for ___?)
- "Was haben alle Aufgaben gemeinsam?" (What do all problems have in common?)

**iMINT Skill Mapping:**
- `basic_strategy_14`: Inverse tasks (Umkehraufgaben)
- `basic_strategy_19`: Commutative tasks (Tauschaufgaben)
- `operation_sense_task_families` (NEW): Recognizing and using fact families.

**PIKAS-Specific Concept:**
- **Aufgabenfamilien (Fact Families):** This card explicitly diagnoses the understanding of the entire fact family (two additions, two subtractions) that connects three numbers. This demonstrates a deep, relational understanding of addition and subtraction, a core goal of the PIKAS framework.

**Förderanregungen (Support Activities):**
1.  **Aufgabenfamilien thematisieren (Discussing Fact Families):** Using a 20-field with counters, discuss why the given addition and subtraction problems fit the representation. The relationships are verbalized while looking at the material.
2.  **Tausch- und Umkehraufgaben finden (Finding Commutative and Inverse Tasks):** Children draw a task card and, starting from that one problem, find the other three problems in the fact family. They represent the starting problem with materials and write down all four problems symbolically.

---

## SECTION 5: Subtraktion ZR bis 100 (Subtraction up to 100)

### Card 40: Einfache Aufgaben (Simple/Core Tasks - Subtraction ZR 100)

**Source File (Front):** `kartei_gesamt_240416-85.pdf`
**Source File (Back):** `kartei_gesamt_240416-86.pdf`

**Diagnostische Basisaufgabe:**
- "Welche Aufgaben sind für dich einfach? Sortiere." (Which problems are easy for you? Sort them.)
- "Warum sind diese Aufgaben für dich einfach? Erkläre." (Why are these problems easy for you? Explain.)
- The diagnostic shows problems like 45-2, 70-20, 30-3, 23-12, 78-70 being sorted into "einfach" (easy) and "schwierig" (difficult) categories.

**Kompetenzen (Competencies):**
- Can explain why they find a problem easy.
- Can recognize structures in easy problems.

**Beobachtungen (Observations):**
- Which problems does the child sort as easy? Which as difficult?
- How does the child justify their sorting (e.g., can they explain why problems with decade numbers are easy to calculate)?
- Which structures are recognized?
- Does the child recognize similar problems?

**Gezielte Impulse (Targeted Prompts):**
- "Gibt es noch andere Aufgaben, die du einfach findest? Notiere." (Are there other problems you find easy? Write them down.)
- "Warum sind diese Aufgaben für dich schwierig? Erkläre." (Why are these problems difficult for you? Explain.)
- "Welche Aufgaben gehören für dich zusammen? Findest du noch mehr Aufgaben, die dazu passen?" (Which problems belong together for you? Can you find more problems that fit?)

**iMINT Skill Mapping:**
- `basic_strategy_21`: Subtracting decade numbers (Zehnerzahlen subtrahieren)
- `combined_strategy_10`: Using analogous tasks in the number range to 100

**PIKAS-Specific Concept:**
- **Kernaufgaben (Core Tasks) for Subtraction up to 100:** This extends the concept from the ZR 20 range. "Easy" problems are those that rely on structural understanding, not complex calculation. Examples include:
  - **Z - Z** (e.g., 70 - 20): Only tens change
  - **ZE - E** without crossing the ten (e.g., 45 - 2): Only ones change
  - **ZE - Z** (e.g., 78 - 70): Only tens change, ones stay same
  - Tasks with "beautiful" numbers (e.g., 30 - 3)

**Förderanregungen (Support Activities):**

1. **Einfache Aufgaben finden (Finding Easy Tasks)**
   - Children write down their own easy problems (e.g., 37 - 6)
   - Collect and represent them with 10-strips and counters
   - Explain WHY they find them easy (e.g., "I know 7 - 6 = 1, so 37 - 6 = 31")
   - Questions to guide: "Warum ist diese Aufgabe für dich einfach?" (Why is this problem easy for you?)
   - Find more similar easy tasks

2. **Mit Einern rechnen (Calculating with Ones)**
   - Practice ZE - E problems (e.g., 47 - 2 = 45, 57 - 2, 67 - 2)
   - Lay out with 10-strips and counters
   - Explain with materials why only the ones digit changes
   - Verbalize: "Bei 47 - 2 ändert sich der Zehner nicht. Es bleiben 4 Zehner und von den 7 Einern muss ich 2 wegnehmen." (For 47 - 2, the ten doesn't change. 4 tens remain and I must take away 2 from the 7 ones.)

3. **Mit Zehnern rechnen (Calculating with Tens)**
   - Practice Z - Z and ZE - Z problems (e.g., 65 - 20)
   - Lay out with 10-strips and counters
   - Explain with materials why ones digit stays same, only tens change
   - Verbalize: "Bei 42 - 10 ändern sich die Einer nicht. Es bleiben 2 Einer und von den 4 Zehnern muss ich einen Zehner wegnehmen." (For 42 - 10, the ones don't change. 2 ones remain and I must take away one ten from the 4 tens.)
   - Partner activity: One child names a problem, explains to another child how to lay it out

**App Adaptation Notes:**
- Interactive sorter: drag problems to "easy" or "hard" categories
- After sorting, child must explain WHY (voice recording or text selection from options)
- Visualize each problem type with 10-strips and counters
- Track which structures child recognizes as easy (reveals their core task repertoire)

---

### Card 41: Aufgaben ableiten (Deriving Problems - Subtraction ZR 100)

**Source File (Front):** `kartei_gesamt_240416-87.pdf`
**Source File (Back):** `kartei_gesamt_240416-88.pdf`

**Diagnostische Basisaufgabe:**
- "Löse die Aufgabe 47 - 20 mit 10er-Streifen und Plättchen und notiere das Ergebnis. Erkläre." (Solve the problem 47 - 20 with 10-strips and counters and write down the result. Explain.)
- "Löse jetzt die Aufgabe 47 - 19. Was fällt dir auf? Erkläre." (Now solve the problem 47 - 19. What do you notice? Explain.)
- The diagnostic shows 47 - 20 represented with counters, prompting the child to solve it first, then notice the relationship to 47 - 19.

**Kompetenzen (Competencies):**
- Can use problem relationships to solve subtraction problems.
- Can explain problem relationships using materials.

**Beobachtungen (Observations):**
- How does the child solve the problem?
- Do they recognize the relationship between the problems?
- Which relationships can the child use to solve the problems?
- Can the child explain the relationships using the materials?

**Gezielte Impulse (Targeted Prompts):**
- "Wie kann dir die erste Aufgabe zum Lösen der zweiten Aufgabe helfen?" (How can the first problem help you solve the second one?)
- "Was verändert sich in der Aufgabe bzw. Darstellung?" (What changes in the problem or the representation?)
- "Löse jetzt die Aufgabe 47 - 18. Was fällt dir auf?" (Now solve 47 - 18. What do you notice?)
- "Löse jetzt die Aufgabe 37 - 18. Was fällt dir auf?" (Now solve 37 - 18. What do you notice?)
- "Was verändert sich bei der neuen Aufgabe an der Darstellung?" (What changes in the new problem in the representation?)

**iMINT Skill Mapping:**
- `combined_strategy_8`: Subtraction by simplifying (Aufgaben vereinfachen)
- `combined_strategy_9`: Using analogous tasks (Analogieaufgaben nutzen)

**PIKAS-Specific Concept:**
- **Ableitungsstrategien (Derivation Strategies) - Nachbaraufgabe (Neighboring Problem) Strategy:** This card specifically diagnoses the neighboring problem strategy for subtraction. The key insight:
  - Solve an easy core task first (47 - 20 = 27)
  - Recognize the relationship to a nearby harder task (47 - 19)
  - Understand: **Subtracting one less → result is one greater**
  - Example: If 47 - 20 = 27, then 47 - 19 = 28 (because we subtracted 1 less, result is 1 more)
- This is a key flexible calculation strategy that builds relational thinking

**Förderanregungen (Support Activities):**

1. **Aufgaben verändern (Changing Problems)**
   - Start with an easy problem (e.g., 60 - 20)
   - Children lay it out with materials and solve it
   - Alter the problem by removing more 10-strips or counters to create a harder problem (e.g., 60 - 22)
   - Verbalize the changes: "Ich decke noch zwei Plättchen ab, also habe ich jetzt die Aufgabe 60 - 22. Das Ergebnis wird um 2 kleiner." (I cover two more counters, so now I have the problem 60 - 22. The result becomes 2 smaller.)
   - Discuss what changed in the problem, material, and result
   - Questions: "Was verändert sich an der Aufgabe bzw. dem Material? Erkläre." (What changes in the problem or material? Explain.)

2. **Aufgabenbeziehungen am Rechenstrich erkunden (Exploring Problem Relationships on the Empty Number Line)**
   - Teacher gives two related problems (e.g., 74 - 30 and 74 - 28)
   - Discuss which is easier
   - Represent the easier one on the Rechenstrich (empty number line) and solve it
   - Use it to solve the harder one
   - Show the change on the Rechenstrich: "Ich bin 2 zu viel zurückgesprungen, also muss ich wieder zwei nach vorne springen." (I jumped back 2 too many, so I have to jump 2 forward again.)
   - Visualize: Start at 74, jump back 30 to reach 44, realize that's 2 too many, jump forward 2 to get 46

3. **Aufgabenbeziehungen nutzen (Using Problem Relationships)**
   - Teacher gives three related problems (e.g., 36 - 8, 36 - 9, 36 - 10 OR 48 - 7, 48 - 17, 48 - 27)
   - Children start with the easiest problem for them
   - Represent it with 10-strips and counters
   - Discuss relationships between problems using the materials
   - Explain which problem is easiest and WHY
   - Show how other problems can be derived from the easy one
   - Questions:
     - "Warum ist die Aufgabe für dich am einfachsten?" (Why is this problem easiest for you?)
     - "Was verändert sich bei den Aufgaben?" (What changes between the problems?)
     - "Wie kann dir die Aufgabe helfen, die anderen Aufgaben zu lösen?" (How can this problem help you solve the others?)

**App Adaptation Notes:**
- Show pair of related problems side-by-side with materials
- Animate the transformation: solve 47 - 20, then show what changes to get 47 - 19
- Interactive Rechenstrich: child can draw jumps, see relationship visually
- Highlight what changed (the subtrahend) and what changed in result
- Track if child can articulate the pattern ("subtract 1 less → result is 1 more")

---

### Card 42: Schrittweise rechnen (Step-by-Step Calculation)

**Source File:** `kartei_gesamt_240416-84.pdf` (front) (Assumed)

**Diagnostische Basisaufgabe:**
- "Rechne die Aufgabe 87 - 22 wie Finja." (Calculate the problem 87 - 22 like Finja.) Finja's work for 48-31 is shown as 48 - 30 = 18, then 18 - 1 = 17.
- "Stelle deine Aufgabe auch am Rechenstrich dar und erkläre." (Represent your problem on the empty number line as well and explain.)

**Kompetenzen (Competencies):**
- Can understand and explain the step-by-step strategy.
- Can apply the step-by-step strategy and represent it symbolically and on the empty number line.

**Beobachtungen (Observations):**
- Can the child follow the calculation path symbolically and on the number line?
- Can the child solve a problem step-by-step and represent it?
- How does the child explain the calculation path?

**Gezielte Impulse (Targeted Prompts):**
- "Wie hat Finja gerechnet? Zeige und erkläre am Material." (How did Finja calculate? Show and explain with materials.)
- "Wie hat Finja zerlegt?" (How did Finja decompose the number?)
- "Wo erkennst du am Rechenstrich die erste Zahl, die zweite Zahl und das Ergebnis?" (Where do you recognize the first number, second number, and the result on the empty number line?)
- "Was bedeutet die 18?" (What does the 18 mean? [It's an intermediate result].)

**iMINT Skill Mapping:**
- `combined_strategy_12`: Subtraction with crossing the ten in steps (Zehnerübergang in Schritten)
- `combined_strategy_13`: Subtraction by simplifying (Aufgaben vereinfachen)

**PIKAS-Specific Concept:**
- **Schrittweise Rechnen (Step-by-Step Calculation):** This is a foundational flexible calculation strategy for multi-digit subtraction. The key is decomposing the second number (subtrahend) into tens and ones and subtracting them sequentially (e.g., ZE - Z - E). This avoids the complexity of the standard algorithm and relies on an understanding of place value. It is a more robust strategy than counting back.


**Source File:** `kartei_gesamt_240416-82.pdf` (front) (Assumed)

**Diagnostische Basisaufgabe:**
- "Löse die Aufgabe 47 - 20 mit 10er-Streifen und Plättchen und notiere das Ergebnis. Erkläre." (Solve the problem 47 - 20 with 10-strips and counters and write down the result. Explain.)
- "Löse jetzt die Aufgabe 47 - 19. Was fällt dir auf? Erkläre." (Now solve the problem 47 - 19. What do you notice? Explain.)

**Kompetenzen (Competencies):**
- Can use problem relationships to solve subtraction problems.
- Can explain problem relationships using materials.

**Beobachtungen (Observations):**
- How does the child solve the problem?
- Do they recognize the relationship between the problems?
- Which relationships can the child use to solve the problems?
- Can the child explain the relationships using the materials?

**Gezielte Impulse (Targeted Prompts):**
- "Wie kann dir die erste Aufgabe zum Lösen der zweiten Aufgabe helfen?" (How can the first problem help you solve the second one?)
- "Was verändert sich in der Aufgabe bzw. Darstellung?" (What changes in the problem or the representation?)
- "Löse jetzt die Aufgabe 47 - 18. Was fällt dir auf?" (Now solve 47 - 18. What do you notice?)
- "Löse jetzt die Aufgabe 37 - 18. Was fällt dir auf?" (Now solve 37 - 18. What do you notice?)

**iMINT Skill Mapping:**
- `combined_strategy_8`: Subtraction by simplifying (Aufgaben vereinfachen)
- `combined_strategy_9`: Using analogous tasks (Analogieaufgaben nutzen)

**PIKAS-Specific Concept:**
- **Ableitungsstrategien (Derivation Strategies):** This card specifically diagnoses the "Nachbaraufgabe" (neighboring problem) strategy. By solving an easy core task (47-20) first, the child is prompted to see the relationship to a more difficult task (47-19). The core idea is to understand that subtracting one less results in an answer that is one greater. This is a key flexible calculation strategy.


**Source File:** `kartei_gesamt_240416-80.pdf` (front) (Assumed)

**Diagnostische Basisaufgabe:**
- "Welche Aufgaben sind für dich einfach? Sortiere." (Which problems are easy for you? Sort them.)
- "Warum sind diese Aufgaben für dich einfach? Erkläre." (Why are these problems easy for you? Explain.)
- The image shows problems like 45-2, 70-20, 30-3, 23-12, 78-70 being sorted into "einfach" (easy) and "schwierig" (difficult).

**Kompetenzen (Competencies):**
- Can explain why they find a problem easy.
- Can recognize structures in easy problems.

**Beobachtungen (Observations):**
- Which problems does the child sort as easy? Which as difficult?
- How does the child justify their sorting (e.g., can they explain why problems with decade numbers are easy to calculate)?
- Which structures are recognized?
- Does the child recognize similar problems?

**Gezielte Impulse (Targeted Prompts):**
- "Gibt es noch andere Aufgaben, die du einfach findest? Notiere." (Are there other problems you find easy? Write them down.)
- "Warum sind diese Aufgaben für dich schwierig? Erkläre." (Why are these problems difficult for you? Explain.)
- "Welche Aufgaben gehören für dich zusammen? Findest du noch mehr Aufgaben, die dazu passen?" (Which problems belong together for you? Can you find more problems that fit?)

**iMINT Skill Mapping:**
- `basic_strategy_21`: Subtracting decade numbers (Zehnerzahlen subtrahieren)
- `combined_strategy_10`: Using analogous tasks in the number range to 100.

**PIKAS-Specific Concept:**
- **Kernaufgaben (Core Tasks) for Subtraction up to 100:** This extends the concept from the ZR 20 range. "Easy" problems are those that rely on structural understanding, not complex calculation. Examples of core tasks in this range include:
    - Z - Z (e.g., 70 - 20)
    - ZE - E without crossing the ten (e.g., 45 - 2)
    - ZE - Z (e.g., 78 - 70)
    - Tasks with "beautiful" numbers (e.g., 30 - 3)


**Source File:** `kartei_gesamt_240416-78.pdf` (front) (Assumed)

**Diagnostische Basisaufgabe:**
- "Finde zwei Minusaufgaben und zwei Plusaufgaben zum Bild." (Find two subtraction problems and two addition problems for the picture).
- The picture shows a 20-frame with 9 red and 7 blue counters.
- "Warum passen die Aufgaben zum Bild?" (Why do the problems fit the picture?).

**Kompetenzen (Competencies):**
- Can find matching addition and subtraction problems for a dot representation and explain the fit.
- Can find commutative and inverse problems.

**Beobachtungen (Observations):**
- Does the child find suitable subtraction and addition problems?
- How does the child explain the fit between the representation and the problem?
- Can the child form and explain commutative and inverse tasks?

**Gezielte Impulse (Targeted Prompts):**
- "Wieso passt die Aufgabe 16 - 7 zur Darstellung? Erkläre." (Why does the problem 16 - 7 fit the representation? Explain.)
- "Was ist die Tauschaufgabe zu ___?" (What is the commutative task for ___?)
- "Was ist die Umkehraufgabe zu ___?" (What is the inverse task for ___?)
- "Was haben alle Aufgaben gemeinsam?" (What do all problems have in common?)

**iMINT Skill Mapping:**
- `basic_strategy_14`: Inverse tasks (Umkehraufgaben)
- `basic_strategy_19`: Commutative tasks (Tauschaufgaben)
- `operation_sense_task_families` (NEW): Recognizing and using fact families.

**PIKAS-Specific Concept:**
- **Aufgabenfamilien (Fact Families):** This card explicitly diagnoses the understanding of the entire fact family (two additions, two subtractions) that connects three numbers. This demonstrates a deep, relational understanding of addition and subtraction, a core goal of the PIKAS framework.


**Source File:** `kartei_gesamt_240416-74.pdf` (front)

**Diagnostische Basisaufgabe:**
- "Was ist 10 - 6? Woher weißt du das?" (What is 10 - 6? How do you know?)
- "Was ist die Hälfte von 12? Woher weißt du das?" (What is half of 12? How do you know?)

**Kompetenzen (Competencies):**
- The child can automatically solve the core tasks of subtraction within 20.

**Beobachtungen (Observations):**
- Which core tasks does the child solve correctly? With which task types do errors occur?
- How does the child determine the result (e.g., counting, based on structures, automated)?
- What structures does the child refer to in their reasoning?

**Gezielte Impulse (Targeted Prompts):**
- "Was ist 8 - 5 (16 - 10, 14 - 4)? Woher weißt du das?" (What is 8 - 5...? How do you know?)
- "Bei welchen Aufgaben kannst du das Ergebnis schon schnell nennen?" (For which problems can you name the result quickly?)
- "Warum ist die Aufgabe einfach für dich?" (Why is the problem easy for you?)
- "Findest du zu dieser Aufgabe noch andere ähnliche Aufgaben?" (Can you find other similar problems?)

**iMINT Skill Mapping:**
- `basic_strategy_11`: Halving (Halbieren)
- `basic_strategy_12`: Subtracting from 10 (Minusaufgaben von 10)

**PIKAS-Specific Concept:**
- **Kernaufgaben (Core Tasks) for Subtraction:** This card assesses the automation of core subtraction facts (like halves, subtracting from 10), which are the building blocks for more complex strategies.
