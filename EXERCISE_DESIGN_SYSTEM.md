# Exercise Design System

**Version:** 1.1
**Last Updated:** 2025-11-23
**Purpose:** Visual design specification for minimalistic, distraction-free skill UI

## Terminology Note

This document uses the term "exercise" in some places for historical reasons, but the correct terminology is:
- **Skill** = Complete learning module (e.g., C1.1, Z1) with multiple levels
- **Level** = Scaffolding stage within a skill (e.g., Level 1, Level 2)
- **Problem** = Individual question within a level

When you see "exercise" below, it typically refers to a **skill** (the complete multi-level module).
See [CLAUDE.md](CLAUDE.md) Terminology section for full clarification.

---

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Visual Hierarchy](#visual-hierarchy)
3. [AppBar Components](#appbar-components)
4. [Segmented Progress Bar](#segmented-progress-bar)
5. [Collapsible Instructions](#collapsible-instructions)
6. [Level Selection Menu](#level-selection-menu)
7. [Auto-Level Progression](#auto-level-progression)
8. [Removed Elements](#removed-elements)
9. [Animation Specifications](#animation-specifications)
10. [Color System](#color-system)
11. [Typography](#typography)
12. [Spacing & Layout](#spacing--layout)
13. [Implementation Guide](#implementation-guide)
14. [Migration Checklist](#migration-checklist)

---

## Design Philosophy

### Core Principles

**Minimalism** - Every element must serve a clear purpose. Remove visual noise to reduce cognitive load.

**Focus-Driven** - Child's attention should be on the exercise itself, not navigation or statistics.

**ADHD-Friendly** - Follows established ADHD design principles from [adhd guidelines.md](adhd%20guidelines.md):
- Low cognitive load (minimal UI elements)
- Immediate feedback (instant visual response)
- No anxiety triggers (no "wrong" counters, no red X marks)
- Clear progress (visual, not numerical)

**Consistent** - All exercises share the same visual language and interaction patterns.

### Design Goals

1. **Eliminate Distractions** - Hide level selectors, progress counters, and instructional text by default
2. **Provide Context When Needed** - Make instructions and level navigation available but not prominent
3. **Celebrate Progress Subtly** - Animate achievements without overwhelming the child
4. **Maintain Flow** - Auto-advance through levels to keep momentum

---

## Visual Hierarchy

### 3-Layer Structure

```
┌─────────────────────────────────────────────────┐
│  AppBar: [Back] Skill Title [≡] [?]            │ Layer 1: Navigation
├─────────────────────────────────────────────────┤
│  ■ ■ ■ ■ ■ ■ ■ ■ ■ ■  (Segmented Progress)    │ Layer 2: Progress
├─────────────────────────────────────────────────┤
│                                                 │
│                                                 │
│           Level Content Area                    │ Layer 3: Content
│         (Manipulatives, Problems)               │
│                                                 │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Layer 1: AppBar** - Fixed height (56px), always visible, provides navigation and help
**Layer 2: Progress Bar** - Minimal height (~8px segments), expands temporarily during animations
**Layer 3: Level Content** - Fills remaining space, focus area for child (shows current level's problems)

---

## AppBar Components

### Standard AppBar Configuration

```dart
AppBar(
  leading: BackButton(),                    // Automatic, returns to Learning Path
  title: Text(skill.title),                 // e.g., "Count the Dots" (skill title)
  actions: [
    IconButton(                             // Hamburger menu (level selection)
      icon: Icon(Icons.menu),
      onPressed: () => _showLevelSelector(context),
    ),
    IconButton(                             // Help button (instructions)
      icon: Icon(Icons.help_outline),
      onPressed: () => _showInstructions(context),
    ),
  ],
)
```

### Component Specifications

#### Back Button (Leading)
- **Icon:** `Icons.arrow_back` (automatic via `BackButton()`)
- **Action:** Returns to Learning Path screen
- **Behavior:** Should trigger progress save before exit (via `WillPopScope`)

#### Skill Title (Center)
- **Text:** Short, descriptive skill name (e.g., "Count the Dots", "Decompose 10")
- **Typography:** Default AppBar title style (20px, medium weight)
- **Truncation:** Should ellipsize if too long

#### Hamburger Menu (Action 1)
- **Icon:** `Icons.menu` (3 horizontal lines)
- **Placement:** First action (right side, before help button)
- **Action:** Opens level selection drawer/modal
- **Tooltip:** "Choose Level"

#### Help Button (Action 2)
- **Icon:** `Icons.help_outline` (question mark in circle)
- **Placement:** Second action (rightmost)
- **Action:** Shows instruction overlay/modal
- **Tooltip:** "Instructions"

---

## Segmented Progress Bar

### Visual Design

The progress bar is a **segmented horizontal line** that transforms into squares during completion animations.

#### Default State (Segments)

```
┌─────────────────────────────────────────┐
│ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■                    │  Grey segments (8px tall)
└─────────────────────────────────────────┘
```

**Specifications:**
- **Count:** Equal to total problems in current level (typically 10)
- **Width:** Screen width divided by segment count, with 4px gaps
- **Height:** 8px (line segments)
- **Color:** `Colors.grey.shade300`
- **Gap:** 4px between segments
- **Border Radius:** 2px (slightly rounded)

#### Animated State (Square Expansion)

When a problem is answered:

```
Step 1: Segment expands downward (200ms)
┌─┐
│█│ ← Expands to 32px tall square
└─┘

Step 2: Color changes + Pop animation (150ms)
┌─┐
│█│ ← Green (correct) or Gold (incorrect)
└─┘  ← Scale: 1.0 → 1.2 → 1.0

Step 3: Contracts back to segment (200ms)
■  ← Back to 8px tall, retains color
```

**Specifications:**
- **Expanded Height:** 32px (4x segment height)
- **Animation Duration:**
  - Expand: 200ms (`Curves.easeOut`)
  - Pop: 150ms (`Curves.elasticOut`)
  - Contract: 200ms (`Curves.easeIn`)
- **Colors:**
  - Correct: `Colors.green` (or `Theme.of(context).primaryColor` if green)
  - Incorrect: `Colors.amber` (gold tone)

#### Sequential Filling

Progress fills **left to right**, one segment at a time:

```
Problem 1 done:  █ ■ ■ ■ ■ ■ ■ ■ ■ ■
Problem 2 done:  █ █ ■ ■ ■ ■ ■ ■ ■ ■
Problem 3 done:  █ █ █ ■ ■ ■ ■ ■ ■ ■
...
All done:        █ █ █ █ █ █ █ █ █ █
```

**Color Mix Example:**
```
█ █ ◆ █ ■ ■ ■ ■ ■ ■
│ │ │ └─ Problem 4: Correct (green)
│ │ └─── Problem 3: Incorrect (gold)
│ └───── Problem 2: Correct (green)
└─────── Problem 1: Correct (green)
```

### Incorrect Answer Animation

When a problem is answered incorrectly, the gold square should have a **gentle shake** to provide feedback without alarm:

```dart
Animation sequence:
1. Expand to square (200ms)
2. Change to gold + gentle shake (100ms)
   - Translate X: 0 → -4 → 4 → -2 → 2 → 0
   - Subtle horizontal oscillation
3. Pop animation (150ms, scale 1.0 → 1.15 → 1.0)
4. Contract to segment (200ms)
```

**Purpose:** Provides immediate feedback without creating anxiety (no harsh "X" or red color)

---

## Collapsible Instructions

### Design Rationale

Instructions are **hidden by default** to minimize cognitive load. Children who understand the task can work without distraction. Those who need help can access instructions via the help button.

### Trigger

**Help Button** in AppBar (? icon, top right) opens instruction overlay.

### Instruction Overlay

#### Modal Style (Recommended)

```
┌─────────────────────────────────────────┐
│  AppBar                           [×]   │
├─────────────────────────────────────────┤
│                                         │
│   ╔═══════════════════════════════╗    │
│   ║  Level 2: Write the Equation  ║    │
│   ║  ─────────────────────────     ║    │
│   ║                                ║    │
│   ║  Look at the counters.         ║    │
│   ║  How many blue? How many red?  ║    │
│   ║                                ║    │
│   ║  Write the equation below.     ║    │
│   ║                                ║    │
│   ║      [Got It!] button          ║    │
│   ╚═══════════════════════════════╝    │
│                                         │
└─────────────────────────────────────────┘
```

**Specifications:**
- **Type:** `showDialog()` with semi-transparent backdrop
- **Background:** White card with elevation (shadow)
- **Padding:** 24px
- **Border Radius:** 16px
- **Max Width:** 400px (centered)
- **Dismiss:** Tap outside, close button, or "Got It!" button

#### Content Structure

```dart
Dialog(
  child: Container(
    padding: EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.help_outline, size: 32, color: levelColor),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Level ${currentLevel.levelNumber}: ${levelTitle}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),

        Divider(),

        // Instructions
        Text(
          instructionText,
          style: TextStyle(fontSize: 16, height: 1.5),
        ),

        SizedBox(height: 24),

        // Dismiss button
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Got It!'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
        ),
      ],
    ),
  ),
)
```

### Instruction Content Guidelines

**Good instructions:**
- Short (1-3 sentences)
- Action-oriented ("Drag the dots", "Tap each object")
- Positive tone ("Let's practice counting!")
- Clear goal ("Find how many dots there are")

**Avoid:**
- Long paragraphs
- Abstract concepts
- Negative language ("Don't forget to...")
- Mathematical jargon for young children

---

## Level Selection Menu

### Design Rationale

Level navigation is **hidden during exercise** to maintain focus, but accessible via hamburger menu for children who want to revisit previous levels or preview upcoming ones.

### Trigger

**Hamburger Icon** in AppBar (≡, top right before help button) opens level selection drawer.

### Level Drawer/Modal

#### Navigation Drawer Style (Recommended)

```
┌─────────┬───────────────────────────────┐
│         │  AppBar                 [×]   │
│ ╔═════╗ ├───────────────────────────────┤
│ ║ L1  ║ │                               │
│ ║ ✓   ║ │  Exercise content continues   │
│ ╚═════╝ │  behind drawer (dimmed)       │
│         │                               │
│ ╔═════╗ │                               │
│ ║ L2  ║ │                               │
│ ║ ✓   ║ │                               │
│ ╚═════╝ │                               │
│         │                               │
│ ╔═════╗ │                               │
│ ║ L3  ║ ← Current level (highlighted)  │
│ ║ →   ║ │                               │
│ ╚═════╝ │                               │
│         │                               │
│ ┌─────┐ │                               │
│ │ L4  │ ← Locked (grey, with lock icon)│
│ │ 🔒  │ │                               │
│ └─────┘ │                               │
│         │                               │
└─────────┴───────────────────────────────┘
```

**Specifications:**
- **Type:** `Drawer` widget (slides in from left or right)
- **Width:** 240px
- **Background:** White or light grey (`Colors.grey.shade50`)
- **Dismiss:** Tap outside drawer, back button, or select level

#### Level Item Design

**Unlocked Level (Previously Completed):**
```dart
Container(
  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey.shade300, width: 1),
  ),
  child: Row(
    children: [
      Icon(Icons.check_circle, color: Colors.green, size: 24),
      SizedBox(width: 12),
      Text('Level ${level.levelNumber}', style: TextStyle(fontSize: 16)),
      Spacer(),
      Icon(Icons.chevron_right, color: Colors.grey),
    ],
  ),
)
```

**Current Level (Active):**
```dart
Container(
  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Theme.of(context).primaryColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: Theme.of(context).primaryColor,
      width: 2,
    ),
  ),
  child: Row(
    children: [
      Icon(Icons.play_arrow, color: Theme.of(context).primaryColor, size: 24),
      SizedBox(width: 12),
      Text(
        'Level ${level.levelNumber}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    ],
  ),
)
```

**Locked Level:**
```dart
Container(
  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.grey.shade200,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey.shade400, width: 1),
  ),
  child: Row(
    children: [
      Icon(Icons.lock, color: Colors.grey.shade600, size: 24),
      SizedBox(width: 12),
      Text(
        'Level ${level.levelNumber}',
        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
      ),
    ],
  ),
)
```

### Level Selection Behavior

**Selecting Unlocked Level:**
- Close drawer
- Animate transition to selected level (fade/slide transition, 300ms)
- Reset level state (new problem set)
- Update progress bar to reflect new level's problem count

**Selecting Locked Level:**
- Show brief tooltip: "Complete Level X to unlock!"
- Shake animation on locked level item (100ms)
- Drawer remains open

**Selecting Current Level:**
- Close drawer (no action, already on that level)

---

## Auto-Level Progression

### Progression Rules

When a child completes the required number of problems in a level (typically 10 correct answers):

1. **Check if next level is unlocked**
   - If unlocked: Auto-advance
   - If locked: Show completion celebration, stay on current level

2. **Auto-Advance Behavior**
   - Brief celebration animation (1 second)
   - Automatic transition to next level (fade transition, 500ms)
   - New level instructions auto-appear (dismissible)

### Completion Celebration

When all problems in a level are complete:

```
┌─────────────────────────────────────────┐
│  AppBar                                 │
├─────────────────────────────────────────┤
│ █ █ █ █ █ █ █ █ █ █  (All green/gold)  │
├─────────────────────────────────────────┤
│                                         │
│         ┌─────────────────┐            │
│         │   Level 2       │            │
│         │   Complete! 🎉  │            │
│         │                 │            │
│         │  Moving to      │            │
│         │  Level 3...     │            │
│         └─────────────────┘            │
│                                         │
└─────────────────────────────────────────┘
```

**Animation:**
- All segments flash/pulse (300ms)
- Celebration modal appears (1 second)
- Fade to next level (500ms)

**Code Example:**
```dart
void _onLevelComplete() async {
  // Pulse all segments
  setState(() { _allSegmentsPulse = true; });
  await Future.delayed(Duration(milliseconds: 300));

  // Show celebration
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => CompletionCelebrationDialog(
      levelNumber: currentLevel.levelNumber,
      nextLevelUnlocked: isNextLevelUnlocked,
    ),
  );

  // Auto-advance if next level unlocked
  if (isNextLevelUnlocked) {
    await Future.delayed(Duration(milliseconds: 500));
    _advanceToNextLevel();
  }
}
```

### Manual Level Return

Children can return to previous levels via hamburger menu at any time. This allows:
- Reviewing easier content for confidence building
- Practicing mastered skills
- Exploring different representations (if multiple levels teach same concept)

---

## Removed Elements

### What's Being Removed

The following UI elements are **no longer visible** in the new design:

#### 1. Level Selector Buttons/Tabs

**Old Design:**
```
┌─────────────────────────────────────────┐
│ [L1 Explore] [L2 Practice] [L3 Master] │ ← REMOVED
├─────────────────────────────────────────┤
```

**Reason:** Distracting, clutters interface. Moved to hamburger menu.

#### 2. Progress Text

**Old Design:**
```
Correct: 5/10 to unlock Level 3
[████████░░] 50%
```

**Reason:** Numerical counters create anxiety for children with ADHD. Visual segments are sufficient.

#### 3. Problem Counters

**Old Design:**
```
Problems solved: 5
Correct answers: 4
```

**Reason:** Focuses on counting errors rather than learning. Segmented bar provides equivalent info visually.

#### 4. Instruction Containers

**Old Design:**
```
┌─────────────────────────────────────────┐
│ Level 2: Write the Equation            │ ← REMOVED
│ Look at the counters. How many blue?   │    (Always visible)
│ How many red? Write the equation below.│
└─────────────────────────────────────────┘
```

**Reason:** Takes up valuable screen space. Children who understand don't need it. Moved to collapsible help button.

#### 5. Visible Lock Icons on Level Buttons

**Old Design:**
```
[L1 ✓] [L2 ✓] [L3 →] [L4 🔒] [L5 🔒]
```

**Reason:** Level tabs are removed entirely. Lock status only visible in hamburger menu.

---

## Animation Specifications

### Segmented Progress Bar Animations

#### 1. Segment to Square Expansion (Correct Answer)

**Duration:** 200ms
**Curve:** `Curves.easeOut`
**Properties:**
- Height: 8px → 32px
- BorderRadius: 2px → 8px (optional, for smoother look)

```dart
AnimatedContainer(
  duration: Duration(milliseconds: 200),
  curve: Curves.easeOut,
  height: isExpanded ? 32 : 8,
  width: segmentWidth,
  decoration: BoxDecoration(
    color: segmentColor,
    borderRadius: BorderRadius.circular(isExpanded ? 8 : 2),
  ),
)
```

#### 2. Pop Animation

**Duration:** 150ms
**Curve:** `Curves.elasticOut`
**Properties:**
- Scale: 1.0 → 1.2 → 1.0

```dart
ScaleTransition(
  scale: Tween<double>(begin: 1.0, end: 1.2).animate(
    CurvedAnimation(
      parent: _popController,
      curve: Curves.elasticOut,
    ),
  ),
  child: ExpandedSquare(),
)
```

#### 3. Square to Segment Contraction

**Duration:** 200ms
**Curve:** `Curves.easeIn`
**Properties:**
- Height: 32px → 8px
- Retains color (green or gold)

#### 4. Gentle Shake (Incorrect Answer)

**Duration:** 100ms
**Curve:** `Curves.easeInOut`
**Properties:**
- TranslateX: 0 → -4 → 4 → -2 → 2 → 0

```dart
AnimatedBuilder(
  animation: _shakeController,
  builder: (context, child) {
    return Transform.translate(
      offset: Offset(_shakeAnimation.value, 0),
      child: child,
    );
  },
  child: ExpandedSquare(),
)

// Animation values
_shakeAnimation = TweenSequence<double>([
  TweenSequenceItem(tween: Tween(begin: 0.0, end: -4.0), weight: 1),
  TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 1),
  TweenSequenceItem(tween: Tween(begin: 4.0, end: -2.0), weight: 1),
  TweenSequenceItem(tween: Tween(begin: -2.0, end: 2.0), weight: 1),
  TweenSequenceItem(tween: Tween(begin: 2.0, end: 0.0), weight: 1),
]).animate(_shakeController);
```

#### 5. Complete Sequence (Correct Answer)

```
Total: ~550ms

┌───────────┬───────────┬───────────┬───────────┐
│  Expand   │    Pop    │  Contract │   Idle    │
│  200ms    │   150ms   │   200ms   │           │
│  ▼        │   ↕       │   ▲       │   ─       │
│  8→32px   │ 1.0→1.2→1.0│ 32→8px   │  8px      │
└───────────┴───────────┴───────────┴───────────┘
```

#### 6. Complete Sequence (Incorrect Answer)

```
Total: ~650ms

┌───────────┬───────────┬───────────┬───────────┬───────────┐
│  Expand   │   Shake   │    Pop    │  Contract │   Idle    │
│  200ms    │   100ms   │   150ms   │   200ms   │           │
│  ▼        │   ↔↔↔     │   ↕       │   ▲       │   ─       │
│  8→32px   │ Translate │ 1.0→1.15→1│ 32→8px   │  8px      │
└───────────┴───────────┴───────────┴───────────┴───────────┘
```

### Level Transition Animation

**Duration:** 500ms
**Curve:** `Curves.easeInOut`
**Type:** Fade + Slide

```dart
AnimatedSwitcher(
  duration: Duration(milliseconds: 500),
  transitionBuilder: (child, animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0.1, 0.0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  },
  child: _buildCurrentLevelWidget(),
)
```

### Celebration Animation (Level Complete)

**Duration:** 300ms (pulse) + 1000ms (modal display)
**Type:** Pulse all segments, then show modal

```dart
// Pulse animation
TweenSequence<double>([
  TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
  TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 1),
]).animate(CurvedAnimation(
  parent: _pulseController,
  curve: Curves.easeInOut,
))
```

---

## Color System

### Progress Bar Colors

| State | Color | Code | Usage |
|-------|-------|------|-------|
| Incomplete | Light Grey | `Colors.grey.shade300` | Default segment state |
| Correct | Green | `Colors.green` or `Color(0xFF4CAF50)` | Correct answer segment |
| Incorrect | Gold | `Colors.amber` or `Color(0xFFFFC107)` | Incorrect answer segment |

### Level Status Colors (in Hamburger Menu)

| State | Border | Background | Icon | Usage |
|-------|--------|------------|------|-------|
| Completed | Grey | White | Green checkmark | Previously completed level |
| Current | Primary | Primary (10% opacity) | Play arrow | Currently active level |
| Locked | Grey | Light grey | Grey lock | Not yet unlocked |

### Instruction Modal Colors

| Element | Color | Code |
|---------|-------|------|
| Header Icon | Level color | Varies by level |
| Background | White | `Colors.white` |
| Text | Dark grey | `Colors.grey.shade800` |
| Dismiss Button | Primary | `Theme.primaryColor` |

### Level Color Associations (Optional)

For visual consistency with existing exercises (if needed):

| Level | Color | Code | Association |
|-------|-------|------|-------------|
| L1 | Blue | `Colors.blue` | Exploration |
| L2 | Purple | `Colors.purple` | Practice |
| L3 | Deep Purple | `Colors.deepPurple` | Mastery |
| L4+ | Red | `Colors.red` | Challenge |
| Finale | Green | `Colors.green` | Completion |

**Note:** These colors are NOT displayed in progress bar (only green/gold/grey). They MAY be used for:
- Level header in instruction modal
- Level border in hamburger menu (current level)
- Subtle background tint in hamburger menu

---

## Typography

### Font Sizes

| Element | Size | Weight | Usage |
|---------|------|--------|-------|
| AppBar Title | 20px | Medium (500) | Exercise name |
| Instruction Header | 20px | Bold (700) | Modal title |
| Instruction Body | 16px | Regular (400) | Modal instructions |
| Level Label | 16px | Regular (400) | Hamburger menu level items |
| Button Text | 16px | Medium (500) | "Got It!" button |

### Font Family

Use system default (Material Design defaults):
- **Android:** Roboto
- **iOS:** San Francisco
- **Web:** Roboto or system font

**Consistency:** All text should use same font family unless explicitly overridden for accessibility (e.g., dyslexia-friendly fonts in future).

---

## Spacing & Layout

### Padding Values

| Element | Padding | Usage |
|---------|---------|-------|
| AppBar | Default (56px height) | Standard Material AppBar |
| Progress Bar Container | 8px horizontal, 4px vertical | Container around segments |
| Progress Segments | 4px gap between | Space between individual segments |
| Instruction Modal | 24px all sides | Internal padding |
| Level Menu Items | 16px all sides | Internal padding for level cards |
| Level Menu Margins | 12px horizontal, 6px vertical | Space between level cards |

### Border Radius

| Element | Radius | Usage |
|---------|--------|-------|
| Progress Segments (Default) | 2px | Slightly rounded line segments |
| Progress Segments (Expanded) | 8px | Rounded squares during animation |
| Instruction Modal | 16px | Smooth, modern corners |
| Level Menu Items | 8px | Consistent with modal style |
| Buttons | 8px | Standard button style |

### Heights

| Element | Height | Usage |
|---------|--------|-------|
| AppBar | 56px | Standard Material AppBar |
| Progress Bar (Default) | 8px | Line segment height |
| Progress Bar (Expanded) | 32px | Square height during animation |
| Progress Bar Container | 16px | Total vertical space (8px segment + 4px padding each side) |

---

## Implementation Guide

### Widget Structure

#### Recommended Exercise Scaffold

```dart
class MinimalistExerciseScaffold extends StatelessWidget {
  final String exerciseTitle;
  final int totalProblems;
  final int currentProblemIndex;
  final List<bool> problemResults; // true = correct, false = incorrect
  final VoidCallback onShowInstructions;
  final VoidCallback onShowLevelSelector;
  final Widget exerciseContent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(exerciseTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            tooltip: 'Choose Level',
            onPressed: onShowLevelSelector,
          ),
          IconButton(
            icon: Icon(Icons.help_outline),
            tooltip: 'Instructions',
            onPressed: onShowInstructions,
          ),
        ],
      ),
      body: Column(
        children: [
          SegmentedProgressBar(
            totalSegments: totalProblems,
            currentSegment: currentProblemIndex,
            results: problemResults,
          ),
          Expanded(
            child: exerciseContent,
          ),
        ],
      ),
    );
  }
}
```

#### Segmented Progress Bar Widget

Create as separate reusable widget in `math_app/lib/widgets/common/segmented_progress_bar.dart`:

```dart
class SegmentedProgressBar extends StatefulWidget {
  final int totalSegments;
  final int currentSegment;
  final List<bool> results; // true = correct (green), false = incorrect (gold)

