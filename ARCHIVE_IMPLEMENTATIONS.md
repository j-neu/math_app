# Exercise Implementations Archive

**⚠️ HISTORICAL DOCUMENT:** This file contains implementation notes for early exercise versions. Some exercises have been superseded:
- **C1.1** has been replaced by C1.1 V2 (4-level implementation) - see [COMPLETED_TASKS.md](COMPLETED_TASKS.md) for current version

For current work, see [tasks.md](tasks.md).

---

## Z1: Decompose 10

**Date Completed:** 2025-10-29
**Skills:** `decomposition_1`, `decomposition_3`
**Source:** PIKAS Card 9 (Zahlen zerlegen), iMINT Yellow Cards

### Files Created
- `models/scaffold_level.dart` - 3-level progression framework
- `widgets/decompose10_level1_widget.dart` - Guided exploration (tap-to-flip)
- `widgets/decompose10_level2_widget.dart` - Supported practice (visual + write)
- `widgets/decompose10_level3_widget.dart` - Independent mastery (hidden visual)
- `exercises/decompose_10_exercise.dart` - Main coordinator

### Key Features
- **Level 1:** Tap counters to flip blue/red, equation auto-displays "10 = 4 blue + 6 red"
- **Level 2:** Random decomposition shown, child writes equation, 10 correct to unlock L3
- **Level 3:** Visual hidden, child finds all 11 decompositions from memory, counters appear only on errors
- **Order-dependent:** Tracks all 11 ordered pairs (0+10, 1+9, ..., 10+0) to reveal "gegensinniges Verändern"
- **Progression:** L1 always available → L2 unlocks after exploration → L3 unlocks after 10 correct in L2

### Translation from Physical Activity
**iMINT Card 3, Activity A:** Partner places pen between fingers → Digital: Tap counters to create groups
**iMINT Card 3, Activity B:** Hands covered with cloth, imagine decomposition → Digital: Level 3 hides counters

### Bug Fixed
Original implementation counted 3+7 and 7+3 as duplicates, making 11/11 completion impossible. Fixed by storing as ordered pairs without normalization.

---

## C1.1: Count the Dots

**Date Completed:** 2025-10-30
**Skills:** `counting_1`
**Source:** iMINT Green Card 1 (Plättchen zählen)

### Files Created
- `widgets/countdots_level1_widget.dart` - Tap to count (one-to-one correspondence)
- `widgets/countdots_level2_widget.dart` - See and write (structured arrangements)
- `widgets/countdots_level3_widget.dart` - Flash and count from memory
- `exercises/count_dots_exercise.dart` - Main coordinator

### Key Features
- **Level 1:** Random dot arrangement, child taps each dot, counter displays "Counted: 4", 3 problems to unlock L2
- **Level 2:** Structured arrangements (grid, rows, 5-frames), child sees and writes total, 10 correct to unlock L3
- **Level 3:** Dots flash for 2 seconds then hide, child counts from memory, adaptive difficulty 5→20
- **Adaptive Difficulty:** Starts at 5 dots, increases by 2 after 3 consecutive correct, max 20 dots
- **No-Fail Support:** "Peek" button available, dots appear briefly on errors

### Innovations
- **Flash-and-hide mechanic:** Novel digital interpretation of "Wie kommt die Handlung in den Kopf?"
- **Structured vs random:** L1 random (natural objects), L2-3 structured (pattern recognition)
- **Adaptive challenge:** Maintains optimal difficulty (Zone of Proximal Development)

### Pedagogical Purpose
- One-to-one correspondence: Each object gets exactly one number
- Prevents: Skipping or double-counting
- Prepares for: Subitizing and quick recognition skills

---

## C1.2: Count the Objects

**Date Completed:** 2025-10-30
**Skills:** `counting_1`
**Source:** iMINT Green Card 1 (variation with diverse objects)

