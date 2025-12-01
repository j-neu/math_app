# Math App - Research-Based Learning for Young Children

A Flutter-based math learning application for pre-1st to 4th grade students, with special focus on supporting children with ADHD. Built on iMINT and PIKAS pedagogical research frameworks.

---

## Project Status

**Phase:** 2 - Skill Engine
**Progress:** 6/120+ skills complete (5%)
**Last Updated:** 2025-11-23

### Completed
- ✅ Phase 1: Core Architecture (Diagnostic, Navigation, User Profiles)
- ✅ Phase 1.5: PIKAS Integration (88 skills, sufficient for Phase 2)
- ✅ Card-Based Scaffolding Framework (follows iMINT/PIKAS card prescriptions)
- ✅ 6 functional skills: Z1, C1.1, C1.2, C2.1, C3.1, C4.1

---

## Documentation Structure

### Essential Files (Read These First)
1. **[TERMINOLOGY.md](TERMINOLOGY.md)** - Terminology guide (NEW!)
   - Skill vs. Level vs. Problem vs. Exercise
   - Avoids confusion in documentation
   - **Read this first if joining the project**

2. **[CLAUDE.md](CLAUDE.md)** - Main project guide (11KB)
   - Quick start commands
   - Card-based scaffolding framework summary
   - Architecture overview
   - Skill creation checklist

3. **[IMINT_TO_APP_FRAMEWORK.md](IMINT_TO_APP_FRAMEWORK.md)** - Core pedagogical framework (13KB)
   - Complete card-based scaffolding methodology
   - Translation rules (physical → digital)
   - "Wie kommt die Handlung in den Kopf?" implementation guide

4. **[DIFFICULTY_CURVE.md](DIFFICULTY_CURVE.md)** - Standard difficulty progression (NEW!)
   - Easy→Hard→Easy pattern for all levels
   - Default: Trivial (P1-2), Easy (P3-4), Medium (P5-6), Hard (P7-8), Medium (P9), Easy (P10)
   - ADHD-friendly: Build confidence, challenge, end positively

5. **[tasks.md](tasks.md)** - Current/future work roadmap (11KB)
   - Phase 2 skill sets (18 sets, 120-150 skills)
   - Widget library status
   - Current focus: SET 1 completion

6. **[adhd guidelines.md](adhd%20guidelines.md)** - ADHD design principles (3KB)
   - 7 core principles from research
   - Concrete & visual learning
   - No-fail approach

### Historical Context
7. **[COMPLETED_TASKS.md](COMPLETED_TASKS.md)** - Brief history (7KB)
   - Phase 1 & 1.5 summary
   - 6 completed skills overview
   - Key architectural decisions

8. **[ARCHIVE_IMPLEMENTATIONS.md](ARCHIVE_IMPLEMENTATIONS.md)** - Detailed implementation notes (11KB)
   - Z1, C1.1, C1.2, C2.1 complete documentation
   - Reusable patterns
   - Common issues & solutions

---

## Quick Start

```bash
cd math_app
flutter pub get
flutter run
```

**For AI assistance:** Start by reading [TERMINOLOGY.md](TERMINOLOGY.md), then [CLAUDE.md](CLAUDE.md)

**For new developers:** Read in order:
1. TERMINOLOGY.md (definitions)
2. CLAUDE.md (overview)
3. IMINT_TO_APP_FRAMEWORK.md (framework)
4. DIFFICULTY_CURVE.md (difficulty progression)
5. adhd guidelines.md (design principles)
6. tasks.md (current work)

---

## Key Concepts

### Terminology: Skill > Level > Problem
- **Skill** = Complete learning module (e.g., C1.1 "Count the Dots") with 3-5 levels
- **Level** = Scaffolding stage (e.g., Level 2: "Tap to Count")
- **Problem** = Individual question (e.g., "Count these 7 dots")

See [TERMINOLOGY.md](TERMINOLOGY.md) for complete clarification.