  const SegmentedProgressBar({
    Key? key,
    required this.totalSegments,
    required this.currentSegment,
    required this.results,
  }) : super(key: key);

  @override
  _SegmentedProgressBarState createState() => _SegmentedProgressBarState();
}

class _SegmentedProgressBarState extends State<SegmentedProgressBar>
    with TickerProviderStateMixin {

  int? _animatingSegment;
  late AnimationController _expandController;
  late AnimationController _popController;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _popController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(SegmentedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger animation when new segment completes
    if (widget.currentSegment > oldWidget.currentSegment) {
      _animateSegment(widget.currentSegment - 1);
    }
  }

  Future<void> _animateSegment(int index) async {
    setState(() { _animatingSegment = index; });

    // Expand
    await _expandController.forward();

    // Shake if incorrect
    if (!widget.results[index]) {
      await _shakeController.forward();
      _shakeController.reset();
    }

    // Pop
    await _popController.forward();
    _popController.reset();

    // Contract
    await _expandController.reverse();

    setState(() { _animatingSegment = null; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.totalSegments, (index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: _buildSegment(index),
          );
        }),
      ),
    );
  }

  Widget _buildSegment(int index) {
    final isComplete = index < widget.results.length;
    final isCorrect = isComplete && widget.results[index];
    final isAnimating = _animatingSegment == index;

    Color color = Colors.grey.shade300;
    if (isComplete) {
      color = isCorrect ? Colors.green : Colors.amber;
    }

    final segmentWidth = (MediaQuery.of(context).size.width - 32) / widget.totalSegments - 4;

    return AnimatedBuilder(
      animation: Listenable.merge([_expandController, _popController, _shakeController]),
      builder: (context, child) {
        double height = 8.0;
        double scale = 1.0;
        double translateX = 0.0;

        if (isAnimating) {
          height = 8.0 + (24.0 * _expandController.value); // 8 -> 32
          scale = 1.0 + (0.2 * _popController.value); // 1.0 -> 1.2

          // Shake animation
          if (_shakeController.value > 0) {
            final shakeProgress = _shakeController.value;
            if (shakeProgress < 0.2) {
              translateX = -4.0 * (shakeProgress / 0.2);
            } else if (shakeProgress < 0.4) {
              translateX = -4.0 + 8.0 * ((shakeProgress - 0.2) / 0.2);
            } else if (shakeProgress < 0.6) {
              translateX = 4.0 - 6.0 * ((shakeProgress - 0.4) / 0.2);
            } else if (shakeProgress < 0.8) {
              translateX = -2.0 + 4.0 * ((shakeProgress - 0.6) / 0.2);
            } else {
              translateX = 2.0 - 2.0 * ((shakeProgress - 0.8) / 0.2);
            }
          }
        }

        return Transform.translate(
          offset: Offset(translateX, 0),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: segmentWidth,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(isAnimating ? 8 : 2),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    _popController.dispose();
    _shakeController.dispose();
    super.dispose();
  }
}
```

#### Level Selection Drawer

Create as separate widget in `math_app/lib/widgets/common/level_selection_drawer.dart`:

```dart
class LevelSelectionDrawer extends StatelessWidget {
  final List<ScaffoldLevel> levels;
  final ScaffoldLevel currentLevel;
  final Function(ScaffoldLevel) onLevelSelected;
  final Function(ScaffoldLevel) isLevelUnlocked;

  const LevelSelectionDrawer({
    Key? key,
    required this.levels,
    required this.currentLevel,
    required this.onLevelSelected,
    required this.isLevelUnlocked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.layers, color: Theme.of(context).primaryColor),
                  SizedBox(width: 12),
                  Text(
                    'Choose Level',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Level list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8),
                itemCount: levels.length,
                itemBuilder: (context, index) {
                  final level = levels[index];
                  return _buildLevelItem(context, level);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelItem(BuildContext context, ScaffoldLevel level) {
    final isUnlocked = isLevelUnlocked(level);
    final isCurrent = level == currentLevel;
    final levelNumber = level.levelNumber;

    Color borderColor;
    Color backgroundColor;
    IconData icon;
    Color iconColor;

    if (isCurrent) {
      borderColor = Theme.of(context).primaryColor;
      backgroundColor = Theme.of(context).primaryColor.withOpacity(0.1);
      icon = Icons.play_arrow;
      iconColor = Theme.of(context).primaryColor;
    } else if (isUnlocked) {
      borderColor = Colors.grey.shade300;
      backgroundColor = Colors.white;
      icon = Icons.check_circle;
      iconColor = Colors.green;
    } else {
      borderColor = Colors.grey.shade400;
      backgroundColor = Colors.grey.shade200;
      icon = Icons.lock;
      iconColor = Colors.grey.shade600;
    }

    return GestureDetector(
      onTap: () {
        if (isUnlocked) {
          Navigator.pop(context); // Close drawer
          onLevelSelected(level);
        } else {
          _showLockedMessage(context, level);
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            SizedBox(width: 12),
            Text(
              'Level $levelNumber',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isUnlocked ? Colors.black : Colors.grey.shade600,
              ),
            ),
            if (isUnlocked && !isCurrent) ...[
              Spacer(),
              Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ],
        ),
      ),
    );
  }

  void _showLockedMessage(BuildContext context, ScaffoldLevel level) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.lock, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text('Complete previous levels to unlock Level ${level.levelNumber}!'),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
```

#### Instruction Modal

Create as separate widget in `math_app/lib/widgets/common/instruction_modal.dart`:

```dart
class InstructionModal extends StatelessWidget {
  final String levelTitle;
  final String instructionText;
  final Color? levelColor;

  const InstructionModal({
    Key? key,
    required this.levelTitle,
    required this.instructionText,
    this.levelColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = levelColor ?? Theme.of(context).primaryColor;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: 400),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.help_outline, size: 32, color: color),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    levelTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            Divider(height: 24),

            // Instructions
            Text(
              instructionText,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),

            SizedBox(height: 24),

            // Dismiss button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Got It!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> show(
    BuildContext context, {
    required String levelTitle,
    required String instructionText,
    Color? levelColor,
  }) {
    return showDialog(
      context: context,
      builder: (context) => InstructionModal(
        levelTitle: levelTitle,
        instructionText: instructionText,
        levelColor: levelColor,
      ),
    );
  }
}
```

### State Management Pattern

#### Exercise Coordinator State

```dart
class _ExerciseCoordinatorState extends State<ExerciseCoordinator>
    with ExerciseProgressMixin {

  // Current level tracking
  ScaffoldLevel _currentLevel = ScaffoldLevel.guidedExploration;

  // Progress tracking (for segmented bar)
  List<bool> _problemResults = []; // true = correct, false = incorrect
  int _currentProblemIndex = 0;

  // Level unlock tracking
  Map<int, bool> _levelUnlocked = {
    1: true,  // Level 1 always unlocked
    2: false,
    3: false,
    // ... etc
  };

  @override
  void initState() {
    super.initState();
    loadProgress(); // From ExerciseProgressMixin
  }

  void _onProblemComplete(bool isCorrect) {
    setState(() {
      _problemResults.add(isCorrect);
      _currentProblemIndex++;
    });

    // Record result for persistence
    recordProblemResult(
      levelNumber: _currentLevel.levelNumber,
      isCorrect: isCorrect,
      responseTime: _stopwatch.elapsedMilliseconds,
    );

    // Check for level completion
    if (_currentProblemIndex >= _problemsPerLevel) {
      _onLevelComplete();
    }
  }

  void _onLevelComplete() async {
    // Unlock next level
    final nextLevelNumber = _currentLevel.levelNumber + 1;
    if (!_levelUnlocked[nextLevelNumber]!) {
      setState(() {
        _levelUnlocked[nextLevelNumber] = true;
      });
      unlockLevel(nextLevelNumber); // Persist unlock
    }

    // Show celebration
    await _showCompletionCelebration();

    // Auto-advance
    if (_levelUnlocked[nextLevelNumber]!) {
      _switchLevel(ScaffoldLevel.values[nextLevelNumber - 1]);
    }
  }

  void _switchLevel(ScaffoldLevel level) {
    if (!_levelUnlocked[level.levelNumber]!) {
      // Show locked message
      return;
    }

    setState(() {
      _currentLevel = level;
      _problemResults = [];
      _currentProblemIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MinimalistExerciseScaffold(
      exerciseTitle: widget.exerciseConfig.title,
      totalProblems: _problemsPerLevel,
      currentProblemIndex: _currentProblemIndex,
      problemResults: _problemResults,
      onShowInstructions: () => _showInstructions(),
      onShowLevelSelector: () => _showLevelSelector(),
      exerciseContent: _buildCurrentLevelWidget(),
    );
  }

  void _showInstructions() {
    InstructionModal.show(
      context,
      levelTitle: 'Level ${_currentLevel.levelNumber}: ${_currentLevel.title}',
      instructionText: _getInstructionText(_currentLevel),
      levelColor: _getLevelColor(_currentLevel),
    );
  }

  void _showLevelSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => LevelSelectionDrawer(
        levels: ScaffoldLevel.values,
        currentLevel: _currentLevel,
        onLevelSelected: _switchLevel,
        isLevelUnlocked: (level) => _levelUnlocked[level.levelNumber] ?? false,
      ),
    );
  }
}
```

---

## Migration Checklist

### For Each Skill (10 coordinator files in `math_app/lib/exercises/`)

#### Step 1: Remove Old UI Components

- [ ] Remove `_buildLevelSelector()` method
- [ ] Remove `_buildProgressIndicator()` method
- [ ] Remove level button/tab widgets
- [ ] Remove progress text ("Correct: X/Y")
- [ ] Remove "Problems solved" counters

#### Step 2: Adopt New Shared Widgets

- [ ] Import shared widgets:
  ```dart
  import 'package:math_app/widgets/common/segmented_progress_bar.dart';
  import 'package:math_app/widgets/common/level_selection_drawer.dart';
  import 'package:math_app/widgets/common/instruction_modal.dart';
  import 'package:math_app/widgets/common/minimalist_exercise_scaffold.dart';
  ```

- [ ] Replace custom scaffold with `MinimalistExerciseScaffold`
- [ ] Add `_showInstructions()` method
- [ ] Add `_showLevelSelector()` method
- [ ] Pass correct props to `SegmentedProgressBar`

#### Step 3: Update State Management

- [ ] Add `List<bool> _problemResults` field
- [ ] Add `int _currentProblemIndex` field
- [ ] Update `_onProblemComplete()` to populate results list
- [ ] Ensure `_problemResults` resets on level switch

#### Step 4: Update Level Widgets (30+ files in `math_app/lib/widgets/`)

- [ ] Remove instruction containers from top of each level widget
- [ ] Store instruction text in coordinator (pass to modal)
- [ ] Remove "Problems solved" / "Correct: X/Y" text from level widgets
- [ ] Simplify layout (content only, no UI chrome)

#### Step 5: Test

- [ ] Run skill, complete problems
- [ ] Verify segmented bar animates correctly (green/gold)
- [ ] Verify incorrect answers show gentle shake
- [ ] Click hamburger menu, verify level selection works
- [ ] Click help button, verify instructions appear
- [ ] Complete level, verify auto-advance works
- [ ] Exit/reopen skill, verify state persists

---

## Accessibility Considerations

### Future Enhancements

While not required for initial implementation, consider these accessibility improvements:

1. **Screen Reader Support**
   - Add semantic labels to progress segments
   - Announce level changes
   - Describe visual animations verbally

2. **Colorblind Support**
   - Add patterns/icons to segments (not just color)
   - Green = checkmark, Gold = circle, Grey = empty

3. **Motor Impairment Support**
   - Larger tap targets for hamburger/help buttons
   - Keyboard navigation for level selection
   - Adjustable animation speed (settings)

4. **Visual Impairment Support**
   - High contrast mode (darker borders)
   - Larger segment sizes (option in settings)
   - Audio feedback for segment completion

---

## Examples & Visual Reference

### Complete Flow Example

**Starting Level 2:**

```
┌────────────────────────────────────────┐
│ ← Count the Dots            [≡] [?]   │  AppBar
├────────────────────────────────────────┤
│ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■                   │  Progress (0/10)
├────────────────────────────────────────┤
│                                        │
│        ● ● ● ● ●                       │  Level content
│        ● ● ● ●                         │  (Problem: count 9 dots)
│                                        │
│        [Submit: 9]                     │
│                                        │
└────────────────────────────────────────┘
```

**After Correct Answer 1:**

```
┌────────────────────────────────────────┐
│ ← Count the Dots            [≡] [?]   │
├────────────────────────────────────────┤
│ █ ■ ■ ■ ■ ■ ■ ■ ■ ■                   │  Progress (1/10, green)
├────────────────────────────────────────┤
│                                        │
│        ● ● ● ● ● ● ●                   │  New problem
│                                        │  (7 dots)
│        [Submit: ?]                     │
│                                        │
└────────────────────────────────────────┘
```

**After Incorrect Answer 2:**

```
┌────────────────────────────────────────┐
│ ← Count the Dots            [≡] [?]   │
├────────────────────────────────────────┤
│ █ ◆ ■ ■ ■ ■ ■ ■ ■ ■                   │  Progress (2/10, gold segment)
├────────────────────────────────────────┤
│                                        │
│        ● ● ● ● ●                       │  New problem
│        ● ● ● ● ● ●                     │  (11 dots)
│                                        │
│        [Submit: ?]                     │
│                                        │
└────────────────────────────────────────┘
```

**Level Complete (10/10):**

```
┌────────────────────────────────────────┐
│ ← Count the Dots            [≡] [?]   │
├────────────────────────────────────────┤
│ █ █ █ █ █ █ █ █ █ █                   │  All segments filled
├────────────────────────────────────────┤
│         ┌──────────────┐              │
│         │  Level 2     │              │
│         │  Complete!🎉 │              │  Celebration modal
│         │              │              │
│         │ Moving to    │              │
│         │ Level 3...   │              │
│         └──────────────┘              │
└────────────────────────────────────────┘
```

**Level Selection Drawer Open:**

```
┌──────────┬─────────────────────────────┐
│          │ ← Count the Dots   [≡] [?] │
│ ╔══════╗ ├─────────────────────────────┤
│ ║ ✓ L1 ║ │ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■        │
│ ╚══════╝ │                             │
│          │       ● ● ● ● ●             │
│ ╔══════╗ │       ● ● ● ●               │
│ ║ → L2 ║ ← Current level (highlighted)│
│ ╚══════╝ │                             │
│          │       [Submit: 9]           │
│ ┌──────┐ │                             │
│ │🔒 L3 │ ← Locked                     │
│ └──────┘ │                             │
│          │                             │
└──────────┴─────────────────────────────┘
```

**Instruction Modal Open:**

```
┌────────────────────────────────────────┐
│ ← Count the Dots            [≡] [?]   │
├────────────────────────────────────────┤
│ █ ■ ■ ■ ■ ■ ■ ■ ■ ■                   │
├────────────────────────────────────────┤
│   ╔══════════════════════════════╗    │
│   ║ ? Level 2: Tap to Count  [×] ║    │
│   ║ ──────────────────────────    ║    │
│   ║                               ║    │
│   ║ Tap each dot once to count    ║    │
│   ║ them. Watch as each dot gets  ║    │
│   ║ marked!                       ║    │
│   ║                               ║    │
│   ║        [ Got It! ]            ║    │
│   ╚══════════════════════════════╝    │
│                                        │
└────────────────────────────────────────┘
```

---

## Summary

This design system prioritizes:

1. **Minimalism** - Only essential elements visible
2. **Focus** - Child's attention on exercise, not UI chrome
3. **Feedback** - Immediate visual response via segmented bar
4. **Flexibility** - Instructions and navigation available but hidden
5. **Delight** - Subtle animations celebrate progress without distraction
6. **Consistency** - All exercises share same visual language

**Key Innovation:** Segmented progress bar replaces numerical counters, providing visual progress feedback without creating anxiety about "right/wrong" counts.

---

**For questions or clarifications, see [CLAUDE.md](CLAUDE.md) or contact project maintainer.**
