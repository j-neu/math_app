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

## No Finale Level

**⚠️ Do NOT add an artificial "Finale" or "Summary" level.**

**Principle:** We trust the card's pedagogical design. The skill ends when the card's prescribed levels are complete.
- **Completion:** Mastery of the FINAL level prescribed by the card constitutes skill completion.
- **Difficulty:** The final card level typically represents the "Mastery" or "Mental Image" stage, which is the natural conclusion.

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
3. **NO FINALE:** Ensure you are NOT adding an extra level.
4. Apply DIFFICULTY_CURVE.md to each level (Easy→Hard→Easy within each level)
5. Decide: Order-dependent (2+8 ≠ 8+2 for pattern recognition) or order-independent (sum only)
6. Plan data tracking (response time, error patterns) and no-fail hints

**Pattern Example - Decompose 10:**
- L1: Tap counters to flip, see equation update (explore)
- L2: See counters, write equation (practice)
- L3: Hidden counters, write from memory (master) - shows briefly on errors

**Typical Scaffolding:**
L1 (Explore): Manipulate + see | L2 (Practice): See + write | L3 (Master): Hidden + memory

This ensures "Wie kommt die Handlung in den Kopf?" (action → mental) through progressive scaffolding.