### Files Created
- `widgets/countobjects_level1_widget.dart` - Tap various shapes
- `widgets/countobjects_level2_widget.dart` - Count emoji objects
- `widgets/countobjects_level3_widget.dart` - Flash and count various objects
- `exercises/count_objects_exercise.dart` - Main coordinator

### Key Features
- **Level 1:** Geometric shapes (stars ⭐, hearts ❤️, circles 🔵, squares 🟩, triangles 🔺, diamonds 💎) with custom painters
- **Level 2:** Emoji objects (🍎 🎃 ⚽ 🌸 🚗 🦋 🍃 🐟) in structured layouts
- **Level 3:** Flash objects, count from memory, adaptive 5→20
- **Custom Painters:** StarPainter (5-pointed star), HeartPainter (Bézier curves), TrianglePainter, DiamondPainter
- **Singular/Plural:** "I count 5 apples" vs "I count 1 apple"

### Difference from C1.1
- **C1.1:** Uniform dots → Focus on counting mechanics
- **C1.2:** Diverse objects → Focus on counting abstraction
- **Learning:** Counting works the SAME way for ANY objects (stars, apples, cars)

### Object Type System
- Level 1: Geometric shapes (tap-friendly, custom painters)
- Level 2-3: Emoji objects (diverse, recognizable, language-independent)

---

## C2.1: Order Cards to 20

**Date Completed:** 2025-10-30
**Skills:** `counting_2`
**Source:** iMINT Green Card 2 (Zahlenkarten bis 20 ordnen)

### Files Created
- `widgets/ordercards_level1_widget.dart` - Tap in sequence
- `widgets/ordercards_level2_widget.dart` - Drag to sort
- `widgets/ordercards_level3_widget.dart` - Memory ordering
- `exercises/order_cards_exercise.dart` - Main coordinator

### Key Features
- **Level 1:** Tap cards in ascending order (smallest first), incorrect taps shake, 3 problems to unlock L2
- **Level 2:** ReorderableListView drag-and-drop, validates full sequence, 10 correct to unlock L3
- **Level 3:** Numbers flash for 3 seconds then hide, child writes sequence from memory, adaptive 5→10 numbers
- **Multi-Input Challenge:** Unlike counting (single number), validates entire sequence
- **Progressive Reveal:** L1 shows "sorted" area, cards move there when correct

### Technical Implementation
**ReorderableListView:**
```dart
ReorderableListView(
  onReorder: _onReorder,
  children: _currentSequence.map((number) {
    return _buildDraggableCard(number, key: ValueKey(number));
  }).toList(),
)
```

### Pedagogical Progression
- **L1:** Tap-in-order (guided selection) → "Start with 1, then 2, then 3..."
- **L2:** Drag to arrange (physical sorting simulation) → Full sequence manipulation
- **L3:** Recall from memory (mental ordering) → Internalize number sequence

