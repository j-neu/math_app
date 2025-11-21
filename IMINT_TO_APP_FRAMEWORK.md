# iMINT/PIKAS to App Translation Framework

**Core Principle:** Translate physical learning activities into digital experiences while preserving pedagogical intent.

## CRITICAL: Cards Define the Scaffolding

**⚠️ The scaffolding levels come FROM THE CARDS, not a predetermined template.**

**Implementation Rules:**
1. Read the card's "Wie kommt die Handlung in den Kopf?" section FIRST
2. Follow the exact progression of actions the card describes
3. Number of levels varies (2, 3, 4, or more) - implement what the card prescribes
4. Use the specific actions prescribed (drag, tap, no action, flash, etc.)
5. Only adapt for technical limitations (e.g., speech → typing)

**Example:** iMINT Card 1 prescribes 4 levels (schieben → antippen → ohne Handlung → mit Augen), so C1.1 implements 4 levels (Drag → Tap → Look → Flash). NOT a 3-level template!

## Finale Level Requirement (ADHD Support)

**⚠️ Add ONE final "Finale" level after card-prescribed levels.**

**Purpose:** Easy→Hard→Easy flow. ADHD children need end-of-exercise success.

**Design Rules:**
1. **Easier** than hardest card level (mixed review, not new concepts)
2. **10 problems** (demonstrate mastery without fatigue)
3. **Completable** - Defines "completed" status (zero errors + time limits)
4. **State persistence** via ExerciseProgressMixin (load/save every 5 problems)

**Examples:** C1.1 finale = 8-12 dots (no flash) | Z1 finale = Decompose 5-8 | C2.1 finale = Order 5-7 numbers

**Completion:** notStarted → inProgress → finished (all levels unlocked) → completed (finale mastered)

## Core Progression: Handlung → Vorstellung → Symbol

iMINT progression: **Action** (manipulate) → **Mental Imagery** (imagine) → **Symbols** (abstract notation)

## Translation Guidelines

### Physical Action → Digital Equivalent

| Physical (Card) | Digital (App) |
|-----------------|---------------|
| Schieben (push aside) | Drag to area |
| Antippen (tap) | Tap/touch |
| Keine Handlung (no action) | No interaction |
| Mit Augen (eyes only) | Flash then hide |
| Verdecken (cover) | Hide visual |

### Translation Rules

**DO:** Follow card sequence exactly • Match support/challenge at each step • Implement all levels card prescribes
**DON'T:** Force 3-level structure • Substitute easier mechanics • Skip steps • Add unlisted difficulty

**Adaptations:** Speech → typing | Teacher observation → track response time | Partner work → automated prompts

## Common Patterns

**Pattern A (Manipulation → Mental):** See & manipulate → Imagine → Symbols only
**Pattern B (Action Reduction):** Drag → Tap → Look → Flash-hide
**Pattern C (Visual Fading):** Full visual → Partial → Hidden (mental image)

## Key Translation Principles

1. **Visual over Realistic:** Use abstract representations (counters, blocks), not realistic simulations
2. **Adaptive Hints:** Convert teacher prompts to written hints (e.g., "Imagine 10 counters...")
3. **Track Strategy:** Response time (slow = counting) • Error patterns • Systematic vs random
4. **Understanding First:** Memorization only after understanding (Level 3 unlocks after L2 success)

## Implementation Checklist

**Before coding:**
1. Read card's "Wie kommt die Handlung in den Kopf?" section → Extract scaffolding steps → Count levels (2-4+)
2. Map each physical action to digital (see table above) → Preserve pedagogical intent
3. Design finale level (easier mixed review, 10 problems, completable)
4. Decide: Order-dependent (2+8 ≠ 8+2 for pattern recognition) or order-independent (sum only)
5. Plan data tracking (response time, error patterns) and no-fail hints

**Pattern Example - Decompose 10:**
- L1: Tap counters to flip, see equation update (explore)
- L2: See counters, write equation (practice)
- L3: Hidden counters, write from memory (master) - shows briefly on errors
- L4 (Finale): Decompose 5-8 (easier, completable)

**Typical Scaffolding:**
L1 (Explore): Manipulate + see | L2 (Practice): See + write | L3 (Master): Hidden + memory | L4 (Finale): Easy review

This ensures "Wie kommt die Handlung in den Kopf?" (action → mental) through progressive scaffolding.