### Card-Based Scaffolding Framework
Every skill implements progressive scaffolding based on iMINT/PIKAS cards:
- Cards prescribe 2-4+ levels (NOT always 3!)
- Each level has specific action (drag, tap, no-action, flash-hide, etc.)
- Plus one finale level (easier mixed review)

**Purpose:** Answer "Wie kommt die Handlung in den Kopf?" (How does action become mental?)

### 88 Skill Tags System
- 76 iMINT skills: `counting_1` through `combined_strategy_20`
- 12 PIKAS skills: `ordinal_`, `representation_`, `operation_sense_`, `number_line_`
- Format: `category_number` (self-documenting)

### ADHD-Informed Design
- Short sessions (15 min max)
- Immediate feedback
- No-fail approach (never say "wrong")
- Concrete & visual
- Low cognitive load

---

## Project Structure

```
Math_App/
├── math_app/                          # Flutter app
│   ├── lib/
│   │   ├── models/                    # Data models
│   │   ├── screens/                   # Full-screen UI
│   │   ├── widgets/                   # Level-specific widgets
│   │   ├── exercises/                 # Exercise coordinators
│   │   └── services/                  # Business logic
│   └── test/
├── Research/                          # Pedagogical materials
│   ├── SKILLS_README.md              # 88 skills documentation
│   ├── skills_taxonomy.csv           # Complete skill catalog
│   ├── MathApp_Diagnostic_with_skills.csv
│   ├── PIKAS_Analysis.md             # 36/58 cards analyzed
│   └── iMINT-Kartei_190529.pdf
├── CLAUDE.md                          # Main project guide
├── IMINT_TO_APP_FRAMEWORK.md         # Core framework
├── tasks.md                           # Current roadmap
├── adhd guidelines.md                 # Design principles
├── COMPLETED_TASKS.md                 # History
└── ARCHIVE_IMPLEMENTATIONS.md         # Detailed notes
```

---

## Development Phases

### Phase 1: Core Architecture ✅ COMPLETE
- Flutter project setup
- Diagnostic test (59 questions)
- Navigation & user profiles
- Semantic skill IDs system

### Phase 2: Skill Engine (IN PROGRESS - 5%)
- **Target:** 120-150 skills covering 88 skill tags
- **Current:** 6 skills complete
- **Focus:** SET 1 - Foundation Counting (5/6 done, Z1 finale pending)

### Phase 3: UI Polish & ADHD Features (PLANNED)
- Gamification
- Helper character
- Parent dashboard
- Localization (DE/EN)

### Phase 4: Content Expansion & Beta Testing (PLANNED)
- Remaining 22 PIKAS cards
- Beta testing
- Algorithm refinement

---

## Technologies

- **Framework:** Flutter
- **State Management:** Riverpod
- **Language:** Dart
- **Platforms:** Web, Android (iOS future)

---

## Research Foundation

### iMINT Kartei
- Diagnostic-first approach
- 76 skills across 5 categories
- Strategy development focus
- "Ablösung vom zählenden Rechnen"

### PIKAS FÖDIMA
- Conceptual understanding
- Connecting representations
- 58 diagnostic cards
- Rich activity repertoire

**See [IMINT_TO_APP_FRAMEWORK.md](IMINT_TO_APP_FRAMEWORK.md) for synthesis**

---

## Contributing

When adding skills:
1. Read [TERMINOLOGY.md](TERMINOLOGY.md) for correct terminology
2. Follow Card-Based Scaffolding Framework
3. Document source (iMINT/PIKAS card)
4. Answer "Wie kommt die Handlung in den Kopf?"
5. Tag with appropriate skill tags
6. Implement no-fail feedback
7. Add finale level (easier than hardest card level)

**See [CLAUDE.md](CLAUDE.md) Skill Creation Checklist**

---

## License

[To be determined]

---

**For questions or guidance, see [CLAUDE.md](CLAUDE.md)**