### Adaptive Difficulty
- Starts at 5 numbers (easy to memorize)
- Increases by 1 after 3 consecutive correct
- Maximum 10 numbers
- Reset streak on error (but doesn't decrease difficulty)

---

## Reusable Patterns Established

### 1. ScaffoldProgress Model
```dart
class ScaffoldProgress {
  final bool level2Unlocked;
  final bool level3Unlocked;
  final int level1ProblemsCompleted;
  final int level2CorrectAnswers;
  final int level2TotalAttempts;

  double get level2Accuracy => ...;
  bool shouldUnlockLevel2() => ...;
  bool shouldUnlockLevel3() => ...;
}
```

### 2. ExerciseConfig Model
Captures pedagogical metadata:
- Source card reference
- Skill tags
- Concept description
- Observation points
- Hints and feedback messages

### 3. No-Fail Feedback System
- Visual safety net (hidden visual appears on errors)
- Constructive hints ("Try a smaller number" not "Wrong!")
- "Peek" button for self-paced support
- Positive reinforcement on success

### 4. Level Coordinator Pattern
```dart
class YourExercise extends StatefulWidget {
  final ExerciseConfig config;

  @override
  State<YourExercise> createState() => _YourExerciseState();
}

class _YourExerciseState extends State<YourExercise> {
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration;
  final ScaffoldProgress _progress = ScaffoldProgress();

  Widget _buildCurrentLevel() {
    switch (_currentLevel) {
      case ScaffoldLevel.guidedExploration:
        return Level1Widget(onProgress: _updateProgress);
      case ScaffoldLevel.supportedPractice:
        return Level2Widget(onProgress: _updateProgress);
      case ScaffoldLevel.independentMastery:
        return Level3Widget(onProgress: _updateProgress);
    }
  }
}
```

---

## Common Implementation Issues & Solutions

### Issue 1: Duplicate Answer Counting
**Problem:** Z1 counted 3+7 and 7+3 as duplicates, making 11/11 impossible
**Solution:** Decide per-exercise if order matters. Document in config. Z1 needs all ordered pairs to reveal pattern.

### Issue 2: Flash Timing
**Problem:** How long should visual flash before hiding?
**Solution:** 2-3 seconds based on testing. Too fast = frustration. Too slow = no challenge.

### Issue 3: When to Unlock Next Level?
**Problem:** Arbitrary criteria feel random to child
**Solution:**
- L1→L2: After exploration (3+ problems) or child requests
- L2→L3: After fluency demonstrated (10 correct = 80%+ accuracy)

### Issue 4: Adaptive Difficulty Step Size
**Problem:** Increasing too fast = frustration, too slow = boredom
**Solution:**
- C1.1/C1.2 (counting): +2 dots after 3 consecutive correct (5→7→9...)
- C2.1 (ordering): +1 number after 3 consecutive correct (5→6→7...)

---

## Widget Library Built

**Level 1 (Guided Exploration) Widgets:**
- Tap-to-flip counters (Z1)
- Tap-to-count dots (C1.1)
- Tap-to-count shapes (C1.2)
- Tap-in-order cards (C2.1)

**Level 2 (Supported Practice) Widgets:**
- Input validation with hints
- Structured visual layouts (grid, rows, 5-frames)
- Drag-and-drop reordering (C2.1)

**Level 3 (Independent Mastery) Widgets:**
- Flash-and-hide mechanic
- Memory recall with input validation
- "Peek" button for self-paced support
- Multi-input sequence validation (C2.1)

**Custom Painters:**
- StarPainter (5-pointed star using trigonometry)
- HeartPainter (Bézier curves)
- TrianglePainter (equilateral)
- DiamondPainter (rhombus)

---

## Testing Notes

**Build Status:** All 4 exercises compile cleanly
- `flutter analyze`: Passes (minor warnings only)
- `flutter build web --release`: Success

**Manual Testing Required:**
- Progression logic (locks/unlocks)
- Visual feedback on errors
- Adaptive difficulty increases
- State persistence when switching levels

**Known Minor Issues:**
- Some unused variable warnings (harmless)
- Deprecated `withOpacity` calls (framework-level, not critical)

---

## Lessons Learned

### What Worked Well
1. **3-Level Framework:** Clear, systematic, pedagogically sound
2. **Reusable patterns:** ScaffoldProgress, ExerciseConfig, Level coordinator
3. **Custom painters:** Clean abstraction for geometric shapes
4. **Flash-and-hide:** Excellent digital interpretation of "in den Kopf"

### Design Decisions to Maintain
1. **Order-dependent tracking:** Document clearly per exercise
2. **Adaptive difficulty:** Maintains optimal challenge (ZPD)
3. **No-fail safety net:** Visual support on errors, never say "wrong"
4. **Progressive unlocking:** Based on demonstrated mastery, not arbitrary time

### Improvements for Future Exercises
1. **State persistence:** Save progress across app restarts
2. **Analytics dashboard:** Show parents which strategies child uses
3. **Hint system:** More context-aware, adaptive to child's specific errors
4. **Audio feedback:** Positive sounds on correct answers

---

**Archive Created:** 2025-10-30
**Covers:** Phase 2 exercises Z1, C1.1, C1.2, C2.1
